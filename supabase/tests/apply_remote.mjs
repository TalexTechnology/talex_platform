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

function required(name) {
  const value = process.env[name];
  if (!value) throw new Error(`${name} is empty`);
  return value;
}

function run(command, args, opts = {}) {
  const result = spawnSync(command, args, {
    cwd: root,
    encoding: 'utf8',
    stdio: ['ignore', 'pipe', 'pipe'],
    shell: true,
    windowsHide: true,
    ...opts,
  });
  if (result.status !== 0) {
    const err = [result.stderr, result.stdout, result.error?.message]
      .filter(Boolean)
      .join('\n')
      .trim();
    throw new Error(
      `${command} ${args[0] ?? ''} exit=${result.status}: ${err.split('\n').slice(-12).join('\n')}`,
    );
  }
  return (result.stdout || '').trim();
}

loadEnv(resolve(root, '.env'));
const ref = required('SUPABASE_PROJECT_REF');
required('SUPABASE_URL');
required('SUPABASE_ANON_KEY');
required('SUPABASE_SERVICE_ROLE_KEY');
required('SUPABASE_ACCESS_TOKEN');
required('SUPABASE_DB_PASSWORD');

console.log(`project_ref=${ref}`);

run('npx', ['--yes', 'supabase', 'login', '--token', process.env.SUPABASE_ACCESS_TOKEN]);
console.log('ok login');

run('npx', [
  '--yes',
  'supabase',
  'link',
  '--project-ref',
  ref,
  '--password',
  process.env.SUPABASE_DB_PASSWORD,
  '--yes',
]);
console.log('ok link');

const tables = run('npx', [
  '--yes',
  'supabase',
  'db',
  'query',
  '--linked',
  '--file',
  'supabase/tests/inspect_remote.sql',
]);
console.log('public_tables_json_start');
console.log(tables);
console.log('public_tables_json_end');
