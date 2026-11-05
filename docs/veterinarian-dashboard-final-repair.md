# V01 final repair verification — 2026-11-05

Branch: `feature/member1`. Firebase project: `petcare-d4413`.

## Identity correction

The guarded live dry run confirms `veterinarians/vet_001.userId` already equals
the enabled Auth account referenced by the sole veterinarian profile. The profile
still explicitly references `vet_001` and `hospital_001`; directory and hospital
are active. No conflicting profile or directory claims exist. Names and emails
were not used. No production write was needed or performed in this execution.

The existing git-ignored receipt records a successful single-field commit and
reread at `2026-11-05T01:09:35.839Z`. The current dry run was checked at
`2026-11-05T01:29:36.152Z`. Its identity mapping matches the previous plan; its
version digest differs, so the old absent-field baseline must not be reused for
a write. Current assignment predicates all pass. Account identifiers and local
receipt contents are intentionally omitted here.

The guarded script was also run in authorized apply mode against the refreshed
plan and returned `Already linked; verified, no write.` (exit 0). No receipt was
overwritten and no production document was mutated.

## Confirmed remaining authorization blocker

Read-only audit at `2026-11-05T01:30:30.487Z` retrieved the current deployed rules
release, last updated `2026-11-02T15:27:48.859892Z`. Its
`isVeterinarianForHospital` looks up `veterinarians/$(request.auth.uid)`.
The doctor's trusted directory ID differs from the UID. The appointment read
predicate calls `isVeterinaryUserForHospital(resource.data.hospitalId)`, which
therefore cannot authorize this doctor. Directory/hospital reads themselves are
available to authenticated users.

The exact deployed rules were loaded into the Firestore emulator. A synthetic
account with the verified relationship shape successfully reads directory and
hospital but is denied the same hospital+vet appointment query. This reproduces
the production rule defect without manufacturing a production login/token.

The real scoped production appointment query succeeds under CLI IAM and returns
an appointment. This does **not** verify authenticated doctor access. The declared
composite index remains absent/not READY, but no query index failure was observed.

## Minimal review artifact — NOT deployed

`scripts/prepare-veterinarian-rules-patch.cjs` only fetches the deployed rules and
generates a candidate in git-ignored `build/veterinarian-rules-review/`. It saves
the release and source/candidate hashes in `metadata.json`. It performs no data
writes or deployments. The readable diff is
`docs/veterinarian-dashboard-rules.patch`.

The prototype adds one appointment-read helper checking role, explicit profile
directory ID (or UID fallback), active directory, matching userId back-reference,
canonical directory ID, matching profile/directory/appointment hospital, and
appointment vetId. Only the appointment read predicate uses it. It replaces the
doctor hospital-wide read branch with doctor-specific reads while retaining the
existing staff branch and owner branch. The original hospital/service/queue
helpers and all write predicates are untouched. In particular this patch does
not enable consultation/queue mutations for the newly linked directory account.

Review effects before a separate rules release: UID-keyed doctors must also have
valid active back-references and matching profile hospital; hospital-wide doctor
appointment reads become denied. Owner and Staff appointment access and Queue
rules retain their deployed predicates. Existing unrelated deployed-rule write
validation weaknesses are outside this narrow patch and are not certified safe.

`test/firestore/veterinarian_dashboard_release.test.mjs` validates both exact
deployed source and candidate. It reproduces baseline denial, verifies candidate
query and refresh, denies another doctor's and another hospital's appointments,
denies hospital-only queries, denies self-reassignment, and rejects inactive,
wrong-user, wrong-hospital, and wrong-canonical-ID assignments. Owner/Staff
appointment and Queue read checks pass. Unauthenticated appointment listing fails.

To regenerate and run the focused emulator check (no deployment):

```powershell
node scripts/prepare-veterinarian-rules-patch.cjs
node node_modules/firebase-tools/lib/bin/firebase.js emulators:exec --only firestore --project demo-petcare "node --test test/firestore/veterinarian_dashboard_release.test.mjs"
```

Release procedure: review this diff against the recorded deployed ruleset; fetch
again and stop if the deployed source has changed; use the generated candidate
in an isolated Firebase rules configuration for a separately authorized rules
release. Do not deploy the workspace's complete `firestore.rules` as part of this
repair. Re-run emulator checks against the reviewed candidate before release.

## Regression results

| Check | Result | Log |
|---|---|---|
| `flutter analyze` | No issues | `final-vet-analysis-verified.log` |
| `flutter test` | 437 passed | `final-vet-flutter-verified.log` |
| `npm run test:rules` | 111 passed | `final-vet-rules.log` |
| `npm run test:legacy` | 46 passed | `final-vet-legacy.log` |
| `npm run test:booking` | 2 passed on retry | `final-vet-booking-retry.log` |
| Repair safeguard tests | 8 passed | terminal TAP output |
| Deployed/candidate dashboard rules | 2 passed | `final-vet-release-rules.log` |
| `git diff --check` | Clean | terminal output |

The initial callable run failed because function discovery exceeded 10 seconds;
the successful retry used `FUNCTIONS_DISCOVERY_TIMEOUT=60` and
`METADATA_SERVER_DETECTION=none` for the local emulator process only. No app or
backend source was changed to address that tooling issue.

These tests cover local Owner, Staff, Appointment, and Queue regressions. They
cannot establish live end-to-end correctness on Android.

## Android verification

ADB returned an empty device list on repeated checks. No install, login,
dashboard refresh, or sanitized device log capture is claimed. Application data
has not been cleared. Existing legacy model parsing, strict assignment, dashboard,
and hospital fixes are preserved unchanged.

The normal fresh Flutter APK build stalled in remote dependency downloads; a
thread dump confirmed SSL download reads and zero-byte Gradle temporary files.
It was interrupted without deleting caches or project files. An offline Gradle
debug build failed because ARMv7 and x86_64 engine JARs were not cached. A fresh
ARM64-only offline debug build was then started using the cached ARM64 engine;
it **succeeded** in 1m 6s (400 tasks; 59 executed). No persistent Gradle or SDK
configuration was changed. Log: `final-vet-build-arm64.log`.

Fresh APK: `build/verified/final-veterinarian-dashboard-arm64-debug.apk`,
129901203 bytes; SHA-256
`dd49d3e5c793e0d5334ca97d92e9f21ae07807cbe925c9ac1c6772964e540c1c`.
Its only Flutter engine ABI is `arm64-v8a`. Direct ZIP/kernel inspection confirmed
the exact current source bytes of the legacy veterinarian model, assignment
repository, dashboard page, and hospital repository are embedded. Evidence:
`build/final-veterinarian-apk-evidence.json`. This is a fresh build, not the old
preserved APK. Installation still requires a connected compatible device.

## Changes in this execution

- Added read-only deployed-rules fetch/candidate generator:
  `scripts/prepare-veterinarian-rules-patch.cjs`.
- Added focused baseline/candidate authorization emulator test:
  `test/firestore/veterinarian_dashboard_release.test.mjs`.
- Added review-only rules diff: `docs/veterinarian-dashboard-rules.patch`.
- Added this redacted report and refreshed the existing read-only live-readiness
  report. Build artifacts, operator metadata, and logs remain local/ignored.
- No Flutter application, Functions, or active Firestore rules source was changed
  in this execution. Existing worktree changes were preserved.

No production rules/Functions deployment, billing/API change, data migration,
commit, push, merge, or unrelated teammate edit was performed.
