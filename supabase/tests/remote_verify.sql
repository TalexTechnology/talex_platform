-- Production verification. Uses disposable rows tagged tmp-remote-verify
-- and deletes them at the end. Does not publish the official culture template.

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
    if expected <> '' and sqlerrm not like '%' || expected || '%' then
      raise exception 'FAIL: % (wanted %, got %)', label, expected, sqlerrm;
    end if;
    raise notice 'PASS: %', label;
end;
$$;

do $$
declare
  org_a uuid;
  org_b uuid;
  vacancy_a uuid;
  person_id uuid;
  app_a uuid;
  profile_a uuid;
  profile_b uuid;
  profile_admin uuid;
  tmp_template uuid;
  tmp_version uuid;
  section_id uuid;
  scale_question uuid;
  token text := 'AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA';
  opened jsonb;
  submitted jsonb;
  replay jsonb;
  first_session uuid;
  seen integer;
begin
  perform pg_temp.ok(
    (select count(*) from public.survey_templates) = 2,
    'seed keeps two official templates'
  );
  perform pg_temp.ok(
    (
      select v.status
      from public.survey_versions v
      join public.survey_templates t on t.id = v.template_id
      where t.slug = 'culture-perception'
    ) = 'draft',
    'official culture perception stays draft'
  );

  insert into public.profiles (firebase_uid, email, is_superadmin)
  values
    ('tmp-uid-a', 'tmp.a@example.com', false),
    ('tmp-uid-b', 'TMP.B@example.com', false),
    ('tmp-uid-admin', 'tmp.admin@example.com', true);

  perform pg_temp.ok(
    (select email from public.profiles where firebase_uid = 'tmp-uid-b') = 'tmp.b@example.com',
    'emails are stored in lowercase'
  );

  begin
    insert into public.profiles (firebase_uid, email)
    values ('tmp-uid-dup', 'Tmp.A@example.com');
    raise exception 'FAIL: duplicate email case should be rejected';
  exception
    when unique_violation then
      raise notice 'PASS: duplicate email case is rejected';
  end;

  select id into profile_a from public.profiles where firebase_uid = 'tmp-uid-a';
  select id into profile_b from public.profiles where firebase_uid = 'tmp-uid-b';
  select id into profile_admin from public.profiles where firebase_uid = 'tmp-uid-admin';

  insert into public.organizations (name, status)
  values ('tmp-remote-verify A', 'onboarding')
  returning id into org_a;
  insert into public.organizations (name, status)
  values ('tmp-remote-verify B', 'atRisk')
  returning id into org_b;

  insert into public.memberships (organization_id, profile_id, role, legacy_role)
  values
    (org_a, profile_a, 'company_lead', 'ceo'),
    (org_b, profile_b, 'people_ops', 'hr');

  insert into public.vacancies (organization_id, name)
  values (org_a, 'tmp-vacancy')
  returning id into vacancy_a;

  insert into public.persons (email, document_number)
  values ('tmp.persona@example.com', 'tmp-123')
  returning id into person_id;
  insert into public.persons (email, document_number)
  values ('tmp.otra@example.com', 'tmp-123');

  perform pg_temp.throws(
    format(
      'insert into public.applications (organization_id, vacancy_id, person_id) select %L, %L, id from public.persons where email = %L',
      org_b,
      vacancy_a,
      'tmp.persona@example.com'
    ),
    'foreign key',
    'application cannot reference another company vacancy'
  );

  insert into public.applications (
    organization_id, vacancy_id, person_id, vacancy_name, assessment_kind
  ) values (
    org_a, vacancy_a, person_id, 'tmp-vacancy', 'affinity'
  ) returning id into app_a;

  insert into public.survey_templates (slug, purpose, title)
  values ('tmp-remote-verify', 'culture_perception', 'tmp')
  returning id into tmp_template;
  insert into public.survey_versions (template_id, version_number, status)
  values (tmp_template, 1, 'draft')
  returning id into tmp_version;
  insert into public.survey_sections (version_id, code, title)
  values (tmp_version, 'core', 'tmp')
  returning id into section_id;
  insert into public.survey_questions (section_id, code, format, statement_a)
  values (section_id, 'p1', 'scale', 'tmp statement')
  returning id into scale_question;
  insert into public.survey_options (question_id, value_int, label)
  values (scale_question, 5, 'ok');
  perform public.publish_survey_version(tmp_version);

  insert into public.organization_culture_versions (
    organization_id, version_number, values_list, is_current
  ) values (org_a, 1, array['tmp'], true);

  insert into public.public_survey_links (
    organization_id, version_id, token_hash, max_responses
  ) values (org_a, tmp_version, public.token_hash(token), 1);

  perform pg_temp.throws(
    'select public.open_culture_survey(''short-token-value-xx'')',
    'invalid_link',
    'short tokens are rejected'
  );

  opened := public.open_culture_survey(token);
  perform pg_temp.ok(
    opened ->> 'sessionPurpose' = 'culture_perception'
      and not (opened ? 'organizationId'),
    'open_culture_survey hides organization id'
  );

  submitted := public.submit_culture_survey(
    token,
    jsonb_build_array(jsonb_build_object('questionId', scale_question, 'valueInt', 5)),
    'es',
    'tmp-idempotency-key'
  );
  first_session := (submitted ->> 'submissionId')::uuid;
  replay := public.submit_culture_survey(
    token,
    jsonb_build_array(jsonb_build_object('questionId', scale_question, 'valueInt', 5)),
    'es',
    'tmp-idempotency-key'
  );
  perform pg_temp.ok(
    (replay ->> 'submissionId')::uuid = first_session,
    'idempotent retry returns the same submission'
  );

  perform set_config(
    'request.jwt.claims',
    jsonb_build_object('role', 'authenticated', 'firebase_uid', 'tmp-uid-a')::text,
    true
  );
  execute 'set local role authenticated';
  select count(*) into seen from public.organizations;
  perform pg_temp.ok(seen = 1, 'company A does not see company B');
  reset role;

  perform set_config(
    'request.jwt.claims',
    jsonb_build_object('role', 'authenticated', 'sub', 'tmp-uid-a')::text,
    true
  );
  perform pg_temp.ok(public.jwt_firebase_uid() is null, 'sub is not accepted as a Firebase uid');

  perform set_config('request.jwt.claims', '{"role":"anon"}', true);
  execute 'set local role anon';
  perform pg_temp.throws('select count(*) from public.applications', '', 'anon cannot read applications');
  reset role;
end;
$$;

-- Remove disposable rows without leaving invented product questions.
set session_replication_role = replica;
delete from public.survey_submission_keys
where public_link_id in (
  select id from public.public_survey_links
  where organization_id in (select id from public.organizations where name like 'tmp-remote-verify%')
);
delete from public.survey_answers
where session_id in (
  select id from public.survey_sessions
  where organization_id in (select id from public.organizations where name like 'tmp-remote-verify%')
);
delete from public.culture_perception_results
where organization_id in (select id from public.organizations where name like 'tmp-remote-verify%');
delete from public.survey_sessions
where organization_id in (select id from public.organizations where name like 'tmp-remote-verify%');
delete from public.public_survey_links
where organization_id in (select id from public.organizations where name like 'tmp-remote-verify%');
delete from public.survey_options
where question_id in (
  select q.id
  from public.survey_questions q
  join public.survey_sections s on s.id = q.section_id
  join public.survey_versions v on v.id = s.version_id
  join public.survey_templates t on t.id = v.template_id
  where t.slug = 'tmp-remote-verify'
);
delete from public.survey_questions
where section_id in (
  select s.id
  from public.survey_sections s
  join public.survey_versions v on v.id = s.version_id
  join public.survey_templates t on t.id = v.template_id
  where t.slug = 'tmp-remote-verify'
);
delete from public.survey_sections
where version_id in (
  select v.id
  from public.survey_versions v
  join public.survey_templates t on t.id = v.template_id
  where t.slug = 'tmp-remote-verify'
);
delete from public.survey_versions
where template_id in (select id from public.survey_templates where slug = 'tmp-remote-verify');
delete from public.survey_templates where slug = 'tmp-remote-verify';
delete from public.activation_invites
where organization_id in (select id from public.organizations where name like 'tmp-remote-verify%');
delete from public.application_status_events
where organization_id in (select id from public.organizations where name like 'tmp-remote-verify%');
delete from public.applications
where organization_id in (select id from public.organizations where name like 'tmp-remote-verify%');
delete from public.vacancies
where organization_id in (select id from public.organizations where name like 'tmp-remote-verify%');
delete from public.organization_culture_versions
where organization_id in (select id from public.organizations where name like 'tmp-remote-verify%');
delete from public.memberships
where organization_id in (select id from public.organizations where name like 'tmp-remote-verify%');
delete from public.organizations where name like 'tmp-remote-verify%';
delete from public.persons where email like 'tmp.%';
delete from public.profiles where firebase_uid like 'tmp-%';
set session_replication_role = origin;

select
  (select count(*) from public.survey_templates) as templates,
  (select count(*) from public.organizations) as organizations,
  (select count(*) from public.profiles) as profiles;
