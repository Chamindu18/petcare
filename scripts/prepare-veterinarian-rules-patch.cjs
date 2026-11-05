// Read-only production fetch. Generates a review artifact; never deploys rules.
const {writeFileSync, mkdirSync} = require('node:fs');
const {createHash} = require('node:crypto');
const auth = require('firebase-tools/lib/auth');
const {requireAuth} = require('firebase-tools/lib/requireAuth');
const {Client} = require('firebase-tools/lib/apiv2');
async function main() {
  const project = 'petcare-d4413', options = {project};
  const account = auth.getProjectDefaultAccount(process.cwd());
  if (account) auth.setActiveAccount(options, account);
  await requireAuth(options);
  const api = new Client({urlPrefix: 'https://firebaserules.googleapis.com', apiVersion: 'v1'});
  const {body: release} = await api.get(`projects/${project}/releases/cloud.firestore`);
  const {body: ruleset} = await api.get(release.rulesetName);
  const source = ruleset.source.files.find(f => f.name === 'firestore.rules').content;
  mkdirSync('build/veterinarian-rules-review', {recursive: true});
  writeFileSync('build/veterinarian-rules-review/deployed.rules', source);
  const helper = `    // V01 read compatibility: trusted profile + active directory back-reference.
    // This helper grants no hospital/service/queue write privileges.
    function dashboardAssignedVeterinarian(data) {
      let profile = get(/databases/$(database)/documents/users/$(request.auth.uid)).data;
      let vetId = profile.get('vetId', request.auth.uid);
      let directory = get(/databases/$(database)/documents/veterinarians/$(vetId)).data;
      return isVeterinarian()
        && vetId is string && vetId.size() > 0
        && data.vetId == vetId
        && data.hospitalId is string && data.hospitalId != 'unassigned'
        && profile.get('hospitalId', null) == data.hospitalId
        && directory.get('userId', null) == request.auth.uid
        && directory.get('active', false) == true
        && directory.get('vetId', vetId) == vetId
        && directory.hospitalId == data.hospitalId;
    }

`;
  const start = source.indexOf('    match /appointments/{appointmentId} {');
  const end = source.indexOf('      // New appointments', start);
  if (start < 0 || end < 0) throw new Error('Unknown deployed appointment rule layout');
  const oldRead = source.slice(start, end);
  const predicate = '|| isVeterinaryUserForHospital(resource.data.hospitalId)';
  if (oldRead.split(predicate).length !== 2) throw new Error('Unexpected read predicate');
  const newRead = oldRead.replace('veterinarians can read appointments in their hospital. List queries',
    'veterinarians can read only their assigned appointments. List queries').replace(predicate,
    '|| isVeterinaryStaffForHospital(resource.data.hospitalId)\n          || dashboardAssignedVeterinarian(resource.data)');
  const candidate = source.slice(0, start) + helper + newRead + source.slice(end);
  writeFileSync('build/veterinarian-rules-review/candidate.rules', candidate);
  writeFileSync('build/veterinarian-rules-review/metadata.json', JSON.stringify({
    project, ruleset: release.rulesetName, releaseUpdatedAt: release.updateTime,
    sourceSha256: createHash('sha256').update(source).digest('hex'),
    candidateSha256: createHash('sha256').update(candidate).digest('hex'),
    deployed: false,
  }, null, 2) + '\n');
  console.log('Deployed rules and minimal appointment-read candidate saved for review; no deployment performed.');
}
main().catch(e => { console.error(e.message); process.exitCode = 1; });
