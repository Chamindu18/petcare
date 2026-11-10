import {readFile} from 'node:fs/promises';
import {initializeApp} from 'firebase-admin/app';
import {getAuth} from 'firebase-admin/auth';
import {FieldValue, Timestamp, getFirestore} from 'firebase-admin/firestore';

const projectId = 'demo-petcare';
const firestoreHost = '127.0.0.1:8080';
const authHost = '127.0.0.1:9099';
const functionsHost = '127.0.0.1:5001';
const password = process.env.PETCARE_DEMO_PASSWORD;
const validateOnly = process.argv.includes('--validate-only');
const check = (condition, message) => { if (!condition) throw new Error(message); };
const localDay = new Date(Date.now() + 330 * 60_000).toISOString().slice(0, 10);
const day = (offset) => {
  const value = new Date(`${localDay}T00:00:00Z`);
  value.setUTCDate(value.getUTCDate() + offset);
  return value.toISOString().slice(0, 10);
};
const hospitalTime = (date, hour) => new Date(`${date}T${hour}:00:00+05:30`).toISOString();
const historicalTime = (offset) => `${day(offset)}T09:00:00.000Z`;

// Emulator environment is set only after conflicting inherited values are rejected.

async function requireEmulators() {
  for (const [key, expected] of [
    ['GCLOUD_PROJECT', projectId], ['GOOGLE_CLOUD_PROJECT', projectId],
    ['FIRESTORE_EMULATOR_HOST', firestoreHost],
    ['FIREBASE_AUTH_EMULATOR_HOST', authHost],
  ]) check(!process.env[key] || process.env[key] === expected, `Conflicting ${key}; refusing reset.`);
  if (process.env.FIREBASE_CONFIG) {
    let config;
    try { config = JSON.parse(process.env.FIREBASE_CONFIG); } catch { throw new Error('Invalid FIREBASE_CONFIG.'); }
    check(config.projectId === projectId, 'Conflicting Firebase project; refusing reset.');
  }
  const config = JSON.parse(await readFile(new URL('../../firebase.json', import.meta.url), 'utf8'));
  check(config.emulators?.auth?.port === 9099 && config.emulators?.firestore?.port === 8080 && config.emulators?.functions?.port === 5001, 'Unexpected emulator ports.');
  const checks = [
    fetch(`http://${firestoreHost}/`, {signal: AbortSignal.timeout(3000)}),
    fetch(`http://${authHost}/`, {signal: AbortSignal.timeout(3000)}),
  ];
  const results = await Promise.allSettled(checks);
  if (results.some((result) => result.status === 'rejected' || result.value.status >= 500)) {
    throw new Error(
      'Auth and Firestore emulators must be running on ports 9099 and 8080.',
    );
  }
  const callable = await fetch(`http://${functionsHost}/${projectId}/asia-south2/reserveAppointmentSlot`, {
    method: 'POST', headers: {'Content-Type': 'application/json'}, body: JSON.stringify({data: {}}),
    signal: AbortSignal.timeout(3000),
  });
  check(callable.status === 401, `Booking Function is not ready in ${projectId} (HTTP ${callable.status}); refusing reset.`);
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
  const page = await auth.listUsers(1000);
  check(!page.pageToken, 'More than 1000 local Auth users; refusing partial reset.');
  if (page.users.length > 0) await auth.deleteUsers(page.users.map((user) => user.uid));
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

function appointment({id, ownerId, petId = 'demo-pet', dateTime, status, vetId, queueId = null}) {
  return {
    appointmentId: id,
    ownerId,
    petId,
    hospitalId: 'demo-hospital',
    serviceId: 'demo-service-30',
    vetId,
    dateTime,
    reason: `Synthetic ${status} appointment for the local emulator demo`,
    status,
    queueId,
    durationMinutes: 30,
    createdAt: historicalTime(-1),
    updatedAt: FieldValue.serverTimestamp(),
  };
}

function schedule(data) {
  return Object.fromEntries(
    ['vetId', 'hospitalId', 'serviceId', 'dateTime', 'status', 'durationMinutes']
      .map((key) => [key, data[key]]),
  );
}

function buildSeed() {
  const accounts = [
    ['demo-owner', 'owner.demo@petcare.test', 'Nimali Perera'],
    ['demo-owner-two', 'owner.two.demo@petcare.test', 'Kasun Silva'],
    ['demo-staff', 'staff.demo@petcare.test', 'Sahana Fernando'],
    ['demo-doctor-a', 'vet.a.demo@petcare.test', 'Dr. Anjali Jayasinghe'],
    ['demo-doctor-b', 'vet.b.demo@petcare.test', 'Dr. Ravi Perera'],
    ['demo-provider', 'provider.demo@petcare.test', 'Colombo Rescue'],
  ];

  const writes = {
    'users/demo-owner': profile(
      'demo-owner',
      'owner.demo@petcare.test',
      'Demo Owner',
      'owner',
    ),
    'users/demo-owner-two': profile('demo-owner-two', 'owner.two.demo@petcare.test', 'Kasun Silva', 'owner'),
    'users/demo-provider': profile('demo-provider', 'provider.demo@petcare.test', 'Colombo Rescue', 'adoption_provider'),
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

  const queueReady = appointment({
    id: 'demo-queue-ready',
    ownerId: 'demo-owner',
    dateTime: hospitalTime(localDay, '10'),
    status: 'confirmed',
    vetId: 'demo-vet-a',
    queueId: 'demo-queue',
  });
  const rejectReady = appointment({
    id: 'demo-reject-ready',
    ownerId: 'demo-owner',
    dateTime: hospitalTime(day(2), '14'),
    status: 'pending',
    vetId: 'demo-vet-a',
  });
  writes['appointments/demo-queue-ready'] = queueReady;
  writes['appointment_schedule/demo-queue-ready'] = schedule(queueReady);
  writes['appointments/demo-reject-ready'] = rejectReady;
  writes['appointment_schedule/demo-reject-ready'] = schedule(rejectReady);

  const addAppointment = (data) => {
    const record = appointment(data);
    writes[`appointments/${data.id}`] = record;
    writes[`appointment_schedule/${data.id}`] = schedule(record);
  };
  addAppointment({id: 'demo-passport-ready', ownerId: 'demo-owner', dateTime: hospitalTime(day(1), '11'), status: 'confirmed', vetId: 'demo-vet-a'});
  addAppointment({id: 'demo-other-appointment', ownerId: 'demo-owner-two', petId: 'demo-other-pet', dateTime: hospitalTime(day(1), '12'), status: 'confirmed', vetId: 'demo-vet-b'});
  addAppointment({id: 'demo-cancelled', ownerId: 'demo-owner', dateTime: hospitalTime(day(-2), '09'), status: 'cancelled', vetId: 'demo-vet-a'});

  writes['pets/demo-pet-two'] = {...writes['pets/demo-pet'], petId: 'demo-pet-two', name: 'Luna', species: 'Cat', breed: 'Domestic Shorthair', gender: 'Female', weight: 4.1};
  writes['pets/demo-other-pet'] = {...writes['pets/demo-pet'], petId: 'demo-other-pet', ownerId: 'demo-owner-two', name: 'Kiki', weight: 8.2};
  const healthDates = {createdAt: historicalTime(-60), updatedAt: historicalTime(-2)};
  writes['vaccinations/demo-vaccination'] = {vaccinationId: 'demo-vaccination', petId: 'demo-pet', name: 'Rabies', dateGiven: historicalTime(-180), nextDueDate: historicalTime(180), providerId: 'demo-vet-a', notes: 'Synthetic vaccination history', ...healthDates};
  writes['medical_conditions/demo-condition'] = {conditionId: 'demo-condition', petId: 'demo-pet', name: 'Seasonal skin sensitivity', status: 'active', source: 'owner_reported', diagnosisDate: historicalTime(-45), vetId: null, notes: 'Synthetic owner-reported history', ...healthDates};
  writes['treatments/demo-treatment'] = {treatmentId: 'demo-treatment', petId: 'demo-pet', name: 'Skin care follow-up', status: 'active', source: 'owner_reported', startDate: historicalTime(-30), endDate: null, notes: 'Synthetic record; no medication or dosage', ...healthDates};
  for (const [id, offset, value] of [['demo-weight-old', -90, 11.8], ['demo-weight-new', -7, 12.5]]) {
    writes[`health_measurements/${id}`] = {measurementId: id, petId: 'demo-pet', type: 'weight', value, unit: 'kg', recordedAt: historicalTime(offset), ...healthDates};
  }
  const queueDay = Timestamp.fromDate(new Date(`${localDay}T00:00:00Z`));
  writes[`hospitals/demo-hospital/queue_days/${localDay}`] = {lastNumber: 1, queueId: 'demo-queue', day: queueDay, updatedAt: FieldValue.serverTimestamp()};
  writes['queue_records/demo-queue'] = {queueId: 'demo-queue', appointmentId: 'demo-queue-ready', hospitalId: 'demo-hospital', ownerId: 'demo-owner', petId: 'demo-pet', veterinarianId: 'demo-vet-a', queueNumber: 1, currentServing: 0, position: 1, status: 'waiting', day: queueDay, dayKey: localDay, createdAt: FieldValue.serverTimestamp(), updatedAt: FieldValue.serverTimestamp()};

  const listing = (id, ownerType, ownerId, petName, status) => {
    writes[`adoption_listings/${id}`] = {
      ...(ownerType === 'adoption_provider' ? {providerId: ownerId} : {}),
      listingOwnerType: ownerType, listingOwnerId: ownerId, petName,
      species: 'Dog', breed: 'Mixed Breed', ageDescription: 'About one year', gender: 'Female',
      description: 'Synthetic adoption listing for local demonstration', location: 'Colombo', status,
      contactNote: 'Contact through the application', createdAt: Timestamp.now(), updatedAt: Timestamp.now(),
    };
  };
  listing('demo-provider-listing', 'adoption_provider', 'demo-provider', 'Coco', 'available');
  listing('demo-provider-draft', 'adoption_provider', 'demo-provider', 'Biscuit', 'draft');
  listing('demo-owner-listing', 'owner', 'demo-owner', 'Bella', 'available');
  writes['adoption_requests/demo-provider-listing_demo-owner'] = {listingId: 'demo-provider-listing', requesterId: 'demo-owner', providerId: 'demo-provider', recipientId: 'demo-provider', recipientType: 'adoption_provider', message: 'I would like to meet Coco.', status: 'pending', submittedAt: Timestamp.now(), updatedAt: Timestamp.now()};

  const notification = (id, recipientUserId, type, message, targetType, targetId, extra = {}) => {
    writes[`notifications/${id}`] = {recipientUserId, type, message, read: false, targetType, targetId, createdAt: FieldValue.serverTimestamp(), ...extra};
  };
  notification('demo-owner-notification', 'demo-owner', 'appointment_confirmed', 'Milo has a confirmed consultation.', 'appointment', 'demo-passport-ready', {appointmentTime: writes['appointments/demo-passport-ready'].dateTime});
  notification('demo-staff-notification', 'demo-staff', 'queue_checked_in', 'Milo is waiting in the hospital queue.', 'queue', 'demo-queue', {queueNumber: 1});
  notification('demo-vet-notification', 'demo-doctor-a', 'patient_checked_in', 'Milo is assigned to your queue.', 'appointment', 'demo-queue-ready', {queueNumber: 1});
  notification('adoption_request_submitted_demo-provider-listing_demo-owner', 'demo-provider', 'adoption_request_submitted', 'A new adoption request was submitted for Coco.', 'adoption_request', 'demo-provider-listing_demo-owner', {listingName: 'Coco'});

  return {accounts, writes};
}

function validate(writes, accounts) {
  const get = path => { const value = writes[path]; check(value, `Missing ${path}`); return value; };
  const roles = {'demo-owner': 'owner', 'demo-owner-two': 'owner', 'demo-staff': 'veterinary_staff', 'demo-doctor-a': 'veterinarian', 'demo-doctor-b': 'veterinarian', 'demo-provider': 'adoption_provider'};
  for (const [uid, email] of accounts) check(get(`users/${uid}`).uid === uid && get(`users/${uid}`).email === email && get(`users/${uid}`).role === roles[uid], `Role/profile mismatch: ${uid}`);
  check(get('hospital_staff/demo-staff').userId === 'demo-staff' && get('hospital_staff/demo-staff').hospitalId === get('users/demo-staff').hospitalId, 'Staff link mismatch');
  for (const [path, data] of Object.entries(writes)) {
    const [collection, id] = path.split('/');
    if (collection === 'veterinarians') check(get(`users/${data.userId}`).vetId === id && get(`users/${data.userId}`).hospitalId === data.hospitalId, `Vet link: ${id}`);
    if (collection === 'pets') check(data.petId === id && get(`users/${data.ownerId}`).role === 'owner', `Pet owner: ${id}`);
    if (['vaccinations', 'medical_conditions', 'treatments', 'health_measurements'].includes(collection)) check(get(`pets/${data.petId}`) && data.createdAt && data.updatedAt, `Health record: ${id}`);
    if (collection === 'hospitals' && path.split('/').length === 2) check(/^\d{1,2}:\d{2} (AM|PM) - \d{1,2}:\d{2} (AM|PM)$/.test(data.hours), `Hours: ${id}`);
    if (collection === 'services') check(get(`hospitals/${data.hospitalId}`) && Number.isInteger(data.duration) && data.duration > 0 && data.duration % 15 === 0, `Service duration: ${id}`);
    if (collection === 'appointments') {
      check(data.appointmentId === id && get(`pets/${data.petId}`).ownerId === data.ownerId && get(`services/${data.serviceId}`).hospitalId === data.hospitalId && get(`veterinarians/${data.vetId}`).hospitalId === data.hospitalId, `Appointment links: ${id}`);
      check(get(`appointment_schedule/${id}`).dateTime === data.dateTime && get(`appointment_schedule/${id}`).status === data.status, `Schedule: ${id}`);
      if (data.queueId) check(get(`queue_records/${data.queueId}`).appointmentId === id, `Queue link: ${id}`);
    }
    if (collection === 'queue_records') {
      const appointment = get(`appointments/${data.appointmentId}`);
      check(appointment.queueId === id && appointment.status === 'confirmed' && ['hospitalId', 'ownerId', 'petId'].every(key => appointment[key] === data[key]) && appointment.vetId === data.veterinarianId, `Queue relationships: ${id}`);
      check(data.dayKey === localDay && data.day.toDate().toISOString().slice(0, 10) === localDay && data.queueNumber > 0, `Queue day: ${id}`);
    }
    if (collection === 'adoption_listings') check(get(`users/${data.listingOwnerId}`).role === data.listingOwnerType && (data.listingOwnerType !== 'adoption_provider' || data.providerId === data.listingOwnerId), `Listing ownership: ${id}`);
    if (collection === 'adoption_requests') {
      const listing = get(`adoption_listings/${data.listingId}`);
      check(listing.status === 'available' && listing.listingOwnerId === data.recipientId && listing.listingOwnerType === data.recipientType && get(`users/${data.requesterId}`).role === 'owner' && data.providerId === data.recipientId, `Request ownership: ${id}`);
    }
    if (collection === 'notifications') {
      const targets = {appointment: 'appointments', queue: 'queue_records', adoption_request: 'adoption_requests'};
      check(get(`users/${data.recipientUserId}`) && targets[data.targetType] && get(`${targets[data.targetType]}/${data.targetId}`), `Notification recipient/target: ${id}`);
    }
  }
  const passport = get('appointments/demo-passport-ready');
  check(passport.status === 'confirmed' && passport.ownerId === get(`pets/${passport.petId}`).ownerId && get(`veterinarians/${passport.vetId}`).active && new Date(passport.dateTime) > new Date(), 'QR passport appointment is not eligible');
}

async function main() {
  const {accounts, writes} = buildSeed();
  validate(writes, accounts);
  if (validateOnly) { console.log(`Validated ${Object.keys(writes).length} documents for ${localDay} Sri Lanka time.`); return; }
  check(password && password.length >= 12, 'Set a private PETCARE_DEMO_PASSWORD (at least 12 characters).');
  await requireEmulators();
  process.env.GCLOUD_PROJECT = projectId;
  process.env.FIREBASE_CONFIG = JSON.stringify({projectId});
  process.env.FIRESTORE_EMULATOR_HOST = firestoreHost;
  process.env.FIREBASE_AUTH_EMULATOR_HOST = authHost;
  const app = initializeApp({projectId});
  const auth = getAuth(app);
  const db = getFirestore(app);
  await resetFirestore();
  await resetAuth(auth);
  for (const [uid, email, displayName] of accounts) await auth.createUser({uid, email, password, displayName, emailVerified: true});

  const batch = db.batch();
  for (const [path, data] of Object.entries(writes)) {
    batch.set(db.doc(path), data);
  }
  await batch.commit();

  console.log('PetCare+ local emulator demo reset and seeded.');
  console.log('Project: demo-petcare (local emulators only)');
  console.log(`Validated and seeded ${Object.keys(writes).length} documents for ${localDay} Sri Lanka time.`);
  for (const [, email] of accounts) {
    console.log(`- ${email}`);
  }
}

main().catch((error) => {
  console.error(error.message);
  process.exitCode = 1;
});
