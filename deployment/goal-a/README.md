# Goal A rules review

The candidate `firestore.rules` starts from the captured live ruleset and
changes only the appointment and schedule permissions. The live rules backup is
`deployed-backup.rules`. The local root `firestore.rules` has many unrelated
differences and must not be deployed as the Goal A patch.

The schedule projection writer contract contains only `vetId`, `hospitalId`,
`serviceId`, `dateTime`, `status`, and `durationMinutes`; no owner, pet, reason,
or clinical data. The live collection had zero documents on 2026-11-08, so
there is no existing live projection document whose shape can be verified.
The candidate denies all client schedule writes. The exact app query filters on
`vetId == selectedVeterinarianId`.

## Restricted demo policy

- Appointment reads keep the deployed owner and hospital role rules.
- Client appointment create and delete are denied. Owner pending edits can
  change only `reason` and `updatedAt`; authorized staff can change only
  `reason`, `queueId`, and `updatedAt` on pending or confirmed appointments.
  Scheduling identity, duration, date/time, hospital, veterinarian, service,
  and status cannot change through a client write.
- Owner cancellation and staff confirmation/rejection are temporarily
  unavailable. The current repository writes `appointment_schedule` in the
  same transaction as each status decision, and the restricted policy rejects
  that client write. This also means cancellation and decision notifications
  are not emitted. Existing notifications and the owner reminder reader keep
  their read permissions. Queue metadata edits can continue where authorized.
- Existing appointment reads, QR Passport reads, and appointment-linked
  authorization remain available for historical appointments. The policy
  creates no new appointment or QR Passport. Existing QR access follows the
  canonical appointment's unchanged status and assignment.
- In ordinary live `flutter run`, O11 displays the real slot picker but shows
  that confirmation is unavailable; the confirmation button is disabled.
  Emulator mode retains the booking callable behavior.

## Completeness gate

The read-only audit on 2026-11-08 again found four October appointments, zero
`appointment_schedule` documents, and zero active future appointments. All
four historical records lack duration snapshots and projections. They cannot
affect future dates in the picker. `firebase functions:list --project
petcare-d4413` reported no deployed functions. The repository contains a
manual Admin SDK backfill script, but no running trusted writer was observed.
Before enabling availability, the team must confirm that no external Admin SDK,
console, import, or other privileged process can create or move future
appointments without writing a matching projection. Firestore rules cannot
constrain privileged writers. Re-run the live audit immediately before release;
any active future appointment lacking a matching projection blocks release.

**Do not deploy until that external-writer check is complete.** No live data
was changed during preparation.

Before any deployment, fetch the live release again and compare it to
`deployed-backup.rules`. If it changed, regenerate and retest this candidate.
After satisfying the completeness gate, deploy only this candidate with:

```powershell
firebase.cmd deploy --only firestore:rules --project petcare-d4413 --config deployment/goal-a/firebase.json
```

If rollback is needed, deploy the captured backup with:

```powershell
firebase.cmd deploy --only firestore:rules --project petcare-d4413 --config deployment/goal-a/rollback.firebase.json
```

Both commands deploy rules only. Neither writes Firestore documents.
