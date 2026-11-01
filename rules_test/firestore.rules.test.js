const {
  assertFails,
  assertSucceeds,
  initializeTestEnvironment,
} = require('@firebase/rules-unit-testing');

const {
  collection,
  deleteDoc,
  doc,
  getDoc,
  getDocs,
  query,
  serverTimestamp,
  setDoc,
  updateDoc,
  where,
} = require('firebase/firestore');

const fs = require('fs');
const path = require('path');

let testEnv;

// ================================================================
// TEST HELPERS
// ================================================================

async function seedUser(db, uid, role, fullName) {
  await setDoc(doc(db, 'users', uid), {
    uid,
    fullName,
    displayName: fullName,
    email: `${uid}@example.com`,
    phone: '+94770000000',
    role,
    notificationEnabled: true,
    createdAt: new Date(),
    updatedAt: new Date(),
  });
}

async function seedVeterinarian(db, uid, hospitalId, fullName) {
  await setDoc(doc(db, 'veterinarians', uid), {
    userId: uid,
    hospitalId,
    fullName,
    role: 'veterinarian',
    isActive: true,
    createdAt: new Date(),
    updatedAt: new Date(),
  });
}

async function seedHospitalStaff(db, uid, hospitalId, active = true) {
  await setDoc(doc(db, 'hospital_staff', uid), {
    userId: uid,
    hospitalId,
    active,
    assignedAt: new Date(),
  });
}

async function seedAppointment(
  appointmentId,
  {
    ownerId = 'owner-a',
    petId = 'pet-a',
    hospitalId = 'hospital-a',
    vetId = 'vet-a',
  } = {},
) {
  await testEnv.withSecurityRulesDisabled(async (context) => {
    const db = context.firestore();

    await setDoc(doc(db, 'appointments', appointmentId), {
      ownerId,
      petId,
      hospitalId,
      serviceId: 'service-a',
      vetId,
      dateTime: new Date(),
      reason: 'Routine checkup',
      status: 'confirmed',
      createdAt: new Date(),
      updatedAt: new Date(),
    });
  });
}

async function seedQueueRecord(
  queueId,
  {
    ownerId = 'owner-a',
    petId = 'pet-a',
    appointmentId = 'appointment-a',
    hospitalId = 'hospital-a',
    queueNumber = 1,
    status = 'waiting',
  } = {},
) {
  await testEnv.withSecurityRulesDisabled(async (context) => {
    const db = context.firestore();

    await setDoc(doc(db, 'queue_records', queueId), {
      ownerId,
      petId,
      appointmentId,
      hospitalId,
      queueNumber,
      status,
      currentServing: 0,
      position: 1,
      createdAt: new Date(),
      updatedAt: new Date(),
    });
  });
}

// ================================================================
// TEST ENVIRONMENT
// ================================================================

before(async function () {
  this.timeout(10000);

  testEnv = await initializeTestEnvironment({
    projectId: 'petcare-d4413',
    firestore: {
      rules: fs.readFileSync(
        path.join(__dirname, '..', 'firestore.rules'),
        'utf8',
      ),
      host: '127.0.0.1',
      port: 8080,
    },
  });
});

after(async function () {
  this.timeout(10000);

  if (testEnv) {
    await testEnv.cleanup();
  }
});

beforeEach(async function () {
  this.timeout(10000);

  await testEnv.clearFirestore();

  await testEnv.withSecurityRulesDisabled(async (context) => {
    const db = context.firestore();

    // ------------------------------------------------------------
    // Owners
    // ------------------------------------------------------------

    await seedUser(db, 'owner-a', 'owner', 'Owner A');
    await seedUser(db, 'owner-b', 'owner', 'Owner B');

    // ------------------------------------------------------------
    // Veterinarians
    // ------------------------------------------------------------

    await seedUser(db, 'vet-a', 'veterinarian', 'Dr. Vet A');
    await seedUser(db, 'vet-b', 'veterinarian', 'Dr. Vet B');

    await seedVeterinarian(
      db,
      'vet-a',
      'hospital-a',
      'Dr. Vet A',
    );

    await seedVeterinarian(
      db,
      'vet-b',
      'hospital-b',
      'Dr. Vet B',
    );

    // ------------------------------------------------------------
    // Hospital Staff
    // ------------------------------------------------------------

    await seedUser(
      db,
      'staff-a',
      'veterinary_staff',
      'Staff A',
    );

    await seedUser(
      db,
      'staff-b',
      'veterinary_staff',
      'Staff B',
    );

    await seedUser(
      db,
      'staff-inactive',
      'veterinary_staff',
      'Inactive Staff',
    );

    await seedUser(
      db,
      'staff-unassigned',
      'veterinary_staff',
      'Unassigned Staff',
    );

    await seedUser(
      db,
      'staff-new',
      'veterinary_staff',
      'New Staff',
    );

    // Staff A is assigned to Hospital A.
    await seedHospitalStaff(
      db,
      'staff-a',
      'hospital-a',
      true,
    );

    // Staff B is assigned to Hospital B.
    await seedHospitalStaff(
      db,
      'staff-b',
      'hospital-b',
      true,
    );

    // Inactive staff must not access hospital resources.
    await seedHospitalStaff(
      db,
      'staff-inactive',
      'hospital-a',
      false,
    );

    // An unassigned staff account must not access any hospital.
    await seedHospitalStaff(
      db,
      'staff-unassigned',
      'unassigned',
      true,
    );

    // staff-new deliberately has no hospital_staff assignment.
    // It is used to test unauthorized assignment creation.
  });
});

// ================================================================
// USER PROFILE SECURITY
// ================================================================

describe('USER PROFILE SECURITY', function () {
  it('allows a user to read their own profile', async function () {
    const db = testEnv.authenticatedContext('owner-a').firestore();

    await assertSucceeds(
      getDoc(doc(db, 'users', 'owner-a')),
    );
  });

  it('denies reading another user profile', async function () {
    const db = testEnv.authenticatedContext('owner-a').firestore();

    await assertFails(
      getDoc(doc(db, 'users', 'owner-b')),
    );
  });

  it('allows creation of a valid owner profile', async function () {
    const db = testEnv.authenticatedContext('owner-new').firestore();

    await assertSucceeds(
      setDoc(doc(db, 'users', 'owner-new'), {
        uid: 'owner-new',
        fullName: 'New Owner',
        displayName: 'New Owner',
        email: 'new-owner@example.com',
        phone: '',
        role: 'owner',
        notificationEnabled: true,
        createdAt: serverTimestamp(),
        updatedAt: serverTimestamp(),
      }),
    );
  });

  it('denies client creation of a privileged profile', async function () {
    const db = testEnv.authenticatedContext('new-vet').firestore();

    await assertFails(
      setDoc(doc(db, 'users', 'new-vet'), {
        uid: 'new-vet',
        fullName: 'New Vet',
        displayName: 'New Vet',
        email: 'new-vet@example.com',
        phone: '',
        role: 'veterinarian',
        notificationEnabled: true,
        createdAt: serverTimestamp(),
        updatedAt: serverTimestamp(),
      }),
    );
  });

  it('denies changing the existing role', async function () {
    const db = testEnv.authenticatedContext('owner-a').firestore();

    await assertFails(
      updateDoc(doc(db, 'users', 'owner-a'), {
        role: 'veterinarian',
        updatedAt: serverTimestamp(),
      }),
    );
  });

  it('denies changing the UID', async function () {
    const db = testEnv.authenticatedContext('owner-a').firestore();

    await assertFails(
      updateDoc(doc(db, 'users', 'owner-a'), {
        uid: 'owner-b',
        updatedAt: serverTimestamp(),
      }),
    );
  });

  it('allows supported profile updates', async function () {
    const db = testEnv.authenticatedContext('owner-a').firestore();

    await assertSucceeds(
      updateDoc(doc(db, 'users', 'owner-a'), {
        fullName: 'Owner A Updated',
        displayName: 'Owner A Updated',
        phone: '+94770000011',
        updatedAt: serverTimestamp(),
      }),
    );
  });

  it('allows notification preference updates', async function () {
    const db = testEnv.authenticatedContext('owner-a').firestore();

    await assertSucceeds(
      updateDoc(doc(db, 'users', 'owner-a'), {
        notificationEnabled: false,
        updatedAt: serverTimestamp(),
      }),
    );
  });

  it('denies changing the email field', async function () {
    const db = testEnv.authenticatedContext('owner-a').firestore();

    await assertFails(
      updateDoc(doc(db, 'users', 'owner-a'), {
        email: 'attacker@example.com',
        updatedAt: serverTimestamp(),
      }),
    );
  });

  it('denies modifying creation time', async function () {
    const db = testEnv.authenticatedContext('owner-a').firestore();

    await assertFails(
      updateDoc(doc(db, 'users', 'owner-a'), {
        createdAt: serverTimestamp(),
        updatedAt: serverTimestamp(),
      }),
    );
  });

  it('denies adding an unauthorized field', async function () {
    const db = testEnv.authenticatedContext('owner-a').firestore();

    await assertFails(
      updateDoc(doc(db, 'users', 'owner-a'), {
        isAdmin: true,
        updatedAt: serverTimestamp(),
      }),
    );
  });

  it('denies client-side profile deletion', async function () {
    const db = testEnv.authenticatedContext('owner-a').firestore();

    await assertFails(
      deleteDoc(doc(db, 'users', 'owner-a')),
    );
  });
});

// ================================================================
// PET SECURITY
// ================================================================

describe('PET SECURITY', function () {
  it('owner can create and read their own pet', async function () {
    const ownerContext = testEnv.authenticatedContext('owner-a');
    const ownerDb = ownerContext.firestore();
    const petRef = doc(ownerDb, 'pets', 'pet-a');

    await assertSucceeds(
      setDoc(petRef, {
        ownerId: 'owner-a',
        name: 'Buddy',
        species: 'dog',
        gender: 'male',
        createdAt: new Date(),
        updatedAt: new Date(),
      }),
    );

    await assertSucceeds(
      getDoc(petRef),
    );
  });

  it("owner cannot read another owner's pet", async function () {
    await testEnv.withSecurityRulesDisabled(async (context) => {
      const db = context.firestore();

      await setDoc(doc(db, 'pets', 'pet-b'), {
        ownerId: 'owner-b',
        name: 'Milo',
        species: 'cat',
        gender: 'male',
        createdAt: new Date(),
        updatedAt: new Date(),
      });
    });

    const ownerDb = testEnv.authenticatedContext('owner-a').firestore();

    await assertFails(
      getDoc(doc(ownerDb, 'pets', 'pet-b')),
    );
  });
});

// ================================================================
// APPOINTMENT SECURITY
// ================================================================

describe('APPOINTMENT SECURITY', function () {
  it('owner can create and read their own appointment', async function () {
    const ownerContext = testEnv.authenticatedContext('owner-a');
    const ownerDb = ownerContext.firestore();

    // Create the owner's pet.
    await assertSucceeds(
      setDoc(doc(ownerDb, 'pets', 'pet-a'), {
        ownerId: 'owner-a',
        name: 'Buddy',
        species: 'dog',
        gender: 'male',
        createdAt: new Date(),
        updatedAt: new Date(),
      }),
    );

    const appointmentRef = doc(
      ownerDb,
      'appointments',
      'appointment-a',
    );

    await assertSucceeds(
      setDoc(appointmentRef, {
        ownerId: 'owner-a',
        petId: 'pet-a',
        hospitalId: 'hospital-a',
        serviceId: 'service-a',
        veterinarianId: 'vet-a',
        appointmentDate: new Date(),
        reason: 'Routine checkup',
        status: 'pending',
        createdAt: new Date(),
        updatedAt: new Date(),
      }),
    );

    await assertSucceeds(
      getDoc(appointmentRef),
    );
  });

  it("owner cannot read another owner's appointment", async function () {
    await seedAppointment('appointment-b', {
      ownerId: 'owner-b',
      petId: 'pet-b',
      hospitalId: 'hospital-a',
      vetId: 'vet-a',
    });

    const ownerDb = testEnv.authenticatedContext('owner-a').firestore();

    await assertFails(
      getDoc(doc(ownerDb, 'appointments', 'appointment-b')),
    );
  });

  it("owner cannot create an appointment for another owner's pet", async function () {
    await testEnv.withSecurityRulesDisabled(async (context) => {
      const db = context.firestore();

      await setDoc(doc(db, 'pets', 'pet-b'), {
        ownerId: 'owner-b',
        name: 'Milo',
        species: 'cat',
        gender: 'male',
        createdAt: new Date(),
        updatedAt: new Date(),
      });
    });

    const ownerDb = testEnv.authenticatedContext('owner-a').firestore();

    await assertFails(
      setDoc(doc(ownerDb, 'appointments', 'appointment-x'), {
        ownerId: 'owner-a',
        petId: 'pet-b',
        hospitalId: 'hospital-a',
        serviceId: 'service-a',
        veterinarianId: 'vet-a',
        appointmentDate: new Date(),
        reason: 'Routine checkup',
        status: 'pending',
        createdAt: new Date(),
        updatedAt: new Date(),
      }),
    );
  });

  it('staff can read appointments belonging to their assigned hospital', async function () {
    await seedAppointment('appointment-staff-a');

    const staffDb = testEnv.authenticatedContext('staff-a').firestore();

    await assertSucceeds(
      getDoc(doc(staffDb, 'appointments', 'appointment-staff-a')),
    );
  });

  it('staff cannot read appointments belonging to another hospital', async function () {
    await seedAppointment('appointment-hospital-a');

    const staffDb = testEnv.authenticatedContext('staff-b').firestore();

    await assertFails(
      getDoc(doc(staffDb, 'appointments', 'appointment-hospital-a')),
    );
  });

  it('inactive staff cannot read hospital appointments', async function () {
    await seedAppointment('appointment-inactive-staff');

    const staffDb = testEnv
      .authenticatedContext('staff-inactive')
      .firestore();

    await assertFails(
      getDoc(doc(staffDb, 'appointments', 'appointment-inactive-staff')),
    );
  });

  it('unassigned staff cannot read hospital appointments', async function () {
    await seedAppointment('appointment-unassigned-staff');

    const staffDb = testEnv
      .authenticatedContext('staff-unassigned')
      .firestore();

    await assertFails(
      getDoc(doc(staffDb, 'appointments', 'appointment-unassigned-staff')),
    );
  });

  it('staff can query appointments for their assigned hospital', async function () {
    await seedAppointment('appointment-query-a', {
      hospitalId: 'hospital-a',
    });

    const staffDb = testEnv.authenticatedContext('staff-a').firestore();

    const hospitalAppointmentsQuery = query(
      collection(staffDb, 'appointments'),
      where('hospitalId', '==', 'hospital-a'),
    );

    await assertSucceeds(
      getDocs(hospitalAppointmentsQuery),
    );
  });

  it('staff cannot query all hospitals appointments without a hospital filter', async function () {
    await seedAppointment('appointment-query-unfiltered-a', {
      hospitalId: 'hospital-a',
    });

    const staffDb = testEnv.authenticatedContext('staff-a').firestore();

    await assertFails(
      getDocs(collection(staffDb, 'appointments')),
    );
  });
});

// ================================================================
// HOSPITAL STAFF ASSIGNMENT SECURITY
// ================================================================

describe('HOSPITAL STAFF ASSIGNMENT SECURITY', function () {
  it('staff can read their own hospital assignment', async function () {
    const staffDb = testEnv.authenticatedContext('staff-a').firestore();

    await assertSucceeds(
      getDoc(doc(staffDb, 'hospital_staff', 'staff-a')),
    );
  });

  it('staff cannot read another staff member assignment', async function () {
    const staffDb = testEnv.authenticatedContext('staff-a').firestore();

    await assertFails(
      getDoc(doc(staffDb, 'hospital_staff', 'staff-b')),
    );
  });

  it('staff cannot list hospital staff assignments', async function () {
    const staffDb = testEnv.authenticatedContext('staff-a').firestore();

    await assertFails(
      getDocs(collection(staffDb, 'hospital_staff')),
    );
  });

  it('staff cannot create their own hospital assignment', async function () {
    const staffDb = testEnv.authenticatedContext('staff-new').firestore();

    await assertFails(
      setDoc(doc(staffDb, 'hospital_staff', 'staff-new'), {
        userId: 'staff-new',
        hospitalId: 'hospital-a',
        active: true,
        assignedAt: serverTimestamp(),
      }),
    );
  });

  it('staff cannot modify their existing hospital assignment', async function () {
    const staffDb = testEnv.authenticatedContext('staff-a').firestore();

    await assertFails(
      updateDoc(doc(staffDb, 'hospital_staff', 'staff-a'), {
        hospitalId: 'hospital-b',
      }),
    );
  });

  it('staff cannot deactivate their own assignment', async function () {
    const staffDb = testEnv.authenticatedContext('staff-a').firestore();

    await assertFails(
      updateDoc(doc(staffDb, 'hospital_staff', 'staff-a'), {
        active: false,
      }),
    );
  });

  it('staff cannot delete their own hospital assignment', async function () {
    const staffDb = testEnv.authenticatedContext('staff-a').firestore();

    await assertFails(
      deleteDoc(doc(staffDb, 'hospital_staff', 'staff-a')),
    );
  });

  it('inactive staff can read their own assignment but cannot access hospital resources', async function () {
    const staffDb = testEnv
      .authenticatedContext('staff-inactive')
      .firestore();

    await assertSucceeds(
      getDoc(doc(staffDb, 'hospital_staff', 'staff-inactive')),
    );

    await seedAppointment('appointment-inactive-assignment');

    await assertFails(
      getDoc(doc(staffDb, 'appointments', 'appointment-inactive-assignment')),
    );
  });

  it('unassigned staff cannot access a hospital appointment', async function () {
    await seedAppointment('appointment-unassigned-access');

    const staffDb = testEnv
      .authenticatedContext('staff-unassigned')
      .firestore();

    await assertFails(
      getDoc(doc(staffDb, 'appointments', 'appointment-unassigned-access')),
    );
  });
});

// ================================================================
// QUEUE SECURITY
// ================================================================

describe('HOSPITAL QUEUE SECURITY', function () {
  it('staff can read queue records belonging to their assigned hospital', async function () {
    await seedQueueRecord('queue-a');

    const staffDb = testEnv.authenticatedContext('staff-a').firestore();

    await assertSucceeds(
      getDoc(doc(staffDb, 'queue_records', 'queue-a')),
    );
  });

  it('staff cannot read queue records belonging to another hospital', async function () {
    await seedQueueRecord('queue-hospital-a', {
      hospitalId: 'hospital-a',
    });

    const staffDb = testEnv.authenticatedContext('staff-b').firestore();

    await assertFails(
      getDoc(doc(staffDb, 'queue_records', 'queue-hospital-a')),
    );
  });

  it('staff can create queue records for their assigned hospital', async function () {
    const staffDb = testEnv.authenticatedContext('staff-a').firestore();

    await assertSucceeds(
      setDoc(doc(staffDb, 'queue_records', 'queue-new-a'), {
        ownerId: 'owner-a',
        petId: 'pet-a',
        appointmentId: 'appointment-a',
        hospitalId: 'hospital-a',
        queueNumber: 1,
        status: 'waiting',
        currentServing: 0,
        position: 1,
        createdAt: new Date(),
        updatedAt: new Date(),
      }),
    );
  });

  it('staff cannot create queue records for another hospital', async function () {
    const staffDb = testEnv.authenticatedContext('staff-a').firestore();

    await assertFails(
      setDoc(doc(staffDb, 'queue_records', 'queue-new-b'), {
        ownerId: 'owner-a',
        petId: 'pet-a',
        appointmentId: 'appointment-a',
        hospitalId: 'hospital-b',
        queueNumber: 1,
        status: 'waiting',
        currentServing: 0,
        position: 1,
        createdAt: new Date(),
        updatedAt: new Date(),
      }),
    );
  });

  it('staff can update queue status within their assigned hospital', async function () {
    await seedQueueRecord('queue-update-a');

    const staffDb = testEnv.authenticatedContext('staff-a').firestore();

    await assertSucceeds(
      updateDoc(doc(staffDb, 'queue_records', 'queue-update-a'), {
        status: 'called',
        updatedAt: serverTimestamp(),
      }),
    );
  });

  it('staff cannot update queue records belonging to another hospital', async function () {
    await seedQueueRecord('queue-update-b', {
      hospitalId: 'hospital-b',
    });

    const staffDb = testEnv.authenticatedContext('staff-a').firestore();

    await assertFails(
      updateDoc(doc(staffDb, 'queue_records', 'queue-update-b'), {
        status: 'called',
        updatedAt: serverTimestamp(),
      }),
    );
  });

  it('staff can query queue records for their assigned hospital', async function () {
    await seedQueueRecord('queue-query-a', {
      hospitalId: 'hospital-a',
    });

    const staffDb = testEnv.authenticatedContext('staff-a').firestore();

    const hospitalQueueQuery = query(
      collection(staffDb, 'queue_records'),
      where('hospitalId', '==', 'hospital-a'),
    );

    await assertSucceeds(
      getDocs(hospitalQueueQuery),
    );
  });

  it('staff cannot query queue records from all hospitals', async function () {
    await seedQueueRecord('queue-query-unfiltered');

    const staffDb = testEnv.authenticatedContext('staff-a').firestore();

    await assertFails(
      getDocs(collection(staffDb, 'queue_records')),
    );
  });

  it('inactive staff cannot read queue records', async function () {
    await seedQueueRecord('queue-inactive');

    const staffDb = testEnv
      .authenticatedContext('staff-inactive')
      .firestore();

    await assertFails(
      getDoc(doc(staffDb, 'queue_records', 'queue-inactive')),
    );
  });
});

// ================================================================
// VETERINARY SECURITY
// ================================================================

describe('VETERINARY SECURITY', function () {
  it('veterinarian can read an appointment in their assigned hospital', async function () {
    await seedAppointment('appointment-vet-a');

    const vetDb = testEnv.authenticatedContext('vet-a').firestore();

    await assertSucceeds(
      getDoc(doc(vetDb, 'appointments', 'appointment-vet-a')),
    );
  });

  it('veterinarian from another hospital cannot read the appointment', async function () {
    await seedAppointment('appointment-vet-hospital-a');

    const vetDb = testEnv.authenticatedContext('vet-b').firestore();

    await assertFails(
      getDoc(doc(vetDb, 'appointments', 'appointment-vet-hospital-a')),
    );
  });

  it('veterinarian can read queue records in their assigned hospital', async function () {
    await seedQueueRecord('queue-vet-a');

    const vetDb = testEnv.authenticatedContext('vet-a').firestore();

    await assertSucceeds(
      getDoc(doc(vetDb, 'queue_records', 'queue-vet-a')),
    );
  });

  it('veterinarian cannot read queue records from another hospital', async function () {
    await seedQueueRecord('queue-vet-hospital-a', {
      hospitalId: 'hospital-a',
    });

    const vetDb = testEnv.authenticatedContext('vet-b').firestore();

    await assertFails(
      getDoc(doc(vetDb, 'queue_records', 'queue-vet-hospital-a')),
    );
  });

  it('staff cannot modify hospital configuration', async function () {
    await testEnv.withSecurityRulesDisabled(async (context) => {
      const db = context.firestore();

      await setDoc(doc(db, 'hospitals', 'hospital-a'), {
        hospitalId: 'hospital-a',
        name: 'Hospital A',
        active: true,
      });
    });

    const staffDb = testEnv.authenticatedContext('staff-a').firestore();

    await assertFails(
      updateDoc(doc(staffDb, 'hospitals', 'hospital-a'), {
        name: 'Changed Hospital Name',
      }),
    );
  });
});
