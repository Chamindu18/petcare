// Operator-only IAM tool. Default is read-only; never import into the app.
const {readFileSync, writeFileSync, mkdirSync} = require('node:fs');
const {createHash} = require('node:crypto');
const auth = require('firebase-tools/lib/auth');
const {requireAuth} = require('firebase-tools/lib/requireAuth');
const {Client} = require('firebase-tools/lib/apiv2');
const project = 'petcare-d4413';
const root = `projects/${project}/databases/(default)`;
const planPath = 'build/veterinarian-link-plan.json';
const assert = (ok, message) => { if (!ok) throw new Error(message); };
const field = (doc, key) => doc.fields?.[key]?.stringValue;
const id = doc => doc.name.split('/').at(-1);
const digest = docs => createHash('sha256').update(JSON.stringify(docs
  .map(d => [d.name, d.updateTime]).sort((a,b) => a[0].localeCompare(b[0])))).digest('hex');

async function main() {
  const args = process.argv.slice(2);
  assert(args.length === 0 || (args.length === 2 && args[0] === '--apply'),
    'Usage: node scripts/repair-veterinarian-link.cjs [--apply APPROVAL_EVIDENCE]');
  const apply = args[0] === '--apply';
  assert(!apply || args[1].trim().length > 0, 'Approval evidence is required');
  const reviewed = apply ? JSON.parse(readFileSync(planPath, 'utf8')) : null;
  const options = {project};
  const account = auth.getProjectDefaultAccount(process.cwd());
  if (account) auth.setActiveAccount(options, account);
  await requireAuth(options);
  const fs = new Client({urlPrefix: 'https://firestore.googleapis.com', apiVersion: 'v1'});
  const identity = new Client({urlPrefix: 'https://identitytoolkit.googleapis.com', apiVersion: 'v1'});
  const {body: database} = await fs.get(root);
  assert(database.databaseEdition === 'STANDARD' && database.type === 'FIRESTORE_NATIVE', 'Unexpected database');
  const {body: begin} = await fs.post(`${root}/documents:beginTransaction`,
    {options: apply ? {readWrite: {}} : {readOnly: {}}});
  let transaction = begin.transaction;
  try {
    async function collection(collectionId) {
      const {body} = await fs.post(`${root}/documents:runQuery`, {
        transaction, structuredQuery: {from: [{collectionId}]},
      });
      return body.filter(row => row.document).map(row => row.document);
    }
    // Whole-collection transactional reads include conflicting roles and inactive entries.
    const users = await collection('users');
    const vets = await collection('veterinarians');
    const doctors = users.filter(u => field(u, 'role') === 'veterinarian');
    assert(doctors.length === 1, 'Expected exactly one existing test doctor; aborting ambiguous selection');
    const user = doctors[0], uid = id(user), vetId = field(user, 'vetId'), hospitalId = field(user, 'hospitalId');
    assert(vetId && hospitalId && hospitalId !== 'unassigned', 'Missing explicit assignment');
    assert(!vetId.includes('/') && !hospitalId.includes('/'), 'Invalid document IDs');
    assert(!user.fields?.uid || field(user, 'uid') === uid, 'Profile UID mismatch');
    const vet = vets.find(v => id(v) === vetId);
    assert(vet && vet.fields?.active?.booleanValue === true, 'Directory missing/inactive');
    assert(!vet.fields?.vetId || field(vet, 'vetId') === vetId, 'Canonical directory ID mismatch');
    assert(field(vet, 'hospitalId') === hospitalId, 'Hospital assignment mismatch');
    assert(!vet.fields?.userId || field(vet, 'userId') === uid, 'Directory already linked to another account');
    assert(!vets.some(v => id(v) !== vetId && field(v, 'userId') === uid), 'Another directory claims Auth UID');
    assert(!users.some(u => id(u) !== uid && (field(u, 'vetId') === vetId || id(u) === vetId)),
      'Conflicting explicit or UID-fallback profile references directory');
    const {body: hospitalRows} = await fs.post(`${root}/documents:batchGet`, {
      transaction, documents: [`${root}/documents/hospitals/${hospitalId}`],
    });
    const hospital = hospitalRows.find(row => row.found)?.found;
    assert(hospital?.fields?.active?.booleanValue === true, 'Hospital missing/inactive');
    const {body: identityResult} = await identity.post(`projects/${project}/accounts:lookup`, {localId: [uid]});
    const authUser = identityResult.users?.find(u => u.localId === uid);
    assert(authUser && !authUser.disabled, 'Auth UID missing or disabled');
    const plan = {project, database: '(default)', checkedAt: new Date().toISOString(),
      authUid: uid, profile: user.name, directory: vet.name, hospital: hospital.name,
      role: 'veterinarian', vetId, hospitalId,
      before: vet.fields?.userId ? {userId: field(vet, 'userId')} : {userId: '<absent>'},
      after: {userId: uid},
      checks: {authExistsAndEnabled: true, directoryActive: true, hospitalActive: true,
        hospitalMatches: true, otherDirectoryClaims: 0, conflictingProfiles: 0},
      baseline: digest([...users, ...vets, hospital])};
    if (!apply) {
      mkdirSync('build', {recursive: true});
      writeFileSync(planPath, JSON.stringify(plan, null, 2) + '\n');
      console.log(JSON.stringify(plan, null, 2));
      return;
    }
    assert(reviewed.project === project && reviewed.authUid === uid && reviewed.directory === vet.name &&
      reviewed.hospital === hospital.name && reviewed.after.userId === uid, 'Reviewed mapping changed');
    if (field(vet, 'userId') === uid) {
      console.log('Already linked; verified, no write.');
      return;
    }
    assert(reviewed.baseline === plan.baseline, 'Records changed since review; run dry-run and obtain renewed approval');
    // Only userId is in the update mask. Transaction plus updateTime protect concurrent changes.
    await fs.post(`${root}/documents:commit`, {transaction, writes: [{
      update: {name: vet.name, fields: {userId: {stringValue: uid}}},
      updateMask: {fieldPaths: ['userId']}, currentDocument: {updateTime: vet.updateTime},
    }]});
    transaction = null;
    const {body: updated} = await fs.get(vet.name);
    assert(field(updated, 'userId') === uid, 'Post-write verification failed');
    writeFileSync('build/veterinarian-link-receipt.json', JSON.stringify({
      ...plan, approvalEvidence: args[1], verifiedAt: new Date().toISOString(), updateTime: updated.updateTime,
    }, null, 2) + '\n');
    console.log('Single userId link committed and reread; local receipt saved. Retain Cloud Audit Logs.');
  } finally {
    if (transaction) await fs.post(`${root}/documents:rollback`, {transaction});
  }
}
main().catch(error => { console.error(error.message); process.exitCode = 1; });
