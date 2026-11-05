const {test} = require('node:test');
const assert = require('node:assert/strict');
const {readFileSync} = require('node:fs');
const vm = require('node:vm');
const source = readFileSync('scripts/repair-veterinarian-link.cjs', 'utf8')
  .replace(/main\(\)\.catch[\s\S]*$/, 'globalThis.run = main;');
const root = 'projects/petcare-d4413/databases/(default)/documents';
const str = stringValue => ({stringValue});
const doc = (path, fields) => ({name: `${root}/${path}`, updateTime: '2026-01-01T00:00:00Z', fields});
async function scenario(change = () => {}, apply = false) {
  const state = {users: [doc('users/uid', {role: str('veterinarian'), vetId: str('vet'), hospitalId: str('hospital')})],
    veterinarians: [doc('veterinarians/vet', {active: {booleanValue: true}, hospitalId: str('hospital')})],
    hospital: doc('hospitals/hospital', {active: {booleanValue: true}}), writes: [], files: {}, rollbacks: 0};
  const context = {console: {log() {}, error() {}}, process: {argv: ['node', 'script'], cwd: () => '.'},
    require(name) {
      if (name === 'node:fs') return {mkdirSync() {}, readFileSync: p => state.files[p], writeFileSync: (p,v) => state.files[p] = v};
      if (name === 'node:crypto') return require(name);
      if (name.endsWith('/auth')) return {getProjectDefaultAccount() {}};
      if (name.endsWith('/requireAuth')) return {requireAuth: async () => {}};
      if (name.endsWith('/apiv2')) return {Client: class {
        async get() { return {body: {databaseEdition: 'STANDARD', type: 'FIRESTORE_NATIVE'}}; }
        async post(path, body) {
          if (path.endsWith(':beginTransaction')) return {body: {transaction: 'txn'}};
          if (path.endsWith(':runQuery')) return {body: state[body.structuredQuery.from[0].collectionId].map(document => ({document}))};
          if (path.endsWith(':batchGet')) return {body: [{found: state.hospital}]};
          if (path.endsWith(':lookup')) return {body: {users: [{localId: 'uid'}]}};
          if (path.endsWith(':rollback')) { state.rollbacks++; return {}; }
          if (path.endsWith(':commit')) { state.writes.push(...body.writes); throw new Error('SIMULATED_COMMIT'); }
          throw new Error(`Unexpected call ${path}`);
        }
      }};
      throw new Error(`Unexpected dependency ${name}`);
    }};
  vm.createContext(context); vm.runInContext(source, context);
  await context.run(); // establish reviewed dry-run baseline
  assert.equal(state.writes.length, 0);
  change(state);
  if (apply) context.process.argv.push('--apply', 'approved change ticket');
  await context.run();
  return state;
}
test('dry-run performs no writes and rolls back snapshots', async () => {
  const state = await scenario(); assert.equal(state.writes.length, 0); assert.equal(state.rollbacks, 2);
});
test('duplicate directory claim aborts', async () => {
  await assert.rejects(scenario(s => s.veterinarians.push(doc('veterinarians/other', {userId: str('uid')})), true), /Another directory claims/);
});
test('conflicting user of any role aborts', async () => {
  await assert.rejects(scenario(s => s.users.push(doc('users/other', {role: str('petOwner'), vetId: str('vet')})), true), /Conflicting/);
});
test('changed review baseline aborts', async () => {
  await assert.rejects(scenario(s => s.hospital.updateTime = 'new version', true), /Records changed/);
});
test('inactive directory aborts', async () => {
  await assert.rejects(scenario(s => s.veterinarians[0].fields.active.booleanValue = false, true), /Directory missing\/inactive/);
});
test('mismatched hospital aborts', async () => {
  await assert.rejects(scenario(s => s.veterinarians[0].fields.hospitalId = str('other'), true), /Hospital assignment mismatch/);
});
test('already matching link is idempotent', async () => {
  const state = await scenario(s => s.veterinarians[0].fields.userId = str('uid'), true);
  assert.equal(state.writes.length, 0);
});
test('apply prepares only single field with transaction precondition', async () => {
  let captured;
  await assert.rejects(scenario(s => { captured = s; }, true), /SIMULATED_COMMIT/);
  assert.equal(captured.writes.length, 1);
  const write = captured.writes[0];
  assert.equal(write.update.name, `${root}/veterinarians/vet`);
  assert.equal(JSON.stringify(write.updateMask.fieldPaths), '["userId"]');
  assert.equal(JSON.stringify(write.update.fields), '{"userId":{"stringValue":"uid"}}');
  assert.equal(write.currentDocument.updateTime, '2026-01-01T00:00:00Z');
});
