# 🐾 PetCare+

**Smart Pet Health, Veterinary Care & Pet Adoption Mobile Application**

A Flutter-based mobile application that helps pet owners manage health records, book veterinary appointments, track live queues, share health data securely via QR, and discover pet adoption options.

---

## 📱 Overview

PetCare+ connects three user roles in one platform:

- **Pet Owners** — Manage pets, health records, appointments, and adoption requests
- **Veterinary Staff** — View appointments, scan QR health passports, manage queue workflow
- **Adoption Providers** — Create listings, review requests, manage adoption status

**Core Journey:** Manage Pet → Monitor Health → Get Reminders → Find Hospital → Book Appointment → Track Queue → Share Health Securely → Get AI Guidance → Discover Adoption

---

## ✨ Key Features

| Feature | Description |
|---------|-------------|
| **Pet Management** | Multiple pet profiles with species, breed, age, weight, and health info |
| **Health Records** | Medical conditions, vaccinations, treatments, measurements, and trends |
| **Preventive Care** | Automated reminders and notifications for vaccinations and appointments |
| **Multi-Hospital Support** | Discover hospitals, view services, select vets, and book appointments |
| **Live Queue** | Real-time queue position, estimated wait time, and status updates |
| **QR Health Passport** | Secure appointment-linked QR for authorized health data sharing |
| **AI Pet-Care Assistant** | General guidance, health summaries, and vet visit preparation |
| **Adoption & Rehoming** | Browse listings, submit requests, and communicate after acceptance |

---

## 🛠️ Technology Stack

| Technology | Purpose |
|------------|---------|
| Flutter & Dart | Cross-platform mobile application |
| Firebase Authentication | User registration and authentication |
| Cloud Firestore | Primary cloud database |
| Firebase Cloud Messaging | Push notifications and reminders |
| Firebase Cloud Functions | Protected backend operations |
| External AI/LLM API | AI-assisted pet-care guidance |

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

# Run the app
flutter run
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
- QR codes contain secure tokens, not embedded medical data
- Queue state controlled by backend logic only
- AI API credentials never stored in client
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
- **Integration Tests** — End-to-end flows (registration → booking → queue)

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

**Under Active Development**

- ✅ Flutter project created
- ✅ Firebase configured
- ✅ Firestore database created
- ✅ Feature-first structure established
- ✅ Android build verified
- ⏳ Authentication implementation
- ⏳ Core features implementation
- ⏳ Integration and testing

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

**Manage Pet. Monitor Health. Get Reminders. Book Vet. Track Queue. Get AI Guidance.**