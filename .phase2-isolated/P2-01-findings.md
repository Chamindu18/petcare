# P2-01 trace (disposable investigation)

- Canonical listing authority uses `listingOwnerType` and `listingOwnerId`; legacy provider listings use `providerId`. Both share `adoption_listings`.
- Listing entity, model, form, and rules have no `petId`. Pet ownership is recorded in `pets/{petId}.ownerId`; pet deletion is a status tombstone.
- Owner dashboard has discovery and submitted requests only. Listing management, create/edit, received requests, and request details are provider-gated routes.
- Request repository and rules explicitly limit new requests and decisions to provider-owned listings. Notification recipient validation follows those provider-only paths.
- Provider reservation is a transaction/batch across listing and request, with an accepted request ID.
- Existing provider-only listing data and legacy request paths need to remain compatible.
- Full owner rehoming requires a pet binding, secure current-ownership checks at create/update/request/decision, listing and request route integration, notification handling, and deletion/tombstone behavior. A listing-create permission change alone cannot complete the lifecycle.
