# Task 5 ? Staff-to-veterinarian appointment integration

Branch: `feature/member1`. Initial working tree was clean. No commit, push, merge, deployment, or production data write was performed.

## Root causes

1. Appointment rules authorized veterinarians by hospital alone, allowing a doctor to read and decide another doctor's appointments. The dashboard already queried hospitalId + vetId, but the rules did not enforce vetId.
2. Hospital authorization assumed directory IDs equaled authentication UIDs, whereas seeded directory doctors have separate IDs and the dashboard consumed users.vetId. Hospital membership was not cross-checked against directory.userId, active, and directory.hospitalId.
3. Owner booking and reassignment did not validate active, same-hospital directory membership in rules. A doctor could mutate active/vetId in their own directory record.
4. Availability queried private appointments with only vetId, which owner read rules could not authorize. See Firebase's [query authorization documentation](https://firebase.google.com/docs/firestore/security/rules-query).
5. Appointment deserialization required ISO strings and embedded appointmentId, while emulator/legacy records use Firestore timestamps and may rely on document IDs. Owner detail updates also lacked updatedAt server timestamps.
6. The staff appointments tab retained stale data when revisited.

## Resulting integration behavior

- Staff access still originates exclusively from hospital_staff/{auth UID}, requiring matching userId, hospitalId, active and veterinary_staff role. The existing access gate and queue management implementation remain in use.
- Doctor identity resolves from the authenticated user's trusted users.vetId (or legacy UID when absent), directory.userId, both hospitalId values, role and active directory state. Dashboard refresh rereads this relationship.
- O11 booking validates the selected service and directory doctor, rechecks projected availability, and atomically writes the appointment plus a minimal appointment_schedule projection. Rules independently require an active directory target and the matching provisioned veterinarian account.
- Hospital A staff can list and confirm Hospital A appointments. Doctor A queries only hospitalId A + vetId A; Doctor B cannot read or decide A's appointment, even at the same hospital. Cross-hospital staff access remains denied.
- Staff can change the doctor on pending/confirmed appointments through a hospital-scoped selection dialog. The repository checks service-duration overlaps and uses a transaction to reject concurrent changes to the selected appointment's scheduling fields. Rules independently reject inactive, missing, mismatched-account and cross-hospital targets. Reassignment changes vetId and its projection atomically; each doctor's next refresh reflects the transfer.
- Once queueId is linked, scheduling/reassignment is blocked. Queue identity fields and record lifecycle remain protected. Appointment status operations do not write queue records. The exclusive queue-link authorization dispatch that avoids the 1,000-expression limit is retained.
- Staff tab return refreshes appointment data; existing pull-to-refresh remains. Doctor dashboard layout and navigation were preserved; its large text diff includes Dart formatter changes.
- Read models accept ISO dates and Firestore Timestamp, and appointment/veterinarian repositories use canonical document IDs.
- Added an explicit appointments hospitalId+vetId composite index. It is not deployed; emulator tests do not validate production index readiness.

## Verification

| Check | Final result | Evidence |
| --- | --- | --- |
| dart format (14 changed Dart files) | Exit 0 | Formatted 14 files; final formatting run changed 3 |
| flutter analyze | Exit 0; no issues | task5-analysis-verified.log |
| flutter test | Exit 0; 417 passed | task5-flutter-final.log |
| npm.cmd run test:rules | Exit 0; 89 passed, 0 failed | task5-rules-verified.log |
| firebase.cmd emulators:exec --only firestore --project demo-petcare "npm.cmd --prefix rules_test test" | Exit 0; 46 passed | task5-legacy.log |
| node --test test/firestore/appointment_schedule_backfill.test.mjs | Exit 0; 2 passed | Terminal output |
| git diff --check | Exit 0 | Terminal output |

The security assertion helpers reject expression-limit, access-limit, undefined-property, null-value and invalid-path errors; a denial caused by those errors does not count as a passing security test. New tests cover real matching-projection bookings with invalid targets, doctor-specific list/get/update permissions, reassignment view changes, directory lockdown, queued scheduling rejection, projected queue linkage, and independent pet-health writes. Existing booking-slot, staff appointment, queue and legacy security tests were included.

Firebase prints expected denial logs and Node deprecation warnings on stderr. Final emulator invocations explicitly propagate the native exit code (`exit $LASTEXITCODE`) so PowerShell warning handling does not misreport success as failure.

The first Flutter run found the old staff-tab read-count expectation; the updated test accounts for the intentional refresh. Rules tests initially exposed unsafe missing-directory/query-field handling; these were corrected rather than weakening assertion helpers. Legacy fixtures were updated from veterinarianId/appointmentDate/isActive to the actual vetId/dateTime/active schema and atomic booking projection.

## Residual risks and rollout dependencies

- Conflict checks use service durations and recheck before writes, but concurrent bookings/reassignments affecting different appointment documents are not globally serialized. A trusted booking transaction service or reservation ledger is still required to guarantee race-free no-overlap enforcement. Security rules do not currently enforce global schedule uniqueness.
- Existing appointments have no availability projection. Before a future rollout, review and backfill them with `node scripts/backfill-appointment-schedule.mjs --project <project-id>` (read-only dry run), then deliberately use `--apply` only after review. The script was tested locally but has not been run against production. It copies only vetId/hospitalId/serviceId/dateTime/status and rereads each source transactionally when applying.
- Seeded doctor discovery records need trusted account provisioning: directory.userId must identify a users document with role veterinarian, matching hospitalId and matching vetId; legacy UID-keyed records can omit users.vetId. Booking/confirmation/reassignment fails closed for unlinked or inactive doctors. No production provisioning was changed.
- App/rules/index/backfill rollout must be coordinated. Older clients do not write the required projection for new bookings, and cannot change projected appointment scheduling/status without synchronizing it. Legacy appointments remain operable until projected.
- Existing owner cancellation behavior retains queue records; this change prevents scheduling edits and deletion from breaking queue linkage but does not add a new queue cancellation workflow.
- Verified with Flutter tests and local Firestore emulators; no Android-device or production end-to-end session was performed.

I've set up prototype Security Rules to keep the data in Firestore safe. They are designed to be secure for trusted hospital assignments, verified doctor identities, same-hospital assignment and doctor-specific appointment access. However, you should review and verify them before broadly sharing your app. If you'd like, I can help you harden these rules.

## Changed files

- `firestore.indexes.json`
- `firestore.rules`
- `lib/features/appointments/data/models/appointment_model.dart`
- `lib/features/appointments/data/repositories/firebase_appointment_availability_repository.dart`
- `lib/features/appointments/data/repositories/firebase_appointment_repository.dart`
- `lib/features/appointments/domain/repositories/appointment_repository.dart`
- `lib/features/hospital_staff/presentation/pages/staff_appointments_page.dart`
- `lib/features/hospital_staff/presentation/pages/staff_shell_page.dart`
- `lib/features/hospital_staff/presentation/providers/staff_appointment_provider.dart`
- `lib/features/veterinary/data/repositories/firebase_veterinarian_assignment_repository.dart`
- `lib/features/veterinary/data/repositories/firebase_veterinarian_repository.dart`
- `lib/features/veterinary/domain/repositories/veterinarian_assignment_repository.dart`
- `lib/features/veterinary/domain/usecases/get_current_veterinarian_assignment.dart`
- `lib/features/veterinary/presentation/pages/veterinarian_dashboard_page.dart`
- `rules_test/firestore.rules.test.js`
- `scripts/backfill-appointment-schedule.mjs`
- `task5-audit.md`
- `task5-verification.md`
- `test/features/appointments/assignment_integration_test.dart`
- `test/features/hospital_staff/presentation/pages/staff_shell_page_test.dart`
- `test/firestore/appointment_rules.test.mjs`
- `test/firestore/appointment_schedule_backfill.test.mjs`
- `test/firestore/queue_rules.test.mjs`
