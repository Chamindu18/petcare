import test from 'node:test';
import assert from 'node:assert/strict';
import {readFileSync} from 'node:fs';
import {initializeTestEnvironment, assertFails, assertSucceeds} from '@firebase/rules-unit-testing';
import {doc, getDoc, setDoc, updateDoc} from 'firebase/firestore';

test('Phase 3.1 deleted-pet and cross-owner boundaries', async () => {
  assert.ok(process.env.FIRESTORE_EMULATOR_HOST, 'Disposable emulator required');
  const env = await initializeTestEnvironment({
    projectId: 'demo-petcare-phase31-probe',
    firestore: {rules: readFileSync('firestore.rules', 'utf8')},
  });
  try {
    await env.withSecurityRulesDisabled(async context => {
      const db = context.firestore();
      await setDoc(doc(db, 'users/owner-a'), {uid: 'owner-a', role: 'owner'});
      await setDoc(doc(db, 'users/owner-b'), {uid: 'owner-b', role: 'owner'});
      await setDoc(doc(db, 'pets/pet-a'), {
        petId: 'pet-a', ownerId: 'owner-a', status: 'deleted',
        name: 'Synthetic A', species: 'Dog', breed: '', dob: '2020-01-01T00:00:00.000',
        gender: 'female', weight: 10, imageUrl: '', notes: '',
      });
    });
    const ownerA = env.authenticatedContext('owner-a').firestore();
    const ownerB = env.authenticatedContext('owner-b').firestore();
    await assertFails(getDoc(doc(ownerB, 'pets/pet-a')));
    await assertFails(updateDoc(doc(ownerB, 'pets/pet-a'), {status: 'active'}));
    await assertFails(setDoc(doc(ownerB, 'pets/forged-b'), {
      petId: 'forged-b', ownerId: 'owner-a', status: 'active',
    }));
    await assertSucceeds(setDoc(doc(ownerA, 'medical_conditions/deleted-pet-record'), {
      petId: 'pet-a', name: 'Synthetic condition',
    }));
    await assertSucceeds(updateDoc(doc(ownerA, 'pets/pet-a'), {status: 'active'}));
    assert.equal((await getDoc(doc(ownerA, 'pets/pet-a'))).data().status, 'active');
  } finally {
    await env.cleanup();
  }
});
