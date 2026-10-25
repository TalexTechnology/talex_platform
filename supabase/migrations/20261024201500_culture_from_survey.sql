-- Company culture comes from the values/culture survey answers.
-- Several people in the same company can answer; all rows are kept and aggregated.

alter table public.culture_perception_results
  alter column culture_version_id drop not null;

alter table public.survey_sessions
  drop constraint if exists survey_sessions_context;

alter table public.survey_sessions
  add constraint survey_sessions_context check (
    (
      purpose = 'affinity'
      and application_id is not null
      and public_link_id is null
    )
    or (
      purpose = 'culture_perception'
      and application_id is null
    )
  );

create or replace function public.current_culture_survey_version()
returns public.survey_versions
language plpgsql
stable
set search_path = public
as $$
declare
  version_row public.survey_versions;
begin
  select v.*
  into version_row
  from public.survey_versions v
  join public.survey_templates t on t.id = v.template_id
  where t.slug = 'culture-perception'
    and exists (
      select 1
      from public.survey_sections s
      join public.survey_questions q on q.section_id = s.id
      where s.version_id = v.id
        and q.is_active
    )
  order by
    case v.status when 'published' then 0 when 'draft' then 1 else 2 end,
    v.version_number desc
  limit 1;
  return version_row;
end;
$$;

create or replace function public.publish_survey_version(p_version_id uuid)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  current_status text;
begin
  select status into current_status
  from public.survey_versions
  where id = p_version_id;

  if current_status is null then
    raise exception 'version_not_draft';
  end if;
  if current_status = 'published' then
    return;
  end if;
  if current_status <> 'draft' then
    raise exception 'version_not_draft';
  end if;

  update public.survey_versions
  set status = 'published',
      published_at = coalesce(published_at, now())
  where id = p_version_id
    and status = 'draft';
end;
$$;

create or replace function public.publish_culture_perception_if_ready()
returns void
language plpgsql
set search_path = public
as $$
declare
  version_row public.survey_versions;
begin
  version_row := public.current_culture_survey_version();
  if version_row.id is null then
    return;
  end if;
  if version_row.status = 'draft' then
    update public.survey_versions
    set status = 'published',
        published_at = coalesce(published_at, now())
    where id = version_row.id
      and status = 'draft';
  end if;
end;
$$;

create or replace function public.organization_survey_culture_data(p_organization_id uuid)
returns jsonb
language plpgsql
stable
security definer
set search_path = public
as $$
declare
  respondents integer := 0;
  values_items text[] := '{}';
  culture_items text[] := '{}';
  standout_items text[] := '{}';
  sought_items text[] := '{}';
begin
  if p_organization_id is null then
    raise exception 'company_not_found';
  end if;

  select count(*)
  into respondents
  from public.survey_sessions s
  where s.organization_id = p_organization_id
    and s.purpose = 'culture_perception'
    and s.status = 'completed';

  with picked as (
    select
      case
        when coalesce(sec.code, '') in ('apertura') or a.format = 'text'
          then 'sought'
        when coalesce(sec.code, '') in ('values', 'cultura', 'needs')
          then 'values'
        when coalesce(sec.code, '') in ('personas')
          then 'standout'
        else 'culture'
      end as bucket,
      nullif(btrim(
        case
          when a.format = 'pair' and a.value_int <= 2 then
            coalesce(nullif(btrim(q.dimension_a), ''), a.statement_a)
          when a.format = 'pair' and a.value_int >= 4 then
            coalesce(nullif(btrim(q.dimension_b), ''), a.statement_b)
          when a.format in ('scale', 'experience', 'single')
            and a.value_int >= 4 then
            coalesce(nullif(btrim(q.dimension_a), ''), a.statement_a)
          when a.format = 'text' then a.value_text
          else null
        end
      ), '') as label
    from public.survey_sessions s
    join public.survey_answers a on a.session_id = s.id
    join public.survey_questions q on q.id = a.question_id
    join public.survey_sections sec on sec.id = q.section_id
    where s.organization_id = p_organization_id
      and s.purpose = 'culture_perception'
      and s.status = 'completed'
  ),
  ranked as (
    select bucket, label, count(*) as votes
    from picked
    where label is not null
    group by bucket, label
  )
  select
    coalesce((
      select array_agg(label order by votes desc, label)
      from ranked
      where bucket = 'values'
    ), '{}'),
    coalesce((
      select array_agg(label order by votes desc, label)
      from ranked
      where bucket = 'culture'
    ), '{}'),
    coalesce((
      select array_agg(label order by votes desc, label)
      from ranked
      where bucket = 'standout'
    ), '{}'),
    coalesce((
      select array_agg(label order by votes desc, label)
      from ranked
      where bucket = 'sought'
    ), '{}')
  into values_items, culture_items, standout_items, sought_items;

  return jsonb_build_object(
    'organizationId', p_organization_id,
    'source', case when respondents > 0 then 'survey' else 'empty' end,
    'respondentCount', respondents,
    'values_list', to_jsonb(values_items[1:25]),
    'culture_list', to_jsonb(culture_items[1:25]),
    'standout_list', to_jsonb(standout_items[1:25]),
    'sought_characteristics', nullif(array_to_string(sought_items[1:12], '; '), '')
  );
end;
$$;

create or replace function public.organization_survey_culture(p_organization_id uuid)
returns jsonb
language plpgsql
stable
security definer
set search_path = public
as $$
begin
  if not (
    public.is_superadmin()
    or public.is_org_member(p_organization_id)
    or current_setting('role', true) not in ('authenticated', 'anon')
  ) then
    raise exception 'permission_denied';
  end if;
  return public.organization_survey_culture_data(p_organization_id);
end;
$$;

create or replace function public.refresh_organization_culture_from_survey(
  p_organization_id uuid
)
returns uuid
language plpgsql
security definer
set search_path = public
as $$
declare
  payload jsonb;
  next_version integer;
  version_id uuid;
  respondents integer;
begin
  payload := public.organization_survey_culture_data(p_organization_id);
  respondents := coalesce((payload ->> 'respondentCount')::int, 0);
  if respondents = 0 then
    return null;
  end if;

  select coalesce(max(version_number), 0) + 1
  into next_version
  from public.organization_culture_versions
  where organization_id = p_organization_id;

  update public.organization_culture_versions
  set is_current = false
  where organization_id = p_organization_id
    and is_current;

  insert into public.organization_culture_versions (
    organization_id,
    version_number,
    values_list,
    culture_list,
    standout_list,
    sought_characteristics,
    is_current
  ) values (
    p_organization_id,
    next_version,
    coalesce(array(select jsonb_array_elements_text(payload -> 'values_list')), '{}'),
    coalesce(array(select jsonb_array_elements_text(payload -> 'culture_list')), '{}'),
    coalesce(array(select jsonb_array_elements_text(payload -> 'standout_list')), '{}'),
    payload ->> 'sought_characteristics',
    true
  )
  returning id into version_id;

  return version_id;
end;
$$;

create or replace function public.culture_survey_questions_payload(p_version_id uuid)
returns jsonb
language sql
stable
set search_path = public
as $$
  select coalesce((
    select jsonb_agg(
      jsonb_build_object(
        'id', q.id,
        'code', q.code,
        'front', s.code,
        'format', q.format,
        'instruction', q.instruction,
        'statementA', q.statement_a,
        'statementB', q.statement_b,
        'required', q.is_required,
        'options', (
          select coalesce(jsonb_agg(
            jsonb_build_object('value', o.value_int, 'label', o.label)
            order by o.sort_order
          ), '[]'::jsonb)
          from public.survey_options o
          where o.question_id = q.id
        )
      ) order by s.sort_order, q.sort_order
    )
    from public.survey_sections s
    join public.survey_questions q on q.section_id = s.id
    where s.version_id = p_version_id
      and q.is_active
  ), '[]'::jsonb);
$$;

create or replace function public.open_company_culture_survey(p_organization_id text)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  org_id uuid;
  version_row public.survey_versions;
begin
  org_id := public.resolve_organization_id(p_organization_id);
  if org_id is null then
    raise exception 'company_not_found';
  end if;
  if not (public.is_superadmin() or public.is_org_member(org_id)) then
    raise exception 'permission_denied';
  end if;

  version_row := public.current_culture_survey_version();
  if version_row.id is null then
    raise exception 'survey_missing';
  end if;

  return jsonb_build_object(
    'sessionPurpose', 'culture_perception',
    'organizationId', org_id,
    'versionId', version_row.id,
    'ready', true,
    'questions', public.culture_survey_questions_payload(version_row.id)
  );
end;
$$;

create or replace function public.save_culture_survey_answers(
  p_organization_id uuid,
  p_version_id uuid,
  p_answers jsonb,
  p_public_link_id uuid default null,
  p_locale text default 'es'
)
returns uuid
language plpgsql
set search_path = public
as $$
declare
  session_id uuid;
  item jsonb;
  question public.survey_questions;
  option_label text;
  culture_id uuid;
begin
  if jsonb_typeof(p_answers) <> 'array' or jsonb_array_length(p_answers) = 0 then
    raise exception 'invalid_answers';
  end if;

  if exists (
    select 1
    from public.survey_questions q
    join public.survey_sections s on s.id = q.section_id
    where s.version_id = p_version_id
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

  insert into public.survey_sessions (
    version_id, purpose, organization_id, public_link_id, locale, status, completed_at
  ) values (
    p_version_id,
    'culture_perception',
    p_organization_id,
    p_public_link_id,
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
      and s.version_id = p_version_id
      and q.is_active;

    if question.id is null then
      raise exception 'invalid_question';
    end if;

    option_label := null;
    if exists (select 1 from public.survey_options o where o.question_id = question.id) then
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
      session_id, question_id, value_int, value_text,
      question_code, format, statement_a, statement_b, option_label
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

  culture_id := public.refresh_organization_culture_from_survey(p_organization_id);

  insert into public.culture_perception_results (
    session_id, organization_id, culture_version_id
  ) values (
    session_id, p_organization_id, culture_id
  );

  return session_id;
end;
$$;

create or replace function public.submit_company_culture_survey(
  p_organization_id text,
  p_answers jsonb,
  p_locale text default 'es'
)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  org_id uuid;
  version_row public.survey_versions;
  session_id uuid;
begin
  org_id := public.resolve_organization_id(p_organization_id);
  if org_id is null then
    raise exception 'company_not_found';
  end if;
  if not (public.is_superadmin() or public.is_org_member(org_id)) then
    raise exception 'permission_denied';
  end if;

  version_row := public.current_culture_survey_version();
  if version_row.id is null then
    raise exception 'survey_missing';
  end if;

  session_id := public.save_culture_survey_answers(
    org_id, version_row.id, p_answers, null, p_locale
  );
  return jsonb_build_object('status', 'accepted', 'submissionId', session_id);
end;
$$;

create or replace function public.ensure_company_culture_link(p_organization_id text)
returns jsonb
language plpgsql
security definer
set search_path = public, extensions
as $$
declare
  org_id uuid;
  version_row public.survey_versions;
  created jsonb;
begin
  org_id := public.resolve_organization_id(p_organization_id);
  if org_id is null then
    raise exception 'company_not_found';
  end if;
  if not (public.is_superadmin() or public.can_write_org(org_id)) then
    raise exception 'permission_denied';
  end if;

  perform public.publish_culture_perception_if_ready();
  version_row := public.current_culture_survey_version();
  if version_row.id is null or version_row.status <> 'published' then
    raise exception 'survey_missing';
  end if;

  created := public.create_public_survey_link(org_id, version_row.id, 1000, null);
  return created;
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
  session_id uuid;
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

  select * into version_row from public.survey_versions where id = link.version_id;
  select purpose into template_purpose from public.survey_templates where id = version_row.template_id;
  if version_row.status <> 'published' or template_purpose <> 'culture_perception' then
    raise exception 'invalid_public_survey_version';
  end if;

  if link.response_count >= link.max_responses then
    raise exception 'link_exhausted';
  end if;

  session_id := public.save_culture_survey_answers(
    link.organization_id, link.version_id, p_answers, link.id, p_locale
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

create or replace function public.trg_publish_culture_if_ready()
returns trigger
language plpgsql
set search_path = public
as $$
begin
  perform public.publish_culture_perception_if_ready();
  return null;
end;
$$;

drop trigger if exists survey_questions_publish_culture on public.survey_questions;
create trigger survey_questions_publish_culture
  after insert or update on public.survey_questions
  for each statement
  execute function public.trg_publish_culture_if_ready();

grant execute on function public.organization_survey_culture(uuid) to authenticated;
grant execute on function public.open_company_culture_survey(text) to authenticated;
grant execute on function public.submit_company_culture_survey(text, jsonb, text) to authenticated;
grant execute on function public.ensure_company_culture_link(text) to authenticated;

revoke all on function public.organization_survey_culture_data(uuid) from public, anon, authenticated;
revoke all on function public.current_culture_survey_version() from public, anon, authenticated;
revoke all on function public.save_culture_survey_answers(uuid, uuid, jsonb, uuid, text) from public, anon, authenticated;
revoke all on function public.refresh_organization_culture_from_survey(uuid) from public, anon, authenticated;
revoke all on function public.culture_survey_questions_payload(uuid) from public, anon, authenticated;
revoke all on function public.publish_culture_perception_if_ready() from public, anon, authenticated;
