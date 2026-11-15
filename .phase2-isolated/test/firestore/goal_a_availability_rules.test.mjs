import {readFileSync} from 'node:fs';
import {resolve} from 'node:path';
import test from 'node:test';
import assert from 'node:assert/strict';
import {initializeTestEnvironment, assertSucceeds} from '@firebase/rules-unit-testing';
import {collection, doc, getDoc, getDocs, query, setDoc, updateDoc, deleteDoc, where, serverTimestamp} from 'firebase/firestore';
import {assertDenied} from './assert_denied.mjs';

const rules = readFileSync(resolve('deployment/goal-a/firestore.rules'), 'utf8');

test('Goal A deployed-rules candidate permits only authenticated availability reads', async () => {
  const env = await initializeTestEnvironment({
    projectId: 'demo-petcare-phase2-isolated', firestore: {rules},
  });
  try {
    const projection = {
      vetId: 'vet-a', hospitalId: 'hospital-a', serviceId: 'service-a',
      dateTime: '2026-11-20T03:30:00.000Z', status: 'confirmed', durationMinutes: 30,
    };
    await env.withSecurityRulesDisabled(async context => {
      const db = context.firestore();
      await setDoc(doc(db, 'appointment_schedule/occupied'), projection);
      await setDoc(doc(db, 'appointments/occupied'), {
        ...projection, ownerId: 'private-owner', petId: 'private-pet',
        reason: 'private clinical reason',
      });
    });

    const owner = env.authenticatedContext('owner-a').firestore();
    const anonymous = env.unauthenticatedContext().firestore();
    const exactQuery = db => getDocs(query(
      collection(db, 'appointment_schedule'), where('vetId', '==', 'vet-a'),
    ));
    const result = await assertSucceeds(exactQuery(owner));
    assert.equal(result.size, 1);
    assert.deepEqual(result.docs[0].data(), projection);
    await assertDenied(exactQuery(anonymous));
    await assertDenied(getDoc(doc(anonymous, 'appointment_schedule/occupied')));
    await assertDenied(getDoc(doc(owner, 'appointments/occupied')));
    await assertDenied(setDoc(doc(owner, 'appointment_schedule/forged'), projection));
    await assertDenied(updateDoc(doc(owner, 'appointment_schedule/occupied'), {status: 'cancelled'}));
    await assertDenied(deleteDoc(doc(owner, 'appointment_schedule/occupied')));
  } finally {
    await env.cleanup();
  }
});

test('Goal A blocks every unprojected occupancy path and preserves scoped reads and metadata edits', async () => {
  const env = await initializeTestEnvironment({projectId: 'demo-petcare-phase2-isolated', firestore: {rules}});
  try {
    const appointment = {
      appointmentId: 'existing', ownerId: 'owner-a', petId: 'pet-a',
      hospitalId: 'hospital-a', vetId: 'vet-a', serviceId: 'service-a',
      dateTime: '2026-11-20T03:30:00.000Z', durationMinutes: 30,
      status: 'pending', reason: 'private', createdAt: 'created', updatedAt: 'updated',
    };
    await env.withSecurityRulesDisabled(async context => {
      const db = context.firestore();
      await setDoc(doc(db, 'users/owner-a'), {role: 'owner'});
      await setDoc(doc(db, 'users/staff-a'), {role: 'veterinary_staff'});
      await setDoc(doc(db, 'hospital_staff/staff-a'), {
        userId: 'staff-a', hospitalId: 'hospital-a', active: true,
      });
      await setDoc(doc(db, 'pets/pet-a'), {ownerId: 'owner-a'});
      await setDoc(doc(db, 'appointments/existing'), appointment);
    });
    const owner = env.authenticatedContext('owner-a').firestore();
    const staff = env.authenticatedContext('staff-a').firestore();
    const stranger = env.authenticatedContext('stranger').firestore();
    const ref = doc(owner, 'appointments/existing');
    assert.equal((await assertSucceeds(getDoc(ref))).data().reason, 'private');
    await assertDenied(getDoc(doc(stranger, 'appointments/existing')));
    assert.ok((await assertSucceeds(getDocs(query(
      collection(staff, 'appointments'), where('hospitalId', '==', 'hospital-a'),
    )))).docs.some(document => document.id === 'existing'));
    await assertDenied(setDoc(doc(owner, 'appointments/forged'), appointment));
    await assertDenied(updateDoc(ref, {dateTime: '2026-11-20T04:00:00.000Z'}));
    await assertDenied(updateDoc(ref, {vetId: 'vet-b'}));
    await assertDenied(updateDoc(ref, {serviceId: 'service-b'}));
    await assertDenied(updateDoc(ref, {durationMinutes: 15}));
    await assertDenied(updateDoc(ref, {hospitalId: 'hospital-b'}));
    await assertDenied(updateDoc(ref, {status: 'cancelled', updatedAt: serverTimestamp()}));
    await assertDenied(updateDoc(doc(staff, 'appointments/existing'), {
      status: 'confirmed', updatedAt: serverTimestamp(),
    }));
    await assertDenied(updateDoc(doc(staff, 'appointments/existing'), {dateTime: '2026-11-20T04:00:00.000Z'}));
    await assertDenied(deleteDoc(ref));
    await assertSucceeds(updateDoc(ref, {reason: 'updated private reason'}));
    await assertSucceeds(updateDoc(doc(staff, 'appointments/existing'), {queueId: 'queue-a'}));
  } finally {
    await env.cleanup();
  }
});
