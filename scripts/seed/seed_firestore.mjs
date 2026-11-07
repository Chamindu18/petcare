import { getApps, initializeApp, cert } from "firebase-admin/app";
import { getFirestore } from "firebase-admin/firestore";
import { readFileSync } from "node:fs";

const PROJECT_ID = "petcare-d4413";
const DEFAULT_CONTACT = "011-1234568";

const SERVICES = [
  {
    suffix: "001",
    name: "General Consultation",
    description: "General health examination and consultation for pets.",
    duration: 30,
  },
  {
    suffix: "002",
    name: "Vaccination",
    description: "Routine vaccination services for pets.",
    duration: 20,
  },
  {
    suffix: "003",
    name: "Dental Checkup",
    description: "Dental examination and basic dental care for pets.",
    duration: 30,
  },
  {
    suffix: "004",
    name: "Grooming",
    description: "Professional grooming services for pets.",
    duration: 60,
  },
  {
    suffix: "005",
    name: "Emergency Consultation",
    description: "Urgent veterinary consultation for pets.",
    duration: 30,
  },
];

const EXISTING_HOSPITALS_NEEDING_SERVICES = [
  "hospital_002",
  "hospital_003",
  "hospital_004",
  "hospital_005",
  "hospital_006",
  "hospital_007",
  "hospital_008",
  "hospital_009",
  "hospital_010",
  "hospital_011",
];
const HOSPITALS = [
  ["hospital_012", "Jaffna Paws Veterinary Hospital", "Jaffna", "9 AM - 6 PM"],
  ["hospital_013", "Kandy Pet Health Centre", "Kandy", "8 AM - 8 PM"],
  ["hospital_014", "Galle PetCare Hospital", "Galle", "8 AM - 7 PM"],
  ["hospital_015", "Negombo Animal Care Hospital", "Negombo", "9 AM - 7 PM"],
  ["hospital_016", "Matara Veterinary Hospital", "Matara", "8 AM - 6 PM"],
  ["hospital_017", "Kurunegala PetCare Centre", "Kurunegala", "8 AM - 8 PM"],
  [
    "hospital_018",
    "Anuradhapura Animal Hospital",
    "Anuradhapura",
    "9 AM - 6 PM",
  ],
  ["hospital_019", "Ratnapura Pet Health Hospital", "Ratnapura", "8 AM - 6 PM"],
  ["hospital_020", "Badulla Veterinary Care Centre", "Badulla", "9 AM - 6 PM"],
  [
    "hospital_021",
    "Nuwara Eliya PetCare Hospital",
    "Nuwara Eliya",
    "9 AM - 5 PM",
  ],
  ["hospital_022", "Kalutara Animal Care Hospital", "Kalutara", "8 AM - 7 PM"],
  ["hospital_023", "Panadura Pet Health Centre", "Panadura", "8 AM - 8 PM"],
  ["hospital_024", "Wattala Veterinary Hospital", "Wattala", "9 AM - 7 PM"],
  ["hospital_025", "Kaduwela PetCare Hospital", "Kaduwela", "8 AM - 8 PM"],
  ["hospital_026", "Homagama Animal Hospital", "Homagama", "9 AM - 7 PM"],
  ["hospital_027", "Maharagama Pet Health Centre", "Maharagama", "8 AM - 8 PM"],
  ["hospital_028", "Moratuwa Veterinary Hospital", "Moratuwa", "9 AM - 7 PM"],
  ["hospital_029", "Dehiwala PetCare Hospital", "Dehiwala", "8 AM - 8 PM"],
  [
    "hospital_030",
    "Mount Lavinia Animal Hospital",
    "Mount Lavinia",
    "9 AM - 7 PM",
  ],
  ["hospital_031", "Batticaloa Veterinary Centre", "Batticaloa", "9 AM - 6 PM"],
  [
    "hospital_032",
    "Trincomalee PetCare Hospital",
    "Trincomalee",
    "9 AM - 6 PM",
  ],
];

const VETERINARIANS = [
  [
    "vet_045",
    "hospital_002",
    "Dr. Kasun Jayawardena",
    "Small Animal Medicine",
    6,
  ],
  ["vet_046", "hospital_003", "Dr. Nethmi Perera", "Veterinary Surgery", 5],
  ["vet_047", "hospital_004", "Dr. Tharindu Silva", "Small Animal Medicine", 7],
  ["vet_048", "hospital_005", "Dr. Piumi Fernando", "Veterinary Surgery", 6],
  ["vet_049", "hospital_006", "Dr. Chamara Perera", "Small Animal Medicine", 8],
  ["vet_050", "hospital_007", "Dr. Dilki Silva", "Veterinary Surgery", 5],
  [
    "vet_051",
    "hospital_008",
    "Dr. Kavindu Fernando",
    "Small Animal Medicine",
    6,
  ],
  ["vet_052", "hospital_009", "Dr. Oshadi Perera", "Veterinary Surgery", 5],
  ["vet_053", "hospital_010", "Dr. Ramesh Silva", "Small Animal Medicine", 7],
  ["vet_054", "hospital_011", "Dr. Shehani Fernando", "Veterinary Surgery", 6],

  ["vet_003", "hospital_012", "Dr. Dilan Fernando", "Small Animal Medicine", 7],
  ["vet_004", "hospital_012", "Dr. Sachini Perera", "Veterinary Surgery", 6],
  ["vet_005", "hospital_013", "Dr. Kavindu Silva", "Small Animal Medicine", 7],
  ["vet_006", "hospital_013", "Dr. Ishara Perera", "Veterinary Surgery", 6],
  ["vet_007", "hospital_014", "Dr. Ruwan Fernando", "Small Animal Medicine", 7],
  ["vet_008", "hospital_014", "Dr. Dinithi Silva", "Veterinary Surgery", 6],
  ["vet_009", "hospital_015", "Dr. Nuwan Perera", "Small Animal Medicine", 7],
  ["vet_010", "hospital_015", "Dr. Hansani Fernando", "Veterinary Surgery", 6],
  ["vet_011", "hospital_016", "Dr. Chathura Silva", "Small Animal Medicine", 7],
  ["vet_012", "hospital_016", "Dr. Piumi Perera", "Veterinary Surgery", 6],
  ["vet_013", "hospital_017", "Dr. Isuru Fernando", "Small Animal Medicine", 7],
  ["vet_014", "hospital_017", "Dr. Malki Silva", "Veterinary Surgery", 6],
  ["vet_015", "hospital_018", "Dr. Gayan Perera", "Small Animal Medicine", 7],
  ["vet_016", "hospital_018", "Dr. Tharushi Fernando", "Veterinary Surgery", 6],
  ["vet_017", "hospital_019", "Dr. Nimesh Silva", "Small Animal Medicine", 7],
  ["vet_018", "hospital_019", "Dr. Shenali Perera", "Veterinary Surgery", 6],
  [
    "vet_019",
    "hospital_020",
    "Dr. Sandun Fernando",
    "Small Animal Medicine",
    7,
  ],
  ["vet_020", "hospital_020", "Dr. Amaya Silva", "Veterinary Surgery", 6],
  ["vet_021", "hospital_021", "Dr. Lakshan Perera", "Small Animal Medicine", 7],
  ["vet_022", "hospital_021", "Dr. Hasini Fernando", "Veterinary Surgery", 6],
  ["vet_023", "hospital_022", "Dr. Dinuka Silva", "Small Animal Medicine", 7],
  ["vet_024", "hospital_022", "Dr. Sewmini Perera", "Veterinary Surgery", 6],
  [
    "vet_025",
    "hospital_023",
    "Dr. Kavishka Fernando",
    "Small Animal Medicine",
    7,
  ],
  ["vet_026", "hospital_023", "Dr. Tharuka Silva", "Veterinary Surgery", 6],
  ["vet_027", "hospital_024", "Dr. Gayan Silva", "Small Animal Medicine", 7],
  ["vet_028", "hospital_024", "Dr. Hansika Perera", "Veterinary Surgery", 6],
  [
    "vet_029",
    "hospital_025",
    "Dr. Asela Wickramasinghe",
    "Small Animal Medicine",
    7,
  ],
  ["vet_030", "hospital_025", "Dr. Tharushi Bandara", "Veterinary Surgery", 6],
  [
    "vet_031",
    "hospital_026",
    "Dr. Nimesh Karunaratne",
    "Small Animal Medicine",
    7,
  ],
  ["vet_032", "hospital_026", "Dr. Shenali Silva", "Veterinary Surgery", 6],
  ["vet_033", "hospital_027", "Dr. Isuru Fernando", "Small Animal Medicine", 7],
  ["vet_034", "hospital_027", "Dr. Malki Wijesinghe", "Veterinary Surgery", 6],
  ["vet_035", "hospital_028", "Dr. Roshan Kumara", "Small Animal Medicine", 7],
  ["vet_036", "hospital_028", "Dr. Dewmini Perera", "Veterinary Surgery", 6],
  [
    "vet_037",
    "hospital_029",
    "Dr. Sandun Jayasinghe",
    "Small Animal Medicine",
    7,
  ],
  ["vet_038", "hospital_029", "Dr. Amaya Silva", "Veterinary Surgery", 6],
  [
    "vet_039",
    "hospital_030",
    "Dr. Lakshan Gunawardena",
    "Small Animal Medicine",
    7,
  ],
  ["vet_040", "hospital_030", "Dr. Hasini Fernando", "Veterinary Surgery", 6],
  ["vet_041", "hospital_031", "Dr. Dinuka Perera", "Small Animal Medicine", 7],
  ["vet_042", "hospital_031", "Dr. Sewmini Ratnayake", "Veterinary Surgery", 6],
  ["vet_043", "hospital_032", "Dr. Kavishka Silva", "Small Animal Medicine", 7],
  ["vet_044", "hospital_032", "Dr. Tharuka Wijeratne", "Veterinary Surgery", 6],
];

function buildHospital([hospitalId, name, location, hours]) {
  return {
    hospitalId,
    name,
    location,
    contact: DEFAULT_CONTACT,
    hours,
    active: true,
  };
}

function buildServices(hospitalId) {
  return SERVICES.map((service) => {
    const serviceId = `${hospitalId}_service_${service.suffix}`;

    return {
      id: serviceId,
      data: {
        serviceId,
        hospitalId,
        name: service.name,
        description: service.description,
        duration: service.duration,
        active: true,
      },
    };
  });
}

function buildVeterinarian([
  vetId,
  hospitalId,
  name,
  specialty,
  experienceYears,
]) {
  return {
    vetId,
    hospitalId,
    name,
    profileImageUrl: "",
    specialty,
    qualifications: "Bachelor of Veterinary Science",
    experienceYears,
    bio: `Experienced veterinarian specializing in ${specialty.toLowerCase()} and companion-animal care.`,
    active: true,
  };
}

function validateDataset() {
  const hospitalIds = new Set([
    ...HOSPITALS.map(([id]) => id),
    ...EXISTING_HOSPITALS_NEEDING_SERVICES,
  ]);
  const vetIds = new Set();

  if (HOSPITALS.length !== 21) {
    throw new Error(`Expected 21 hospitals, found ${HOSPITALS.length}.`);
  }

  if (VETERINARIANS.length !== 52) {
    throw new Error(
      `Expected 52 veterinarians, found ${VETERINARIANS.length}.`,
    );
  }

  if (SERVICES.length !== 5) {
    throw new Error(`Expected 5 services, found ${SERVICES.length}.`);
  }

  for (const [hospitalId] of HOSPITALS) {
    if (!/^hospital_0(1[2-9]|2[0-9]|3[0-2])$/.test(hospitalId)) {
      throw new Error(`Invalid hospital ID: ${hospitalId}`);
    }
  }

  for (const [vetId, hospitalId, , , experienceYears] of VETERINARIANS) {
    if (vetIds.has(vetId)) {
      throw new Error(`Duplicate veterinarian ID: ${vetId}`);
    }

    vetIds.add(vetId);

    if (!hospitalIds.has(hospitalId)) {
      throw new Error(
        `Veterinarian ${vetId} references missing hospital ${hospitalId}.`,
      );
    }

    if (!Number.isInteger(experienceYears) || experienceYears <= 0) {
      throw new Error(`Invalid experienceYears for ${vetId}.`);
    }
  }

  const expectedVetIds = Array.from(
    { length: 52 },
    (_, index) => `vet_${String(index + 3).padStart(3, "0")}`,
  );

  if (
    JSON.stringify([...vetIds].sort()) !== JSON.stringify(expectedVetIds.sort())
  ) {
    throw new Error("Veterinarian IDs do not match vet_003 through vet_054.");
  }

  for (const service of SERVICES) {
    if (!Number.isInteger(service.duration) || service.duration <= 0) {
      throw new Error(`Invalid duration for ${service.name}.`);
    }
  }

  const seededServiceCount =
    HOSPITALS.length * SERVICES.length +
    EXISTING_HOSPITALS_NEEDING_SERVICES.length * SERVICES.length;

  console.log("Dataset validation passed.");
  console.log(`Hospitals:      ${HOSPITALS.length}`);
  console.log(`Services:       ${seededServiceCount}`);
  console.log(`Veterinarians:  ${VETERINARIANS.length}`);
}

async function seed() {
  validateDataset();

  if (getApps().length === 0) {
    const serviceAccount = JSON.parse(
      readFileSync("./service-account-petcare.json", "utf8"),
    );

    initializeApp({
      credential: cert(serviceAccount),
      projectId: PROJECT_ID,
    });
  }

  const db = getFirestore();

  /*
   * The write phase is intentionally separated from validation.
   * This prevents malformed seed data from reaching Firestore.
   */
  const batch = db.batch();

  for (const hospital of HOSPITALS) {
    const [hospitalId] = hospital;
    const hospitalRef = db.collection("hospitals").doc(hospitalId);

    batch.set(hospitalRef, buildHospital(hospital));

    for (const service of buildServices(hospitalId)) {
      const serviceRef = db.collection("services").doc(service.id);
      batch.set(serviceRef, service.data);
    }
  }

  // Add services to hospitals_002 through hospital_011.
  // These hospital documents already exist, so they are not rewritten.
  for (const hospitalId of EXISTING_HOSPITALS_NEEDING_SERVICES) {
    for (const service of buildServices(hospitalId)) {
      const serviceRef = db.collection("services").doc(service.id);
      batch.set(serviceRef, service.data);
    }
  }

  for (const veterinarian of VETERINARIANS) {
    const [vetId] = veterinarian;
    const veterinarianRef = db.collection("veterinarians").doc(vetId);

    batch.set(veterinarianRef, buildVeterinarian(veterinarian));
  }

  await batch.commit();

  console.log("Firestore seed completed successfully.");
  console.log("Created/updated:");
  console.log(`  Hospitals:      ${HOSPITALS.length}`);
  console.log(
    `  Services:       ${
      HOSPITALS.length * SERVICES.length +
      EXISTING_HOSPITALS_NEEDING_SERVICES.length * SERVICES.length
    }`,
  );
  console.log(`  Veterinarians:   ${VETERINARIANS.length}`);
}

await seed();
