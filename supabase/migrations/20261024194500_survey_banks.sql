-- Question banks live in Postgres. Gemini reads scoring dimensions here.
-- Culture perception stays draft and empty so the real survey can be uploaded.

create or replace function public.survey_bank_edit_allowed()
returns boolean
language sql
stable
as $$
  select current_setting('talex.allow_survey_edit', true) = 'on';
$$;

create or replace function public.prevent_published_question_mutation()
returns trigger
language plpgsql
set search_path = public
as $$
declare
  version_status text;
begin
  if public.survey_bank_edit_allowed() then
    if tg_op = 'DELETE' then
      return old;
    end if;
    return new;
  end if;

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
  if public.survey_bank_edit_allowed() then
    if tg_op = 'DELETE' then
      return old;
    end if;
    return new;
  end if;

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
  if public.survey_bank_edit_allowed() then
    if tg_op = 'DELETE' then
      return old;
    end if;
    return new;
  end if;

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

create or replace function public.require_survey_bank_manager()
returns void
language plpgsql
stable
set search_path = public
as $$
begin
  if public.is_superadmin() then
    return;
  end if;
  if current_setting('request.jwt.claim.role', true) in ('authenticated', 'anon')
    or current_setting('role', true) in ('authenticated', 'anon') then
    raise exception 'permission_denied';
  end if;
end;
$$;

create or replace function public.survey_json_text(p_data jsonb, variadic p_keys text[])
returns text
language plpgsql
immutable
as $$
declare
  key text;
  value text;
begin
  foreach key in array p_keys loop
    if p_data ? key then
      value := nullif(btrim(p_data ->> key), '');
      if value is not null then
        return value;
      end if;
    end if;
  end loop;
  return null;
end;
$$;

create or replace function public.survey_json_int(p_data jsonb, variadic p_keys text[])
returns integer
language plpgsql
immutable
as $$
declare
  key text;
  raw text;
begin
  foreach key in array p_keys loop
    if p_data ? key and jsonb_typeof(p_data -> key) <> 'null' then
      raw := btrim(p_data ->> key);
      if raw is not null and raw <> '' then
        return raw::integer;
      end if;
    end if;
  end loop;
  return null;
end;
$$;

create or replace function public.survey_json_bool(p_data jsonb, p_default boolean, variadic p_keys text[])
returns boolean
language plpgsql
immutable
as $$
declare
  key text;
begin
  foreach key in array p_keys loop
    if p_data ? key and jsonb_typeof(p_data -> key) <> 'null' then
      return (p_data ->> key)::boolean;
    end if;
  end loop;
  return p_default;
end;
$$;

-- ---------------------------------------------------------------------------
-- Workspace: both surveys exist even before questions are uploaded
-- ---------------------------------------------------------------------------
insert into public.survey_templates (slug, purpose, title, description)
values
  (
    'affinity-core',
    'affinity',
    'Encuesta de afinidad TaleX',
    'Valores, necesidades y experiencias. Gemini lee este banco en Postgres.'
  ),
  (
    'culture-perception',
    'culture_perception',
    'Percepción cultural TaleX',
    'Encuesta que responden empresas o sus empleados para conocer la cultura vivida. Lista para cargar preguntas.'
  )
on conflict (slug) do update
  set title = excluded.title,
      description = excluded.description,
      purpose = excluded.purpose;

insert into public.survey_versions (template_id, version_number, status, published_at)
select id, 1, 'published', now()
from public.survey_templates
where slug = 'affinity-core'
on conflict (template_id, version_number) do nothing;

insert into public.survey_versions (template_id, version_number, status)
select id, 1, 'draft'
from public.survey_templates
where slug = 'culture-perception'
on conflict (template_id, version_number) do nothing;

select set_config('talex.allow_survey_edit', 'on', true);

insert into public.survey_sections (version_id, code, title, sort_order)
select v.id, seed.code, seed.title, seed.sort_order
from public.survey_versions v
join public.survey_templates t on t.id = v.template_id
join (
  values
    ('affinity-core', 'values', 'Valores', 1),
    ('affinity-core', 'needs', 'Necesidades', 2),
    ('affinity-core', 'capabilities', 'Experiencias', 3),
    ('culture-perception', 'cultura', 'Cultura vivida', 1),
    ('culture-perception', 'liderazgo', 'Liderazgo y decisiones', 2),
    ('culture-perception', 'trabajo', 'Forma de trabajar', 3),
    ('culture-perception', 'personas', 'Personas y relaciones', 4),
    ('culture-perception', 'apertura', 'Comentarios abiertos', 5)
) as seed(slug, code, title, sort_order) on seed.slug = t.slug
on conflict (version_id, code) do update
  set title = excluded.title,
      sort_order = excluded.sort_order;

select set_config('talex.allow_survey_edit', 'off', true);

create or replace view public.survey_scoring_questions
with (security_invoker = true) as
select
  q.id,
  q.code,
  q.format,
  q.instruction,
  q.statement_a,
  q.statement_b,
  q.dimension_a,
  q.dimension_b,
  q.time_limit_seconds,
  q.sort_order,
  q.is_required,
  q.is_active,
  s.id as section_id,
  s.code as front,
  s.title as section_title,
  s.sort_order as section_sort,
  v.id as version_id,
  v.version_number,
  v.status as version_status,
  t.slug,
  t.purpose
from public.survey_questions q
join public.survey_sections s on s.id = q.section_id
join public.survey_versions v on v.id = s.version_id
join public.survey_templates t on t.id = v.template_id;

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

create or replace function public.current_survey_version(p_slug text)
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
  where t.slug = p_slug
  order by
    case v.status when 'published' then 0 when 'draft' then 1 else 2 end,
    v.version_number desc
  limit 1;

  if version_row.id is null then
    raise exception 'survey_missing';
  end if;
  return version_row;
end;
$$;

create or replace function public.ensure_survey_section(
  p_version_id uuid,
  p_code text,
  p_title text default null,
  p_sort_order integer default null
)
returns public.survey_sections
language plpgsql
set search_path = public
as $$
declare
  section_row public.survey_sections;
  next_sort integer;
begin
  select * into section_row
  from public.survey_sections
  where version_id = p_version_id
    and code = p_code;

  if section_row.id is not null then
    return section_row;
  end if;

  select coalesce(max(sort_order), 0) + 1
  into next_sort
  from public.survey_sections
  where version_id = p_version_id;

  insert into public.survey_sections (
    version_id, code, title, sort_order
  ) values (
    p_version_id,
    p_code,
    coalesce(nullif(btrim(p_title), ''), p_code),
    coalesce(p_sort_order, next_sort)
  )
  returning * into section_row;

  return section_row;
end;
$$;

create or replace function public.survey_question_payload(p_question public.survey_questions)
returns jsonb
language plpgsql
stable
set search_path = public
as $$
declare
  section_row public.survey_sections;
  options jsonb;
begin
  select * into section_row
  from public.survey_sections
  where id = p_question.section_id;

  select coalesce(
    jsonb_agg(o.label order by o.sort_order, o.value_int),
    '[]'::jsonb
  )
  into options
  from public.survey_options o
  where o.question_id = p_question.id;

  return jsonb_build_object(
    'id', p_question.id,
    'code', p_question.code,
    'front', section_row.code,
    'section', section_row.code,
    'sectionTitle', section_row.title,
    'format', p_question.format,
    'instruction', p_question.instruction,
    'statementA', p_question.statement_a,
    'statementB', p_question.statement_b,
    'dimensionA', p_question.dimension_a,
    'dimensionB', p_question.dimension_b,
    'options', options,
    'timeLimitSeconds', p_question.time_limit_seconds,
    'order', p_question.sort_order,
    'required', p_question.is_required,
    'active', p_question.is_active
  );
end;
$$;

create or replace function public.upsert_survey_question(p_slug text, p_question jsonb)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  version_row public.survey_versions;
  section_row public.survey_sections;
  question_row public.survey_questions;
  resolved_code text;
  resolved_section text;
  resolved_format text;
  option_label text;
  option_index integer := 0;
begin
  perform public.require_survey_bank_manager();
  perform set_config('talex.allow_survey_edit', 'on', true);

  if p_question is null or jsonb_typeof(p_question) <> 'object' then
    raise exception 'invalid_question';
  end if;

  version_row := public.current_survey_version(p_slug);
  resolved_code := upper(public.survey_json_text(p_question, 'code'));
  resolved_section := lower(public.survey_json_text(p_question, 'section', 'front'));
  resolved_format := lower(public.survey_json_text(p_question, 'format'));

  if resolved_code is null or resolved_section is null then
    raise exception 'invalid_question';
  end if;
  if resolved_format is null then
    resolved_format := case
      when resolved_section = 'capabilities' then 'experience'
      when resolved_section in ('values', 'needs') then 'pair'
      when resolved_section = 'apertura' then 'text'
      else 'scale'
    end;
  end if;
  if resolved_format not in ('pair', 'experience', 'single', 'multi', 'scale', 'text') then
    raise exception 'invalid_question';
  end if;

  section_row := public.ensure_survey_section(
    version_row.id,
    resolved_section,
    public.survey_json_text(p_question, 'sectionTitle', 'section_title')
  );

  select q.*
  into question_row
  from public.survey_questions q
  join public.survey_sections s on s.id = q.section_id
  where s.version_id = version_row.id
    and q.code = resolved_code
  limit 1;

  if question_row.id is null then
    insert into public.survey_questions (
      section_id, code, format, instruction, statement_a, statement_b,
      dimension_a, dimension_b, time_limit_seconds, sort_order,
      is_required, is_active
    ) values (
      section_row.id,
      resolved_code,
      resolved_format,
      public.survey_json_text(p_question, 'instruction'),
      coalesce(
        public.survey_json_text(p_question, 'statementA', 'statement_a'),
        resolved_code
      ),
      public.survey_json_text(p_question, 'statementB', 'statement_b'),
      public.survey_json_text(p_question, 'dimensionA', 'dimension_a'),
      public.survey_json_text(p_question, 'dimensionB', 'dimension_b'),
      public.survey_json_int(p_question, 'timeLimitSeconds', 'time_limit_seconds'),
      coalesce(public.survey_json_int(p_question, 'order', 'sort_order'), 0),
      public.survey_json_bool(p_question, true, 'required', 'is_required'),
      public.survey_json_bool(p_question, true, 'active', 'is_active')
    )
    returning * into question_row;
  else
    update public.survey_questions
    set
      section_id = section_row.id,
      format = resolved_format,
      instruction = public.survey_json_text(p_question, 'instruction'),
      statement_a = coalesce(
        public.survey_json_text(p_question, 'statementA', 'statement_a'),
        statement_a
      ),
      statement_b = public.survey_json_text(p_question, 'statementB', 'statement_b'),
      dimension_a = public.survey_json_text(p_question, 'dimensionA', 'dimension_a'),
      dimension_b = public.survey_json_text(p_question, 'dimensionB', 'dimension_b'),
      time_limit_seconds = public.survey_json_int(
        p_question, 'timeLimitSeconds', 'time_limit_seconds'
      ),
      sort_order = coalesce(
        public.survey_json_int(p_question, 'order', 'sort_order'),
        sort_order
      ),
      is_required = public.survey_json_bool(p_question, is_required, 'required', 'is_required'),
      is_active = public.survey_json_bool(p_question, is_active, 'active', 'is_active')
    where id = question_row.id
    returning * into question_row;
  end if;

  delete from public.survey_options where question_id = question_row.id;
  if p_question ? 'options' and jsonb_typeof(p_question -> 'options') = 'array' then
    for option_label in
      select value
      from jsonb_array_elements_text(p_question -> 'options') as value
    loop
      option_index := option_index + 1;
      insert into public.survey_options (question_id, value_int, label, sort_order)
      values (question_row.id, option_index, option_label, option_index);
    end loop;
  end if;

  return public.survey_question_payload(question_row);
end;
$$;

create or replace function public.replace_survey_bank(p_slug text, p_questions jsonb)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  version_row public.survey_versions;
  question_data jsonb;
  uploaded text[] := '{}';
  removed integer := 0;
  deactivated integer := 0;
  saved integer := 0;
begin
  perform public.require_survey_bank_manager();
  perform set_config('talex.allow_survey_edit', 'on', true);

  if p_questions is null or jsonb_typeof(p_questions) <> 'array' then
    raise exception 'invalid_question';
  end if;

  version_row := public.current_survey_version(p_slug);

  for question_data in
    select value from jsonb_array_elements(p_questions)
  loop
    perform public.upsert_survey_question(p_slug, question_data);
    uploaded := array_append(
      uploaded,
      upper(public.survey_json_text(question_data, 'code'))
    );
    saved := saved + 1;
  end loop;

  for question_data in
    select jsonb_build_object('id', q.id, 'code', q.code)
    from public.survey_questions q
    join public.survey_sections s on s.id = q.section_id
    where s.version_id = version_row.id
      and not (q.code = any (uploaded))
  loop
    if exists (
      select 1
      from public.survey_answers a
      where a.question_id = (question_data ->> 'id')::uuid
    ) then
      update public.survey_questions
      set is_active = false
      where id = (question_data ->> 'id')::uuid;
      deactivated := deactivated + 1;
    else
      delete from public.survey_options
      where question_id = (question_data ->> 'id')::uuid;
      delete from public.survey_questions
      where id = (question_data ->> 'id')::uuid;
      removed := removed + 1;
    end if;
  end loop;

  return jsonb_build_object(
    'slug', p_slug,
    'saved', saved,
    'removed', removed,
    'deactivated', deactivated
  );
end;
$$;

create or replace function public.list_survey_bank(p_slug text)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  version_row public.survey_versions;
begin
  perform public.require_survey_bank_manager();
  version_row := public.current_survey_version(p_slug);

  return coalesce(
    (
      select jsonb_agg(public.survey_question_payload(q) order by q.sort_order, q.code)
      from public.survey_questions q
      join public.survey_sections s on s.id = q.section_id
      where s.version_id = version_row.id
    ),
    '[]'::jsonb
  );
end;
$$;

create or replace function public.survey_bank_status()
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
begin
  perform public.require_survey_bank_manager();

  return coalesce(
    (
      select jsonb_agg(bank order by bank ->> 'slug')
      from (
        select jsonb_build_object(
          'slug', t.slug,
          'purpose', t.purpose,
          'title', t.title,
          'version', v.version_number,
          'status', v.status,
          'questionCount', (
            select count(*)
            from public.survey_questions q
            join public.survey_sections s on s.id = q.section_id
            where s.version_id = v.id
          ),
          'activeCount', (
            select count(*)
            from public.survey_questions q
            join public.survey_sections s on s.id = q.section_id
            where s.version_id = v.id
              and q.is_active
          ),
          'readyToUpload', t.purpose = 'culture_perception',
          'sections', (
            select coalesce(jsonb_agg(
              jsonb_build_object(
                'code', s.code,
                'title', s.title,
                'sortOrder', s.sort_order,
                'questionCount', (
                  select count(*)
                  from public.survey_questions q
                  where q.section_id = s.id
                )
              )
              order by s.sort_order
            ), '[]'::jsonb)
            from public.survey_sections s
            where s.version_id = v.id
          )
        ) as bank
        from public.survey_templates t
        join lateral (
          select *
          from public.survey_versions v
          where v.template_id = t.id
          order by
            case v.status when 'published' then 0 when 'draft' then 1 else 2 end,
            v.version_number desc
          limit 1
        ) v on true
        where t.slug in ('affinity-core', 'culture-perception')
      ) rows
    ),
    '[]'::jsonb
  );
end;
$$;

create or replace function public.set_survey_question_active(
  p_slug text,
  p_code text,
  p_active boolean
)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  version_row public.survey_versions;
  question_row public.survey_questions;
begin
  perform public.require_survey_bank_manager();
  perform set_config('talex.allow_survey_edit', 'on', true);
  version_row := public.current_survey_version(p_slug);

  update public.survey_questions q
  set is_active = p_active
  from public.survey_sections s
  where q.section_id = s.id
    and s.version_id = version_row.id
    and q.code = upper(p_code)
  returning q.* into question_row;

  if question_row.id is null then
    raise exception 'question_missing';
  end if;
  return public.survey_question_payload(question_row);
end;
$$;

create or replace function public.swap_survey_question_order(
  p_slug text,
  p_code_a text,
  p_code_b text
)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  version_row public.survey_versions;
  first_id uuid;
  second_id uuid;
  first_order integer;
  second_order integer;
begin
  perform public.require_survey_bank_manager();
  perform set_config('talex.allow_survey_edit', 'on', true);
  version_row := public.current_survey_version(p_slug);

  select q.id, q.sort_order
  into first_id, first_order
  from public.survey_questions q
  join public.survey_sections s on s.id = q.section_id
  where s.version_id = version_row.id
    and q.code = upper(p_code_a);

  select q.id, q.sort_order
  into second_id, second_order
  from public.survey_questions q
  join public.survey_sections s on s.id = q.section_id
  where s.version_id = version_row.id
    and q.code = upper(p_code_b);

  if first_id is null or second_id is null then
    raise exception 'question_missing';
  end if;

  update public.survey_questions set sort_order = second_order where id = first_id;
  update public.survey_questions set sort_order = first_order where id = second_id;

  return public.list_survey_bank(p_slug);
end;
$$;

create or replace function public.delete_survey_question(p_slug text, p_code text)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  version_row public.survey_versions;
  question_row public.survey_questions;
begin
  perform public.require_survey_bank_manager();
  perform set_config('talex.allow_survey_edit', 'on', true);
  version_row := public.current_survey_version(p_slug);

  select q.*
  into question_row
  from public.survey_questions q
  join public.survey_sections s on s.id = q.section_id
  where s.version_id = version_row.id
    and q.code = upper(p_code);

  if question_row.id is null then
    raise exception 'question_missing';
  end if;
  if exists (
    select 1 from public.survey_answers a where a.question_id = question_row.id
  ) then
    raise exception 'question_has_answers';
  end if;

  delete from public.survey_options where question_id = question_row.id;
  delete from public.survey_questions where id = question_row.id;
  return jsonb_build_object('deleted', question_row.code);
end;
$$;

drop policy if exists survey_templates_admin_write on public.survey_templates;
create policy survey_templates_admin_write on public.survey_templates
  for all to authenticated
  using (public.is_superadmin())
  with check (public.is_superadmin());

drop policy if exists survey_versions_admin_write on public.survey_versions;
create policy survey_versions_admin_write on public.survey_versions
  for all to authenticated
  using (public.is_superadmin())
  with check (public.is_superadmin());

drop policy if exists survey_sections_admin_write on public.survey_sections;
create policy survey_sections_admin_write on public.survey_sections
  for all to authenticated
  using (public.is_superadmin())
  with check (public.is_superadmin());

drop policy if exists survey_questions_admin_write on public.survey_questions;
create policy survey_questions_admin_write on public.survey_questions
  for all to authenticated
  using (public.is_superadmin())
  with check (public.is_superadmin());

drop policy if exists survey_options_admin_write on public.survey_options;
create policy survey_options_admin_write on public.survey_options
  for all to authenticated
  using (public.is_superadmin())
  with check (public.is_superadmin());

grant select on public.survey_scoring_questions to authenticated;
grant insert, update, delete on
  public.survey_templates,
  public.survey_versions,
  public.survey_sections,
  public.survey_questions,
  public.survey_options
to authenticated;

grant execute on function public.survey_bank_status() to authenticated;
grant execute on function public.list_survey_bank(text) to authenticated;
grant execute on function public.upsert_survey_question(text, jsonb) to authenticated;
grant execute on function public.replace_survey_bank(text, jsonb) to authenticated;
grant execute on function public.set_survey_question_active(text, text, boolean) to authenticated;
grant execute on function public.swap_survey_question_order(text, text, text) to authenticated;
grant execute on function public.delete_survey_question(text, text) to authenticated;

revoke all on function public.require_survey_bank_manager() from public, anon, authenticated;
revoke all on function public.survey_json_text(jsonb, text[]) from public, anon, authenticated;
revoke all on function public.survey_json_int(jsonb, text[]) from public, anon, authenticated;
revoke all on function public.survey_json_bool(jsonb, boolean, text[]) from public, anon, authenticated;
revoke all on function public.current_survey_version(text) from public, anon, authenticated;
revoke all on function public.ensure_survey_section(uuid, text, text, integer) from public, anon, authenticated;
revoke all on function public.survey_question_payload(public.survey_questions) from public, anon, authenticated;
revoke all on function public.survey_bank_edit_allowed() from public, anon, authenticated;
