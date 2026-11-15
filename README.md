# PetCare+ 🐾

**Healthier Pets. Happier Lives.**

A Flutter-based mobile application that brings together pet profiles and health records, veterinary care, appointment and queue workflows, QR-based health information sharing, and pet adoption.

> **Project:** SE303.3 — Mobile Application Development  
> **Institution:** NSBM Green University, Faculty of Computing  
> **Group:** 29  
> **Repository:** https://github.com/Chamindu18/petcare

## About the project

Pet owners often manage veterinary appointments, health records, and adoption information through separate channels. PetCare+ provides a single role-based application where owners can keep pet information organized and coordinate with veterinary care teams, while hospitals, veterinarians, and adoption providers work in their dedicated interfaces.

The project is intended as an academic demonstration. Its complete, trusted appointment-booking workflow is supported in the **local Firebase Emulator Suite**. The shared Firebase **Spark** configuration does **not** deploy the required booking Cloud Function.

## User roles and features

| Role | Key functionality |
| --- | --- |
| **Pet Owner** | Manage pet profiles and images; record conditions, vaccinations, treatments and measurements; explore hospitals, veterinarians and services; view appointments and manually refresh queue status; generate appointment-linked QR Health Passports; browse adoption listings and requests; view notifications and pet-care guidance. |
| **Hospital Staff** | View an assigned hospital overview; review and manage appointments; assign or reassign veterinarians where supported; manage patient queue states; verify QR Health Passport information; access notifications and profile controls. |
| **Veterinarian** | View assigned appointments and patient details; use the assigned queue workspace; scan an appointment-linked QR Health Passport and review authorized records; view notifications and profile information. |
| **Adoption Provider** | Manage adoption listings; review and process incoming adoption requests; view notifications and sign out. |

### QR Health Passport

An owner can generate a time-limited, appointment-linked QR passport. The access window is **15 minutes**, and authorized users see only the information permitted by the current role and appointment association. The shared passport contains a **bounded selection of up to 12 recent health records**, rather than an unlimited medical history. QR generation and verification should be demonstrated on the local setup with eligible appointments.

### Pet-care guidance and notifications

PetCare+ includes pet-context guidance and health summaries. Some advice is deterministic/general guidance, **not a live AI diagnosis or medical recommendation**. The application also supports role-specific in-app notifications; a failure to mark an item as read should not silently masquerade as successful delivery or navigation.

## Technology stack

| Area | Technology |
| --- | --- |
| Mobile application | Flutter, Dart, Material 3 |
| App state and modular architecture | Provider, feature-first presentation/domain/data layers |
| Authentication | Firebase Authentication |
| Database and access control | Cloud Firestore and Firestore Security Rules |
| Trusted local appointment operations | Firebase Functions Emulator, Node.js 22 |
| Pet image hosting | Cloudinary |
| QR workflow | `qr_flutter`, `mobile_scanner` |
| Quality checks | Flutter unit/widget tests, Firestore rules tests, Functions integration tests |
| Collaboration | Git and GitHub |

## Architecture

PetCare+ organizes its Flutter code by feature, with a separation between UI, domain logic, and data access.

```text
lib/
├── app/                    # Routing and visual theme
├── core/                   # Shared configuration and services
├── features/
│   ├── adoption/
│   ├── ai_assistant/
│   ├── appointments/
│   ├── auth/
│   ├── health/
│   ├── home/
│   ├── hospital_staff/
│   ├── hospitals/
│   ├── notifications/
│   ├── pets/
│   ├── profile/
│   ├── qr_health_passport/
│   ├── queue/
│   └── veterinary/
├── shared/
└── main.dart
```

A typical feature uses:

```text
feature/
├── presentation/           # Screens, widgets and controllers/providers
├── domain/                 # Entities, repository contracts and use cases
└── data/                   # Models, Firebase repositories and data sources
```

**Typical request flow:** Flutter page → controller/provider → use case or repository contract → Firebase repository → Firebase service. The precise flow varies by feature. Firestore rules are an authorization boundary, not a substitute for server-side validation of privileged operations.

## Run the local demonstration (Windows)

### Requirements

- Flutter SDK and Android SDK / platform-tools
- Node.js **22** and npm
- A physical Android phone with USB debugging, or an Android emulator
- Repository dependencies installed
- No Firebase billing upgrade is needed for the local demo

Clone the repository and install dependencies:

```powershell
git clone https://github.com/Chamindu18/petcare.git
cd petcare
flutter pub get
npm.cmd ci
npm.cmd --prefix functions ci
```

Use the branch containing the latest demo setup and review the [local demo runbook](docs/DEMO_RUNBOOK.md) for detailed instructions and troubleshooting.

### Terminal 1 — Start the backend emulators

```powershell
npm.cmd run demo:emulators
```

Wait until Authentication, Firestore and Functions are ready. The Firebase Emulator UI is available at <http://127.0.0.1:4000>.

| Emulator | Local port |
| --- | ---: |
| Authentication | `9099` |
| Firestore | `8080` |
| Functions | `5001` |
| Emulator UI | `4000` |

### Terminal 2 — Seed and verify synthetic data

```powershell
$env:PETCARE_DEMO_PASSWORD = Read-Host 'Choose a demo password'
npm.cmd run demo:seed
node scripts/demo/seed_emulators.mjs --validate-only
node scripts/demo/verify_seeded.mjs
```

The seeder creates **six synthetic Auth accounts and 40 linked Firestore documents** in the **local `demo-petcare` project**. It resets local demo data, **not** the production Firebase project. Do not run it while another presenter is using the local demo.

### Terminal 3 — Connect the phone and run the app

For a **physical Android phone** connected by USB with debugging enabled:

```powershell
adb devices
adb reverse tcp:9099 tcp:9099
adb reverse tcp:8080 tcp:8080
adb reverse tcp:5001 tcp:5001
adb reverse --list
flutter devices
flutter run --dart-define=USE_FIREBASE_EMULATORS=true --dart-define=FIREBASE_EMULATOR_HOST=127.0.0.1
```

If several devices are connected, add `-d YOUR_DEVICE_ID` to `flutter run`. Keep the USB cable connected for the demonstration.

For the **Android Studio emulator**, run:

```powershell
flutter run --dart-define=USE_FIREBASE_EMULATORS=true
```

> **Important:** Use `USE_FIREBASE_EMULATORS=true` for the isolated demo. An ordinary launch uses the app's standard Firebase configuration and will not have the same trusted local booking functionality.

### Synthetic demo accounts

All six accounts use the **same password selected in Terminal 2**. No reusable password is stored in this README.

| Role | Email |
| --- | --- |
| Pet Owner | `owner.demo@petcare.test` |
| Second Pet Owner | `owner.two.demo@petcare.test` |
| Hospital Staff | `staff.demo@petcare.test` |
| Veterinarian A | `vet.a.demo@petcare.test` |
| Veterinarian B | `vet.b.demo@petcare.test` |
| Adoption Provider | `provider.demo@petcare.test` |

The synthetic accounts demonstrate role-restricted views and cross-role workflows. The second owner is useful for validating data isolation. Share the demo password securely with the team, not in Git history, a public README, or the recorded presentation.

### Rehearsal and reset

A recommended walkthrough is:

1. Sign in as the Pet Owner and show the seeded pets, health records, hospital discovery and appointments.
2. Show owner queue details and the manual refresh behavior.
3. Generate a fresh QR passport for the eligible confirmed appointment and verify it using the assigned veterinarian (or demonstrate staff QR header verification).
4. Show the Hospital Staff dashboard, appointment actions and patient queue.
5. Show the Veterinarian dashboard, assigned appointments and queue.
6. Show the Adoption Provider listings, requests and decisions, followed by relevant notifications.

To restore the demo to its original seeded state:

```powershell
npm.cmd run demo:seed
node scripts/demo/verify_seeded.mjs
```

Sign out or restart the app after reseeding. QR tokens expire after 15 minutes and must be generated again when needed. Reseed after Sri Lanka midnight to refresh date-relative records.

## Tests and verification

Run the normal Flutter checks:

```powershell
dart format --output=none --set-exit-if-changed lib test
flutter analyze --no-pub
flutter test --no-pub
```

The repository also contains emulator-backed tests for Firestore authorization, booking and cross-role workflows:

```powershell
npm.cmd run test:rules
npm.cmd run test:booking
```

These emulator test commands manage local emulator processes. Avoid running them concurrently with an active recorded demo or a backend instance already using the same ports.

**Latest user-reported demo verification (November 2026):** Six seeded account sign-ins and role workflows were manually exercised successfully on the demonstration setup. The preceding Codex setup report recorded **586 passing Flutter tests**, **8 passing booking/cross-role tests**, **7 passing QR authorization tests**, and no Flutter analyzer issues. These are reported results, not a claim of a new CI run or production deployment.

## Security and important limitations

- Firestore Security Rules enforce role and ownership restrictions on supported client operations.
- Appointment reservation and conflict handling require a trusted server-side path. **Do not enable direct client appointment creation to bypass this requirement.**
- The full booking demonstration runs with local Firebase emulators. The shared Spark project does not deploy the booking callable.
- Owner queue status uses **manual refresh**; do not describe it as automatically live-updating.
- Cloudinary photo removal/replacement can remove or change the Firestore URL without deleting an already hosted asset. Old URLs may remain accessible; see [image retention notes](docs/pet-image-retention.md).
- External Google Sign-In, remote AI services and Cloudinary uploads are not guaranteed by the isolated emulator seed and require separate integration verification.
- Do not commit passwords, service-account private keys, local emulator exports containing credentials, or private user information.
- The demo is academic software and should not be treated as a production veterinary medical-record system.

## Visual design

The application uses a warm, understated visual palette and Plus Jakarta Sans typography.

| Theme color | Hex |
| --- | --- |
| Primary | `#B5714A` |
| Secondary | `#E0B98D` |
| Background | `#F7EEE0` |
| Deep brown | `#8C5A3C` |
| Espresso | `#3D2417` |
| Success | `#4F9A6A` |

## Team and documentation

Developed by **Group 29**, NSBM Green University, for **SE303.3 — Mobile Application Development**.

| Name | Student index |
| --- | --- |
| R A C H Ranasinghe | 37014 |
| R P D A Mihisarani | 37047 |
| H H N V Induwara | 37171 |
| H M I Udara | 37020 |
| M C I Fernando | 37101 |

### Individual contributions

The following summarizes the team’s feature ownership and integration work. Detailed responsibilities for **Members 2, 4, and 5 are draft summaries based on the team workstream plan** and should be confirmed by those members before the README is published. Members 1 and 3 are based on the individual contribution statements in the current project report.

| Member | Name / Index | Contribution |
| --- | --- | --- |
| **1** | **R A C H Ranasinghe** · `37014` | Developed the application foundation, authentication and role-based routing, Pet Owner interface and Hospital Staff workspace; contributed to appointment validation, QR Health Passport, Firebase emulator setup, security checks, integration and regression testing. |
| **2** | **R P D A Mihisarani** · `37047` | **Draft — confirm:** Pet profile and health-record modules, including pet data management and medical conditions, vaccination, treatment and measurement workflows. |
| **3** | **H M I Udara** · `37020` | Developed hospital and veterinarian discovery, appointment booking and time-slot workflows, the Veterinarian Dashboard, veterinarian queue management and Pet Owner queue information; integrated Firebase data access, validation and role-based checks. |
| **4** | **M C I Fernando** · `37101` | **Draft — confirm:** Adoption listings and requests, notifications, and account/profile-related user workflows, including their integration with the relevant role interfaces. |
| **5** | **H H N V Induwara** · `37171` | **Draft — confirm:** Pet-care guidance features, shared integration tasks and quality assurance, including checking feature behavior and user-facing states. |

Contributions reflect team responsibilities rather than exclusive ownership of shared modules. See the final report and GitHub history for member-specific implementation evidence.

Additional project information:

- [Local demo runbook](docs/DEMO_RUNBOOK.md) — setup, account roles, walkthrough and recovery.
- [Spark emulator booking notes](docs/SPARK_EMULATOR_DEMO.md) — booking behavior and supported environment.
- [Cloudinary image-retention note](docs/pet-image-retention.md) — hosted-image limitation and user-facing behavior.

---

**PetCare+** — Healthier Pets. Happier Lives.
