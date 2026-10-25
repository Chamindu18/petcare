# Adoption ownership and request security contract

**Status:** Updated for the shared security review. The requester-recipient backfill has not been run against production. Firestore Emulator and Flutter suites must be rerun against the follow-up patch before this patch is approved for deployment.

## Decisions

1. `adoption_listings.listingOwnerType` is `owner` or `adoption_provider`; `listingOwnerId` is the authenticated UID that owns/manages the listing. Provider listings retain `providerId` as a compatibility alias; new owner listings do not use that alias.
2. New adoption requests write `recipientId` and `recipientType`. Provider requests also retain `providerId` for compatibility. **The alias alone is never authorization evidence** for a recipient inbox or decision. Recipient access uses canonical metadata that was written by the current validated client or a trusted backfill.
3. Only an owner can create a request. The referenced listing must exist, be `available`, have a valid owner type and UID, belong to the specified recipient, and not belong to the requester. Request creation validates these relationships in both the repository and Firestore rules.
4. Request withdrawal is a retained-record `pending -> withdrawn` transition, limited to the requester and the fields `status`, `updatedAt`, and `closedAt`. Physical deletion of adoption requests is denied to clients.
5. The canonical listing recipient can decide only a pending request tied to a listing they own. **Acceptance is denied unless the listing status is currently `available`** in both the client transaction and rules. Rejection remains permitted for a pending request when the listing is no longer available so the recipient can close the request.
6. **Multiple acceptance policy:** a listing should become unavailable after the first successful acceptance to prevent a second request from also being accepted. This patch intentionally does not auto-change the listing status: the existing listing schema/UI support `available` and `draft`, and converting a successful adoption to `draft` would be misleading. Consequently, this patch does not fully prevent two different pending requests for one listing from both being accepted while its status remains `available`. Before production, coordinate a terminal status/availability design across listing entities/models, repository transaction, rules, and UI; do not add an unapproved status in this patch.
7. Owner and provider screens share listing/request workflows, but the provider dashboard remains provider-only. The owner workspace shows only the owner's listings and incoming requests. Hospital-managed adoption is not included.
8. Notification target-routing and FCM token/event handling remain out of scope.

## Trusted legacy-request backfill

The provider inbox query now uses only `recipientId == currentUser.uid` and `recipientType == adoption_provider`; owner inboxes use the equivalent owner fields. It does not query `providerId` and does not rely on client-side filtering. Firestore Rules cannot safely act as a post-query filter, and broad queries using only `providerId` must not be retained.

A valid legacy request is backfilled only when all relationships are verified: the requester profile exists and is an owner; the referenced listing exists; its owner type/UID is valid and matches the recipient account role; the requester is not the listing owner; listing ownership fields do not conflict; any request-level legacy `providerId` agrees with the actual provider listing owner; and the request status is a recognized lifecycle state. A valid record receives `recipientId` and `recipientType`. If canonical metadata exists but the relationship is missing or inconsistent, the backfill clears those recipient fields. Records without canonical fields and without a provable legacy relationship remain without canonical fields and therefore cannot appear in the recipient inbox; the requester can still view their own history.

### Required rollout sequence

1. Back up Firestore using the team's approved export procedure.
2. Install the npm dependencies and run the trusted backfill in dry-run mode against the intended project; examine the planned updates/clears before applying anything.
3. Apply only after review and explicit confirmation, then rerun dry-run. The post-run dry-run should show zero pending updates/clears for the unchanged dataset.
4. Deploy the stricter rules only after verified legacy records have canonical recipient metadata and mismatched/missing records have no recipient metadata.
5. Until all clients write canonical recipient fields, legacy clients may still create provider requests using only `providerId`. Those new records will not appear in the provider inbox until the trusted backfill is rerun. Keep this compatibility path only during the migration window, and plan its retirement once old clients are no longer in use.

The backfill script is a one-off trusted Admin SDK tool; it is not deployed as a function and has not been run against any project in this review. It is dry-run by default. Applying requires an explicit `--apply` and `CONFIRM_ADOPTION_RECIPIENT_BACKFILL=yes`. Application Default Credentials/service-account credentials must be secured outside the repository. Never put credential files into the project or review ZIP.

## Emulator tests

From the repository root after installing/updating npm development dependencies:

```powershell
npm install
npm run test:rules
```

The command runs both the Firestore Rules Emulator tests and the pure backfill-planner tests. Tests cover owner/provider listing authorization, legacy listing/request compatibility, canonical inbox isolation, missing/mismatched unbackfilled requests, invalid backfill data, retained withdrawal, ownership immutability, recipient decisions, and rejection versus acceptance of unavailable listings. The tests use a demo project; they do not deploy or test production rules.

## Current verification scope

Prior to this follow-up, the local Windows checkout reported 19 Firestore Emulator tests, 44 focused adoption tests, 185 full Flutter tests, and `flutter analyze` with no issues. These are **results for the earlier patch**, not this follow-up. In the current authoring environment, the pure Node backfill-planner tests can run, but the npm registry is unreachable and Flutter/Dart are unavailable; therefore the updated Emulator and Flutter suites must be rerun on the Windows development machine before approval.
