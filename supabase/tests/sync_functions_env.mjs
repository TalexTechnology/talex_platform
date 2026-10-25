import { readFileSync, existsSync, writeFileSync } from 'node:fs';
import { resolve, dirname } from 'node:path';
import { fileURLToPath } from 'node:url';

const root = resolve(dirname(fileURLToPath(import.meta.url)), '..', '..');

function loadEnv(path) {
  const values = {};
  if (!existsSync(path)) return values;
  for (const line of readFileSync(path, 'utf8').split(/\r?\n/)) {
    if (!line || line.trim().startsWith('#') || !line.includes('=')) continue;
    const eq = line.indexOf('=');
    values[line.slice(0, eq).trim()] = line.slice(eq + 1).trim();
  }
  return values;
}

const existing = loadEnv(resolve(root, 'functions/.env'));
const example = loadEnv(resolve(root, 'functions/.env.example'));
const rootEnv = loadEnv(resolve(root, '.env'));
const merged = {...example, ...existing, ...rootEnv};
const keys = [
  'SMTP_HOST',
  'SMTP_PORT',
  'SMTP_USER',
  'SMTP_PASS',
  'SMTP_FROM',
  'GEMINI_MODEL',
  'SUPABASE_URL',
  'SUPABASE_ANON_KEY',
  'SUPABASE_SERVICE_ROLE_KEY',
  'SUPABASE_JWT_SECRET',
];
const lines = keys
  .filter((key) => merged[key] != null && merged[key] !== '')
  .map((key) => `${key}=${merged[key]}`);
writeFileSync(resolve(root, 'functions/.env'), `${lines.join('\n')}\n`);
console.log(`functions_env_keys=${lines.map((line) => line.split('=')[0]).join(',')}`);
