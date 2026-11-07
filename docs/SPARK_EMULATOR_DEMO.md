# Spark booking demonstration

The Spark project does not host `reserveAppointmentSlot`. Full appointment booking, atomic slot reservation, rescheduling, and reassignment require the local Functions, Auth, and Firestore emulators. Do not deploy functions, enable billing, or replace the callable with direct client appointment writes.

1. Start `npm.cmd run demo:emulators` from the repository root.
2. Seed synthetic demo data with `npm.cmd run demo:seed` in another terminal.
3. Launch the Android app with `flutter run --dart-define=USE_FIREBASE_EMULATORS=true`. The Android emulator uses `10.0.2.2` for the host. For a physical device with `adb reverse`, add `--dart-define=FIREBASE_EMULATOR_HOST=127.0.0.1`.

The picker reads each hospital's stored `hours` field and the privacy-preserving `appointment_schedule` projection. Bare time ranges apply daily; `Monday - Saturday, 8 AM - 6 PM` style ranges close the other day. Unsupported or missing schedules fail closed. Appointment times are interpreted in Sri Lanka hospital time (UTC+05:30). No veterinarian workday or break schema exists yet, so the app uses active hospital assignment and hospital hours; the team must provision reliable schedule data before promising veterinarian-specific shifts or breaks.

The projection is advisory. The callable uses a veterinarian transaction lock and canonical appointment overlap checks. Cancellation and rejection atomically change the canonical status and projection, releasing the interval; a concurrent booking may then reserve it. Existing longer appointments retain their snapshotted duration and block every overlapping 15-minute start. Notifications are written with successful booking transactions.
