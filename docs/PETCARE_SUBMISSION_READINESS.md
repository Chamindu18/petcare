# PetCare+ academic submission readiness

Audit: 2026-11-06, current `feature/member1` HEAD `c0fde89`. **Audit only; no feature, Firebase, or Git state change was performed.** This is an implementation-status review, not a device acceptance test.

## Basis and verification

- Requirements baseline: `AGENTS.md` MVP and screen IDs, `README.md` workstreams, and the five-member allocation in the audit request. The original **Team Work Plan**, project proposal, and separate screen specifications are **not present in this repository**. Obtain them before claiming exact requirement coverage. The README's “Under Active Development” status is stale.
- The post-merge report verifies integrated `main` at `1ffa402` with `flutter analyze`, 459 Flutter tests, 111 rules tests, 46 legacy tests, and two booking emulator scenarios passing. `docs/SPARK_EMULATOR_DEMO.md` records the later `45ea3df` Spark demo fixture reset, the same test results, and a successful emulator-only Android debug APK build. Current HEAD adds the documented emulator switch/seed over `45ea3df`; it has **not** been installed or interactively driven on Android.
- Current source checks: `flutter analyze` **no issues**; targeted scheduling datasource and router tests **27 passed**; `git diff --check` clean; no unmerged paths or conflict markers in `lib`, `test`, `functions`, `docs`. Workspace was clean before this report. No full suite was repeated.
- Demo uses synthetic Auth/Firestore/Functions emulators. Booking against shared Spark Firebase is not a supported demo path because its callable is not deployed. This is a documented environment boundary, **not a new source bug**. No paid service is needed for the emulator demo.

## Member checklist

Status: **I** implemented/connected within tested scope; **P** partial; **M** missing. A screen's presence alone does not earn I.

| Owner | Planned work | Status and current evidence |
| --- | --- | --- |
| Member 1 | A01–A09 splash, onboarding, email/password login, registration, reset flow; O03 home; role routing and owner shell | **I** routes, Firebase auth repository, home and five-tab `Home | Pets | Appointments | AI | Profile` shell; auth/router/widget tests. **P** O01/O02: first-pet empty-state/add form exists, but no distinct first-pet setup or pet-created success screen. Password-reset email flow is not in the synthetic emulator demo. |
| Member 2 | O05–O08 pet add/edit/view, health hub, conditions, vaccinations, treatments, measurements, analytics | **I** connected pet/health repositories, controllers and pages; existing post-merge tests report no regression. No obvious broken action found in this focused review. |
| Member 3 | O09–O16 hospitals, services/vets, booking, confirmation, owner appointments/queue/QR; V01–V05 veterinary | **I** discovery, details, selection, emulator booking/confirmation, owner appointment list, verified veterinarian dashboard/list/status/profile, staff-backed queue data. **P/M** owner appointment detail and owner live-queue screens, QR creation/scanning/passport, consultation notes/completion, veterinarian queue control; see tasks below. |
| Member 4 | O04 notifications/reminders; O19–O22 adoption, rehoming, profile; R01–R04 provider | **I** notification list/read state, adoption discovery/request tracking, provider listing CRUD and accept/reject, owner profile/settings. **P/M** reminder generation/delivery and owner rehoming create/manage/applicant decisions. Provider has dashboard actions and logout, but no distinct R04 profile/settings screen was found. Adoption filter button does nothing. |
| Member 5 | O17/O18 chat, summaries, insights, preventive guidance, visit prep; integration and QA | **P** screens and pet-context-based deterministic templates work; no actual model-generated responses. Chat contains a hardcoded wrong pet name. Repository methods return placeholder text. Automated Flutter, Firestore, and cross-role emulator tests exist; no Android UI integration test or interactive screenshot evidence was found. |
| Hospital staff | Assignment, dashboard, appointment decisions/reassignment, queue, profile/logout | **I** assignment gate, overview, hospital-scoped appointment confirm/reject/reassign, check-in and queue lifecycle, profile/logout; emulator cross-role scenario covers the workflow. **P** visible “Schedule” tab is a static placeholder. |

### Implemented, partial, and missing at a glance

- **Implemented:** authentication/owner shell; pet and health CRUD/analytics; hospital discovery and selection; emulator appointment booking/confirmation; owner appointment list; staff decisions/reassignment/queue; assigned veterinarian dashboard and profile; adoption browsing/provider requests and listing management; notification list/read; owner profile/settings.
- **Partial:** owner appointment management, veterinarian appointment/consultation, in-app notifications versus reminders, deterministic pet-context summaries/insights/chat, first-pet onboarding, provider profile/settings, staff schedule.
- **Missing:** functioning QR passport/scanner, owner live queue and detail screen, owner rehoming management, reminder producer/delivery, genuine AI-generated replies, veterinarian queue controls and consultation notes/completion.

## Findings and ranked remaining work

**A = essential to satisfy the stated MVP or avoid an obvious submission failure.** These required features cannot silently be downgraded because they take time. If the team cannot finish one, disclose it and obtain course/supervisor acceptance of a reduced demonstration. Effort is a rough developer estimate, excluding review and device setup.

| Rank | Class | Feature / owner | Current implementation and exact gap | File or route | Quick fix? / effort | Blocks? |
| --- | --- | --- | --- | --- | --- | --- |
| 1 | A | Demo evidence / M5 with all members | Emulator demo and APK are documented; no recorded Android installation, interactive run, or final screenshots. Execute the documented synthetic-account flow, capture evidence, and attach test/APK results to final report. | `docs/SPARK_EMULATOR_DEMO.md` | Yes, 0.5–1 day if device/emulator works | **Yes**, a mobile app submission needs demonstrable mobile behavior. |
| 2 | A | QR Health Passport and scanner / M3 | Repository `createQrReference` and `verifyQrReference` throw `UnimplementedError`; veterinarian QR action states unavailable; O16/V03/V04 have no functioning route/workflow. | `lib/features/qr_health_passport/data/repositories/firebase_qr_health_passport_repository.dart`, `veterinarian_dashboard_page.dart` | No, 2–4 days plus demo test | **Yes** for full stated MVP; disclose/agree scope if not feasible. |
| 3 | A | Owner appointment details and live queue / M3 | O13 is a summary-card list; no O14/O15 route or owner queue page. Queue state exists and staff can advance it, but owner cannot open a live position/status view. Cancellation exists in repository but no owner list/detail action is exposed. | `/my-appointments`, `my_appointments_page.dart`, `firebase_appointment_repository.dart` | Moderate, 1–2 days | **Yes** for full appointment/queue journey. |
| 4 | A | AI assistant function / M5 | Chat sends keyword/template responses from page code; repository returns “dummy”/“will appear here”; summaries/insights/prep are deterministic pet-record templates, **not AI-generated**. Summary chat says “Spiderman” for every pet. Either provide a genuine free, permitted AI path or explicitly relabel/limit claims with supervisor approval; fix wrong name regardless. | `/ai-chat`, `ai_chat_page.dart:65`, `ai_repository_impl.dart` | Name: yes, <1 hour; actual AI: no, 1–3 days | **Yes** if advertised as an AI assistant. |
| 5 | A | Owner rehoming / M4 | Owner dashboard only links browse and submitted requests. Provider listing editor exists, but owner create/manage and applicant approval flow is absent; current request rules reject owner-owned listings. | `/owner-rehoming`, `owner_rehoming_dashboard_page.dart` | No, 2–4 days | **Yes** for stated owner rehoming MVP. |
| 6 | A | Reminders / M4 | In-app notification list/read and settings toggle exist; no producer, schedule, or delivery of vaccination/appointment reminders found. `firebase_messaging` dependency alone does not implement reminders. | `/notifications`, `firebase_notification_repository.dart`, `notification_settings_page.dart` | No, 1–3 days for a demonstrable free/local mechanism | **Yes** for stated reminder objective. |
| 7 | A | Consultation and veterinarian queue / M3 | Vet can see assigned appointment and status; detail explicitly says notes/completion and queue management unavailable. Staff queue works, but V02/V05 workflows are incomplete. | `veterinarian_appointment_details_page.dart:312`, `veterinarian_dashboard_page.dart` | No, 2–3 days | **Yes** for full veterinary MVP; staff queue can demonstrate only part. |
| 8 | B | Adoption filter control / M4 | Tune icon has an empty `onPressed`; search itself works. Either make filter operate or remove the inert affordance before screenshots. | `adoption_listings_page.dart:132` | Yes, <0.5 day | No, unless shown during demo. |
| 9 | B | Staff daily schedule / staff workstream, M3 | Schedule tab opens a description-only placeholder. Existing Appointments tab is functional. | `staff_shell_page.dart:101` | Moderate, 0.5–1 day, or hide unused tab | No for core staff demo; do not present tab as finished. |
| 10 | B | Distinct first-pet success and provider settings / M1, M4 | First pet uses general add form/empty state with no O02 success page; R04 distinct profile/settings page not found, though provider dashboard has logout. | `/my-pets`, provider dashboard | Moderate, 0.5–1 day each | No if original screen specs do not require distinct views; verify source requirements. |
| 11 | A | Final requirements/report alignment / M5 and team lead | Original work plan/screen specs and final screenshots/report artifact absent from repository. Reconcile the actual documents, label emulator-only booking and deterministic AI honestly, then submit evidence. | `README.md`, this report, demo doc | Yes, 0.5–1 day after evidence | **Yes** for truthful final submission. |

**C — document as limitation:** Shared-project booking is unavailable on Spark without a deployed callable; the supported academic path is the documented local emulator. Android installation and device behavior remain unverified until task 1 is done. Production deployment, paid Firebase services, advanced AI diagnosis, payments, and hospital administration are outside this submission scope. The A-class MVP gaps above remain required by the supplied baseline and are **not** reclassified as C merely because implementation would take longer.

### Visible broken or misleading functionality

- The adoption filter button is inert (`adoption_listings_page.dart:132`).
- Chat summary uses a hardcoded “Spiderman” title (`ai_chat_page.dart:65`) and behaves like AI despite template responses.
- Staff “Schedule”, QR shortcut, vet queue and consultation actions expose unavailable/placeholder content. These are incomplete features, not runtime crashes.
- No broken import or current analyzer error was found. No other obvious action defect was established by this review.

## Minimum acceptable academic demonstration

1. Run the Spark emulator setup exactly as documented; use synthetic accounts only. Show owner pet and health records, hospital/service/vet selection, booking confirmation, owner appointment list, staff confirm/reject/reassign, assigned vet visibility, and staff queue transitions. Show adoption provider listing/request decisions, owner adoption request tracking, notification read state, and profile/logout where fixtures permit.
2. Show the Android app running, not only emulator backend tests. Capture the real on-screen sequence and successful build/test summaries.
3. State clearly in the presentation/report that booking runs against local emulators on Spark, AI text is currently deterministic, and the A-class MVP gaps above are incomplete unless finished before submission. Do not claim QR scanning, live owner queue, reminders, owner rehoming, or consultation/doctor queue are working when they are not.
4. Compare the missing original work plan and screen specification with this checklist. If the course requires every MVP item, the current project is **not fully ready**; secure an accepted reduced scope or complete those items before final submission.

## Required screenshots and report evidence

- Android: splash/login, owner five-tab shell, pet profile/health/analytics, hospital/service/vet selection, booking confirmation and appointment list.
- Cross-role: staff pending confirm/reject/reassign, veterinarian assignment before/after, staff queue waiting/in consultation/completed, provider listing and request decision, adoption browsing/request tracking, notification read state, profile/logout.
- Backend/test: Emulator UI synthetic users and relevant records; one-winner booking test, analyzer/test results, APK build result. Capture QR/AI/owner queue only if completed; otherwise list them as limitations in the report.
- Source documentation: original work plan and approved screens (currently missing), final report, `docs/SPARK_EMULATOR_DEMO.md`, `docs/PETCARE_POST_MERGE_VERIFICATION.md`.

## Recommendation

**Submission is conditional.** The connected Spark emulator booking/staff/veterinarian path is strong enough for a focused academic demo, and the current source analyzes cleanly. First obtain Android screen evidence and reconcile the original requirements. The stated MVP still has substantial required QR, owner queue, AI, reminder, rehoming, and veterinary consultation gaps; present those honestly and seek scope acceptance if they cannot be completed in time. Do not spend submission time on cloud deployment or production hardening.
