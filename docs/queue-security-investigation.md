# Queue security evaluation investigation (2026-11-03)

Branch: feature/member1. No commit, push, merge, or deployment performed.

## Reproduction and root cause

The session-start rules already contained queue-link guards and operation-aware AND/OR dispatch. Running the requested queue emulator command passed all 9 tests, including a valid atomic create/link. However, `appointment queue linkage cannot be changed independently` returned `Unable to evaluate the expression as the maximum of 1000 expressions to evaluate has been reached` at appointment update line 495. `assertFails` accepted that runtime failure as a successful security test. Standalone queue creation also accessed an undefined post-write appointment `queueId`.

Controlled experiment: changed only appointment update dispatch to a ternary selecting queue-link writes exclusively, keeping all authorization predicates unchanged. The same nine tests still passed and the expression-limit error disappeared. This isolates cumulative evaluation of the ordinary-edit OR tree alongside the failed queue-link branch as the expression-budget cause. Adding AND guards to branches had not bounded that failure path. This was not a circular rule authorization lookup or evidence of an access-call quota failure.

The full baseline rules and emulator log were preserved in the local temporary directory as petcare-rules-before.rules and petcare-rules-baseline.log.

## Changes relative to session start

- Select queue-link authorization exclusively when queueId changes. Ordinary edits retain their existing predicates; the link predicate still requires hospital authorization, confirmed status, immutable identity, a previously unlinked appointment, server updatedAt, a new queue document, and matching after-state relationships.
- Safely form paths for malformed identifiers, while retaining explicit identifier validation before authorization can succeed.
- Use fail-closed defaults for missing assignment fields, read/query ownership and hospital fields, and the appointment after-state queueId. Defaults never grant a missing hospital assignment: hospitalId defaults to null.
- Add strict denial assertions to all security suites: permission-denied is required, and expression/access limits, undefined fields, null values, and invalid paths cannot qualify as expected denials. The emulator sometimes labels ordinary false predicates as generic `evaluation error`; that label alone is not treated as proof of runtime exhaustion.
- Expand the queue suite from 9 to 18 tests and include it in npm run test:rules. Exercise genuine atomic batches for forged relationships and cross-hospital access, concurrent duplicate check-in, absent and removed links, confirmed-state eligibility, valid lifecycle progression, invalid transitions, terminal immutability, queue identity/number preservation, scoped owner/staff reads, malformed data, staff assignment identity/active state, and veterinarian success. Failed forged batches verify both documents remain unchanged.
- Repair stale legacy test fixtures: demo emulator project, sufficient cold-start timeout, trusted veterinarian hospital provisioning, queueId in seeded records, atomic queue creation, and in_consultation rather than called. No application module was changed.

## Limits and authorization review

Firestore documents limits of 1,000 expressions, 10 document access calls per write, and 20 for an atomic multi-document request; repeated calls may be cached. See https://firebase.google.com/docs/firestore/quotas and https://firebase.google.com/docs/firestore/security/rules-conditions.

For an authorized staff check-in, each write refers to four distinct document/state combinations: user profile, staff assignment, and before/after counterpart document. Veterinarians use their directory record instead of staff assignment. Repeated exists/get calls target the same paths and are cache eligible. Both staff and veterinarian two-write batches actually succeed under emulator-enforced access limits. No added helper performs recursive authorization; getAfter inspects the pending document state and does not run that document's allow rule recursively. Both sides independently enforce linkage, and both writes must pass. Arbitrarily large multi-appointment batches were not proven; the aggregate 20-call limit still applies.

Staff role remains sourced from the trusted user profile. Staff assignment is keyed by authenticated UID and must match userId, hospitalId, and active=true. Clients cannot write assignments or promote their role. Owners retain pending edits, pending/confirmed cancellation, own-resource reads and scoped queries; they cannot perform staff check-in or decision operations. Cross-hospital reads and writes fail.

## Verification

- Initial queue suite: 9/9 passed but concealed one expression exhaustion and one undefined-field denial.
- Final npm run test:rules: 70/70 passed, with strict denial checks across appointment, queue, and adoption rule suites.
- Expanded standalone queue suite: 18/18 passed.
- Legacy Mocha suite: 46/46 passed with strict denial assertions in the final rerun.
- flutter analyze: no issues.
- flutter test: 388 passed.
- git diff --check: clean.

## Residual scope and risks

This proves the tested emulator workflows, not every possible production request or an exact remaining expression-budget margin. No deployment or live Firebase validation was performed. Existing rules do not enforce globally unique queue numbers or same-day scheduling, and do not comprehensively bound all queue strings/extra creation fields; those are separate policy/schema hardening work. The existing queue repository query filtered only by appointmentId cannot generally prove owner/hospital scope under these read rules; this patch verifies ownerId/hospitalId scoped queries and does not modify teammate application modules. Full repository-wide security certification is outside this focused fix.

Scoped auditor assessment:

```json
{"score":4,"summary":"Tested queue authorization and atomic linkage pass with runtime-limit-aware denials; broader schema hardening remains.","findings":[{"check":"Storage Abuse","severity":"minor","issue":"Existing queue string lengths and extra creation fields are not comprehensively bounded.","recommendation":"Review the queue schema in a separate agreed change."},{"check":"Business Logic vs. Rules","severity":"moderate","issue":"The legacy appointmentId-only queue query lacks an ownerId or hospitalId authorization constraint.","recommendation":"Use the linked queue document ID or add the authenticated owner/hospital query constraint in the responsible application feature."}]}
```
