-- TaleX relational schema for PostgreSQL / Supabase.
-- Phase 1: create the target model. Firebase remains the live source of truth.
-- Auth stays on Firebase. Authenticated table access requires a server-minted
-- JWT that carries firebase_uid. Anon can only call public survey RPCs.

create schema if not exists extensions;
create extension if not exists pgcrypto with schema extensions;

do $$
begin
  if not exists (select 1 from pg_roles where rolname = 'anon') then
    create role anon nologin noinherit;
  end if;
  if not exists (select 1 from pg_roles where rolname = 'authenticated') then
    create role authenticated nologin noinherit;
  end if;
  if not exists (select 1 from pg_roles where rolname = 'service_role') then
    create role service_role nologin bypassrls;
  end if;
end
$$;

create or replace function public.set_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

create or replace function public.normalize_email(p_email text)
returns text
language sql
immutable
as $$
  select lower(btrim(p_email));
$$;

create or replace function public.normalize_email_trigger()
returns trigger
language plpgsql
as $$
begin
  new.email := public.normalize_email(new.email);
  return new;
end;
$$;

create or replace function public.token_hash(p_token text)
returns text
language plpgsql
immutable
set search_path = public, extensions
as $$
begin
  return encode(digest(convert_to(btrim(p_token), 'UTF8'), 'sha256'), 'hex');
end;
$$;

create or replace function public.generate_survey_token()
returns text
language plpgsql
volatile
set search_path = public, extensions
as $$
begin
  return replace(replace(rtrim(encode(gen_random_bytes(32), 'base64'), '='), '+', '-'), '/', '_');
end;
$$;

create or replace function public.jsonb_contains_secret_key(payload jsonb)
returns boolean
language plpgsql
immutable
as $$
declare
  secret_key text;
  secret_value jsonb;
begin
  if payload is null or jsonb_typeof(payload) <> 'object' then
    return false;
  end if;

  for secret_key, secret_value in select * from jsonb_each(payload)
  loop
    if lower(secret_key) ~ '(password|token|pin|secret|apikey|service_role|pin_hash|token_hash)' then
      return true;
    end if;
    if jsonb_typeof(secret_value) = 'object'
      and public.jsonb_contains_secret_key(secret_value) then
      return true;
    end if;
  end loop;

  return false;
end;
$$;

-- ---------------------------------------------------------------------------
-- Documented, reversible mappings from Firestore values
-- ---------------------------------------------------------------------------

create table public.legacy_role_map (
  firestore_role text primary key,
  membership_role text,
  creates_membership boolean not null,
  is_superadmin boolean not null default false,
  notes text not null
);

insert into public.legacy_role_map (
  firestore_role, membership_role, creates_membership, is_superadmin, notes
) values
  ('superadmin', null, false, true, 'Global flag on profiles.is_superadmin. No company membership.'),
  ('respondent', null, false, false, 'Candidate session. No membership. Link via applications.'),
  ('user', null, false, false, 'Placeholder after Google sign-in, before an invite assigns a staff role.'),
  ('company_admin', 'company_admin', true, false, 'Identity mapping.'),
  ('company_lead', 'company_lead', true, false, 'Identity mapping.'),
  ('ceo', 'company_lead', true, false, 'Legacy alias. Preserve firestore_role in memberships.legacy_role.'),
  ('people_ops', 'people_ops', true, false, 'Identity mapping.'),
  ('hr', 'people_ops', true, false, 'Legacy alias. Preserve firestore_role in memberships.legacy_role.'),
  ('recruiter', 'recruiter', true, false, 'Identity mapping.'),
  ('hiring_manager', 'hiring_manager', true, false, 'Identity mapping.');

create table public.legacy_company_status_map (
  firestore_status text primary key,
  postgres_status text not null,
  notes text not null
);

insert into public.legacy_company_status_map (firestore_status, postgres_status, notes) values
  ('active', 'active', 'Identity mapping.'),
  ('onboarding', 'onboarding', 'Default when a company is provisioned.'),
  ('inactive', 'inactive', 'Identity mapping.'),
  ('atRisk', 'atRisk', 'Preserve camelCase from CompanyStatus.name / Firestore.'),
  ('suspended', 'suspended', 'Identity mapping.');

-- ---------------------------------------------------------------------------
-- Identity and tenancy
-- ---------------------------------------------------------------------------

create table public.profiles (
  id uuid primary key default gen_random_uuid(),
  firebase_uid text unique,
  email text not null,
  display_name text,
  is_active boolean not null default true,
  is_superadmin boolean not null default false,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint profiles_email_format check (position('@' in email) > 1),
  constraint profiles_email_normalized check (email = public.normalize_email(email)),
  constraint profiles_email_unique unique (email)
);

create table public.organizations (
  id uuid primary key default gen_random_uuid(),
  firebase_id text unique,
  name text not null,
  nit text,
  logo_url text,
  sector text,
  size_label text,
  city text,
  country text,
  region text,
  website text,
  description text,
  status text not null default 'onboarding'
    check (status in ('active', 'onboarding', 'inactive', 'atRisk', 'suspended')),
  archived boolean not null default false,
  archived_at timestamptz,
  plan text,
  contract_value numeric,
  mrr numeric,
  renewal_at timestamptz,
  commercial_stage text
    check (commercial_stage is null or commercial_stage in (
      'prospect', 'contacted', 'meeting', 'proposal', 'negotiation', 'client'
    )),
  last_activity_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table public.memberships (
  id uuid primary key default gen_random_uuid(),
  organization_id uuid not null references public.organizations (id) on delete restrict,
  profile_id uuid not null references public.profiles (id) on delete restrict,
  role text not null check (role in (
    'company_admin',
    'company_lead',
    'people_ops',
    'recruiter',
    'hiring_manager'
  )),
  legacy_role text,
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (organization_id, profile_id)
);

create index memberships_profile_idx on public.memberships (profile_id)
  where is_active;

-- ---------------------------------------------------------------------------
-- Declared culture (official, versioned). Perception never overwrites this.
-- ---------------------------------------------------------------------------

create table public.organization_culture_versions (
  id uuid primary key default gen_random_uuid(),
  organization_id uuid not null references public.organizations (id) on delete restrict,
  version_number integer not null check (version_number > 0),
  values_list text[] not null default '{}',
  culture_list text[] not null default '{}',
  standout_list text[] not null default '{}',
  sought_characteristics text,
  is_current boolean not null default false,
  published_by uuid references public.profiles (id) on delete set null,
  published_at timestamptz not null default now(),
  unique (organization_id, version_number),
  unique (id, organization_id)
);

create unique index organization_culture_current_idx
  on public.organization_culture_versions (organization_id)
  where is_current;

create table public.dna_catalog_entries (
  id uuid primary key default gen_random_uuid(),
  type text not null check (type in ('values', 'culture', 'standout', 'area')),
  label_es text not null,
  label_en text,
  source text not null default 'seed' check (source in ('seed', 'company')),
  organization_id uuid references public.organizations (id) on delete restrict,
  firebase_id text unique,
  created_at timestamptz not null default now()
);

-- ---------------------------------------------------------------------------
-- Vacancies, persons, applications
-- ---------------------------------------------------------------------------

create table public.vacancies (
  id uuid primary key default gen_random_uuid(),
  organization_id uuid not null references public.organizations (id) on delete restrict,
  firebase_id text unique,
  name text not null,
  status text not null default 'active' check (status in ('active', 'closed')),
  area text,
  description text,
  city text,
  country text,
  region text,
  work_mode text,
  contract_type text,
  seniority text,
  role_profile text,
  created_by uuid references public.profiles (id) on delete set null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (id, organization_id)
);

create index vacancies_org_status_idx on public.vacancies (organization_id, status);

create table public.persons (
  id uuid primary key default gen_random_uuid(),
  email text not null,
  document_number text,
  display_name text,
  linked_profile_id uuid references public.profiles (id) on delete set null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint persons_email_format check (position('@' in email) > 1),
  constraint persons_email_normalized check (email = public.normalize_email(email)),
  constraint persons_email_unique unique (email)
);

comment on column public.persons.document_number is
  'Not globally unique. Import must flag same-document/different-email rows instead of merging.';

create index persons_document_idx
  on public.persons (document_number)
  where document_number is not null and document_number <> '';

create table public.applications (
  id uuid primary key default gen_random_uuid(),
  organization_id uuid not null,
  vacancy_id uuid not null,
  person_id uuid not null references public.persons (id) on delete restrict,
  firebase_candidate_id text unique,
  vacancy_name text,
  process_status text not null default 'pending' check (process_status in (
    'pending', 'inProgress', 'completed', 'inReview', 'shortlisted',
    'interview', 'finalist', 'hired', 'rejected'
  )),
  assessment_kind text check (assessment_kind is null or assessment_kind in ('affinity', 'fit')),
  company_affinity text not null default 'unknown'
    check (company_affinity in ('high', 'medium', 'low', 'unknown')),
  vacancy_affinity text not null default 'unknown'
    check (vacancy_affinity in ('high', 'medium', 'low', 'unknown')),
  evaluation_completed boolean not null default false,
  result_requested boolean not null default false,
  result_requested_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (organization_id, vacancy_id, person_id),
  unique (id, organization_id),
  foreign key (vacancy_id, organization_id)
    references public.vacancies (id, organization_id)
);

create index applications_org_status_idx
  on public.applications (organization_id, process_status);
create index applications_person_idx on public.applications (person_id);

create table public.application_status_events (
  id uuid primary key default gen_random_uuid(),
  application_id uuid not null,
  organization_id uuid not null,
  from_status text,
  to_status text not null check (to_status in (
    'pending', 'inProgress', 'completed', 'inReview', 'shortlisted',
    'interview', 'finalist', 'hired', 'rejected'
  )),
  changed_by uuid references public.profiles (id) on delete set null,
  changed_at timestamptz not null default now(),
  foreign key (application_id, organization_id)
    references public.applications (id, organization_id)
);

create index application_status_events_application_idx
  on public.application_status_events (application_id);

-- ---------------------------------------------------------------------------
-- Survey engine (affinity + culture perception share the same tables)
-- ---------------------------------------------------------------------------

create table public.survey_templates (
  id uuid primary key default gen_random_uuid(),
  slug text not null unique,
  purpose text not null check (purpose in ('affinity', 'culture_perception')),
  title text not null,
  description text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table public.survey_versions (
  id uuid primary key default gen_random_uuid(),
  template_id uuid not null references public.survey_templates (id) on delete restrict,
  version_number integer not null check (version_number > 0),
  status text not null default 'draft'
    check (status in ('draft', 'published', 'retired')),
  published_at timestamptz,
  created_at timestamptz not null default now(),
  unique (template_id, version_number)
);

create table public.survey_sections (
  id uuid primary key default gen_random_uuid(),
  version_id uuid not null references public.survey_versions (id) on delete restrict,
  code text not null,
  title text not null,
  sort_order integer not null default 0,
  unique (version_id, code)
);

create table public.survey_questions (
  id uuid primary key default gen_random_uuid(),
  section_id uuid not null references public.survey_sections (id) on delete restrict,
  code text not null,
  format text not null check (format in (
    'pair', 'experience', 'single', 'multi', 'scale', 'text'
  )),
  instruction text,
  statement_a text not null,
  statement_b text,
  dimension_a text,
  dimension_b text,
  time_limit_seconds integer,
  sort_order integer not null default 0,
  is_required boolean not null default true,
  is_active boolean not null default true,
  unique (section_id, code)
);

create table public.survey_options (
  id uuid primary key default gen_random_uuid(),
  question_id uuid not null references public.survey_questions (id) on delete restrict,
  value_int integer not null,
  label text not null,
  sort_order integer not null default 0,
  unique (question_id, value_int)
);

create table public.public_survey_links (
  id uuid primary key default gen_random_uuid(),
  organization_id uuid not null references public.organizations (id) on delete restrict,
  version_id uuid not null references public.survey_versions (id) on delete restrict,
  token_hash text not null unique,
  status text not null default 'active' check (status in ('active', 'revoked', 'expired')),
  expires_at timestamptz,
  max_responses integer not null default 1000
    check (max_responses > 0 and max_responses <= 10000),
  response_count integer not null default 0 check (response_count >= 0),
  created_by uuid references public.profiles (id) on delete set null,
  created_at timestamptz not null default now(),
  unique (id, organization_id)
);

create table public.survey_sessions (
  id uuid primary key default gen_random_uuid(),
  version_id uuid not null references public.survey_versions (id) on delete restrict,
  purpose text not null check (purpose in ('affinity', 'culture_perception')),
  organization_id uuid not null references public.organizations (id) on delete restrict,
  application_id uuid,
  person_id uuid references public.persons (id) on delete restrict,
  public_link_id uuid,
  locale text not null default 'es',
  status text not null default 'in_progress'
    check (status in ('in_progress', 'completed', 'abandoned')),
  started_at timestamptz not null default now(),
  completed_at timestamptz,
  unique (id, organization_id),
  constraint survey_sessions_context check (
    (purpose = 'affinity'
      and application_id is not null
      and public_link_id is null)
    or (purpose = 'culture_perception'
      and public_link_id is not null
      and application_id is null
      and person_id is null)
  ),
  foreign key (application_id, organization_id)
    references public.applications (id, organization_id),
  foreign key (public_link_id, organization_id)
    references public.public_survey_links (id, organization_id)
);

create index survey_sessions_org_purpose_idx
  on public.survey_sessions (organization_id, purpose, status);
create index survey_sessions_application_idx
  on public.survey_sessions (application_id);
create index survey_sessions_public_link_idx
  on public.survey_sessions (public_link_id);

create table public.survey_answers (
  id uuid primary key default gen_random_uuid(),
  session_id uuid not null references public.survey_sessions (id) on delete restrict,
  question_id uuid not null references public.survey_questions (id) on delete restrict,
  value_int integer,
  value_text text,
  question_code text,
  format text,
  statement_a text,
  statement_b text,
  option_label text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (session_id, question_id),
  constraint survey_answers_has_value check (
    value_int is not null or (value_text is not null and value_text <> '')
  )
);

create table public.survey_submission_keys (
  id uuid primary key default gen_random_uuid(),
  public_link_id uuid not null references public.public_survey_links (id) on delete restrict,
  key_hash text not null,
  session_id uuid not null references public.survey_sessions (id) on delete restrict,
  created_at timestamptz not null default now(),
  unique (public_link_id, key_hash)
);

create table public.culture_perception_results (
  id uuid primary key default gen_random_uuid(),
  session_id uuid not null unique,
  organization_id uuid not null,
  culture_version_id uuid not null,
  processed_at timestamptz not null default now(),
  notes text,
  foreign key (session_id, organization_id)
    references public.survey_sessions (id, organization_id),
  foreign key (culture_version_id, organization_id)
    references public.organization_culture_versions (id, organization_id)
);

-- ---------------------------------------------------------------------------
-- Affinity evaluations and reports (algorithm stays in Cloud Functions)
-- ---------------------------------------------------------------------------

create table public.affinity_evaluations (
  id uuid primary key default gen_random_uuid(),
  application_id uuid not null,
  session_id uuid,
  organization_id uuid not null,
  firebase_evaluation_id text unique,
  status text not null default 'in_progress'
    check (status in ('in_progress', 'completed', 'failed')),
  dimension_scores jsonb,
  completed_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (application_id),
  unique (id, organization_id),
  foreign key (application_id, organization_id)
    references public.applications (id, organization_id),
  foreign key (session_id, organization_id)
    references public.survey_sessions (id, organization_id)
);

create index affinity_evaluations_application_idx
  on public.affinity_evaluations (application_id);

create table public.evaluation_reports (
  id uuid primary key default gen_random_uuid(),
  evaluation_id uuid not null unique,
  application_id uuid not null,
  organization_id uuid not null,
  status text not null default 'pending'
    check (status in ('pending', 'completed', 'failed', 'insufficient_data')),
  level text check (level in ('high', 'medium', 'low', 'unknown')),
  score integer check (score is null or (score >= 0 and score <= 100)),
  confidence text check (confidence is null or confidence in ('high', 'medium', 'low', 'unknown')),
  summary text,
  alignments jsonb not null default '[]'::jsonb,
  differences jsonb not null default '[]'::jsonb,
  conversation_topics text[] not null default '{}',
  guidance text,
  data_gaps text[] not null default '{}',
  model text,
  prompt_version text,
  error_code text,
  analyzed_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  foreign key (evaluation_id, organization_id)
    references public.affinity_evaluations (id, organization_id),
  foreign key (application_id, organization_id)
    references public.applications (id, organization_id)
);

-- ---------------------------------------------------------------------------
-- Invites, mapping, activity and audit
-- ---------------------------------------------------------------------------

create table public.activation_invites (
  id uuid primary key default gen_random_uuid(),
  email text not null,
  organization_id uuid not null references public.organizations (id) on delete restrict,
  vacancy_id uuid,
  kind text not null check (kind in ('recruiter', 'respondent')),
  role text,
  token_hash text unique,
  pin_hash text,
  pin_algorithm text not null default 'fnv1a32'
    check (pin_algorithm in ('fnv1a32', 'bfcrypt')),
  used boolean not null default false,
  application_id uuid,
  first_name text,
  last_name text,
  document_number text,
  pin_expires_at timestamptz,
  token_expires_at timestamptz,
  expires_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint invites_email_normalized check (email = public.normalize_email(email)),
  foreign key (vacancy_id, organization_id)
    references public.vacancies (id, organization_id),
  foreign key (application_id, organization_id)
    references public.applications (id, organization_id)
);

create index activation_invites_email_idx on public.activation_invites (email);
create index activation_invites_org_idx on public.activation_invites (organization_id);

create table public.firebase_id_map (
  collection text not null,
  firebase_id text not null,
  postgres_id uuid not null,
  created_at timestamptz not null default now(),
  primary key (collection, firebase_id),
  unique (collection, postgres_id),
  constraint firebase_id_map_collection check (collection in (
    'users',
    'companies',
    'vacancies',
    'candidates',
    'evaluations',
    'affinity_analyses',
    'assessment_questions',
    'activation_invites',
    'admin_audit_logs',
    'activity_events',
    'dna_catalog',
    'survey_result_requests'
  ))
);

create table public.activity_events (
  id uuid primary key default gen_random_uuid(),
  firebase_id text unique,
  organization_id uuid references public.organizations (id) on delete set null,
  actor_profile_id uuid references public.profiles (id) on delete set null,
  kind text not null check (kind in (
    'companyCreated',
    'companyActivated',
    'processCreated',
    'vacancyCreated',
    'respondentInvited',
    'evaluationStarted',
    'evaluationCompleted',
    'affinityDetected',
    'saleRecorded',
    'statusChanged'
  )),
  entity_name text not null,
  status_label text,
  context text,
  created_at timestamptz not null default now()
);

create index activity_events_org_created_idx
  on public.activity_events (organization_id, created_at desc);

create table public.audit_logs (
  id uuid primary key default gen_random_uuid(),
  actor_profile_id uuid references public.profiles (id) on delete set null,
  organization_id uuid references public.organizations (id) on delete set null,
  action text not null,
  entity text not null,
  entity_id uuid,
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  constraint audit_logs_no_secrets check (
    not public.jsonb_contains_secret_key(metadata)
  )
);

create or replace view public.survey_published_questions as
select
  q.id,
  q.code,
  q.format,
  q.instruction,
  q.statement_a,
  q.statement_b,
  q.time_limit_seconds,
  q.sort_order,
  q.is_required,
  q.is_active,
  s.id as section_id,
  s.code as section_code,
  s.title as section_title,
  s.sort_order as section_sort,
  v.id as version_id,
  t.slug,
  t.purpose
from public.survey_questions q
join public.survey_sections s on s.id = q.section_id
join public.survey_versions v on v.id = s.version_id
join public.survey_templates t on t.id = v.template_id
where v.status = 'published'
  and t.purpose = 'affinity'
  and q.is_active;

create or replace view public.survey_published_options as
select
  o.id,
  o.question_id,
  o.value_int,
  o.label,
  o.sort_order
from public.survey_options o
join public.survey_published_questions q on q.id = o.question_id;

-- ---------------------------------------------------------------------------
-- Triggers: timestamps, email, snapshots, immutability, purpose checks
-- ---------------------------------------------------------------------------

create trigger profiles_email_normalize before insert or update on public.profiles
  for each row execute function public.normalize_email_trigger();
create trigger persons_email_normalize before insert or update on public.persons
  for each row execute function public.normalize_email_trigger();
create trigger invites_email_normalize before insert or update on public.activation_invites
  for each row execute function public.normalize_email_trigger();

create trigger profiles_updated_at before update on public.profiles
  for each row execute function public.set_updated_at();
create trigger organizations_updated_at before update on public.organizations
  for each row execute function public.set_updated_at();
create trigger memberships_updated_at before update on public.memberships
  for each row execute function public.set_updated_at();
create trigger vacancies_updated_at before update on public.vacancies
  for each row execute function public.set_updated_at();
create trigger persons_updated_at before update on public.persons
  for each row execute function public.set_updated_at();
create trigger applications_updated_at before update on public.applications
  for each row execute function public.set_updated_at();
create trigger survey_templates_updated_at before update on public.survey_templates
  for each row execute function public.set_updated_at();
create trigger survey_answers_updated_at before update on public.survey_answers
  for each row execute function public.set_updated_at();
create trigger affinity_evaluations_updated_at before update on public.affinity_evaluations
  for each row execute function public.set_updated_at();
create trigger evaluation_reports_updated_at before update on public.evaluation_reports
  for each row execute function public.set_updated_at();
create trigger activation_invites_updated_at before update on public.activation_invites
  for each row execute function public.set_updated_at();

create or replace function public.snapshot_survey_answer()
returns trigger
language plpgsql
set search_path = public
as $$
declare
  question public.survey_questions;
  option_label text;
begin
  select q.*
  into question
  from public.survey_questions q
  where q.id = new.question_id;

  if question.id is null then
    raise exception 'invalid_question';
  end if;

  if new.question_code is null then
    new.question_code := question.code;
  end if;
  if new.format is null then
    new.format := question.format;
  end if;
  if new.statement_a is null then
    new.statement_a := question.statement_a;
  end if;
  if new.statement_b is null then
    new.statement_b := question.statement_b;
  end if;
  if new.option_label is null and new.value_int is not null then
    select o.label
    into option_label
    from public.survey_options o
    where o.question_id = question.id
      and o.value_int = new.value_int;
    new.option_label := option_label;
  end if;

  return new;
end;
$$;

create trigger survey_answers_snapshot
  before insert on public.survey_answers
  for each row execute function public.snapshot_survey_answer();

create or replace function public.prevent_published_question_mutation()
returns trigger
language plpgsql
set search_path = public
as $$
declare
  version_status text;
begin
  select v.status
  into version_status
  from public.survey_versions v
  join public.survey_sections s on s.version_id = v.id
  where s.id = coalesce(new.section_id, old.section_id);

  if version_status = 'published' then
    raise exception 'published_version_immutable';
  end if;

  if tg_op = 'DELETE' then
    return old;
  end if;
  return new;
end;
$$;

create or replace function public.prevent_published_option_mutation()
returns trigger
language plpgsql
set search_path = public
as $$
declare
  version_status text;
begin
  select v.status
  into version_status
  from public.survey_versions v
  join public.survey_sections s on s.version_id = v.id
  join public.survey_questions q on q.section_id = s.id
  where q.id = coalesce(new.question_id, old.question_id);

  if version_status = 'published' then
    raise exception 'published_version_immutable';
  end if;

  if tg_op = 'DELETE' then
    return old;
  end if;
  return new;
end;
$$;

create or replace function public.prevent_published_section_mutation()
returns trigger
language plpgsql
set search_path = public
as $$
declare
  version_status text;
begin
  select v.status
  into version_status
  from public.survey_versions v
  where v.id = coalesce(new.version_id, old.version_id);

  if version_status = 'published' then
    raise exception 'published_version_immutable';
  end if;

  if tg_op = 'DELETE' then
    return old;
  end if;
  return new;
end;
$$;

create or replace function public.protect_published_survey_version()
returns trigger
language plpgsql
as $$
begin
  if old.status = 'published' then
    if new.status = 'retired'
      and new.template_id = old.template_id
      and new.version_number = old.version_number
      and new.published_at is not distinct from old.published_at then
      return new;
    end if;
    raise exception 'published_version_immutable';
  end if;
  return new;
end;
$$;

create or replace function public.protect_culture_version()
returns trigger
language plpgsql
as $$
begin
  if new.organization_id is distinct from old.organization_id
    or new.version_number is distinct from old.version_number
    or new.values_list is distinct from old.values_list
    or new.culture_list is distinct from old.culture_list
    or new.standout_list is distinct from old.standout_list
    or new.sought_characteristics is distinct from old.sought_characteristics
    or new.published_at is distinct from old.published_at
    or new.published_by is distinct from old.published_by then
    raise exception 'culture_version_immutable';
  end if;
  return new;
end;
$$;

create trigger survey_questions_immutable
  before update or delete on public.survey_questions
  for each row execute function public.prevent_published_question_mutation();
create trigger survey_options_immutable
  before update or delete on public.survey_options
  for each row execute function public.prevent_published_option_mutation();
create trigger survey_sections_immutable
  before update or delete on public.survey_sections
  for each row execute function public.prevent_published_section_mutation();
create trigger survey_versions_immutable
  before update on public.survey_versions
  for each row execute function public.protect_published_survey_version();
create trigger culture_versions_immutable
  before update on public.organization_culture_versions
  for each row execute function public.protect_culture_version();

create or replace function public.enforce_public_link_version()
returns trigger
language plpgsql
set search_path = public
as $$
declare
  version_row public.survey_versions;
  template_purpose text;
begin
  select *
  into version_row
  from public.survey_versions
  where id = new.version_id;

  select purpose
  into template_purpose
  from public.survey_templates
  where id = version_row.template_id;

  if version_row.status <> 'published' or template_purpose <> 'culture_perception' then
    raise exception 'invalid_public_survey_version';
  end if;
  return new;
end;
$$;

create trigger public_survey_links_version
  before insert or update on public.public_survey_links
  for each row execute function public.enforce_public_link_version();

create or replace function public.enforce_session_version_purpose()
returns trigger
language plpgsql
set search_path = public
as $$
declare
  version_row public.survey_versions;
  template_purpose text;
begin
  select *
  into version_row
  from public.survey_versions
  where id = new.version_id;

  select purpose
  into template_purpose
  from public.survey_templates
  where id = version_row.template_id;

  if template_purpose <> new.purpose then
    raise exception 'session_purpose_mismatch';
  end if;
  if new.purpose = 'culture_perception' and version_row.status <> 'published' then
    raise exception 'invalid_public_survey_version';
  end if;
  if new.purpose = 'affinity' and new.person_id is not null then
    if not exists (
      select 1
      from public.applications a
      where a.id = new.application_id
        and a.person_id = new.person_id
        and a.organization_id = new.organization_id
    ) then
      raise exception 'session_person_mismatch';
    end if;
  end if;
  return new;
end;
$$;

create trigger survey_sessions_purpose
  before insert or update on public.survey_sessions
  for each row execute function public.enforce_session_version_purpose();

-- ---------------------------------------------------------------------------
-- Authorization helpers. firebase_uid is a custom claim minted by a trusted
-- server after verifying a Firebase ID token. sub is never treated as a
-- Firebase uid.
-- ---------------------------------------------------------------------------

create or replace function public.jwt_firebase_uid()
returns text
language sql
stable
as $$
  select nullif(btrim(coalesce(auth.jwt() ->> 'firebase_uid', '')), '');
$$;

create or replace function public.current_profile_id()
returns uuid
language sql
stable
security definer
set search_path = public
as $$
  select p.id
  from public.profiles p
  where p.is_active
    and public.jwt_firebase_uid() is not null
    and p.firebase_uid = public.jwt_firebase_uid()
  limit 1;
$$;

create or replace function public.is_superadmin()
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1
    from public.profiles p
    where p.id = public.current_profile_id()
      and p.is_superadmin
  );
$$;

create or replace function public.is_org_member(org_id uuid)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select public.is_superadmin()
    or exists (
      select 1
      from public.memberships m
      where m.organization_id = org_id
        and m.profile_id = public.current_profile_id()
        and m.is_active
    );
$$;

create or replace function public.hash_invite_pin(p_pin text)
returns text
language plpgsql
volatile
set search_path = public, extensions
as $$
begin
  return crypt(p_pin, gen_salt('bf', 12));
end;
$$;

create or replace function public.fnv1a32_hex(p_value text)
returns text
language plpgsql
immutable
as $$
declare
  hash bigint := 2166136261;
  i integer;
begin
  for i in 1..octet_length(p_value)
  loop
    hash := ((hash # get_byte(convert_to(p_value, 'UTF8'), i - 1)) * 16777619) & 4294967295;
  end loop;
  return lpad(to_hex(hash), 8, '0');
end;
$$;

create or replace function public.verify_invite_pin(
  p_pin text,
  p_email text,
  p_hash text,
  p_algorithm text
)
returns boolean
language plpgsql
stable
set search_path = public, extensions
as $$
begin
  if p_algorithm = 'bfcrypt' then
    return crypt(p_pin, p_hash) = p_hash;
  end if;
  if p_algorithm = 'fnv1a32' then
    return public.fnv1a32_hex(public.normalize_email(p_email) || '|' || p_pin) = p_hash;
  end if;
  return false;
end;
$$;

-- ---------------------------------------------------------------------------
-- Row Level Security
-- ---------------------------------------------------------------------------

alter table public.legacy_role_map enable row level security;
alter table public.legacy_company_status_map enable row level security;
alter table public.profiles enable row level security;
alter table public.organizations enable row level security;
alter table public.memberships enable row level security;
alter table public.organization_culture_versions enable row level security;
alter table public.dna_catalog_entries enable row level security;
alter table public.vacancies enable row level security;
alter table public.persons enable row level security;
alter table public.applications enable row level security;
alter table public.application_status_events enable row level security;
alter table public.survey_templates enable row level security;
alter table public.survey_versions enable row level security;
alter table public.survey_sections enable row level security;
alter table public.survey_questions enable row level security;
alter table public.survey_options enable row level security;
alter table public.public_survey_links enable row level security;
alter table public.survey_sessions enable row level security;
alter table public.survey_answers enable row level security;
alter table public.survey_submission_keys enable row level security;
alter table public.culture_perception_results enable row level security;
alter table public.affinity_evaluations enable row level security;
alter table public.evaluation_reports enable row level security;
alter table public.activation_invites enable row level security;
alter table public.firebase_id_map enable row level security;
alter table public.activity_events enable row level security;
alter table public.audit_logs enable row level security;

alter table public.legacy_role_map force row level security;
alter table public.legacy_company_status_map force row level security;
alter table public.profiles force row level security;
alter table public.organizations force row level security;
alter table public.memberships force row level security;
alter table public.organization_culture_versions force row level security;
alter table public.dna_catalog_entries force row level security;
alter table public.vacancies force row level security;
alter table public.persons force row level security;
alter table public.applications force row level security;
alter table public.application_status_events force row level security;
alter table public.survey_templates force row level security;
alter table public.survey_versions force row level security;
alter table public.survey_sections force row level security;
alter table public.survey_questions force row level security;
alter table public.survey_options force row level security;
alter table public.public_survey_links force row level security;
alter table public.survey_sessions force row level security;
alter table public.survey_answers force row level security;
alter table public.survey_submission_keys force row level security;
alter table public.culture_perception_results force row level security;
alter table public.affinity_evaluations force row level security;
alter table public.evaluation_reports force row level security;
alter table public.activation_invites force row level security;
alter table public.firebase_id_map force row level security;
alter table public.activity_events force row level security;
alter table public.audit_logs force row level security;

create policy role_map_read on public.legacy_role_map
  for select to authenticated
  using (public.is_superadmin());
create policy company_status_map_read on public.legacy_company_status_map
  for select to authenticated
  using (public.is_superadmin());

create policy profiles_self_or_admin on public.profiles
  for select to authenticated
  using (
    id = public.current_profile_id()
    or public.is_superadmin()
    or exists (
      select 1
      from public.memberships mine
      join public.memberships theirs
        on theirs.organization_id = mine.organization_id
      where mine.profile_id = public.current_profile_id()
        and mine.is_active
        and theirs.profile_id = profiles.id
        and theirs.is_active
    )
  );

create policy organizations_member_read on public.organizations
  for select to authenticated
  using (public.is_org_member(id));

create policy memberships_member_read on public.memberships
  for select to authenticated
  using (public.is_org_member(organization_id));

create policy culture_member_read on public.organization_culture_versions
  for select to authenticated
  using (public.is_org_member(organization_id));

create policy dna_catalog_member_read on public.dna_catalog_entries
  for select to authenticated
  using (organization_id is null or public.is_org_member(organization_id));

create policy vacancies_member_read on public.vacancies
  for select to authenticated
  using (public.is_org_member(organization_id));

create policy persons_via_application on public.persons
  for select to authenticated
  using (
    public.is_superadmin()
    or exists (
      select 1
      from public.applications a
      where a.person_id = persons.id
        and public.is_org_member(a.organization_id)
    )
  );

create policy applications_member_read on public.applications
  for select to authenticated
  using (public.is_org_member(organization_id));

create policy application_events_member_read on public.application_status_events
  for select to authenticated
  using (public.is_org_member(organization_id));

create policy survey_definition_admin_read on public.survey_templates
  for select to authenticated
  using (public.is_superadmin());
create policy survey_versions_admin_read on public.survey_versions
  for select to authenticated
  using (public.is_superadmin());
create policy survey_sections_admin_read on public.survey_sections
  for select to authenticated
  using (public.is_superadmin());
create policy survey_questions_admin_read on public.survey_questions
  for select to authenticated
  using (public.is_superadmin());
create policy survey_options_admin_read on public.survey_options
  for select to authenticated
  using (public.is_superadmin());

create policy public_links_member_read on public.public_survey_links
  for select to authenticated
  using (public.is_org_member(organization_id));

create policy sessions_member_read on public.survey_sessions
  for select to authenticated
  using (public.is_org_member(organization_id));

create policy answers_member_read on public.survey_answers
  for select to authenticated
  using (
    exists (
      select 1
      from public.survey_sessions s
      where s.id = session_id
        and public.is_org_member(s.organization_id)
    )
  );

create policy submission_keys_admin_read on public.survey_submission_keys
  for select to authenticated
  using (public.is_superadmin());

create policy perception_member_read on public.culture_perception_results
  for select to authenticated
  using (public.is_org_member(organization_id));

create policy evaluations_member_read on public.affinity_evaluations
  for select to authenticated
  using (public.is_org_member(organization_id));

create policy reports_member_read on public.evaluation_reports
  for select to authenticated
  using (public.is_org_member(organization_id));

create policy invites_member_read on public.activation_invites
  for select to authenticated
  using (public.is_org_member(organization_id));

create policy firebase_map_admin_read on public.firebase_id_map
  for select to authenticated
  using (public.is_superadmin());

create policy activity_member_read on public.activity_events
  for select to authenticated
  using (
    public.is_superadmin()
    or (organization_id is not null and public.is_org_member(organization_id))
  );

create policy audit_admin_read on public.audit_logs
  for select to authenticated
  using (public.is_superadmin() or public.is_org_member(organization_id));

-- ---------------------------------------------------------------------------
-- Privileges: default grants are revoked. Anon gets RPC execute only.
-- Authenticated gets column-scoped SELECT. Writes stay on the service role.
-- ---------------------------------------------------------------------------

revoke all on all tables in schema public from public, anon, authenticated;
revoke all on all sequences in schema public from public, anon, authenticated;
revoke all on all functions in schema public from public, anon, authenticated;

alter default privileges in schema public revoke all on tables from public, anon, authenticated;
alter default privileges in schema public revoke all on sequences from public, anon, authenticated;
alter default privileges in schema public revoke all on functions from public, anon, authenticated;

grant usage on schema public to anon, authenticated;

grant select on table
  public.legacy_role_map,
  public.legacy_company_status_map,
  public.profiles,
  public.organizations,
  public.memberships,
  public.organization_culture_versions,
  public.dna_catalog_entries,
  public.vacancies,
  public.persons,
  public.applications,
  public.application_status_events,
  public.survey_templates,
  public.survey_versions,
  public.survey_sections,
  public.survey_questions,
  public.survey_options,
  public.survey_sessions,
  public.survey_answers,
  public.culture_perception_results,
  public.affinity_evaluations,
  public.evaluation_reports,
  public.firebase_id_map,
  public.activity_events,
  public.audit_logs
to authenticated;

grant select on public.survey_published_questions to authenticated;
grant select on public.survey_published_options to authenticated;

grant select (
  id,
  organization_id,
  version_id,
  status,
  expires_at,
  max_responses,
  response_count,
  created_by,
  created_at
) on public.public_survey_links to authenticated;

grant select (
  id,
  email,
  organization_id,
  vacancy_id,
  kind,
  role,
  used,
  application_id,
  first_name,
  last_name,
  document_number,
  pin_expires_at,
  token_expires_at,
  expires_at,
  pin_algorithm,
  created_at,
  updated_at
) on public.activation_invites to authenticated;

grant execute on function public.jwt_firebase_uid() to authenticated;
grant execute on function public.current_profile_id() to authenticated;
grant execute on function public.is_superadmin() to authenticated;
grant execute on function public.is_org_member(uuid) to authenticated;

-- ---------------------------------------------------------------------------
-- Public culture survey: token in, questions/answers out. No table grants.
-- ---------------------------------------------------------------------------

create or replace function public.open_culture_survey(p_token text)
returns jsonb
language plpgsql
security definer
set search_path = public, extensions
as $$
declare
  link public.public_survey_links;
  version_row public.survey_versions;
  template_purpose text;
  payload jsonb;
begin
  if p_token is null or length(btrim(p_token)) < 43 then
    raise exception 'invalid_link';
  end if;

  select *
  into link
  from public.public_survey_links
  where token_hash = public.token_hash(p_token)
    and status = 'active'
    and (expires_at is null or expires_at > now())
  limit 1;

  if link.id is null then
    raise exception 'invalid_link';
  end if;

  select *
  into version_row
  from public.survey_versions
  where id = link.version_id;

  select purpose
  into template_purpose
  from public.survey_templates
  where id = version_row.template_id;

  if version_row.status <> 'published' or template_purpose <> 'culture_perception' then
    raise exception 'invalid_public_survey_version';
  end if;

  select jsonb_build_object(
    'sessionPurpose', 'culture_perception',
    'questions', coalesce((
      select jsonb_agg(
        jsonb_build_object(
          'id', q.id,
          'code', q.code,
          'format', q.format,
          'instruction', q.instruction,
          'statementA', q.statement_a,
          'statementB', q.statement_b,
          'required', q.is_required,
          'options', (
            select coalesce(jsonb_agg(
              jsonb_build_object(
                'value', o.value_int,
                'label', o.label
              ) order by o.sort_order
            ), '[]'::jsonb)
            from public.survey_options o
            where o.question_id = q.id
          )
        ) order by s.sort_order, q.sort_order
      )
      from public.survey_sections s
      join public.survey_questions q on q.section_id = s.id
      where s.version_id = link.version_id
        and q.is_active
    ), '[]'::jsonb)
  )
  into payload;

  return payload;
end;
$$;

create or replace function public.submit_culture_survey(
  p_token text,
  p_answers jsonb,
  p_locale text default 'es',
  p_idempotency_key text default null
)
returns jsonb
language plpgsql
security definer
set search_path = public, extensions
as $$
declare
  link public.public_survey_links;
  version_row public.survey_versions;
  template_purpose text;
  culture_id uuid;
  session_id uuid;
  item jsonb;
  question public.survey_questions;
  option_label text;
  idempotency_hash text;
  existing uuid;
begin
  if p_token is null or length(btrim(p_token)) < 43 then
    raise exception 'invalid_link';
  end if;
  if jsonb_typeof(p_answers) <> 'array' or jsonb_array_length(p_answers) = 0 then
    raise exception 'invalid_answers';
  end if;
  if (
    select count(*)
    from jsonb_array_elements(p_answers)
  ) <> (
    select count(distinct value ->> 'questionId')
    from jsonb_array_elements(p_answers)
  ) then
    raise exception 'duplicate_answers';
  end if;

  select *
  into link
  from public.public_survey_links
  where token_hash = public.token_hash(p_token)
    and status = 'active'
    and (expires_at is null or expires_at > now())
  for update;

  if link.id is null then
    raise exception 'invalid_link';
  end if;

  if p_idempotency_key is not null and btrim(p_idempotency_key) <> '' then
    if length(btrim(p_idempotency_key)) < 16 then
      raise exception 'invalid_idempotency_key';
    end if;
    idempotency_hash := public.token_hash(link.id::text || ':' || btrim(p_idempotency_key));
    select k.session_id
    into existing
    from public.survey_submission_keys k
    where k.public_link_id = link.id
      and k.key_hash = idempotency_hash;
    if existing is not null then
      return jsonb_build_object('status', 'accepted', 'submissionId', existing);
    end if;
  end if;

  select *
  into version_row
  from public.survey_versions
  where id = link.version_id;

  select purpose
  into template_purpose
  from public.survey_templates
  where id = version_row.template_id;

  if version_row.status <> 'published' or template_purpose <> 'culture_perception' then
    raise exception 'invalid_public_survey_version';
  end if;

  select v.id
  into culture_id
  from public.organization_culture_versions v
  where v.organization_id = link.organization_id
    and v.is_current
  limit 1;

  if culture_id is null then
    raise exception 'missing_current_culture';
  end if;

  if exists (
    select 1
    from public.survey_questions q
    join public.survey_sections s on s.id = q.section_id
    where s.version_id = link.version_id
      and q.is_active
      and q.is_required
      and not exists (
        select 1
        from jsonb_array_elements(p_answers) answers
        where (answers.value ->> 'questionId') ~* '^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$'
          and (answers.value ->> 'questionId')::uuid = q.id
      )
  ) then
    raise exception 'missing_required_answers';
  end if;

  if link.response_count >= link.max_responses then
    raise exception 'link_exhausted';
  end if;

  insert into public.survey_sessions (
    version_id,
    purpose,
    organization_id,
    public_link_id,
    locale,
    status,
    completed_at
  ) values (
    link.version_id,
    'culture_perception',
    link.organization_id,
    link.id,
    coalesce(nullif(btrim(p_locale), ''), 'es'),
    'completed',
    now()
  )
  returning id into session_id;

  for item in select value from jsonb_array_elements(p_answers)
  loop
    if (item ->> 'questionId') is null
      or (item ->> 'questionId') !~* '^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$' then
      raise exception 'invalid_question';
    end if;

    select q.*
    into question
    from public.survey_questions q
    join public.survey_sections s on s.id = q.section_id
    where q.id = (item ->> 'questionId')::uuid
      and s.version_id = link.version_id
      and q.is_active;

    if question.id is null then
      raise exception 'invalid_question';
    end if;

    option_label := null;
    if exists (
      select 1 from public.survey_options o where o.question_id = question.id
    ) then
      select o.label
      into option_label
      from public.survey_options o
      where o.question_id = question.id
        and o.value_int = nullif(item ->> 'valueInt', '')::integer;
      if option_label is null then
        raise exception 'invalid_option';
      end if;
    elsif question.format <> 'text' then
      if nullif(item ->> 'valueInt', '') is null then
        raise exception 'invalid_option';
      end if;
    elsif nullif(item ->> 'valueText', '') is null then
      raise exception 'invalid_answers';
    end if;

    insert into public.survey_answers (
      session_id,
      question_id,
      value_int,
      value_text,
      question_code,
      format,
      statement_a,
      statement_b,
      option_label
    ) values (
      session_id,
      question.id,
      nullif(item ->> 'valueInt', '')::integer,
      nullif(item ->> 'valueText', ''),
      question.code,
      question.format,
      question.statement_a,
      question.statement_b,
      option_label
    );
  end loop;

  insert into public.culture_perception_results (
    session_id,
    organization_id,
    culture_version_id
  ) values (
    session_id,
    link.organization_id,
    culture_id
  );

  update public.public_survey_links
  set response_count = response_count + 1
  where id = link.id;

  if idempotency_hash is not null then
    insert into public.survey_submission_keys (
      public_link_id, key_hash, session_id
    ) values (
      link.id, idempotency_hash, session_id
    );
  end if;

  return jsonb_build_object('status', 'accepted', 'submissionId', session_id);
end;
$$;

create or replace function public.create_public_survey_link(
  p_organization_id uuid,
  p_version_id uuid,
  p_max_responses integer default 1000,
  p_expires_at timestamptz default null
)
returns jsonb
language plpgsql
security definer
set search_path = public, extensions
as $$
declare
  token text;
  link_id uuid;
begin
  if p_max_responses is null or p_max_responses < 1 or p_max_responses > 10000 then
    raise exception 'invalid_max_responses';
  end if;

  token := public.generate_survey_token();
  if length(token) < 43 then
    raise exception 'token_entropy';
  end if;

  insert into public.public_survey_links (
    organization_id,
    version_id,
    token_hash,
    max_responses,
    expires_at
  ) values (
    p_organization_id,
    p_version_id,
    public.token_hash(token),
    p_max_responses,
    p_expires_at
  )
  returning id into link_id;

  return jsonb_build_object('id', link_id, 'token', token);
end;
$$;

create or replace function public.publish_survey_version(p_version_id uuid)
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  update public.survey_versions
  set status = 'published',
      published_at = coalesce(published_at, now())
  where id = p_version_id
    and status = 'draft';

  if not found then
    raise exception 'version_not_draft';
  end if;
end;
$$;

grant execute on function public.open_culture_survey(text) to anon, authenticated;
grant execute on function public.submit_culture_survey(text, jsonb, text, text) to anon, authenticated;
grant execute on function public.token_hash(text) to anon, authenticated;
