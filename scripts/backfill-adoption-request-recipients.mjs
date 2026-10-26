import { applicationDefault, initializeApp } from 'firebase-admin/app';
import { FieldValue, getFirestore } from 'firebase-admin/firestore';
import { planRecipientBackfill } from './lib/adoption-recipient-backfill-plan.mjs';

function parseArgs(argv) {
  const options = { projectId: null, apply: false };
  for (let index = 0; index < argv.length; index += 1) {
    const arg = argv[index];
    if (arg === '--project') {
      options.projectId = argv[index + 1] ?? null;
      index += 1;
    } else if (arg === '--apply') {
      options.apply = true;
    } else if (arg === '--help' || arg === '-h') {
      options.help = true;
    } else {
      throw new Error(`Unknown argument: ${arg}`);
    }
  }
  return options;
}

function printUsage() {
  console.log(`Trusted adoption request recipient backfill

Dry run (default):
  npm run backfill:adoption-request-recipients -- --project petcare-d4413

Apply changes after reviewing the dry-run and creating a Firestore backup:
  npm run backfill:adoption-request-recipients -- --project petcare-d4413 --apply

Credentials must be supplied through Application Default Credentials, for example
GOOGLE_APPLICATION_CREDENTIALS pointing to a secured service-account key outside the repository.
Never put credential files in this project or review ZIP.`);
}

const options = parseArgs(process.argv.slice(2));
if (options.help) {
  printUsage();
  process.exit(0);
}
if (!options.projectId) {
  printUsage();
  throw new Error('--project is required to prevent running against an unintended database.');
}
if (options.apply && process.env.CONFIRM_ADOPTION_RECIPIENT_BACKFILL !== 'yes') {
  throw new Error('For apply mode, set CONFIRM_ADOPTION_RECIPIENT_BACKFILL=yes after reviewing the dry run and taking a backup.');
}

const app = initializeApp({
  credential: applicationDefault(),
  projectId: options.projectId,
});
const db = getFirestore(app);

const usersCache = new Map();
const listingsCache = new Map();
const getCachedDocData = (cache, collectionName, id) => {
  if (!id || typeof id !== 'string') return Promise.resolve(null);
  if (!cache.has(id)) {
    cache.set(id, db.collection(collectionName).doc(id).get()
      .then((snapshot) => snapshot.exists ? snapshot.data() : null));
  }
  return cache.get(id);
};

const summary = { scanned: 0, backfilled: 0, alreadyValid: 0, cleared: 0, skipped: 0 };
const writes = [];
try {
  const snapshot = await db.collection('adoption_requests').get();
  summary.scanned = snapshot.size;

  for (const requestSnapshot of snapshot.docs) {
    const requestData = requestSnapshot.data();
    const listingId = requestData.listingId;
    const listingData = await getCachedDocData(listingsCache, 'adoption_listings', listingId);
    const requesterData = await getCachedDocData(usersCache, 'users', requestData.requesterId);
    const recipientId = listingData?.listingOwnerId ??
      ((listingData?.listingOwnerType ?? 'adoption_provider') === 'adoption_provider'
        ? listingData?.providerId
        : null);
    const recipientData = await getCachedDocData(usersCache, 'users', recipientId);
    const plan = planRecipientBackfill({
      requestData,
      listingData,
      listingExists: listingData != null,
      requesterRole: requesterData?.role,
      recipientRole: recipientData?.role,
    });

    if (plan.action === 'skip') {
      if (plan.reason === 'recipient metadata already valid') summary.alreadyValid += 1;
      else summary.skipped += 1;
      continue;
    }

    if (plan.action === 'update') {
      summary.backfilled += 1;
      writes.push({ ref: requestSnapshot.ref, update: plan.fields, id: requestSnapshot.id, reason: plan.reason });
      console.log(`[BACKFILL] ${requestSnapshot.id}: ${plan.reason}`);
    } else if (plan.action === 'clear') {
      summary.cleared += 1;
      writes.push({
        ref: requestSnapshot.ref,
        update: { recipientId: FieldValue.delete(), recipientType: FieldValue.delete() },
        id: requestSnapshot.id,
        reason: plan.reason,
      });
      console.log(`[CLEAR recipient metadata] ${requestSnapshot.id}: ${plan.reason}`);
    }
  }

  console.log(`\nProject: ${options.projectId}`);
  console.log(`Mode: ${options.apply ? 'APPLY' : 'DRY RUN (no writes)'}`);
  console.log(JSON.stringify(summary, null, 2));
  console.log(`Planned write operations: ${writes.length}`);

  if (options.apply) {
    for (let offset = 0; offset < writes.length; offset += 400) {
      const batch = db.batch();
      for (const operation of writes.slice(offset, offset + 400)) {
        batch.update(operation.ref, operation.update);
      }
      await batch.commit();
      console.log(`Committed ${Math.min(offset + 400, writes.length)} of ${writes.length} planned writes.`);
    }
    console.log('Backfill completed. Rerun dry-run to verify no remaining changes are planned.');
  }
} finally {
  await app.delete();
}
