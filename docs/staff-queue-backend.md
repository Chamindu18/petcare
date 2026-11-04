# Staff queue backend (V05 preparation)

## Existing context and scope

The working tree already contained the verified queue security changes, entity/model/contracts,
eligibility validator, tests and investigation notes. Preserve those changes. This work adds
repository commands and a daily allocation ledger; it does not implement V05 or change dashboards.
The appointment queue-link dispatch that fixed the expression limit remains intact.
Firestore `(default)` in `petcare-d4413` was inspected read-only: STANDARD, FIRESTORE_NATIVE,
asia-south2. Runtime verification uses only demo-petcare and the local emulator.

Code/query scan: appointments and queue records use top-level collections; hospital staff uses
UID-keyed assignments plus users roles. Existing appointments contain ISO strings; some seeded or
legacy records use Timestamps. Queue updatedAt previously used ISO strings. Existing queue read
consumers depend on the unchanged QueueRepository API. No other feature query/rule is broadened.

## Atomic allocation

Each transaction reads the current authenticated user's role and active hospital_staff assignment,
the confirmed appointment and hospitals/{hospitalId}/queue_days/{YYYY-MM-DD}. It then writes
one queue_records document, increments lastNumber, records the allocated queueId on the ledger,
and links the appointment with queueId. Server timestamps bind all writes to the same commit.
Firestore retries transaction conflicts. Failed writes leave neither a number nor a partial link.
Rules require a newly created matching queue, forward-only ledger increments, hospital membership,
appointment relationships and today eligibility; counter-only writes and bypassing the ledger fail.
A single counter serializes arrivals per hospital/day, appropriate for MVP traffic; contention can
still exhaust SDK retries, in which case callers may retry after refreshing the appointment.

The counter rule alone validates the increment. Queue creation verifies the counter after the
commit, its allocated number and queueId. Duplicating a pre-commit counter check in the queue rule
caused contention denials in the emulator; the post-commit binding plus counter rule enforces the
same invariant and passes concurrent transaction tests.

## Calendar and compatibility

MVP hospital calendar is Asia/Colombo (UTC+05:30), independent of device timezone.
`day` is UTC midnight encoding that local calendar date, not the instant of local midnight.
`dayKey` is YYYY-MM-DD. getHospitalQueue accepts calendar components, as its interface specifies.
Rules derive today from request.time. A device clock mismatch or a transaction crossing local
midnight is rejected rather than allocating in the wrong day. Future multi-timezone hospitals
need a trusted hospital timezone policy before expansion.

Appointment ISO strings ending in Z are instants; offset-free ISO strings are hospital wall time.
Timestamp appointments are accepted and normalized only inside this repository. Other ISO offset
spellings are not supported for new check-ins. Queue timestamps accept both Timestamp and legacy
ISO strings. Unknown malformed records fail closed. Relationship-free legacy queue documents
remain parsable but are readable only if existing rules can authorize them; no access is widened.

getQueueByAppointment first reads the authorized appointment, follows a queueId if present, or
queries with ownerId for the owner / hospitalId for hospital users plus appointmentId for legacy
records. New writes always establish linkage. Existing unlinked but scoped legacy entries are
rejected by preflight. Before rollout, a trusted migration must reconcile orphaned or relationship-
free legacy entries and initialize the current day's ledger above any legacy numbers, or begin
on a clean day. Rules cannot query an arbitrary historical collection for orphaned duplicates.
Legacy records without day are intentionally excluded from the new daily list until migrated.
No migration or production write is performed here.

The list sorts by immutable ticket number; position/currentServing are legacy operational fields,
not a promise of a recalculated waiting-room rank. Status commands set position to zero, enforce
expected status in a transaction, and allow waiting -> in_consultation -> completed only.
They do not modify appointment status or veterinarian workflows.

## Infrastructure and failure behavior

Rules and application changes must roll out together before staff commands are enabled. Nothing
is deployed by this task. Equality-only scoped queries use Firestore's existing single-field
index merging; no new composite index is required. Trusted provisioning must own staff role and
assignment documents. Admin SDK writers bypass rules and must preserve these invariants.
Transactions require connectivity; there is no offline check-in allocation. A failure in the
post-commit queue fetch can surface after the write committed: refresh the appointment/link before
retrying. Duplicate attempts intentionally report an error and never allocate a replacement.

Dart fake Firestore tests verify repository behavior, validation and stale expected statuses.
The fake does not implement real transaction locking/rollback, so emulator transaction tests are
the evidence for concurrent allocation, duplicate races and atomic rollback. Security denials use
the existing strict assertion helper; runtime-limit errors cannot masquerade as expected denials.

## Verification evidence

- Full `flutter test`: 398 passed, zero failed (`queue-backend-all-flutter.log`).
- Full `flutter analyze`: no issues (`queue-backend-analysis.log`).
- Node Firestore suites: 77 passed, zero failed.
- Mocha security suite: 46 passed, zero failed.
- Both security suites ran sequentially under one demo-petcare emulator session
  (`queue-backend-complete-security.log`). Concurrency tests use real SDK transactions.
- `git diff --check`: passed.

Logs are ignored local verification artifacts. No commit, push, merge, deployment, database
migration or production data mutation was performed. Existing unrelated working-tree changes
were preserved. The additional Mocha change only adapts its successful queue-creation fixture
to the mandatory ledger and server timestamp; its security assertions remain intact.
