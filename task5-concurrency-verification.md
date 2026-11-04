# Task 5 continuation ? Concurrent appointment conflict prevention

Branch: `feature/member1`. Existing uncommitted Task 5 work was preserved. No teammate-owned screens were changed in this continuation. No commit, push, merge, deployment, production booking, or production migration was performed.

This report supersedes the concurrency limitation recorded in the earlier task5-verification.md; that earlier report remains as historical evidence.

## Root cause and reproduction

Booking queried appointment_schedule outside its write batch. Staff reassignment queried hospital appointments before a transaction that read only its selected appointment and directory record. Two requests affecting different appointment IDs had no shared read/write conflict, so both could observe availability and commit overlapping intervals.

Before changing rules, an emulator test synchronized two empty schedule reads, then submitted both booking batches concurrently. Both succeeded and the emulator contained two appointments for the same veterinarian and interval. See task5-concurrency-reproduction.log (1 reproduction test passed, asserting the incorrect count of 2). The retained reproduction test now verifies that this old client-only path is denied and leaves both collections empty.

## Implementation and invariants

- Added the `appointments` Firebase Functions codebase and authenticated `reserveAppointmentSlot` callable in asia-south2. The data source follows the documented Firebase callable protocol with the existing HTTP dependency and a Firebase Auth ID token; no Flutter dependency was added.
- Create, owner rescheduling, and hospital staff reassignment all call the same server transaction. Server code verifies user role, pet ownership on create, trusted staff assignment, same-hospital service, active directory membership, directory.userId, and the matching veterinarian account/hospital/vetId. Client-supplied ownership, status, creation time, queue linkage and duration cannot override these fields.
- Every scheduling transaction reads and updates `appointment_booking_locks/{canonical vetId}`. Reassignment locks both source and target doctor IDs in sorted order. This is a persistent revision document, not a lease requiring cleanup. Empty schedule queries still contend on the shared lock.
- The transaction reads canonical appointments for the target hospital/veterinarian, including legacy records with no projection. All non-cancelled/non-rejected intervals reserve time. Overlap uses half-open intervals: startA < endB and endA > startB. Adjacent intervals remain valid.
- The server snapshots `durationMinutes` in appointment and projection documents so later service-duration edits cannot shrink an existing server-booked interval. Legacy appointments without snapshots fall back to the trusted service duration and fail closed if it is unavailable or invalid. Hospital-local legacy ISO strings without an offset are interpreted as Asia/Colombo; new requests use UTC ISO strings.
- Appointment, projection and lock revisions commit atomically. Failed validation, conflicts, duplicate IDs, and exhausted transactions cannot partially create a booking. A caller-supplied request ID cannot overwrite an existing appointment.
- Firestore rules deny direct client appointment creation and all vetId/dateTime/serviceId changes. Existing owner cancellation, staff confirmation/rejection, note editing, hospital/doctor reads and atomic queue linkage remain authorized by the existing predicates. Clients cannot read/write mutex documents or forge duration snapshots. Cancellation/rejection only release occupied intervals; confirmation preserves an interval already reserved while pending.
- Availability remains advisory and reads the privacy-preserving projection. It now prefers the stored duration snapshot. The backfill script preserves snapshots instead of dropping them.
- Queued appointments cannot be rescheduled or reassigned. Existing queue records and the exclusive queue-link authorization branch that prevents 1,000-expression exhaustion were preserved.

Firebase documents [transaction serialization and contention](https://firebase.google.com/docs/firestore/transaction-data-contention) and the [callable protocol](https://firebase.google.com/docs/functions/callable-reference).

## Verified results

| Check | Result | Evidence |
| --- | --- | --- |
| dart format (5 changed Dart files) | Exit 0 | Terminal output |
| flutter analyze | Exit 0; no issues | task5-concurrency-analyze.log |
| flutter test | Exit 0; 421 passed | task5-concurrency-flutter.log |
| npm.cmd run test:rules | Exit 0; 108 passed, 0 failed | task5-concurrency-rules-final.log |
| Legacy Firestore emulator tests | Exit 0; 46 passed | task5-concurrency-legacy.log |
| npm.cmd run test:booking (Auth/Functions/Firestore emulators) | Exit 0; 1 passed | task5-concurrency-callable-final.log |
| Backfill tests | Exit 0; 3 passed | task5-concurrency-backfill.log |
| Node syntax checks, function module loading, git diff --check | Passed | Terminal output |
| New server production-dependency audit | Exit 1; 6 moderate, 0 high/critical | task5-concurrency-dependencies.json |

The rules suite includes 18 trusted-server tests and a client race/bypass test, alongside the existing security regressions. Tested cases include six simultaneous same-interval requests; partially overlapping service lengths; adjacent intervals; separate dates, doctors and hospitals; concurrent reassignments; booking versus reassignment; booking versus owner rescheduling; unauthorized staff/doctor/owner access; inactive/missing/mismatched directory accounts; legacy appointments missing projections; duration changes; duplicate request IDs; queue protection; cancellation releasing a reservation; and client lock/duration tampering. Counts and matching IDs verify no orphan appointments or schedules after failures. Existing strict denial helpers still reject expression/access-budget and malformed-rule evaluation errors rather than treating them as successful denials.

The first callable check ran while server dependencies were changing; a subsequent startup/discovery failure was diagnosed with the repository's pinned CLI. The actual authenticated endpoint subsequently passed, rather than relying only on directly calling the transaction function. Dart analysis initially reported three style issues; these were fixed and analysis/tests rerun.

## Deployment and migration prerequisites / remaining limitations

1. This local app now requires the new callable for create/reschedule/reassign. An authorized release must provision/deploy the Functions codebase, its Firestore permissions, and the declared hospitalId+vetId index where needed, then coordinate updated rules and mobile app rollout. Older clients' direct scheduling writes will be denied. No deployment has been performed.
2. Install Node 22 server dependencies with `npm --prefix functions ci` in addition to root test dependencies. `npm run test:booking` explicitly uses the repository's Firebase CLI and local demo Auth/Functions/Firestore emulators. The function endpoint region and project derive from the Firebase app configuration.
3. No lock backfill is required; mutex documents are created transactionally. Legacy appointments already participate in conflict checks even without projections. Backfill projections separately for accurate availability UI, using the existing dry-run-first script only during an authorized migration.
4. Review existing overlapping appointments, malformed dates, missing/invalid service durations, and unlinked/inactive doctor accounts. This change prevents new conflicts but does not automatically resolve historical overlaps or invent historical durations. Snapshot legacy durations after reviewing them if services may be edited.
5. One global lock per doctor deliberately favors correctness and covers cross-day intervals. The canonical query currently scans that doctor's hospital appointment history. Very large histories or high contention can increase latency or exhaust retry limits; such failures reject the operation atomically. A future bounded time-range index requires normalizing legacy timestamps first.
6. A lost HTTP response can leave the caller uncertain whether an atomic booking committed. The app must refresh appointments before retrying; the server prevents overlapping duplicate reservations and refuses to overwrite an existing request ID. No offline/direct-write fallback exists.
7. The new server dependency audit retains six moderate transitive findings in glob/minimatch and their gaxios/google-gax/rimraf dependency chains. Direct dependencies were updated to firebase-admin 14.5.0 and firebase-functions 7.4.0 and compatible `npm audit fix` was attempted; the remaining findings were not suppressed or bypassed with unverified major-version overrides. Review them before a production release.
8. Verification is emulator/Flutter-test based; no production or Android-device session was run.

I've set up prototype Security Rules to keep the data in Firestore safe. They are designed to be secure for trusted-only scheduling writes, hospital-scoped staff access, verified veterinarian assignments, protected duration snapshots and unchanged queue authorization. However, you should review and verify them before broadly sharing your app. If you'd like, I can help you harden these rules.

## Exact files changed in this continuation

- `firebase.json`
- `firestore.rules`
- `package.json`
- `functions/package.json`
- `functions/package-lock.json`
- `functions/src/appointment_booking.mjs`
- `functions/src/index.mjs`
- `functions/test/appointment_concurrency.test.mjs`
- `functions/test/callable_transport.test.mjs`
- `lib/features/appointments/data/datasources/appointment_scheduling_datasource.dart`
- `lib/features/appointments/data/repositories/firebase_appointment_repository.dart`
- `lib/features/appointments/data/repositories/firebase_appointment_availability_repository.dart`
- `rules_test/firestore.rules.test.js`
- `scripts/backfill-appointment-schedule.mjs`
- `test/features/appointments/assignment_integration_test.dart`
- `test/features/appointments/appointment_scheduling_datasource_test.dart`
- `test/firestore/appointment_concurrency.test.mjs`
- `test/firestore/appointment_rules.test.mjs`
- `test/firestore/appointment_schedule_backfill.test.mjs`
- `task5-concurrency-audit.md`
- `task5-concurrency-verification.md`
