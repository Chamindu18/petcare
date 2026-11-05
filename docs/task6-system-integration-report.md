# Task 6 — System integration and shared Firebase verification

Audit date: 2026-11-04. Repository: `D:\projects\petcare`. Branch: `feature/member1`.

**Recommendation: NO-GO for deployment readiness.** Local emulator contracts pass after one small scheduling fix. The shared project is incompatible with the current trusted scheduler and verified veterinarian identity contract. No deployment, live callable invocation, production data change, migration, commit, push, or merge was performed.

## Repository baseline and teammate integration

- Initial tracked and untracked working tree was clean. HEAD was `c1127bb`, the Task 5 PR #101 merge. Local `main`, `origin/main`, and `origin/feature/member1` matched HEAD.
- Relevant history: `fd2490a` trusted concurrent scheduling/verified veterinarian assignment; `d90f8f0` staff queue UI; `34b3d9e` secure queue backend; `08f74f4` veterinarian dashboard redesign through PR #99.
- Cached teammate refs include member3's veterinarian UI, member4's home/adoption work and member5's AI work. Branch-ref history shows no unmerged feature commits outside HEAD; the only additional `--all --not HEAD` objects belong to the existing stash. No remote fetch was performed, so newly pushed remote work is outside this audit.
- Existing `stash@{0}` (`temporary changes before switching to feature-member1`) was preserved. No stash was applied or modified.
- No existing uncommitted changes or merge markers required resolution. No teammate UI or dashboard code was changed.

## Existing integration architecture

Flutter retains feature-first presentation/domain/data layers. Owner O09–O11 uses active hospital discovery, hospital-scoped doctor/service discovery and advisory availability. Availability reads `appointment_schedule`, then the slot-generation use case subtracts occupied intervals using duration snapshots or legacy service durations. These reads are not a reservation guarantee.

`FirebaseAppointmentRepository.createAppointment`, `updateAppointment`, and `reassignVeterinarian` delegate to `FirebaseAppointmentSchedulingDataSource`. It sends an authenticated Firebase callable-protocol HTTP request to `https://asia-south2-<FirebaseAuth projectId>.cloudfunctions.net/reserveAppointmentSlot`. It does not fall back to direct Firestore scheduling writes.

The Node 22 v2 callable validates the owner/pet, staff assignment, hospital, service and verified veterinarian relationship. A Firestore transaction writes the canonical `appointments/<id>`, privacy-limited `appointment_schedule/<id>` and veterinarian mutex revisions in `appointment_booking_locks`. Conflicts use canonical appointments, including legacy appointments without schedule projections. Appointment IDs, directory veterinarian IDs, service IDs, hospital IDs and owner Auth UIDs are shared across modules.

Staff authority requires `users/<Auth UID>.role == veterinary_staff` and `hospital_staff/<Auth UID>` with matching `userId`, `hospitalId`, and `active: true`. Doctor authority requires a veterinarian user profile, matching hospital, `users.vetId` (or UID-keyed legacy fallback), and an active directory record whose `userId` matches that Auth UID. Display names, email addresses and arbitrary directory IDs grant no authority.

Status decisions use client Firestore transactions and synchronously update appointment and schedule status under security rules. Staff queue commands atomically allocate a hospital/day counter, create one `queue_records` entry and link it from the appointment. Queue lifecycle is `waiting -> in_consultation -> completed`; reverse/skipped transitions are denied. Hospital dates use Asia/Colombo. Queue completion and appointment status are separate fields; no new automatic appointment-completion behavior was introduced.

## Environment and deployment compatibility

Evidence: [read-only audit snapshot](task6-live-readiness.json). The reusable audit script performs authenticated GET requests only and saves aggregates, configuration, and rule hashes; it does not print credentials or personal document contents. Re-run from the repository root with `node scripts/verify-shared-firebase.cjs` using authorized Firebase CLI credentials. Reads consume normal read quota. The snapshot is not an atomic database export.

| Check | Repository / emulator | Actual shared project |
| --- | --- | --- |
| Project | `.firebaserc`, Android services JSON and Dart options agree on `petcare-d4413` | Database reachable in this project |
| Region / edition | Function `asia-south2`; configured Firestore `(default)` / `asia-south2` | Native Firestore, Standard edition, `asia-south2` |
| Functions | `appointments` codebase, Node 22, `reserveAppointmentSlot` | Listing returns HTTP 403: Cloud Functions API has not been used or is disabled. Deployed callable/region/version cannot be verified; treat trusted booking as unavailable until resolved |
| Rules | Repository rules loaded into emulator | Active release updated `2026-11-02T15:27:48.859892Z`; deployed source hash differs from local rules. Live enforcement was not exercised with test writes |
| Indexes | Eight declared composite indexes | Eight deployed indexes; seven declared indexes match READY entries. Declared `appointments(hospitalId ASC, vetId ASC)` index is absent. Deployed count alone does not establish compatibility |
| Directory | Verified Auth/user/directory linkage required | 55 active directory records; all 55 lack `userId`, so none satisfies current linkage. One user has veterinarian role; 10 Auth accounts and 10 user profiles were readable |
| Staff | Active UID-keyed assignment required | One active assignment; no invalid active assignment detected against users, Auth identities, and hospital references |
| Legacy appointments | Canonical records remain the conflict source | Four appointments, zero schedule records, all four missing duration snapshots. Referenced users/hospitals/services/doctors exist; no invalid pet ownership detected |
| Queues | Atomic linkage and daily ledger required | Zero queue records; no broken appointment queue link detected |

There are 32 hospitals, 160 services and 10 pets in the read-only snapshot. Existing references do not prove doctor eligibility: missing directory-to-account linkage remains a blocker. No provisioning guesses were made.

Legacy preparation requires a reviewed plan for verified veterinarian provisioning, privacy-limited schedule projections and duration snapshots. Historical duration cannot necessarily be recovered from a service's current duration; review it before migration. The callable already checks legacy canonical appointments for conflicts, but availability can display stale/free slots when projections are absent. No migration/backfill was run. The backfill tests below only exercise pure transformation functions with fixture data.

Existing application clients that still write bookings or reassignment directly will be denied by the current repository rules. A coordinated client/backend/rules release is required; deploying only restrictive rules would break those clients. No installed Android client version inventory was available.

## Confirmed defect and smallest fix

**Scheduler accepted nonexistent/inactive hospitals.** The owner discovery UI hid inactive hospitals, but the trusted server checked only matching service and doctor hospital IDs. A stale or forged request could therefore schedule against a missing hospital.

Reproduction: a new emulator test first booked a valid appointment, deleted the hospital and attempted a second booking. The pre-fix run failed with `Missing expected rejection` (20 passed, 1 failed in `task6-hospital-reproduction.log`).

Fix: read the hospital inside the same scheduling transaction and require `active === true` before proceeding. This covers create, owner update and staff reassignment. Existing status/queue workflows were not redesigned. The regression verifies missing and inactive hospitals deny booking and reassignment without changing appointment/schedule counts or lock revision. Fixture hospitals were added to existing scheduling/transport tests. Rules were not changed or weakened.

Two additional Dart transport regressions verify network failures propagate without apparent success and HTTP 403 preserves the callable's denial message. No production Dart implementation change was required.

## Cross-role coverage and limits

| Workflow | Automated evidence |
| --- | --- |
| A — Owner booking | Real authenticated callable creates pending canonical appointment and projection with trusted owner/duration. Active hospital/doctor discovery queries run under owner rules. Slot calculation and Flutter repository delegation covered by Flutter tests |
| B — Staff | Hospital-scoped reads; confirmation/rejection with schedule consistency; stale decision refused; real authenticated staff callable reassigns to another eligible doctor. Foreign/inactive/forged assignments denied by rules and scheduler tests |
| C — Veterinarian | Hospital + canonical vet ID queries; old doctor's access disappears after real reassignment; new doctor sees the record; forged identity and wrong hospital denied |
| D — Queue | Today's confirmed booking checks in with one linked record/counter; two concurrent check-ins produce one winner; forward lifecycle works and skipped/reverse/foreign-hospital edits fail. Dedicated tests cover distinct daily numbers, hospitals, dates and Colombo/UTC boundaries |
| E — Concurrency / failure | Six overlapping reservations produce one winner; partial overlaps, booking/reassignment races and failed validation preserve atomicity; duplicate check-ins do not increment twice; direct writes and forged durations/locks fail. Dart tests cover offline errors and permission denials |
| F — Compatibility | Owner, staff and assigned doctor reread the same reassigned/queued appointment; owner sees queue lifecycle changes; projection matches assignment. Full Flutter suite and legacy rules suite cover teammate regression boundaries |

The new `functions/test/cross_role.test.mjs` bridges real Auth/Functions emulator transport to Firestore security-rule reads and writes; it does not simulate reassignment with a rules-disabled write. Only fixture provisioning uses the Admin SDK. Doctor reads use rules-test authenticated contexts; owner booking and staff reassignment use actual Auth emulator tokens.

These are backend contract and Flutter unit/widget/repository tests, not Android device end-to-end tests. No Android screens were driven against live Firebase. Emulator tests do not prove deployed rules, index enforcement, cloud runtime/IAM, real connectivity, App Check configuration, or device refresh behavior. A timeout after a server commit can leave the client uncertain: refresh before retrying and verify the existing appointment, rather than assuming rollback. Stale status/queue transactions are tested; arbitrary offline UI interactions remain manual.

## Verification results

Environment: Flutter 3.47.5, Dart 3.13.4, Node v22.22.2; Functions configured for Node 22. No dependency installation or version changes.

| Command | Result / evidence |
| --- | --- |
| `dart format test/features/appointments/appointment_scheduling_datasource_test.dart` | Changed Dart file formatted |
| `flutter analyze` | No issues, including final state (`task6-analyze-final.log`) |
| `flutter test` | Final full run: 425 passed (`task6-flutter-final.log`) |
| Targeted Flutter scheduling datasource tests | 5 passed (`task6-transport-flutter.log`) |
| `npm run test:rules` | Final 111 passed, zero skipped/failed (`task6-rules-final.log`) |
| `npm run test:legacy` | 46 passed (`task6-legacy.log`) |
| `npm run test:booking` | 2 integration tests passed: authenticated concurrency transport and full cross-role scenario (`task6-callable-final.log`) |
| `node --test test/firestore/appointment_schedule_backfill.test.mjs` | 3 pure migration-planning tests passed (`task6-migration-unit.log`); no migration performed |
| `git diff --check` | Passed; final status contains only Task 6 changes |

All emulator commands explicitly use `demo-petcare`. Suites were serialized to avoid shared Firestore ports/fixture resets. One initial reproduction attempt collided with an already-running emulator; another shell name-filter attempt selected no tests. Neither was counted as validation. The complete reproduction file was then run and exposed the defect. Initial sandboxed Flutter/CLI commands needed SDK/settings access; authorized reruns completed. Expected permission-denied logging comes from negative tests.

## Changed files

- `functions/src/appointment_booking.mjs`: active hospital validation.
- `functions/test/appointment_concurrency.test.mjs`: hospital fixtures and atomic failure regression.
- `functions/test/callable_transport.test.mjs`: active hospital fixture.
- `functions/test/cross_role.test.mjs`: real callable-to-cross-role integration scenario.
- `test/features/appointments/appointment_scheduling_datasource_test.dart`: offline/403 regressions, formatted.
- `package.json`: include cross-role test in `test:booking`; add reproducible `test:legacy` command.
- `scripts/verify-shared-firebase.cjs`: GET-only shared-project readiness audit.
- `docs/task6-live-readiness.json`: aggregate live evidence and rule hashes.
- `docs/task6-system-integration-report.md`: this report.
- `docs/task6-security-audit.json`: scoped security audit assessment.

Local ignored `task6-*.log` files retain detailed command evidence. No production configuration, rules, indexes, dependency locks, UI, or teammate dashboard files were edited.

## Exact remaining Android scenarios

Run on isolated emulators or a separately authorized staging project after its readiness prerequisites are satisfied. The current app bootstrap has no emulator switch: a test-only harness must configure Auth/Firestore and inject the scheduling datasource endpoint together. Android emulator host is typically `10.0.2.2`; do not point only Firestore at an emulator while leaving the default callable on the shared project. No such harness or live-data writes were added during this task.

Prepare owner O1 with pet P1, unrelated owner O2/P2, active hospitals H1/H2, H1 service S1 (30 minutes), H2 service S2, active H1 doctors D1/D2 and H2 doctor D3, and staff S-H1/S-H2. Provision real test Auth users and matching trusted assignment documents. Use a future hospital-open slot for booking and separate fixtures scheduled for today's Colombo date for check-in. Test each role in an independent signed-in app instance.

1. **O09 -> O10 -> O11 -> O12 -> O13/O14:** O1 chooses H1, D1, S1, and a displayed free future slot. Submit once. Verify success, pending status, P1/O1/H1/S1/D1 IDs, UTC time and 30-minute duration. Refresh and restart; exactly one booking remains. Inactive H2/doctor fixtures must disappear or fail safely if deactivated after selection.
2. **Availability race:** O1 and O2 select the same H1/D1 interval before submitting simultaneously. Exactly one succeeds; the loser sees a useful error and refreshed availability. No second canonical appointment/projection is created. An adjacent slot or D2 booking succeeds.
3. **Staff decision:** S-H1 refreshes and sees H1's pending appointment; S-H2 cannot see it. Confirm one booking and reject a separate pending booking. O1 and D1 refresh and see matching statuses. Try confirming the already-rejected item from stale UI; it must fail without reopening it.
4. **Reassignment:** S-H1 reassigns a pending/confirmed unqueued H1 appointment from D1 to D2. After refresh/relaunch D1 loses access, D2 sees it, and O1/staff display D2. H2 doctor D3 and inactive/unlinked directory records must be unavailable/rejected. Try a conflicting D2 slot and verify no assignment/projection change.
5. **Identity isolation:** Sign in as an unassigned doctor, D3, and staff S-H2. Attempt cached/deep-linked H1 appointment access. Each must fail safely. An unrelated owner must not read O1's appointment. Sign out/in and ensure prior role's records do not remain accessible.
6. **Today's check-in:** S-H1 checks in a confirmed appointment scheduled today in Colombo. Owner O14/O15 and staff queue refresh to the same queue ID/number. Simultaneous taps from two S-H1 sessions create one record/link and one counter increment. Yesterday, tomorrow, pending, rejected and cancelled fixtures cannot check in.
7. **Queue allocation/lifecycle:** Check in several distinct H1 appointments concurrently: unique increasing daily numbers. H2 allocates its own sequence. Move waiting -> in consultation -> completed; owner refresh sees each change. Attempt skip/reverse/stale and S-H2 changes; all fail. Restart preserves history; another Colombo day starts an independent counter.
8. **Connectivity/errors:** Disable network while loading, booking, deciding, reassigning and checking in. Verify no false success, no stuck spinner and usable error/retry UI. Disconnect immediately after submission, reconnect and refresh to resolve unknown server outcome before retrying. Revoke assignment in test fixtures and verify permission errors and refreshed role gating.
9. **Time boundaries:** Repeat today's eligibility with device timezone different from Colombo and around Colombo midnight. Verify displayed appointment time, chosen slot, day counter and eligibility match the intended hospital date. Include legacy Timestamp and offset-free fixture dates.
10. **Teammate smoke:** Exercise login/reset/role routing, pet profile/health records, adoption listing/request ownership, notifications, home navigation and AI entry points. Verify O01–O22 navigation is unchanged and QR passport remains appointment-authorized. AI/backend/device functionality beyond existing tests is not certified by this task.

## Readiness exit criteria

Resolve the Functions API/deployment availability, verify the intended callable/region/runtime, review and deploy compatible rules/indexes through a separately authorized release, provision verified doctor identities, and approve/validate legacy projection/duration preparation. Then repeat read-only readiness checks, run the Android scenarios on staging, and review older-client rollout compatibility. The current result is **local integration verified within the stated automated scope; shared Firebase and Android deployment readiness not achieved**.
