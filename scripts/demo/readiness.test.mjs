import assert from 'node:assert/strict';
import {test} from 'node:test';
import {spawnSync} from 'node:child_process';
import {fileURLToPath} from 'node:url';
import {requireDemoServices, waitForBookingFunction} from './readiness.mjs';

const ready = () => ({status: 401, json: async () => ({error: {status: 'UNAUTHENTICATED', message: 'Sign in to manage appointments.'}})});
const response = status => ({status, json: async () => ({})});
const options = (fetcher, extra = {}) => ({projectId: 'demo-petcare-isolated', host: '127.0.0.1:15001', fetcher, timeoutMs: 20, intervalMs: 1, ...extra});
const refusal = () => Object.assign(new TypeError('fetch failed'), {cause: {code: 'ECONNREFUSED'}});

test('expected callable rejection is ready immediately', async () => {
  let calls = 0;
  await waitForBookingFunction(options(async (url, init) => {
    calls++;
    assert.equal(url, 'http://127.0.0.1:15001/demo-petcare-isolated/asia-south2/reserveAppointmentSlot');
    assert.deepEqual(JSON.parse(init.body), {data: {}});
    return ready();
  }));
  assert.equal(calls, 1);
});

test('registration after 404 is accepted', async () => {
  let calls = 0;
  let clock = 0;
  await waitForBookingFunction(options(async () => ++calls < 3 ? response(404) : ready(),
    {now: () => clock, sleep: async ms => { clock += ms; }}));
  assert.equal(calls, 3);
});

test('connection refusal before registration is retried', async () => {
  let calls = 0;
  let clock = 0;
  await waitForBookingFunction(options(async () => { if (++calls === 1) throw refusal(); return ready(); },
    {now: () => clock, sleep: async ms => { clock += ms; }}));
  assert.equal(calls, 2);
});

test('missing callable times out with endpoint and last status', async () => {
  let clock = 0;
  await assert.rejects(waitForBookingFunction(options(async () => response(404), {
    now: () => clock, sleep: async ms => { clock += ms; }, timeoutMs: 3,
  })), /reserveAppointmentSlot after 3ms \(last: HTTP 404\); refusing reset/);
});

test('HTTP 500 fails immediately', async () => {
  let calls = 0;
  await assert.rejects(waitForBookingFunction(options(async () => { calls++; return response(500); })), /HTTP 500.*refusing reset/);
  assert.equal(calls, 1);
});

test('wrong project and function routes do not pass readiness', async () => {
  let clock = 0;
  await assert.rejects(waitForBookingFunction(options(async url => {
    assert.match(url, /demo-petcare-isolated\/asia-south2\/reserveAppointmentSlot$/);
    return response(404);
  }, {now: () => clock, sleep: async ms => { clock += ms; }, timeoutMs: 2})), /not ready/);
});

test('unrelated HTTP 401 cannot pass', async () => {
  const unrelated = async () => ({status: 401, json: async () => ({error: {status: 'UNAUTHENTICATED', message: 'Other service'}})});
  await assert.rejects(waitForBookingFunction(options(unrelated)), /Unexpected booking callable rejection/);
});

test('Auth and Firestore must return their emulator fingerprints', async () => {
  const fetcher = async url => url.includes('9099')
    ? {status: 200, json: async () => ({authEmulator: {ready: true}})}
    : {status: 200, text: async () => 'Ok\n'};
  await requireDemoServices({authHost: '127.0.0.1:9099', firestoreHost: '127.0.0.1:8080', fetcher});
  await assert.rejects(requireDemoServices({authHost: '127.0.0.1:9099', firestoreHost: '127.0.0.1:8080', fetcher: async url => url.includes('9099') ? fetcher(url) : response(404)}), /refusing reset/);
  await assert.rejects(requireDemoServices({authHost: '127.0.0.1:9099', firestoreHost: '127.0.0.1:8080', fetcher: async () => { throw refusal(); }}), /refusing reset/);
});

test('unsafe project or host configuration fails closed', async () => {
  for (const projectId of ['petcare-d4413', 'demo-petcare/other']) {
    await assert.rejects(waitForBookingFunction(options(async () => ready(), {projectId})), /Unsafe demo Functions project/);
  }
  await assert.rejects(waitForBookingFunction(options(async () => ready(), {host: 'example.com:5001'})), /Unsafe demo Functions project/);
});

test('network error output excludes request details', async () => {
  const secret = 'sensitive-token-value';
  await assert.rejects(waitForBookingFunction(options(async () => { throw new Error(secret); })), error => !error.message.includes(secret) && error.message.includes('refusing reset'));
});

test('validate-only does not require emulator readiness or a password', () => {
  const script = fileURLToPath(new URL('./seed_emulators.mjs', import.meta.url));
  const result = spawnSync(process.execPath, [script, '--validate-only'], {
    env: {...process.env, GCLOUD_PROJECT: 'unavailable-project', PETCARE_DEMO_PASSWORD: ''}, encoding: 'utf8',
  });
  assert.equal(result.status, 0);
  assert.match(result.stdout, /Validated 40 documents/);
});

test('incorrect project configuration fails before any reset without printing password', () => {
  const script = fileURLToPath(new URL('./seed_emulators.mjs', import.meta.url));
  const secret = 'private-test-password-123';
  const result = spawnSync(process.execPath, [script], {
    env: {...process.env, GCLOUD_PROJECT: 'petcare-d4413', PETCARE_DEMO_PASSWORD: secret}, encoding: 'utf8',
  });
  assert.equal(result.status, 1);
  assert.match(result.stderr, /Conflicting GCLOUD_PROJECT; refusing reset/);
  assert.doesNotMatch(result.stdout + result.stderr, /private-test-password-123/);
});
