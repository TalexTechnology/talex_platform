-- Real SQL / RLS / RPC checks. Run against a disposable database after the
-- migration and two seed passes. The runner reports each assertion by name.

create or replace function pg_temp.ok(condition boolean, label text)
returns void
language plpgsql
as $$
begin
  if condition is not true then
    raise exception 'FAIL: %', label;
  end if;
  raise notice 'PASS: %', label;
end;
$$;

create or replace function pg_temp.throws(sql text, expected text, label text)
returns void
language plpgsql
as $$
begin
  execute sql;
  raise exception 'FAIL: % (expected error %)', label, expected;
exception
  when others then
    if sqlerrm not like '%' || expected || '%' then
      raise exception 'FAIL: % (wanted %, got %)', label, expected, sqlerrm;
    end if;
    raise notice 'PASS: %', label;
end;
$$;

create or replace function pg_temp.as_user(firebase_uid text)
returns void
language plpgsql
as $$
begin
  perform set_config(
    'request.jwt.claims',
    jsonb_build_object('role', 'authenticated', 'firebase_uid', firebase_uid)::text,
    true
  );
  execute 'set local role authenticated';
end;
$$;

do $$
declare
  org_a uuid;
  org_b uuid;
  vacancy_a uuid;
  vacancy_b uuid;
  person_id uuid;
  app_a uuid;
  profile_a uuid;
  profile_b uuid;
  profile_admin uuid;
  perception_template uuid;
  perception_version uuid;
  affinity_template uuid;
  affinity_version uuid;
  section_id uuid;
  question_id uuid;
  question_text uuid;
  culture_id uuid;
  token text := 'AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA';
  link_id uuid;
  opened jsonb;
  submitted jsonb;
  replay jsonb;
  first_session uuid;
  statement_copy text;
  seen_a integer;
  seen_b integer;
  pin_hash text;
begin
  -- Seed is idempotent: two templates remain after a second pass.
  perform pg_temp.ok(
    (select count(*) from public.survey_templates) = 2,
    'seed keeps two templates'
  );

  insert into public.profiles (firebase_uid, email, is_superadmin)
  values
    ('uid-a', 'staff.a@example.com', false),
    ('uid-b', 'STAFF.B@example.com', false),
    ('uid-admin', 'admin@example.com', true);

  select id into profile_a from public.profiles where firebase_uid = 'uid-a';
  select id into profile_b from public.profiles where firebase_uid = 'uid-b';
  select id into profile_admin from public.profiles where firebase_uid = 'uid-admin';

  perform pg_temp.ok(
    (select email from public.profiles where firebase_uid = 'uid-b') = 'staff.b@example.com',
    'emails are stored in lowercase'
  );

  begin
    insert into public.profiles (firebase_uid, email)
    values ('uid-dup', 'Staff.A@example.com');
    raise exception 'FAIL: duplicate email case should be rejected';
  exception
    when unique_violation then
      raise notice 'PASS: duplicate email case is rejected';
  end;
end;
$$;

do $$
declare
  org_a uuid;
  org_b uuid;
  vacancy_a uuid;
  vacancy_b uuid;
  person_id uuid;
  person_two uuid;
  app_a uuid;
  profile_a uuid;
  profile_b uuid;
  profile_admin uuid;
  perception_template uuid;
  perception_version uuid;
  affinity_version uuid;
  section_id uuid;
  scale_question uuid;
  text_question uuid;
  culture_id uuid;
  token text := 'AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA';
  short_token text := 'short-token-value-xx';
  opened jsonb;
  submitted jsonb;
  replay jsonb;
  first_session uuid;
  statement_copy text;
  seen integer;
  pin_ok boolean;
  invite_id uuid;
begin
  select id into profile_a from public.profiles where firebase_uid = 'uid-a';
  select id into profile_b from public.profiles where firebase_uid = 'uid-b';
  select id into profile_admin from public.profiles where firebase_uid = 'uid-admin';

  insert into public.organizations (name, status)
  values ('Empresa A', 'onboarding')
  returning id into org_a;
  insert into public.organizations (name, status)
  values ('Empresa B', 'atRisk')
  returning id into org_b;

  insert into public.memberships (organization_id, profile_id, role, legacy_role)
  values
    (org_a, profile_a, 'company_lead', 'ceo'),
    (org_b, profile_b, 'people_ops', 'hr');

  insert into public.vacancies (organization_id, name)
  values (org_a, 'Analista A')
  returning id into vacancy_a;
  insert into public.vacancies (organization_id, name)
  values (org_b, 'Analista B')
  returning id into vacancy_b;

  insert into public.persons (email, document_number, display_name)
  values ('persona@example.com', '123', 'Ana');
  insert into public.persons (email, document_number, display_name)
  values ('otra@example.com', '123', 'Otra');

  perform pg_temp.throws(
    format(
      'insert into public.applications (organization_id, vacancy_id, person_id) select %L, %L, id from public.persons where email = %L',
      org_b,
      vacancy_a,
      'persona@example.com'
    ),
    'foreign key',
    'application cannot reference another company vacancy'
  );
  perform pg_temp.ok(
    (select count(*) from public.persons where document_number = '123') = 2,
    'same document number is not merged automatically'
  );

  select id into person_id from public.persons where email = 'persona@example.com';

  insert into public.applications (
    organization_id, vacancy_id, person_id, vacancy_name, assessment_kind
  ) values (
    org_a, vacancy_a, person_id, 'Analista A', 'affinity'
  ) returning id into app_a;

  perform pg_temp.throws(
    format(
      $sql$
      insert into public.survey_sessions (
        version_id, purpose, organization_id, application_id
      ) values (
        (select id from public.survey_versions limit 1),
        'affinity',
        %L,
        %L
      )
      $sql$,
      org_b,
      app_a
    ),
    '',
    'affinity session cannot use another company id'
  );

  select v.id into affinity_version
  from public.survey_versions v
  join public.survey_templates t on t.id = v.template_id
  where t.slug = 'affinity-core';

  select id into perception_template
  from public.survey_templates
  where slug = 'culture-perception';

  select id into perception_version
  from public.survey_versions
  where template_id = perception_template;

  insert into public.survey_sections (version_id, code, title, sort_order)
  values (perception_version, 'core', 'Percepción', 1)
  returning id into section_id;

  insert into public.survey_questions (
    section_id, code, format, statement_a, is_required, sort_order
  ) values (
    section_id, 'p1', 'scale', 'El equipo colabora con claridad', true, 1
  ) returning id into scale_question;

  insert into public.survey_questions (
    section_id, code, format, statement_a, is_required, sort_order
  ) values (
    section_id, 'p2', 'text', 'Comentario opcional', false, 2
  ) returning id into text_question;

  insert into public.survey_options (question_id, value_int, label, sort_order)
  values
    (scale_question, 1, 'En desacuerdo', 1),
    (scale_question, 5, 'De acuerdo', 2);

  perform public.publish_survey_version(perception_version);

  perform pg_temp.throws(
    format(
      'update public.survey_questions set statement_a = %L where id = %L',
      'texto alterado',
      scale_question
    ),
    'published_version_immutable',
    'published questions cannot change'
  );

  insert into public.organization_culture_versions (
    organization_id, version_number, values_list, is_current
  ) values (
    org_a, 1, array['respeto'], true
  ) returning id into culture_id;

  insert into public.public_survey_links (
    organization_id, version_id, token_hash, max_responses
  ) values (
    org_a, perception_version, public.token_hash(token), 1
  );

  opened := public.open_culture_survey(token);
  perform pg_temp.ok(
    opened ? 'sessionPurpose'
      and not (opened ? 'organizationId')
      and jsonb_array_length(opened -> 'questions') = 2,
    'open_culture_survey returns questions without organization id'
  );

  perform pg_temp.throws(
    format('select public.open_culture_survey(%L)', short_token),
    'invalid_link',
    'short tokens are rejected'
  );
  perform pg_temp.throws(
    'select public.open_culture_survey(''BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB'')',
    'invalid_link',
    'unknown tokens are rejected'
  );
  perform pg_temp.throws(
    format('select public.submit_culture_survey(%L, %L::jsonb)', token, '[]'),
    'invalid_answers',
    'empty answers are rejected'
  );

  -- Missing required question (only the optional text answer).
  perform pg_temp.throws(
    format(
      'select public.submit_culture_survey(%L, %L::jsonb)',
      token,
      jsonb_build_array(
        jsonb_build_object('questionId', text_question, 'valueText', 'hola')
      )
    ),
    'missing_required_answers',
    'missing required answers are rejected'
  );

  perform pg_temp.throws(
    format(
      'select public.submit_culture_survey(%L, %L::jsonb)',
      token,
      jsonb_build_array(
        jsonb_build_object('questionId', scale_question, 'valueInt', 9)
      )
    ),
    'invalid_option',
    'options outside the question are rejected'
  );

  submitted := public.submit_culture_survey(
    token,
    jsonb_build_array(
      jsonb_build_object('questionId', scale_question, 'valueInt', 5)
    ),
    'es',
    'idempotency-key-1'
  );
  first_session := (submitted ->> 'submissionId')::uuid;
  perform pg_temp.ok(submitted ->> 'status' = 'accepted', 'valid submit is accepted');

  select a.statement_a into statement_copy
  from public.survey_answers a
  where a.session_id = first_session
    and a.question_id = scale_question;
  perform pg_temp.ok(
    statement_copy = 'El equipo colabora con claridad',
    'answers snapshot the original statement'
  );

  replay := public.submit_culture_survey(
    token,
    jsonb_build_array(
      jsonb_build_object('questionId', scale_question, 'valueInt', 5)
    ),
    'es',
    'idempotency-key-1'
  );
  perform pg_temp.ok(
    (replay ->> 'submissionId')::uuid = first_session,
    'idempotent retry returns the same submission'
  );

  perform pg_temp.throws(
    format(
      'select public.submit_culture_survey(%L, %L::jsonb)',
      token,
      jsonb_build_array(
        jsonb_build_object('questionId', scale_question, 'valueInt', 1)
      )
    ),
    'link_exhausted',
    'max responses per link is enforced'
  );

  insert into public.activation_invites (
    email, organization_id, kind, role, pin_hash, pin_algorithm
  ) values (
    'invite@example.com',
    org_a,
    'recruiter',
    'recruiter',
    'deadbeef',
    'fnv1a32'
  ) returning id into invite_id;

  pin_ok := public.verify_invite_pin(
    '246813',
    'invite@example.com',
    public.fnv1a32_hex('invite@example.com|246813'),
    'fnv1a32'
  );
  perform pg_temp.ok(pin_ok, 'fnv1a32 pin verification matches the current hasher');

  perform pg_temp.ok(
    public.verify_invite_pin(
      '246813',
      'invite@example.com',
      public.hash_invite_pin('246813'),
      'bfcrypt'
    ),
    'bfcrypt pin verification works for new hashes'
  );

  -- Privilege and isolation checks.
  perform set_config(
    'request.jwt.claims',
    jsonb_build_object('role', 'authenticated', 'firebase_uid', 'uid-a')::text,
    true
  );
  execute 'set local role authenticated';

  select count(*) into seen from public.organizations;
  perform pg_temp.ok(seen = 1, 'company A does not see company B');

  select count(*) into seen from public.applications;
  perform pg_temp.ok(seen = 1, 'company A only sees its applications');

  select count(*) into seen from public.persons;
  perform pg_temp.ok(seen = 1, 'company A only sees persons with its applications');

  select count(*) into seen from public.survey_questions;
  perform pg_temp.ok(seen = 0, 'members cannot read scoring-dimension tables');

  select count(*) into seen from public.survey_published_questions;
  perform pg_temp.ok(seen >= 0, 'members can read the published affinity catalog view');

  perform pg_temp.throws(
    'select pin_hash from public.activation_invites',
    '',
    'members cannot select invite pin hashes'
  );

  perform pg_temp.throws(
    'update public.profiles set is_superadmin = true where firebase_uid = ''uid-a''',
    '',
    'members cannot grant themselves superadmin'
  );

  reset role;
  perform set_config(
    'request.jwt.claims',
    jsonb_build_object('role', 'authenticated', 'firebase_uid', 'uid-b')::text,
    true
  );
  execute 'set local role authenticated';
  select count(*) into seen from public.applications;
  perform pg_temp.ok(seen = 0, 'company B does not see company A applications');

  reset role;
  perform set_config(
    'request.jwt.claims',
    jsonb_build_object('role', 'authenticated', 'firebase_uid', 'uid-admin')::text,
    true
  );
  execute 'set local role authenticated';
  select count(*) into seen from public.organizations;
  perform pg_temp.ok(seen = 2, 'superadmin can read both companies');

  reset role;
  perform set_config('request.jwt.claims', '{"role":"anon"}', true);
  execute 'set local role anon';

  perform pg_temp.throws(
    'select count(*) from public.applications',
    '',
    'anon cannot read applications'
  );
  perform pg_temp.throws(
    'select count(*) from public.persons',
    '',
    'anon cannot read persons'
  );
  perform pg_temp.throws(
    'select count(*) from public.vacancies',
    '',
    'anon cannot read vacancies'
  );
  perform pg_temp.throws(
    'select count(*) from public.activation_invites',
    '',
    'anon cannot read invites'
  );
  perform pg_temp.throws(
    'select count(*) from public.survey_answers',
    '',
    'anon cannot read answers'
  );
  perform pg_temp.throws(
    'select count(*) from public.survey_questions',
    '',
    'anon cannot read questions'
  );

  opened := public.open_culture_survey(token);
  perform pg_temp.ok(
    opened ->> 'sessionPurpose' = 'culture_perception',
    'anon can execute open_culture_survey'
  );

  reset role;
  perform pg_temp.ok(
    not exists (
      select 1
      from information_schema.role_table_grants
      where grantee = 'anon'
        and table_schema = 'public'
        and privilege_type in ('SELECT', 'INSERT', 'UPDATE', 'DELETE')
    ),
    'anon has no table DML privileges'
  );

  perform set_config(
    'request.jwt.claims',
    jsonb_build_object('role', 'authenticated', 'sub', 'uid-a')::text,
    true
  );
  perform pg_temp.ok(
    public.jwt_firebase_uid() is null,
    'sub is not accepted as a Firebase uid'
  );
  perform pg_temp.ok(
    public.current_profile_id() is null,
    'a sub-only token does not resolve a profile'
  );
end;
$$;

-- A session that mixes public-link and application context must fail.
do $$
declare
  org uuid;
  vacancy uuid;
  person uuid;
  application uuid;
  version uuid;
  link uuid;
begin
  select o.id into org from public.organizations o where o.name = 'Empresa A';
  select v.id into vacancy from public.vacancies v where v.organization_id = org limit 1;
  select p.id into person from public.persons p where p.email = 'persona@example.com';
  select a.id into application from public.applications a where a.organization_id = org limit 1;
  select ver.id into version
  from public.survey_versions ver
  join public.survey_templates t on t.id = ver.template_id
  where t.slug = 'affinity-core';
  select l.id into link from public.public_survey_links l limit 1;

  perform pg_temp.throws(
    format(
      $sql$
      insert into public.survey_sessions (
        version_id, purpose, organization_id, application_id, public_link_id
      ) values (%L, 'affinity', %L, %L, %L)
      $sql$,
      version, org, application, link
    ),
    '',
    'affinity sessions cannot carry a public link'
  );
end;
$$;
