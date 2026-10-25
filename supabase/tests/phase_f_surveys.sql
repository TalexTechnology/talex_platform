-- Survey banks: Gemini catalog, culture workspace, superadmin upload RPCs.

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
  affinity_sections integer;
  culture_sections integer;
  status_payload jsonb;
  listed jsonb;
  replaced jsonb;
  uploaded jsonb;
  seen integer;
begin
  reset role;
  perform set_config('request.jwt.claims', '', true);

  select count(*) into affinity_sections
  from public.survey_sections s
  join public.survey_versions v on v.id = s.version_id
  join public.survey_templates t on t.id = v.template_id
  where t.slug = 'affinity-core'
    and s.code in ('values', 'needs', 'capabilities');
  perform pg_temp.ok(affinity_sections = 3, 'affinity fronts exist');

  select count(*) into culture_sections
  from public.survey_sections s
  join public.survey_versions v on v.id = s.version_id
  join public.survey_templates t on t.id = v.template_id
  where t.slug = 'culture-perception'
    and s.code in ('cultura', 'liderazgo', 'trabajo', 'personas', 'apertura');
  perform pg_temp.ok(culture_sections = 5, 'culture perception sections are ready');

  perform pg_temp.as_user('uid-a');
  begin
    perform public.list_survey_bank('affinity-core');
    raise exception 'FAIL: member listed the survey bank';
  exception
    when others then
      if sqlerrm like '%permission_denied%' then
        raise notice 'PASS: members cannot manage survey banks';
      else
        raise;
      end if;
  end;

  reset role;
  perform pg_temp.as_user('uid-admin');
  status_payload := public.survey_bank_status();
  perform pg_temp.ok(
    jsonb_array_length(status_payload) = 2,
    'superadmin sees both survey workspaces'
  );
  perform pg_temp.ok(
    exists (
      select 1
      from jsonb_array_elements(status_payload) bank
      where bank ->> 'slug' = 'culture-perception'
        and (bank ->> 'readyToUpload')::boolean
        and jsonb_array_length(bank -> 'sections') >= 5
    ),
    'culture workspace is ready to upload'
  );

  uploaded := public.upsert_survey_question(
    'affinity-core',
    jsonb_build_object(
      'code', 'VTEST',
      'front', 'values',
      'format', 'pair',
      'dimensionA', 'Estabilidad',
      'dimensionB', 'Cambio',
      'statementA', 'Prefiero lo estable',
      'statementB', 'Prefiero el cambio',
      'options', jsonb_build_array('A', 'B', 'C', 'D', 'E'),
      'order', 99,
      'active', true
    )
  );
  perform pg_temp.ok(uploaded ->> 'code' = 'VTEST', 'superadmin can upsert published affinity');

  select count(*) into seen
  from public.survey_scoring_questions
  where code = 'VTEST'
    and dimension_a = 'Estabilidad'
    and front = 'values'
    and purpose = 'affinity';
  perform pg_temp.ok(seen = 1, 'Gemini scoring view exposes dimensions');

  replaced := public.upsert_survey_question(
    'culture-perception',
    jsonb_build_object(
      'code', 'CUL01',
      'section', 'cultura',
      'format', 'scale',
      'statementA', 'Se actúa como se dice',
      'options', jsonb_build_array('1', '2', '3', '4', '5'),
      'order', 1
    )
  );
  perform pg_temp.ok(replaced ->> 'code' = 'CUL01', 'culture questions can be uploaded now');
  perform public.upsert_survey_question(
    'culture-perception',
    jsonb_build_object(
      'code', 'APE01',
      'section', 'apertura',
      'format', 'text',
      'statementA', 'Qué cambiaría de la cultura',
      'required', false,
      'order', 2
    )
  );

  listed := public.list_survey_bank('culture-perception');
  perform pg_temp.ok(
    exists (
      select 1 from jsonb_array_elements(listed) item where item ->> 'code' = 'CUL01'
    ),
    'uploaded culture questions are listed'
  );

  perform public.delete_survey_question('affinity-core', 'VTEST');
  perform public.delete_survey_question('culture-perception', 'CUL01');
  perform public.delete_survey_question('culture-perception', 'APE01');
end;
$$;
