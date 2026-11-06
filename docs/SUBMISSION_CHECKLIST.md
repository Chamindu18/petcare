# PetCare+ submission checklist

Prepared 2026-11-06 from `feature/member1` commit `fc65f0574922fcfd700c91f4c9c7daa565c0c234`. The repository had a clean working tree before these documentation updates. No commit, push, merge, deployment, or device run was made during preparation.

## Ready to collect

- [x] Source commit for final build: `fc65f0574922fcfd700c91f4c9c7daa565c0c234` (UI cleanup). It is on `feature/member1`; submit the repository link with this commit identified. The branch has not been merged into protected `main`.
- [x] Android debug APK: `build/app/outputs/flutter-apk/app-debug.apk`, 203,217,069 bytes, SHA-256 `552BC2E2617373F8AE7204F2F3F5CFE38D26B0F453FE29252E636864FD4D110D`. Built with `flutter build apk --debug` on this commit, using the existing default-off emulator configuration. This APK is not independently functional for booking against shared Spark Firebase.
- [x] Current analyzer: `flutter analyze` on this commit, 2026-11-06, no issues. Existing integrated-main evidence: `docs/PETCARE_POST_MERGE_VERIFICATION.md` and `docs/SPARK_EMULATOR_DEMO.md`.
- [x] Existing automated tests (earlier integrated commits): 459 Flutter tests, 111 Firestore rules tests, 46 legacy rules tests, and 2 emulator booking/cross-role integration tests. See the two reports above; raw evidence includes `task6-rules-final.log`, `task6-legacy.log`, and `task6-callable-final.log`. These suites were not rerun after the UI cleanup, so their results must be labeled by the verified commit/date in the reports.
- [x] Project overview, architecture, feature structure, and team workstreams: `README.md`. Detailed integration and limitations: `docs/task6-system-integration-report.md` and `docs/PETCARE_SUBMISSION_READINESS.md`. The latter is an earlier audit and contains findings that the UI cleanup subsequently addressed; use its implementation summary with that date caveat.
- [x] Firebase emulator startup, seed, synthetic accounts, demonstration sequence, and screenshot list: `docs/SPARK_EMULATOR_DEMO.md`. Run `npm run demo:emulators`, then `npm run demo:seed` in a second terminal. The seed resets only the local `demo-petcare` namespace.

## Demonstration accounts

All use password `PetCareDemo!2026` in the synthetic local emulator environment: `owner.demo@petcare.test`, `staff.demo@petcare.test`, `vet.a.demo@petcare.test`, and `vet.b.demo@petcare.test`. Do not use these as shared Firebase accounts. See the demo guide for the emulator flag and host address.

## Still needed from the team

- [ ] Capture Android screenshots of login, owner home, pet health/analytics, hospital/service/vet selection, booking confirmation, and owner appointment list.
- [ ] Capture cross-role screenshots of staff confirmation/rejection/reassignment, veterinarian assignment visibility, staff queue transitions, adoption provider request decision, and owner adoption/notification views. `artifacts/demo-smoke/owner-home.png` is the only existing screenshot in the repository; it shows the synthetic Demo Owner and Milo Demo on the owner dashboard.
- [ ] Capture emulator UI synthetic accounts and the existing test/build summaries for the presentation. Android interaction and installation remain unverified by this preparation task.
- [ ] Add the final academic report, original Team Work Plan, and approved screen specifications if required by the course; these documents are absent from the repository. Match team contribution names and claims to the actual work plan and Git/PR history.
- [ ] Decide with the course team/supervisor how to disclose incomplete MVP features in the report and demo. QR Health Passport/scanner, owner live queue, live AI integration, automated reminders, owner rehoming, and full veterinarian consultation/queue controls are incomplete. Shared Spark-hosted booking is unavailable because the appointment callable is not deployed; the supported booking demonstration uses local emulators.
- [ ] Provide the final repository URL/commit and APK to the submission channel after the team has reviewed these files. Documentation edits in this working tree remain uncommitted under the no-commit instruction.

## Next action

Run the documented synthetic-account Android emulator demonstration and capture the missing screenshots, then place them with the final report. No emulator or device was started during this preparation task.
