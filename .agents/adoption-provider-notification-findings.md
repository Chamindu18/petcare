# Adoption provider notification findings

Scope: adoption request creation/withdrawal, the shared notification inbox,
provider request routing, and their Firestore rules/tests. No broader project
audit was performed.

## Existing workflow findings

- Provider listings use `listingOwnerType`, `listingOwnerId`, and the legacy
  `providerId` alias. New requests are accepted only for `available`
  provider-owned listings.
- Adoption requests use canonical `recipientId`/`recipientType` fields, retain
  `providerId` for compatibility, and are visible only to the requester or the
  verified listing recipient.
- Applicant withdrawal already existed for a request in `pending` state and
  transitions it to `withdrawn`; therefore a withdrawal notification is within
  the implemented workflow.
- Provider accept/reject notifications to owners already existed and use the
  shared `notifications` collection and inbox.
- The request-creation transaction contained a duplicate request write and no
  provider notification before this change.

## Relevant access/query patterns

- Provider requests: `recipientId == current UID`, `recipientType ==
  adoption_provider`, ordered by `submittedAt` descending.
- User notifications: `recipientUserId == current UID`, ordered by `createdAt`
  descending. Unread bulk updates add `read == false`.

## Security attack review

- Public/other-provider notification read: denied by recipient-only rules.
- Forged recipient, listing relationship, message, listing name, timestamp, or
  notification ID: denied by authoritative listing/request validation.
- Notification without a request created in the same atomic operation: denied
  using `!exists(request)` plus `existsAfter(request)`.
- Request creation without its matching provider notification: denied using
  `getAfter()` from the request rule.
- Duplicate submission/replay: denied by the deterministic
  `adoption_request_submitted_<listingId>_<requesterId>` document.
- Failed request leaving an orphan notification: denied by atomic rules.
- Notification schema pollution: denied by the existing strict notification
  field allowlist.
- Unauthorized read-state/content update: only the recipient may change only
  `read` to `true`.
- Withdrawal notification without the pending-to-withdrawn transition: denied.
- Existing owner accept/reject notifications: retained and covered by the
  emulator suite.

Verification: focused Flutter tests and the 133-test Firestore emulator rules
suite passed on 2026-11-07.
