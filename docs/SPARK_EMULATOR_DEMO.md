# PetCare+ secure Spark-compatible academic demo

This demo uses the existing callable appointment scheduler only in the Firebase
Local Emulator Suite. It never deploys Functions and never writes to
`petcare-d4413`.

## Prerequisites

- Node.js 22
- Java 21 or a compatible Firebase Emulator Suite Java runtime
- Flutter with the Android SDK configured
- Firebase CLI dependencies installed with `npm install`
- Function dependencies installed with `npm --prefix functions install`

## Start on Windows

Open PowerShell in `D:\projects\petcare`.

Terminal 1:

```powershell
npm run demo:emulators
```

Wait for Auth `9099`, Firestore `8080`, Functions `5001`, and Emulator UI
`4000` to report ready. Keep this terminal open.

Terminal 2:

```powershell
npm run demo:seed
```

The seed command deliberately resets only the local `demo-petcare` emulator
namespace, then creates the same synthetic fixtures every time.

## Synthetic accounts

All accounts use password `PetCareDemo!2026`.

| Role | Email |
| --- | --- |
| Owner | `owner.demo@petcare.test` |
| Staff | `staff.demo@petcare.test` |
| Veterinarian A | `vet.a.demo@petcare.test` |
| Veterinarian B | `vet.b.demo@petcare.test` |

The fixtures also create one active hospital, two services, two verified
veterinarian assignments, one pet, one confirmed appointment for today's queue,
and one pending appointment for rejection.

## Run on an Android Emulator

```powershell
flutter run --debug --dart-define=USE_FIREBASE_EMULATORS=true --dart-define=FIREBASE_EMULATOR_HOST=10.0.2.2
```

The explicit flag switches the app to synthetic Firebase options with project
ID `demo-petcare`. Without it, the app retains its normal Firebase configuration.

## Run on a physical Android device

Connect the device by USB with debugging enabled, then run:

```powershell
adb reverse tcp:8080 tcp:8080
adb reverse tcp:9099 tcp:9099
adb reverse tcp:5001 tcp:5001
flutter run --debug --dart-define=USE_FIREBASE_EMULATORS=true --dart-define=FIREBASE_EMULATOR_HOST=127.0.0.1
```

The device must stay connected while using `adb reverse`.

## Build and install the demo APK

```powershell
flutter build apk --debug --dart-define=USE_FIREBASE_EMULATORS=true --dart-define=FIREBASE_EMULATOR_HOST=127.0.0.1
adb install -r build\app\outputs\flutter-apk\app-debug.apk
```

For an Android Emulator build, use `10.0.2.2` instead of `127.0.0.1`.

## Automated verification

Run emulator suites sequentially so they do not compete for ports:

```powershell
npm run test:rules
npm run test:legacy
npm run test:booking
flutter analyze
flutter test
```

`test:booking` proves authenticated callable transport, concurrent overlap
rejection, staff decisions and reassignment, assigned-doctor visibility,
cross-role denials, queue allocation, and the forward queue lifecycle.

Latest verification on integrated `main` (`45ea3df`), 2026-11-05:

| Check | Result |
| --- | --- |
| Synthetic fixture reset against Auth/Firestore/Functions emulators | Passed |
| `npm run test:rules` | 111 passed |
| `npm run test:legacy` | 46 passed |
| `npm run test:booking` | 2 passed |
| `flutter analyze` | No issues |
| `flutter test` | 459 passed |
| Emulator-only Android debug APK | Built successfully |

APK: `build\app\outputs\flutter-apk\app-debug.apk`

SHA-256:
`01CEF27E868E774D152848E46D0A7F7EA3D83BBE1CF5F2AC68A1BC6072290E23`
(203,219,408 bytes).

`adb` was not available on the verification host, so APK installation, physical
device connectivity, and interactive Android screenshots remain untested.

## Demonstration sequence

1. Open Emulator UI at `http://127.0.0.1:4000` and show project
   `demo-petcare` plus the four synthetic Auth users.
2. Sign in as Veterinarian B and show that the appointment initially assigned
   to Veterinarian A is absent. Sign out.
3. Sign in as Owner. Show Milo Demo, PetCare+ Emulator Hospital, both doctors,
   and the existing appointments.
4. Book a new General Consultation with Veterinarian A. Show the pending
   appointment and its Firestore projection in Emulator UI.
5. Show overlap protection using the successful `npm run test:booking` console
   result: two concurrent identical requests produce one success and one
   conflict. The owner UI intentionally hides already occupied slots.
6. Sign in as Staff. Confirm the newly booked appointment and reject
   `demo-reject-ready`.
7. Reassign `demo-queue-ready` from Veterinarian A to Veterinarian B.
8. Sign in as Veterinarian B and show the reassigned appointment. Veterinarian
   A no longer has access to it.
9. Sign back in as Staff, open Queue, check in `demo-queue-ready`, then advance
   `waiting -> in consultation -> completed`.
10. Sign in as Owner, refresh the appointment/queue state, and cancel a separate
    pending appointment.

Run `npm run demo:seed` whenever a clean repeat of the demonstration is needed.

## Screenshot checklist

- Emulator UI showing only synthetic Auth accounts.
- Owner dashboard and Milo Demo profile.
- Hospital, service, and veterinarian selection.
- Appointment confirmation screen.
- `test:booking` one-winner overlap result.
- Staff pending appointment with Confirm/Reject/Reassign actions.
- Veterinarian B before and after reassignment.
- Queue waiting, in-consultation, and completed states.
- Owner cancellation and refreshed queue status.
- Final automated test summaries and APK build success.

## Boundary and known limitations

- Auth, Firestore, Functions and their security rules are locally emulated.
- The shared Spark project hosts Auth and Firestore, but has no deployed
  appointment callable. Booking against shared Firebase is therefore not part
  of this demo.
- Emulator success does not prove cloud IAM, deployed-rule parity, production
  indexes, device networking, App Check, or Spark quota behavior.
- Firebase Storage is not used; images use the existing external Cloudinary
  integration.
- AI responses remain placeholders. Automated reminders, QR Health Passport,
  owner live-queue UI, and complete veterinarian queue management remain
  incomplete and must not be presented as finished.
- Google Sign-In and password-reset links are not part of the emulator demo;
  use the synthetic email/password accounts above.
