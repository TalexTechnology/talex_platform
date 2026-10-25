-- App cutover: authenticated writes, respondent self-access, session RPCs.
-- JWT still requires firebase_uid. sub is never treated as a Firebase uid.

alter table public.profiles
  add column if not exists must_change_password boolean not null default false,
  add column if not exists must_review_company_dna boolean not null default false,
  add column if not exists document_number text;

alter table public.organizations
  add column if not exists status_before_archive text;

create table if not exists public.deals (
  id uuid primary key default gen_random_uuid(),
  organization_id uuid not null references public.organizations (id) on delete restrict,
  stage text not null check (stage in (
    'prospect', 'contacted', 'meeting', 'proposal', 'negotiation', 'client'
  )),
  estimated_value numeric,
  owner_name text,
  next_action text,
  probability numeric,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.sales (
  id uuid primary key default gen_random_uuid(),
  organization_id uuid not null references public.organizations (id) on delete restrict,
  amount numeric not null,
  product text,
  recurring boolean not null default false,
  sold_at timestamptz not null default now(),
  created_at timestamptz not null default now()
);

alter table public.deals enable row level security;
alter table public.deals force row level security;
alter table public.sales enable row level security;
alter table public.sales force row level security;

drop trigger if exists deals_updated_at on public.deals;
create trigger deals_updated_at before update on public.deals
  for each row execute function public.set_updated_at();

create or replace function public.is_uuid(p_value text)
returns boolean
language sql
immutable
as $$
  select p_value ~* '^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$';
$$;

create or replace function public.resolve_organization_id(p_id text)
returns uuid
language plpgsql
stable
security definer
set search_path = public
as $$
declare
  result uuid;
begin
  if p_id is null or btrim(p_id) = '' then
    return null;
  end if;
  if public.is_uuid(p_id) then
    select id into result
    from public.organizations
    where id = p_id::uuid or firebase_id = p_id
    limit 1;
  else
    select id into result
    from public.organizations
    where firebase_id = p_id
    limit 1;
  end if;
  return result;
end;
$$;

create or replace function public.resolve_vacancy_id(p_id text)
returns uuid
language plpgsql
stable
security definer
set search_path = public
as $$
declare
  result uuid;
begin
  if p_id is null or btrim(p_id) = '' then
    return null;
  end if;
  if public.is_uuid(p_id) then
    select id into result
    from public.vacancies
    where id = p_id::uuid or firebase_id = p_id
    limit 1;
  else
    select id into result
    from public.vacancies
    where firebase_id = p_id
    limit 1;
  end if;
  return result;
end;
$$;

create or replace function public.resolve_application_id(p_id text)
returns uuid
language plpgsql
stable
security definer
set search_path = public
as $$
declare
  result uuid;
begin
  if p_id is null or btrim(p_id) = '' then
    return null;
  end if;
  if public.is_uuid(p_id) then
    select id into result
    from public.applications
    where id = p_id::uuid or firebase_candidate_id = p_id
    limit 1;
  else
    select id into result
    from public.applications
    where firebase_candidate_id = p_id
    limit 1;
  end if;
  return result;
end;
$$;

create or replace function public.current_profile_email()
returns text
language sql
stable
security definer
set search_path = public
as $$
  select p.email
  from public.profiles p
  where p.id = public.current_profile_id();
$$;

create or replace function public.owns_application(p_application_id uuid)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1
    from public.applications a
    join public.persons pe on pe.id = a.person_id
    where a.id = p_application_id
      and public.current_profile_id() is not null
      and (
        pe.linked_profile_id = public.current_profile_id()
        or pe.email = public.current_profile_email()
      )
  );
$$;

create or replace function public.can_write_org(org_id uuid)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select public.is_superadmin() or public.is_org_member(org_id);
$$;

create or replace function public.public_entity_id(p_uuid uuid, p_firebase text)
returns text
language sql
immutable
as $$
  select coalesce(nullif(btrim(p_firebase), ''), p_uuid::text);
$$;

-- ---------------------------------------------------------------------------
-- Extra read policies for respondents (own application / company snapshot)
-- ---------------------------------------------------------------------------

create policy organizations_respondent_read on public.organizations
  for select to authenticated
  using (
    exists (
      select 1
      from public.applications a
      join public.persons pe on pe.id = a.person_id
      where a.organization_id = organizations.id
        and public.current_profile_id() is not null
        and (
          pe.linked_profile_id = public.current_profile_id()
          or pe.email = public.current_profile_email()
        )
    )
  );

create policy vacancies_respondent_read on public.vacancies
  for select to authenticated
  using (
    exists (
      select 1
      from public.applications a
      join public.persons pe on pe.id = a.person_id
      where a.vacancy_id = vacancies.id
        and (
          pe.linked_profile_id = public.current_profile_id()
          or pe.email = public.current_profile_email()
        )
    )
  );

create policy persons_self_read on public.persons
  for select to authenticated
  using (
    linked_profile_id = public.current_profile_id()
    or email = public.current_profile_email()
  );

create policy applications_self_read on public.applications
  for select to authenticated
  using (public.owns_application(id));

create policy sessions_self_read on public.survey_sessions
  for select to authenticated
  using (public.owns_application(application_id));

create policy answers_self_read on public.survey_answers
  for select to authenticated
  using (
    exists (
      select 1
      from public.survey_sessions s
      where s.id = session_id
        and public.owns_application(s.application_id)
    )
  );

create policy evaluations_self_read on public.affinity_evaluations
  for select to authenticated
  using (public.owns_application(application_id));

create policy reports_self_read on public.evaluation_reports
  for select to authenticated
  using (public.owns_application(application_id));

create policy culture_respondent_read on public.organization_culture_versions
  for select to authenticated
  using (
    exists (
      select 1
      from public.applications a
      join public.persons pe on pe.id = a.person_id
      where a.organization_id = organization_culture_versions.organization_id
        and (
          pe.linked_profile_id = public.current_profile_id()
          or pe.email = public.current_profile_email()
        )
    )
  );

create policy deals_admin_read on public.deals
  for select to authenticated
  using (public.is_superadmin());

create policy sales_admin_read on public.sales
  for select to authenticated
  using (public.is_superadmin());

-- ---------------------------------------------------------------------------
-- Write policies
-- ---------------------------------------------------------------------------

create policy profiles_self_update on public.profiles
  for update to authenticated
  using (id = public.current_profile_id())
  with check (id = public.current_profile_id());

create policy profiles_admin_update on public.profiles
  for update to authenticated
  using (public.is_superadmin())
  with check (public.is_superadmin());

create policy organizations_staff_update on public.organizations
  for update to authenticated
  using (public.can_write_org(id))
  with check (public.can_write_org(id));

create policy organizations_admin_insert on public.organizations
  for insert to authenticated
  with check (public.is_superadmin());

create policy memberships_admin_write on public.memberships
  for all to authenticated
  using (public.is_superadmin() or public.can_write_org(organization_id))
  with check (public.is_superadmin() or public.can_write_org(organization_id));

create policy culture_staff_write on public.organization_culture_versions
  for insert to authenticated
  with check (public.can_write_org(organization_id));

create policy culture_staff_update on public.organization_culture_versions
  for update to authenticated
  using (public.can_write_org(organization_id))
  with check (public.can_write_org(organization_id));

create policy dna_staff_write on public.dna_catalog_entries
  for insert to authenticated
  with check (organization_id is null or public.can_write_org(organization_id));

create policy dna_staff_delete on public.dna_catalog_entries
  for delete to authenticated
  using (
    source = 'company'
    and organization_id is not null
    and public.can_write_org(organization_id)
  );

create policy vacancies_staff_insert on public.vacancies
  for insert to authenticated
  with check (public.can_write_org(organization_id));

create policy vacancies_staff_update on public.vacancies
  for update to authenticated
  using (public.can_write_org(organization_id))
  with check (public.can_write_org(organization_id));

create policy persons_staff_insert on public.persons
  for insert to authenticated
  with check (public.is_superadmin() or public.current_profile_id() is not null);

create policy persons_staff_update on public.persons
  for update to authenticated
  using (
    public.is_superadmin()
    or linked_profile_id = public.current_profile_id()
    or email = public.current_profile_email()
    or exists (
      select 1
      from public.applications a
      where a.person_id = persons.id
        and public.can_write_org(a.organization_id)
    )
  )
  with check (true);

create policy applications_staff_insert on public.applications
  for insert to authenticated
  with check (public.can_write_org(organization_id));

create policy applications_staff_update on public.applications
  for update to authenticated
  using (public.can_write_org(organization_id) or public.owns_application(id))
  with check (public.can_write_org(organization_id) or public.owns_application(id));

create policy applications_staff_delete on public.applications
  for delete to authenticated
  using (public.can_write_org(organization_id) or public.is_superadmin());

create policy application_events_staff_insert on public.application_status_events
  for insert to authenticated
  with check (public.can_write_org(organization_id));

create policy sessions_write on public.survey_sessions
  for insert to authenticated
  with check (
    public.can_write_org(organization_id) or public.owns_application(application_id)
  );

create policy sessions_update on public.survey_sessions
  for update to authenticated
  using (
    public.can_write_org(organization_id) or public.owns_application(application_id)
  )
  with check (
    public.can_write_org(organization_id) or public.owns_application(application_id)
  );

create policy answers_write on public.survey_answers
  for insert to authenticated
  with check (
    exists (
      select 1
      from public.survey_sessions s
      where s.id = session_id
        and (
          public.can_write_org(s.organization_id)
          or public.owns_application(s.application_id)
        )
    )
  );

create policy answers_update on public.survey_answers
  for update to authenticated
  using (
    exists (
      select 1
      from public.survey_sessions s
      where s.id = session_id
        and (
          public.can_write_org(s.organization_id)
          or public.owns_application(s.application_id)
        )
    )
  )
  with check (true);

create policy evaluations_write on public.affinity_evaluations
  for insert to authenticated
  with check (
    public.can_write_org(organization_id) or public.owns_application(application_id)
  );

create policy evaluations_update on public.affinity_evaluations
  for update to authenticated
  using (
    public.can_write_org(organization_id) or public.owns_application(application_id)
  )
  with check (
    public.can_write_org(organization_id) or public.owns_application(application_id)
  );

create policy reports_write on public.evaluation_reports
  for insert to authenticated
  with check (public.can_write_org(organization_id) or public.is_superadmin());

create policy reports_update on public.evaluation_reports
  for update to authenticated
  using (public.can_write_org(organization_id) or public.is_superadmin())
  with check (public.can_write_org(organization_id) or public.is_superadmin());

create policy invites_staff_insert on public.activation_invites
  for insert to authenticated
  with check (public.can_write_org(organization_id) or public.is_superadmin());

create policy invites_staff_update on public.activation_invites
  for update to authenticated
  using (public.can_write_org(organization_id) or public.is_superadmin())
  with check (public.can_write_org(organization_id) or public.is_superadmin());

create policy invites_staff_delete on public.activation_invites
  for delete to authenticated
  using (public.can_write_org(organization_id) or public.is_superadmin());

create policy activity_staff_insert on public.activity_events
  for insert to authenticated
  with check (
    public.is_superadmin()
    or organization_id is null
    or public.can_write_org(organization_id)
  );

create policy audit_admin_insert on public.audit_logs
  for insert to authenticated
  with check (public.is_superadmin());

create policy deals_admin_write on public.deals
  for all to authenticated
  using (public.is_superadmin())
  with check (public.is_superadmin());

create policy sales_admin_write on public.sales
  for all to authenticated
  using (public.is_superadmin())
  with check (public.is_superadmin());

-- ---------------------------------------------------------------------------
-- Column grants for writes. pin_hash / token_hash stay hidden.
-- ---------------------------------------------------------------------------

grant select, insert, update, delete on table public.deals to authenticated;
grant select, insert, update, delete on table public.sales to authenticated;

grant update (
  display_name,
  must_change_password,
  must_review_company_dna,
  document_number
) on public.profiles to authenticated;

grant insert, update on public.organizations to authenticated;
grant insert, update, delete on public.memberships to authenticated;
grant insert, update on public.organization_culture_versions to authenticated;
grant insert, delete on public.dna_catalog_entries to authenticated;
grant insert, update on public.vacancies to authenticated;
grant insert, update on public.persons to authenticated;
grant insert, update, delete on public.applications to authenticated;
grant insert on public.application_status_events to authenticated;
grant insert, update on public.survey_sessions to authenticated;
grant insert, update on public.survey_answers to authenticated;
grant insert, update on public.affinity_evaluations to authenticated;
grant insert, update on public.evaluation_reports to authenticated;
grant insert, update, delete on public.activation_invites to authenticated;
grant insert on public.activity_events to authenticated;
grant insert on public.audit_logs to authenticated;

grant select on public.deals to authenticated;
grant select on public.sales to authenticated;

-- ---------------------------------------------------------------------------
-- Session and write RPCs
-- ---------------------------------------------------------------------------

create or replace function public.current_session_profile()
returns jsonb
language plpgsql
stable
security definer
set search_path = public
as $$
declare
  profile public.profiles;
  membership public.memberships;
  org public.organizations;
  person public.persons;
  application public.applications;
  role_name text;
begin
  if public.current_profile_id() is null then
    return null;
  end if;

  select * into profile
  from public.profiles
  where id = public.current_profile_id();

  role_name := 'user';
  if profile.is_superadmin then
    role_name := 'superadmin';
  end if;

  select * into membership
  from public.memberships
  where profile_id = profile.id
    and is_active
  order by created_at
  limit 1;

  if membership.id is not null then
    role_name := coalesce(nullif(membership.legacy_role, ''), membership.role);
    select * into org from public.organizations where id = membership.organization_id;
  end if;

  select * into person
  from public.persons
  where linked_profile_id = profile.id
     or email = profile.email
  order by case when linked_profile_id = profile.id then 0 else 1 end
  limit 1;

  if person.id is not null then
    select * into application
    from public.applications
    where person_id = person.id
    order by created_at desc
    limit 1;
    if role_name = 'user' and application.id is not null then
      role_name := 'respondent';
    end if;
    if org.id is null and application.id is not null then
      select * into org from public.organizations where id = application.organization_id;
    end if;
  end if;

  return jsonb_build_object(
    'profileId', profile.id,
    'firebaseUid', profile.firebase_uid,
    'email', profile.email,
    'displayName', profile.display_name,
    'isSuperadmin', profile.is_superadmin,
    'role', role_name,
    'organizationId', case
      when org.id is null then null
      else public.public_entity_id(org.id, org.firebase_id)
    end,
    'organizationUuid', org.id,
    'organizationName', org.name,
    'documentNumber', coalesce(profile.document_number, person.document_number),
    'mustChangePassword', profile.must_change_password,
    'mustReviewCompanyDna', profile.must_review_company_dna,
    'applicationId', case
      when application.id is null then null
      else public.public_entity_id(application.id, application.firebase_candidate_id)
    end
  );
end;
$$;

create or replace function public.activate_invite_pin(p_pin text)
returns jsonb
language plpgsql
security definer
set search_path = public, extensions
as $$
declare
  profile public.profiles;
  invite public.activation_invites;
  org public.organizations;
  person public.persons;
  mapped public.legacy_role_map;
begin
  if public.current_profile_id() is null then
    raise exception 'need_sign_in';
  end if;
  if p_pin is null or length(btrim(p_pin)) < 6 then
    raise exception 'invalid_pin';
  end if;

  select * into profile from public.profiles where id = public.current_profile_id();

  select * into invite
  from public.activation_invites
  where email = profile.email
    and kind = 'recruiter'
    and used = false
  order by created_at desc
  limit 1;

  if invite.id is null then
    raise exception 'invite_missing';
  end if;
  if invite.pin_expires_at is not null and invite.pin_expires_at <= now() then
    raise exception 'pin_expired';
  end if;
  if not public.verify_invite_pin(btrim(p_pin), profile.email, invite.pin_hash, invite.pin_algorithm) then
    raise exception 'invalid_pin';
  end if;

  select * into mapped
  from public.legacy_role_map
  where firestore_role = coalesce(invite.role, 'recruiter');

  insert into public.memberships (organization_id, profile_id, role, legacy_role, is_active)
  values (
    invite.organization_id,
    profile.id,
    coalesce(mapped.membership_role, 'recruiter'),
    invite.role,
    true
  )
  on conflict (organization_id, profile_id) do update
    set role = excluded.role,
        legacy_role = excluded.legacy_role,
        is_active = true;

  update public.profiles
  set
    display_name = coalesce(nullif(btrim(concat_ws(' ', invite.first_name, invite.last_name)), ''), display_name),
    document_number = coalesce(invite.document_number, document_number),
    must_change_password = false,
    must_review_company_dna = false
  where id = profile.id;

  update public.activation_invites
  set used = true
  where id = invite.id;

  select * into org from public.organizations where id = invite.organization_id;

  return jsonb_build_object(
    'organizationId', public.public_entity_id(org.id, org.firebase_id),
    'role', coalesce(invite.role, 'recruiter')
  );
end;
$$;

create or replace function public.provision_organization(
  p_name text,
  p_recruiter_email text,
  p_recruiter_first_name text,
  p_recruiter_last_name text,
  p_pin text,
  p_nit text default null,
  p_logo_url text default null,
  p_sector text default null,
  p_size text default null,
  p_city text default null,
  p_country text default null,
  p_region text default null,
  p_website text default null,
  p_description text default null,
  p_values text[] default '{}',
  p_culture text[] default '{}',
  p_standout text[] default '{}',
  p_sought text default null
)
returns jsonb
language plpgsql
security definer
set search_path = public, extensions
as $$
declare
  org public.organizations;
  pin_value text;
begin
  if not public.is_superadmin() then
    raise exception 'permission_denied';
  end if;
  if p_name is null or length(btrim(p_name)) = 0 then
    raise exception 'invalid_company';
  end if;
  if p_recruiter_email is null or position('@' in p_recruiter_email) < 2 then
    raise exception 'invalid_email';
  end if;

  pin_value := coalesce(nullif(btrim(p_pin), ''), lpad((floor(random() * 900000) + 100000)::int::text, 6, '0'));

  insert into public.organizations (
    name, nit, logo_url, sector, size_label, city, country, region, website, description, status
  ) values (
    btrim(p_name), p_nit, p_logo_url, p_sector, p_size, p_city, p_country, p_region, p_website, p_description, 'onboarding'
  ) returning * into org;

  update public.organizations
  set firebase_id = id::text
  where id = org.id
    and firebase_id is null;

  select * into org from public.organizations where id = org.id;

  insert into public.organization_culture_versions (
    organization_id, version_number, values_list, culture_list, standout_list,
    sought_characteristics, is_current, published_by
  ) values (
    org.id, 1, coalesce(p_values, '{}'), coalesce(p_culture, '{}'), coalesce(p_standout, '{}'),
    p_sought, true, public.current_profile_id()
  );

  insert into public.activation_invites (
    email, organization_id, kind, role, pin_hash, pin_algorithm, used,
    first_name, last_name, pin_expires_at
  ) values (
    public.normalize_email(p_recruiter_email),
    org.id,
    'recruiter',
    'company_admin',
    public.hash_invite_pin(pin_value),
    'bfcrypt',
    false,
    p_recruiter_first_name,
    p_recruiter_last_name,
    now() + interval '15 minutes'
  );

  insert into public.activity_events (organization_id, actor_profile_id, kind, entity_name, status_label)
  values (org.id, public.current_profile_id(), 'companyCreated', org.name, 'onboarding');

  return jsonb_build_object(
    'organizationId', public.public_entity_id(org.id, org.firebase_id),
    'pin', pin_value
  );
end;
$$;

create or replace function public.save_organization_profile(
  p_organization_id text,
  p_name text,
  p_nit text default null,
  p_logo_url text default null,
  p_sector text default null,
  p_size text default null,
  p_city text default null,
  p_country text default null,
  p_region text default null,
  p_website text default null,
  p_description text default null,
  p_values text[] default '{}',
  p_culture text[] default '{}',
  p_standout text[] default '{}',
  p_sought text default null
)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  org_id uuid;
  next_version integer;
begin
  org_id := public.resolve_organization_id(p_organization_id);
  if org_id is null or not public.can_write_org(org_id) then
    raise exception 'permission_denied';
  end if;

  update public.organizations
  set
    name = coalesce(nullif(btrim(p_name), ''), name),
    nit = p_nit,
    logo_url = p_logo_url,
    sector = p_sector,
    size_label = p_size,
    city = p_city,
    country = p_country,
    region = p_region,
    website = p_website,
    description = p_description,
    last_activity_at = now()
  where id = org_id;

  update public.organization_culture_versions
  set is_current = false
  where organization_id = org_id
    and is_current;

  select coalesce(max(version_number), 0) + 1
  into next_version
  from public.organization_culture_versions
  where organization_id = org_id;

  insert into public.organization_culture_versions (
    organization_id, version_number, values_list, culture_list, standout_list,
    sought_characteristics, is_current, published_by
  ) values (
    org_id, next_version, coalesce(p_values, '{}'), coalesce(p_culture, '{}'),
    coalesce(p_standout, '{}'), p_sought, true, public.current_profile_id()
  );

  update public.profiles
  set must_review_company_dna = false
  where id = public.current_profile_id();
end;
$$;

create or replace function public.create_staff_invite(
  p_organization_id text,
  p_email text,
  p_first_name text,
  p_last_name text,
  p_role text,
  p_pin text
)
returns jsonb
language plpgsql
security definer
set search_path = public, extensions
as $$
declare
  org_id uuid;
  pin_value text;
begin
  org_id := public.resolve_organization_id(p_organization_id);
  if org_id is null or not public.can_write_org(org_id) then
    raise exception 'permission_denied';
  end if;
  pin_value := coalesce(nullif(btrim(p_pin), ''), lpad((floor(random() * 900000) + 100000)::int::text, 6, '0'));

  update public.activation_invites
  set used = true
  where email = public.normalize_email(p_email)
    and organization_id = org_id
    and kind = 'recruiter'
    and used = false;

  insert into public.activation_invites (
    email, organization_id, kind, role, pin_hash, pin_algorithm, used,
    first_name, last_name, pin_expires_at
  ) values (
    public.normalize_email(p_email),
    org_id,
    'recruiter',
    coalesce(nullif(btrim(p_role), ''), 'recruiter'),
    public.hash_invite_pin(pin_value),
    'bfcrypt',
    false,
    p_first_name,
    p_last_name,
    now() + interval '15 minutes'
  );

  return jsonb_build_object('pin', pin_value);
end;
$$;

create or replace function public.create_respondent_application(
  p_organization_id text,
  p_vacancy_id text,
  p_email text,
  p_document_number text,
  p_display_name text,
  p_token text
)
returns jsonb
language plpgsql
security definer
set search_path = public, extensions
as $$
declare
  org_id uuid;
  vac_id uuid;
  vac public.vacancies;
  resolved_person_id uuid;
  app public.applications;
  token_value text;
  first_name text;
  last_name text;
begin
  org_id := public.resolve_organization_id(p_organization_id);
  vac_id := public.resolve_vacancy_id(p_vacancy_id);
  if org_id is null or vac_id is null or not public.can_write_org(org_id) then
    raise exception 'permission_denied';
  end if;

  select * into vac from public.vacancies where id = vac_id;
  if vac.organization_id <> org_id then
    raise exception 'permission_denied';
  end if;

  token_value := coalesce(nullif(btrim(p_token), ''), public.generate_survey_token());
  first_name := split_part(btrim(coalesce(p_display_name, '')), ' ', 1);
  last_name := nullif(btrim(substr(btrim(coalesce(p_display_name, '')), length(first_name) + 1)), '');

  insert into public.persons (email, document_number, display_name)
  values (
    public.normalize_email(p_email),
    nullif(btrim(p_document_number), ''),
    nullif(btrim(p_display_name), '')
  )
  on conflict (email) do update
    set document_number = coalesce(excluded.document_number, public.persons.document_number),
        display_name = coalesce(excluded.display_name, public.persons.display_name)
  returning id into resolved_person_id;

  insert into public.applications (
    organization_id, vacancy_id, person_id, vacancy_name, process_status
  ) values (
    org_id, vac_id, resolved_person_id, vac.name, 'pending'
  )
  on conflict (organization_id, vacancy_id, person_id) do update
    set vacancy_name = excluded.vacancy_name
  returning * into app;

  update public.applications
  set firebase_candidate_id = coalesce(firebase_candidate_id, id::text)
  where id = app.id;

  select * into app from public.applications where id = app.id;

  insert into public.activation_invites (
    email, organization_id, vacancy_id, kind, role, token_hash, used,
    application_id, first_name, last_name, document_number, token_expires_at
  ) values (
    public.normalize_email(p_email),
    org_id,
    vac_id,
    'respondent',
    'respondent',
    public.token_hash(token_value),
    false,
    app.id,
    first_name,
    last_name,
    nullif(btrim(p_document_number), ''),
    now() + interval '14 days'
  );

  insert into public.activity_events (
    organization_id, actor_profile_id, kind, entity_name, context
  ) values (
    org_id, public.current_profile_id(), 'respondentInvited', coalesce(p_display_name, p_email), vac.name
  );

  return jsonb_build_object(
    'applicationId', public.public_entity_id(app.id, app.firebase_candidate_id),
    'token', token_value
  );
end;
$$;

create or replace function public.save_affinity_answer(
  p_application_id text,
  p_question_code text,
  p_value integer
)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  app public.applications;
  resolved_session_id uuid;
  resolved_question_id uuid;
  version_id uuid;
begin
  select * into app
  from public.applications
  where id = public.resolve_application_id(p_application_id);

  if app.id is null then
    raise exception 'assessment_missing';
  end if;
  if not (public.can_write_org(app.organization_id) or public.owns_application(app.id)) then
    raise exception 'permission_denied';
  end if;
  if p_value is null or p_value < 1 or p_value > 5 then
    raise exception 'invalid_answer';
  end if;

  select v.id into version_id
  from public.survey_versions v
  join public.survey_templates t on t.id = v.template_id
  where t.slug = 'affinity-core'
    and v.status = 'published'
  order by v.version_number desc
  limit 1;

  select s.id into resolved_session_id
  from public.survey_sessions s
  where s.application_id = app.id
    and s.purpose = 'affinity'
  order by s.started_at desc
  limit 1;

  if resolved_session_id is null then
    insert into public.survey_sessions (
      version_id, purpose, organization_id, application_id, person_id, status
    ) values (
      version_id, 'affinity', app.organization_id, app.id, app.person_id, 'in_progress'
    ) returning id into resolved_session_id;
  end if;

  select q.id into resolved_question_id
  from public.survey_published_questions q
  where q.code = p_question_code
  limit 1;

  if resolved_question_id is null then
    select q.id into resolved_question_id
    from public.survey_questions q
    where q.code = p_question_code
    limit 1;
  end if;

  if resolved_question_id is null then
    raise exception 'invalid_question';
  end if;

  insert into public.survey_answers (session_id, question_id, value_int)
  values (resolved_session_id, resolved_question_id, p_value)
  on conflict (session_id, question_id) do update
    set value_int = excluded.value_int;

  update public.applications
  set process_status = 'inProgress'
  where id = app.id
    and process_status = 'pending';
end;
$$;

create or replace function public.complete_affinity_evaluation(
  p_application_id text,
  p_vacancy_affinity text,
  p_dimension_scores jsonb default null
)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  app public.applications;
  resolved_session_id uuid;
  evaluation_id uuid;
begin
  select * into app
  from public.applications
  where id = public.resolve_application_id(p_application_id);

  if app.id is null then
    raise exception 'assessment_missing';
  end if;
  if not (public.can_write_org(app.organization_id) or public.owns_application(app.id)) then
    raise exception 'permission_denied';
  end if;

  select s.id into resolved_session_id
  from public.survey_sessions s
  where s.application_id = app.id
    and s.purpose = 'affinity'
  order by s.started_at desc
  limit 1;

  if resolved_session_id is not null then
    update public.survey_sessions
    set status = 'completed', completed_at = now()
    where id = resolved_session_id;
  end if;

  update public.applications
  set
    process_status = 'completed',
    evaluation_completed = true,
    vacancy_affinity = coalesce(p_vacancy_affinity, vacancy_affinity)
  where id = app.id;

  insert into public.affinity_evaluations (
    application_id, session_id, organization_id, firebase_evaluation_id,
    status, dimension_scores, completed_at
  ) values (
    app.id, resolved_session_id, app.organization_id,
    coalesce(app.firebase_candidate_id, app.id::text),
    'completed', p_dimension_scores, now()
  )
  on conflict (application_id) do update
    set session_id = excluded.session_id,
        status = 'completed',
        dimension_scores = excluded.dimension_scores,
        completed_at = now()
  returning id into evaluation_id;

  insert into public.activity_events (
    organization_id, actor_profile_id, kind, entity_name, status_label
  )
  select app.organization_id, public.current_profile_id(), 'evaluationCompleted',
         coalesce(pe.display_name, pe.email), 'completed'
  from public.persons pe
  where pe.id = app.person_id;

  return jsonb_build_object(
    'applicationId', public.public_entity_id(app.id, app.firebase_candidate_id),
    'evaluationId', evaluation_id,
    'firebaseCandidateId', coalesce(app.firebase_candidate_id, app.id::text)
  );
end;
$$;

create or replace function public.link_respondent_profile(
  p_firebase_uid text,
  p_token_hash text
)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  invite public.activation_invites;
  profile public.profiles;
begin
  if p_firebase_uid is null or p_token_hash is null then
    raise exception 'invalid_invite';
  end if;

  select * into invite
  from public.activation_invites
  where token_hash = p_token_hash
    and kind = 'respondent'
  limit 1;

  if invite.id is null then
    return;
  end if;

  select * into profile
  from public.profiles
  where firebase_uid = p_firebase_uid;

  if profile.id is null then
    return;
  end if;

  update public.persons
  set linked_profile_id = profile.id
  where email = invite.email
    and linked_profile_id is null;

  if invite.application_id is not null then
    update public.persons
    set linked_profile_id = profile.id
    where id = (select person_id from public.applications where id = invite.application_id);
  end if;

  update public.activation_invites
  set used = true
  where id = invite.id;

  update public.profiles
  set
    display_name = coalesce(nullif(btrim(concat_ws(' ', invite.first_name, invite.last_name)), ''), display_name),
    document_number = coalesce(invite.document_number, document_number)
  where id = profile.id;
end;
$$;

grant execute on function public.is_uuid(text) to authenticated;
grant execute on function public.resolve_organization_id(text) to authenticated;
grant execute on function public.resolve_vacancy_id(text) to authenticated;
grant execute on function public.resolve_application_id(text) to authenticated;
grant execute on function public.current_profile_email() to authenticated;
grant execute on function public.owns_application(uuid) to authenticated;
grant execute on function public.can_write_org(uuid) to authenticated;
grant execute on function public.public_entity_id(uuid, text) to authenticated;
grant execute on function public.current_session_profile() to authenticated;
grant execute on function public.activate_invite_pin(text) to authenticated;
grant execute on function public.provision_organization(text, text, text, text, text, text, text, text, text, text, text, text, text, text, text[], text[], text[], text) to authenticated;
grant execute on function public.save_organization_profile(text, text, text, text, text, text, text, text, text, text, text, text[], text[], text[], text) to authenticated;
grant execute on function public.create_staff_invite(text, text, text, text, text, text) to authenticated;
grant execute on function public.create_respondent_application(text, text, text, text, text, text) to authenticated;
grant execute on function public.save_affinity_answer(text, text, integer) to authenticated;
grant execute on function public.complete_affinity_evaluation(text, text, jsonb) to authenticated;

-- link_respondent_profile is only called with the service role from Functions.
revoke all on function public.link_respondent_profile(text, text) from public, anon, authenticated;
