import test from 'node:test';
import assert from 'node:assert/strict';
import {readFileSync} from 'node:fs';
import {initializeTestEnvironment} from '@firebase/rules-unit-testing';
import {doc, setDoc, collection, getDocs, writeBatch} from 'firebase/firestore';

test('two stale client availability reads cannot bypass the trusted scheduler', async () => {
  const env = await initializeTestEnvironment({projectId: 'demo-petcare', firestore: {rules: readFileSync('firestore.rules', 'utf8')}});
  try {
    await env.clearFirestore();
    await env.withSecurityRulesDisabled(async c => {
      const db = c.firestore();
      for (const uid of ['owner-a', 'owner-b']) {
        await setDoc(doc(db, 'users', uid), {role: 'owner'});
        await setDoc(doc(db, 'pets', uid), {ownerId: uid});
      }
      await setDoc(doc(db, 'users/doctor'), {role: 'veterinarian', vetId: 'vet-a', hospitalId: 'hospital-a'});
      await setDoc(doc(db, 'veterinarians/vet-a'), {vetId: 'vet-a', userId: 'doctor', hospitalId: 'hospital-a', active: true});
    });
    const clients = ['owner-a', 'owner-b'].map(uid => env.authenticatedContext(uid).firestore());
    // Barrier: both requests finish their advisory availability read before either commits.
    const reads = await Promise.all(clients.map(db => getDocs(collection(db, 'appointment_schedule'))));
    assert.deepEqual(reads.map(s => s.size), [0, 0]);
    const results = await Promise.allSettled(clients.map((db, i) => {
      const data = {ownerId: `owner-${i ? 'b' : 'a'}`, petId: `owner-${i ? 'b' : 'a'}`,
        hospitalId: 'hospital-a', vetId: 'vet-a', serviceId: 'service',
        dateTime: '2026-11-10T09:00:00Z', createdAt: '2026-11-04T09:00:00Z', status: 'pending', reason: 'Checkup'};
      const batch = writeBatch(db);
      batch.set(doc(db, 'appointments', `race-${i}`), data);
      batch.set(doc(db, 'appointment_schedule', `race-${i}`), Object.fromEntries(
        ['vetId', 'hospitalId', 'serviceId', 'dateTime', 'status'].map(k => [k, data[k]])));
      return batch.commit();
    }));
    assert.equal(results.filter(r => r.status === 'fulfilled').length, 0);
    await env.withSecurityRulesDisabled(async c => {
      assert.equal((await getDocs(collection(c.firestore(), 'appointments'))).size, 0);
      assert.equal((await getDocs(collection(c.firestore(), 'appointment_schedule'))).size, 0);
    });
  } finally { await env.cleanup(); }
});
