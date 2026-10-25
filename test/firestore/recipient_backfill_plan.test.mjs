import test from 'node:test';
import assert from 'node:assert/strict';
import { planRecipientBackfill } from '../../scripts/lib/adoption-recipient-backfill-plan.mjs';

const providerListing = {
  listingOwnerType: 'adoption_provider',
  listingOwnerId: 'provider-1',
  providerId: 'provider-1',
  status: 'draft',
};
const common = {
  requestData: { requesterId: 'owner-1', providerId: 'provider-1', status: 'pending' },
  listingData: providerListing,
  listingExists: true,
  requesterRole: 'owner',
  recipientRole: 'adoption_provider',
};

test('backfills a valid legacy provider request from its verified providerId/listing relationship', () => {
  assert.deepEqual(planRecipientBackfill(common), {
    action: 'update',
    fields: { recipientId: 'provider-1', recipientType: 'adoption_provider' },
    reason: 'legacy providerId matches verified listing owner',
  });
});

test('leaves already valid canonical recipient metadata unchanged', () => {
  const plan = planRecipientBackfill({
    ...common,
    requestData: {
      ...common.requestData,
      recipientId: 'provider-1',
      recipientType: 'adoption_provider',
    },
  });
  assert.equal(plan.action, 'skip');
  assert.match(plan.reason, /already valid/);
});

test('clears recipient metadata when the listing is missing', () => {
  const plan = planRecipientBackfill({
    ...common,
    requestData: {
      ...common.requestData,
      recipientId: 'provider-1',
      recipientType: 'adoption_provider',
    },
    listingData: null,
    listingExists: false,
  });
  assert.equal(plan.action, 'clear');
  assert.deepEqual(plan.fields, ['recipientId', 'recipientType']);
});

test('clears recipient metadata when legacy providerId disagrees with listing owner', () => {
  const plan = planRecipientBackfill({
    ...common,
    requestData: {
      requesterId: 'owner-1',
      providerId: 'provider-2',
      recipientId: 'provider-2',
      recipientType: 'adoption_provider',
      status: 'pending',
    },
  });
  assert.equal(plan.action, 'clear');
  assert.match(plan.reason, /conflicts with listing recipient|does not match/);
});

test('does not infer an owner rehoming recipient from legacy providerId alone', () => {
  const plan = planRecipientBackfill({
    ...common,
    listingData: {
      listingOwnerType: 'owner',
      listingOwnerId: 'owner-2',
      status: 'available',
    },
    recipientRole: 'owner',
    requestData: {
      requesterId: 'owner-1',
      providerId: 'owner-2',
      status: 'pending',
    },
  });
  assert.equal(plan.action, 'skip');
  assert.match(plan.reason, /provider alias conflicts|recipient does not match/);
});

test('clears recipient metadata when requester is not an owner or is the listing owner', () => {
  for (const requestData of [
    { ...common.requestData, recipientId: 'provider-1', recipientType: 'adoption_provider' },
    { ...common.requestData, requesterId: 'provider-1', recipientId: 'provider-1', recipientType: 'adoption_provider' },
  ]) {
    const plan = planRecipientBackfill({
      ...common,
      requestData,
      requesterRole: requestData.requesterId === 'provider-1' ? 'adoption_provider' : 'veterinarian',
    });
    assert.equal(plan.action, 'clear');
  }
});


test('clears canonical metadata when request provider alias conflicts with verified listing owner', () => {
  const plan = planRecipientBackfill({
    ...common,
    requestData: {
      ...common.requestData,
      providerId: 'provider-2',
      recipientId: 'provider-1',
      recipientType: 'adoption_provider',
    },
  });
  assert.equal(plan.action, 'clear');
  assert.match(plan.reason, /provider alias conflicts/);
});

test('does not backfill requests with invalid lifecycle status', () => {
  const plan = planRecipientBackfill({
    ...common,
    requestData: {
      ...common.requestData,
      recipientId: 'provider-1',
      recipientType: 'adoption_provider',
      status: 'approved-by-client',
    },
  });
  assert.equal(plan.action, 'clear');
  assert.match(plan.reason, /status is invalid/);
});


test('preserves legacy closed requests when their listing and recipient are valid', () => {
  const plan = planRecipientBackfill({
    ...common,
    requestData: {
      ...common.requestData,
      status: 'closed',
    },
  });
  assert.equal(plan.action, 'update');
  assert.deepEqual(plan.fields, {
    recipientId: 'provider-1',
    recipientType: 'adoption_provider',
  });
});
