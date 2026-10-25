import { readFileSync, existsSync } from 'node:fs';
import { resolve, dirname } from 'node:path';
import { fileURLToPath } from 'node:url';

const root = resolve(dirname(fileURLToPath(import.meta.url)), '..', '..');
const envPath = resolve(root, '.env');
if (!existsSync(envPath)) throw new Error('missing .env');
for (const line of readFileSync(envPath, 'utf8').split(/\r?\n/)) {
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

const url = String(process.env.SUPABASE_URL || '').replace(/\/$/, '');
const key = String(process.env.SUPABASE_SERVICE_ROLE_KEY || '').trim();
if (!url || !key) throw new Error('missing supabase credentials');
const headers = {apikey: key, Authorization: `Bearer ${key}`};

const questionsRes = await fetch(
  `${url}/rest/v1/survey_scoring_questions?purpose=eq.affinity&version_status=eq.published&select=code,front,dimension_a`,
  {headers},
);
const questions = await questionsRes.json();
if (!Array.isArray(questions)) {
  throw new Error(`scoring view failed: ${questionsRes.status}`);
}

const templatesRes = await fetch(
  `${url}/rest/v1/survey_templates?select=slug,purpose,title`,
  {headers},
);
const templates = await templatesRes.json();

const sectionsRes = await fetch(
  `${url}/rest/v1/survey_sections?select=code,title,version_id`,
  {headers},
);
const sections = await sectionsRes.json();
const versionsRes = await fetch(
  `${url}/rest/v1/survey_versions?select=id,status,template_id,survey_templates!inner(slug)`,
  {headers},
);
const versions = await versionsRes.json();
const versionSlug = Object.fromEntries(
  (Array.isArray(versions) ? versions : []).map((row) => [
    row.id,
    row.survey_templates?.slug,
  ]),
);
const sectionCounts = {};
for (const row of Array.isArray(sections) ? sections : []) {
  const slug = versionSlug[row.version_id] || 'unknown';
  sectionCounts[slug] = sectionCounts[slug] || [];
  sectionCounts[slug].push(row.code);
}

console.log(JSON.stringify({
  affinityQuestions: questions.length,
  affinityWithDimension: questions.filter((item) => item.dimension_a).length,
  fronts: [...new Set(questions.map((item) => item.front))],
  templates: (Array.isArray(templates) ? templates : []).map((item) => item.slug),
  sections: sectionCounts,
}, null, 2));
