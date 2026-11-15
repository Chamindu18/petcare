// Read-only booking data check. Prints only hospital, service and vet directory data.
const auth = require('firebase-tools/lib/auth');
const {requireAuth} = require('firebase-tools/lib/requireAuth');
const {Client} = require('firebase-tools/lib/apiv2');

const project = 'petcare-d4413';
const root = `projects/${project}/databases/(default)/documents`;
const client = new Client({urlPrefix: 'https://firestore.googleapis.com', apiVersion: 'v1'});
function value(v) {
  if ('mapValue' in v) return fields(v.mapValue.fields);
  return v.stringValue ?? v.booleanValue ?? v.integerValue ?? v.timestampValue ?? null;
}
function fields(data = {}) {
  return Object.fromEntries(Object.entries(data).map(([key, item]) => [key, value(item)]));
}
async function collection(name) {
  const result = [];
  let pageToken;
  do {
    const {body} = await client.get(`${root}/${name}`, {
      queryParams: {pageSize: 300, ...(pageToken ? {pageToken} : {})},
    });
    result.push(...(body.documents || []).map(doc => ({id: doc.name.split('/').at(-1), ...fields(doc.fields)})));
    pageToken = body.nextPageToken;
  } while (pageToken);
  return result;
}
async function main() {
  const options = {project};
  const account = auth.getProjectDefaultAccount(process.cwd());
  if (account) auth.setActiveAccount(options, account);
  await requireAuth(options);
  const [hospitals, vets, services, schedules] = await Promise.all([
    collection('hospitals'), collection('veterinarians'),
    collection('services'), collection('appointment_schedule'),
  ]);
  const rulesClient = new Client({urlPrefix: 'https://firebaserules.googleapis.com', apiVersion: 'v1'});
  const {body: release} = await rulesClient.get(`projects/${project}/releases/cloud.firestore`);
  const {body: ruleset} = await rulesClient.get(release.rulesetName);
  const deployedRules = ruleset.source.files.map(file => file.content).join('\n');
  const selectedVets = vets.filter(v => v.name?.includes('Kasun Perera'));
  console.log(JSON.stringify({
    selectedVets: selectedVets.map(v => ({id: v.id, name: v.name, hospitalId: v.hospitalId, active: v.active})),
    selectedHospitals: hospitals.filter(h => selectedVets.some(v => v.hospitalId === h.id))
      .map(h => ({id: h.id, name: h.name, hours: h.hours, active: h.active})),
    selectedServices: services.filter(s => selectedVets.some(v => v.hospitalId === s.hospitalId))
      .map(s => ({id: s.id, name: s.name, fieldNames: Object.keys(s),
        hospitalId: s.hospitalId, duration: s.duration, active: s.active})),
    deployedScheduleRule: deployedRules.includes('match /appointment_schedule/{appointmentId}'),
    schedules: selectedVets.map(v => {
      const rows = schedules.filter(s => s.vetId === v.id);
      return {vetId: v.id, count: rows.length,
        malformed: rows.filter(s => !s.dateTime || !s.status || !s.serviceId).map(s => s.id),
        selectedDate: rows.filter(s => String(s.dateTime).startsWith('2026-11-20'))
          .map(s => ({id: s.id, dateTime: s.dateTime, status: s.status, durationMinutes: s.durationMinutes}))};
    }),
    totals: {hospitals: hospitals.length, vets: vets.length, schedules: schedules.length},
  }, null, 2));
}
main().catch(error => {console.error(error.message); process.exitCode = 1;});
