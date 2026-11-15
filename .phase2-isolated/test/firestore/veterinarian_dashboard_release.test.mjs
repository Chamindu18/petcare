import {readFileSync} from 'node:fs';
import test from 'node:test';
import assert from 'node:assert/strict';
import {initializeTestEnvironment, assertSucceeds, assertFails} from '@firebase/rules-unit-testing';
import {doc, setDoc, getDoc, getDocs, collection, query, where, updateDoc} from 'firebase/firestore';

for (const variant of ['deployed', 'candidate']) {
  test(`${variant}: V01 assignment authorization and workflow boundaries`, async () => {
    const env = await initializeTestEnvironment({projectId: 'demo-petcare-phase2-isolated', firestore: {
      rules: readFileSync(`build/veterinarian-rules-review/${variant}.rules`, 'utf8'),
    }});
    try {
      await env.clearFirestore();
      await env.withSecurityRulesDisabled(async context => {
        const db = context.firestore();
        const records = {
          'users/doctor': {role: 'veterinarian', vetId: 'vet_001', hospitalId: 'hospital_001'},
          'veterinarians/vet_001': {userId: 'doctor', active: true, hospitalId: 'hospital_001'},
          'users/owner': {role: 'owner'},
          'users/staff': {role: 'veterinary_staff'},
          'hospital_staff/staff': {userId: 'staff', active: true, hospitalId: 'hospital_001'},
          'hospitals/hospital_001': {active: true},
          'appointments/own': {ownerId: 'owner', hospitalId: 'hospital_001', vetId: 'vet_001'},
          'appointments/other': {ownerId: 'other-owner', hospitalId: 'hospital_001', vetId: 'vet_002'},
          'appointments/foreign': {ownerId: 'other-owner', hospitalId: 'hospital_002', vetId: 'vet_001'},
          'queue_records/q': {ownerId: 'owner', hospitalId: 'hospital_001'},
        };
        for (const [path, data] of Object.entries(records)) await setDoc(doc(db, path), data);
      });
      const doctor = env.authenticatedContext('doctor').firestore();
      await assertSucceeds(getDoc(doc(doctor, 'veterinarians/vet_001')));
      await assertSucceeds(getDoc(doc(doctor, 'hospitals/hospital_001')));
      const schedule = () => getDocs(query(collection(doctor, 'appointments'),
        where('hospitalId', '==', 'hospital_001'), where('vetId', '==', 'vet_001')));
      if (variant === 'deployed') {
        await assertFails(schedule()); // Reproduce the exact live UID/directory mismatch.
      } else {
        assert.equal((await assertSucceeds(schedule())).size, 1);
        assert.equal((await assertSucceeds(schedule())).size, 1); // Refresh.
        await assertFails(getDoc(doc(doctor, 'appointments/other')));
        await assertFails(getDoc(doc(doctor, 'appointments/foreign')));
        await assertFails(getDocs(query(collection(doctor, 'appointments'), where('hospitalId', '==', 'hospital_001'))));
        await assertFails(updateDoc(doc(doctor, 'users/doctor'), {vetId: 'vet_002'}));
        await assertFails(updateDoc(doc(doctor, 'veterinarians/vet_001'), {userId: 'attacker'}));
        for (const invalid of [{active: false}, {userId: 'wrong'}, {hospitalId: 'hospital_002'}, {vetId: 'wrong'}]) {
          await env.withSecurityRulesDisabled(async context => setDoc(doc(context.firestore(), 'veterinarians/vet_001'),
            {userId: 'doctor', active: true, hospitalId: 'hospital_001', ...invalid}));
          await assertFails(schedule());
        }
      }
      const owner = env.authenticatedContext('owner').firestore();
      const staff = env.authenticatedContext('staff').firestore();
      await assertSucceeds(getDoc(doc(owner, 'appointments/own')));
      await assertFails(getDoc(doc(owner, 'appointments/other')));
      await assertSucceeds(getDoc(doc(staff, 'appointments/other')));
      await assertFails(getDoc(doc(staff, 'appointments/foreign')));
      await assertSucceeds(getDoc(doc(staff, 'queue_records/q')));
      await assertSucceeds(getDoc(doc(owner, 'queue_records/q')));
      await assertFails(getDocs(collection(env.unauthenticatedContext().firestore(), 'appointments')));
    } finally { await env.cleanup(); }
  });
}
