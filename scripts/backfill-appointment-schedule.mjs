// Read-only by default. Use --apply only after reviewing the dry-run counts.
import { pathToFileURL } from 'node:url';

export function scheduleForAppointment(data) {
  for (const key of ['vetId', 'hospitalId', 'serviceId', 'status']) {
    if (typeof data[key] !== 'string' || !data[key]) throw new Error(`Invalid ${key}`);
  }
  const date = data.dateTime;
  if (!(typeof date === 'string' && Number.isFinite(Date.parse(date))) &&
      !(date && typeof date.toDate === 'function' && Number.isFinite(date.toDate().getTime()))) {
    throw new Error('Invalid dateTime');
  }
  // A current service value cannot establish the historical duration of a
  // legacy appointment. Do not create a projection that appears authoritative
  // until its duration snapshot has been verified and backfilled separately.
  if (!Number.isInteger(data.durationMinutes) || data.durationMinutes <= 0 || data.durationMinutes > 1440) {
    throw new Error('Verified durationMinutes snapshot is required before projection backfill');
  }
  return Object.fromEntries(['vetId', 'hospitalId', 'serviceId', 'dateTime', 'status', 'durationMinutes']
    .filter(key => data[key] !== undefined).map(key => [key, data[key]]));
}

async function main() {
  const args = process.argv.slice(2);
  const index = args.indexOf('--project');
  const projectId = index >= 0 ? args[index + 1] : null;
  if (!projectId || projectId.startsWith('--')) throw new Error('--project is required');
  const { initializeApp, applicationDefault } = await import('firebase-admin/app');
  const { getFirestore } = await import('firebase-admin/firestore');
  initializeApp({projectId, credential: applicationDefault()});
  const db = getFirestore();
  const apply = args.includes('--apply');
  let cursor;
  let count = 0;
  // Fail a page before writing if any source document cannot be projected.
  while (true) {
    let query = db.collection('appointments').orderBy('__name__').limit(200);
    if (cursor) query = query.startAfter(cursor);
    const page = await query.get();
    if (page.empty) break;
    const entries = page.docs.map(document => ({document, schedule: scheduleForAppointment(document.data())}));
    if (apply) {
      // Read and write each source transactionally so a concurrent status or
      // reassignment cannot be overwritten by this migration's stale snapshot.
      for (const {document} of entries) {
        await db.runTransaction(async transaction => {
          const current = await transaction.get(document.ref);
          if (!current.exists) return;
          transaction.set(db.collection('appointment_schedule').doc(document.id),
            scheduleForAppointment(current.data()));
        });
      }
    }
    count += entries.length;
    cursor = page.docs.at(-1);
  }
  console.log(JSON.stringify({projectId, mode: apply ? 'apply' : 'dry-run', appointments: count}));
}

if (process.argv[1] && import.meta.url === pathToFileURL(process.argv[1]).href) {
  main().catch(error => { console.error(error.message); process.exitCode = 1; });
}
