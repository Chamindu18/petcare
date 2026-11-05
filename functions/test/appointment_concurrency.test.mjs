import test, {before, beforeEach, after} from 'node:test';
import assert from 'node:assert/strict';
import {readFileSync} from 'node:fs';
import {initializeApp, deleteApp} from 'firebase-admin/app';
import {getFirestore} from 'firebase-admin/firestore';
import {initializeTestEnvironment} from '@firebase/rules-unit-testing';
import {doc, runTransaction, serverTimestamp, getDoc, updateDoc, setDoc} from 'firebase/firestore';
import {assertDenied} from '../../test/firestore/assert_denied.mjs';
import {reserveAppointment, BookingError, instant, schedule} from '../src/appointment_booking.mjs';

let db, app, env;
const base = '2026-11-10T09:00:00.000Z';
const request = (appointmentId, patch = {}) => ({action: 'create', appointmentId,
  petId: 'pet-a', hospitalId: 'hospital-a', vetId: 'vet-a', serviceId: 'service-a',
  dateTime: base, reason: 'Checkup', ...patch});
const book = (appointmentId, patch = {}, uid = 'owner-a') => reserveAppointment(db, uid, request(appointmentId, patch));
const reassign = (appointmentId, vetId, uid = 'staff-a') => reserveAppointment(db, uid,
  {action: 'reassign', appointmentId, hospitalId: 'hospital-a', vetId});
async function counts(appointments, schedules = appointments) {
  assert.equal((await db.collection('appointments').get()).size, appointments);
  assert.equal((await db.collection('appointment_schedule').get()).size, schedules);
}
async function oneWinner(promises) {
  const results = await Promise.allSettled(promises);
  assert.equal(results.filter(r => r.status === 'fulfilled').length, 1);
  for (const r of results.filter(r => r.status === 'rejected')) {
    assert.ok(r.reason instanceof BookingError, r.reason?.stack);
    assert.equal(r.reason.code, 'already-exists');
  }
  return results;
}
before(async () => {
  assert.ok(process.env.FIRESTORE_EMULATOR_HOST, 'Emulator is required; never run these tests on production');
  env = await initializeTestEnvironment({projectId: 'demo-petcare',
    firestore: {rules: readFileSync('firestore.rules', 'utf8')}});
  app = initializeApp({projectId: 'demo-petcare'}, 'appointment-concurrency-tests');
  db = getFirestore(app);
});
after(async () => { await env?.cleanup(); if (app) await deleteApp(app); });
beforeEach(async () => {
  await env.clearFirestore();
  const entries = {
    'hospitals/hospital-a': {active: true}, 'hospitals/hospital-b': {active: true},
    'users/owner-a': {role: 'owner'}, 'users/owner-b': {role: 'owner'},
    'users/staff-a': {role: 'veterinary_staff'}, 'users/staff-b': {role: 'veterinary_staff'},
    'hospital_staff/staff-a': {userId: 'staff-a', hospitalId: 'hospital-a', active: true},
    'hospital_staff/staff-b': {userId: 'staff-b', hospitalId: 'hospital-b', active: true},
    'pets/pet-a': {ownerId: 'owner-a'}, 'pets/pet-b': {ownerId: 'owner-b'},
    'services/service-a': {hospitalId: 'hospital-a', duration: 30},
    'services/long': {hospitalId: 'hospital-a', duration: 60},
    'services/service-b': {hospitalId: 'hospital-b', duration: 30},
  };
  for (const [vetId, userId, hospitalId] of [['vet-a', 'doctor-a', 'hospital-a'],
    ['vet-b', 'doctor-b', 'hospital-a'], ['vet-c', 'doctor-c', 'hospital-b']]) {
    entries[`users/${userId}`] = {role: 'veterinarian', vetId, hospitalId};
    entries[`veterinarians/${vetId}`] = {userId, vetId, hospitalId, active: true};
  }
  await Promise.all(Object.entries(entries).map(([path, data]) => db.doc(path).set(data)));
});

test('six simultaneous requests for one interval have one winner and no orphan documents', async () => {
  await oneWinner(Array.from({length: 6}, (_, i) => book(`simultaneous-${i}`)));
  await counts(1);
  assert.equal((await db.collection('appointment_booking_locks').get()).size, 1);
  const winner = (await db.collection('appointments').get()).docs[0];
  assert.equal((await db.doc(`appointment_schedule/${winner.id}`).get()).data().durationMinutes, 30);
});

test('missing and inactive hospitals cannot accept bookings or reassignment', async () => {
  await book('existing');
  for (const hospital of [null, {active: false}]) {
    if (hospital) await db.doc('hospitals/hospital-a').set(hospital);
    else await db.doc('hospitals/hospital-a').delete();
    await assert.rejects(book('blocked', {dateTime: '2026-11-10T10:00:00Z'}),
      error => error instanceof BookingError && error.code === 'failed-precondition');
    await assert.rejects(reassign('existing', 'vet-b'),
      error => error instanceof BookingError && error.code === 'failed-precondition');
    await counts(1);
    assert.equal((await db.doc('appointments/existing').get()).data().vetId, 'vet-a');
    assert.equal((await db.doc('appointment_booking_locks/vet-a').get()).data().revision, 1);
  }
});

test('partially overlapping intervals with different service lengths cannot both reserve', async () => {
  await oneWinner([book('long', {serviceId: 'long'}), book('short', {dateTime: '2026-11-10T09:45:00Z'})]);
  await counts(1);
});

test('adjacent appointments and different dates may reserve concurrently', async () => {
  await Promise.all([book('first'), book('adjacent', {dateTime: '2026-11-10T09:30:00Z'}),
    book('tomorrow', {dateTime: '2026-11-11T09:00:00Z'})]);
  await counts(3);
});

test('different veterinarians in the same hospital do not conflict', async () => {
  await Promise.all([book('a'), book('b', {vetId: 'vet-b'})]);
  await counts(2);
});

test('different hospitals with their own verified doctors do not conflict', async () => {
  await Promise.all([book('a'), book('c', {vetId: 'vet-c', hospitalId: 'hospital-b', serviceId: 'service-b'})]);
  await counts(2);
});

test('simultaneous staff reassignment to the same target has one winner', async () => {
  await book('source-a');
  await book('source-b', {vetId: 'vet-b'});
  // A third verified doctor in the same hospital is the free target.
  await db.doc('users/doctor-d').set({role: 'veterinarian', vetId: 'vet-d', hospitalId: 'hospital-a'});
  await db.doc('veterinarians/vet-d').set({active: true, userId: 'doctor-d', vetId: 'vet-d', hospitalId: 'hospital-a'});
  await oneWinner([reassign('source-a', 'vet-d'), reassign('source-b', 'vet-d')]);
  await counts(2);
  const target = await db.collection('appointments').where('vetId', '==', 'vet-d').get();
  assert.equal(target.size, 1);
  for (const doc of (await db.collection('appointments').get()).docs) {
    assert.equal((await db.doc(`appointment_schedule/${doc.id}`).get()).data().vetId, doc.data().vetId);
  }
});

test('booking and staff reassignment contend on the same target lock', async () => {
  await book('source', {vetId: 'vet-b'});
  await oneWinner([book('new'), reassign('source', 'vet-a')]);
  const target = await db.collection('appointments').where('vetId', '==', 'vet-a').get();
  assert.equal(target.size, 1);
  const appointments = await db.collection('appointments').get();
  assert.equal((await db.collection('appointment_schedule').get()).size, appointments.size);
});

test('owner rescheduling and booking enforce the same interval rules', async () => {
  await book('source', {dateTime: '2026-11-10T11:00:00Z'});
  await oneWinner([book('new'), reserveAppointment(db, 'owner-a', request('source', {action: 'update'}))]);
  const occupied = (await db.collection('appointments').get()).docs.filter(d => d.data().dateTime === base);
  assert.equal(occupied.length, 1);
});

test('unauthorized and invalid requests leave no appointment, schedule or lock', async () => {
  for (const [uid, patch] of [[null, {}], ['staff-a', {}], ['owner-b', {}],
    ['owner-a', {vetId: 'vet-c'}], ['owner-a', {serviceId: 'service-b'}],
    ['owner-a', {reason: 'x'.repeat(2001)}]]) {
    await assert.rejects(book('invalid', patch, uid), BookingError);
  }
  await db.doc('veterinarians/vet-a').update({active: false});
  await assert.rejects(book('inactive'), BookingError);
  await counts(0);
  assert.equal((await db.collection('appointment_booking_locks').get()).size, 0);
});

test('cross-hospital staff, doctors and owners cannot use staff reassignment', async () => {
  await book('source');
  const before = (await db.doc('appointments/source').get()).data();
  for (const uid of ['staff-b', 'doctor-a', 'owner-a']) {
    await assert.rejects(reassign('source', 'vet-b', uid), BookingError);
  }
  await assert.rejects(reassign('source', 'vet-c'), BookingError);
  assert.deepEqual((await db.doc('appointments/source').get()).data(), before);
  await counts(1);
});

test('legacy appointments without projections still prevent overlapping booking', async () => {
  await db.doc('appointments/legacy').set({...request('legacy'), dateTime: '2026-11-10T14:30:00.000',
    ownerId: 'owner-a', status: 'pending', createdAt: base});
  await assert.rejects(book('new'), error => error.code === 'already-exists');
  await counts(1, 0);
});

test('snapshotted duration is stable when the service duration changes', async () => {
  await book('first');
  await db.doc('services/service-a').update({duration: 10});
  await assert.rejects(book('overlap', {dateTime: '2026-11-10T09:15:00Z'}), error => error.code === 'already-exists');
  await book('adjacent', {dateTime: '2026-11-10T09:30:00Z'});
  await counts(2);
});

test('failed duplicate request ID cannot overwrite an existing booking', async () => {
  await book('same');
  await assert.rejects(book('same', {vetId: 'vet-b'}), error => error.code === 'already-exists');
  assert.equal((await db.doc('appointments/same').get()).data().vetId, 'vet-a');
  await counts(1);
});

test('queued appointment reassignment is rejected without changing its queue', async () => {
  await book('queued');
  await db.doc('appointments/queued').update({status: 'confirmed', queueId: 'queue'});
  await db.doc('queue_records/queue').set({appointmentId: 'queued', status: 'waiting'});
  await assert.rejects(reassign('queued', 'vet-b'), BookingError);
  assert.equal((await db.doc('queue_records/queue').get()).data().status, 'waiting');
  assert.equal((await db.doc('appointments/queued').get()).data().vetId, 'vet-a');
});

test('hospital-local legacy times and offset times represent the same instant', () => {
  assert.equal(instant('2026-11-10T14:30:00.000').toISOString(), base);
  assert.equal(instant('2026-11-10T14:30:00+05:30').toISOString(), base);
});


test('owner cancellation releases a server-booked interval without corrupting duration snapshots', async () => {
  await book('first');
  const client = env.authenticatedContext('owner-a').firestore();
  await runTransaction(client, async tx => {
    const ref = doc(client, 'appointments/first');
    const data = (await tx.get(ref)).data();
    tx.update(ref, {status: 'cancelled', updatedAt: serverTimestamp()});
    tx.set(doc(client, 'appointment_schedule/first'), schedule({...data, status: 'cancelled'}));
  });
  await book('replacement');
  await counts(2);
  assert.equal((await db.doc('appointments/first').get()).data().durationMinutes, 30);
});

test('clients cannot forge duration snapshots, lock revisions, or direct rescheduling', async () => {
  await book('first');
  const owner = env.authenticatedContext('owner-a').firestore();
  await assertDenied(updateDoc(doc(owner, 'appointments/first'), {durationMinutes: 1}));
  await assertDenied(updateDoc(doc(owner, 'appointment_schedule/first'), {durationMinutes: 1}));
  await assertDenied(updateDoc(doc(owner, 'appointments/first'), {dateTime: '2026-11-10T10:00:00Z', updatedAt: serverTimestamp()}));
  await assertDenied(getDoc(doc(owner, 'appointment_booking_locks/vet-a')));
  await assertDenied(setDoc(doc(owner, 'appointment_booking_locks/vet-a'), {revision: 999}));
});

test('missing and mismatched veterinarian accounts fail before any writes', async () => {
  await db.doc('veterinarians/vet-a').update({userId: 'missing-doctor'});
  await assert.rejects(book('missing-account'), BookingError);
  await db.doc('veterinarians/vet-a').update({userId: 'doctor-b'});
  await assert.rejects(book('wrong-account'), BookingError);
  await assert.rejects(book('missing-directory', {vetId: 'missing'}), BookingError);
  await counts(0);
  assert.equal((await db.collection('appointment_booking_locks').get()).size, 0);
});

test('unassigned hospitals cannot book even with internally matching records', async () => {
  await db.doc('users/doctor-a').update({hospitalId: 'unassigned'});
  await db.doc('veterinarians/vet-a').update({hospitalId: 'unassigned'});
  await db.doc('services/service-a').update({hospitalId: 'unassigned'});
  await assert.rejects(book('unassigned', {hospitalId: 'unassigned'}),
    error => error instanceof BookingError && error.code === 'failed-precondition');
  await counts(0);
});

test('malformed account IDs and contradictory directory IDs grant no doctor access', async () => {
  await book('first');
  const doctor = env.authenticatedContext('doctor-a').firestore();
  for (const patch of [{vetId: ''}, {vetId: 123}]) {
    await db.doc('users/doctor-a').update(patch);
    await assertDenied(getDoc(doc(doctor, 'appointments/first')));
  }
  await db.doc('users/doctor-a').update({vetId: 'vet-a'});
  await db.doc('veterinarians/vet-a').update({vetId: 'contradictory'});
  await assertDenied(getDoc(doc(doctor, 'appointments/first')));
  await assert.rejects(book('invalid-directory'), BookingError);
});
