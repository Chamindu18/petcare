# V01 veterinarian dashboard investigation and remediation

## Confirmed root cause

Read-only checks against `petcare-d4413/(default)` found one veterinarian user profile. Its Auth account exists, its explicit `vetId` identifies an active directory document with a different ID from the Auth UID, and its hospital exists, is active, and matches. However, the directory document has no `userId`.

`FirebaseVeterinarianAssignmentRepository.getCurrentAssignment()` therefore returns null at `data['userId'] != uid`. The original dashboard then throws `StateError('Your active veterinarian assignment could not be verified.')` before either hospital or appointment loading starts. There is no Firebase exception code for that application-level identity rejection. This conclusion follows the current source and actual live records; no Android runtime exception was captured.

A second confirmed defect was masked by that first failure: all 55 live directory records store `experienceYears` as a string. The original `(map['experienceYears'] as num?)` cast throws a TypeError once a linked record is parsed. The model now supports finite, nonnegative numeric strings and numbers; malformed optional display fields have safe fallbacks. Required identity, hospital and active checks remain strict.

## Local fixes

- Keep the trusted explicit directory assignment; never substitute a name/email lookup or assume the directory ID equals Auth UID.
- Recheck Auth UID after assignment reads, and log safe assignment reason codes without document identifiers.
- Classify dashboard errors by operation and Firebase code, separately identifying identity, permission, precondition, network and parsing failures. End-user messages contain no technical identifiers.
- Load appointments with both canonical `vetId` and `hospitalId`, as before. Hospital display failures can show a warning while retaining the authorized schedule; hospital authorization failures remain blocking.
- Reset data on refresh/profile change/sign-out. Generation guards discard stale asynchronous responses; auth changes immediately clear cached dashboard state.
- Convert display dates, day grouping and greetings to Sri Lanka UTC+05:30 independently of the device timezone. Timestamp/ISO parsing remains in the existing appointment model.
- Use the hospital document path as its canonical ID.
- Add 12 dashboard/assignment/query regression tests, including retry, doctor switching, malformed legacy fields, zero appointments and Sri Lanka clock display. Existing emulator tests exercise actual cross-doctor denials and staff/queue workflows.

## Live environment evidence

See `veterinarian-dashboard-live-readiness.json` for timestamped aggregate checks. No personal values or credentials are included.

- Database: STANDARD, FIRESTORE_NATIVE, `asia-south2`; project/default database match Android and local Firebase configuration.
- All 55 directory documents lack `userId`; the sole veterinarian account fails that specific link check.
- All 55 `experienceYears` values are strings.
- Deployed rules differ from local rules. The deployed appointment read predicate allows hospital-scoped veterinary access; local rules require a verified directory assignment and doctor-specific appointment scope.
- The declared `appointments(hospitalId ASC, vetId ASC)` composite index is absent/not READY. However, a live read-only `runQuery` with both equality filters succeeds and returns a matching appointment under CLI IAM authorization. Therefore the missing declared index is NOT a confirmed cause for this query. IAM reads do not verify mobile security-rule authorization.
- Cloud Functions listing returns HTTP 403 SERVICE_DISABLED (API disabled/not previously used). This is a booking/reassignment readiness issue, not a dashboard read dependency.
- Four appointments lack schedule projections and duration snapshots. This affects scheduling readiness, not this initial dashboard failure.
- ADB reports no connected devices. No Android install, login, logcat capture or authenticated mobile production query was performed.

## Exact remaining administrator/release procedure (NOT executed)

1. Identify the existing veterinarian profile by its trusted Auth UID in Firebase Console. Read its existing explicit `vetId` and `hospitalId`; do not publish them in reports. Confirm the identity-to-directory relationship with the authorized hospital provisioning record. Names/email alone are insufficient evidence.
2. Prepare a reviewed mapping row with columns `authUid`, `profileVetId`, `directoryDocumentId`, `profileHospitalId`, `directoryHospitalId`, `directoryUserIdBefore`, `directoryUserIdAfter`, `active`, and `approvalEvidence`. For this account, the two directory IDs must equal the existing profile `vetId`; both hospitals must match. `directoryUserIdAfter` must be the verified Auth UID. Do not link the other 54 directory entries without their own approved evidence.
3. After explicit production-change approval, a trusted administrator should apply that single `userId` back-reference using an Admin SDK transaction: reread the user/directory/hospital, assert unchanged profile role/IDs, active directory/hospital, and absent-or-already-matching `userId`; abort on conflicts. Update only `userId`, preserve other fields, record an administrative audit entry, and reread to confirm. No client-side provisioning bypass or migration was added.
4. Ship the local Flutter fix; adding the link alone leaves the old Android build vulnerable to the confirmed string-to-number TypeError.
5. After review and explicit deployment approval, deploy the local doctor-scoped rules with `firebase deploy --only firestore:rules --project petcare-d4413`. Local emulator success does not change deployed rules. Review the full existing local rules diff because it also contains prior shared appointment changes.
6. For index parity, after approval run `firebase deploy --only firestore:indexes --project petcare-d4413` and wait for the appointment index to become READY. The current equality query already works under IAM; do not report this as its observed root cause.
7. For booking/reassignment readiness separately: enable the Cloud Functions API and required billing/services through the authorized admin process, deploy reviewed appointment functions to `asia-south2`, then reconcile the four legacy schedule projections/duration snapshots under a separately approved plan. No live migration or deployment was run.
8. Install the updated app on Android, log in as the reconciled doctor, and verify V01, zero/nonzero appointments, local clock display, pull-to-refresh, Retry, and logout/login as another approved doctor. Confirm another doctor's appointment is denied under deployed rules. Until these checks succeed, the live dashboard is NOT verified fixed.

## Files changed by this investigation

- `lib/features/veterinary/presentation/pages/veterinarian_dashboard_page.dart`
- `lib/features/veterinary/data/repositories/firebase_veterinarian_assignment_repository.dart`
- `lib/features/veterinary/data/models/veterinarian_model.dart`
- `lib/features/hospitals/data/repositories/firebase_hospital_repository.dart`
- `test/features/veterinary/veterinarian_dashboard_test.dart`
- `scripts/verify-veterinarian-dashboard.cjs`
- `docs/veterinarian-dashboard-live-readiness.json`
- `docs/veterinarian-dashboard-investigation.md`

Pre-existing uncommitted functions, package, appointment-test, and task6 audit files were preserved. No commits, pushes, deployments, or production data mutations were performed.

## Verification

Final counts are recorded below after completion. Emulator results are separate from the read-only production audit.

| Check | Passed | Failed |
|---|---:|---:|
| Full `flutter test` (final run, including 12 new dashboard regressions) | 437 | 0 |
| Dashboard targeted suite | 12 | 0 |
| `npm run test:rules` | 111 | 0 |
| `npm run test:legacy` | 46 | 0 |
| `npm run test:booking` | 2 | 0 |

`flutter analyze`: no issues. `dart format`: all five changed Dart files formatted. `git diff --check`: clean. All Node test suites reported zero skipped tests. Earlier intermediate Flutter runs found only new test setup issues (an off-screen lazy-list finder and an incompatible anonymous-auth mock); both were corrected before the passing final run. Logs: `vet-dashboard-flutter-verified.log`, `vet-dashboard-targeted.log`, `vet-dashboard-analysis-final.log`, `vet-dashboard-rules.log`, `vet-dashboard-legacy.log`, `vet-dashboard-booking.log`.

Live status: blocked by missing trusted account-directory link; local model fix must also ship. Production mobile loading is not verified fixed. No device is connected. The exact equality query succeeds under IAM, but doctor-specific mobile authorization must be smoke-tested after approved reconciliation and rules deployment.
