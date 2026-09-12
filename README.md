\# 🐾 PetCare+

\## Smart Pet Health, Veterinary Care & Pet Adoption Mobile Application

PetCare+ is a Flutter-based mobile application designed to help pet owners manage the health and veterinary care of multiple pets in one place while also supporting veterinary appointment services and pet adoption/rehoming.

The application brings together digital pet profiles, health records, vaccination and treatment tracking, preventive-care reminders, multiple veterinary hospital discovery, appointment booking, live queue tracking, appointment-linked QR Health Passport sharing, AI-assisted general pet-care guidance, and adoption/rehoming discovery and requests.

\### Core Product Journey

\*\***Manage Pet → Monitor Health → Get Reminders → Find Hospital → Book Appointment → Track Queue → Share Health Securely → Get AI Guidance → Discover Adoption**\*\*

\---

\## 📌 Project Status

This project is currently under active development.

### Current foundation

- ✅ Flutter project created
- ✅ Git repository initialized
- ✅ Firebase project created
- ✅ Firebase CLI initialized
- ✅ FlutterFire configured
- ✅ Cloud Firestore database created
- ✅ `lib/firebase_options.dart` generated
- ✅ Initial feature-first project structure created
- ✅ Android build verified successfully
- ✅ Kotlin incremental-cache build issue resolved
- ✅ Static assets structure created
- ⏳ Finalize Firestore schema and contracts
- ⏳ Configure production-ready Firestore Security Rules
- ⏳ Implement authentication
- ⏳ Implement core owner features
- ⏳ Implement veterinary/staff features
- ⏳ Implement adoption/provider features
- ⏳ Implement QR Health Passport
- ⏳ Implement AI-assisted care functions
- ⏳ Integration and testing
- ⏳ Final release/demo preparation

### Current Firebase project

```text
Project Display Name: PetCare
Project ID: petcare-d4413
Android Application ID: com.example.petcare
```

Firebase Storage is intentionally **not part of the current MVP architecture**. Static and sample images are stored in the Flutter `assets/` directory.

---

\## 🎯 Project Scope

PetCare+ supports three main user roles:

1. **Pet Owner**
2. **Veterinarian / Veterinary Staff**
3. **Adoption / Rehoming Provider**

There is **no public mobile Admin role** in the current MVP.

### Pet Owner

Pet owners can:

- Manage multiple pet profiles
- Maintain digital pet health records
- Track medical conditions
- Track vaccination history
- Track treatments
- Record health measurements
- View basic health trends
- Receive preventive-care reminders
- Discover multiple veterinary hospitals
- View hospital and service information
- Book veterinary appointments
- Track appointment-related live queue information
- Generate/use an appointment-linked QR Health Passport
- Receive notifications
- Use AI-assisted general pet-care guidance
- Browse adoption and rehoming listings
- Submit and track adoption requests
- Manage personal profile and settings

### Veterinarian / Veterinary Staff

The veterinary side supports the operational functionality required by the MVP, including:

- Viewing assigned/relevant appointments
- Viewing authorized pet information for an appointment
- Scanning appointment-linked QR Health Passports
- Accessing relevant authorized health information
- Managing or updating supported appointment/queue workflow states
- Supporting consultation-related record updates where included in the agreed scope

PetCare+ is **not** intended to become a complete veterinary hospital management system.

### Adoption / Rehoming Provider

Adoption providers can:

- Create and manage adoption/rehoming listings
- Publish relevant pet information
- Review adoption requests
- Update request status
- Communicate with interested owners after acceptance

The MVP does **not** include in-app payment, delivery, transport, or legal ownership-transfer processing.

---

\## ✨ Main Features

## 🐶 Pet Management

Users can create and manage profiles for multiple pets.

Typical pet information includes:

- Name
- Species
- Breed
- Date of birth
- Gender
- Weight
- Image
- Relevant health information

Each pet is associated with its owner through an ownership relationship rather than being stored as generic shared user data.

## 🩺 Health Records

The health module provides a centralized place for:

- Medical conditions
- Vaccination history
- Treatment history
- Health measurements
- Recent health activity
- Basic health analytics

Owner-reported information should remain distinguishable from veterinarian-confirmed information.

## 🔔 Preventive Care & Notifications

PetCare+ supports reminders and notifications for:

- Vaccinations
- Preventive-care events
- Appointments
- Queue updates
- Other relevant application events

Notifications should link users to the relevant feature where practical.

## 🏥 Multi-Hospital Veterinary Services

PetCare+ is designed to support **multiple veterinary hospitals**, not a single-hospital model.

Users can:

- Discover nearby/available veterinary hospitals
- View hospital information
- View supported services
- Select a hospital for an appointment
- Select a pet
- Select an available service/veterinarian where applicable
- Choose an available date and time
- Provide an appointment reason

Hospital functionality remains focused on the appointment, queue, authorized health-sharing, and supported operational requirements of the MVP.

## 🕐 Live Queue

The queue feature provides information such as:

- Current serving number
- User's queue number
- Current position
- Patients ahead
- Estimated waiting time
- Queue status
- Real-time updates

Queue state should be controlled by appropriate backend/database logic rather than being freely editable from the mobile client.

## 🔐 QR Health Passport

PetCare+ uses an appointment-linked QR Health Passport for controlled health-information sharing.

The QR should contain a secure reference/token rather than embedding medical data directly.

Typical flow:

```text
Owner
  ↓
Select Appointment / Pet
  ↓
Generate Secure QR
  ↓
Veterinarian / Staff Scans QR
  ↓
Authorize Request
  ↓
Relevant Pet Health Information
```

Access must be limited to the appropriate appointment and authorization context.

## 🤖 AI Pet-Care Assistant

The AI feature provides **general, context-aware pet-care guidance**.

Relevant pet context may include:

- Species
- Breed
- Age
- Recorded medical conditions
- Vaccination status
- Treatments
- Recent health measurements
- Other minimal context required for the requested assistance

Supported AI functions include:

- General pet-care guidance
- Contextual care questions
- Health-summary generation
- Preventive-care insights
- Explanation of existing health records
- Preparation for veterinary visits

The AI must **not**:

- Diagnose diseases
- Prescribe medication
- Recommend medication dosage changes
- Replace professional veterinary advice

AI API credentials must never be stored in the Flutter client.

## 🐾 Adoption & Rehoming

PetCare+ includes an adoption/rehoming flow.

Owners can:

- Browse listings
- View pet details
- Submit adoption requests
- Track request status
- Communicate after acceptance

Providers can:

- Create/manage listings
- Review requests
- Update request status

The MVP intentionally excludes:

- In-app payments
- Delivery
- Transport booking
- Legal ownership-transfer processing

These arrangements are handled externally between the relevant parties.

## 👤 Profile & Settings

Users can manage:

- Personal profile information
- Notification preferences
- Privacy/security settings
- Support information
- Account actions

---

\# 🛠️ Technology Stack

\| Technology | Purpose |

\|---|---|

\| \*\***Flutter**\*\* | Cross-platform mobile application |

\| \*\***Dart**\*\* | Application programming language |

\| \*\***Firebase Authentication**\*\* | User registration and authentication |

\| \*\***Cloud Firestore**\*\* | Main cloud database |

\| \*\***Firebase Storage**\*\* | Pet images and required documents |

\| \*\***Firebase Cloud Messaging**\*\* | Push notifications and reminders |

\| \*\***Firebase Cloud Functions**\*\* | Protected backend operations where required |

\| \*\***External AI / LLM API**\*\* | AI-assisted general pet-care guidance |

\| \*\***Git**\*\* | Version control |

\| \*\***GitHub**\*\* | Collaboration and contribution tracking |

\| \*\***VS Code / Android Studio**\*\* | Development, debugging and testing |

\---

\# 🏗️ Architecture

PetCare+ uses a **feature-first Clean Architecture approach**.

```text
lib/
├── main.dart
├── firebase_options.dart
│
├── app/
│   ├── di/
│   ├── router/
│   └── theme/
│
├── core/
│   ├── constants/
│   ├── errors/
│   ├── firebase/
│   ├── services/
│   ├── utils/
│   └── widgets/
│
├── shared/
│   ├── enums/
│   └── widgets/
│
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

Feature-owned models belong to their feature. Do **not** use `lib/shared/models/` as a generic dumping ground.

Each major feature should normally follow:

```text
feature/
├── data/
│   ├── datasources/
│   ├── models/
│   └── repositories/
│
├── domain/
│   ├── entities/
│   ├── repositories/
│   └── usecases/
│
└── presentation/
    ├── pages/
    ├── providers/
    └── widgets/
```

## Architecture Responsibilities

**Presentation**

Contains pages, widgets, UI state and user interaction.

**Domain**

Contains entities, repository contracts, use cases and business rules.

**Data**

Contains Firebase/API data sources, models, repository implementations and data mapping.

**Core**

Contains genuinely global infrastructure and utilities.

**Shared**

Contains only components and enums that are genuinely reused across multiple features.

## Dependency Direction

```text
Presentation
      ↓
   Domain
      ↑
    Data
```

Presentation should not contain direct Firestore/API implementation code, and the domain layer should not depend on Firebase or UI code.

---

\# 🗂️ Team Workstreams

The application remains **one shared codebase**.

| Member | Main workstream |
|---|---|
| **Member 1** | Application foundation, authentication, navigation and Home |
| **Member 2** | Pets and health records |
| **Member 3** | Hospitals, appointments, live queue and QR Health Passport |
| **Member 4** | Adoption, adoption provider, notifications, reminders, profile and settings |
| **Member 5** | AI Pet-Care Assistant, cross-feature integration and QA |

### Important dependencies

```text
Member 1 — Foundation
        ↓
All members

Member 2 — Pet model/health context
        ↓
Appointments / QR / AI

Member 3 — Hospital / appointment / queue / QR
        ↓
Integration

Member 4 — Adoption / notifications / profile
        ↓
Integration

Member 5 — AI / integration / QA
        ↓
Whole system
```

Cross-feature contracts must be coordinated before breaking changes are introduced.

---|---|

\| \*\***Member 1**\*\* | Application foundation, authentication, navigation and Home |

\| \*\***Member 2**\*\* | Pets, health records and health analytics |

\| \*\***Member 3**\*\* | Veterinary services, appointments and live queue |

\| \*\***Member 4**\*\* | Notifications, reminders, profile and settings |

\| \*\***Member 5**\*\* | AI Pet-Care Assistant, integration and quality |

This is a feature-based organization strategy. The application remains one shared codebase.

\---

\# 🖥️ Visual Screen Baseline

The project uses **20 visual reference screens** as design anchors.

```text
01  Splash
02  Onboarding
03  Login
04  Register
05  Forgot Password
06  Reset Password
07  First Pet Setup
08  Home Dashboard
09  My Pets
10  Health Records
11  Hospital Discovery
12  Hospital Details
13  Book Appointment
14  Live Queue
15  QR Health Passport
16  AI PetCare Hub
17  Adoption Listings
18  Veterinary Dashboard
19  Adoption Provider Dashboard
20  Profile & Settings
```

These are **visual anchor screens**, not a restriction on the final number of application routes.

Dialogs, bottom sheets, forms, confirmation states, loading states, empty states and error states do not need to become separate full visual screens unless the user journey genuinely requires them.

Do not add screens merely to increase the page count.

---

\# 🔥 Firebase

PetCare+ uses one shared Firebase project:

```text
Firebase Project
│
├── Authentication
├── Cloud Firestore
├── Cloud Messaging
└── Cloud Functions
    (only when actually required)
```

## Firebase Configuration

Current Android application:

```text
Application ID: com.example.petcare
Firebase Project ID: petcare-d4413
Flutter configuration: lib/firebase_options.dart
```

The Flutter application initializes Firebase using the generated FlutterFire configuration.

## Firestore

The planned data areas include:

```text
users
pets
medical_conditions
vaccinations
treatments
health_measurements
hospitals
services
veterinarians
appointments
queue_records
notifications
adoption_listings
adoption_requests
```

The exact schema may evolve during implementation. Collection names, field names, identifiers and contracts must be agreed before changes that affect other features are introduced.

## Firebase Storage

**Not used in the current MVP.**

Static and sample images belong in:

```text
assets/
```

The team should only introduce a remote file-storage service if the agreed scope later requires persistent user-generated uploads.

---

\# 🔐 Security

Security is a shared responsibility.

## Authentication

Firebase Authentication is the source of user identity.

Public registration is for **Pet Owners**.

Veterinarian/staff and adoption-provider access should be provisioned through the approved process rather than allowing unrestricted public role selection during registration.

Passwords must never be stored in Firestore.

## Authorization

Firestore Security Rules and backend logic must enforce access control.

The application must not rely only on UI restrictions for security.

Access decisions should consider:

- Authenticated user identity
- Pet ownership
- Appointment relationship
- Veterinary/staff authorization
- Hospital affiliation where applicable
- Adoption-provider ownership of listings/requests
- Appropriate request/status permissions

## QR Security

QR codes must not embed sensitive medical records directly.

Use a secure reference/token and enforce authorization on the server/database side.

## Queue Security

Queue state must not be freely editable by clients.

Use controlled backend/database operations and appropriate rules.

## Secrets

Never commit:

```text
API keys intended to remain secret
Passwords
Service-account credentials
Private keys
Access tokens
.env secrets
```

AI API credentials must never be stored in the Flutter client.

## AI Privacy

Send only the minimum relevant pet context required for an AI operation. Avoid unnecessary personal information.

---

\# 🎨 UI / UX

PetCare+ follows the approved **Warm Modern PetCare** visual direction.

### Visual characteristics

- Warm cream/off-white backgrounds
- Realistic pet photography where appropriate
- Rounded cards
- Earth-tone accents
- Compact information hierarchy
- Simple modern icons
- Professional but warm presentation
- Minimal decoration
- Clear, practical layouts

Avoid:

- Huge gradients or decorative blobs
- Excessive paw/heart decoration
- Childish cartoon styling
- Glassmorphism/neon-heavy interfaces
- Heavy shadows
- Random icon families
- Oversized headings
- Overloaded dashboards

### Color system

```text
Primary / Clay Brown     #B5714A
Secondary / Sandy Beige  #E0B98D
Background / Warm Cream  #F7EEE0
Deep Brown               #8C5A3C
Espresso                 #3D2417
White                    #FFFFFF
Success / Healthy        #4F9A6A
Warning / Due Soon       #D9953D
Error / Critical        #C85C52
Information              #5C84A6
```

**Typography:** Plus Jakarta Sans

Use the shared design tokens rather than scattering raw values throughout widgets.

The approved logo is maintained as a branding asset and does not need to match the UI color palette exactly.

---

\# 🌿 Git & GitHub Workflow

The repository is shared by the entire team.

Members should normally work on feature branches rather than directly on the main branch.

\### Branch naming

\`\`\`text

feature/\<area>-\<description>

fix/\<area>-\<description>

refactor/\<area>-\<description>

\`\`\`

Examples:

\`\`\`text

feature/pets-profile

feature/health-records

feature/appointment-booking

feature/live-queue

feature/ai-assistant

fix/queue-listener

refactor/theme

\`\`\`

\### Commit format

\`\`\`text

type(scope): short description

\`\`\`

Examples:

\`\`\`text

feat(pets): add pet profile repository

feat(health): implement vaccination history

feat(appointments): add booking flow

feat(queue): implement realtime queue listener

feat(ai): add pet context builder

fix(auth): handle invalid login credentials

test(queue): add queue state tests

refactor(theme): centralize spacing tokens

\`\`\`

Avoid meaningless messages such as:

\`\`\`text

update

changes

done

final

test

\`\`\`

Every member must make identifiable individual commits.

\---

\# 🔄 Pull Request Workflow

\`\`\`text

main

  │

  ├── feature branch

  │

  ▼

Development

  │

  ▼

Testing

  │

  ▼

Pull Request

  │

  ▼

Code Review

  │

  ▼

Merge

  │

  ▼

main

\`\`\`

Before opening a Pull Request:

\`\`\`bash

*dart* format .

*flutter* analyze

*flutter* test

\`\`\`

Also test the affected feature on an emulator or physical device where appropriate.

\---

\# 🧪 Testing

PetCare+ should use multiple levels of testing.

\### Unit Tests

Use for business logic such as:

\- Validation

\- Pet age calculation

\- Queue calculations

\- Health analytics

\- AI response parsing

\### Widget Tests

Use for important UI behaviour such as:

\- Form validation

\- Buttons

\- Loading states

\- Error states

\- Important user interactions

\### Integration Tests

Use for critical end-to-end flows such as:

\`\`\`text

Register

   ↓

Add Pet

   ↓

Book Appointment

   ↓

Appointment Confirmation

   ↓

Live Queue

\`\`\`

and:

\`\`\`text

Select Pet

   ↓

AI Assistant

   ↓

Pet Context

   ↓

AI Response

\`\`\`

\---

\# 🤖 AI Coding Agent Guidelines

AI coding agents may be used to accelerate implementation, but \*\***the developer who requested the code remains responsible for reviewing and testing it**\*\*.

Every AI agent should:

1\. Read the relevant project documentation before making changes.

2\. Inspect the existing repository before creating new files.

3\. Follow the current folder structure and architecture.

4\. Search for existing models, routes, repositories, widgets and services before duplicating them.

5\. Identify dependencies on other members' code before modifying shared files.

6\. Keep Firebase/API access inside the appropriate data layer.

7\. Reuse existing design tokens and shared components.

8\. Implement appropriate loading, empty, success and error states.

9\. Add tests for important business logic.

10\. Run formatting, static analysis and relevant tests.

11\. Review the final diff for secrets, debug code and unrelated modifications.

12\. Explain any change that affects another feature or shared contract.

\### AI agents must not

\- Rewrite the entire project architecture.

\- Create duplicate models for the same entity.

\- Put direct Firestore queries inside UI widgets.

\- Introduce a separate navigation system.

\- Create a separate visual identity for one feature.

\- Add unnecessary packages without technical justification.

\- Add features only to increase screen count.

\- Put API keys or secrets into client code.

\- Create fake real-time queue behaviour.

\- Diagnose diseases or prescribe medication through the AI assistant.

\---

\# 🔗 Cross-Feature Integration

PetCare+ contains many connected features.

\`\`\`text

Pets

 │

 ├──────────────► Health

 │                   │

 │                   └────────► Notifications

 │

 ├──────────────► Appointments

 │                    │

 │                    ├──────► Queue

 │                    │

 │                    └──────► Notifications

 │

 └──────────────► AI Assistant

\`\`\`

Before modifying any shared:

\- Model

\- Enum

\- Route

\- Firestore field

\- Collection name

\- Repository contract

\- Theme token

\- Shared widget

search the repository for all usages and consider the impact on other features.

Do not silently rename shared fields or contracts.

\---

\# 📐 Development Rules

The team should maintain one consistent implementation style.

\### Always

\- Use clear naming.

\- Keep classes and methods focused.

\- Prefer reusable widgets.

\- Use null safety correctly.

\- Use const where appropriate.

\- Handle asynchronous states explicitly.

\- Dispose controllers/listeners correctly.

\- Keep Firestore access out of UI widgets.

\- Test after integration with the shared codebase.

\- Keep Git commits small and meaningful.

\- Use engineering judgement for unspecified details.

\### Avoid

\- Unnecessary abstraction.

\- Duplicate code.

\- Magic strings.

\- Direct database calls from multiple screens.

\- Large widgets containing business logic.

\- Silent exception handling.

\- Unnecessary dependencies.

\- Unrelated refactoring inside feature commits.

\---

\# 🧠 Technical Decision Rule

This project cannot document every implementation detail.

When something is not explicitly specified, developers should use their own engineering judgement.

Choose the solution that is:

\*\***Secure + Maintainable + Testable + Consistent with the existing architecture**\*\*

Team discussion is required when a decision:

\- Changes project scope

\- Changes the architecture

\- Changes shared Firestore contracts

\- Changes navigation

\- Changes the design system

\- Changes state-management strategy

\- Changes security boundaries

\- Changes the external AI integration strategy

Small implementation decisions inside one feature can normally be made by the responsible developer.

\---

\# 📋 Definition of Done

A feature should not be considered complete merely because the screen renders.

Before declaring a feature complete:

\- Functional behaviour has been verified.

\- Relevant states are implemented.

\- Important business logic has tests.

\- Security and ownership have been considered.

\- UI follows the shared design system.

\- Firebase access follows the agreed architecture.

\- \`dart format\` passes.

\- \`flutter analyze\` passes.

\- Relevant tests pass.

\- The feature works with the current integrated codebase.

\- No secrets or unnecessary debug code are present.

\- The Git history contains a meaningful individual commit.

\- The Pull Request accurately describes the change.

\---

\# 📚 Project Documentation

The following documents should be kept consistent with the implementation:

\`\`\`text

PetCare+

│

├── Project Proposal

├── Team Work Plan & AI Agent Guide

├── Flutter Project Structure & AI Agent Guide

├── UI/UX Design System

├── Firestore Database Schema

└── Final Report

\`\`\`

When the implementation changes an important project decision, the relevant documentation should be updated.

\---

\# 👥 Team Responsibility

The five workstreams are an organizational split, not five separate applications.

Every team member should understand:

\- The overall PetCare+ user journey

\- The application architecture

\- Firebase basics

\- Their own feature

\- How their feature connects to the other features

\- The project's security requirements

\- The project's Git workflow

\- The major AI limitations

The final system should behave as \*\***one connected application**\*\*.

\---

\## 🐾 PetCare+

\*\***Manage Pet. Monitor Health. Get Reminders. Book Vet. Track Queue. Get AI Guidance.**\*\*