import test from 'node:test';
import assert from 'node:assert/strict';
import {initializeApp, deleteApp} from 'firebase-admin/app';
import {getFirestore} from 'firebase-admin/firestore';

test('authenticated callable transport serializes concurrent bookings and rejects anonymous callers', async () => {
  assert.ok(process.env.FIRESTORE_EMULATOR_HOST && process.env.FIREBASE_AUTH_EMULATOR_HOST,
    'Firestore and Auth emulators are required');
  const projectId = 'demo-petcare';
  const app = initializeApp({projectId}, 'callable-transport-test');
  try {
    const authHost = process.env.FIREBASE_AUTH_EMULATOR_HOST;
    const signup = await fetch(`http://${authHost}/identitytoolkit.googleapis.com/v1/accounts:signUp?key=demo-key`, {
      method: 'POST', headers: {'Content-Type': 'application/json'}, body: JSON.stringify({returnSecureToken: true})});
    const {localId: uid, idToken} = await signup.json();
    assert.ok(idToken);
    const db = getFirestore(app);
    await db.doc(`users/${uid}`).set({role: 'owner'});
    await db.doc('pets/transport-pet').set({ownerId: uid});
    await db.doc('hospitals/transport-hospital').set({active: true, hours: '8 AM - 8 PM'});
    await db.doc('users/transport-staff').set({role: 'veterinary_staff'});
    await db.doc('hospital_staff/transport-staff').set({
      userId: 'transport-staff', hospitalId: 'transport-hospital', active: true,
    });
    await db.doc('users/transport-doctor').set({role: 'veterinarian', vetId: 'transport-vet', hospitalId: 'transport-hospital'});
    await db.doc('veterinarians/transport-vet').set({active: true, userId: 'transport-doctor', hospitalId: 'transport-hospital'});
    await db.doc('services/transport-service').set({hospitalId: 'transport-hospital', duration: 30});
    const endpoint = `http://127.0.0.1:5001/${projectId}/asia-south2/reserveAppointmentSlot`;
    const payload = appointmentId => ({data: {action: 'create', appointmentId, petId: 'transport-pet',
      hospitalId: 'transport-hospital', serviceId: 'transport-service', vetId: 'transport-vet',
      dateTime: '2026-12-10T09:00:00Z', reason: 'Checkup'}});
    const invoke = (appointmentId, token) => fetch(endpoint, {method: 'POST',
      headers: {'Content-Type': 'application/json', ...(token ? {Authorization: `Bearer ${token}`} : {})},
      body: JSON.stringify(payload(appointmentId))});
    assert.equal((await invoke('transport-anonymous')).status, 401);
    const responses = await Promise.all([invoke('transport-a', idToken), invoke('transport-b', idToken)]);
    assert.deepEqual(responses.map(r => r.status).sort(), [200, 409]);
    const result = await responses.find(r => r.status === 200).json();
    assert.equal(result.result.ownerId, uid);
    assert.equal(result.result.durationMinutes, 15);
    assert.equal((await db.collection('appointments').where('hospitalId', '==', 'transport-hospital').get()).size, 1);
    assert.equal((await db.collection('appointment_schedule').where('hospitalId', '==', 'transport-hospital').get()).size, 1);
    const notices = (await db.collection('notifications').where('recipientUserId', '==', 'transport-staff').get()).docs;
    assert.equal(notices.length, 1);
    assert.equal(notices[0].data().type, 'appointment_requested');
    assert.equal(notices[0].data().targetId, result.result.appointmentId);
  } finally { await deleteApp(app); }
});
