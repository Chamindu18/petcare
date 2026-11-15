import { assertDenied as assertFails } from './assert_denied.mjs';
import { readFileSync } from 'node:fs';
import { fileURLToPath } from 'node:url';
import { dirname, resolve } from 'node:path';
import test, { before, beforeEach, after } from 'node:test';
import assert from 'node:assert/strict';
import {
  initializeTestEnvironment,
  assertSucceeds,
} from '@firebase/rules-unit-testing';
import {
  collection, getDoc, getDocs, query, where, writeBatch,
  doc,
  setDoc,
  updateDoc,
  serverTimestamp,
  Timestamp,
} from 'firebase/firestore';

const __dirname = dirname(fileURLToPath(import.meta.url));
const projectId = 'demo-petcare-phase2-isolated';
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
        active: true,
        userId: 'vet-a',
        hospitalId: 'hospital-a',
      }),
      setDoc(doc(db, 'users/doctor-b'), {role: 'veterinarian', hospitalId: 'hospital-a', vetId: 'directory-b'}),
      setDoc(doc(db, 'veterinarians/directory-b'), {vetId: 'directory-b', userId: 'doctor-b', hospitalId: 'hospital-a', active: true}),
      setDoc(doc(db, 'veterinarians/bad-link'), {hospitalId: 'hospital-a', active: true, userId: 'doctor-b'}),
      setDoc(doc(db, 'veterinarians/unlinked'), {hospitalId: 'hospital-a', active: true}),
      setDoc(doc(db, 'veterinarians/inactive'), {hospitalId: 'hospital-a', active: false}),
      setDoc(doc(db, 'veterinarians/cross-hospital'), {hospitalId: 'hospital-b', active: true}),
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

test('owner cannot bypass the trusted scheduler even while pending', async () => {
  await seedAppointment();

  await assertFails(
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
function doctorQuery(uid, vetId) {
  return getDocs(query(collection(authenticatedDb(uid), 'appointments'),
    where('hospitalId', '==', 'hospital-a'), where('vetId', '==', vetId)));
}

test('booking through confirmation and same-hospital reassignment isolates doctor views', async () => {
  const owner = authenticatedDb('owner-1');
  const data = appointmentData();
  const batch = writeBatch(owner);
  batch.set(doc(owner, 'appointments/integration'), data);
  batch.set(doc(owner, 'appointment_schedule/integration'), {
    vetId: data.vetId, hospitalId: data.hospitalId, serviceId: data.serviceId,
    dateTime: data.dateTime, status: data.status,
  });
  await assertFails(batch.commit());
  await env.withSecurityRulesDisabled(async context => {
    await setDoc(doc(context.firestore(), 'appointments/integration'), data);
    await setDoc(doc(context.firestore(), 'appointment_schedule/integration'), {
      vetId: data.vetId, hospitalId: data.hospitalId, serviceId: data.serviceId, dateTime: data.dateTime, status: data.status,
    });
  });
  await assertSucceeds(getDocs(query(collection(authenticatedDb('staff-a'), 'appointments'), where('hospitalId', '==', 'hospital-a'))));
  await assertFails(getDoc(doc(authenticatedDb('staff-b'), 'appointments/integration')));
  await assertFails(getDoc(doc(authenticatedDb('doctor-b'), 'appointments/integration')));
  assert.equal((await assertSucceeds(doctorQuery('vet-a', 'vet-a'))).size, 1);
  assert.equal((await assertSucceeds(doctorQuery('doctor-b', 'directory-b'))).size, 0);
  const staff = authenticatedDb('staff-a');
  const confirm = writeBatch(staff);
  confirm.update(doc(staff, 'appointments/integration'), {status: 'confirmed', updatedAt: serverTimestamp()});
  confirm.update(doc(staff, 'appointment_schedule/integration'), {status: 'confirmed'});
  await assertSucceeds(confirm.commit());
  const reassign = writeBatch(staff);
  reassign.update(doc(staff, 'appointments/integration'), {vetId: 'directory-b', updatedAt: serverTimestamp()});
  reassign.update(doc(staff, 'appointment_schedule/integration'), {vetId: 'directory-b'});
  await assertFails(reassign.commit());
  // The server transaction's assignment behavior is covered by the concurrency suite.
  await env.withSecurityRulesDisabled(async context => {
    await updateDoc(doc(context.firestore(), 'appointments/integration'), {vetId: 'directory-b'});
    await updateDoc(doc(context.firestore(), 'appointment_schedule/integration'), {vetId: 'directory-b'});
  });
  assert.equal((await assertSucceeds(doctorQuery('vet-a', 'vet-a'))).size, 0);
  assert.equal((await assertSucceeds(doctorQuery('doctor-b', 'directory-b'))).size, 1);
  await assertFails(getDoc(doc(authenticatedDb('vet-a'), 'appointments/integration')));
});

for (const vetId of ['missing', 'inactive', 'cross-hospital', 'unlinked', 'bad-link']) {
  test(`invalid veterinarian ${vetId} rejected on booking and reassignment`, async () => {
    const owner = authenticatedDb('owner-1');
    const data = {...appointmentData(), vetId};
    const booking = writeBatch(owner);
    booking.set(doc(owner, 'appointments/invalid'), data);
    booking.set(doc(owner, 'appointment_schedule/invalid'), {
      vetId, hospitalId: data.hospitalId, serviceId: data.serviceId,
      dateTime: data.dateTime, status: data.status,
    });
    await assertFails(booking.commit());
    await seedAppointment();
    await assertFails(updateDoc(doc(authenticatedDb('staff-a'), 'appointments/appointment-1'), {vetId, updatedAt: serverTimestamp()}));
  });
}

test('same-hospital doctor cannot query or modify another doctor appointment', async () => {
  await seedAppointment();
  await assertFails(doctorQuery('doctor-b', 'vet-a'));
  await assertFails(updateAppointmentStatus(authenticatedDb('doctor-b'), 'appointment-1', 'confirmed'));
  await assertFails(getDocs(query(collection(authenticatedDb('doctor-b'), 'appointments'), where('hospitalId', '==', 'hospital-a'))));
});

test('directory identity and active state cannot be self-promoted', async () => {
  const vet = authenticatedDb('vet-a');
  for (const patch of [{active: false}, {vetId: 'directory-b'}, {userId: 'doctor-b'}, {hospitalId: 'hospital-b'}]) {
    await assertFails(updateDoc(doc(vet, 'veterinarians/vet-a'), patch));
  }
});

test('queued appointment cannot be reassigned or rescheduled', async () => {
  await env.withSecurityRulesDisabled(async context => {
    await setDoc(doc(context.firestore(), 'appointments/queued'), {...appointmentData({status: 'confirmed'}), queueId: 'queue-1'});
  });
  await assertFails(updateDoc(doc(authenticatedDb('staff-a'), 'appointments/queued'), {vetId: 'directory-b', updatedAt: serverTimestamp()}));
  await assertFails(updateDoc(doc(authenticatedDb('staff-a'), 'appointments/queued'), {dateTime: CREATED_AT, updatedAt: serverTimestamp()}));
});

test('availability exposes schedule fields only and cannot be forged', async () => {
  await seedAppointment();
  await assertFails(setDoc(doc(authenticatedDb('owner-2'), 'appointment_schedule/appointment-1'), {
    vetId: 'vet-a', hospitalId: 'hospital-a', serviceId: 'service-a', dateTime: APPOINTMENT_DATE, status: 'pending',
  }));
  await assertFails(getDocs(collection(authenticatedDb('owner-2'), 'appointments')));
});


test('owner health-record creation remains independent of appointment assignment', async () => {
  for (const collectionName of ['medical_conditions', 'vaccinations', 'treatments', 'health_measurements']) {
    await assertSucceeds(setDoc(doc(authenticatedDb('owner-1'), `${collectionName}/health-record`), {petId: 'pet-1', notes: 'Owner record'}));
  }
});
