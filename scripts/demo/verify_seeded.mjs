import {initializeTestEnvironment} from '@firebase/rules-unit-testing';
import {getDoc, doc, getDocs, collection, query, where} from 'firebase/firestore';

const projectId = 'demo-petcare';
if (process.env.GCLOUD_PROJECT && process.env.GCLOUD_PROJECT !== projectId) throw new Error('Wrong project.');
if (process.env.FIRESTORE_EMULATOR_HOST && process.env.FIRESTORE_EMULATOR_HOST !== '127.0.0.1:8080') throw new Error('Wrong Firestore endpoint.');
const env = await initializeTestEnvironment({projectId, firestore: {host: '127.0.0.1', port: 8080}});
const db = uid => env.authenticatedContext(uid).firestore();
const read = async (uid, path, allowed) => {
  let result;
  try { result = await getDoc(doc(db(uid), path)); }
  catch (error) {
    if (!allowed && error.code === 'permission-denied') return;
    throw new Error(`${uid} ${path}: ${error.message}`);
  }
  if (!allowed || !result.exists()) throw new Error(`${uid} ${path}: unexpected result`);
};
try {
  if (process.env.PETCARE_DEMO_PASSWORD) {
    for (const [uid, email, role] of [
      ['demo-owner', 'owner.demo@petcare.test', 'owner'], ['demo-owner-two', 'owner.two.demo@petcare.test', 'owner'],
      ['demo-staff', 'staff.demo@petcare.test', 'veterinary_staff'], ['demo-doctor-a', 'vet.a.demo@petcare.test', 'veterinarian'],
      ['demo-doctor-b', 'vet.b.demo@petcare.test', 'veterinarian'], ['demo-provider', 'provider.demo@petcare.test', 'adoption_provider'],
    ]) {
      const response = await fetch('http://127.0.0.1:9099/identitytoolkit.googleapis.com/v1/accounts:signInWithPassword?key=demo-key', {
        method: 'POST', headers: {'Content-Type': 'application/json'},
        body: JSON.stringify({email, password: process.env.PETCARE_DEMO_PASSWORD, returnSecureToken: true}),
      });
      const result = await response.json();
      if (!response.ok || result.localId !== uid || !result.idToken) throw new Error(`Auth sign-in failed for ${email}`);
      const profile = await getDoc(doc(db(uid), `users/${uid}`));
      if (profile.data()?.role !== role || profile.data()?.email !== email) throw new Error(`Auth/profile mismatch for ${email}`);
    }
  }
  for (const [uid, path, allowed] of [
    ['demo-owner', 'pets/demo-pet', true],
    ['demo-owner-two', 'pets/demo-pet', false],
    ['demo-owner', 'pets/demo-other-pet', false],
    ['demo-owner', 'medical_conditions/demo-condition', true],
    ['demo-owner-two', 'medical_conditions/demo-condition', false],
    ['demo-owner', 'appointments/demo-passport-ready', true],
    ['demo-owner-two', 'appointments/demo-passport-ready', false],
    ['demo-staff', 'appointments/demo-queue-ready', true],
    ['demo-doctor-a', 'appointments/demo-queue-ready', true],
    ['demo-doctor-b', 'appointments/demo-queue-ready', false],
    ['demo-owner', 'queue_records/demo-queue', true],
    ['demo-staff', 'queue_records/demo-queue', true],
    ['demo-doctor-a', 'queue_records/demo-queue', true],
    ['demo-doctor-b', 'queue_records/demo-queue', false],
    ['demo-provider', 'adoption_requests/demo-provider-listing_demo-owner', true],
    ['demo-owner', 'adoption_requests/demo-provider-listing_demo-owner', true],
    ['demo-owner-two', 'adoption_requests/demo-provider-listing_demo-owner', false],
    ['demo-provider', 'adoption_listings/demo-provider-draft', true],
    ['demo-owner', 'adoption_listings/demo-provider-draft', false],
    ['demo-provider', 'notifications/adoption_request_submitted_demo-provider-listing_demo-owner', true],
    ['demo-owner', 'notifications/adoption_request_submitted_demo-provider-listing_demo-owner', false],
    ['demo-staff', 'notifications/demo-staff-notification', true],
    ['demo-doctor-a', 'notifications/demo-vet-notification', true],
    ['demo-doctor-b', 'notifications/demo-vet-notification', false],
  ]) await read(uid, path, allowed);
  for (const [uid, collectionName, field, value, count] of [
    ['demo-owner', 'pets', 'ownerId', 'demo-owner', 2],
    ['demo-owner-two', 'pets', 'ownerId', 'demo-owner-two', 1],
    ['demo-provider', 'adoption_requests', 'recipientId', 'demo-provider', 1],
    ['demo-owner', 'notifications', 'recipientUserId', 'demo-owner', 1],
  ]) {
    const constraints = [where(field, '==', value)];
    if (collectionName === 'adoption_requests') constraints.push(where('recipientType', '==', 'adoption_provider'));
    const snapshot = await getDocs(query(collection(db(uid), collectionName), ...constraints));
    if (snapshot.size !== count) throw new Error(`${uid} ${collectionName}: expected ${count}, got ${snapshot.size}`);
  }
  const passportAppointment = (await getDoc(doc(db('demo-owner'), 'appointments/demo-passport-ready'))).data();
  if (passportAppointment?.status !== 'confirmed' || passportAppointment.ownerId !== 'demo-owner' ||
      passportAppointment.petId !== 'demo-pet' || new Date(passportAppointment.dateTime) <= new Date()) {
    throw new Error('Seeded QR appointment is not eligible.');
  }
  for (const name of ['medical_conditions', 'vaccinations', 'treatments', 'health_measurements']) {
    const records = await getDocs(query(collection(db('demo-owner'), name), where('petId', '==', 'demo-pet')));
    if (records.empty) throw new Error(`QR health projection has no ${name}.`);
  }
  console.log('Seeded Auth sign-ins (when password supplied), Firestore role reads, and protected-record denials passed.');
} finally {
  await env.cleanup();
}
