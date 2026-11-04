# Task 5 final release-readiness audit

Branch: `feature/member1`; reviewed against HEAD `d90f8f0`, including all existing uncommitted Task 5 files. No deployment, commit, push, live booking, production read/migration, or production data modification was performed. This report supersedes the rollout advice in the earlier Task 5 reports.

**Verdict: code is conditionally ready; production release is blocked on the migration and client-compatibility gates below. A deployment sequence alone cannot keep old direct-write clients working while also enforcing trusted-only scheduling.**

## Findings fixed during this audit

1. UTC appointment strings returned by the callable stayed UTC in the Flutter model. Screens render hour/calendar components directly, shifting displayed times relative to the device's local time. Normalize both Timestamp and ISO inputs to local DateTime, preserving the instant. Added regression coverage.
2. The callable accepted the reserved hospital ID `unassigned` if directory, service and account agreed; rules and the assignment repository reject it. Reject this hospital before scheduling writes. Added a matching-record attack test.
3. Doctor read/queue authorization did not reject contradictory directory.vetId or malformed account.vetId consistently with scheduling/Flutter assignment checks. Reuse the account validator and check optional directory.vetId in the hospital predicate. Flutter now also rejects an explicitly null directory.vetId, matching the server/rules (omission remains supported). Added strict denial tests, including malformed account IDs and a contradictory directory ID.
4. Availability omitted previous-day reservations extending past midnight. Include preceding-day starts (the trusted scheduler caps durations at 24 hours), retain intervals ending after the selected midnight, and retain unknown durations conservatively. Added an overnight projection regression. The server already rejected these overlaps.

## Ten release checks

| Check | Assessment |
| --- | --- |
| 1. Creation/reschedule/reassignment | PASS: repository createAppointment, updateAppointment and reassignVeterinarian call the same scheduling data source and reserveAppointmentSlot transaction. Use cases and staff UI/provider delegate to these methods. |
| 2. Client concurrency bypass | PASS under these rules: appointment create is denied; every allowed update predicate restricts changes to notes, status or atomic queue linkage. Slot/service/vet/duration changes cannot be combined with those updates. Mutex writes/reads are denied. Projection writes must equal the canonical appointment and do not authorize canonical scheduling. No offline or failure fallback writes exist. |
| 3. Identity/hospital validation | PASS after fixes: trusted role, directory document ID, optional directory.vetId, active, directory.userId, users.vetId (UID fallback only when null/absent), both hospital IDs. Reassignment additionally requires active hospital_staff/{UID}, matching userId and hospital. Service must belong to that hospital. Missing/malformed links fail closed. |
| 4. Queue/status compatibility | PASS in emulator regressions: confirmed check-in remains an atomic queue/counter/appointment link; exclusive queue rule dispatch is retained. Queued scheduling/reassignment is denied. Pending confirmation/rejection and owner cancellation preserve duration and matching projection. Queue status commands remain unchanged. Cancellation continues to retain existing queue records; no new cancellation workflow is introduced. |
| 5. Callable security | PASS for authorization/concurrency boundary, with residual risks below. Firebase validates bearer token via onCall; server reads role/ownership/assignments inside transaction. Caller cannot set owner, status, duration, queue or creation time. IDs, reason length and trusted duration are validated; date must parse. Known BookingErrors map to HttpsError; unexpected errors return a generic unavailable message and are logged server-side. |
| 6. Region | PASS: function region, Flutter default HTTPS host and emulator transport test all use asia-south2. Project comes from FirebaseAuth.app.options.projectId. Node 22 matches firebase.json and functions/package.json. |
| 7. Existing veterinarian data | CONDITIONAL: safe explicit reconciliation procedure below; not performed on live data. Seed directory records alone are insufficient for booking. |
| 8. Backfill | PASS by code inspection and pure tests: explicit --project required; no writes without --apply; pagination of 200; minimal projection only; malformed page fails; apply rereads each source in a transaction. Repeating produces the same projection contents, preserving duration. Operational safeguards below remain required. |
| 9. Six moderate dependencies | CONFIRMED by fresh functions production audit: six moderate, zero high/critical. Details and acceptance gate below. |
| 10. Safe deployment | BLOCKED until a coordinated upgrade/cutover is available. Old clients cannot be made compatible by reordering these artifacts. Do not leave permissive old rules alongside callable scheduling in a live mixed-writer release. |

## Concurrency and security evidence

The transaction reads canonical appointments, including legacy records without projections, and takes persistent per-veterinarian revision locks before querying/writing. Reassignment locks source and target in sorted order. Two empty queries therefore still contend. Appointments, duration snapshot, availability projection and lock increments commit atomically; conflict/validation failures leave no partial booking. Half-open intervals permit adjacency. Cancelled/rejected intervals release reservations; other statuses occupy them. Status-only writes cannot add a reservation and contend on canonical documents when relevant.

Deletion releases a reservation and is retained under the existing owner policy, only without queue linkage and with projection removal. It cannot introduce an overlap. Admin SDK scripts/IAM identities bypass rules: restrict them operationally and never run legacy appointment writers during cutover or normal operation.

Rules-auditor assessment (Task 5 boundary only, not a whole-project certification):

```json
{"score":4,"summary":"Trusted-only scheduling, immutable client slot fields and verified doctor/staff scope pass regression checks. Operational release gates and resource-abuse risks remain.","findings":[{"check":"Resource Exhaustion/DoS","severity":"minor","issue":"Authenticated callable has no App Check enforcement or per-owner rate limit; transaction scans veterinarian history. Note-only client rule predicates do not bound reason length.","recommendation":"Monitor and budget the endpoint; review App Check/client support and rate limiting separately. Add note limits in a separately tested rules change if required by the release policy."}]}
```

## Existing-account reconciliation procedure (future authorized operation)

1. Export/review users, veterinarian directory, hospital assignments, referenced services and active appointments. Verify real Firebase Auth UID against the provisioned person's identity; never infer identity solely from display name/email similarity. Produce a reviewed mapping manifest: Auth UID -> canonical directory ID -> hospital ID, including expected current values.
2. Require a unique account/directory association, actual hospital, correct veterinarian role, matching hospital in both records, active directory, directory.userId = Auth UID, and optional directory.vetId = document ID. Set users.vetId explicitly for seeded IDs. Preserve UID-keyed legacy records with omitted/null users.vetId only when directory ID equals UID. Inactive/unlinked entries remain unavailable until approved.
3. Do not rename directory documents or bulk rewrite appointment vetId values. Preserve canonical IDs used by appointments. Resolve duplicate mappings, historical cross-hospital assignments, overlaps, invalid timestamps, missing services and uncertain legacy durations manually with the hospital. A doctor moving hospitals requires resolving old active reservations before changing the mapping.
4. Any future apply tool must default to dry-run, require an explicit project and reviewed manifest, reread expected values transactionally, abort on mismatch, update both sides atomically with merge/field updates, skip already-matching pairs, and never invent accounts/roles/active states. Retain backup/audit evidence. There is no automated veterinarian-account reconciliation script in Task 5; do not present the seed script as one.
5. Do not rerun scripts/seed/seed_firestore.mjs as reconciliation: it uses unconditional replacement writes and can erase directory.userId links. It is outside the Task 5 backfill and is not dry-run-first.

## Projection backfill runbook

Commands below are documentation only; neither was run against a live project:

```text
node scripts/backfill-appointment-schedule.mjs --project <reviewed-project-id>
node scripts/backfill-appointment-schedule.mjs --project <reviewed-project-id> --apply
```

Review the complete dry-run result before apply; use least-privilege migration credentials and confirm project/environment. Take a backup and quiesce other trusted migration writers. Apply is per-document transactional, not globally all-or-nothing: an error on a later page can leave earlier projections written. Stop, correct reviewed source data, dry-run again and rerun safely. It does not repair canonical appointments, create duration snapshots for legacy records, detect historical overlaps, or delete orphan projections. Check those separately and compare projection/source counts and IDs after apply. No mutex backfill is needed. Unknown legacy service durations fail closed in scheduling; do not guess historical durations.

## Dependency assessment

Fresh `npm --prefix functions audit --omit=dev --json` returns exit 1 because findings remain, not a clean audit. See task5-release-dependencies.json; functions/package-lock.json pins the assessed tree.

| Package finding | Origin/impact |
| --- | --- |
| minimatch | GHSA-g3hv-75wg-m249: globparts amplification denial of service; affected <11.0.1. |
| glob | GHSA-3g3m-2fjr-6pw4: AbortSignal timeout cancellation bypass during traversal; affected 9 through 14.0.1. Also inherits minimatch. |
| rimraf | Inherits glob/minimatch through filesystem glob dependency. |
| gaxios | Inherits rimraf in nested Firestore API dependency tree. |
| gcp-metadata | Inherits nested gaxios finding. |
| google-gax | Inherits rimraf in nested Firestore API dependency tree. |

These are six affected package nodes arising from two root advisories, not six independent exploit classes. The scheduling handler does not pass user-controlled glob patterns, paths or AbortSignals to these packages; it accepts bounded Firestore IDs and uses Firestore APIs. Installed gaxios/google-gax declare rimraf dependencies, but inspection found no rimraf calls in their built JavaScript. Direct exploitation through this handler was not demonstrated. Residual transitive DoS exposure is assessed as low for this endpoint, not zero or proven unreachable across the SDK. A release owner must record acceptance with a follow-up to upgrade/re-audit and rerun emulator transport/concurrency tests. Do not force incompatible major transitive overrides simply to clear the report. Re-audit at release time because advisory data changes.

References: [glob advisory](https://github.com/advisories/GHSA-3g3m-2fjr-6pw4), [minimatch advisory](https://github.com/advisories/GHSA-g3hv-75wg-m249), [Firebase callable protocol](https://firebase.google.com/docs/functions/callable-reference).

## Deployment order and release checklist

- [x] Trace every application scheduling writer and deny direct client mutations.
- [x] Match callable/client region and runtime configuration.
- [x] Validate concurrency, authorization, queue and projection regressions locally (results below).
- [ ] Review/accept moderate dependencies and endpoint resource-abuse exposure.
- [ ] Verify real account mappings, historical intervals/durations and projection data through the authorized process above.
- [ ] Stage on a non-production Firebase project: install locked dependencies with npm ci at root and functions; deploy index first and wait for readiness, then Functions. Verify runtime service-account Firestore permissions, Node 22, billing/quota and endpoint authentication. Emulators do not prove production index/IAM readiness.
- [ ] Establish a minimum supported app version/controlled distribution or a planned scheduling maintenance cutover. This repository has no demonstrated force-upgrade gate that makes existing installed direct-write clients compatible. If old clients must remain fully functional, release is blocked pending an agreed migration design.
- [ ] For production cutover, quiesce scheduling writers, back up and reconcile reviewed data, deploy indexes and wait, then Functions. Run an authorized staging/smoke process before exposing booking to users. Dry-run/apply/verify projections while writers remain controlled.
- [ ] Distribute the callable-capable mobile build and enforce the supported-version gate. Deploy trusted-only scheduling rules before reopening scheduling. Keep both legacy clients and the new client out of a live mixed-writer interval; callable locks cannot serialize an old direct writer that ignores them. Status/queue clients also need projection-compatible updates after backfill.
- [ ] Reopen only after O11 create, O14 update/cancel, staff reassign/confirm/reject, V01 assigned reads and V05 queue check-in/status pass on Android, including hospital-local/UTC midnight cases. Verify permission denials for unsupported clients and monitor errors/contention.
- [ ] Rollback must retain trusted-only write rules. Disable scheduling or roll forward with a compatible app/function; restoring permissive direct-write rules loses the concurrency guarantee.

Residual limits: tests are local/emulator based; no physical Android, production endpoint, IAM/index readiness or live-data audit was performed. Availability is advisory. Local DateTime display follows device timezone; MVP queue business-day checks explicitly use Asia/Colombo. Server accepts parseable requested timestamps without enforcing hospital opening hours or a future-booking window; those are currently UI policies, not server guarantees. Historical malformed intervals/durations and unbounded doctor history may deny scheduling or increase latency. A lost response may represent a committed booking; refresh before retry. No App Check/rate limiting was added in this audit.

## Validation results

Final command results are recorded after completion below. Initial sandboxed Flutter invocations stalled with empty logs; the Firestore CLI was denied access to its external config, and npm advisory access failed. These are not passing checks; successful reruns use the SDK/CLI outside the sandbox and demo emulators only.

| Command/check | Result | Evidence |
| --- | --- | --- |
| flutter test | 422 passed, exit 0; before the final overnight and explicit-null-directory regression additions | task5-release-flutter-verified.log |
| flutter test test/features/appointments | 11 passed, exit 0 on the final Dart implementation, including both later regressions | task5-release-appointments-final.log |
| flutter analyze | No issues, exit 0 | task5-release-analyze-final.log |
| npm run test:rules | 110 passed, zero failures, exit 0 on final server/rules changes | task5-release-rules.log |
| npm run test:booking | 1 passed, exit 0; real local onCall HTTP transport with Auth/Functions/Firestore emulators | task5-release-callable.log |
| Repository-pinned firebase emulators:exec with npm --prefix rules_test test | 46 passed, exit 0 | task5-release-legacy.log |
| node --test test/firestore/appointment_schedule_backfill.test.mjs | 3 passed, exit 0 | terminal output |
| functions production npm audit | Exit 1; six moderate, zero high/critical | task5-release-dependencies.json |
| Dart formatting, Node source/backfill syntax, git diff --check | Passed | terminal output |

No tests use production credentials/data for writes; emulator tests explicitly use demo-petcare. Projection CLI apply behavior was inspected, not exercised against a live database. The pure backfill tests validate projection privacy, malformed data rejection and duration preservation; CLI pagination/restart idempotency is a code-review conclusion, not an end-to-end migration test claim.

## Exact audit changes

- firestore.rules
- functions/src/appointment_booking.mjs
- functions/test/appointment_concurrency.test.mjs
- lib/features/appointments/data/models/appointment_model.dart
- lib/features/appointments/data/repositories/firebase_appointment_availability_repository.dart
- lib/features/veterinary/data/repositories/firebase_veterinarian_assignment_repository.dart
- test/features/appointments/assignment_integration_test.dart
- task5-release-dependencies.json (fresh audit evidence)
- task5-release-readiness.md (this report)

All earlier Task 5 changes remain uncommitted; complete candidate inventory is recorded below.

## Complete Task 5 candidate file inventory

Paths are relative to the repository root. This includes work present when the audit started plus this audit's changes; logs are ignored local verification artifacts.

```text
firebase.json
firestore.indexes.json
firestore.rules
functions/package.json
functions/package-lock.json
functions/src/index.mjs
functions/src/appointment_booking.mjs
functions/test/appointment_concurrency.test.mjs
functions/test/callable_transport.test.mjs
lib/features/appointments/data/datasources/appointment_scheduling_datasource.dart
lib/features/appointments/data/models/appointment_model.dart
lib/features/appointments/data/repositories/firebase_appointment_availability_repository.dart
lib/features/appointments/data/repositories/firebase_appointment_repository.dart
lib/features/appointments/domain/repositories/appointment_repository.dart
lib/features/hospital_staff/presentation/pages/staff_appointments_page.dart
lib/features/hospital_staff/presentation/pages/staff_shell_page.dart
lib/features/hospital_staff/presentation/providers/staff_appointment_provider.dart
lib/features/veterinary/data/repositories/firebase_veterinarian_assignment_repository.dart
lib/features/veterinary/data/repositories/firebase_veterinarian_repository.dart
lib/features/veterinary/domain/repositories/veterinarian_assignment_repository.dart
lib/features/veterinary/domain/usecases/get_current_veterinarian_assignment.dart
lib/features/veterinary/presentation/pages/veterinarian_dashboard_page.dart
package.json
rules_test/firestore.rules.test.js
scripts/backfill-appointment-schedule.mjs
test/features/appointments/assignment_integration_test.dart
test/features/appointments/appointment_scheduling_datasource_test.dart
test/features/hospital_staff/presentation/pages/staff_shell_page_test.dart
test/firestore/appointment_concurrency.test.mjs
test/firestore/appointment_rules.test.mjs
test/firestore/appointment_schedule_backfill.test.mjs
test/firestore/queue_rules.test.mjs
task5-audit.md
task5-verification.md
task5-concurrency-audit.md
task5-concurrency-verification.md
task5-concurrency-dependencies.json
task5-release-dependencies.json
task5-release-readiness.md
```

Recommended commit message for the full Task 5 change:

```text
feat(appointments): enforce trusted concurrent scheduling and verified vet assignments
```
