import { readFileSync, existsSync } from 'node:fs';
import { resolve, dirname } from 'node:path';
import { fileURLToPath } from 'node:url';

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

loadEnv(resolve(root, '.env'));

const slug = process.argv[2] || 'culture-perception';
const file = resolve(root, process.argv[3] || 'supabase/surveys/culture-perception.example.json');
const payload = JSON.parse(readFileSync(file, 'utf8'));
const questions = Array.isArray(payload) ? payload : payload.questions;
if (!Array.isArray(questions)) {
  throw new Error('JSON must be an array or { questions: [] }');
}

const url = String(process.env.SUPABASE_URL || '').replace(/\/$/, '');
const key = String(process.env.SUPABASE_SERVICE_ROLE_KEY || '').trim();
if (!url || !key) throw new Error('missing SUPABASE_URL or SUPABASE_SERVICE_ROLE_KEY');

const response = await fetch(`${url}/rest/v1/rpc/replace_survey_bank`, {
  method: 'POST',
  headers: {
    apikey: key,
    Authorization: `Bearer ${key}`,
    'Content-Type': 'application/json',
  },
  body: JSON.stringify({
    p_slug: payload.slug || slug,
    p_questions: questions,
  }),
});
const body = await response.text();
if (!response.ok) {
  throw new Error(`upload failed ${response.status}: ${body}`);
}
console.log(body);
