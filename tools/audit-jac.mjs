// Node entry point; inventory and threshold checks execute in Jac.
import { spawnSync } from 'node:child_process';
import { fileURLToPath } from 'node:url';
import path from 'node:path';
const root = fileURLToPath(new URL('../', import.meta.url));
const result = spawnSync(path.join(root, '.venv', 'Scripts', 'jac.exe'), ['run', 'source_audit.jac', ...process.argv.slice(2)], { cwd: root, stdio: 'inherit' });
if (result.error) throw result.error;
process.exit(result.status ?? 1);
