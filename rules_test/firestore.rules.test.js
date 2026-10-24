const {
  assertFails,
  assertSucceeds,
  initializeTestEnvironment,
} = require('@firebase/rules-unit-testing');

const {
  deleteDoc,
  doc,
  getDoc,
  serverTimestamp,
  setDoc,
  updateDoc,
} = require('firebase/firestore');

const fs = require('fs');
const path = require('path');

let testEnv;

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
    // Owner A
    // ------------------------------------------------------------
    await setDoc(doc(db, 'users', 'owner-a'), {
      uid: 'owner-a',
      fullName: 'Owner A',
      displayName: 'Owner A',
      email: 'owner-a@example.com',
      phone: '+94770000001',
      role: 'owner',
      notificationEnabled: true,
      createdAt: new Date(),
      updatedAt: new Date(),
    });

    // ------------------------------------------------------------
    // Owner B
    // ------------------------------------------------------------
    await setDoc(doc(db, 'users', 'owner-b'), {
      uid: 'owner-b',
      fullName: 'Owner B',
      displayName: 'Owner B',
      email: 'owner-b@example.com',
      phone: '+94770000002',
      role: 'owner',
      notificationEnabled: true,
      createdAt: new Date(),
      updatedAt: new Date(),
    });

    // ------------------------------------------------------------
    // Veterinarian A
    // ------------------------------------------------------------
    await setDoc(doc(db, 'users', 'vet-a'), {
      uid: 'vet-a',
      fullName: 'Dr. Vet A',
      displayName: 'Dr. Vet A',
      email: 'vet-a@example.com',
      phone: '+94770000003',
      role: 'veterinarian',
      notificationEnabled: true,
      createdAt: new Date(),
      updatedAt: new Date(),
    });

    await setDoc(doc(db, 'veterinarians', 'vet-a'), {
      userId: 'vet-a',
      hospitalId: 'hospital-a',
      fullName: 'Dr. Vet A',
      role: 'veterinarian',
      isActive: true,
      createdAt: new Date(),
      updatedAt: new Date(),
    });

    // ------------------------------------------------------------
    // Veterinary Staff A
    // ------------------------------------------------------------
    await setDoc(doc(db, 'users', 'staff-a'), {
      uid: 'staff-a',
      fullName: 'Staff A',
      displayName: 'Staff A',
      email: 'staff-a@example.com',
      phone: '+94770000004',
      role: 'veterinary_staff',
      notificationEnabled: true,
      createdAt: new Date(),
      updatedAt: new Date(),
    });

    await setDoc(doc(db, 'veterinarians', 'staff-a'), {
      userId: 'staff-a',
      hospitalId: 'hospital-a',
      fullName: 'Staff A',
      role: 'veterinary_staff',
      isActive: true,
      createdAt: new Date(),
      updatedAt: new Date(),
    });
  });
});

// ================================================================
// USER PROFILE SECURITY
// ================================================================

describe('USER PROFILE SECURITY', function () {
  it('allows a user to read their own profile', async function () {
    const db = testEnv.authenticatedContext('owner-a').firestore();

    await assertSucceeds(getDoc(doc(db, 'users', 'owner-a')));
  });

  it('denies reading another user profile', async function () {
    const db = testEnv.authenticatedContext('owner-a').firestore();

    await assertFails(getDoc(doc(db, 'users', 'owner-b')));
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

    await assertFails(deleteDoc(doc(db, 'users', 'owner-a')));
  });
});

// ================================================================
// PET SECURITY
// ================================================================

describe('PET SECURITY', function () {
  it('owner can create and read their own pet', async function () {
    this.timeout(10000);

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

    await assertSucceeds(getDoc(petRef));
  });

  it("owner cannot read another owner's pet", async function () {
    this.timeout(10000);

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

    const ownerContext = testEnv.authenticatedContext('owner-a');
    const ownerDb = ownerContext.firestore();

    await assertFails(getDoc(doc(ownerDb, 'pets', 'pet-b')));
  });
});

// ================================================================
// APPOINTMENT SECURITY
// ================================================================

describe('APPOINTMENT SECURITY', function () {
  it('owner can create and read their own appointment', async function () {
    this.timeout(10000);

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

    const appointmentRef = doc(ownerDb, 'appointments', 'appointment-a');

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

    await assertSucceeds(getDoc(appointmentRef));
  });

  it("owner cannot read another owner's appointment", async function () {
    this.timeout(10000);

    await testEnv.withSecurityRulesDisabled(async (context) => {
      const db = context.firestore();

      await setDoc(doc(db, 'appointments', 'appointment-b'), {
        ownerId: 'owner-b',
        petId: 'pet-b',
        hospitalId: 'hospital-a',
        serviceId: 'service-a',
        veterinarianId: 'vet-a',
        appointmentDate: new Date(),
        reason: 'Routine checkup',
        status: 'confirmed',
        createdAt: new Date(),
        updatedAt: new Date(),
      });
    });

    const ownerContext = testEnv.authenticatedContext('owner-a');
    const ownerDb = ownerContext.firestore();

    await assertFails(
      getDoc(doc(ownerDb, 'appointments', 'appointment-b')),
    );
  });

  it("owner cannot create an appointment for another owner's pet", async function () {
    this.timeout(10000);

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

    const ownerContext = testEnv.authenticatedContext('owner-a');
    const ownerDb = ownerContext.firestore();

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
});

// ================================================================
// VETERINARY SECURITY
// ================================================================

describe('VETERINARY SECURITY', function () {
  it('veterinarian can read an appointment', async function () {
    this.timeout(10000);

    await testEnv.withSecurityRulesDisabled(async (context) => {
      const db = context.firestore();

      await setDoc(doc(db, 'appointments', 'appointment-vet-a'), {
        ownerId: 'owner-a',
        petId: 'pet-a',
        hospitalId: 'hospital-a',
        serviceId: 'service-a',
        veterinarianId: 'vet-a',
        appointmentDate: new Date(),
        reason: 'Routine checkup',
        status: 'confirmed',
        createdAt: new Date(),
        updatedAt: new Date(),
      });
    });

    const vetContext = testEnv.authenticatedContext('vet-a');
    const vetDb = vetContext.firestore();

    await assertSucceeds(
      getDoc(doc(vetDb, 'appointments', 'appointment-vet-a')),
    );
  });

  it('veterinary staff can read an appointment', async function () {
    this.timeout(10000);

    await testEnv.withSecurityRulesDisabled(async (context) => {
      const db = context.firestore();

      await setDoc(doc(db, 'appointments', 'appointment-staff-a'), {
        ownerId: 'owner-a',
        petId: 'pet-a',
        hospitalId: 'hospital-a',
        serviceId: 'service-a',
        veterinarianId: 'vet-a',
        appointmentDate: new Date(),
        reason: 'Vaccination',
        status: 'confirmed',
        createdAt: new Date(),
        updatedAt: new Date(),
      });
    });

    const staffContext = testEnv.authenticatedContext('staff-a');
    const staffDb = staffContext.firestore();

    await assertSucceeds(
      getDoc(doc(staffDb, 'appointments', 'appointment-staff-a')),
    );
  });

  it('veterinary user from another hospital cannot read the appointment', async function () {
    this.timeout(10000);

    await testEnv.withSecurityRulesDisabled(async (context) => {
      const db = context.firestore();

      // Hospital A appointment.
      await setDoc(doc(db, 'appointments', 'appointment-hospital-a'), {
        ownerId: 'owner-a',
        petId: 'pet-a',
        hospitalId: 'hospital-a',
        serviceId: 'service-a',
        veterinarianId: 'vet-a',
        appointmentDate: new Date(),
        reason: 'Routine checkup',
        status: 'confirmed',
        createdAt: new Date(),
        updatedAt: new Date(),
      });

      // Veterinarian B belongs to Hospital B.
      await setDoc(doc(db, 'users', 'vet-b'), {
        uid: 'vet-b',
        fullName: 'Dr. Vet B',
        displayName: 'Dr. Vet B',
        email: 'vet-b@example.com',
        phone: '+94770000005',
        role: 'veterinarian',
        notificationEnabled: true,
        createdAt: new Date(),
        updatedAt: new Date(),
      });

      await setDoc(doc(db, 'veterinarians', 'vet-b'), {
        userId: 'vet-b',
        hospitalId: 'hospital-b',
        fullName: 'Dr. Vet B',
        role: 'veterinarian',
        isActive: true,
        createdAt: new Date(),
        updatedAt: new Date(),
      });
    });

    const vetContext = testEnv.authenticatedContext('vet-b');
    const vetDb = vetContext.firestore();

    await assertFails(
      getDoc(doc(vetDb, 'appointments', 'appointment-hospital-a')),
    );
  });
});