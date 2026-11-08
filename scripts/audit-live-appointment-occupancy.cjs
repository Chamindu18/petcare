// Read-only live audit. Uses the Firebase CLI account; never writes to Firestore.
const auth = require('firebase-tools/lib/auth');
const {requireAuth} = require('firebase-tools/lib/requireAuth');
const {Client} = require('firebase-tools/lib/apiv2');

const project = process.argv[2] || 'petcare-d4413';
const root = `projects/${project}/databases/(default)/documents`;
const client = new Client({urlPrefix: 'https://firestore.googleapis.com', apiVersion: 'v1'});

function decode(value) {
  if ('mapValue' in value) return fields(value.mapValue.fields);
  return value.stringValue ?? value.booleanValue ??
    (value.integerValue === undefined ? undefined : Number(value.integerValue)) ??
    value.timestampValue ?? null;
}
function fields(data = {}) {
  return Object.fromEntries(Object.entries(data).map(([key, value]) => [key, decode(value)]));
}
async function collection(name) {
  const rows = [];
  let pageToken;
  do {
    const {body} = await client.get(`${root}/${name}`, {
      queryParams: {pageSize: 300, ...(pageToken ? {pageToken} : {})},
    });
    rows.push(...(body.documents || []).map(doc => ({id: doc.name.split('/').at(-1), ...fields(doc.fields)})));
    pageToken = body.nextPageToken;
  } while (pageToken);
  return rows;
}
function instant(raw) {
  if (typeof raw !== 'string') return null;
  const parsed = new Date(/(Z|[+-]\d{2}:\d{2})$/i.test(raw) ? raw : `${raw}+05:30`);
  return Number.isNaN(parsed.getTime()) ? null : parsed;
}
function intervalIds(appointment, minutes) {
  const start = instant(appointment.dateTime);
  if (!start || minutes % 15) return null;
  const ids = [];
  const first = Math.floor(start.getTime() / 900000) * 900000;
  for (let instantMs = first; instantMs < start.getTime() + minutes * 60000; instantMs += 900000) {
    const time = new Date(instantMs + 330 * 60000);
    const date = time.toISOString().slice(0, 10);
    const clock = time.toISOString().slice(11, 16);
    ids.push(`${appointment.hospitalId}|${appointment.vetId}|${date}|${clock}`);
  }
  return ids;
}
async function main() {
  const options = {project};
  const account = auth.getProjectDefaultAccount(process.cwd());
  if (account) auth.setActiveAccount(options, account);
  await requireAuth(options);
  const [appointments, services, schedules, hospitals, vets] = await Promise.all([
    collection('appointments'), collection('services'), collection('appointment_schedule'),
    collection('hospitals'), collection('veterinarians'),
  ]);
  const byId = rows => new Map(rows.map(row => [row.id, row]));
  const serviceMap = byId(services), scheduleMap = byId(schedules);
  const hospitalMap = byId(hospitals), vetMap = byId(vets);
  const occupied = new Map();
  const report = appointments.map(appointment => {
    const issues = [];
    const service = serviceMap.get(appointment.serviceId);
    const hospital = hospitalMap.get(appointment.hospitalId);
    const vet = vetMap.get(appointment.vetId);
    const snapshot = appointment.durationMinutes;
    const authoritative = service?.duration;
    const duration = Number.isInteger(snapshot) ? snapshot : authoritative;
    if (snapshot == null) issues.push('historical_duration_not_snapshotted');
    if (!service || service.hospitalId !== appointment.hospitalId || service.active !== true) issues.push('service_missing_mismatched_or_inactive');
    if (!Number.isInteger(duration) || duration <= 0 || duration > 1440 || duration % 15) issues.push('duration_unverified_or_unaligned');
    if (snapshot != null && snapshot !== authoritative) issues.push('duration_snapshot_differs_from_current_service');
    if (!hospital || hospital.active !== true) issues.push('hospital_missing_or_inactive');
    if (!vet || vet.hospitalId !== appointment.hospitalId) issues.push('veterinarian_missing_or_mismatched');
    if (!['pending', 'confirmed', 'cancelled', 'rejected'].includes(appointment.status)) issues.push('status_unknown');
    if (!appointment.ownerId || !appointment.petId || !appointment.appointmentId || appointment.appointmentId !== appointment.id) issues.push('identity_missing_or_mismatched');
    const intervals = Number.isInteger(duration) && duration > 0 ? intervalIds(appointment, duration) : null;
    if (!intervals) issues.push('time_invalid');
    else if (instant(appointment.dateTime).getTime() % 900000) issues.push('time_unaligned');
    const schedule = scheduleMap.get(appointment.id);
    if (schedule && ['hospitalId', 'vetId', 'serviceId', 'dateTime', 'status', 'durationMinutes'].some(key => schedule[key] !== (key === 'durationMinutes' ? duration : appointment[key]))) issues.push('schedule_mismatch');
    if (!schedule) issues.push('schedule_missing');
    if (['pending', 'confirmed'].includes(appointment.status) && intervals) {
      for (const interval of intervals) {
        const previous = occupied.get(interval) || [];
        previous.push(appointment.id);
        occupied.set(interval, previous);
      }
    }
    return {id: appointment.id, status: appointment.status, hospitalId: appointment.hospitalId,
      vetId: appointment.vetId, serviceId: appointment.serviceId, dateTime: appointment.dateTime,
      durationMinutes: duration ?? null, durationSource: snapshot == null ? 'current_service' : 'snapshot',
      intervals, issues};
  });
  const conflicts = [...occupied].filter(([, ids]) => ids.length > 1).map(([interval, ids]) => ({interval, ids}));
  for (const row of report) {
    if (conflicts.some(conflict => conflict.ids.includes(row.id))) row.issues.push('existing_overlap');
  }
  console.log(JSON.stringify({project, mode: 'read-only', appointmentCount: report.length,
    scheduleCount: schedules.length,
    serviceDurations: [...new Set(services.map(service => service.duration))].sort((a, b) => a - b),
    appointments: report, conflicts,
    migrationSafe: report.every(row => row.issues.every(issue => issue === 'schedule_missing')) && conflicts.length === 0}, null, 2));
}
main().catch(error => {console.error(error.message); process.exitCode = 1;});
