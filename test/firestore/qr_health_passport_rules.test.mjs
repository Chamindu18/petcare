import { readFileSync } from 'node:fs';
import { fileURLToPath } from 'node:url';
import { dirname, resolve } from 'node:path';
import test, { after, before, beforeEach } from 'node:test';
import {
  assertFails,
  assertSucceeds,
  initializeTestEnvironment,
} from '@firebase/rules-unit-testing';
import {
  doc,
  getDoc,
  serverTimestamp,
  setDoc,
  updateDoc,
  writeBatch,
  Timestamp,
} from 'firebase/firestore';

const here = dirname(fileURLToPath(import.meta.url));
const rules = readFileSync(resolve(here, '../../firestore.rules'), 'utf8');
const token = 'A'.repeat(43);
const token2 = 'B'.repeat(43);
let env;

before(async () => {
  env = await initializeTestEnvironment({
    projectId: 'demo-petcare-qr',
    firestore: { rules },
  });
});

after(async () => env?.cleanup());

beforeEach(async () => {
  await env.clearFirestore();
  await env.withSecurityRulesDisabled(async (context) => {
    const db = context.firestore();
    await Promise.all([
      setDoc(doc(db, 'users/owner-a'), { uid: 'owner-a', role: 'owner' }),
      setDoc(doc(db, 'users/owner-b'), { uid: 'owner-b', role: 'owner' }),
      setDoc(doc(db, 'users/vet-a'), {
        uid: 'vet-a', role: 'veterinarian', hospitalId: 'hospital-a',
      }),
      setDoc(doc(db, 'users/vet-other'), {
        uid: 'vet-other', role: 'veterinarian', hospitalId: 'hospital-a',
      }),
      setDoc(doc(db, 'users/vet-b'), {
        uid: 'vet-b', role: 'veterinarian', hospitalId: 'hospital-b',
      }),
      setDoc(doc(db, 'users/staff-a'), {
        uid: 'staff-a', role: 'veterinary_staff',
      }),
      setDoc(doc(db, 'users/provider-a'), {
        uid: 'provider-a', role: 'adoption_provider',
      }),
      setDoc(doc(db, 'veterinarians/vet-a'), {
        vetId: 'vet-a', userId: 'vet-a', hospitalId: 'hospital-a', active: true,
      }),
      setDoc(doc(db, 'veterinarians/vet-other'), {
        vetId: 'vet-other', userId: 'vet-other', hospitalId: 'hospital-a', active: true,
      }),
      setDoc(doc(db, 'veterinarians/vet-b'), {
        vetId: 'vet-b', userId: 'vet-b', hospitalId: 'hospital-b', active: true,
      }),
      setDoc(doc(db, 'hospital_staff/staff-a'), {
        userId: 'staff-a', hospitalId: 'hospital-a', active: true,
      }),
      setDoc(doc(db, 'pets/pet-a'), {
        petId: 'pet-a', ownerId: 'owner-a', name: 'Milo', species: 'Dog',
        breed: 'Mixed', dob: '2022-01-01T00:00:00.000Z', gender: 'male',
        weight: 12, imageUrl: '', notes: '', status: 'active',
      }),
      setDoc(doc(db, 'pets/pet-b'), {
        petId: 'pet-b', ownerId: 'owner-b', name: 'Luna', species: 'Cat',
        breed: 'Mixed', dob: '2023-01-01T00:00:00.000Z', gender: 'female',
        weight: 4, imageUrl: '', notes: '', status: 'active',
      }),
      setDoc(doc(db, 'appointments/appointment-a'), appointment()),
      setDoc(doc(db, 'medical_conditions/condition-a'), condition()),
    ]);
  });
});

function appointment(overrides = {}) {
  return {
    ownerId: 'owner-a', petId: 'pet-a', hospitalId: 'hospital-a',
    serviceId: 'service-a', vetId: 'vet-a', dateTime: Timestamp.now(),
    reason: 'Checkup', status: 'confirmed', createdAt: Timestamp.now(),
    updatedAt: Timestamp.now(), ...overrides,
  };
}

function condition() {
  return {
    conditionId: 'condition-a', petId: 'pet-a', name: 'Allergy',
    status: 'active', source: 'owner-reported',
    diagnosisDate: '2026-10-01T00:00:00.000Z', vetId: null,
    notes: 'Seasonal', createdAt: '2026-10-01T00:00:00.000Z',
    updatedAt: '2026-10-01T00:00:00.000Z',
  };
}

function passport(createdAt = serverTimestamp()) {
  return {
    appointmentId: 'appointment-a', petId: 'pet-a', hospitalId: 'hospital-a',
    veterinarianId: 'vet-a', status: 'active', schemaVersion: 1, createdAt,
  };
}

async function createValidPassport(value = token) {
  const db = env.authenticatedContext('owner-a').firestore();
  const batch = writeBatch(db);
  const root = doc(db, `qr_health_passports/${value}`);
  batch.set(root, passport());
  batch.set(doc(db, `qr_health_passports/${value}/pet/summary`), {
    name: 'Milo', species: 'Dog', breed: 'Mixed',
    dob: '2022-01-01T00:00:00.000Z',
  });
  batch.set(
    doc(db, `qr_health_passports/${value}/medical_conditions/condition-a`),
    condition(),
  );
  await assertSucceeds(batch.commit());
}

test('owner creates a valid opaque appointment-linked QR passport', async () => {
  await createValidPassport();
  await assertSucceeds(getDoc(doc(
    env.authenticatedContext('owner-a').firestore(),
    `qr_health_passports/${token}`,
  )));
});

test('wrong owner and forged relationships cannot create a passport', async () => {
  const wrongOwner = env.authenticatedContext('owner-b').firestore();
  await assertFails(setDoc(doc(wrongOwner, `qr_health_passports/${token}`), passport()));

  const owner = env.authenticatedContext('owner-a').firestore();
  await assertFails(setDoc(doc(owner, `qr_health_passports/${token2}`), {
    ...passport(), petId: 'pet-b',
  }));
});

test('assigned veterinarian reads verified projection; other vets are denied', async () => {
  await createValidPassport();
  const assigned = env.authenticatedContext('vet-a').firestore();
  await assertSucceeds(getDoc(doc(assigned, `qr_health_passports/${token}`)));
  await assertSucceeds(getDoc(doc(
    assigned,
    `qr_health_passports/${token}/medical_conditions/condition-a`,
  )));

  for (const uid of ['vet-other', 'vet-b']) {
    await assertFails(getDoc(doc(
      env.authenticatedContext(uid).firestore(),
      `qr_health_passports/${token}`,
    )));
  }
});

test('hospital staff verifies only metadata and adoption provider is denied', async () => {
  await createValidPassport();
  const staff = env.authenticatedContext('staff-a').firestore();
  await assertSucceeds(getDoc(doc(staff, `qr_health_passports/${token}`)));
  await assertFails(getDoc(doc(
    staff,
    `qr_health_passports/${token}/medical_conditions/condition-a`,
  )));
  await assertFails(getDoc(doc(
    env.authenticatedContext('provider-a').firestore(),
    `qr_health_passports/${token}`,
  )));
});

test('revoked and cancelled appointment passports are rejected', async () => {
  await createValidPassport();
  const owner = env.authenticatedContext('owner-a').firestore();
  await assertSucceeds(updateDoc(doc(owner, `qr_health_passports/${token}`), {
    status: 'revoked', revokedAt: serverTimestamp(),
  }));
  await assertFails(getDoc(doc(
    env.authenticatedContext('vet-a').firestore(),
    `qr_health_passports/${token}`,
  )));

  await createValidPassport(token2);
  await env.withSecurityRulesDisabled((context) => updateDoc(
    doc(context.firestore(), 'appointments/appointment-a'),
    { status: 'cancelled' },
  ));
  await assertFails(getDoc(doc(
    env.authenticatedContext('vet-a').firestore(),
    `qr_health_passports/${token2}`,
  )));
});

test('expired passports and client-controlled old timestamps are denied', async () => {
  const owner = env.authenticatedContext('owner-a').firestore();
  await assertFails(setDoc(doc(owner, `qr_health_passports/${token}`),
    passport(Timestamp.fromMillis(Date.now() - 60_000))));

  await env.withSecurityRulesDisabled((context) => setDoc(
    doc(context.firestore(), `qr_health_passports/${token}`),
    passport(Timestamp.fromMillis(Date.now() - 16 * 60_000)),
  ));
  await assertFails(getDoc(doc(
    env.authenticatedContext('vet-a').firestore(),
    `qr_health_passports/${token}`,
  )));
});

test('projection tampering and schema pollution are denied', async () => {
  const db = env.authenticatedContext('owner-a').firestore();
  const batch = writeBatch(db);
  batch.set(doc(db, `qr_health_passports/${token}`), passport());
  batch.set(doc(db, `qr_health_passports/${token}/medical_conditions/condition-a`), {
    ...condition(), notes: 'Fabricated', extraData: 'not allowed',
  });
  await assertFails(batch.commit());
});
