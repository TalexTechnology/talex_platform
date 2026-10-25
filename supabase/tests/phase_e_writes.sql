-- Write RLS and session RPCs. Runs after phase_a_security.sql on the same DB.

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
  vacancy_a uuid;
  session_payload jsonb;
  provisioned jsonb;
  respondent jsonb;
  pin_value text := '246813';
  token_value text := 'respondent-token-phase-e-0000000000001';
  seen integer;
begin
  select id into org_a from public.organizations where name = 'Empresa A';
  select id into vacancy_a from public.vacancies where organization_id = org_a limit 1;

  perform pg_temp.as_user('uid-a');
  session_payload := public.current_session_profile();
  perform pg_temp.ok(
    session_payload ->> 'role' in ('ceo', 'company_lead'),
    'staff session exposes membership role'
  );
  perform pg_temp.ok(
    session_payload ->> 'organizationUuid' = org_a::text,
    'staff session resolves organization'
  );

  perform public.save_organization_profile(
    org_a::text,
    'Empresa A',
    null, null, null, null, null, null, null, null, null,
    array['Respeto'],
    array['Colaborativa'],
    array['Iniciativa'],
    'Claridad'
  );
  perform pg_temp.ok(
    exists (
      select 1
      from public.organization_culture_versions
      where organization_id = org_a
        and is_current
        and 'Respeto' = any (values_list)
    ),
    'staff can publish a new culture version'
  );

  reset role;
  perform pg_temp.as_user('uid-b');
  begin
    perform public.save_organization_profile(
      org_a::text,
      'Hack',
      null, null, null, null, null, null, null, null, null,
      '{}', '{}', '{}', null
    );
    raise exception 'FAIL: company B cannot write company A';
  exception
    when others then
      if sqlerrm like '%permission_denied%' then
        raise notice 'PASS: company B cannot write company A';
      else
        raise;
      end if;
  end;

  reset role;
  perform pg_temp.as_user('uid-admin');
  provisioned := public.provision_organization(
    'Empresa Nueva',
    'nuevo.admin@example.com',
    'Nueva',
    'Admin',
    pin_value,
    null, null, null, null, null, null, null, null, null,
    array['Confianza'],
    array['Ágil'],
    array['Ownership'],
    null
  );
  perform pg_temp.ok(provisioned ? 'organizationId', 'superadmin can provision a company');
  perform pg_temp.ok(provisioned ->> 'pin' = pin_value, 'provision returns the invite pin');

  reset role;
  insert into public.profiles (firebase_uid, email, display_name)
  values ('uid-new-admin', 'nuevo.admin@example.com', 'Nueva Admin')
  on conflict (email) do update set firebase_uid = excluded.firebase_uid;

  reset role;
  perform pg_temp.as_user('uid-new-admin');
  perform public.activate_invite_pin(pin_value);
  perform pg_temp.ok(
    exists (
      select 1
      from public.memberships m
      join public.profiles p on p.id = m.profile_id
      where p.firebase_uid = 'uid-new-admin'
        and m.is_active
    ),
    'pin activation creates a membership'
  );

  reset role;
  insert into public.survey_sections (version_id, code, title, sort_order)
  select v.id, 'values-e', 'Valores E', 1
  from public.survey_versions v
  join public.survey_templates t on t.id = v.template_id
  where t.slug = 'affinity-core'
    and v.status = 'published'
  on conflict (version_id, code) do nothing;

  insert into public.survey_questions (
    section_id, code, format, statement_a, statement_b, sort_order
  )
  select s.id, 'V01', 'pair', 'Frase A', 'Frase B', 1
  from public.survey_sections s
  where s.code = 'values-e'
  on conflict (section_id, code) do nothing;

  perform pg_temp.as_user('uid-a');
  respondent := public.create_respondent_application(
    org_a::text,
    vacancy_a::text,
    'candidato.e@example.com',
    '900',
    'Candidato E',
    token_value
  );
  perform pg_temp.ok(respondent ? 'token', 'staff can create a respondent invite');

  reset role;
  insert into public.profiles (firebase_uid, email, display_name)
  values ('uid-respondent-e', 'candidato.e@example.com', 'Candidato E')
  on conflict (email) do update set firebase_uid = excluded.firebase_uid;

  reset role;
  perform set_config('request.jwt.claims', '{"role":"service_role"}', true);
  perform public.link_respondent_profile(
    'uid-respondent-e',
    public.token_hash(token_value)
  );

  reset role;
  perform pg_temp.as_user('uid-respondent-e');
  session_payload := public.current_session_profile();
  perform pg_temp.ok(
    session_payload ->> 'role' = 'respondent',
    'respondent session role is respondent'
  );
  perform public.save_affinity_answer(session_payload ->> 'applicationId', 'V01', 5);
  perform public.complete_affinity_evaluation(
    session_payload ->> 'applicationId',
    'high',
    '{"capabilities": 4}'::jsonb
  );
  select count(*) into seen
  from public.applications a
  join public.persons pe on pe.id = a.person_id
  where pe.email = 'candidato.e@example.com'
    and a.evaluation_completed;
  perform pg_temp.ok(seen = 1, 'respondent can complete their own evaluation');

  reset role;
  perform pg_temp.as_user('uid-b');
  select count(*) into seen
  from public.applications a
  join public.persons pe on pe.id = a.person_id
  where pe.email = 'candidato.e@example.com';
  perform pg_temp.ok(seen = 0, 'other company still cannot see the new respondent');

  reset role;
  perform set_config(
    'request.jwt.claims',
    jsonb_build_object('role', 'authenticated', 'sub', 'uid-a')::text,
    true
  );
  perform pg_temp.ok(
    public.current_session_profile() is null,
    'sub-only token still cannot open a session'
  );
end;
$$;
