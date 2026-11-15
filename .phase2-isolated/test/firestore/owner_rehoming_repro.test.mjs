import test from 'node:test';
import assert from 'node:assert/strict';
import {readFileSync} from 'node:fs';
import {initializeTestEnvironment, assertFails} from '@firebase/rules-unit-testing';
import {doc, setDoc, serverTimestamp} from 'firebase/firestore';

test('P2-01: owner of an active pet is denied a rehoming listing', async () => {
  assert.ok(process.env.FIRESTORE_EMULATOR_HOST, 'Disposable emulator required');
  const env = await initializeTestEnvironment({
    projectId: 'demo-petcare-phase2-repro',
    firestore: {rules: readFileSync('firestore.rules', 'utf8')},
  });
  try {
    await env.withSecurityRulesDisabled(async context => {
      const db = context.firestore();
      await setDoc(doc(db, 'users/owner-a'), {uid: 'owner-a', role: 'owner'});
      await setDoc(doc(db, 'pets/pet-a'), {
        petId: 'pet-a', ownerId: 'owner-a', status: 'active', name: 'Pet A',
      });
    });
    const owner = env.authenticatedContext('owner-a').firestore();
    const error = await assertFails(setDoc(doc(owner, 'adoption_listings/owner-pet-a'), {
      listingOwnerType: 'owner', listingOwnerId: 'owner-a', petId: 'pet-a',
      petName: 'Pet A', species: 'Dog', gender: 'Female',
      description: 'Rehoming listing', location: 'Colombo', status: 'available',
      createdAt: serverTimestamp(), updatedAt: serverTimestamp(),
    }));
    assert.equal(error.code, 'permission-denied');
  } finally {
    await env.cleanup();
  }
});
