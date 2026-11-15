import assert from 'node:assert/strict';
import {requireDemoServices, waitForBookingFunction} from './readiness.mjs';

// Explicit disposable endpoint only. Never accepts the real demo project or ports.
const projectId = 'demo-petcare-isolated';
const host = '127.0.0.1:15001';
await requireDemoServices({authHost: '127.0.0.1:19099', firestoreHost: '127.0.0.1:18080'});
await waitForBookingFunction({projectId, host, timeoutMs: 90_000});
const endpoint = `http://${host}/${projectId}/asia-south2/reserveAppointmentSlot`;
const response = await fetch(endpoint, {method: 'POST', headers: {'Content-Type': 'application/json'}, body: JSON.stringify({data: {}})});
assert.equal(response.status, 401);
assert.equal((await response.json()).error.status, 'UNAUTHENTICATED');
await assert.rejects(
  waitForBookingFunction({projectId: 'demo-petcare-absent', host, timeoutMs: 1500, intervalMs: 250}),
  /not ready.*reserveAppointmentSlot.*HTTP 404.*refusing reset/,
);
console.log('Isolated Auth, Firestore and asia-south2 booking callable are ready.');
