import assert from 'node:assert/strict';
import { readFileSync } from 'node:fs';
import { dirname, resolve } from 'node:path';
import { fileURLToPath } from 'node:url';
import test, { after, before, beforeEach } from 'node:test';
import { assertSucceeds, initializeTestEnvironment } from '@firebase/rules-unit-testing';
import { collection, deleteDoc, doc, getDoc, getDocs, query, setDoc, updateDoc, where } from 'firebase/firestore';
import { assertDenied } from './assert_denied.mjs';

const projectId = 'demo-petcare-p31-04';
const here = dirname(fileURLToPath(import.meta.url));
const rules = readFileSync(resolve(here, '../../firestore.rules'), 'utf8');
const date = '2026-01-01T00:00:00.000Z';
const cases = [
  ['medical_conditions', 'conditionId', { name: 'Synthetic condition', status: 'active', source: 'owner-reported', diagnosisDate: date, vetId: null, notes: '' }, 'name'],
  ['vaccinations', 'vaccinationId', { name: 'Synthetic vaccine', dateGiven: date, nextDueDate: null, providerId: null, notes: '' }, 'name'],
  ['treatments', 'treatmentId', { name: 'Synthetic treatment', status: 'active', source: 'owner-reported', startDate: date, endDate: null, notes: '' }, 'name'],
  ['health_measurements', 'measurementId', { type: 'weight', value: 10, unit: 'kg', recordedAt: date }, 'value'],
];
let env;
const db = (uid) => uid ? env.authenticatedContext(uid).firestore() : env.unauthenticatedContext().firestore();
const record = (idField, fields, id = 'record-a', petId = 'pet-a') => ({
  [idField]: id, petId, ...fields, createdAt: date, updatedAt: date,
});

before(async () => {
  assert.equal(process.env.FIRESTORE_EMULATOR_HOST, '127.0.0.1:18081', 'Use only the P31-04 isolated Firestore emulator');
  env = await initializeTestEnvironment({ projectId, firestore: { rules } });
});
after(async () => env?.cleanup());
beforeEach(async () => {
  await env.clearFirestore();
  await env.withSecurityRulesDisabled(async (context) => {
    const seed = context.firestore();
    const fixtures = [
      ['users/owner-a', { uid: 'owner-a', role: 'owner' }],
      ['users/owner-b', { uid: 'owner-b', role: 'owner' }],
      ['users/provider-a', { uid: 'provider-a', role: 'adoption_provider' }],
      ['users/staff-a', { uid: 'staff-a', role: 'veterinary_staff' }],
      ['users/vet-a', { uid: 'vet-a', role: 'veterinarian', hospitalId: 'hospital-a' }],
      ['veterinarians/vet-a', { vetId: 'vet-a', userId: 'vet-a', hospitalId: 'hospital-a', active: true }],
      ['hospital_staff/staff-a', { userId: 'staff-a', hospitalId: 'hospital-a', active: true }],
      ['pets/pet-a', { petId: 'pet-a', ownerId: 'owner-a', status: 'active' }],
      ['pets/pet-b', { petId: 'pet-b', ownerId: 'owner-b', status: 'active' }],
      ['pets/pet-deleted', { petId: 'pet-deleted', ownerId: 'owner-a', status: 'deleted' }],
    ];
    for (const [path, data] of fixtures) await setDoc(doc(seed, path), data);
    for (const [name, idField, fields] of cases) {
      await setDoc(doc(seed, name, 'record-a'), record(idField, fields));
      await setDoc(doc(seed, name, 'record-deleted'), record(idField, fields, 'record-deleted', 'pet-deleted'));
      await setDoc(doc(seed, name, 'record-orphan'), record(idField, fields, 'record-orphan', 'missing-pet'));
    }
  });
});

for (const [name, idField, fields, editable] of cases) {
  const path = (id) => `${name}/${id}`;
  const changed = editable === 'value' ? 12 : 'Updated synthetic value';

  test(`${name}: owner reads, creates, updates, queries, and deletes own records`, async () => {
    const owner = db('owner-a');
    assert.equal((await assertSucceeds(getDoc(doc(owner, path('record-a'))))).exists(), true);
    const list = await assertSucceeds(getDocs(query(collection(owner, name), where('petId', '==', 'pet-a'))));
    assert.deepEqual(list.docs.map((item) => item.id), ['record-a']);
    await assertSucceeds(setDoc(doc(owner, path('created')), record(idField, fields, 'created')));
    await assertSucceeds(updateDoc(doc(owner, path('record-a')), { [editable]: changed, updatedAt: date }));
    assert.equal((await getDoc(doc(owner, path('record-a')))).data()[editable], changed);
    await assertSucceeds(deleteDoc(doc(owner, path('created'))));
  });

  test(`${name}: another owner cannot read, create for pet, update, delete, or list private records`, async () => {
    const other = db('owner-b');
    await assertDenied(getDoc(doc(other, path('record-a'))));
    await assertDenied(setDoc(doc(other, path('cross-create')), record(idField, fields, 'cross-create')));
    await assertDenied(updateDoc(doc(other, path('record-a')), { [editable]: changed }));
    await assertDenied(deleteDoc(doc(other, path('record-a'))));
    await assertDenied(getDocs(query(collection(other, name), where('petId', '==', 'pet-a'))));
    await assertDenied(setDoc(doc(other, path('record-a')), record(idField, fields, 'record-a', 'pet-b')));
  });

  test(`${name}: unauthenticated clients cannot read or write`, async () => {
    const anonymous = db();
    await assertDenied(getDoc(doc(anonymous, path('record-a'))));
    await assertDenied(setDoc(doc(anonymous, path('anonymous')), record(idField, fields, 'anonymous')));
    await assertDenied(updateDoc(doc(anonymous, path('record-a')), { [editable]: changed }));
    await assertDenied(deleteDoc(doc(anonymous, path('record-a'))));
  });

  test(`${name}: petId remains fixed and missing pets confer no access`, async () => {
    const owner = db('owner-a');
    await assertDenied(updateDoc(doc(owner, path('record-a')), { petId: 'pet-b' }));
    await assertDenied(updateDoc(doc(owner, path('record-a')), { petId: 'missing-pet' }));
    await assertDenied(setDoc(doc(owner, path('missing-create')), record(idField, fields, 'missing-create', 'missing-pet')));
    await assertDenied(getDoc(doc(owner, path('record-orphan'))));
    await assertDenied(updateDoc(doc(owner, path('record-orphan')), { [editable]: changed }));
    await assertDenied(deleteDoc(doc(owner, path('record-orphan'))));
  });

  test(`${name}: embedded identity is immutable`, async () => {
    await assertDenied(updateDoc(doc(db('owner-a'), path('record-a')), { [idField]: 'forged-id' }));
  });
  test(`${name}: embedded identity matches document path`, async () => {
    await assertDenied(setDoc(doc(db('owner-a'), path('different-path')), record(idField, fields, 'record-a')));
  });
  test(`${name}: a forged document path does not grant cross-pet access`, async () => {
    await assertDenied(setDoc(doc(db('owner-a'), path('record-b')), record(idField, fields, 'record-b', 'pet-b')));
  });
  test(`${name}: invalid create field type is rejected`, async () => {
    await assertDenied(setDoc(doc(db('owner-a'), path('wrong-type')), { ...record(idField, fields, 'wrong-type'), [editable]: { invalid: true } }));
  });
  test(`${name}: missing required create field is rejected`, async () => {
    const missing = record(idField, fields, 'missing-field');
    delete missing[editable];
    await assertDenied(setDoc(doc(db('owner-a'), path('missing-field')), missing));
  });
  test(`${name}: unexpected privileged create field is rejected`, async () => {
    await assertDenied(setDoc(doc(db('owner-a'), path('privileged-field')), { ...record(idField, fields, 'privileged-field'), isAdmin: true }));
  });
  test(`${name}: invalid update type is rejected`, async () => {
    await assertDenied(updateDoc(doc(db('owner-a'), path('record-a')), { [editable]: { invalid: true } }));
  });
  test(`${name}: unexpected privileged update field is rejected`, async () => {
    await assertDenied(updateDoc(doc(db('owner-a'), path('record-a')), { isAdmin: true }));
  });

  test(`${name}: adoption provider, hospital staff, and veterinarian cannot access raw records`, async () => {
    for (const uid of ['provider-a', 'staff-a', 'vet-a']) {
      const roleDb = db(uid);
      await assertDenied(getDoc(doc(roleDb, path('record-a'))));
      await assertDenied(setDoc(doc(roleDb, path(`${uid}-create`)), record(idField, fields, `${uid}-create`)));
      await assertDenied(updateDoc(doc(roleDb, path('record-a')), { [editable]: changed }));
      await assertDenied(deleteDoc(doc(roleDb, path('record-a'))));
    }
  });

  test(`${name}: retained records of soft-deleted pets remain readable`, async () => {
    const owner = db('owner-a');
    assert.equal((await assertSucceeds(getDoc(doc(owner, 'pets/pet-deleted')))).data().status, 'deleted');
    assert.equal((await assertSucceeds(getDoc(doc(owner, path('record-deleted'))))).exists(), true);
  });

  test(`${name}: soft-deleted pet cannot receive new health records`, async () => {
    await assertDenied(setDoc(doc(db('owner-a'), path('deleted-create')), record(idField, fields, 'deleted-create', 'pet-deleted')));
  });
  test(`${name}: soft-deleted pet records cannot be updated`, async () => {
    await assertDenied(updateDoc(doc(db('owner-a'), path('record-deleted')), { [editable]: changed }));
  });
  test(`${name}: soft-deleted pet records cannot be deleted`, async () => {
    await assertDenied(deleteDoc(doc(db('owner-a'), path('record-deleted'))));
  });
}
