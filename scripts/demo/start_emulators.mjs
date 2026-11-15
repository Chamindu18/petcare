import {spawn} from 'node:child_process';
import {fileURLToPath} from 'node:url';

const cli = fileURLToPath(new URL('../../node_modules/firebase-tools/lib/bin/firebase.js', import.meta.url));
const child = spawn(process.execPath, [cli, 'emulators:start', '--only', 'auth,firestore,functions', '--project', 'demo-petcare'], {
  stdio: 'inherit',
  env: {...process.env, FIREBASE_FUNCTIONS_DISCOVERY_OUTPUT_PATH: 'true'},
  windowsHide: true,
});
for (const signal of ['SIGINT', 'SIGTERM']) process.on(signal, () => child.kill(signal));
child.on('error', error => { console.error(error.message); process.exitCode = 1; });
child.on('exit', code => { process.exitCode = code ?? 1; });
