import { assertDenied as assertFails } from './assert_denied.mjs';
import assert from 'node:assert/strict';
import { readFileSync } from 'node:fs';
import { fileURLToPath } from 'node:url';
import { dirname, resolve } from 'node:path';
import test, { before, beforeEach, after } from 'node:test';
import { initializeTestEnvironment, assertSucceeds } from '@firebase/rules-unit-testing';
import { doc, getDoc, setDoc, updateDoc, writeBatch, serverTimestamp, Timestamp } from 'firebase/firestore';

const rules = readFileSync(resolve(dirname(fileURLToPath(import.meta.url)), '../../firestore.rules'), 'utf8');
let env;
before(async () => { env = await initializeTestEnvironment({ projectId: 'demo-petcare', firestore: { rules } }); });
after(async () => { await env?.cleanup(); });
beforeEach(async () => {
  await env.clearFirestore();
  await env.withSecurityRulesDisabled(async (context) => {
    const db = context.firestore();
    await Promise.all([
      setDoc(doc(db, 'users/owner-1'), { uid: 'owner-1', role: 'owner' }),
      setDoc(doc(db, 'users/owner-2'), { uid: 'owner-2', role: 'owner' }),
      setDoc(doc(db, 'users/staff-a'), { uid: 'staff-a', role: 'veterinary_staff' }),
      setDoc(doc(db, 'users/vet-a'), { uid: 'vet-a', role: 'veterinarian', hospitalId: 'hospital-a' }),
      setDoc(doc(db, 'veterinarians/vet-a'), { userId: 'vet-a', hospitalId: 'hospital-a', active: true }),
      setDoc(doc(db, 'hospital_staff/staff-a'), { userId: 'staff-a', hospitalId: 'hospital-a', active: true }),
      setDoc(doc(db, 'users/provider-1'), { uid: 'provider-1', role: 'adoption_provider' }),
      setDoc(doc(db, 'pets/pet-1'), { ownerId: 'owner-1', name: 'Milo' }),
      setDoc(doc(db, 'appointments/appointment-1'), {
        ownerId: 'owner-1', petId: 'pet-1', hospitalId: 'hospital-a', serviceId: 'service-a',
        vetId: 'vet-a', dateTime: Timestamp.fromDate(new Date('2026-11-10T08:30:00Z')),
        reason: 'Checkup', status: 'pending', createdAt: Timestamp.fromDate(new Date('2026-10-01T10:00:00Z')),
        updatedAt: Timestamp.fromDate(new Date('2026-10-01T10:00:00Z')),
      }),
      setDoc(doc(db, 'adoption_listings/listing-1'), {
        listingOwnerType: 'adoption_provider', listingOwnerId: 'provider-1', providerId: 'provider-1',
        petName: 'Buddy', species: 'Dog', gender: 'Male', description: 'Friendly', location: 'Colombo',
        status: 'available', createdAt: Timestamp.fromDate(new Date('2026-10-01T10:00:00Z')),
        updatedAt: Timestamp.fromDate(new Date('2026-10-01T10:00:00Z')),
      }),
      setDoc(doc(db, 'adoption_requests/request-1'), {
        listingId: 'listing-1', requesterId: 'owner-1', recipientId: 'provider-1',
        recipientType: 'adoption_provider', providerId: 'provider-1', status: 'pending',
        submittedAt: Timestamp.fromDate(new Date('2026-10-02T10:00:00Z')),
        updatedAt: Timestamp.fromDate(new Date('2026-10-02T10:00:00Z')),
      }),
    ]);
  });
});

const dbFor = (uid) => env.authenticatedContext(uid).firestore();
function notification(type, recipientUserId, targetType, targetId, message) {
  return { recipientUserId, type, message, read: false, targetType, targetId,
    ...(targetType === 'appointment' ? {appointmentTime: Timestamp.fromDate(new Date('2026-11-10T08:30:00Z'))} : {}),
    ...(targetType === 'queue' ? {queueNumber: 4} : {}),
    ...(targetType === 'adoption_request' ? {listingName: 'Buddy'} : {}),
    createdAt: serverTimestamp() };
}

test('confirmation is atomic, owner scoped, and cannot be replayed', async () => {
  const db = dbFor('staff-a');
  const batch = writeBatch(db);
  batch.update(doc(db, 'appointments/appointment-1'), { status: 'confirmed', updatedAt: serverTimestamp() });
  batch.set(doc(db, 'notifications/appointment_confirmed_appointment-1'),
    notification('appointment_confirmed', 'owner-1', 'appointment', 'appointment-1', 'Your appointment was confirmed.'));
  await assertSucceeds(batch.commit());
  assert.equal((await getDoc(doc(dbFor('owner-1'), 'notifications/appointment_confirmed_appointment-1'))).data()?.read, false);
  await assertFails(setDoc(doc(db, 'notifications/appointment_confirmed_appointment-1'),
    notification('appointment_confirmed', 'owner-1', 'appointment', 'appointment-1', 'Your appointment was confirmed.')));
  await assertFails(getDoc(doc(dbFor('owner-2'), 'notifications/appointment_confirmed_appointment-1')));
});

test('rejection succeeds; failed transition creates no notification', async () => {
  const db = dbFor('staff-a');
  const wrong = writeBatch(db);
  wrong.update(doc(db, 'appointments/appointment-1'), { status: 'confirmed', updatedAt: serverTimestamp() });
  wrong.set(doc(db, 'notifications/appointment_rejected_appointment-1'),
    notification('appointment_rejected', 'owner-1', 'appointment', 'appointment-1', 'Your appointment was rejected.'));
  await assertFails(wrong.commit());
  const good = writeBatch(db);
  good.update(doc(db, 'appointments/appointment-1'), { status: 'rejected', updatedAt: serverTimestamp() });
  good.set(doc(db, 'notifications/appointment_rejected_appointment-1'),
    notification('appointment_rejected', 'owner-1', 'appointment', 'appointment-1', 'Your appointment was rejected.'));
  await assertSucceeds(good.commit());
});

test('owner cannot forge a decision notification for another owner', async () => {
  const db = dbFor('owner-2');
  await assertFails(setDoc(doc(db, 'notifications/appointment_confirmed_appointment-1'),
    notification('appointment_confirmed', 'owner-1', 'appointment', 'appointment-1', 'Your appointment was confirmed.')));
});

test('staff cannot forge appointment time or recipient in an atomic decision', async () => {
  const db = dbFor('staff-a');
  const batch = writeBatch(db);
  batch.update(doc(db, 'appointments/appointment-1'), {
    status: 'confirmed', updatedAt: serverTimestamp(),
  });
  batch.set(doc(db, 'notifications/appointment_confirmed_appointment-1'), {
    ...notification('appointment_confirmed', 'owner-2', 'appointment',
      'appointment-1', 'Your appointment was confirmed.'),
    appointmentTime: Timestamp.fromDate(new Date('2026-12-10T08:30:00Z')),
  });
  await assertFails(batch.commit());
  assert.equal((await getDoc(doc(db, 'appointments/appointment-1'))).data()?.status, 'pending');
});

test('provider rejection notifies only the applicant', async () => {
  const db = dbFor('provider-1');
  const batch = writeBatch(db);
  batch.update(doc(db, 'adoption_requests/request-1'), {
    status: 'rejected', closedAt: serverTimestamp(), updatedAt: serverTimestamp(),
  });
  batch.set(doc(db, 'notifications/adoption_rejected_request-1'),
    notification('adoption_rejected', 'owner-1', 'adoption_request', 'request-1', 'Your adoption request was rejected.'));
  await assertSucceeds(batch.commit());
  assert.equal((await getDoc(doc(dbFor('owner-1'), 'notifications/adoption_rejected_request-1'))).data()?.recipientUserId, 'owner-1');
  await assertFails(getDoc(doc(dbFor('owner-2'), 'notifications/adoption_rejected_request-1')));
});

test('provider acceptance notifies only the applicant', async () => {
  const db = dbFor('provider-1');
  const batch = writeBatch(db);
  batch.update(doc(db, 'adoption_listings/listing-1'), {
    status: 'reserved', acceptedRequestId: 'request-1', updatedAt: serverTimestamp(),
  });
  batch.update(doc(db, 'adoption_requests/request-1'), {
    status: 'accepted', acceptedAt: serverTimestamp(), updatedAt: serverTimestamp(),
  });
  batch.set(doc(db, 'notifications/adoption_accepted_request-1'),
    notification('adoption_accepted', 'owner-1', 'adoption_request', 'request-1', 'Your adoption request was accepted.'));
  await assertSucceeds(batch.commit());
  assert.equal((await getDoc(doc(dbFor('owner-1'), 'notifications/adoption_accepted_request-1'))).data()?.recipientUserId, 'owner-1');
});

test('queue transitions notify only their owner at each lifecycle step', async () => {
  await env.withSecurityRulesDisabled(async (context) => {
    await setDoc(doc(context.firestore(), 'queue_records/queue-1'), {
      queueId: 'queue-1', appointmentId: 'appointment-1', hospitalId: 'hospital-a',
      ownerId: 'owner-1', petId: 'pet-1', queueNumber: 4, currentServing: 0,
      position: 4, status: 'waiting', updatedAt: Timestamp.fromDate(new Date('2026-10-02T10:00:00Z')),
      day: Timestamp.fromDate(new Date('2026-11-06T00:00:00Z')), dayKey: '2026-11-06',
    });
  });
  const db = dbFor('staff-a');
  const called = writeBatch(db);
  called.update(doc(db, 'queue_records/queue-1'), {
    status: 'called', calledAt: serverTimestamp(), position: 0, updatedAt: serverTimestamp(),
  });
  called.set(doc(db, 'notifications/queue_called_queue-1'),
    notification('queue_called', 'owner-1', 'queue', 'queue-1',
      'Your pet has been called to the consultation room.'));
  await assertSucceeds(called.commit());
  assert.equal((await getDoc(doc(dbFor('owner-1'), 'notifications/queue_called_queue-1'))).data()?.recipientUserId, 'owner-1');
  await assertFails(getDoc(doc(dbFor('owner-2'), 'notifications/queue_called_queue-1')));

  const start = writeBatch(db);
  start.update(doc(db, 'queue_records/queue-1'), {
    status: 'in_consultation', consultationStartedAt: serverTimestamp(),
    position: 0, updatedAt: serverTimestamp(),
  });
  start.set(doc(db, 'notifications/queue_in_consultation_queue-1'),
    notification('queue_in_consultation', 'owner-1', 'queue', 'queue-1', "Your pet's consultation has begun."));
  await assertSucceeds(start.commit());

  const complete = writeBatch(db);
  complete.update(doc(db, 'queue_records/queue-1'), {
    status: 'completed', completedAt: serverTimestamp(),
    position: 0, updatedAt: serverTimestamp(),
  });
  complete.set(doc(db, 'notifications/queue_completed_queue-1'),
    notification('queue_completed', 'owner-1', 'queue', 'queue-1', "Your pet's consultation is complete."));
  await assertSucceeds(complete.commit());
});

test('queue skip and cancel notifications match their transitions', async () => {
  await env.withSecurityRulesDisabled(async (context) => {
    const db = context.firestore();
    for (const id of ['queue-skip', 'queue-cancel']) {
      await setDoc(doc(db, `queue_records/${id}`), {
        queueId: id, appointmentId: 'appointment-1', hospitalId: 'hospital-a',
        ownerId: 'owner-1', petId: 'pet-1', queueNumber: 4, currentServing: 0,
        position: 4, status: 'waiting', updatedAt: Timestamp.fromDate(new Date('2026-10-02T10:00:00Z')),
        day: Timestamp.fromDate(new Date('2026-11-06T00:00:00Z')), dayKey: '2026-11-06',
      });
    }
  });
  const db = dbFor('staff-a');
  const skip = writeBatch(db);
  skip.update(doc(db, 'queue_records/queue-skip'), {
    status: 'skipped', skippedAt: serverTimestamp(), position: 0, updatedAt: serverTimestamp(),
  });
  skip.set(doc(db, 'notifications/queue_skipped_queue-skip'),
    notification('queue_skipped', 'owner-1', 'queue', 'queue-skip',
      'Your pet was skipped in the queue.'));
  await assertSucceeds(skip.commit());

  const cancel = writeBatch(db);
  cancel.update(doc(db, 'queue_records/queue-cancel'), {
    status: 'cancelled', cancelledAt: serverTimestamp(), position: 0, updatedAt: serverTimestamp(),
  });
  cancel.set(doc(db, 'notifications/queue_cancelled_queue-cancel'),
    notification('queue_cancelled', 'owner-1', 'queue', 'queue-cancel',
      "Your pet's queue entry was cancelled."));
  await assertSucceeds(cancel.commit());
});

test('atomic check-in creates the waiting notification', async () => {
  const localDay = new Date(Date.now() + 330 * 60000).toISOString().slice(0, 10);
  const day = Timestamp.fromDate(new Date(`${localDay}T00:00:00Z`));
  await env.withSecurityRulesDisabled(async (context) => {
    await updateDoc(doc(context.firestore(), 'appointments/appointment-1'), {
      status: 'confirmed', dateTime: `${localDay}T10:00:00.000`,
    });
  });
  const db = dbFor('staff-a');
  const batch = writeBatch(db);
  batch.set(doc(db, `hospitals/hospital-a/queue_days/${localDay}`), {
    lastNumber: 1, queueId: 'queue-1', day, updatedAt: serverTimestamp(),
  });
  batch.set(doc(db, 'queue_records/queue-1'), {
    queueId: 'queue-1', appointmentId: 'appointment-1', hospitalId: 'hospital-a',
    ownerId: 'owner-1', petId: 'pet-1', veterinarianId: 'vet-a', queueNumber: 1,
    currentServing: 0, position: 1, status: 'waiting', createdAt: serverTimestamp(),
    updatedAt: serverTimestamp(), day, dayKey: localDay,
  });
  batch.update(doc(db, 'appointments/appointment-1'), {
    queueId: 'queue-1', updatedAt: serverTimestamp(),
  });
  batch.set(doc(db, 'notifications/queue_checked_in_queue-1'), {
    ...notification('queue_checked_in', 'owner-1', 'queue', 'queue-1',
      'Your pet was checked in to the queue.'),
    queueNumber: 1,
  });
  await assertSucceeds(batch.commit());
  assert.equal((await getDoc(doc(dbFor('owner-1'), 'notifications/queue_checked_in_queue-1'))).data()?.queueNumber, 1);
});
