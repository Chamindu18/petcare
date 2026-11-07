import test from 'node:test';
import assert from 'node:assert/strict';
import {readFileSync} from 'node:fs';
import {initializeApp, deleteApp} from 'firebase-admin/app';
import {getFirestore} from 'firebase-admin/firestore';
import {initializeTestEnvironment, assertSucceeds} from '@firebase/rules-unit-testing';
import {doc, getDoc, getDocs, collection, query, where, runTransaction,
  serverTimestamp, Timestamp, updateDoc} from 'firebase/firestore';
import {assertDenied} from '../../test/firestore/assert_denied.mjs';

test('real callable booking, staff decisions/reassignment, doctor visibility and daily queue agree across roles', async () => {
  assert.ok(process.env.FIRESTORE_EMULATOR_HOST && process.env.FIREBASE_AUTH_EMULATOR_HOST,
    'Auth and Firestore emulators are required');
  const projectId = 'demo-petcare';
  const env = await initializeTestEnvironment({projectId,
    firestore: {rules: readFileSync('firestore.rules', 'utf8')}});
  const app = initializeApp({projectId}, 'cross-role');
  const admin = getFirestore(app);
  try {
    await env.clearFirestore();
    const signup = await fetch(`http://${process.env.FIREBASE_AUTH_EMULATOR_HOST}/identitytoolkit.googleapis.com/v1/accounts:signUp?key=demo-key`,
      {method: 'POST', headers: {'Content-Type': 'application/json'}, body: JSON.stringify({returnSecureToken: true})});
    const {localId: ownerId, idToken} = await signup.json();
    assert.ok(idToken);
    const entries = {
      [`users/${ownerId}`]: {role: 'owner'},
      'pets/cross-pet': {ownerId},
      'hospitals/cross-hospital': {active: true},
      'services/cross-service': {hospitalId: 'cross-hospital', duration: 30},
      'users/cross-staff': {role: 'veterinary_staff'},
      'users/cross-outsider': {role: 'veterinary_staff'},
      'hospital_staff/cross-staff': {userId: 'cross-staff', hospitalId: 'cross-hospital', active: true},
      'hospital_staff/cross-outsider': {userId: 'cross-outsider', hospitalId: 'other-hospital', active: true},
    };
    for (const suffix of ['a', 'b']) {
      entries[`users/cross-doctor-${suffix}`] = {role: 'veterinarian', vetId: `cross-vet-${suffix}`, hospitalId: 'cross-hospital'};
      entries[`veterinarians/cross-vet-${suffix}`] = {active: true, userId: `cross-doctor-${suffix}`, hospitalId: 'cross-hospital'};
    }
    await Promise.all(Object.entries(entries).map(([path, data]) => admin.doc(path).set(data)));
    const db = uid => env.authenticatedContext(uid).firestore();
    const owner = db(ownerId), staff = db('cross-staff'), outsider = db('cross-outsider');
    const dayKey = new Date(Date.now() + 330 * 60000).toISOString().slice(0, 10);
    const day = Timestamp.fromDate(new Date(`${dayKey}T00:00:00Z`));
    const invoke = async input => {
      const response = await fetch(`http://127.0.0.1:5001/${projectId}/asia-south2/reserveAppointmentSlot`,
        {method: 'POST', headers: {'Content-Type': 'application/json', Authorization: `Bearer ${idToken}`},
          body: JSON.stringify({data: input})});
      return {status: response.status, body: await response.json()};
    };
    const create = (appointmentId, time) => invoke({action: 'create', appointmentId, petId: 'cross-pet',
      hospitalId: 'cross-hospital', vetId: 'cross-vet-a', serviceId: 'cross-service',
      dateTime: `${dayKey}T${time}:00+05:30`, reason: 'Integration check'});
    assert.equal((await getDocs(query(collection(owner, 'hospitals'), where('active', '==', true)))).size, 1);
    assert.equal((await getDocs(query(collection(owner, 'veterinarians'), where('active', '==', true),
      where('hospitalId', '==', 'cross-hospital')))).size, 2);
    assert.equal((await create('cross-booking', '10:00')).status, 200);
    assert.equal((await create('cross-reject', '11:00')).status, 200);
    const appointmentRef = client => doc(client, 'appointments/cross-booking');
    const doctorQuery = (uid, vetId) => getDocs(query(collection(db(uid), 'appointments'),
      where('hospitalId', '==', 'cross-hospital'), where('vetId', '==', vetId)));
    assert.equal((await doctorQuery('cross-doctor-a', 'cross-vet-a')).size, 2);
    assert.equal((await doctorQuery('cross-doctor-b', 'cross-vet-b')).size, 0);
    await assertDenied(doctorQuery('cross-doctor-b', 'cross-vet-a'));
    await assertDenied(getDoc(appointmentRef(outsider)));
    const decision = async (id, status) => runTransaction(staff, async tx => {
      const ref = doc(staff, 'appointments', id);
      const data = (await tx.get(ref)).data();
      assert.equal(data.status, 'pending', 'stale decisions must stop before writing');
      const schedule = Object.fromEntries(['vetId', 'hospitalId', 'serviceId', 'dateTime', 'durationMinutes']
        .map(key => [key, data[key]]));
      tx.set(doc(staff, 'appointment_schedule', id), {...schedule, status});
      tx.update(ref, {status, updatedAt: serverTimestamp()});
    });
    await decision('cross-booking', 'confirmed');
    await decision('cross-reject', 'rejected');
    await assert.rejects(decision('cross-reject', 'confirmed'), /stale decisions/);
    // Obtain a real Auth emulator staff token for the reassignment callable.
    const {getAuth} = await import('firebase-admin/auth');
    await getAuth(app).createUser({uid: 'cross-staff'});
    const customToken = await getAuth(app).createCustomToken('cross-staff');
    const signIn = await fetch(`http://${process.env.FIREBASE_AUTH_EMULATOR_HOST}/identitytoolkit.googleapis.com/v1/accounts:signInWithCustomToken?key=demo-key`,
      {method: 'POST', headers: {'Content-Type': 'application/json'}, body: JSON.stringify({token: customToken, returnSecureToken: true})});
    const {idToken: staffToken} = await signIn.json();
    assert.ok(staffToken);
    const response = await fetch(`http://127.0.0.1:5001/${projectId}/asia-south2/reserveAppointmentSlot`,
      {method: 'POST', headers: {'Content-Type': 'application/json', Authorization: `Bearer ${staffToken}`},
        body: JSON.stringify({data: {action: 'reassign', appointmentId: 'cross-booking', hospitalId: 'cross-hospital', vetId: 'cross-vet-b'}})});
    assert.equal(response.status, 200, await response.text());
    assert.equal((await doctorQuery('cross-doctor-a', 'cross-vet-a')).size, 1); // rejected record remains history
    assert.equal((await doctorQuery('cross-doctor-b', 'cross-vet-b')).size, 1);
    await assertDenied(getDoc(appointmentRef(db('cross-doctor-a'))));
    const checkIn = queueId => runTransaction(staff, async tx => {
      const ref = appointmentRef(staff);
      const appointment = (await tx.get(ref)).data();
      if (appointment.queueId) throw new Error('duplicate check-in');
      const counterRef = doc(staff, `hospitals/cross-hospital/queue_days/${dayKey}`);
      const counter = await tx.get(counterRef);
      const number = counter.exists() ? counter.data().lastNumber + 1 : 1;
      tx.set(counterRef, {lastNumber: number, queueId, day, updatedAt: serverTimestamp()});
      tx.set(doc(staff, 'queue_records', queueId), {queueId, appointmentId: 'cross-booking', hospitalId: 'cross-hospital',
        ownerId, petId: 'cross-pet', veterinarianId: appointment.vetId, queueNumber: number, currentServing: 0, position: number,
        status: 'waiting', day, dayKey, createdAt: serverTimestamp(), updatedAt: serverTimestamp()});
      tx.update(ref, {queueId, updatedAt: serverTimestamp()});
    });
    const results = await Promise.allSettled([checkIn('cross-queue-a'), checkIn('cross-queue-b')]);
    assert.equal(results.filter(r => r.status === 'fulfilled').length, 1);
    assert.equal((await admin.collection('queue_records').get()).size, 1);
    const ownerRecord = (await getDoc(appointmentRef(owner))).data();
    assert.equal(ownerRecord.ownerId, ownerId);
    assert.equal(ownerRecord.vetId, 'cross-vet-b');
    assert.equal(ownerRecord.status, 'confirmed');
    for (const client of [owner, staff, db('cross-doctor-b')]) {
      const refreshed = (await getDoc(appointmentRef(client))).data();
      assert.equal(refreshed.queueId, ownerRecord.queueId);
      assert.equal(refreshed.vetId, ownerRecord.vetId);
    }
    assert.equal((await getDoc(doc(owner, 'appointment_schedule/cross-booking'))).data().vetId, 'cross-vet-b');
    const queueRef = doc(staff, 'queue_records', ownerRecord.queueId);
    await assertDenied(updateDoc(doc(outsider, 'queue_records', ownerRecord.queueId), {status: 'called', calledAt: serverTimestamp(), updatedAt: serverTimestamp()}));
    await assertDenied(updateDoc(queueRef, {status: 'completed', completedAt: serverTimestamp(), updatedAt: serverTimestamp()}));
    for (const [status, timestampField] of [['called', 'calledAt'], ['in_consultation', 'consultationStartedAt'], ['completed', 'completedAt']]) {
      await assertSucceeds(updateDoc(queueRef, {status, position: 0, [timestampField]: serverTimestamp(), updatedAt: serverTimestamp()}));
      assert.equal((await getDoc(doc(owner, 'queue_records', ownerRecord.queueId))).data().status, status);
    }
  } finally { await env.cleanup(); await deleteApp(app); }
});
