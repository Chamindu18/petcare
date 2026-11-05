# P0 integration stabilization — 2026-11-05

Branch: feature/member1. No production deployment, billing change, migration,
commit, push, merge, reset, or patient-data write performed.

## Current cloud evidence

Read-only checks at 13:34–13:35 UTC are saved in task6-live-readiness.json and
p0-cloud-readiness.json. Firestore is STANDARD / FIRESTORE_NATIVE in asia-south2.
Cloud Functions API is ENABLED; global and regional function listings succeed
and return no functions. Billing API reports billingEnabled=false. Thus the
previous SERVICE_DISABLED-style 403 has cleared; current listing is not blocked
by IAM, service unavailability or tooling. Historical logs identify API-disabled
response wording, but do not establish when or by whom the API was enabled.
Deploy IAM, runtime IAM and build-service readiness remain unverified; successful
listing does not establish deployment privileges. Billing is a release blocker.
Sandbox EPERM credential-file errors and the Node punycode warning are separate
local tooling issues, not explanations for the historical server response.

Deployed Firestore release remains November 2, hash
2a05ad9ba461abb8d9a042d0af5784f0ac9438b36d5c6466499078cba56146d2.
Intended local rules hash is
c97b729189ac450c50aa13e3a7a2fc141bb2700ed3e62bf5371ffa97bcc26a33.
Seven of eight declared indexes match READY indexes; the declared
appointments(hospitalId ASC, vetId ASC) index does not.

The intended firebase.json references firestore.rules, firestore.indexes.json
and the appointments Functions codebase. Local rules already resolve users.vetId,
validate active directory/back-reference/hospital, and restrict doctor reads to
assigned appointments. Staff reads require active hospital assignment; owner
reads require ownerId. Scheduling is callable-only, with direct creates denied.
Do not substitute the read-only dashboard patch for the complete cutover rules.

The app derives its callable project from FirebaseAuth options and uses
asia-south2 / reserveAppointmentSlot. Dart options, Android services JSON and
.firebaserc agree on petcare-d4413; Functions region is asia-south2, Node 22.

## Legacy compatibility

Four appointments: one rejected, three confirmed. All dates parse, referenced
services belong to the appointment hospital, none has a queue link. All four
lack duration snapshots and schedule projections. Current service durations are
30, 30, 30, 60 minutes, respectively; these are not verified historical values.
No missing references or invalid pet ownership was detected.

The scheduler checks canonical legacy appointments, falling back to current
service duration when no snapshot exists. This fallback can be historically
inaccurate: review durations and active overlaps before reopening scheduling.
Rejected appointments do not occupy reservations. The existing projection
backfill does not invent duration snapshots or repair canonical appointments.
Review exact minimal projections for all four records, including terminal status,
and verify source/projection identity after an authorized apply. Keep writers
quiescent and retain a backup. No apply was performed.

One doctor identity remains valid; 54 other active directory entries lack userId
and remain ineligible. Do not bulk-link them or rerun the seed script. One active
staff assignment is valid. Demonstrate only provisioned, verified accounts.

## Minimum complete cutover (requires separate production authorization)

1. Authorize project billing configuration and confirm deployment/build/runtime
   permissions, quotas and required services. API enablement alone is insufficient.
2. Inventory installed clients; close scheduling to all writers during cutover.
   Back up and approve legacy durations/overlaps/projections and account mappings.
3. Deploy reviewed indexes; wait for READY. Deploy the appointments codebase with
   reserveAppointmentSlot in asia-south2; verify authenticated callable behavior,
   runtime Firestore access and denial behavior on an isolated test environment.
4. Apply only reviewed legacy changes with separately authorized credentials;
   verify projections and canonical values. No blanket seed or guessed durations.
5. Distribute the callable-compatible APK to every demo participant, removing old
   direct writers from use. Activate reviewed full compatible Firestore rules
   before reopening scheduling. No permissive mixed-writer interval is safe.
6. Test owner booking, staff confirmation/reassignment, assigned doctor refresh,
   today's staff check-in and queue lifecycle on synthetic fixtures. Keep real
   patient records unchanged. Reopen only after these checks pass.
7. Rollback by disabling scheduling or rolling forward; never restore direct-write
   rules to make old clients work. Preserve existing unrelated feature contracts.

## Demonstration boundary and Android checks

ADB devices returned an empty list in this execution. Existing verified ARM64 APK
can be used when a compatible device is connected; no rebuild is required by this
task because application source is unchanged.

Backend cross-role integration is demonstrable in emulators. Shared-project
Android integration is not ready: no callable, disabled billing, stale rules,
missing index readiness and unprepared legacy projections block release.
Staff queue UI exists; owner live-queue UI does not. Doctor appointment cards and
quick actions are not a consultation workflow. Do not claim owner live tracking
or doctor queue management from backend tests. New feature work is outside this task.

Remaining device cases on synthetic records: owner create/conflict/cancel and
refresh; staff decision/reassignment; previous doctor loses read access/new doctor
gains it; foreign owner/staff/doctor denials; same-day check-in and duplicate-tap
protection; waiting -> in_consultation -> completed; Colombo date boundaries;
offline/timeout recovery with refresh before retry; logout clears prior-role data.

## Changes and validation

Added GET-only diagnostic scripts/verify-p0-cloud-readiness.cjs and its redacted
JSON output; refreshed the existing readiness JSON; added this runbook. No app,
Functions handler or security-rules source defect was demonstrated requiring a fix.
Fresh validation (all exit 0):

| Check | Result | Evidence |
|---|---|---|
| Authenticated callable and cross-role emulator transport | 2 passed | p0-booking.log |
| Rules, scheduling concurrency and queue authorization | 111 passed, 0 skipped | p0-rules.log |
| Flutter appointments and hospital staff regressions | 101 passed | p0-flutter-approved.log |
| Pure projection-planning regressions | 3 passed | terminal TAP |
| Diagnostic Node syntax and git diff --check | Passed | terminal output |

The initial sandboxed booking attempt failed reading CLI credentials; the
outside-sandbox rerun passed. The sandboxed Flutter invocation produced no
useful verification; the completed outside-sandbox run above is the evidence.
Project-wide Flutter/legacy suites were not repeated because no application or
rules source changed. Prior complete results remain in the final repair report.

Minimum next action: obtain specific authorization for billing activation and a
reviewed coordinated release/data-preparation plan. In parallel connect an ARM64
device and prepare synthetic test accounts/fixtures in an isolated environment.
Do not spend another cycle repairing the already-valid doctor link.
