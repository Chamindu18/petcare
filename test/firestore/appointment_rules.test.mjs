import { readFileSync } from 'node:fs';
import { fileURLToPath } from 'node:url';
import { dirname, resolve } from 'node:path';
import test, { before, beforeEach, after } from 'node:test';
import assert from 'node:assert/strict';
import {
  initializeTestEnvironment,
  assertSucceeds,
  assertFails,
} from '@firebase/rules-unit-testing';
import {
  doc,
  setDoc,
  updateDoc,
  serverTimestamp,
  Timestamp,
} from 'firebase/firestore';

const __dirname = dirname(fileURLToPath(import.meta.url));
const projectId = 'demo-petcare';
const rules = readFileSync(
  resolve(__dirname, '../../firestore.rules'),
  'utf8',
);

const CREATED_AT = Timestamp.fromDate(
  new Date('2026-10-01T10:00:00.000Z'),
);
const APPOINTMENT_DATE = Timestamp.fromDate(
  new Date('2026-11-10T08:30:00.000Z'),
);

let env;

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
      setDoc(doc(db, 'users/owner-2'), {
        uid: 'owner-2',
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
      setDoc(doc(db, 'users/staff-inactive'), {
        uid: 'staff-inactive',
        role: 'veterinary_staff',
      }),
      setDoc(doc(db, 'users/staff-unassigned'), {
        uid: 'staff-unassigned',
        role: 'veterinary_staff',
      }),
      setDoc(doc(db, 'users/vet-a'), {
        uid: 'vet-a',
        role: 'veterinarian',
        hospitalId: 'hospital-a',
      }),
      setDoc(doc(db, 'veterinarians/vet-a'), {
        userId: 'vet-a',
        hospitalId: 'hospital-a',
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
      setDoc(doc(db, 'hospital_staff/staff-inactive'), {
        userId: 'staff-inactive',
        hospitalId: 'hospital-a',
        active: false,
      }),
      setDoc(doc(db, 'pets/pet-1'), {
        ownerId: 'owner-1',
        name: 'Milo',
      }),
      setDoc(doc(db, 'pets/pet-2'), {
        ownerId: 'owner-2',
        name: 'Luna',
      }),
    ]);
  });
});

function authenticatedDb(uid) {
  return env.authenticatedContext(uid).firestore();
}

function appointmentData({
  ownerId = 'owner-1',
  petId = ownerId === 'owner-1' ? 'pet-1' : 'pet-2',
  hospitalId = 'hospital-a',
  status = 'pending',
} = {}) {
  return {
    ownerId,
    petId,
    hospitalId,
    serviceId: 'service-a',
    vetId: 'vet-a',
    dateTime: APPOINTMENT_DATE,
    reason: 'Routine checkup',
    status,
    createdAt: CREATED_AT,
    updatedAt: CREATED_AT,
  };
}

async function seedAppointment(
  id = 'appointment-1',
  options = {},
) {
  await env.withSecurityRulesDisabled(async (context) => {
    await setDoc(
      doc(context.firestore(), `appointments/${id}`),
      appointmentData(options),
    );
  });
}

async function updateAppointmentStatus(db, appointmentId, status) {
  await updateDoc(doc(db, `appointments/${appointmentId}`), {
    status,
    updatedAt: serverTimestamp(),
  });
}

test('owner can cancel their own pending appointment', async () => {
  await seedAppointment();

  await assertSucceeds(
    updateAppointmentStatus(
      authenticatedDb('owner-1'),
      'appointment-1',
      'cancelled',
    ),
  );
});

test('owner can cancel their own confirmed appointment', async () => {
  await seedAppointment('appointment-confirmed', { status: 'confirmed' });

  await assertSucceeds(
    updateAppointmentStatus(
      authenticatedDb('owner-1'),
      'appointment-confirmed',
      'cancelled',
    ),
  );
});

test('owner cannot cancel another owner appointment', async () => {
  await seedAppointment('appointment-owner-2', { ownerId: 'owner-2' });

  await assertFails(
    updateAppointmentStatus(
      authenticatedDb('owner-1'),
      'appointment-owner-2',
      'cancelled',
    ),
  );
});

test('owner cannot confirm or reject their own appointment', async () => {
  await seedAppointment('appointment-confirm');
  await seedAppointment('appointment-reject');

  const ownerDb = authenticatedDb('owner-1');

  await assertFails(
    updateAppointmentStatus(ownerDb, 'appointment-confirm', 'confirmed'),
  );
  await assertFails(
    updateAppointmentStatus(ownerDb, 'appointment-reject', 'rejected'),
  );
});

test('owner can edit scheduling details while appointment is pending', async () => {
  await seedAppointment();

  await assertSucceeds(
    updateDoc(doc(authenticatedDb('owner-1'), 'appointments/appointment-1'), {
      dateTime: Timestamp.fromDate(new Date('2026-11-11T09:00:00.000Z')),
      reason: 'Follow-up consultation',
      updatedAt: serverTimestamp(),
    }),
  );
});

test('owner cannot edit scheduling details after appointment is confirmed', async () => {
  await seedAppointment('appointment-confirmed', { status: 'confirmed' });

  await assertFails(
    updateDoc(
      doc(authenticatedDb('owner-1'), 'appointments/appointment-confirmed'),
      {
        reason: 'Change after confirmation',
        updatedAt: serverTimestamp(),
      },
    ),
  );
});

test('assigned hospital staff can confirm a pending appointment', async () => {
  await seedAppointment();

  await assertSucceeds(
    updateAppointmentStatus(
      authenticatedDb('staff-a'),
      'appointment-1',
      'confirmed',
    ),
  );
});

test('assigned hospital staff can reject a pending appointment', async () => {
  await seedAppointment();

  await assertSucceeds(
    updateAppointmentStatus(
      authenticatedDb('staff-a'),
      'appointment-1',
      'rejected',
    ),
  );
});

test('assigned veterinarian can confirm a pending appointment', async () => {
  await seedAppointment();

  await assertSucceeds(
    updateAppointmentStatus(
      authenticatedDb('vet-a'),
      'appointment-1',
      'confirmed',
    ),
  );
});

test('staff assigned to another hospital cannot decide the appointment', async () => {
  await seedAppointment();

  await assertFails(
    updateAppointmentStatus(
      authenticatedDb('staff-b'),
      'appointment-1',
      'confirmed',
    ),
  );
});

test('inactive hospital staff cannot decide the appointment', async () => {
  await seedAppointment();

  await assertFails(
    updateAppointmentStatus(
      authenticatedDb('staff-inactive'),
      'appointment-1',
      'confirmed',
    ),
  );
});

test('unassigned hospital staff cannot decide the appointment', async () => {
  await seedAppointment();

  await assertFails(
    updateAppointmentStatus(
      authenticatedDb('staff-unassigned'),
      'appointment-1',
      'confirmed',
    ),
  );
});

test('hospital staff cannot cancel an appointment on behalf of the owner', async () => {
  await seedAppointment();

  await assertFails(
    updateAppointmentStatus(
      authenticatedDb('staff-a'),
      'appointment-1',
      'cancelled',
    ),
  );
});

test('hospital staff cannot change immutable appointment relationships', async () => {
  await seedAppointment();

  await assertFails(
    updateDoc(doc(authenticatedDb('staff-a'), 'appointments/appointment-1'), {
      hospitalId: 'hospital-b',
      updatedAt: serverTimestamp(),
    }),
  );
});

test('owner cannot change immutable appointment relationships while cancelling', async () => {
  await seedAppointment();

  await assertFails(
    updateDoc(doc(authenticatedDb('owner-1'), 'appointments/appointment-1'), {
      hospitalId: 'hospital-b',
      status: 'cancelled',
      updatedAt: serverTimestamp(),
    }),
  );
});

test('staff cannot decide an appointment that is no longer pending', async () => {
  await seedAppointment('appointment-confirmed', { status: 'confirmed' });
  await seedAppointment('appointment-rejected', { status: 'rejected' });

  const staffDb = authenticatedDb('staff-a');

  await assertFails(
    updateAppointmentStatus(staffDb, 'appointment-confirmed', 'rejected'),
  );
  await assertFails(
    updateAppointmentStatus(staffDb, 'appointment-rejected', 'confirmed'),
  );
});

test('terminal appointment statuses cannot be reopened by owner or staff', async () => {
  await seedAppointment('appointment-cancelled', { status: 'cancelled' });
  await seedAppointment('appointment-rejected', { status: 'rejected' });

  await assertFails(
    updateAppointmentStatus(
      authenticatedDb('owner-1'),
      'appointment-cancelled',
      'confirmed',
    ),
  );
  await assertFails(
    updateAppointmentStatus(
      authenticatedDb('staff-a'),
      'appointment-rejected',
      'pending',
    ),
  );
});

test('appointment status transition requires a server timestamp', async () => {
  await seedAppointment();

  await assertFails(
    updateDoc(doc(authenticatedDb('staff-a'), 'appointments/appointment-1'), {
      status: 'confirmed',
      updatedAt: Timestamp.fromDate(new Date('2026-11-02T00:00:00.000Z')),
    }),
  );
});

test('hospital staff can update scheduling details without changing status', async () => {
  await seedAppointment();

  await assertSucceeds(
    updateDoc(doc(authenticatedDb('staff-a'), 'appointments/appointment-1'), {
      vetId: 'vet-a',
      reason: 'Updated clinical note',
      updatedAt: serverTimestamp(),
    }),
  );
});

// Keep the fixture timestamps deterministic and ensure this module fails
// loudly if an assertion helper is accidentally removed from the test setup.
assert.ok(CREATED_AT instanceof Timestamp);