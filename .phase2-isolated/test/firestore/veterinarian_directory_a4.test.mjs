import test, { before, beforeEach, after } from 'node:test';
import { readFileSync } from 'node:fs';
import { initializeTestEnvironment, assertFails, assertSucceeds } from '@firebase/rules-unit-testing';
import { collection, deleteDoc, deleteField, doc, getDoc, getDocs, query, setDoc, updateDoc, where, serverTimestamp } from 'firebase/firestore';

const projectId = 'demo-petcare-phase2-isolated-a4-isolated';
const rules = readFileSync(new URL('../../firestore.rules', import.meta.url), 'utf8');
let env;
const assigned = { vetId: 'directory-vet', userId: 'vet', hospitalId: 'hospital-a', active: true, name: 'Dr. Vet', profileImageUrl: '', specialty: 'General', qualifications: 'BVSc', experienceYears: 5, bio: 'Veterinarian' };
const unassigned = { userId: 'unassigned-vet', hospitalId: 'unassigned', active: false, name: 'Dr. New' };
const db = uid => uid ? env.authenticatedContext(uid).firestore() : env.unauthenticatedContext().firestore();
const vet = (database, id) => doc(database, 'veterinarians', id);

before(async () => {
  env = await initializeTestEnvironment({ projectId, firestore: { rules } });
});
after(async () => { await env?.cleanup(); });
beforeEach(async () => {
  await env.clearFirestore();
  await env.withSecurityRulesDisabled(async context => {
    const admin = context.firestore();
    await Promise.all([
      setDoc(doc(admin, 'users/owner'), { role: 'owner' }),
      setDoc(doc(admin, 'users/provider'), { role: 'adoption_provider' }),
      setDoc(doc(admin, 'users/staff'), { role: 'veterinary_staff', hospitalId: 'hospital-a' }),
      setDoc(doc(admin, 'users/vet'), { role: 'veterinarian', vetId: 'directory-vet', hospitalId: 'hospital-a' }),
      setDoc(doc(admin, 'users/legacy-vet'), { role: 'veterinarian', hospitalId: 'hospital-a' }),
      setDoc(doc(admin, 'users/unassigned-vet'), { role: 'veterinarian' }),
      setDoc(doc(admin, 'users/new-vet'), { role: 'veterinarian' }),
      setDoc(vet(admin, 'directory-vet'), assigned),
      setDoc(vet(admin, 'legacy-vet'), { userId: 'legacy-vet', hospitalId: 'hospital-a', active: true, fullName: 'Dr. Legacy', role: 'veterinarian' }),
      setDoc(vet(admin, 'unassigned-vet'), unassigned),
    ]);
  });
});

test('only trusted provisioning can create directory records, including UID keyed unassigned records', async () => {
  await assertFails(setDoc(vet(db('owner'), 'owner'), { ...unassigned, userId: 'owner' }));
  await assertFails(setDoc(vet(db('provider'), 'provider'), { ...unassigned, userId: 'provider' }));
  await assertFails(setDoc(vet(db('staff'), 'staff'), { ...unassigned, userId: 'staff' }));
  await assertFails(setDoc(vet(db('unassigned-vet'), 'another-vet'), { ...unassigned, userId: 'unassigned-vet' }));
  await assertFails(setDoc(vet(db('unassigned-vet'), 'self-new'), { ...unassigned, userId: 'unassigned-vet', active: true, hospitalId: 'hospital-a' }));
  await assertFails(setDoc(vet(db('unassigned-vet'), 'unassigned-vet-new'), { ...unassigned, userId: 'unassigned-vet', role: 'admin' }));
  await assertFails(setDoc(vet(db('new-vet'), 'new-vet'), { ...unassigned, userId: 'new-vet' }));
  await assertFails(setDoc(vet(db(), 'anonymous'), unassigned));
});

test('self creation cannot inject privileged, malformed, or oversized values', async () => {
  const database = db('new-vet');
  await assertFails(setDoc(vet(database, 'new-vet'), { ...unassigned, userId: 'new-vet', role: 'admin', approval: true }));
  await assertFails(setDoc(vet(database, 'new-vet'), { ...unassigned, userId: 'new-vet', name: 7 }));
  await assertFails(setDoc(vet(database, 'new-vet'), { ...unassigned, userId: 'new-vet', bio: 'x'.repeat(5000) }));
});

test('client deletion of UID keyed assigned, inactive, and unassigned records is denied', async () => {
  await assertFails(deleteDoc(vet(db('legacy-vet'), 'legacy-vet')));
  await assertFails(deleteDoc(vet(db('unassigned-vet'), 'unassigned-vet')));
  await assertFails(deleteDoc(vet(db('provider'), 'directory-vet')));
  await assertFails(deleteDoc(vet(db(), 'directory-vet')));
});

test('other roles cannot edit a veterinarian record', async () => {
  for (const uid of ['owner', 'provider', 'staff']) {
    await assertFails(updateDoc(vet(db(uid), 'directory-vet'), { name: 'Forged' }));
  }
});

test('veterinarian cannot edit identity, assignment, approval, or arbitrary fields', async () => {
  const ref = vet(db('vet'), 'directory-vet');
  for (const change of [{ userId: 'other' }, { vetId: 'other' }, { hospitalId: 'hospital-b' }, { active: false }, { role: 'admin' }, { approved: true }]) {
    await assertFails(updateDoc(ref, change));
  }
  await assertFails(updateDoc(ref, { userId: null }));
  await assertFails(updateDoc(ref, { hospitalId: null }));
  await assertFails(updateDoc(vet(db(), 'directory-vet'), { name: 'Anonymous' }));
});

test('veterinarian profile updates require valid values and preserve required fields', async () => {
  const ref = vet(db('vet'), 'directory-vet');
  for (const change of [{ name: null }, { name: '' }, { name: 7 }, { name: 'x'.repeat(300) }, { bio: 'x'.repeat(5000) }, { specialty: [] }, { experienceYears: -1 }, { experienceYears: 'five' }, { profileImageUrl: false }, { updatedAt: 'yesterday' }]) {
    await assertFails(updateDoc(ref, change));
  }
  await assertFails(updateDoc(ref, { name: deleteField() }));
});

test('authorized reads, discovery, profile edits, legacy and unassigned records remain usable', async () => {
  await assertSucceeds(getDoc(vet(db('vet'), 'directory-vet')));
  await assertSucceeds(getDocs(query(collection(db('owner'), 'veterinarians'), where('active', '==', true))));
  await assertSucceeds(getDocs(query(collection(db('owner'), 'veterinarians'), where('hospitalId', '==', 'hospital-a'), where('active', '==', true))));
  await assertSucceeds(updateDoc(vet(db('vet'), 'directory-vet'), { name: 'Dr. Updated', specialty: null, profileImageUrl: null, updatedAt: serverTimestamp() }));
  await assertSucceeds(updateDoc(vet(db('legacy-vet'), 'legacy-vet'), { fullName: 'Dr. Legacy Updated', updatedAt: serverTimestamp() }));
  await assertSucceeds(updateDoc(vet(db('unassigned-vet'), 'unassigned-vet'), { bio: 'Preparing profile', updatedAt: serverTimestamp() }));
  await assertFails(getDoc(vet(db(), 'directory-vet')));
});
