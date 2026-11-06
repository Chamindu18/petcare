# 🐾 PetCare+

**Smart Pet Health, Veterinary Care & Pet Adoption Mobile Application**

A Flutter-based mobile application for pet records, veterinary appointment workflows, and adoption discovery. The supported academic booking demonstration uses local Firebase emulators.

---

## 📱 Overview

PetCare+ connects three user roles in one platform:

- **Pet Owners** — Manage pets, health records, appointments, and adoption requests
- **Veterinary Staff** — View assigned appointments; hospital staff manage the appointment queue
- **Adoption Providers** — Create listings, review requests, manage adoption status

**Demonstrated Journey:** Manage Pet → Monitor Health → Find Hospital → Book Appointment in local emulators → Staff confirmation and queue updates → Discover Adoption

---

## ✨ Key Features

| Feature | Description |
|---------|-------------|
| **Pet Management** | Multiple pet profiles with species, breed, age, weight, and health info |
| **Health Records** | Medical conditions, vaccinations, treatments, measurements, and trends |
| **Notifications** | In-app notification list and read state; automated reminders are incomplete |
| **Multi-Hospital Support** | Discover hospitals, view services, select vets, and book through the local emulator demo |
| **Staff Queue** | Hospital staff check-in and queue state changes; owner live queue and veterinarian queue controls are incomplete |
| **QR Health Passport** | Planned; scanning and authorized passport access are incomplete |
| **Care Guidance** | Deterministic pet-context responses and summaries; live AI integration is incomplete |
| **Adoption** | Browse listings, submit requests, and manage provider listings and requests; owner rehoming is incomplete |

---

## 🛠️ Technology Stack

| Technology | Purpose |
|------------|---------|
| Flutter & Dart | Cross-platform mobile application |
| Firebase Authentication | User registration and authentication |
| Cloud Firestore | Primary cloud database |
| Firebase Cloud Functions | Appointment callable in the local Firebase Emulator Suite |

---

## 🏗️ Architecture

PetCare+ uses **feature-first Clean Architecture**:

```
lib/
├── main.dart
├── firebase_options.dart
├── app/                    # DI, router, theme
├── core/                   # Constants, errors, services, utils
├── shared/                 # Enums and shared widgets
└── features/
    ├── adoption/
    ├── adoption_provider/
    ├── ai_assistant/
    ├── appointments/
    ├── auth/
    ├── health/
    ├── home/
    ├── hospitals/
    ├── notifications/
    ├── pets/
    ├── profile/
    ├── qr_health_passport/
    ├── queue/
    └── veterinary/
```

Each feature follows:

```
feature/
├── data/          # Datasources, models, repositories
├── domain/        # Entities, repository contracts, usecases
└── presentation/  # Pages, providers, widgets
```

**Dependency Direction:** Presentation → Domain ← Data

---

## 🚀 Getting Started

### Prerequisites

- Flutter SDK
- Firebase project access
- VS Code or Android Studio

### Firebase Configuration

```
Project ID: petcare-d4413
Android Application ID: com.example.petcare
Configuration: lib/firebase_options.dart
```

### Setup

```bash
# Clone repository
git clone <repository-url>

# Install dependencies
flutter pub get

# For the supported Spark emulator demonstration, follow docs/SPARK_EMULATOR_DEMO.md
```

### Before Committing

```bash
dart format .
flutter analyze
flutter test
```

---

## 🔐 Security

- Firebase Authentication handles user identity
- Firestore Security Rules enforce access control
- Queue state controlled by backend logic only
- Never commit secrets, passwords, or service-account credentials

---

## 🎨 Design System

**Warm Modern PetCare** visual direction with:

| Color | Hex |
|-------|-----|
| Primary / Clay Brown | #B5714A |
| Secondary / Sandy Beige | #E0B98D |
| Background / Warm Cream | #F7EEE0 |
| Deep Brown | #8C5A3C |
| Espresso | #3D2417 |
| Success | #4F9A6A |
| Warning | #D9953D |
| Error | #C85C52 |

**Typography:** Plus Jakarta Sans

---

## 🌿 Git Workflow

### Branch Naming

```
feature/<area>-<description>
fix/<area>-<description>
refactor/<area>-<description>
```

### Commit Format

```
type(scope): short description
```

Examples:

```
feat(pets): add pet profile repository
feat(queue): implement realtime queue listener
fix(auth): handle invalid login credentials
```

### Pull Request Process

1. Create feature branch
2. Implement and test locally
3. Run `dart format`, `flutter analyze`, `flutter test`
4. Open PR with clear description
5. Code review and merge

---

## 🧪 Testing

- **Unit Tests** — Business logic, validation, calculations
- **Widget Tests** — Form validation, UI states, interactions
- **Integration Tests** — Emulator-backed callable, cross-role booking, and queue workflows

---

## 📋 Definition of Done

A feature is complete when:

- [ ] Functional behavior verified
- [ ] Loading, empty, success, and error states implemented
- [ ] Business logic has tests
- [ ] Security and ownership considered
- [ ] UI follows shared design system
- [ ] Firebase access follows architecture
- [ ] `dart format` passes
- [ ] `flutter analyze` passes
- [ ] Tests pass
- [ ] No secrets or debug code present
- [ ] Meaningful commit in Git history

---

## 👥 Team Workstreams

| Member | Workstream |
|--------|------------|
| Member 1 | Foundation, authentication, navigation, Home |
| Member 2 | Pets and health records |
| Member 3 | Hospitals, appointments, live queue, QR Health Passport |
| Member 4 | Adoption, notifications, profile, settings |
| Member 5 | AI Assistant, integration, QA |

**Important:** Cross-feature contracts must be coordinated before breaking changes.

---

## 📚 Documentation

| Document | Purpose |
|----------|---------|
| Project Proposal | Scope and objectives |
| Team Work Plan | Workstreams and dependencies |
| Flutter Project Structure | Architecture guide |
| UI/UX Design System | Visual standards |
| Firestore Database Schema | Data contracts |
| Final Report | Project summary |

---

## 📌 Project Status

**Academic submission preparation.** The debug APK builds and the analyzer passes on the current feature branch. Existing automated Flutter, Firestore rules, and cross-role emulator tests are documented in `docs/SPARK_EMULATOR_DEMO.md` and `docs/PETCARE_POST_MERGE_VERIFICATION.md`. Shared Spark Firebase does not host the booking callable. QR Health Passport, owner live queue, live AI integration, automated reminders, owner rehoming, and complete veterinarian consultation/queue management remain incomplete. See `docs/SUBMISSION_CHECKLIST.md` for deliverables and remaining evidence.

---

## 🔗 Cross-Feature Integration

```
Pets
 │
 ├──────────────► Health
 │                   │
 │                   └────────► Notifications
 │
 ├──────────────► Appointments
 │                    │
 │                    ├──────► Queue
 │                    │
 │                    └──────► Notifications
 │
 └──────────────► AI Assistant
```

Before modifying shared models, enums, routes, or contracts, search for all usages and consider impact on other features.

---

## 🐾 PetCare+

**Manage Pet. Monitor Health. Explore Veterinary Care and Adoption.**
