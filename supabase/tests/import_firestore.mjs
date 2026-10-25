import { readFileSync, writeFileSync, existsSync } from 'node:fs';
import { resolve, dirname } from 'node:path';
import { fileURLToPath } from 'node:url';
import { spawnSync } from 'node:child_process';

const root = resolve(dirname(fileURLToPath(import.meta.url)), '..', '..');
const rejectsPath = resolve(root, 'supabase/tests/.import-rejects.jsonl');
const reportPath = resolve(root, 'supabase/tests/.import-report.json');
const PROJECT = 'talex-platform';
const dryRun = process.argv.includes('--dry-run');

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

function accessToken() {
  const result = spawnSync('gcloud', ['auth', 'print-access-token'], {
    encoding: 'utf8',
    shell: true,
    windowsHide: true,
  });
  const token = (result.stdout || '').trim();
  if (result.status !== 0 || !token) {
    throw new Error('gcloud auth print-access-token failed');
  }
  return token;
}

function decodeValue(value) {
  if (value == null) return null;
  if ('stringValue' in value) return value.stringValue;
  if ('integerValue' in value) return Number(value.integerValue);
  if ('doubleValue' in value) return value.doubleValue;
  if ('booleanValue' in value) return value.booleanValue;
  if ('timestampValue' in value) return value.timestampValue;
  if ('nullValue' in value) return null;
  if ('arrayValue' in value) return (value.arrayValue.values || []).map(decodeValue);
  if ('mapValue' in value) {
    const out = {};
    for (const [key, nested] of Object.entries(value.mapValue.fields || {})) {
      out[key] = decodeValue(nested);
    }
    return out;
  }
  return null;
}

function decodeDoc(doc) {
  const id = doc.name.split('/').pop();
  const data = {};
  for (const [key, value] of Object.entries(doc.fields || {})) {
    data[key] = decodeValue(value);
  }
  return { id, data };
}

const emailOf = (value) => String(value || '').trim().toLowerCase();

function parseDna(list, text) {
  const fromList = Array.isArray(list)
    ? list.map((item) => String(item).trim()).filter(Boolean)
    : [];
  const fromText = String(text || '')
    .split(/\s*[·|,;]\s*|\n+/)
    .map((item) => item.trim())
    .filter(Boolean);
  return [...new Set([...fromList, ...fromText])];
}

function toIso(value) {
  if (!value) return null;
  const date = new Date(value);
  return Number.isNaN(date.getTime()) ? null : date.toISOString();
}

const rejects = [];
function reject(collection, firebaseId, reason, extra = {}) {
  rejects.push({ collection, firebaseId, reason, ...extra });
}

async function listCollection(token, collection) {
  const docs = [];
  let pageToken = '';
  do {
    const url = new URL(
      `https://firestore.googleapis.com/v1/projects/${PROJECT}/databases/(default)/documents/${collection}`,
    );
    url.searchParams.set('pageSize', '300');
    if (pageToken) url.searchParams.set('pageToken', pageToken);
    const response = await fetch(url, { headers: { Authorization: `Bearer ${token}` } });
    if (!response.ok) throw new Error(`firestore ${collection} ${response.status}`);
    const payload = await response.json();
    for (const doc of payload.documents || []) docs.push(decodeDoc(doc));
    pageToken = payload.nextPageToken || '';
  } while (pageToken);
  return docs;
}

async function sb(path, { method = 'GET', body, query = '' } = {}) {
  const url = `${process.env.SUPABASE_URL.replace(/\/$/, '')}/rest/v1/${path}${query}`;
  const response = await fetch(url, {
    method,
    headers: {
      apikey: process.env.SUPABASE_SERVICE_ROLE_KEY,
      Authorization: `Bearer ${process.env.SUPABASE_SERVICE_ROLE_KEY}`,
      'Content-Type': 'application/json',
      Prefer:
        method === 'GET'
          ? 'count=exact'
          : 'return=representation,resolution=merge-duplicates',
    },
    body: body == null ? undefined : JSON.stringify(body),
  });
  const text = await response.text();
  if (!response.ok) {
    throw new Error(`${method} ${path} ${response.status}: ${text.slice(0, 500)}`);
  }
  return text ? JSON.parse(text) : [];
}

async function writeRows(table, rows, onConflict) {
  if (!rows.length) return [];
  const saved = [];
  for (let i = 0; i < rows.length; i += 80) {
    const chunk = rows.slice(i, i + 80);
    saved.push(
      ...(await sb(table, {
        method: 'POST',
        query: onConflict ? `?on_conflict=${onConflict}` : '',
        body: chunk,
      })),
    );
  }
  return saved;
}

async function mapIds(collection, items, idKey = 'id') {
  if (!items.length) return;
  await writeRows(
    'firebase_id_map',
    items.map((item) => ({
      collection,
      firebase_id: item.firebase_id || item.firebase_uid || item.firebase_candidate_id,
      postgres_id: item[idKey],
    })),
    'collection,firebase_id',
  );
}

const PROCESS = new Set([
  'pending', 'inProgress', 'completed', 'inReview', 'shortlisted',
  'interview', 'finalist', 'hired', 'rejected',
]);
const ACTIVITY = new Set([
  'companyCreated', 'companyActivated', 'processCreated', 'vacancyCreated',
  'respondentInvited', 'evaluationStarted', 'evaluationCompleted',
  'affinityDetected', 'saleRecorded', 'statusChanged',
]);
const SECRET = /(password|token|pin|secret|apikey|service_role|pin_hash|token_hash)/i;

loadEnv(resolve(root, '.env'));
const token = accessToken();
const names = [
  'users', 'companies', 'vacancies', 'candidates', 'evaluations',
  'affinity_analyses', 'assessment_questions', 'activation_invites',
  'activity_events', 'admin_audit_logs', 'dna_catalog',
  'survey_result_requests', 'config',
];
const data = {};
for (const name of names) {
  data[name] = await listCollection(token, name);
  console.log(`read ${name}=${data[name].length}`);
}

const report = {
  dryRun,
  source: Object.fromEntries(names.map((name) => [name, data[name].length])),
  loaded: {},
};
if (dryRun) {
  writeFileSync(reportPath, JSON.stringify(report, null, 2));
  console.log('dry-run complete');
  process.exit(0);
}

const superadminEmails = new Set(
  (data.config.find((doc) => doc.id === 'superadmin')?.data.emails || []).map(emailOf),
);
const roleMap = Object.fromEntries((await sb('legacy_role_map')).map((row) => [row.firestore_role, row]));
const statusMap = Object.fromEntries(
  (await sb('legacy_company_status_map')).map((row) => [row.firestore_status, row]),
);
const templates = await sb('survey_templates?select=id,slug');
const affinityTemplate = templates.find((row) => row.slug === 'affinity-core');
const versions = await sb(`survey_versions?select=id,status,template_id&template_id=eq.${affinityTemplate.id}`);
const affinityVersion = versions.find((row) => row.status === 'published');
if (!affinityVersion) throw new Error('published affinity version missing');

const rankRole = (role) => {
  if (role === 'superadmin') return 5;
  if (roleMap[role]?.creates_membership) return 4;
  if (role === 'respondent') return 1;
  return 2;
};
const usersByEmail = new Map();
for (const doc of data.users) {
  const email = emailOf(doc.data.email);
  if (!email.includes('@')) {
    reject('users', doc.id, 'invalid_email');
    continue;
  }
  const current = usersByEmail.get(email);
  if (!current || rankRole(doc.data.role) > rankRole(current.data.role)) {
    if (current) reject('users', current.id, 'duplicate_profile_email', { kept: doc.id });
    usersByEmail.set(email, doc);
  } else {
    reject('users', doc.id, 'duplicate_profile_email', { kept: current.id });
  }
}

const profiles = await writeRows(
  'profiles',
  [...usersByEmail.values()].map((doc) => {
    const email = emailOf(doc.data.email);
    return {
      firebase_uid: doc.id,
      email,
      display_name: doc.data.displayName || null,
      is_active: doc.data.isActive !== false,
      is_superadmin: doc.data.role === 'superadmin' || superadminEmails.has(email),
    };
  }),
  'firebase_uid',
);
const profileByUid = Object.fromEntries(profiles.map((row) => [row.firebase_uid, row]));
report.loaded.profiles = profiles.length;
await mapIds('users', profiles.map((row) => ({ ...row, firebase_id: row.firebase_uid })));

const orgs = await writeRows(
  'organizations',
  data.companies.flatMap((doc) => {
    const rawStatus = doc.data.status || 'onboarding';
    const mapped = statusMap[rawStatus];
    if (!mapped) {
      reject('companies', doc.id, 'unknown_status', { status: rawStatus });
      return [];
    }
    const stage = doc.data.commercialStage;
    return [{
      firebase_id: doc.id,
      name: doc.data.name || 'Empresa',
      nit: doc.data.nit || null,
      logo_url: doc.data.logoUrl || null,
      sector: doc.data.sector || null,
      size_label: doc.data.size || null,
      city: doc.data.city || null,
      country: doc.data.country || null,
      region: doc.data.region || null,
      website: doc.data.website || null,
      description: doc.data.description || null,
      status: mapped.postgres_status,
      archived: doc.data.archived === true,
      archived_at: toIso(doc.data.archivedAt),
      plan: doc.data.plan || null,
      contract_value: doc.data.contractValue ?? null,
      mrr: doc.data.mrr ?? null,
      renewal_at: toIso(doc.data.renewalAt),
      commercial_stage: ['prospect', 'contacted', 'meeting', 'proposal', 'negotiation', 'client'].includes(stage)
        ? stage
        : null,
      last_activity_at: toIso(doc.data.lastActivityAt),
      created_at: toIso(doc.data.createdAt) || undefined,
    }];
  }),
  'firebase_id',
);
const orgByFirebase = Object.fromEntries(orgs.map((row) => [row.firebase_id, row]));
report.loaded.organizations = orgs.length;
await mapIds('companies', orgs);

const memberships = [];
for (const doc of data.users) {
  const profile = profileByUid[doc.id];
  const mapped = roleMap[doc.data.role] || roleMap.user;
  if (!profile || !mapped?.creates_membership) continue;
  const org = orgByFirebase[doc.data.companyId];
  if (!org) {
    if (doc.data.companyId) reject('users', doc.id, 'membership_org_missing', { companyId: doc.data.companyId });
    continue;
  }
  memberships.push({
    organization_id: org.id,
    profile_id: profile.id,
    role: mapped.membership_role,
    legacy_role: doc.data.role,
    is_active: doc.data.isActive !== false,
  });
}
report.loaded.memberships = (await writeRows('memberships', memberships, 'organization_id,profile_id')).length;

const cultures = orgs.map((org) => {
  const source = data.companies.find((doc) => doc.id === org.firebase_id)?.data || {};
  return {
    organization_id: org.id,
    version_number: 1,
    values_list: parseDna(source.valuesList, source.valuesText),
    culture_list: parseDna(source.cultureList, source.culture),
    standout_list: parseDna(source.standoutList, source.standoutPeople),
    sought_characteristics: source.soughtCharacteristics || null,
    is_current: true,
  };
});
const cultureRows = await writeRows('organization_culture_versions', cultures, 'organization_id,version_number');
report.loaded.organization_culture_versions = cultureRows.length;

const dnaRows = data.dna_catalog.flatMap((doc) => {
  const type = doc.data.type;
  if (!['values', 'culture', 'standout', 'area'].includes(type)) {
    reject('dna_catalog', doc.id, 'unknown_type', { type });
    return [];
  }
  const org = doc.data.companyId ? orgByFirebase[doc.data.companyId] : null;
  if (doc.data.companyId && !org) {
    reject('dna_catalog', doc.id, 'org_missing');
    return [];
  }
  return [{
    firebase_id: doc.id,
    type,
    label_es: doc.data.labelEs || doc.data.label || doc.id,
    label_en: doc.data.labelEn || null,
    source: doc.data.source === 'company' ? 'company' : 'seed',
    organization_id: org?.id || null,
  }];
});
const dnaSaved = await writeRows('dna_catalog_entries', dnaRows, 'firebase_id');
report.loaded.dna_catalog_entries = dnaSaved.length;
await mapIds('dna_catalog', dnaSaved);

const vacancies = await writeRows(
  'vacancies',
  data.vacancies.flatMap((doc) => {
    const org = orgByFirebase[doc.data.companyId];
    if (!org) {
      reject('vacancies', doc.id, 'org_missing', { companyId: doc.data.companyId });
      return [];
    }
    return [{
      firebase_id: doc.id,
      organization_id: org.id,
      name: doc.data.name || 'Vacante',
      status: doc.data.status === 'closed' ? 'closed' : 'active',
      area: doc.data.area || null,
      description: doc.data.description || null,
      city: doc.data.city || null,
      country: doc.data.country || null,
      region: doc.data.region || null,
      work_mode: doc.data.workMode || null,
      contract_type: doc.data.contractType || null,
      seniority: doc.data.seniority || null,
      role_profile: doc.data.roleProfile || null,
      created_at: toIso(doc.data.createdAt) || undefined,
    }];
  }),
  'firebase_id',
);
const vacancyByFirebase = Object.fromEntries(vacancies.map((row) => [row.firebase_id, row]));
report.loaded.vacancies = vacancies.length;
await mapIds('vacancies', vacancies);

const personByEmail = new Map();
const personRows = [];
for (const doc of data.candidates) {
  const email = emailOf(doc.data.email);
  if (!email.includes('@')) {
    reject('candidates', doc.id, 'invalid_email');
    continue;
  }
  const documentNumber = String(doc.data.documentNumber || '').trim() || null;
  const existing = personByEmail.get(email);
  if (existing) {
    if (documentNumber && existing.document_number && documentNumber !== existing.document_number) {
      reject('candidates', doc.id, 'email_document_conflict', {
        email,
        existingDocument: existing.document_number,
        documentNumber,
      });
    }
    continue;
  }
  const row = { email, document_number: documentNumber, display_name: doc.data.displayName || null };
  personByEmail.set(email, row);
  personRows.push(row);
}
const persons = await writeRows('persons', personRows, 'email');
for (const row of persons) personByEmail.set(row.email, row);
report.loaded.persons = persons.length;

const applications = await writeRows(
  'applications',
  data.candidates.flatMap((doc) => {
    const email = emailOf(doc.data.email);
    const person = personByEmail.get(email);
    const org = orgByFirebase[doc.data.companyId];
    const vacancy = vacancyByFirebase[doc.data.vacancyId];
    if (!person?.id) {
      reject('candidates', doc.id, 'person_missing');
      return [];
    }
    if (!org || !vacancy || vacancy.organization_id !== org.id) {
      reject('candidates', doc.id, 'org_or_vacancy_mismatch', {
        companyId: doc.data.companyId,
        vacancyId: doc.data.vacancyId,
      });
      return [];
    }
    const status = PROCESS.has(doc.data.processStatus) ? doc.data.processStatus : 'pending';
    const kind = doc.data.assessmentKind === 'fit' || doc.data.assessmentKind === 'affinity'
      ? doc.data.assessmentKind
      : null;
    return [{
      firebase_candidate_id: doc.id,
      organization_id: org.id,
      vacancy_id: vacancy.id,
      person_id: person.id,
      vacancy_name: doc.data.vacancyName || vacancy.name,
      process_status: status,
      assessment_kind: kind,
      company_affinity: ['high', 'medium', 'low', 'unknown'].includes(doc.data.companyAffinity)
        ? doc.data.companyAffinity
        : 'unknown',
      vacancy_affinity: ['high', 'medium', 'low', 'unknown'].includes(doc.data.vacancyAffinity)
        ? doc.data.vacancyAffinity
        : 'unknown',
      evaluation_completed: doc.data.evaluationCompleted === true,
      result_requested: doc.data.resultRequested === true,
      result_requested_at: toIso(doc.data.resultRequestedAt),
    }];
  }),
  'firebase_candidate_id',
);
const applicationByCandidate = Object.fromEntries(
  applications.map((row) => [row.firebase_candidate_id, row]),
);
report.loaded.applications = applications.length;
await mapIds('candidates', applications.map((row) => ({ ...row, firebase_id: row.firebase_candidate_id })));

await writeRows(
  'application_status_events',
  applications.map((row) => ({
    application_id: row.id,
    organization_id: row.organization_id,
    to_status: row.process_status,
  })),
);
report.loaded.application_status_events = applications.length;

const existingSections = await sb(
  `survey_sections?select=id,code,version_id&version_id=eq.${affinityVersion.id}`,
);
const sectionByCode = Object.fromEntries(existingSections.map((row) => [row.code, row]));
for (const [code, title, sort] of [
  ['values', 'Valores', 1],
  ['needs', 'Necesidades', 2],
  ['capabilities', 'Experiencias', 3],
]) {
  if (!sectionByCode[code]) {
    const created = await writeRows('survey_sections', [{
      version_id: affinityVersion.id,
      code,
      title,
      sort_order: sort,
    }]);
    sectionByCode[code] = created[0];
  }
}

const questionRows = data.assessment_questions.flatMap((doc, index) => {
  const front = doc.data.front === 'needs' || doc.data.front === 'capabilities' ? doc.data.front : 'values';
  const section = sectionByCode[front];
  const format = doc.data.format === 'experience' ? 'experience' : 'pair';
  return [{
    section_id: section.id,
    code: doc.id,
    format,
    instruction: doc.data.instruction || null,
    statement_a: doc.data.statementA || doc.id,
    statement_b: doc.data.statementB || null,
    dimension_a: doc.data.dimensionA || null,
    dimension_b: doc.data.dimensionB || null,
    time_limit_seconds: doc.data.timeLimitSeconds ?? null,
    sort_order: doc.data.order ?? index,
    is_required: true,
    is_active: doc.data.active !== false,
  }];
});
const questions = questionRows.length
  ? await writeRows('survey_questions', questionRows, 'section_id,code')
  : [];
const questionByCode = Object.fromEntries(questions.map((row) => [row.code, row]));
report.loaded.survey_questions = questions.length;
await mapIds(
  'assessment_questions',
  questions.map((row) => ({ firebase_id: row.code, id: row.id })),
);

const optionRows = [];
for (const doc of data.assessment_questions) {
  const question = questionByCode[doc.id];
  if (!question) continue;
  const options = Array.isArray(doc.data.options) ? doc.data.options : [];
  options.forEach((label, index) => {
    optionRows.push({
      question_id: question.id,
      value_int: index + 1,
      label: String(label),
      sort_order: index + 1,
    });
  });
}
report.loaded.survey_options = optionRows.length
  ? (await writeRows('survey_options', optionRows, 'question_id,value_int')).length
  : 0;

const sessionRows = [];
const answerRows = [];
const evaluationRows = [];
for (const doc of data.evaluations) {
  const application = applicationByCandidate[doc.id];
  if (!application) {
    reject('evaluations', doc.id, 'application_missing');
    continue;
  }
  sessionRows.push({
    _candidateId: doc.id,
    version_id: affinityVersion.id,
    purpose: 'affinity',
    organization_id: application.organization_id,
    application_id: application.id,
    person_id: application.person_id,
    locale: 'es',
    status: doc.data.completed === true ? 'completed' : 'in_progress',
    completed_at: doc.data.completed === true ? toIso(doc.data.completedAt) || new Date().toISOString() : null,
  });
  const answers = doc.data.answers && typeof doc.data.answers === 'object' ? doc.data.answers : {};
  for (const [code, value] of Object.entries(answers)) {
    const question = questionByCode[code];
    if (!question) continue;
    answerRows.push({
      _candidateId: doc.id,
      question_id: question.id,
      value_int: Number(value),
      question_code: question.code,
      format: question.format,
      statement_a: question.statement_a,
      statement_b: question.statement_b,
    });
  }
  evaluationRows.push({
    firebase_evaluation_id: doc.id,
    application_id: application.id,
    organization_id: application.organization_id,
    status: doc.data.completed === true ? 'completed' : 'in_progress',
    dimension_scores: doc.data.dimensionScores || null,
    completed_at: toIso(doc.data.completedAt),
    _candidateId: doc.id,
  });
}
const sessions = await writeRows(
  'survey_sessions',
  sessionRows.map(({ _candidateId, ...row }) => row),
);
const sessionByCandidate = {};
sessionRows.forEach((row, index) => {
  sessionByCandidate[row._candidateId] = sessions[index];
});
report.loaded.survey_sessions = sessions.length;
await writeRows(
  'survey_answers',
  answerRows.flatMap((row) => {
    const session = sessionByCandidate[row._candidateId];
    if (!session) return [];
    const { _candidateId, ...rest } = row;
    return [{ ...rest, session_id: session.id }];
  }),
  'session_id,question_id',
);
report.loaded.survey_answers = answerRows.length;
const evaluations = await writeRows(
  'affinity_evaluations',
  evaluationRows.map((row) => ({
    firebase_evaluation_id: row.firebase_evaluation_id,
    application_id: row.application_id,
    organization_id: row.organization_id,
    session_id: sessionByCandidate[row._candidateId]?.id || null,
    status: row.status,
    dimension_scores: row.dimension_scores,
    completed_at: row.completed_at,
  })),
  'firebase_evaluation_id',
);
const evaluationByCandidate = Object.fromEntries(
  evaluations.map((row) => [row.firebase_evaluation_id, row]),
);
report.loaded.affinity_evaluations = evaluations.length;
await mapIds('evaluations', evaluations.map((row) => ({ firebase_id: row.firebase_evaluation_id, id: row.id })));

const reports = await writeRows(
  'evaluation_reports',
  data.affinity_analyses.flatMap((doc) => {
    const evaluation = evaluationByCandidate[doc.id] || evaluationByCandidate[doc.data.candidateId];
    const application = applicationByCandidate[doc.id] || applicationByCandidate[doc.data.candidateId];
    if (!evaluation || !application) {
      reject('affinity_analyses', doc.id, 'evaluation_or_application_missing');
      return [];
    }
    const status = ['pending', 'completed', 'failed', 'insufficient_data'].includes(doc.data.status)
      ? doc.data.status
      : 'pending';
    return [{
      evaluation_id: evaluation.id,
      application_id: application.id,
      organization_id: application.organization_id,
      status,
      level: ['high', 'medium', 'low', 'unknown'].includes(doc.data.level) ? doc.data.level : null,
      score: Number.isFinite(Number(doc.data.score)) ? Number(doc.data.score) : null,
      confidence: ['high', 'medium', 'low', 'unknown'].includes(doc.data.confidence)
        ? doc.data.confidence
        : null,
      summary: doc.data.summary || null,
      alignments: doc.data.alignments || [],
      differences: doc.data.differences || [],
      conversation_topics: Array.isArray(doc.data.conversationTopics) ? doc.data.conversationTopics : [],
      guidance: doc.data.guidance || null,
      data_gaps: Array.isArray(doc.data.dataGaps) ? doc.data.dataGaps : [],
      model: doc.data.model || null,
      prompt_version: doc.data.promptVersion || null,
      error_code: doc.data.error || null,
      analyzed_at: toIso(doc.data.analyzedAt),
    }];
  }),
  'evaluation_id',
);
report.loaded.evaluation_reports = reports.length;
await mapIds(
  'affinity_analyses',
  data.affinity_analyses.flatMap((doc) => {
    const evaluation = evaluationByCandidate[doc.id] || evaluationByCandidate[doc.data.candidateId];
    return evaluation ? [{ firebase_id: doc.id, id: reports.find((row) => row.evaluation_id === evaluation.id)?.id }] : [];
  }).filter((row) => row.id),
);

for (const doc of data.survey_result_requests) {
  const application = applicationByCandidate[doc.id] || applicationByCandidate[doc.data.candidateId];
  if (!application) {
    reject('survey_result_requests', doc.id, 'application_missing');
    continue;
  }
  await sb('applications', {
    method: 'POST',
    query: '?on_conflict=id',
    body: [{
      id: application.id,
      organization_id: application.organization_id,
      vacancy_id: application.vacancy_id,
      person_id: application.person_id,
      result_requested: true,
      result_requested_at: toIso(doc.data.requestedAt) || application.result_requested_at,
    }],
  });
}

const invites = await writeRows(
  'activation_invites',
  data.activation_invites.flatMap((doc) => {
    const org = orgByFirebase[doc.data.companyId];
    if (!org) {
      reject('activation_invites', doc.id, 'org_missing');
      return [];
    }
    const vacancy = doc.data.vacancyId ? vacancyByFirebase[doc.data.vacancyId] : null;
    const application = doc.data.candidateId ? applicationByCandidate[doc.data.candidateId] : null;
    return [{
      email: emailOf(doc.data.email || doc.id),
      organization_id: org.id,
      vacancy_id: vacancy && vacancy.organization_id === org.id ? vacancy.id : null,
      kind: doc.data.kind === 'respondent' ? 'respondent' : 'recruiter',
      role: doc.data.role || null,
      token_hash: doc.data.tokenHash || null,
      pin_hash: doc.data.pinHash || null,
      pin_algorithm: 'fnv1a32',
      used: doc.data.used === true,
      application_id: application?.id || null,
      first_name: doc.data.firstName || null,
      last_name: doc.data.lastName || null,
      document_number: doc.data.documentNumber || null,
      pin_expires_at: toIso(doc.data.pinExpiresAt),
      token_expires_at: toIso(doc.data.tokenExpiresAt),
      created_at: toIso(doc.data.createdAt) || undefined,
    }];
  }),
);
report.loaded.activation_invites = invites.length;
await mapIds(
  'activation_invites',
  invites.map((row, index) => ({
    firebase_id: data.activation_invites[index]?.id,
    id: row.id,
  })).filter((row) => row.firebase_id),
);

const activities = await writeRows(
  'activity_events',
  data.activity_events.map((doc) => ({
    firebase_id: doc.id,
    organization_id: orgByFirebase[doc.data.companyId]?.id || null,
    kind: ACTIVITY.has(doc.data.kind) ? doc.data.kind : 'statusChanged',
    entity_name: doc.data.entityName || 'evento',
    status_label: doc.data.statusLabel || null,
    context: doc.data.context || null,
    created_at: toIso(doc.data.createdAt) || undefined,
  })),
  'firebase_id',
);
report.loaded.activity_events = activities.length;
await mapIds('activity_events', activities);

const audits = data.admin_audit_logs.flatMap((doc) => {
  const metadata = doc.data.metadata && typeof doc.data.metadata === 'object' ? doc.data.metadata : {};
  if (Object.keys(metadata).some((key) => SECRET.test(key))) {
    reject('admin_audit_logs', doc.id, 'secret_metadata');
    return [];
  }
  return [{
    organization_id: orgByFirebase[doc.data.companyId]?.id || null,
    action: doc.data.action || doc.data.kind || 'imported',
    entity: doc.data.entity || doc.data.entityName || 'unknown',
    metadata,
    created_at: toIso(doc.data.createdAt) || undefined,
  }];
});
report.loaded.audit_logs = (await writeRows('audit_logs', audits)).length;

writeFileSync(rejectsPath, rejects.map((item) => JSON.stringify(item)).join('\n') + (rejects.length ? '\n' : ''));
report.rejected = rejects.length;
writeFileSync(reportPath, JSON.stringify(report, null, 2));
console.log(JSON.stringify({ loaded: report.loaded, rejected: rejects.length }, null, 2));
