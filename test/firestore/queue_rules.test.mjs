import { assertDenied as assertFails } from './assert_denied.mjs';

import assert from 'node:assert/strict';
import { readFileSync } from 'node:fs';
import { fileURLToPath } from 'node:url';
import { dirname, resolve } from 'node:path';
import test, { before, beforeEach, after } from 'node:test';
import {
  initializeTestEnvironment,
  assertSucceeds,
} from '@firebase/rules-unit-testing';
import {
  doc,
  setDoc,
  updateDoc,
  deleteDoc,
  writeBatch,
  serverTimestamp,
  getDoc,
  getDocs,
  collection,
  query,
  where,
  deleteField,
  Timestamp,
  runTransaction,
} from 'firebase/firestore';

const __dirname = dirname(fileURLToPath(import.meta.url));

const projectId = 'demo-petcare';

const rules = readFileSync(
  resolve(__dirname, '../../firestore.rules'),
  'utf8',
);

let env;
const localDay = new Date(Date.now() + 330 * 60000).toISOString().slice(0, 10);
const day = Timestamp.fromDate(new Date(localDay + 'T00:00:00Z'));
function allocate(batch, db, id = 'queue-1', number = 1) {
  batch.set(doc(db, `hospitals/hospital-a/queue_days/${localDay}`), {
    lastNumber: number, queueId: id, day, updatedAt: serverTimestamp(),
  });
}


before(async () => {
  env = await initializeTestEnvironment({
    projectId,
    firestore: { rules },
  });
});

after(async () => {
  await env?.cleanup();
});

beforeEach(async () => {
  await env.clearFirestore();

  await env.withSecurityRulesDisabled(async (context) => {
    const db = context.firestore();

    await Promise.all([
      setDoc(doc(db, 'users/owner-1'), {
        uid: 'owner-1',
        role: 'owner',
      }),
      setDoc(doc(db, 'users/staff-a'), {
        uid: 'staff-a',
        role: 'veterinary_staff',
      }),
      setDoc(doc(db, 'users/staff-b'), {
        uid: 'staff-b',
        role: 'veterinary_staff',
      }),
      setDoc(doc(db, 'hospital_staff/staff-a'), {
        userId: 'staff-a',
        hospitalId: 'hospital-a',
        active: true,
      }),
      setDoc(doc(db, 'hospital_staff/staff-b'), {
        userId: 'staff-b',
        hospitalId: 'hospital-b',
        active: true,
      }),
      setDoc(doc(db, 'pets/pet-1'), {
        ownerId: 'owner-1',
        name: 'Milo',
      }),
      setDoc(doc(db, 'appointments/appointment-1'), {
        appointmentId: 'appointment-1',
        ownerId: 'owner-1',
        petId: 'pet-1',
        hospitalId: 'hospital-a',
        serviceId: 'service-a',
        vetId: 'vet-a',
        dateTime: localDay + 'T10:00:00.000',
        reason: 'Routine consultation',
        status: 'confirmed',
        createdAt: '2026-11-01T09:00:00.000Z',
      }),
    ]);
  });
});


function checkIn(db, overrides = {}, appointmentPatch = {}, id = 'queue-1') {
  const batch = writeBatch(db);
  allocate(batch, db);
  allocate(batch, db, id);
  batch.set(doc(db, 'queue_records', id), queueData({ queueId: id, ...overrides }));
  batch.update(doc(db, 'appointments/appointment-1'), {
    queueId: id, updatedAt: serverTimestamp(), ...appointmentPatch,
  });
  return batch.commit();
}

function authenticatedDb(uid) {
  return env.authenticatedContext(uid).firestore();
}

function queueData(overrides = {}) {
  return {
    queueId: 'queue-1',
    appointmentId: 'appointment-1',
    hospitalId: 'hospital-a',
    ownerId: 'owner-1',
    petId: 'pet-1',
    veterinarianId: 'vet-a',
    queueNumber: 1,
    currentServing: 0,
    position: 1,
    status: 'waiting',
    createdAt: serverTimestamp(),
    updatedAt: serverTimestamp(),
    day, dayKey: localDay,
    ...overrides,
  };
}

async function seedQueue(id = 'queue-1', overrides = {}) {
  await env.withSecurityRulesDisabled(async (context) => {
    await setDoc(
      doc(context.firestore(), `queue_records/${id}`),
      queueData({ queueId: id, ...overrides }),
    );
  });
}

test('staff can atomically create and link a valid queue entry', async () => {
  const db = authenticatedDb('staff-a');
  const batch = writeBatch(db);
  allocate(batch, db);

  batch.set(
    doc(db, 'queue_records/queue-1'),
    queueData(),
  );

  batch.update(
    doc(db, 'appointments/appointment-1'),
    {
      queueId: 'queue-1',
      updatedAt: serverTimestamp(),
    },
  );

  await assertSucceeds(batch.commit());
});

test('staff from another hospital cannot create a queue entry', async () => {
  const db = authenticatedDb('staff-b');

  await assertFails(
    setDoc(
      doc(db, 'queue_records/queue-1'),
      queueData(),
    ),
  );
});

test('queue creation rejects forged owner and pet relationships', async () => {
  const db = authenticatedDb('staff-a');

  await assertFails(
    setDoc(
      doc(db, 'queue_records/queue-1'),
      queueData({
        ownerId: 'another-owner',
        petId: 'another-pet',
      }),
    ),
  );
});

test('queue creation rejects a nonexistent appointment', async () => {
  const db = authenticatedDb('staff-a');

  await assertFails(
    setDoc(
      doc(db, 'queue_records/queue-1'),
      queueData({
        appointmentId: 'missing-appointment',
      }),
    ),
  );
});

test('queue creation requires atomic appointment linkage', async () => {
  const db = authenticatedDb('staff-a');

  await assertFails(
    setDoc(
      doc(db, 'queue_records/queue-1'),
      queueData(),
    ),
  );
});

test('queue status cannot skip directly to completed', async () => {
  await seedQueue();

  const db = authenticatedDb('staff-a');

  await assertFails(
    updateDoc(doc(db, 'queue_records/queue-1'), {
      status: 'completed',
      completedAt: serverTimestamp(),
      updatedAt: serverTimestamp(),
    }),
  );
});

test('hospital staff cannot delete queue history', async () => {
  await seedQueue();

  const db = authenticatedDb('staff-a');

  await assertFails(
    deleteDoc(doc(db, 'queue_records/queue-1')),
  );
});

test('appointment queue linkage cannot be changed independently', async () => {
  const db = authenticatedDb('staff-a');

  await assertFails(
    updateDoc(
      doc(db, 'appointments/appointment-1'),
      {
        queueId: 'nonexistent-queue',
        updatedAt: serverTimestamp(),
      },
    ),
  );
});

test('an already-linked appointment cannot enter another queue', async () => {
  await env.withSecurityRulesDisabled(async (context) => {
    const db = context.firestore();

    await updateDoc(
      doc(db, 'appointments/appointment-1'),
      { queueId: 'queue-original' },
    );

    await setDoc(
      doc(db, 'queue_records/queue-original'),
      queueData({ queueId: 'queue-original' }),
    );
  });

  const db = authenticatedDb('staff-a');

  await assertFails(
    setDoc(
      doc(db, 'queue_records/queue-duplicate'),
      queueData({
        queueId: 'queue-duplicate',
        queueNumber: 2,
      }),
    ),
  );
});


test('atomic check-in rejects each forged relationship and mixed appointment edit', async () => {
  const db = authenticatedDb('staff-a');
  for (const patch of [
    { ownerId: 'forged' }, { petId: 'forged' },
    { hospitalId: 'hospital-b' }, { appointmentId: 'missing' },
    { queueId: 'different-id' }, { status: 'completed' },
    { queueNumber: 0 }, { position: -1 }, { currentServing: 'zero' },
    { veterinarianId: 'forged' },
    { createdAt: Timestamp.fromMillis(0) },
  ]) {
    await assertFails(checkIn(db, patch));
    await env.withSecurityRulesDisabled(async context => {
      assert.equal((await getDoc(doc(context.firestore(), 'queue_records/queue-1'))).exists(), false);
      assert.equal((await getDoc(doc(context.firestore(), 'appointments/appointment-1'))).data().queueId, undefined);
    });
  }
  await assertFails(checkIn(db, {}, { reason: 'unauthorized combined edit' }));
});

test('atomic check-in requires a confirmed appointment', async () => {
  for (const status of ['pending', 'cancelled', 'rejected', 'completed']) {
    await env.withSecurityRulesDisabled(context =>
      updateDoc(doc(context.firestore(), 'appointments/appointment-1'), { status }));
    await assertFails(checkIn(authenticatedDb('staff-a')));
  }
});

test('atomic duplicate and concurrent check-ins cannot replace the first link', async () => {
  const db = authenticatedDb('staff-a');
  const results = await Promise.allSettled([
    checkIn(db), checkIn(db, {}, {}, 'queue-2'),
  ]);
  assert.equal(results.filter(result => result.status === 'fulfilled').length, 1);
  const failure = results.find(result => result.status === 'rejected').reason;
  assert.equal(failure.code, 'permission-denied');
  assert.doesNotMatch(failure.message, /1000|undefined on object|access.*limit/i);
  await assertFails(checkIn(db, {}, {}, 'queue-3'));
});

test('staff lifecycle succeeds forward and rejects reverse or terminal edits', async () => {
  const db = authenticatedDb('staff-a');
  await assertSucceeds(checkIn(db));
  const ref = doc(db, 'queue_records/queue-1');
  await assertFails(updateDoc(ref, { position: 0, updatedAt: serverTimestamp() }));
  await assertFails(updateDoc(ref, {
    currentServing: 1,
    updatedAt: serverTimestamp(),
  }));
  await assertFails(updateDoc(ref, {
    status: 'in_consultation',
    consultationStartedAt: serverTimestamp(),
    updatedAt: serverTimestamp(),
  }));
  await assertFails(updateDoc(ref, {
    status: 'called',
    updatedAt: serverTimestamp(),
  }));
  await assertSucceeds(updateDoc(ref, {
    status: 'called',
    calledAt: serverTimestamp(),
    updatedAt: serverTimestamp(),
  }));
  await assertSucceeds(updateDoc(ref, {
    status: 'in_consultation',
    consultationStartedAt: serverTimestamp(),
    updatedAt: serverTimestamp(),
  }));
  await assertFails(updateDoc(ref, { status: 'waiting', updatedAt: serverTimestamp() }));
  await assertFails(updateDoc(ref, { ownerId: 'forged', updatedAt: serverTimestamp() }));
  await assertFails(updateDoc(ref, { queueNumber: 2, updatedAt: serverTimestamp() }));
  await assertFails(updateDoc(ref, {
    status: 'completed',
    updatedAt: serverTimestamp(),
  }));
  await assertSucceeds(updateDoc(ref, {
    status: 'completed',
    completedAt: serverTimestamp(),
    updatedAt: serverTimestamp(),
  }));
  await assertFails(updateDoc(ref, { position: 1, updatedAt: serverTimestamp() }));
});

test('same-status updates cannot change queue ordering fields', async () => {
  const db = authenticatedDb('staff-a');
  await assertSucceeds(checkIn(db));
  const ref = doc(db, 'queue_records/queue-1');

  await assertFails(updateDoc(ref, { position: 0, updatedAt: serverTimestamp() }));
  await assertFails(updateDoc(ref, { currentServing: 1, updatedAt: serverTimestamp() }));

  await assertSucceeds(updateDoc(ref, {
    status: 'called',
    calledAt: serverTimestamp(),
    updatedAt: serverTimestamp(),
  }));
  await assertFails(updateDoc(ref, { position: 0, updatedAt: serverTimestamp() }));
  await assertFails(updateDoc(ref, { currentServing: 1, updatedAt: serverTimestamp() }));

  await assertSucceeds(updateDoc(ref, {
    status: 'in_consultation',
    consultationStartedAt: serverTimestamp(),
    updatedAt: serverTimestamp(),
  }));
  await assertFails(updateDoc(ref, { position: 0, updatedAt: serverTimestamp() }));
  await assertFails(updateDoc(ref, { currentServing: 1, updatedAt: serverTimestamp() }));
});

test('called and in-consultation entries can be skipped or cancelled', async () => {
  const db = authenticatedDb('staff-a');
  for (const [id, status, timestamps, next, timestampField] of [
    ['queue-called-skipped', 'called', { calledAt: Timestamp.now() }, 'skipped', 'skippedAt'],
    ['queue-called-cancelled', 'called', { calledAt: Timestamp.now() }, 'cancelled', 'cancelledAt'],
    ['queue-consultation-cancelled', 'in_consultation', { calledAt: Timestamp.now(), consultationStartedAt: Timestamp.now() }, 'cancelled', 'cancelledAt'],
  ]) {
    await seedQueue(id, { status, ...timestamps });
    await assertSucceeds(updateDoc(doc(db, `queue_records/${id}`), {
      status: next,
      [timestampField]: serverTimestamp(),
      updatedAt: serverTimestamp(),
    }));
  }
});

test('active queue entries can be skipped or cancelled but not reopened', async () => {
  const db = authenticatedDb('staff-a');
  await assertSucceeds(checkIn(db));
  const ref = doc(db, 'queue_records/queue-1');
  await assertFails(updateDoc(ref, {
    status: 'cancelled',
    updatedAt: serverTimestamp(),
  }));
  await assertSucceeds(updateDoc(ref, {
    status: 'cancelled',
    cancelledAt: serverTimestamp(),
    updatedAt: serverTimestamp(),
  }));
  await assertFails(updateDoc(ref, {
    status: 'called',
    calledAt: serverTimestamp(),
    updatedAt: serverTimestamp(),
  }));
  await assertFails(updateDoc(ref, {
    status: 'waiting',
    updatedAt: serverTimestamp(),
  }));

  await env.withSecurityRulesDisabled(async context => {
    const adminDb = context.firestore();
    await updateDoc(doc(adminDb, 'appointments/appointment-1'), {
      queueId: deleteField(),
    });
    await deleteDoc(doc(adminDb, 'queue_records/queue-1'));
    await deleteDoc(doc(adminDb, `hospitals/hospital-a/queue_days/${localDay}`));
  });
  await assertSucceeds(checkIn(db));
  await assertSucceeds(updateDoc(ref, {
    status: 'skipped',
    skippedAt: serverTimestamp(),
    updatedAt: serverTimestamp(),
  }));
  await assertFails(updateDoc(ref, {
    status: 'called',
    calledAt: serverTimestamp(),
    updatedAt: serverTimestamp(),
  }));
});

test('queue transitions reject forged or extra lifecycle timestamps', async () => {
  const db = authenticatedDb('staff-a');
  await assertSucceeds(checkIn(db));
  const ref = doc(db, 'queue_records/queue-1');
  await assertFails(updateDoc(ref, {
    status: 'called',
    calledAt: Timestamp.fromMillis(0),
    updatedAt: serverTimestamp(),
  }));
  await assertFails(updateDoc(ref, {
    status: 'called',
    calledAt: serverTimestamp(),
    completedAt: serverTimestamp(),
    updatedAt: serverTimestamp(),
  }));
  await assertSucceeds(updateDoc(ref, {
    status: 'called',
    calledAt: serverTimestamp(),
    updatedAt: serverTimestamp(),
  }));
});

test('owners and hospital users retain scoped reads and cannot cross hospitals', async () => {
  await assertSucceeds(checkIn(authenticatedDb('staff-a')));
  for (const uid of ['owner-1', 'staff-a']) {
    const db = authenticatedDb(uid);
    await assertSucceeds(getDoc(doc(db, 'queue_records/queue-1')));
    await assertSucceeds(getDocs(query(collection(db, 'queue_records'),
      where(uid === 'owner-1' ? 'ownerId' : 'hospitalId', '==',
        uid === 'owner-1' ? 'owner-1' : 'hospital-a'))));
  }
  const db = authenticatedDb('staff-b');
  await assertFails(getDoc(doc(db, 'queue_records/queue-1')));
  await assertFails(getDoc(doc(db, 'appointments/appointment-1')));
  await assertFails(getDocs(collection(authenticatedDb('staff-a'), 'queue_records')));
  await assertFails(updateDoc(doc(db, 'queue_records/queue-1'), {
    status: 'called', calledAt: serverTimestamp(), updatedAt: serverTimestamp(),
  }));
  await assertFails(checkIn(authenticatedDb('owner-1'), {}, {}, 'queue-owner'));

  const owner = authenticatedDb('owner-1');
  await assertFails(updateDoc(doc(owner, 'queue_records/queue-1'), {
    status: 'called', calledAt: serverTimestamp(), updatedAt: serverTimestamp(),
  }));
  const otherOwner = authenticatedDb('owner-2');
  await assertFails(getDoc(doc(otherOwner, 'queue_records/queue-1')));
  await assertFails(getDoc(doc(otherOwner, 'appointments/appointment-1')));
});

test('atomic check-in rejects cross-hospital and forged or inactive assignments', async () => {
  await assertFails(checkIn(authenticatedDb('staff-b')));
  for (const assignment of [
    { userId: 'someone-else', hospitalId: 'hospital-a', active: true },
    { userId: 'staff-a', hospitalId: 'hospital-a', active: false },
    { userId: 'staff-a', hospitalId: 'unassigned', active: true },
    { hospitalId: 'hospital-a' },
  ]) {
    await env.withSecurityRulesDisabled(context =>
      setDoc(doc(context.firestore(), 'hospital_staff/staff-a'), assignment));
    await assertFails(checkIn(authenticatedDb('staff-a')));
  }
});

test('malformed queue identifiers and missing fields deny without runtime limits', async () => {
  const db = authenticatedDb('staff-a');
  for (const queueId of [null, 7, '']) {
    await assertFails(updateDoc(doc(db, 'appointments/appointment-1'), {
      queueId, updatedAt: serverTimestamp(),
    }));
  }
  for (const field of ['appointmentId', 'hospitalId', 'ownerId', 'veterinarianId', 'status', 'queueNumber', 'createdAt']) {
    const data = queueData();
    delete data[field];
    await assertFails(setDoc(doc(db, 'queue_records/queue-1'), data));
  }
  for (const appointmentId of [null, 7, '']) {
    await assertFails(setDoc(doc(db, 'queue_records/queue-1'), queueData({ appointmentId })));
  }
});

test('an existing appointment queue link cannot be removed', async () => {
  const db = authenticatedDb('staff-a');
  await assertSucceeds(checkIn(db));
  await assertFails(updateDoc(doc(db, 'appointments/appointment-1'), {
    queueId: deleteField(), updatedAt: serverTimestamp(),
  }));
});

test('assigned veterinarian can atomically check in without gaining cross-hospital access', async () => {
  await env.withSecurityRulesDisabled(async context => {
    const db = context.firestore();
    await setDoc(doc(db, 'users/vet-a'), { role: 'veterinarian', hospitalId: 'hospital-a' });
    await setDoc(doc(db, 'veterinarians/vet-a'), { userId: 'vet-a', hospitalId: 'hospital-a', active: true });
  });
  await assertSucceeds(checkIn(authenticatedDb('vet-a')));
});

test('assigned veterinarian can read and update only their own queue records', async () => {
  await env.withSecurityRulesDisabled(async context => {
    const db = context.firestore();
    await setDoc(doc(db, 'users/vet-a'), { role: 'veterinarian', hospitalId: 'hospital-a' });
    await setDoc(doc(db, 'users/vet-b'), { role: 'veterinarian', hospitalId: 'hospital-a' });
    await setDoc(doc(db, 'veterinarians/vet-a'), { userId: 'vet-a', hospitalId: 'hospital-a', active: true });
    await setDoc(doc(db, 'veterinarians/vet-b'), { userId: 'vet-b', hospitalId: 'hospital-a', active: true });
    await setDoc(doc(db, 'queue_records/queue-vet-a'), queueData({
      queueId: 'queue-vet-a', veterinarianId: 'vet-a',
    }));
    await setDoc(doc(db, 'queue_records/queue-vet-b'), queueData({
      queueId: 'queue-vet-b', appointmentId: 'appointment-vet-b', veterinarianId: 'vet-b',
    }));
  });
  const db = authenticatedDb('vet-a');
  await assertSucceeds(getDoc(doc(db, 'queue_records/queue-vet-a')));
  await assertFails(getDoc(doc(db, 'queue_records/queue-vet-b')));
  await assertSucceeds(getDocs(query(collection(db, 'queue_records'),
    where('hospitalId', '==', 'hospital-a'), where('veterinarianId', '==', 'vet-a'))));
  await assertSucceeds(updateDoc(doc(db, 'queue_records/queue-vet-a'), {
    status: 'called', calledAt: serverTimestamp(), updatedAt: serverTimestamp(),
  }));
  await assertFails(updateDoc(doc(db, 'queue_records/queue-vet-b'), {
    status: 'called', calledAt: serverTimestamp(), updatedAt: serverTimestamp(),
  }));
});

async function transactionCheckIn(db, appointmentId) {
  const ref = doc(collection(db, 'queue_records'));
  const counterRef = doc(db, `hospitals/hospital-a/queue_days/${localDay}`);
  await runTransaction(db, async tx => {
    const appointmentRef = doc(db, 'appointments', appointmentId);
    const appointment = (await tx.get(appointmentRef)).data();
    if (appointment.queueId) throw new Error('duplicate');
    const counter = await tx.get(counterRef);
    const number = counter.exists() ? counter.data().lastNumber + 1 : 1;
    tx.set(counterRef, {lastNumber: number, queueId: ref.id, day, updatedAt: serverTimestamp()});
    tx.set(ref, queueData({queueId: ref.id, appointmentId, queueNumber: number, position: number}));
    tx.update(appointmentRef, {queueId: ref.id, updatedAt: serverTimestamp()});
  }, {maxAttempts: 20});
  return (await getDoc(ref)).data();
}

test('parallel transactions allocate distinct consecutive daily numbers', async () => {
  await env.withSecurityRulesDisabled(async context => {
    const db = context.firestore();
    const original = (await getDoc(doc(db, 'appointments/appointment-1'))).data();
    await Promise.all([2,3,4].map(i => setDoc(doc(db, `appointments/appointment-${i}`),
      {...original, appointmentId: `appointment-${i}`})));
  });
  const db = authenticatedDb('staff-a');
  const outcomes = await Promise.allSettled([1,2,3,4].map(i => transactionCheckIn(db, `appointment-${i}`)));
  const records = outcomes.map(result => { if (result.status === 'rejected') throw result.reason; return result.value; });
  assert.deepEqual(records.map(r => r.queueNumber).sort(), [1,2,3,4]);
  await assert.rejects(transactionCheckIn(db, 'appointment-1'), /duplicate/);
});

test('check-in rejects yesterday, tomorrow, forged day and counter-only writes atomically', async () => {
  const db = authenticatedDb('staff-a');
  for (const offset of [-1, 1]) {
    const date = new Date(day.toMillis() + offset * 86400000).toISOString().slice(0, 10);
    await env.withSecurityRulesDisabled(context => updateDoc(doc(context.firestore(), 'appointments/appointment-1'),
      {dateTime: date + 'T10:00:00.000'}));
    await assertFails(checkIn(db));
  }
  await assertFails(setDoc(doc(db, `hospitals/hospital-a/queue_days/${localDay}`),
    {lastNumber: 1, queueId: 'missing', day, updatedAt: serverTimestamp()}));
  await assertFails(checkIn(db, {day: Timestamp.fromMillis(0)}));
  assert.equal((await getDoc(doc(db, `hospitals/hospital-a/queue_days/${localDay}`))).exists(), false);
});

test('queue numbers cannot bypass or jump the allocation ledger', async () => {
  await assertFails(checkIn(authenticatedDb('staff-a'), {queueNumber: 2}));
  const db = authenticatedDb('staff-b');
  await assertFails(getDoc(doc(db, `hospitals/hospital-a/queue_days/${localDay}`)));
});

test('sequential transaction allocates and increments ledger', async () => {
 const db = authenticatedDb('staff-a');
 await transactionCheckIn(db, 'appointment-1');
 await env.withSecurityRulesDisabled(async context => {
   const other = context.firestore();
   const original = (await getDoc(doc(other, 'appointments/appointment-1'))).data();
   delete original.queueId;
   await setDoc(doc(other, 'appointments/appointment-2'), {...original, appointmentId: 'appointment-2'});
 });
 await transactionCheckIn(db, 'appointment-2');
});


test('transaction duplicates have one winner and one allocation', async () => {
  const db = authenticatedDb('staff-a');
  const outcomes = await Promise.allSettled([
    transactionCheckIn(db, 'appointment-1'), transactionCheckIn(db, 'appointment-1'),
  ]);
  assert.equal(outcomes.filter(r => r.status === 'fulfilled').length, 1);
  assert.equal((await getDoc(doc(db, `hospitals/hospital-a/queue_days/${localDay}`))).data().lastNumber, 1);
});

test('allocation is independent across hospitals and a previous day', async () => {
  await env.withSecurityRulesDisabled(async context => {
    const db = context.firestore();
    const appointment = (await getDoc(doc(db, 'appointments/appointment-1'))).data();
    await setDoc(doc(db, 'appointments/appointment-b'), {...appointment,
      appointmentId: 'appointment-b', hospitalId: 'hospital-b'});
    const previous = new Date(day.toMillis() - 86400000).toISOString().slice(0, 10);
    await setDoc(doc(db, `hospitals/hospital-a/queue_days/${previous}`), {lastNumber: 50});
  });
  await transactionCheckIn(authenticatedDb('staff-a'), 'appointment-1');
  const db = authenticatedDb('staff-b');
  const batch = writeBatch(db);
  batch.set(doc(db, `hospitals/hospital-b/queue_days/${localDay}`),
    {lastNumber: 1, queueId: 'queue-b', day, updatedAt: serverTimestamp()});
  batch.set(doc(db, 'queue_records/queue-b'), queueData({queueId: 'queue-b', appointmentId: 'appointment-b', hospitalId: 'hospital-b'}));
  batch.update(doc(db, 'appointments/appointment-b'), {queueId: 'queue-b', updatedAt: serverTimestamp()});
  await assertSucceeds(batch.commit());
});

test('legacy timestamp appointments and UTC boundary dates check in safely', async () => {
  for (const value of [Timestamp.now(),
    new Date(day.toMillis() - 330 * 60000).toISOString(),
    new Date(day.toMillis() + (24 * 60 - 330) * 60000 - 1).toISOString()]) {
    await env.withSecurityRulesDisabled(async context => {
      const db = context.firestore();
      await updateDoc(doc(db, 'appointments/appointment-1'), {dateTime: value, queueId: deleteField()});
      await deleteDoc(doc(db, 'queue_records/queue-1'));
      await deleteDoc(doc(db, `hospitals/hospital-a/queue_days/${localDay}`));
    });
    await assertSucceeds(checkIn(authenticatedDb('staff-a')));
  }
});


test('projected appointments preserve schedule and queue linkage through check-in', async () => {
  await env.withSecurityRulesDisabled(async context => {
    const db = context.firestore();
    const appointment = (await getDoc(doc(db, 'appointments/appointment-1'))).data();
    await setDoc(doc(db, 'appointment_schedule/appointment-1'), Object.fromEntries(
      ['vetId', 'hospitalId', 'serviceId', 'dateTime', 'status'].map(key => [key, appointment[key]])));
  });
  await assertSucceeds(checkIn(authenticatedDb('staff-a')));
  const owner = authenticatedDb('owner-1');
  const appointment = (await getDoc(doc(owner, 'appointments/appointment-1'))).data();
  assert.equal(appointment.queueId, 'queue-1');
  assert.equal((await getDoc(doc(owner, 'appointment_schedule/appointment-1'))).data().status, 'confirmed');
});
