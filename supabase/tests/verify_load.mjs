import { readFileSync, existsSync } from 'node:fs';
import { resolve, dirname } from 'node:path';
import { fileURLToPath } from 'node:url';
import { spawnSync } from 'node:child_process';

const root = resolve(dirname(fileURLToPath(import.meta.url)), '..', '..');

function loadEnv(path) {
  if (!existsSync(path)) throw new Error(`Missing ${path}`);
  for (const line of readFileSync(path, 'utf8').split(/\r?\n/)) {
    if (!line || line.trim().startsWith('#') || !line.includes('=')) continue;
    const eq = line.indexOf('=');
    const key = line.slice(0, eq).trim();
    let value = line.slice(eq + 1).trim();
    if (
      (value.startsWith('"') && value.endsWith('"')) ||
      (value.startsWith("'") && value.endsWith("'"))
    ) {
      value = value.slice(1, -1);
    }
    if (key) process.env[key] = value;
  }
}

function run(args) {
  const result = spawnSync('npx', ['--yes', 'supabase', ...args], {
    cwd: root,
    encoding: 'utf8',
    stdio: ['ignore', 'pipe', 'pipe'],
    shell: true,
    windowsHide: true,
  });
  const out = [result.stdout, result.stderr].filter(Boolean).join('\n').trim();
  if (result.status !== 0) throw new Error(out.split('\n').slice(-12).join('\n'));
  return out;
}

loadEnv(resolve(root, '.env'));
run(['login', '--token', process.env.SUPABASE_ACCESS_TOKEN]);
run([
  'link',
  '--project-ref',
  process.env.SUPABASE_PROJECT_REF,
  '--password',
  process.env.SUPABASE_DB_PASSWORD,
  '--yes',
]);
const validation = run(['db', 'query', '--linked', '--file', 'supabase/tests/validate_counts.sql']);
console.log(validation.replace(/[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,}/gi, '[email]'));

const isolation = run([
  'db',
  'query',
  '--linked',
  '--file',
  'supabase/tests/validate_isolation.sql',
]);
console.log(isolation.replace(/[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,}/gi, '[email]'));
