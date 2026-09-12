# PetCare+ — OpenCode Project Context

## Project Identity
- Project: PetCare+
- Course: SE303.3 Mobile Application Development
- Platform: Flutter/Dart mobile application
- Backend: Firebase
- Team size: 5
- Supervisor: Mr. Diluka Wijesinghe
- MVP constraint: approximately one month remaining

## Product Positioning
PetCare+ is a smart multi-hospital pet-care platform. Pet owners manage multiple pets and their health information, discover veterinary hospitals, book appointments, track live queues, use an appointment-linked QR Pet Health Passport with authorized veterinary access, use AI-assisted pet-care functions, and discover/adopt or rehome pets.

The MVP is intentionally not a full hospital information system, full e-commerce system, or online payment/delivery platform.

## User Contexts
1. Pet Owner — primary user; public mobile registration.
2. Veterinarian / Veterinary Staff — secondary user; account provisioned/approved through an authorized process, not public self-registration.
3. Adoption Provider / Rehoming Provider — supporting user; account provisioned/approved through an authorized process, not public self-registration.
4. No Admin role in the PetCare+ mobile application.

## MVP Boundaries
Included:
- Multiple pet profiles
- Pet health records, medical conditions, vaccinations, treatments, measurements and analytics
- Multi-hospital discovery and hospital details
- Appointment booking and appointment management
- Real-time queue tracking and veterinary queue management
- Appointment-linked QR Health Passport with authorization checks
- Veterinary consultation support
- AI general care assistant, health summary, preventive insights and vet-visit preparation
- Notifications/reminders
- Adoption discovery and adoption requests
- Owner rehoming listings
- Adoption-provider listing/request management

Excluded from MVP:
- Pet-product marketplace/e-commerce
- Online payments
- Delivery/logistics/transport
- Legal ownership transfer processing
- Full hospital administration system
- Mobile Admin application
- AI diagnosis, prescribing, dosage changes or treatment replacement
- Advanced AI image diagnosis

## Owner Navigation
Home | Pets | Appointments | AI | Profile

## Primary Screen IDs
Shared/auth: A01 Splash, A02 Onboarding, A03 Login, A04 Pet Owner Registration, A05 Forgot Password, A06 Check Your Email, A07 Reset Password, A08 Password Reset Success, A09 Registration Success.

Owner: O01 First Pet Setup, O02 Pet Created Success, O03 Home Dashboard, O04 Notifications, O05 My Pets, O06 Add/Edit Pet, O07 Pet Profile & Health Hub, O08 Health Analytics, O09 Find Veterinary Hospitals, O10 Hospital Details, O11 Book Appointment, O12 Appointment Confirmation, O13 My Appointments, O14 Appointment Details, O15 Live Queue, O16 Pet Health Passport/QR, O17 AI Assistant, O18 AI Insights, O19 Adoption Listings, O20 Adoption Pet Details & Request, O21 My Adoption/Rehoming, O22 Profile & Settings.

Vet/Staff: V01 Veterinary Dashboard, V02 Veterinary Appointment/Consultation, V03 QR Scanner, V04 Pet Health Passport, V05 Veterinary Queue.

Adoption provider: R01 Adoption Provider Dashboard, R02 Adoption Listings/Create-Edit, R03 Adoption Requests, R04 Provider Profile & Settings.

## Architecture
Use feature-first layered/Clean Architecture:
- Presentation: pages, widgets, UI state, navigation; no direct Firestore/API access.
- Domain: entities, repository contracts, use cases, business validation.
- Data: repository implementations, DTO/model mapping, Firebase/API data sources.
- Core: genuinely global infrastructure/utilities/errors/constants.
- Shared: genuinely reusable components/models/enums only.

Use existing state-management conventions. Do not introduce a second state-management framework for one feature without team agreement.

## Core Data Contracts
Key entities: users, pets, medical_conditions, vaccinations, treatments, health_measurements, hospitals, services, veterinarians, appointments, queues, notifications, adoption_listings, adoption_requests.

Important relationship rules:
- User profile and pets are separate records.
- pets.ownerId identifies the owner.
- Appointments reference ownerId, petId, hospitalId, serviceId and vetId.
- Health records belong to a pet.
- Owner-reported and veterinarian-confirmed health information must remain distinguishable.

## Security
- Firebase Authentication is the identity source.
- Firestore/Storage Security Rules enforce ownership and role authorization.
- Client-side hiding is never security.
- Vet access to pet data must be authorized by the relevant appointment/hospital context.
- QR codes contain secure token/reference information, not full medical data.
- External AI keys/secrets remain server-side.
- Minimize health/personal data sent to external AI services.
- Never log passwords, access tokens, API keys or unnecessary health information.

## AI Rules
OpenCode is an engineering assistant, not an autonomous developer or source of product truth.

AI product functions:
- General pet-care chat
- Health-record summarization
- Preventive-care insights
- Veterinary-visit preparation

AI must not diagnose, prescribe, change medication dosage, or replace veterinary judgment.

## OpenCode Working Rules
Before advising:
1. Inspect the current repository and branch.
2. Locate the feature and screen ID.
3. Inspect existing routes, models, repositories and shared components.
4. Trace dependencies into/out of the feature.
5. Inspect Firebase/API usage and security assumptions.
6. Check related work from other members.
7. Only then explain the issue and recommend the smallest safe change.

Default behavior:
- Inspect, explain, debug, trace, summarize and review.
- Do not implement code changes unless the developer explicitly requests implementation.
- Do not rewrite whole features for small defects.
- Do not invent duplicate models/repositories/components.
- Do not change navigation, Firestore contracts, roles, security boundaries or architecture without team coordination.

## Project State Summary
Every member may ask OpenCode to produce a concise current-state summary with:
- Current branch
- Completed work
- In-progress work
- Related screen IDs
- Dependencies on other members
- Routes affected
- Known issues
- Security concerns
- Tests run/pending
- Next action

## Five Members
- Member 1 — RPDA Mihisarani 37047: app foundation, authentication, routing/theme, owner Home.
- Member 2 — RACH Ranasinghe 37014: pets and health.
- Member 3 — HMI Udara 37020: hospitals, appointments, queue, QR, veterinary core.
- Member 4 — MCI Fernando 37101: notifications, adoption/rehoming, provider flow, profile/settings.
- Member 5 — HHNV Induwara 37171: AI, integration, QA.

## Git Rules
- Use feature/fix/refactor branches; do not develop directly on main.
- Use small coherent PRs.
- Meaningful identifiable commits are required for individual contribution evidence.
- Review diffs before merge.
- Re-test after shared-contract changes.

## UI System
- Primary Purple: #6C4DE6
- Dark Purple: #4D35B8
- Coral: #FF7A6B
- Sky Blue: #55B8E8
- Sunshine Yellow: #FFC94A
- Warm Cream: #FFF9F4
- White: #FFFFFF
- Deep Navy: #20243A
- Slate: #687086
- Success: #43B581
- Warning: #F2A93B
- Error: #E95D65
- Font: Plus Jakarta Sans
- Spacing rhythm: 8 px
- Card radius: 16–20 px
- Owner bottom navigation: Home | Pets | Appointments | AI | Profile

## Source of Truth Order
1. Approved project scope and supervisor decisions
2. Current Git repository and integrated code
3. The four PetCare+ team documents
4. This AGENTS.md as a concise machine-readable context file

When uncertain, inspect the repository and the approved documents before proposing a new direction.
