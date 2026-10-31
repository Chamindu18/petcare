# Adoption ownership and request security contract

**Status:** Updated for the provider-only adoption listing policy. The local implementation and tests have been validated. These results do not establish that the latest rules have been deployed to production. The trusted requester-recipient backfill has not been applied to production as part of this work.

## Decisions

1. **Listing ownership and management:** Only users with the `adoption_provider` role can create, update, reserve, or manage adoption listings. New listings use `listingOwnerType = adoption_provider`, with `listingOwnerId` set to the authenticated provider UID. The `providerId` field remains as a compatibility alias. Regular owners cannot create or manage advertisements.

2. **Public listing access:** Regular owners can browse available adoption listings and view listing details. Providers can access their own listing-management workflows, including their drafts. Browsing listings does not grant permission to create, update, or manage advertisements.

3. **Adoption request creation:** Only an owner can create an adoption request. The referenced listing must exist, be available, and belong to an adoption provider. The recipient must match the verified provider who owns the listing, and requesters cannot submit requests to themselves. These relationships must be validated in both the repository and Firestore rules.

4. **Canonical recipient metadata:** New adoption requests write `recipientId` and `recipientType`. Provider requests also retain `providerId` for compatibility. The `providerId` alias alone is never sufficient evidence for recipient authorization. Provider inbox queries and decisions must rely on canonical recipient metadata and a verified relationship to the listing.

5. **Request withdrawal:** Withdrawal is a retained-record `pending -> withdrawn` transition, limited to the requester and the permitted fields `status`, `updatedAt`, and `closedAt`. Physical deletion of adoption requests is denied to clients.

6. **Provider request decisions:** Only the authorized adoption provider can decide a pending request tied to that provider's listing. The requester can view their own request history but cannot accept or reject requests. A provider can reject a pending request for an unavailable listing so the request can be closed.

7. **Atomic acceptance:** Listing reservation and request acceptance must be performed atomically. Acceptance reserves the listing and records the accepted request relationship. The existing safeguards prevent a second request for the same listing from also being accepted. Preserve the transaction and Firestore rule protections; do not replace them with independent, non-atomic writes.

8. **Role-specific workspaces:** The provider dashboard is restricted to `adoption_provider` users and provides listing management and access to requests received for their listings. The owner workspace provides public listing browsing and access to the owner's own adoption requests. Owners must not access listing creation, listing management, or the inbox for requests received by providers. Hospital-managed adoption is outside this scope.

9. **Legacy data:** Existing listing and request documents may contain legacy ownership or recipient fields. Legacy data must not grant permissions that contradict the provider-only policy. Historical documents must be reviewed and handled through an approved migration or data-cleanup plan rather than being silently reassigned or deleted.

10. **Notifications:** Notification target-routing and FCM token/event handling remain out of scope.

## Trusted legacy-request backfill

The provider inbox query uses canonical recipient metadata: `recipientId == currentUser.uid` and `recipientType == adoption_provider`. It must not depend on a query using only `providerId` or on client-side filtering. Firestore rules do not act as post-query filters.

A legacy request can be backfilled as a provider request only when the relationships can be verified:

- The requester profile exists and has the `owner` role.
- The referenced listing exists and is a valid provider-owned listing.
- The listing's provider identity is verified against its ownership fields and provider profile.
- The recipient is the provider who owns the referenced listing.
- The requester is not the listing owner.
- Any request-level legacy `providerId` agrees with the verified provider identity.
- The request status is a recognized lifecycle state.
- Existing recipient or ownership metadata does not conflict with the verified relationship.

A request's `providerId` field alone must never be used to infer a recipient. If canonical metadata exists but the underlying relationship is missing or inconsistent, the backfill clears the invalid recipient fields. Records without a provable provider-recipient relationship remain without canonical recipient metadata and therefore cannot appear in the provider inbox. The requester may still view their own request history where the rules permit it.

Historical owner-owned listing documents require separate review. They must not be treated as valid provider advertisements or automatically converted to provider ownership. Review these records before production rollout so that listings which cannot accept valid provider-directed requests do not create a misleading public experience.

### Required rollout sequence

1. Back up Firestore using the team's approved export procedure.
2. Install the npm dependencies and run the trusted backfill in dry-run mode against the intended project. Review all proposed updates and clears.
3. Apply the backfill only after review and explicit approval. Then rerun dry-run; the unchanged dataset should have zero pending updates or clears.
4. Deploy the reviewed rules only after the verified legacy requests have canonical recipient metadata and inconsistent records have been handled.
5. Retain compatibility for older provider clients only during the migration period. Legacy requests without canonical recipient metadata may not appear in provider inboxes until the trusted backfill processes them. Plan to retire this compatibility path when older clients are no longer in use.

The backfill script is a one-off trusted Admin SDK tool. It is not deployed as a function and must not be run against production without the approved migration process. It is dry-run by default. Applying requires the explicit `--apply` argument and `CONFIRM_ADOPTION_RECIPIENT_BACKFILL=yes`.

Application Default Credentials and service-account credentials must be secured outside the repository. Never put credential files into the project or a review ZIP.

## Emulator tests

From the repository root, after installing or updating npm development dependencies:

```powershell
npm install
npm run test:rules
```

The command runs the Firestore Rules Emulator tests and the pure backfill-planner tests. Tests cover provider-only listing authorization, legacy provider compatibility, canonical inbox isolation, invalid or unbackfilled requests, retained withdrawal, ownership immutability, recipient decisions, and atomic single-request acceptance.

These tests use a demo project. They do not deploy or verify production rules.

## Current verification scope

The local Windows checkout has validated the provider-only repository changes:

- `flutter analyze`: no issues found.
- `flutter test`: all 213 tests passed.
- Repository tests: all 3 provider-only access tests passed.
- `npm run test:rules`: all 33 Firestore rules and backfill-planner tests passed.
- `git diff --check`: no whitespace errors.

These are local validation results. They do not prove that the latest rules have been deployed or that the production dataset has been migrated. Rerun the relevant checks after any subsequent code or rules changes and before release approval.
