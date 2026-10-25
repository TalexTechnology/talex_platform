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
    throw new Error(`supabase ${args.join(' ')} exit=${result.status}: ${out.split('\n').slice(-20).join('\n')}`);
  }
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

const sqlResult = run(['db', 'query', '--linked', '--file', 'supabase/tests/remote_verify.sql']);
if (/FAIL:/.test(sqlResult)) {
  throw new Error(sqlResult);
}
console.log('ok sql verification');
const leftover = sqlResult.match(/"templates":\s*\d+|"organizations":\s*\d+|"profiles":\s*\d+/g);
if (leftover) console.log(leftover.join(' '));

const url = `${process.env.SUPABASE_URL.replace(/\/$/, '')}/rest/v1/rpc/open_culture_survey`;
const response = await fetch(url, {
  method: 'POST',
  headers: {
    apikey: process.env.SUPABASE_ANON_KEY,
    Authorization: `Bearer ${process.env.SUPABASE_ANON_KEY}`,
    'Content-Type': 'application/json',
  },
  body: JSON.stringify({ p_token: 'short-token-value-xx' }),
});
const body = await response.text();
if (response.ok) {
  throw new Error(`anon RPC unexpectedly succeeded: ${response.status}`);
}
if (!/invalid_link/i.test(body)) {
  throw new Error(`anon RPC did not return invalid_link (${response.status})`);
}
console.log(`ok anon rpc rejected short token (${response.status})`);

const privateRead = await fetch(
  `${process.env.SUPABASE_URL.replace(/\/$/, '')}/rest/v1/applications?select=id`,
  {
    headers: {
      apikey: process.env.SUPABASE_ANON_KEY,
      Authorization: `Bearer ${process.env.SUPABASE_ANON_KEY}`,
    },
  },
);
if (privateRead.ok) {
  throw new Error(`anon unexpectedly read applications (${privateRead.status})`);
}
console.log(`ok anon cannot read applications (${privateRead.status})`);
console.log('ok remote production checks passed');
