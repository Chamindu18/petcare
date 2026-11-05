// Read-only diagnostic: no API enablement, billing changes, or document writes.
const {writeFileSync} = require('node:fs');
const auth = require('firebase-tools/lib/auth');
const {requireAuth} = require('firebase-tools/lib/requireAuth');
const {Client} = require('firebase-tools/lib/apiv2');
const project = 'petcare-d4413';
const report = {project, checkedAt: new Date().toISOString(), checks: {}};
async function check(name, operation) {
  try { report.checks[name] = {ok: true, result: await operation()}; }
  catch (error) {
    const body = error.context?.body?.error;
    report.checks[name] = {ok: false, message: error.message,
      code: body?.code, status: body?.status, details: body?.details};
  }
}
async function main() {
  const options = {project};
  const account = auth.getProjectDefaultAccount(process.cwd());
  if (account) auth.setActiveAccount(options, account);
  await requireAuth(options);
  const get = async (origin, path, version = 'v1') =>
    (await new Client({urlPrefix: origin, apiVersion: version}).get(path)).body;
  await check('functionsApi', async () => {
    const body = await get('https://serviceusage.googleapis.com', `projects/${project}/services/cloudfunctions.googleapis.com`);
    return {state: body.state};
  });
  await check('billing', async () => {
    const body = await get('https://cloudbilling.googleapis.com', `projects/${project}/billingInfo`);
    return {billingEnabled: body.billingEnabled};
  });
  await check('functions', async () => {
    const body = await get('https://cloudfunctions.googleapis.com', `projects/${project}/locations/asia-south2/functions`, 'v2');
    return (body.functions || []).map(f => ({name: f.name, state: f.state,
      entryPoint: f.buildConfig?.entryPoint, runtime: f.buildConfig?.runtime}));
  });
  await check('legacyAppointments', async () => {
    const root = `projects/${project}/databases/(default)/documents`;
    const decode = v => v?.stringValue ?? v?.integerValue ?? v?.timestampValue ?? v?.booleanValue ?? null;
    const fields = d => Object.fromEntries(Object.entries(d.fields || {}).map(([k,v]) => [k, decode(v)]));
    const body = await get('https://firestore.googleapis.com', `${root}/appointments?pageSize=100`);
    if (body.nextPageToken) throw new Error('Appointment count exceeds diagnostic page; review pagination before use.');
    const rows = [];
    for (const [index, doc] of (body.documents || []).entries()) {
      const a = fields(doc);
      const service = fields(await get('https://firestore.googleapis.com', `${root}/services/${encodeURIComponent(a.serviceId)}`));
      rows.push({record: index + 1, status: a.status, dateParses: Number.isFinite(Date.parse(a.dateTime)),
        hasDurationSnapshot: Number.isInteger(Number(a.durationMinutes)) && Number(a.durationMinutes) > 0,
        currentServiceDuration: Number(service.duration), serviceHospitalMatches: service.hospitalId === a.hospitalId,
        hasQueueLink: Boolean(a.queueId)});
    }
    return rows;
  });
}
main().catch(error => {report.authenticationError = error.message;}).finally(() => {
  writeFileSync('docs/p0-cloud-readiness.json', JSON.stringify(report, null, 2) + '\n');
  console.log(JSON.stringify(report, null, 2));
});
