# V01 single-account link repair

## Verified proposal (not applied)

Read-only snapshot: 2026-11-04 17:45:47 UTC. Target: `petcare-d4413/(default)`, STANDARD / FIRESTORE_NATIVE.

The sole veterinarian profile's document ID is an existing enabled Auth UID. Its role is `veterinarian`, explicit `vetId` is `vet_001`, and `hospitalId` is `hospital_001`. The active `veterinarians/vet_001` record has the same hospital assignment; that hospital exists and is active. No other directory document claims the UID. No other user profile (including other roles and UID-based fallback references) references this directory record. Names and emails were not used.

The exact UID, full document paths, before/after values, and reviewed version digest are in the local, git-ignored [repair plan](../build/veterinarian-link-plan.json). Treat this file as operator account metadata; do not commit or publish it.

Only `veterinarians/vet_001` changes:

```diff
- userId: <field absent>
+ userId: <authUid from the verified local plan>
```

All other fields, including the legacy string `experienceYears`, remain untouched. No profile, hospital, other veterinarian, rules, index, or application identity configuration changes are proposed.

## Prerequisites and safe execution

1. An authorized hospital/account administrator must confirm the existing profile assignment against the hospital provisioning record. The database link is internally consistent; independent provisioning paperwork was not available in this workspace.
2. Obtain explicit approval for the exact local plan before a production write. General permission to continue safe preparation is not approval to apply this live change.
3. Use the existing trusted Firebase CLI administrator account with database read/update and Auth lookup IAM permissions. This script uses the privileged REST transaction API with CLI OAuth credentials; it is an operator tool, not a mobile action or callable endpoint. Do not grant these permissions to the doctor. Keep account provisioning/Auth deletion or disabling paused during execution, since Auth and Firestore cannot share one transaction.
4. From the repository root, review the existing plan, then use the dry run below to revalidate before execution. A new dry run replaces the local plan; review any differences and obtain renewed approval if the mapping changes.

```powershell
node scripts/repair-veterinarian-link.cjs
```

The default opens a read-only snapshot, verifies the profile/directory/hospital and Auth account, reads all users and directory entries to detect conflicts, saves the plan, and rolls back without committing any writes.

Only after the production change has been explicitly approved, an administrator may run:

```powershell
node scripts/repair-veterinarian-link.cjs --apply "ACTUAL approval or change-ticket reference"
```

The apply mode rereads and validates the relationship and conflict collections in a Firestore read/write transaction. The reviewed document-version digest must match. A transaction and directory `updateTime` precondition guard concurrent changes; the sole write mask is `userId`. Conflict, permission, or stale-plan failures abort; there is no automatic retry. An already matching link is a verified no-op. The script rereads the committed directory document and saves `build/veterinarian-link-receipt.json`. Retain the approval, plan, receipt, and available Cloud Audit Logs in the administrator's audit system. It writes no audit document to the live database.

If a timeout or network error makes the commit result uncertain, run the dry run and inspect the current link before proceeding. Never restore a whole old directory document. Any rollback requires a separately reviewed field-only change with a fresh precondition.

Firestore transactions provide serializable isolation; REST commit applies the supplied writes atomically. References: [transaction isolation](https://firebase.google.com/docs/firestore/transaction-data-contention), [REST commit](https://docs.cloud.google.com/firestore/docs/reference/rest/v1/projects.databases.documents/commit).

## Android verification after approved correction

1. A verified debug APK is preserved at `build/verified/veterinarian-dashboard-debug.apk` (129900678 bytes; SHA-256 `4dad6e265e42e32e9c019fdeba7ef52e8ece753611cf55be955990e1885847be`). At 2026-11-04 18:00:07 UTC its embedded Dart kernel was checked to contain the exact current source of the model, assignment repository, and V01 dashboard page. Evidence: `build/veterinarian-dashboard-apk-evidence.json`. `VeterinarianModel._experienceYears` parses numeric strings and rejects malformed, negative, and nonfinite values. All 12 dashboard regression tests pass, including a verified assignment with `experienceYears: '12'` and strict identity/active/hospital checks. All eight repair safeguard tests also pass. A separate fresh `flutter build apk --debug` was started but has not completed; its success is not claimed. The preserved APK came from the existing build and was verified directly.
2. Verify the preserved APK's hash using `Get-FileHash build/verified/veterinarian-dashboard-debug.apk -Algorithm SHA256`, then connect the Android test device (ADB reported it connected during this task). Install with `adb -s RFCX90V4D3B install -r build/verified/veterinarian-dashboard-debug.apk`. Do not uninstall or clear app data. If a signing mismatch occurs, stop and resolve it without deleting user data.
3. Launch PetCare+, sign in through normal Firebase authentication with the existing test doctor's credentials, and open V01. Use the approved account corresponding to the plan's UID; do not create a replacement doctor or use a custom token/admin session.
4. Confirm V01 leaves its loading state, shows the assigned doctor/hospital and schedule or legitimate empty state, and has no assignment or numeric-cast failure. Pull to refresh and cold-relaunch; confirm the same result. Check date/time labels in Sri Lanka time (UTC+05:30).
5. Open an assigned appointment (V02) if present. Confirm its canonical `vetId` and hospital match the plan. An empty schedule is valid only if no matching appointments exist. Capture only relevant sanitized V01 error codes/logs if loading fails.
6. Test offline/online Retry or refresh and sign-out/sign-in. Do not change appointment, consultation, or queue state for this read-only smoke test. Record app/APK hash, device, timestamp, and observed result.

The previously observed deployed rules use a UID-based directory lookup and differ from the reviewed local rules. The missing back-reference correction does not guarantee those rules authorize appointment reads for a directory ID different from the UID. If the linked updated app reports `permission-denied`, retain that result for a separate reviewed rules release; do not duplicate the directory under the UID, broaden rules, or change the profile's `vetId`. This repair does not deploy rules. Cross-doctor authorization testing remains a separate release check using another approved test account.

No production write/deployment, commit, or push was performed. Successful live Android dashboard loading remains pending the approved link correction and authenticated device smoke test.
