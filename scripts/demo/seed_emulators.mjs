import {initializeApp} from 'firebase-admin/app';
import {getAuth} from 'firebase-admin/auth';
import {FieldValue, getFirestore} from 'firebase-admin/firestore';

const projectId = 'demo-petcare';
const firestoreHost = '127.0.0.1:8080';
const authHost = '127.0.0.1:9099';
const password = 'PetCareDemo!2026';

// Force every Admin SDK operation into local emulators. This script must never
// inherit production credentials or a production project ID.
process.env.GCLOUD_PROJECT = projectId;
process.env.FIREBASE_CONFIG = JSON.stringify({projectId});
process.env.FIRESTORE_EMULATOR_HOST = firestoreHost;
process.env.FIREBASE_AUTH_EMULATOR_HOST = authHost;

async function requireEmulators() {
  const checks = [
    fetch(`http://${firestoreHost}/`),
    fetch(`http://${authHost}/`),
  ];
  const results = await Promise.allSettled(checks);
  if (results.some((result) => result.status === 'rejected')) {
    throw new Error(
      'Auth and Firestore emulators must be running on ports 9099 and 8080.',
    );
  }
}

async function resetFirestore() {
  const response = await fetch(
    `http://${firestoreHost}/emulator/v1/projects/${projectId}/databases/(default)/documents`,
    {method: 'DELETE'},
  );
  if (!response.ok) {
    throw new Error(`Unable to reset Firestore emulator (${response.status}).`);
  }
}

async function resetAuth(auth) {
  let token;
  do {
    const page = await auth.listUsers(1000, token);
    if (page.users.length > 0) {
      await auth.deleteUsers(page.users.map((user) => user.uid));
    }
    token = page.pageToken;
  } while (token);
}

function profile(uid, email, fullName, role, extra = {}) {
  return {
    uid,
    email,
    fullName,
    displayName: fullName,
    phone: '0000000000',
    role,
    notificationEnabled: true,
    createdAt: FieldValue.serverTimestamp(),
    updatedAt: FieldValue.serverTimestamp(),
    ...extra,
  };
}

function appointment({id, ownerId, dateTime, status, vetId}) {
  return {
    appointmentId: id,
    ownerId,
    petId: 'demo-pet',
    hospitalId: 'demo-hospital',
    serviceId: 'demo-service-30',
    vetId,
    dateTime,
    reason: `Synthetic ${status} appointment for the local emulator demo`,
    status,
    queueId: null,
    durationMinutes: 30,
    createdAt: new Date().toISOString(),
    updatedAt: FieldValue.serverTimestamp(),
  };
}

function schedule(data) {
  return Object.fromEntries(
    ['vetId', 'hospitalId', 'serviceId', 'dateTime', 'status', 'durationMinutes']
      .map((key) => [key, data[key]]),
  );
}

async function main() {
  await requireEmulators();
  const app = initializeApp({projectId});
  const auth = getAuth(app);
  const db = getFirestore(app);

  await resetFirestore();
  await resetAuth(auth);

  const accounts = [
    ['demo-owner', 'owner.demo@petcare.test', 'Demo Owner'],
    ['demo-staff', 'staff.demo@petcare.test', 'Demo Staff'],
    ['demo-doctor-a', 'vet.a.demo@petcare.test', 'Dr. Demo A'],
    ['demo-doctor-b', 'vet.b.demo@petcare.test', 'Dr. Demo B'],
  ];
  for (const [uid, email, displayName] of accounts) {
    await auth.createUser({uid, email, password, displayName, emailVerified: true});
  }

  const writes = {
    'users/demo-owner': profile(
      'demo-owner',
      'owner.demo@petcare.test',
      'Demo Owner',
      'owner',
    ),
    'users/demo-staff': profile(
      'demo-staff',
      'staff.demo@petcare.test',
      'Demo Staff',
      'veterinary_staff',
      {staffId: 'demo-staff', hospitalId: 'demo-hospital'},
    ),
    'users/demo-doctor-a': profile(
      'demo-doctor-a',
      'vet.a.demo@petcare.test',
      'Dr. Demo A',
      'veterinarian',
      {vetId: 'demo-vet-a', hospitalId: 'demo-hospital'},
    ),
    'users/demo-doctor-b': profile(
      'demo-doctor-b',
      'vet.b.demo@petcare.test',
      'Dr. Demo B',
      'veterinarian',
      {vetId: 'demo-vet-b', hospitalId: 'demo-hospital'},
    ),
    'hospital_staff/demo-staff': {
      userId: 'demo-staff',
      hospitalId: 'demo-hospital',
      active: true,
    },
    'hospitals/demo-hospital': {
      hospitalId: 'demo-hospital',
      name: 'PetCare+ Emulator Hospital',
      location: 'Local Academic Demo',
      contact: '000-000-0000',
      hours: '12:00 AM - 11:59 PM',
      active: true,
    },
    'services/demo-service-30': {
      serviceId: 'demo-service-30',
      hospitalId: 'demo-hospital',
      name: 'General Consultation',
      description: 'Thirty-minute synthetic consultation',
      duration: 30,
      active: true,
    },
    'services/demo-service-60': {
      serviceId: 'demo-service-60',
      hospitalId: 'demo-hospital',
      name: 'Extended Consultation',
      description: 'Sixty-minute synthetic consultation',
      duration: 60,
      active: true,
    },
    'veterinarians/demo-vet-a': {
      vetId: 'demo-vet-a',
      userId: 'demo-doctor-a',
      hospitalId: 'demo-hospital',
      name: 'Dr. Demo A',
      specialty: 'General Veterinary Medicine',
      qualifications: 'Synthetic Demo Profile',
      experienceYears: 5,
      bio: 'Local emulator-only veterinarian profile.',
      profileImageUrl: '',
      active: true,
    },
    'veterinarians/demo-vet-b': {
      vetId: 'demo-vet-b',
      userId: 'demo-doctor-b',
      hospitalId: 'demo-hospital',
      name: 'Dr. Demo B',
      specialty: 'Companion Animal Care',
      qualifications: 'Synthetic Demo Profile',
      experienceYears: 4,
      bio: 'Local emulator-only veterinarian profile.',
      profileImageUrl: '',
      active: true,
    },
    'pets/demo-pet': {
      petId: 'demo-pet',
      ownerId: 'demo-owner',
      name: 'Milo Demo',
      species: 'Dog',
      breed: 'Mixed Breed',
      dob: '2022-05-12T00:00:00.000',
      gender: 'Male',
      weight: 12.5,
      imageUrl: '',
      notes: 'Synthetic pet used only with local Firebase emulators.',
      status: 'active',
    },
  };

  const localDay = new Date(Date.now() + 330 * 60_000)
    .toISOString()
    .slice(0, 10);
  const tomorrow = new Date(`${localDay}T00:00:00Z`);
  tomorrow.setUTCDate(tomorrow.getUTCDate() + 1);
  const tomorrowKey = tomorrow.toISOString().slice(0, 10);

  const queueReady = appointment({
    id: 'demo-queue-ready',
    ownerId: 'demo-owner',
    dateTime: `${localDay}T10:00:00.000`,
    status: 'confirmed',
    vetId: 'demo-vet-a',
  });
  const rejectReady = appointment({
    id: 'demo-reject-ready',
    ownerId: 'demo-owner',
    dateTime: `${tomorrowKey}T11:00:00.000`,
    status: 'pending',
    vetId: 'demo-vet-a',
  });
  writes['appointments/demo-queue-ready'] = queueReady;
  writes['appointment_schedule/demo-queue-ready'] = schedule(queueReady);
  writes['appointments/demo-reject-ready'] = rejectReady;
  writes['appointment_schedule/demo-reject-ready'] = schedule(rejectReady);

  const batch = db.batch();
  for (const [path, data] of Object.entries(writes)) {
    batch.set(db.doc(path), data);
  }
  await batch.commit();

  console.log('PetCare+ local emulator demo reset and seeded.');
  console.log('Project: demo-petcare (local emulators only)');
  console.log(`Password for all synthetic accounts: ${password}`);
  for (const [, email, displayName] of accounts) {
    console.log(`- ${displayName}: ${email}`);
  }
}

main().catch((error) => {
  console.error(error.message);
  process.exitCode = 1;
});
