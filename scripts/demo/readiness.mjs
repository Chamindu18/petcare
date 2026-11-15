const expectedError = 'Sign in to manage appointments.';

export async function requireDemoServices({authHost, firestoreHost, fetcher = fetch}) {
  try {
    const [auth, firestore] = await Promise.all([
      fetcher(`http://${authHost}/`, {signal: AbortSignal.timeout(3000)}),
      fetcher(`http://${firestoreHost}/`, {signal: AbortSignal.timeout(3000)}),
    ]);
    const [authBody, firestoreBody] = await Promise.all([auth.json(), firestore.text()]);
    if (auth.status === 200 && authBody?.authEmulator?.ready === true &&
        firestore.status === 200 && firestoreBody.trim() === 'Ok') return;
  } catch { /* Fail closed with a stable, non-sensitive message. */ }
  throw new Error('Auth and Firestore emulators are unavailable or unexpected; refusing reset.');
}

export async function waitForBookingFunction({
  projectId, host, fetcher = fetch, sleep = ms => new Promise(resolve => setTimeout(resolve, ms)),
  now = () => Date.now(), timeoutMs = 90_000, intervalMs = 500, requestTimeoutMs = 3000,
}) {
  if (!/^demo-[a-z0-9-]+$/.test(projectId) || !/^127\.0\.0\.1:\d+$/.test(host)) {
    throw new Error('Unsafe demo Functions project or host; refusing reset.');
  }
  const endpoint = `http://${host}/${projectId}/asia-south2/reserveAppointmentSlot`;
  const deadline = now() + timeoutMs;
  let observed = 'no response';
  for (;;) {
    try {
      const response = await fetcher(endpoint, {
        method: 'POST', headers: {'Content-Type': 'application/json'},
        body: JSON.stringify({data: {}}), signal: AbortSignal.timeout(requestTimeoutMs),
      });
      observed = `HTTP ${response.status}`;
      if (response.status === 401) {
        let payload;
        try { payload = await response.json(); } catch { /* Incorrect callable response below. */ }
        if (payload?.error?.status === 'UNAUTHENTICATED' && payload.error.message === expectedError) return;
        throw new Error(`Unexpected booking callable rejection at ${endpoint} (${observed}); refusing reset.`);
      }
      if (response.status !== 404) {
        throw new Error(`Booking Function failed at ${endpoint} (${observed}); refusing reset.`);
      }
    } catch (error) {
      if (error.message?.includes('refusing reset.')) throw error;
      const cause = error.cause?.code;
      if (cause !== 'ECONNREFUSED' && cause !== 'ECONNRESET' && error.name !== 'TimeoutError') {
        throw new Error(`Booking Function request failed at ${endpoint} (${error.name}); refusing reset.`);
      }
      observed = cause ?? error.name;
    }
    const remaining = deadline - now();
    if (remaining <= 0) {
      throw new Error(`Booking Function is not ready at ${endpoint} after ${timeoutMs}ms (last: ${observed}); refusing reset.`);
    }
    await sleep(Math.min(intervalMs, remaining));
  }
}
