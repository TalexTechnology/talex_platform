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
  if (result.status !== 0) {
    throw new Error(`supabase ${args[0]} exit=${result.status}: ${out.split('\n').slice(-15).join('\n')}`);
  }
  return out;
}

loadEnv(resolve(root, '.env'));
if (!process.env.SUPABASE_ACCESS_TOKEN || !process.env.SUPABASE_DB_PASSWORD) {
  throw new Error('missing remote credentials');
}

run(['login', '--token', process.env.SUPABASE_ACCESS_TOKEN]);
console.log('ok login');
run([
  'link',
  '--project-ref',
  process.env.SUPABASE_PROJECT_REF,
  '--password',
  process.env.SUPABASE_DB_PASSWORD,
  '--yes',
]);
console.log('ok link');

const push = run(['db', 'push', '--yes', '--linked']);
console.log('ok db push');
console.log(push.split('\n').filter((line) => !/password|token|secret/i.test(line)).slice(-12).join('\n'));

const seed = run(['db', 'query', '--linked', '--file', 'supabase/seed.sql']);
console.log('ok seed');
console.log(seed.includes('error') ? 'seed reported an error' : 'seed completed');

const seedAgain = run(['db', 'query', '--linked', '--file', 'supabase/seed.sql']);
console.log('ok seed second pass');
console.log(seedAgain.includes('error') ? 'second seed reported an error' : 'second seed completed');
