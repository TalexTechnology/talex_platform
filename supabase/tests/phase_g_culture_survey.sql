-- Company culture is built from every completed values/culture survey.

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
  opened jsonb;
  first jsonb;
  second jsonb;
  culture jsonb;
  answers jsonb;
begin
  reset role;
  perform set_config('request.jwt.claims', '', true);

  select id into org_a from public.organizations where name = 'Empresa A';

  reset role;
  perform pg_temp.as_user('uid-admin');
  perform public.upsert_survey_question(
    'culture-perception',
    jsonb_build_object(
      'code', 'VAL01',
      'section', 'cultura',
      'format', 'scale',
      'dimensionA', 'Respeto',
      'statementA', 'Se trata a las personas con respeto',
      'options', jsonb_build_array('1', '2', '3', '4', '5'),
      'order', 1
    )
  );
  perform public.upsert_survey_question(
    'culture-perception',
    jsonb_build_object(
      'code', 'LID01',
      'section', 'liderazgo',
      'format', 'scale',
      'dimensionA', 'Claridad',
      'statementA', 'Las decisiones se explican con claridad',
      'options', jsonb_build_array('1', '2', '3', '4', '5'),
      'order', 2
    )
  );

  perform pg_temp.ok(
    exists (
      select 1
      from public.survey_versions v
      join public.survey_templates t on t.id = v.template_id
      where t.slug = 'culture-perception'
        and v.status = 'published'
    ),
    'uploading culture questions publishes the survey'
  );

  reset role;
  perform pg_temp.as_user('uid-a');
  opened := public.open_company_culture_survey(org_a::text);
  perform pg_temp.ok(
    jsonb_array_length(opened -> 'questions') >= 2,
    'company staff can open the values/culture survey'
  );
  select jsonb_agg(
    case
      when q ->> 'format' = 'text' then
        jsonb_build_object('questionId', q ->> 'id', 'valueText', 'Claridad')
      else jsonb_build_object('questionId', q ->> 'id', 'valueInt', 5)
    end
  )
  into answers
  from jsonb_array_elements(opened -> 'questions') q;

  first := public.submit_company_culture_survey(org_a::text, answers);
  second := public.submit_company_culture_survey(org_a::text, answers);
  perform pg_temp.ok(first ->> 'status' = 'accepted', 'first company answer is stored');
  perform pg_temp.ok(second ->> 'status' = 'accepted', 'second company answer is stored');

  culture := public.organization_survey_culture(org_a);
  perform pg_temp.ok(
    (culture ->> 'respondentCount')::int >= 2,
    'several people from the same company are kept'
  );
  perform pg_temp.ok(culture ->> 'source' = 'survey', 'culture source is the survey');
  perform pg_temp.ok(
    exists (
      select 1
      from jsonb_array_elements_text(culture -> 'values_list') item
      where item = 'Respeto'
    ),
    'survey answers become the company values'
  );
  perform pg_temp.ok(
    exists (
      select 1
      from public.organization_culture_versions
      where organization_id = org_a
        and is_current
        and 'Respeto' = any (values_list)
    ),
    'aggregated survey culture is the current snapshot'
  );
end;
$$;
