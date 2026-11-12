const CANONICAL_TYPES = new Set(['owner', 'adoption_provider']);
const hasOwn = (value, key) => Object.prototype.hasOwnProperty.call(value ?? {}, key);
const nonEmptyString = (value) => typeof value === 'string' && value.trim().length > 0;

/**
 * Pure migration planner for adoption request recipient metadata.
 * It never mutates input and never trusts recipient fields without checking the
 * current listing owner and both users' roles. The Admin SDK runner applies the
 * returned updates only when invoked with --apply.
 */
export function planRecipientBackfill({
  requestData,
  listingData,
  listingExists,
  requesterRole,
  recipientRole,
}) {
  const data = requestData ?? {};
  const hasRecipientFields = hasOwn(data, 'recipientId') || hasOwn(data, 'recipientType');
  const clearOrSkip = (reason) => ({
    action: hasRecipientFields ? 'clear' : 'skip',
    fields: hasRecipientFields ? ['recipientId', 'recipientType'] : [],
    reason,
  });

  if (!listingExists || listingData == null) {
    return clearOrSkip('referenced listing is missing');
  }

  const listing = listingData;
  const ownerType = listing.listingOwnerType ?? 'adoption_provider';
  const ownerId = listing.listingOwnerId ??
    (ownerType === 'adoption_provider' ? listing.providerId : '');
  if (!CANONICAL_TYPES.has(ownerType) || !nonEmptyString(ownerId)) {
    return clearOrSkip('listing owner metadata is invalid');
  }

  const providerAlias = listing.providerId;
  if (nonEmptyString(providerAlias) && providerAlias !== ownerId) {
    return clearOrSkip('listing ownership fields conflict');
  }
  if (ownerType === 'owner' && nonEmptyString(providerAlias)) {
    return clearOrSkip('owner listing contains a provider alias');
  }
  // A request-level providerId is a legacy alias, not an independent source
  // of truth. If present it must agree with the verified listing recipient.
  if (hasOwn(data, 'providerId') && (
    ownerType !== 'adoption_provider' || data.providerId !== ownerId
  )) {
    return clearOrSkip('request provider alias conflicts with listing recipient');
  }
  if (!['pending', 'accepted', 'rejected', 'withdrawn', 'closed'].includes(data.status)) {
    return clearOrSkip('request status is invalid');
  }
  if (data.requesterId === ownerId) {
    return clearOrSkip('requester cannot request their own listing');
  }
  if (!nonEmptyString(data.requesterId) || requesterRole !== 'owner') {
    return clearOrSkip('requester identity or role is invalid');
  }
  if (recipientRole !== ownerType) {
    return clearOrSkip('listing owner account role does not match listing metadata');
  }

  const hasRecipientId = nonEmptyString(data.recipientId);
  const hasRecipientType = nonEmptyString(data.recipientType);
  const canonicalExact = data.recipientId === ownerId && data.recipientType === ownerType;
  if (canonicalExact) {
    return { action: 'skip', fields: [], reason: 'recipient metadata already valid' };
  }

  // A providerId that exactly matches the verified listing owner is the only
  // legacy relationship proof accepted for requests created before canonical
  // recipient fields existed. For owner listings, only non-conflicting partial
  // canonical metadata can be repaired; providerId is never treated as owner proof.
  const validLegacyProviderLink = ownerType === 'adoption_provider'
    && data.providerId === ownerId;
  const partialFieldsDoNotConflict =
    (!hasRecipientId || data.recipientId === ownerId)
    && (!hasRecipientType || data.recipientType === ownerType);
  const hasCanonicalClue =
    (hasRecipientId && data.recipientId === ownerId)
    || (hasRecipientType && data.recipientType === ownerType);
  const validPartialCanonicalLink = hasCanonicalClue && partialFieldsDoNotConflict;

  if (validLegacyProviderLink || validPartialCanonicalLink) {
    return {
      action: 'update',
      fields: { recipientId: ownerId, recipientType: ownerType },
      reason: validLegacyProviderLink
        ? 'legacy providerId matches verified listing owner'
        : 'partial canonical recipient metadata matches verified listing owner',
    };
  }

  return clearOrSkip('request recipient does not match the referenced listing');
}
