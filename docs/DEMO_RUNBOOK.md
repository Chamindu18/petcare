# PetCare+ local presentation runbook

Run from `D:\projects\petcare` on branch `feature/member1`. The demo uses only Firebase project `demo-petcare` with Auth `127.0.0.1:9099`, Firestore `127.0.0.1:8080`, and Functions `127.0.0.1:5001`. `firebase.json` production app settings remain untouched. No billing or deployment is needed.

## Start and reset

1. In terminal A: `npm.cmd run demo:emulators`. Wait for Auth, Firestore and Functions to report ready. The emulator UI is at `http://127.0.0.1:4000`.
2. In terminal B, choose a private synthetic password (PowerShell): `$env:PETCARE_DEMO_PASSWORD = Read-Host 'Demo password'`. Keep it off camera and do not save it in the repository. Run `npm.cmd run demo:seed`.
3. Check the seed: `node scripts/demo/seed_emulators.mjs --validate-only` and `node scripts/demo/verify_seeded.mjs`.
4. Android emulator: `flutter run --dart-define=USE_FIREBASE_EMULATORS=true`.

`demo:seed` clears **only** `demo-petcare` local Auth and Firestore emulator data, then recreates six accounts and deterministic documents. Re-run it to reset after a walkthrough. It does not reset the app's in-memory sign-in: sign out or restart the app after resetting. Run the seed again after Sri Lanka midnight to refresh today's queue and future appointments. The seed refuses conflicting Firebase project or emulator environment variables, unexpected local ports, missing endpoints, or an unset password.

### Physical Android phone

Enable USB debugging, connect the phone, and confirm it appears in `adb devices -l`. With Android SDK platform tools on `PATH`:

```powershell
adb reverse tcp:9099 tcp:9099
adb reverse tcp:8080 tcp:8080
adb reverse tcp:5001 tcp:5001
adb reverse --list
flutter devices
flutter run -d <device-id> --dart-define=USE_FIREBASE_EMULATORS=true --dart-define=FIREBASE_EMULATOR_HOST=127.0.0.1
```

Keep the USB connection and all three reverses active. If the device cannot sign in, check `adb reverse --list`, emulator terminal status, and the Flutter build flags. The app uses isolated demo Firebase options only when `USE_FIREBASE_EMULATORS=true` is passed. For an Android Studio emulator, omit `FIREBASE_EMULATOR_HOST`; the app uses `10.0.2.2`. QR scanning needs a camera-capable device or a second device showing the owner's QR.

## Accounts and seeded modules

All accounts use the private password chosen at seed time.

| Role | Sign-in email | Main records |
| --- | --- | --- |
| Pet Owner | `owner.demo@petcare.test` | Milo and Luna, health history, confirmed/pending/cancelled appointments, queue, owner listing, adoption request, notification |
| Second Pet Owner | `owner.two.demo@petcare.test` | Kiki and a separate confirmed appointment; used to demonstrate protected-record denial |
| Hospital Staff | `staff.demo@petcare.test` | Active assignment to demo hospital, hospital appointments and queue, notification |
| Veterinarian A | `vet.a.demo@petcare.test` | Active directory assignment, Milo's appointment and queue, notification |
| Veterinarian B | `vet.b.demo@petcare.test` | Active assignment, Luna's pending appointment and Kiki's confirmed appointment |
| Adoption Provider | `provider.demo@petcare.test` | Available Coco listing, Biscuit draft, received pending Coco request, notification |

The seed creates one hospital with daily hours, two 30/60-minute services, two veterinarians, three pets, one vaccination, one condition, one treatment, two weight measurements, five appointments with matching availability projections, one linked waiting queue and day counter, three listings, one request, and four role-specific notifications. All names and contact data are synthetic. A second owner exists for security checks.

## Suggested walkthrough

1. **O03/O05/O07/O08:** Sign in as Nimali. Show Milo and Luna, Milo's health records and weight trend.
2. **O09–O14:** Show hospital, services, veterinarians, confirmed appointment `demo-passport-ready` (tomorrow, 11:00 Sri Lanka time), pending appointment, and cancelled history. Live booking uses the local `reserveAppointmentSlot` Function; leave a free future interval if creating a new booking.
3. **O15/V05:** Show Milo's linked waiting queue (`demo-queue-ready`) as owner, staff and assigned Veterinarian A. Staff can advance its status. Re-seed to restore waiting state.
4. **O16/V03/V04:** As owner, open Milo's **confirmed** `demo-passport-ready` appointment and generate the QR in the real app. Scan or enter it while signed in as assigned Veterinarian A. The app creates a random token and projects authorized health records; the seed never creates a token. The QR expires after 15 minutes. Staff can verify its header, while the assigned veterinarian can read the projected health data. Generate a new QR after expiry or a reset.
5. **O19–O21/R01–R03:** Show Coco and the owner's pending request, then switch to the provider dashboard to review it. Provider can accept or reject through the app; re-seed before repeating. Show the owner's Bella rehoming listing and the provider's Biscuit draft in their respective workspaces.
6. **O04:** Show role-specific notifications. Sign in as the second owner to demonstrate that Milo's private pet and appointment are unavailable.

## Recovery and limits

- If a queue or adoption decision has been made, run `npm.cmd run demo:seed` and sign in again.
- If the backend is stopped, restart `npm.cmd run demo:emulators`, re-seed, then restart the Android app.
- If a QR fails, verify the appointment is still confirmed, use Veterinarian A at the same hospital, and generate a fresh QR within 15 minutes.
- Password reset email, Google sign-in, AI remote calls, and Cloudinary image uploads require external services and are outside this local seeded walkthrough. Existing synthetic records have no uploaded images. Image upload and AI output are not claimed as locally verified.
- Firestore integration checks validate role access, but this runbook does not imply every screen or camera path has been exercised on a physical device. Rehearse the complete walkthrough on the presentation devices before recording.
