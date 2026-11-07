// Read-only readiness audit. Uses existing Firebase CLI authentication.
// Never prints credentials or document contents, and performs only reads (GET and Firestore runQuery).
const {readFileSync, writeFileSync} = require('node:fs');
const {createHash} = require('node:crypto');
const auth = require('firebase-tools/lib/auth');
const {requireAuth} = require('firebase-tools/lib/requireAuth');
const {Client} = require('firebase-tools/lib/apiv2');
const project = 'petcare-d4413';
const report = {project, checkedAt: new Date().toISOString(), checks: {}};
const client = origin => new Client({urlPrefix: origin, apiVersion: 'v1'});
async function check(name, operation) {
  try { report.checks[name] = {status: 'verified', result: await operation()}; }
  catch (error) { report.checks[name] = {status: 'unverified', error: error.message}; }
}
function value(v) {
  if ('mapValue' in v) return fields(v.mapValue.fields);
  if ('arrayValue' in v) return (v.arrayValue.values || []).map(value);
  return v.stringValue ?? v.booleanValue ?? v.integerValue ?? v.timestampValue ?? null;
}
function fields(data = {}) { return Object.fromEntries(Object.entries(data).map(([k, v]) => [k, value(v)])); }
async function main() {
  const options = {project};
  const account = auth.getProjectDefaultAccount(process.cwd());
  if (account) auth.setActiveAccount(options, account);
  await requireAuth(options);
  const firestore = client('https://firestore.googleapis.com');
  const root = `projects/${project}/databases/(default)`;
  await check('database', async () => {
    const {body} = await firestore.get(root);
    return {location: body.locationId, edition: body.databaseEdition, type: body.type};
  });
  await check('functions', async () => {
    const {body} = await new Client({urlPrefix: 'https://cloudfunctions.googleapis.com', apiVersion: 'v2'})
      .get(`projects/${project}/locations/-/functions`);
    return (body.functions || []).map(f => ({name: f.name, state: f.state,
      runtime: f.buildConfig?.runtime, entryPoint: f.buildConfig?.entryPoint, updateTime: f.updateTime}));
  });
  await check('rules', async () => {
    const rules = client('https://firebaserules.googleapis.com');
    const {body: release} = await rules.get(`projects/${project}/releases/cloud.firestore`);
    const {body} = await rules.get(release.rulesetName);
    const deployed = body.source.files.find(f => f.name === 'firestore.rules') || body.source.files[0];
    const normalize = text => text.replace(/\r\n/g, '\n').trim();
    const hash = text => createHash('sha256').update(normalize(text)).digest('hex');
    return {releaseUpdatedAt: release.updateTime, ruleset: release.rulesetName,
      localHash: hash(readFileSync('firestore.rules', 'utf8')), deployedHash: hash(deployed.content),
      veterinarianAuthorization: deployed.content.split('\n').filter(line => /vetId|veterinarian|hospitalId|allow read|allow list/.test(line)),
      matchesLocal: normalize(deployed.content) === normalize(readFileSync('firestore.rules', 'utf8'))};
  });
  await check('indexes', async () => {
    const indexes = []; let pageToken;
    do {
      const {body} = await firestore.get(`${root}/collectionGroups/-/indexes`, {queryParams: {...(pageToken ? {pageToken} : {})}});
      indexes.push(...(body.indexes || [])); pageToken = body.nextPageToken;
    } while (pageToken);
    const expected = JSON.parse(readFileSync('firestore.indexes.json', 'utf8')).indexes;
    return {deployedCount: indexes.length, expected: expected.map(index => ({...index,
      ready: indexes.some(live => live.name.includes(`/collectionGroups/${index.collectionGroup}/`) &&
        live.state === 'READY' && live.queryScope === index.queryScope && index.fields.every((field, i) =>
          live.fields[i]?.fieldPath === field.fieldPath && live.fields[i]?.order === field.order))}))};
  });
  const data = {};
  for (const collection of ['users', 'hospital_staff', 'veterinarians', 'hospitals', 'services', 'pets', 'appointments', 'appointment_schedule', 'queue_records']) {
    await check(collection, async () => {
      const documents = []; let pageToken;
      do {
        const {body} = await firestore.get(`${root}/documents/${collection}`, {queryParams: {pageSize: 300, ...(pageToken ? {pageToken} : {})}});
        documents.push(...(body.documents || [])); pageToken = body.nextPageToken;
      } while (pageToken);
      data[collection] = new Map(documents.map(d => [d.name.split('/').at(-1), fields(d.fields)]));
      return {count: documents.length};
    });
  }
  await check('authIdentities', async () => {
    const ids = new Set(); let nextPageToken;
    do {
      const {body} = await client('https://identitytoolkit.googleapis.com').get(`projects/${project}/accounts:batchGet`,
        {queryParams: {maxResults: 1000, ...(nextPageToken ? {nextPageToken} : {})}});
      for (const user of body.users || []) ids.add(user.localId);
      nextPageToken = body.nextPageToken;
    } while (nextPageToken);
    data.auth = ids;
    return {accountCount: ids.size};
  });
  if (['users', 'hospital_staff', 'veterinarians', 'hospitals', 'services', 'appointments', 'appointment_schedule'].every(c => data[c])) {
    const invalidVets = [...data.veterinarians].filter(([id, vet]) => {
      const user = data.users.get(vet.userId);
      return vet.active !== true || !user || user.role !== 'veterinarian' || user.hospitalId !== vet.hospitalId ||
        (user.vetId ?? vet.userId) !== id || (vet.vetId !== undefined && vet.vetId !== id) ||
        !data.hospitals.get(vet.hospitalId)?.active || (data.auth && !data.auth.has(vet.userId));
    });
    await check('doctorAppointmentQueryIam', async () => {
      const doctors = [...data.users.values()].filter(u => u.role === 'veterinarian');
      const results = [];
      for (const u of doctors) {
        if (typeof u.vetId !== 'string' || typeof u.hospitalId !== 'string') continue;
        const {body} = await firestore.post(`${root}/documents:runQuery`, {structuredQuery: {
          from: [{collectionId: 'appointments'}],
          where: {compositeFilter: {op: 'AND', filters: [
            {fieldFilter: {field: {fieldPath: 'hospitalId'}, op: 'EQUAL', value: {stringValue: u.hospitalId}}},
            {fieldFilter: {field: {fieldPath: 'vetId'}, op: 'EQUAL', value: {stringValue: u.vetId}}},
          ]}}, limit: 1,
        }});
        results.push({queryExecuted: true, returnedAny: body.some(row => !!row.document)});
      }
      return {authorization: 'CLI IAM; does not test mobile security rules', results};
    });
    report.relationships = {
      doctorAssignmentChecks: [...data.users].filter(([,u]) => u.role === 'veterinarian').map(([uid,u]) => {
        const id = u.vetId ?? uid; const v = data.veterinarians.get(id);
        return {authExists: data.auth?.has(uid), explicitVetId: typeof u.vetId === 'string',
          directoryExists: !!v, directoryIdEqualsAuthUid: id === uid, directoryCanonicalIdMatches: !!v && (v.vetId === undefined || v.vetId === id),
          userIdMatches: v?.userId === uid, active: v?.active === true,
          hospitalMatches: !!v && v.hospitalId === u.hospitalId,
          hospitalExists: data.hospitals.has(u.hospitalId), hospitalActive: data.hospitals.get(u.hospitalId)?.active === true};
      }),
      activeDirectoryRecords: [...data.veterinarians.values()].filter(v => v.active === true).length,
      directorySchema: Object.fromEntries(['name','profileImageUrl','specialty','qualifications','experienceYears','bio'].map(k => [k,
        Object.fromEntries(['string','number','boolean','object','undefined'].map(t => [t, [...data.veterinarians.values()].filter(v => typeof v[k] === t).length]))])),
      directoryRecordsMissingUserId: [...data.veterinarians.values()].filter(v => !v.userId).length,
      directoryRecordsMissingActiveFlag: [...data.veterinarians.values()].filter(v => v.active === undefined).length,
      veterinarianUserAccounts: [...data.users.values()].filter(u => u.role === 'veterinarian').length,
      activeStaffAssignments: [...data.hospital_staff.values()].filter(s => s.active === true).length,
      // Inactive directory entries are included as ineligible, not necessarily corrupt.
      ineligibleDirectoryRecords: invalidVets.length,
      invalidActiveStaffAssignments: [...data.hospital_staff].filter(([id, s]) => s.active === true &&
        (s.userId !== id || data.users.get(id)?.role !== 'veterinary_staff' || !data.hospitals.has(s.hospitalId) ||
          (data.auth && !data.auth.has(id)))).length,
      appointmentsMissingSchedule: [...data.appointments.keys()].filter(id => !data.appointment_schedule.has(id)).length,
      appointmentsMissingDuration: [...data.appointments.values()].filter(a => !Number.isInteger(Number(a.durationMinutes)) || !a.durationMinutes).length,
      appointmentsWithMissingReferences: [...data.appointments.values()].filter(a =>
        !data.users.has(a.ownerId) || !data.hospitals.has(a.hospitalId) || !data.veterinarians.has(a.vetId) || !data.services.has(a.serviceId)).length,
      ...(data.pets ? {appointmentsWithInvalidPetOwnership: [...data.appointments.values()].filter(a =>
        data.pets.get(a.petId)?.ownerId !== a.ownerId).length} : {}),
      ...(data.queue_records ? {brokenAppointmentQueueLinks: [...data.appointments].filter(([id, a]) => a.queueId &&
        data.queue_records.get(a.queueId)?.appointmentId !== id).length} : {}),
      mismatchedScheduleRecords: [...data.appointment_schedule].filter(([id, s]) => {
        const a = data.appointments.get(id);
        return !a || ['vetId', 'hospitalId', 'serviceId', 'dateTime', 'status', 'durationMinutes'].some(k => a[k] !== s[k]);
      }).length,
    };
  }
}
main().catch(error => { report.authenticationError = error.message; }).finally(() => {
  writeFileSync('docs/veterinarian-dashboard-live-readiness.json', JSON.stringify(report, null, 2) + '\n');
  console.log('Read-only audit saved to docs/veterinarian-dashboard-live-readiness.json');
});

