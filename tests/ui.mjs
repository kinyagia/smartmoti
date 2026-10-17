// Playwright entry point; the complete suite is authored in ui.cl.jac.
import { spawnSync } from 'node:child_process';
import { fileURLToPath, pathToFileURL } from 'node:url';
import path from 'node:path';
const root = fileURLToPath(new URL('../', import.meta.url));
const result = spawnSync(path.join(root, '.venv', 'Scripts', 'jac.exe'), ['run', 'client_build.jac', '--tests'], { cwd: root, stdio: 'inherit' });
if (result.error) throw result.error;
if (result.status !== 0) process.exit(result.status ?? 1);
await import(pathToFileURL(path.join(root, '.jac', 'tests', 'ui.mjs')).href);
