# PetCare+ — OpenCode Project Context

## 1. Project Identity

- Project: PetCare+
- Full name: PetCare+ — Smart Multi-Hospital Pet-Care Mobile Application
- Course: SE303.3 Mobile Application Development
- Platform: Flutter / Dart mobile application
- Backend: Firebase
- Primary development target: Android
- Team size: 5
- Supervisor: Mr. Diluka Wijesinghe
- MVP constraint: Approximately one month of implementation remaining
- Repository: https://github.com/Chamindu18/petcare
- Default branch: main
- Development model: Feature branches + Pull Requests
- Main branch: Protected

---

# 2. Product Positioning

PetCare+ is a smart multi-hospital pet-care platform.

Pet owners can:

- Manage multiple pets
- Manage pet health information
- Maintain medical conditions, vaccinations, treatments and measurements
- View health trends and analytics
- Discover multiple veterinary hospitals
- View hospital services and veterinarians
- Book and manage veterinary appointments
- Track live appointment queues
- Generate an appointment-linked QR Health Passport
- Securely share authorized pet health information with veterinary professionals
- Use AI-assisted pet-care functions
- Receive notifications and reminders
- Discover pets available for adoption
- Submit adoption requests
- Create owner rehoming listings

Veterinary users can:

- Access assigned/authorized appointments
- Scan appointment-linked QR codes
- View only authorized pet health information
- Support consultations
- Manage queue state

Adoption providers can:

- Create/manage adoption listings
- Review adoption requests
- Accept/reject/contact applicants

PetCare+ is intentionally NOT:

- A full hospital information system
- A hospital enterprise administration platform
- An e-commerce marketplace
- A payment platform
- A delivery/logistics platform
- A pet transportation service
- A legal ownership-transfer system
- A mobile Admin application
- An AI diagnosis or prescribing application

---

# 3. User Roles

## 3.1 Pet Owner

- Primary application user
- Public mobile registration is allowed
- Can manage multiple pets
- Can access owner workflows
- Can create rehoming listings

## 3.2 Veterinarian / Veterinary Staff

- Secondary user
- Account is provisioned/approved through an authorized process
- No public self-registration
- Veterinary access is role- and context-controlled

## 3.3 Adoption Provider / Rehoming Provider

- Supporting user
- Account is provisioned/approved through an authorized process
- No public self-registration
- Can manage only authorized adoption listings and requests

## 3.4 Admin

- No Admin role in the PetCare+ mobile application
- Do not introduce an Admin mobile workflow unless the project scope is formally changed

---

# 4. MVP Scope

## Included

- Multiple pet profiles
- Pet health records
- Medical conditions
- Vaccinations
- Treatments
- Health measurements
- Health analytics
- Multi-hospital discovery
- Hospital details
- Veterinary services
- Veterinarian selection where applicable
- Appointment booking
- Appointment management
- Live queue tracking
- Veterinary queue management
- Appointment-linked QR Health Passport
- Authorized veterinary health-data access
- Veterinary consultation support
- Notifications and reminders
- Adoption discovery
- Adoption requests
- Owner rehoming listings
- Adoption-provider listing management
- Adoption-provider request management
- AI general care assistant
- AI health summaries
- AI preventive insights
- AI veterinary-visit preparation
- Profile and settings

## Explicitly excluded

- Pet-product marketplace
- E-commerce
- Online payments
- Delivery
- Transport/logistics
- Pet transportation service
- Legal ownership transfer
- Full hospital administration
- Mobile Admin
- AI diagnosis
- AI prescribing
- AI dosage changes
- AI replacement of veterinary judgment
- Advanced AI image diagnosis

Do not expand MVP scope merely because a feature sounds useful.

Scope changes require team review and, where appropriate, supervisor review.

---

# 5. Owner Navigation

The primary owner navigation is:

Home | Pets | Appointments | AI | Profile

Do not introduce a second competing owner navigation structure without team agreement.

---

# 6. Primary Screen IDs

## Shared / Authentication

- A01 Splash
- A02 Onboarding
- A03 Login
- A04 Pet Owner Registration
- A05 Forgot Password
- A06 Check Your Email
- A07 Reset Password
- A08 Password Reset Success
- A09 Registration Success

## Pet Owner

- O01 First Pet Setup
- O02 Pet Created Success
- O03 Home Dashboard
- O04 Notifications
- O05 My Pets
- O06 Add/Edit Pet
- O07 Pet Profile & Health Hub
- O08 Health Analytics
- O09 Find Veterinary Hospitals
- O10 Hospital Details
- O11 Book Appointment
- O12 Appointment Confirmation
- O13 My Appointments
- O14 Appointment Details
- O15 Live Queue
- O16 Pet Health Passport / QR
- O17 AI Assistant
- O18 AI Insights
- O19 Adoption Listings
- O20 Adoption Pet Details & Request
- O21 My Adoption / Rehoming
- O22 Profile & Settings

## Veterinary / Staff

- V01 Veterinary Dashboard
- V02 Veterinary Appointment / Consultation
- V03 QR Scanner
- V04 Pet Health Passport
- V05 Veterinary Queue

## Adoption Provider

- R01 Adoption Provider Dashboard
- R02 Adoption Listings / Create-Edit
- R03 Adoption Requests
- R04 Provider Profile & Settings

Use the established screen IDs in implementation notes, PRs and OpenCode prompts where useful.

Do not casually renumber approved screen IDs.

---

# 7. Architecture Standard

Use feature-first layered Clean Architecture.

## Presentation

Responsible for:

- Pages
- Widgets
- UI state
- Controllers/providers/notifiers
- User interaction
- Navigation calls

Must avoid:

- Direct Firestore access
- Direct API access
- Heavy business rules
- Data-source implementation details

## Domain

Responsible for:

- Entities
- Repository contracts
- Use cases
- Business validation
- Domain rules

Must avoid:

- Firebase SDK dependency
- UI-specific dependencies
- Presentation concerns

## Data

Responsible for:

- DTOs/models
- Data mapping
- Repository implementations
- Firebase data sources
- API data sources
- Persistence details

Must avoid:

- Presentation-specific UI decisions

## Core

Contains only genuinely global infrastructure:

- constants
- errors
- utility functions
- services
- Firebase helpers
- network infrastructure
- global widgets where genuinely cross-feature

Do not place feature-specific business logic in `core`.

## Shared

Contains only genuinely reusable cross-feature artifacts:

- shared enums
- shared models when truly cross-feature
- shared widgets/components

Do not use `shared` as a dumping ground.

---

# 8. Required Feature Structure

Each feature should follow:

```text
lib/features/<feature>/

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