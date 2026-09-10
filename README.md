# 🐾 PetCare+

## Smart Pet Health & Veterinary Management Mobile Application

PetCare+ is a Flutter-based mobile application designed primarily for pet owners to manage the health and veterinary care of multiple pets in one place.

The application brings together digital pet profiles, health records, vaccination and treatment tracking, preventive-care reminders, health analytics, veterinary appointment booking, real-time queue tracking, notifications, and an AI-assisted general pet-care guidance feature.

### Core Product Journey

**Manage Pet → Monitor Health → Get Reminders → Book Vet → Track Queue → Get AI Guidance**

---

## 📌 Project Status

This project is currently under active development.

### Current foundation

- ✅ Flutter project created
- ✅ Firebase project created
- ✅ Cloud Firestore database created
- ✅ Initial project folder structure created
- ⏳ Connect Flutter application to Firebase
- ⏳ Finalize Firestore schema
- ⏳ Configure Firebase Security Rules
- ⏳ Implement authentication
- ⏳ Implement feature modules
- ⏳ Integration and testing
- ⏳ Final release/demo preparation

---

## 🎯 Project Scope

PetCare+ is mainly an **owner-facing application**.

The system allows pet owners to:

- Manage multiple pet profiles
- Maintain digital pet health records
- Track medical conditions
- Track vaccination history
- Track treatments
- Record health measurements
- View basic health trends
- Receive preventive-care reminders
- Manage veterinary appointments
- Track their veterinary queue position in real time
- Receive relevant notifications
- Use an AI-assisted Pet-Care Assistant for general guidance
- Manage their profile, notification preferences, privacy and settings

The application is **not** intended to become a complete veterinary hospital management system or a multi-hospital marketplace. Only supporting hospital functionality required for appointments and real-time queue operation should be introduced.

---

## ✨ Main Features

### 🐶 Pet Management

Users can create and manage profiles for multiple pets. Pet information includes details such as name, species, breed, date of birth, gender, weight, image and relevant health information.

### 🩺 Health Records

The health module provides a centralized place for:

- Medical conditions
- Vaccination history
- Treatment history
- Health measurements
- Recent health activity
- Basic health analytics

Owner-reported information should remain distinguishable from veterinarian-confirmed information.

### 🔔 Preventive Care & Notifications

PetCare+ supports reminders and notifications for important events, including vaccinations, health reminders, appointments and queue updates.

Notifications should link users to the relevant feature where practical.

### 🏥 Veterinary Services

Users can view the available veterinary hospital/service information and book appointments by selecting a pet, service, veterinarian where applicable, date, time and reason.

Appointments can then be viewed and managed through the application.

### 🕐 Real-Time Queue

The queue feature provides:

- Current serving number
- User's queue number
- Current position
- Patients ahead
- Estimated waiting time
- Queue status
- Real-time updates

Queue state should be controlled by appropriate backend/database logic rather than being freely editable from the mobile client.

### 🤖 AI Pet-Care Assistant

The AI assistant provides **general, context-aware pet-care guidance**.

Relevant pet context may include:

- Species
- Breed
- Age
- Recorded medical conditions
- Vaccination status
- Treatments
- Recent health measurements

Suitable topics include nutrition, exercise, grooming, preventive care, vaccination explanations and explanations of existing health records.

The AI must not diagnose diseases, prescribe medication, or independently change treatment doses. A clear message should state that AI guidance does not replace professional veterinary advice.

### 👤 Profile & Settings

Users can manage their personal profile, notification preferences, privacy/security settings, support information and account actions.

---

# 🛠️ Technology Stack

| Technology | Purpose |
|---|---|
| **Flutter** | Cross-platform mobile application |
| **Dart** | Application programming language |
| **Firebase Authentication** | User registration and authentication |
| **Cloud Firestore** | Main cloud database |
| **Firebase Storage** | Pet images and required documents |
| **Firebase Cloud Messaging** | Push notifications and reminders |
| **Firebase Cloud Functions** | Protected backend operations where required |
| **External AI / LLM API** | AI-assisted general pet-care guidance |
| **Git** | Version control |
| **GitHub** | Collaboration and contribution tracking |
| **VS Code / Android Studio** | Development, debugging and testing |

---

# 🏗️ Architecture

PetCare+ uses a **feature-first Clean Architecture approach**.

```text
lib/
├── app/
│   ├── router/
│   ├── theme/
│   └── di/
│
├── core/
│   ├── constants/
│   ├── errors/
│   ├── utils/
│   ├── services/
│   ├── firebase/
│   └── widgets/
│
├── shared/
│   ├── models/
│   ├── enums/
│   └── widgets/
│
└── features/
    ├── auth/
    ├── home/
    ├── pets/
    ├── health/
    ├── appointments/
    ├── queue/
    ├── notifications/
    ├── ai_assistant/
    └── profile/
```

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
    ├── widgets/
    └── providers/
```

### Architecture Responsibilities

**Presentation**

Contains pages, widgets, UI state and user interaction.

**Domain**

Contains entities, repository contracts, use cases and business rules.

**Data**

Contains Firebase/API data sources, models, repository implementations and data mapping.

**Core**

Contains genuinely global infrastructure and utilities.

**Shared**

Contains components, models or enums that are genuinely reused across multiple features.

### Dependency Direction

```text
Presentation
      ↓
   Domain
      ↑
    Data
```

Presentation should not contain direct Firestore/API implementation code, and the domain layer should not depend on Firebase or UI code.

---

# 🗂️ Main Feature Areas

The current five-member workstreams are organized as follows:

| Member | Main workstream |
|---|---|
| **Member 1** | Application foundation, authentication, navigation and Home |
| **Member 2** | Pets, health records and health analytics |
| **Member 3** | Veterinary services, appointments and live queue |
| **Member 4** | Notifications, reminders, profile and settings |
| **Member 5** | AI Pet-Care Assistant, integration and quality |

This is a feature-based organization strategy. The application remains one shared codebase.

---

# 🖥️ Current Screen Baseline

The current planned baseline contains 21 main screens:

```text
01  Welcome
02  Onboarding
03  Login
04  Register
05  Home Dashboard
06  Notifications
07  My Pets
08  Add / Edit Pet
09  Pet Profile
10  Health Records
11  Medical Conditions
12  Vaccination History
13  Treatment History
14  Health Analytics
15  Veterinary Hospital & Services
16  Book Appointment
17  Appointment Confirmation
18  Appointment Details
19  Live Queue
20  AI Pet-Care Assistant
21  Profile & Settings
```

The 21-screen set is a baseline rather than a hard restriction. Supporting pages, forms, bottom sheets, dialogs, detail views and states may be added when they are genuinely required for completeness, usability, security or technical correctness.

Do not add screens simply to increase the screen count.

---

# 🔥 Firebase

PetCare+ uses one shared Firebase project for the application.

```text
Firebase Project
│
├── Authentication
├── Cloud Firestore
├── Storage
├── Cloud Messaging
└── Cloud Functions
```

## Firestore

The planned data areas are:

```text
users / profiles
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
```

The exact Firestore schema may evolve as implementation requirements become clearer. Shared collection names, field names, identifiers and contracts must be coordinated before breaking changes are introduced.

## Firebase Storage

Use Firebase Storage for:

- Pet profile images
- Required medical documents
- Other approved file attachments

Structured application data should remain in Firestore.

---

# 🔐 Security

Security is a shared responsibility.

### Authentication

Firebase Authentication is the source of user identity.

### Authorization

Firestore and Storage Security Rules must enforce authenticated access and ownership.

The application must not rely only on UI restrictions for security.

### Ownership

A user must only be able to access data they are authorized to access.

Pet, health and appointment operations must validate ownership and/or permissions as appropriate.

### Secrets

Never commit:

```text
API keys
Passwords
Service-account credentials
Private keys
Access tokens
.env secrets
```

AI API credentials must never be stored in the Flutter client.

### AI Privacy

Only relevant pet information should be sent to an external AI service. Avoid sending unnecessary personal information.

---

# 🎨 UI / UX

PetCare+ follows a shared design system.

### Visual direction

- Caring
- Trustworthy
- Smart
- Modern
- Calm

### Current design tokens

```text
Primary Teal       #168A83
Dark Teal          #126B67
Warm Ivory         #F7FAF8
White              #FFFFFF
Deep Navy          #18323A
Slate              #63757B
Soft Teal          #DDF3F0
Warm Coral         #F28C72
Health Green       #35A77A
Warning Amber      #E9A83B
Muted Red          #D95C5C
```

**Typography:** Plus Jakarta Sans

Use the shared design tokens rather than scattering raw values throughout widgets.

The finalized screen designs will be shared with the team separately. Once a design is approved, implementation should follow the shared visual language rather than introducing feature-specific styling.

---

# 🌿 Git & GitHub Workflow

The repository is shared by the entire team.

Members should normally work on feature branches rather than directly on the main branch.

### Branch naming

```text
feature/<area>-<description>
fix/<area>-<description>
refactor/<area>-<description>
```

Examples:

```text
feature/pets-profile
feature/health-records
feature/appointment-booking
feature/live-queue
feature/ai-assistant
fix/queue-listener
refactor/theme
```

### Commit format

```text
type(scope): short description
```

Examples:

```text
feat(pets): add pet profile repository
feat(health): implement vaccination history
feat(appointments): add booking flow
feat(queue): implement realtime queue listener
feat(ai): add pet context builder
fix(auth): handle invalid login credentials
test(queue): add queue state tests
refactor(theme): centralize spacing tokens
```

Avoid meaningless messages such as:

```text
update
changes
done
final
test
```

Every member must make identifiable individual commits.

---

# 🔄 Pull Request Workflow

```text
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
```

Before opening a Pull Request:

```bash
dart format .
flutter analyze
flutter test
```

Also test the affected feature on an emulator or physical device where appropriate.

---

# 🧪 Testing

PetCare+ should use multiple levels of testing.

### Unit Tests

Use for business logic such as:

- Validation
- Pet age calculation
- Queue calculations
- Health analytics
- AI response parsing

### Widget Tests

Use for important UI behaviour such as:

- Form validation
- Buttons
- Loading states
- Error states
- Important user interactions

### Integration Tests

Use for critical end-to-end flows such as:

```text
Register
   ↓
Add Pet
   ↓
Book Appointment
   ↓
Appointment Confirmation
   ↓
Live Queue
```

and:

```text
Select Pet
   ↓
AI Assistant
   ↓
Pet Context
   ↓
AI Response
```

---

# 🤖 AI Coding Agent Guidelines

AI coding agents may be used to accelerate implementation, but **the developer who requested the code remains responsible for reviewing and testing it**.

Every AI agent should:

1. Read the relevant project documentation before making changes.
2. Inspect the existing repository before creating new files.
3. Follow the current folder structure and architecture.
4. Search for existing models, routes, repositories, widgets and services before duplicating them.
5. Identify dependencies on other members' code before modifying shared files.
6. Keep Firebase/API access inside the appropriate data layer.
7. Reuse existing design tokens and shared components.
8. Implement appropriate loading, empty, success and error states.
9. Add tests for important business logic.
10. Run formatting, static analysis and relevant tests.
11. Review the final diff for secrets, debug code and unrelated modifications.
12. Explain any change that affects another feature or shared contract.

### AI agents must not

- Rewrite the entire project architecture.
- Create duplicate models for the same entity.
- Put direct Firestore queries inside UI widgets.
- Introduce a separate navigation system.
- Create a separate visual identity for one feature.
- Add unnecessary packages without technical justification.
- Add features only to increase screen count.
- Put API keys or secrets into client code.
- Create fake real-time queue behaviour.
- Diagnose diseases or prescribe medication through the AI assistant.

---

# 🔗 Cross-Feature Integration

PetCare+ contains many connected features.

```text
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

Before modifying any shared:

- Model
- Enum
- Route
- Firestore field
- Collection name
- Repository contract
- Theme token
- Shared widget

search the repository for all usages and consider the impact on other features.

Do not silently rename shared fields or contracts.

---

# 📐 Development Rules

The team should maintain one consistent implementation style.

### Always

- Use clear naming.
- Keep classes and methods focused.
- Prefer reusable widgets.
- Use null safety correctly.
- Use const where appropriate.
- Handle asynchronous states explicitly.
- Dispose controllers/listeners correctly.
- Keep Firestore access out of UI widgets.
- Test after integration with the shared codebase.
- Keep Git commits small and meaningful.
- Use engineering judgement for unspecified details.

### Avoid

- Unnecessary abstraction.
- Duplicate code.
- Magic strings.
- Direct database calls from multiple screens.
- Large widgets containing business logic.
- Silent exception handling.
- Unnecessary dependencies.
- Unrelated refactoring inside feature commits.

---

# 🧠 Technical Decision Rule

This project cannot document every implementation detail.

When something is not explicitly specified, developers should use their own engineering judgement.

Choose the solution that is:

**Secure + Maintainable + Testable + Consistent with the existing architecture**

Team discussion is required when a decision:

- Changes project scope
- Changes the architecture
- Changes shared Firestore contracts
- Changes navigation
- Changes the design system
- Changes state-management strategy
- Changes security boundaries
- Changes the external AI integration strategy

Small implementation decisions inside one feature can normally be made by the responsible developer.

---

# 📋 Definition of Done

A feature should not be considered complete merely because the screen renders.

Before declaring a feature complete:

- Functional behaviour has been verified.
- Relevant states are implemented.
- Important business logic has tests.
- Security and ownership have been considered.
- UI follows the shared design system.
- Firebase access follows the agreed architecture.
- `dart format` passes.
- `flutter analyze` passes.
- Relevant tests pass.
- The feature works with the current integrated codebase.
- No secrets or unnecessary debug code are present.
- The Git history contains a meaningful individual commit.
- The Pull Request accurately describes the change.

---

# 📚 Project Documentation

The following documents should be kept consistent with the implementation:

```text
PetCare+
│
├── Project Proposal
├── Team Work Plan & AI Agent Guide
├── Flutter Project Structure & AI Agent Guide
├── UI/UX Design System
├── Firestore Database Schema
└── Final Report
```

When the implementation changes an important project decision, the relevant documentation should be updated.

---

# 👥 Team Responsibility

The five workstreams are an organizational split, not five separate applications.

Every team member should understand:

- The overall PetCare+ user journey
- The application architecture
- Firebase basics
- Their own feature
- How their feature connects to the other features
- The project's security requirements
- The project's Git workflow
- The major AI limitations

The final system should behave as **one connected application**.

---

## 🐾 PetCare+

**Manage Pet. Monitor Health. Get Reminders. Book Vet. Track Queue. Get AI Guidance.**
