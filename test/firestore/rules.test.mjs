import firebase from 'firebase/compat/app';
import 'firebase/compat/firestore';
import { readFileSync } from 'node:fs';
import { fileURLToPath } from 'node:url';
import { dirname, resolve } from 'node:path';
import test, { before, beforeEach, after } from 'node:test';
import assert from 'node:assert/strict';
import {
  initializeTestEnvironment,
  assertSucceeds,
  assertFails,
} from '@firebase/rules-unit-testing';
import {
  collection,
  deleteDoc,
  doc,
  getDoc,
  getDocs,
  setDoc,
  updateDoc,
  query,
  where,
  orderBy,
  runTransaction,
  serverTimestamp,
  Timestamp,
} from 'firebase/firestore';

const __dirname = dirname(fileURLToPath(import.meta.url));
const projectId = 'demo-petcare';
const rules = readFileSync(resolve(__dirname, '../../firestore.rules'), 'utf8');
let env;

before(async () => {
  env = await initializeTestEnvironment({
    projectId,
    firestore: { rules },
  });
});

after(async () => {
  await env?.cleanup();
});

beforeEach(async () => {
  await env.clearFirestore();
  await env.withSecurityRulesDisabled(async (context) => {
    const db = context.firestore();
    await Promise.all([
      setDoc(doc(db, 'users/owner-1'), { uid: 'owner-1', role: 'owner' }),
      setDoc(doc(db, 'users/owner-2'), { uid: 'owner-2', role: 'owner' }),
      setDoc(doc(db, 'users/provider-1'), {
        uid: 'provider-1',
        role: 'adoption_provider',
      }),
      setDoc(doc(db, 'users/provider-2'), {
        uid: 'provider-2',
        role: 'adoption_provider',
      }),
    ]);
    await setDoc(doc(db, 'adoption_listings/owner-listing'), listing({
      ownerId: 'owner-1',
      ownerType: 'owner',
    }));
    await setDoc(doc(db, 'adoption_listings/provider-listing'), listing({
      ownerId: 'provider-1',
      ownerType: 'adoption_provider',
      providerId: 'provider-1',
    }));
    // A legacy provider listing has no canonical ownership metadata.
    await setDoc(doc(db, 'adoption_listings/legacy-provider-listing'), listing({
      providerId: 'provider-1',
      legacy: true,
    }));
  });
});

function listing({ ownerId, ownerType, providerId, legacy = false, status = 'available' } = {}) {
  const data = {
    petName: 'Buddy',
    species: 'Dog',
    gender: 'Male',
    description: 'Friendly dog looking for a home.',
    location: 'Colombo',
    status,
    createdAt: Timestamp.fromDate(new Date('2026-10-01T10:00:00Z')),
    updatedAt: Timestamp.fromDate(new Date('2026-10-01T10:00:00Z')),
  };
  if (legacy) {
    data.providerId = providerId;
    return data;
  }
  data.listingOwnerType = ownerType;
  data.listingOwnerId = ownerId;
  if (providerId) data.providerId = providerId;
  return data;
}

function requestData({
  requesterId = 'owner-2',
  listingId = 'provider-listing',
  recipientId = 'provider-1',
  recipientType = 'adoption_provider',
  providerId = recipientType === 'adoption_provider' ? recipientId : undefined,
  status = 'pending',
} = {}) {
  return {
    listingId,
    requesterId,
    ...(providerId ? { providerId } : {}),
    recipientId,
    recipientType,
    message: 'I would like to adopt this pet.',
    status,
    submittedAt: Timestamp.fromDate(new Date('2026-10-10T10:00:00Z')),
    updatedAt: Timestamp.fromDate(new Date('2026-10-10T10:00:00Z')),
  };
}

async function seedRequest(id = 'request-1', data = requestData()) {
  await env.withSecurityRulesDisabled(async (context) => {
    await setDoc(doc(context.firestore(), `adoption_requests/${id}`), data);
  });
}

function authed(uid) {
  return env.authenticatedContext(uid).firestore();
}

async function acceptRequestAtomically(db, requestId, listingId) {
  const requestReference = doc(
    db,
    `adoption_requests/${requestId}`,
  );
  const listingReference = doc(
    db,
    `adoption_listings/${listingId}`,
  );

  await runTransaction(db, async (transaction) => {
    const requestSnapshot = await transaction.get(requestReference);
    const listingSnapshot = await transaction.get(listingReference);

    assert.ok(requestSnapshot.exists(), `Missing request: ${requestId}`);
    assert.ok(listingSnapshot.exists(), `Missing listing: ${listingId}`);

    transaction.update(listingReference, {
      status: 'reserved',
      acceptedRequestId: requestId,
      updatedAt: serverTimestamp(),
    });

    transaction.update(requestReference, {
      status: 'accepted',
      acceptedAt: serverTimestamp(),
      updatedAt: serverTimestamp(),
    });
  });
}

test('owners cannot create or manage adoption listings', async () => {
  const db = authed('owner-2');

  // Regular owners cannot create advertisements.
  await assertFails(setDoc(doc(db, 'adoption_listings/owner-new'), {
    ...listing({ ownerId: 'owner-2', ownerType: 'owner' }),
    createdAt: serverTimestamp(),
    updatedAt: serverTimestamp(),
  }));

  // Regular owners cannot edit even a listing assigned to their own UID.
  await assertFails(updateDoc(doc(authed('owner-1'), 'adoption_listings/owner-listing'), {
    description: 'Owner must not manage adoption advertisements',
    updatedAt: serverTimestamp(),
  }));

  // Regular owners cannot edit another user's listing either.
  await assertFails(updateDoc(doc(db, 'adoption_listings/owner-listing'), {
    description: 'Trying to edit another owner listing',
    updatedAt: serverTimestamp(),
  }));
});

test('owner cannot create a provider listing or claim provider identity', async () => {
  const db = authed('owner-2');
  await assertFails(setDoc(doc(db, 'adoption_listings/forged-provider'), {
    ...listing({ ownerId: 'owner-2', ownerType: 'adoption_provider', providerId: 'owner-2' }),
    createdAt: serverTimestamp(),
    updatedAt: serverTimestamp(),
  }));
  await assertFails(setDoc(doc(db, 'adoption_listings/forged-legacy-provider'), {
    providerId: 'owner-2',
    petName: 'Forged',
    species: 'Dog',
    gender: 'Male',
    description: 'Owner trying to use provider compatibility path.',
    location: 'Colombo',
    status: 'available',
    createdAt: Timestamp.fromDate(new Date('2026-10-12T10:00:00Z')),
    updatedAt: Timestamp.fromDate(new Date('2026-10-12T10:00:00Z')),
  }));
});

test('older provider clients can still create a legacy provider listing', async () => {
  const db = authed('provider-2');
  await assertSucceeds(setDoc(doc(db, 'adoption_listings/legacy-new-listing'), {
    providerId: 'provider-2',
    petName: 'Luna',
    species: 'Cat',
    gender: 'Female',
    description: 'A calm cat looking for a home.',
    location: 'Kandy',
    status: 'available',
    createdAt: Timestamp.fromDate(new Date('2026-10-12T10:00:00Z')),
    updatedAt: Timestamp.fromDate(new Date('2026-10-12T10:00:00Z')),
  }));
});

test('provider can continue managing a legacy provider listing', async () => {
  const db = authed('provider-1');
  await assertSucceeds(updateDoc(doc(db, 'adoption_listings/legacy-provider-listing'), {
    ...listing({ ownerId: 'provider-1', ownerType: 'adoption_provider', providerId: 'provider-1' }),
    createdAt: Timestamp.fromDate(new Date('2026-10-01T10:00:00Z')),
    updatedAt: serverTimestamp(),
  }));
});

test('older provider clients can update a canonical provider listing without changing ownership', async () => {
  const db = authed('provider-1');
  await assertSucceeds(updateDoc(doc(db, 'adoption_listings/provider-listing'), {
    providerId: 'provider-1',
    petName: 'Buddy Updated',
    species: 'Dog',
    gender: 'Male',
    description: 'Updated details from an older client.',
    location: 'Colombo',
    status: 'available',
    createdAt: Timestamp.fromDate(new Date('2026-10-01T10:00:00Z')),
    updatedAt: Timestamp.fromDate(new Date('2026-10-20T10:00:00Z')),
  }));
  const updated = await getDoc(doc(db, 'adoption_listings/provider-listing'));
  assert.equal(updated.data().listingOwnerType, 'adoption_provider');
  assert.equal(updated.data().listingOwnerId, 'provider-1');
});

test('owner can submit a request to an available provider listing', async () => {
  const db = authed('owner-2');
  await assertSucceeds(setDoc(doc(db, 'adoption_requests/owner-to-provider'), {
    listingId: 'provider-listing',
    requesterId: 'owner-2',
    providerId: 'provider-1',
    recipientId: 'provider-1',
    recipientType: 'adoption_provider',
    message: 'Hello!',
    status: 'pending',
    submittedAt: serverTimestamp(),
    updatedAt: serverTimestamp(),
  }));
});

test('older clients can still submit a validated legacy provider request', async () => {
  const db = authed('owner-2');
  await assertSucceeds(setDoc(doc(db, 'adoption_requests/legacy-new-request'), {
    listingId: 'provider-listing',
    requesterId: 'owner-2',
    providerId: 'provider-1',
    message: 'Hello from an older client.',
    status: 'pending',
    submittedAt: serverTimestamp(),
    updatedAt: serverTimestamp(),
  }));
  await assertFails(setDoc(doc(db, 'adoption_requests/legacy-wrong-provider'), {
    listingId: 'provider-listing',
    requesterId: 'owner-2',
    providerId: 'provider-2',
    message: 'Mismatched recipient.',
    status: 'pending',
    submittedAt: serverTimestamp(),
    updatedAt: serverTimestamp(),
  }));
});

test('owner cannot submit a request to an owner-owned listing', async () => {
  const db = authed('owner-2');

  await assertFails(setDoc(doc(db, 'adoption_requests/owner-to-owner'), {
    listingId: 'owner-listing',
    requesterId: 'owner-2',
    recipientId: 'owner-1',
    recipientType: 'owner',
    message: 'Hello!',
    status: 'pending',
    submittedAt: serverTimestamp(),
    updatedAt: serverTimestamp(),
  }));
});

test('request creation is denied for unavailable listing, mismatched recipient, or self-request', async () => {
  await env.withSecurityRulesDisabled(async (context) => {
    await updateDoc(doc(context.firestore(), 'adoption_listings/provider-listing'), {
      status: 'draft',
    });
  });
  const db = authed('owner-2');
  await assertFails(setDoc(doc(db, 'adoption_requests/unavailable'), {
    ...requestData(),
    submittedAt: serverTimestamp(),
    updatedAt: serverTimestamp(),
  }));
  await env.withSecurityRulesDisabled(async (context) => {
    await updateDoc(doc(context.firestore(), 'adoption_listings/provider-listing'), {
      status: 'available',
    });
  });
  await assertFails(setDoc(doc(db, 'adoption_requests/mismatch'), {
    ...requestData({ recipientId: 'provider-2', providerId: 'provider-2' }),
    submittedAt: serverTimestamp(),
    updatedAt: serverTimestamp(),
  }));
  await assertFails(setDoc(doc(authed('owner-1'), 'adoption_requests/self'), {
    listingId: 'owner-listing',
    requesterId: 'owner-1',
    recipientId: 'owner-1',
    recipientType: 'owner',
    status: 'pending',
    submittedAt: serverTimestamp(),
    updatedAt: serverTimestamp(),
  }));
});


test('provider accounts cannot submit owner adoption requests', async () => {
  const db = authed('provider-1');
  await assertFails(setDoc(doc(db, 'adoption_requests/provider-cannot-request'), {
    listingId: 'owner-listing',
    requesterId: 'provider-1',
    recipientId: 'owner-1',
    recipientType: 'owner',
    status: 'pending',
    submittedAt: serverTimestamp(),
    updatedAt: serverTimestamp(),
  }));
});

test('a requester cannot withdraw after a provider decision', async () => {
  await seedRequest('already-accepted', requestData({ status: 'accepted' }));
  await assertFails(updateDoc(doc(authed('owner-2'), 'adoption_requests/already-accepted'), {
    status: 'withdrawn',
    updatedAt: serverTimestamp(),
    closedAt: serverTimestamp(),
  }));
});

test('only the requester may withdraw a pending request; record is retained', async () => {
  await seedRequest();
  const requesterDb = authed('owner-2');

  await assertSucceeds(
    updateDoc(doc(requesterDb, 'adoption_requests/request-1'), {
      status: 'withdrawn',
      updatedAt: serverTimestamp(),
      closedAt: serverTimestamp(),
    }),
  );

  const retained = await getDoc(
    doc(requesterDb, 'adoption_requests/request-1'),
  );
  assert.equal(retained.exists(), true);
  assert.equal(retained.data().status, 'withdrawn');

  await assertFails(
    deleteDoc(doc(requesterDb, 'adoption_requests/request-1')),
  );
});

test('provider drafts are readable only by their provider', async () => {
  await env.withSecurityRulesDisabled(async (context) => {
    await setDoc(
      doc(context.firestore(), 'adoption_listings/provider-draft'),
      listing({
        ownerId: 'provider-1',
        ownerType: 'adoption_provider',
        providerId: 'provider-1',
        status: 'draft',
      }),
    );
  });

  await assertSucceeds(
    getDoc(doc(authed('provider-1'), 'adoption_listings/provider-draft')),
  );

  await assertFails(
    getDoc(doc(authed('provider-2'), 'adoption_listings/provider-draft')),
  );

  await assertFails(
    getDoc(doc(authed('owner-2'), 'adoption_listings/provider-draft')),
  );

  // Regular users can still read published listings.
  await assertSucceeds(
    getDoc(doc(authed('owner-2'), 'adoption_listings/provider-listing')),
  );

  // Verify the same query used by watchMyListings().
  const providerListingsQuery = query(
    collection(authed('provider-1'), 'adoption_listings'),
    where('providerId', '==', 'provider-1'),
    orderBy('createdAt', 'desc'),
  );

  const providerListingsSnapshot = await assertSucceeds(
    getDocs(providerListingsQuery),
  );

  assert.ok(
    providerListingsSnapshot.docs.some(
      (document) => document.id === 'provider-draft',
    ),
    'The provider query should include the provider draft.',
  );
});

test('listing owners cannot hard-delete listing documents', async () => {
  await assertFails(
    deleteDoc(doc(authed('owner-1'), 'adoption_listings/owner-listing')),
  );

  const retained = await getDoc(
    doc(authed('owner-1'), 'adoption_listings/owner-listing'),
  );

  assert.equal(retained.exists(), true);
});


test('withdrawal cannot alter unrelated fields or withdraw another user request', async () => {
  await seedRequest();
  const requesterDb = authed('owner-2');
  await assertFails(updateDoc(doc(requesterDb, 'adoption_requests/request-1'), {
    status: 'withdrawn',
    message: 'Tampered message',
    updatedAt: serverTimestamp(),
    closedAt: serverTimestamp(),
  }));
  await assertFails(updateDoc(doc(authed('owner-1'), 'adoption_requests/request-1'), {
    status: 'withdrawn',
    updatedAt: serverTimestamp(),
    closedAt: serverTimestamp(),
  }));
});

test('owners cannot decide requests for adoption listings', async () => {
  await seedRequest('owner-recipient', requestData({
    listingId: 'owner-listing',
    recipientId: 'owner-1',
    recipientType: 'owner',
    providerId: undefined,
  }));

  const db = authed('owner-1');

  await assertFails(
    acceptRequestAtomically(db, 'owner-recipient', 'owner-listing'),
  );

  // The requester can still read their own request.
  const requestSnapshot = await getDoc(
    doc(authed('owner-2'), 'adoption_requests/owner-recipient'),
  );

  const listingSnapshot = await getDoc(
    doc(authed('owner-2'), 'adoption_listings/owner-listing'),
  );

  assert.equal(requestSnapshot.data()?.status, 'pending');
  assert.equal(listingSnapshot.data()?.status, 'available');
});

test('provider acceptance must be atomic; unrelated providers are denied', async () => {
  await seedRequest();

  const requestReference = doc(
    authed('provider-1'),
    'adoption_requests/request-1',
  );

  await assertFails(
    updateDoc(
      doc(authed('provider-2'), 'adoption_requests/request-1'),
      {
        status: 'accepted',
        acceptedAt: serverTimestamp(),
        updatedAt: serverTimestamp(),
      },
    ),
  );

  // A request cannot be accepted without reserving its listing.
  await assertFails(
    updateDoc(requestReference, {
      status: 'accepted',
      acceptedAt: serverTimestamp(),
      updatedAt: serverTimestamp(),
    }),
  );

  // The authorized provider can accept when both changes are atomic.
  await assertSucceeds(
    acceptRequestAtomically(
      authed('provider-1'),
      'request-1',
      'provider-listing',
    ),
  );
});

test('acceptance requires an available listing; rejection remains allowed for unavailable listings', async () => {
  const cases = [
    { listingId: 'draft-provider-listing', status: 'draft' },
    // This is an arbitrary non-available persisted value used to verify the
    // rule checks specifically for `available`; it does not add a supported
    // client-facing listing status to the app contract.
    { listingId: 'paused-provider-listing', status: 'paused' },
  ];

  await env.withSecurityRulesDisabled(async (context) => {
    const db = context.firestore();
    for (const item of cases) {
      await setDoc(doc(db, `adoption_listings/${item.listingId}`), {
        ...listing({
          ownerId: 'provider-1',
          ownerType: 'adoption_provider',
          providerId: 'provider-1',
          status: item.status,
        }),
      });
    }
  });
  for (const item of cases) {
    await seedRequest(`${item.status}-accept`, requestData({ listingId: item.listingId }));
    await seedRequest(`${item.status}-reject`, requestData({ listingId: item.listingId }));
  }

  const providerDb = authed('provider-1');
  for (const item of cases) {
    await assertFails(updateDoc(doc(providerDb, `adoption_requests/${item.status}-accept`), {
      status: 'accepted',
      acceptedAt: serverTimestamp(),
      updatedAt: serverTimestamp(),
    }));
    await assertSucceeds(updateDoc(doc(providerDb, `adoption_requests/${item.status}-reject`), {
      status: 'rejected',
      closedAt: serverTimestamp(),
      updatedAt: serverTimestamp(),
    }));
  }
});

test('only one request can be accepted for a listing', async () => {
  await seedRequest('first-request');
  await seedRequest('second-request');

  const db = authed('provider-1');

  await assertSucceeds(
    acceptRequestAtomically(db, 'first-request', 'provider-listing'),
  );

  await assertFails(
    acceptRequestAtomically(db, 'second-request', 'provider-listing'),
  );

  const listingSnapshot = await getDoc(
    doc(db, 'adoption_listings/provider-listing'),
  );
  const firstRequestSnapshot = await getDoc(
    doc(db, 'adoption_requests/first-request'),
  );
  const secondRequestSnapshot = await getDoc(
    doc(db, 'adoption_requests/second-request'),
  );

  assert.equal(listingSnapshot.data()?.status, 'reserved');
  assert.equal(
    listingSnapshot.data()?.acceptedRequestId,
    'first-request',
  );
  assert.equal(firstRequestSnapshot.data()?.status, 'accepted');
  assert.equal(secondRequestSnapshot.data()?.status, 'pending');
});

test('backfilled legacy provider requests retain the provider decision path', async () => {
  // Represents the trusted migration output for a valid legacy request.
  await seedRequest('backfilled-legacy-request', {
    listingId: 'legacy-provider-listing',
    requesterId: 'owner-2',
    providerId: 'provider-1',
    recipientId: 'provider-1',
    recipientType: 'adoption_provider',
    message: 'Legacy request data',
    status: 'pending',
    submittedAt: Timestamp.fromDate(new Date('2026-10-10T10:00:00Z')),
    updatedAt: Timestamp.fromDate(new Date('2026-10-10T10:00:00Z')),
  });
  await assertSucceeds(updateDoc(doc(authed('provider-1'), 'adoption_requests/backfilled-legacy-request'), {
    status: 'rejected',
    closedAt: serverTimestamp(),
    updatedAt: serverTimestamp(),
  }));
});

test('only verified/backfilled legacy requests appear in provider inboxes', async () => {
  // Represents a valid legacy request after the trusted backfill checked its
  // referenced listing and copied the verified recipient to canonical fields.
  await seedRequest('legacy-valid-backfilled', {
    listingId: 'legacy-provider-listing',
    requesterId: 'owner-2',
    providerId: 'provider-1',
    recipientId: 'provider-1',
    recipientType: 'adoption_provider',
    message: 'Verified legacy request',
    status: 'pending',
    submittedAt: Timestamp.fromDate(new Date('2026-10-10T10:00:00Z')),
    updatedAt: Timestamp.fromDate(new Date('2026-10-10T10:00:00Z')),
  });

  // Unbackfilled requests are intentionally left without canonical recipient
  // fields, so a provider query cannot return them.
  await seedRequest('legacy-valid-not-yet-backfilled', {
    listingId: 'legacy-provider-listing',
    requesterId: 'owner-2',
    providerId: 'provider-1',
    message: 'Awaiting trusted backfill',
    status: 'pending',
    submittedAt: Timestamp.fromDate(new Date('2026-10-10T10:00:00Z')),
    updatedAt: Timestamp.fromDate(new Date('2026-10-10T10:00:00Z')),
  });
  await seedRequest('legacy-missing-listing', {
    listingId: 'listing-does-not-exist',
    requesterId: 'owner-2',
    providerId: 'provider-1',
    status: 'pending',
    submittedAt: Timestamp.fromDate(new Date('2026-10-10T10:00:00Z')),
    updatedAt: Timestamp.fromDate(new Date('2026-10-10T10:00:00Z')),
  });
  await seedRequest('legacy-mismatched-provider', {
    listingId: 'provider-listing',
    requesterId: 'owner-2',
    providerId: 'provider-2',
    status: 'pending',
    submittedAt: Timestamp.fromDate(new Date('2026-10-10T10:00:00Z')),
    updatedAt: Timestamp.fromDate(new Date('2026-10-10T10:00:00Z')),
  });

  const providerQuery = query(
    collection(authed('provider-1'), 'adoption_requests'),
    where('recipientId', '==', 'provider-1'),
    where('recipientType', '==', 'adoption_provider'),
    orderBy('submittedAt', 'desc'),
  );
  const providerSnapshot = await assertSucceeds(getDocs(providerQuery));
  assert.deepEqual(providerSnapshot.docs.map((item) => item.id), ['legacy-valid-backfilled']);

  await assertFails(getDoc(doc(authed('provider-1'), 'adoption_requests/legacy-valid-not-yet-backfilled')));
  await assertFails(getDoc(doc(authed('provider-1'), 'adoption_requests/legacy-missing-listing')));
  await assertFails(getDoc(doc(authed('provider-2'), 'adoption_requests/legacy-mismatched-provider')));
  // Requesters retain access to their own historical records.
  await assertSucceeds(getDoc(doc(authed('owner-2'), 'adoption_requests/legacy-valid-not-yet-backfilled')));
});

test('recipient cannot modify request relationships or decide a non-pending request', async () => {
  await seedRequest();
  const db = authed('provider-1');
  await assertFails(updateDoc(doc(db, 'adoption_requests/request-1'), {
    status: 'accepted',
    requesterId: 'provider-1',
    acceptedAt: serverTimestamp(),
    updatedAt: serverTimestamp(),
  }));
  await env.withSecurityRulesDisabled(async (context) => {
    await updateDoc(doc(context.firestore(), 'adoption_requests/request-1'), {
      status: 'withdrawn',
    });
  });
  await assertFails(updateDoc(doc(db, 'adoption_requests/request-1'), {
    status: 'accepted',
    acceptedAt: serverTimestamp(),
    updatedAt: serverTimestamp(),
  }));
});


test('requesters and providers can query their own adoption requests', async () => {
  await seedRequest('provider-request', requestData());

  // Regular owners track requests they submitted.
  const ownerQuery = query(
    collection(authed('owner-2'), 'adoption_requests'),
    where('requesterId', '==', 'owner-2'),
    orderBy('submittedAt', 'desc'),
  );

  // Providers view requests addressed to their advertisements.
  const providerQuery = query(
    collection(authed('provider-1'), 'adoption_requests'),
    where('recipientId', '==', 'provider-1'),
    where('recipientType', '==', 'adoption_provider'),
    orderBy('submittedAt', 'desc'),
  );

  const ownerSnapshot = await assertSucceeds(getDocs(ownerQuery));
  const providerSnapshot = await assertSucceeds(getDocs(providerQuery));

  assert.deepEqual(
    ownerSnapshot.docs.map((item) => item.id),
    ['provider-request'],
  );

  assert.deepEqual(
    providerSnapshot.docs.map((item) => item.id),
    ['provider-request'],
  );
});

test('only requester or authorized listing recipient can read a request', async () => {
  await seedRequest();
  await assertSucceeds(getDoc(doc(authed('owner-2'), 'adoption_requests/request-1')));
  await assertSucceeds(getDoc(doc(authed('provider-1'), 'adoption_requests/request-1')));
  await assertFails(getDoc(doc(authed('provider-2'), 'adoption_requests/request-1')));
});
