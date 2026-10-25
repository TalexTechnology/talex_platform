do $$
declare
  staff_uid text;
  seen_orgs integer;
  seen_apps integer;
  seen_persons integer;
  seen_questions integer;
begin
  select p.firebase_uid
  into staff_uid
  from public.profiles p
  join public.memberships m on m.profile_id = p.id
  where m.is_active
  limit 1;

  if staff_uid is null then
    raise exception 'FAIL: no staff membership to test isolation';
  end if;

  perform set_config(
    'request.jwt.claims',
    jsonb_build_object('role', 'authenticated', 'firebase_uid', staff_uid)::text,
    true
  );
  execute 'set local role authenticated';

  select count(*) into seen_orgs from public.organizations;
  select count(*) into seen_apps from public.applications;
  select count(*) into seen_persons from public.persons;
  select count(*) into seen_questions from public.survey_questions;

  reset role;

  if seen_orgs <> 1 then
    raise exception 'FAIL: staff saw % organizations', seen_orgs;
  end if;
  if seen_apps <> 3 then
    raise exception 'FAIL: staff saw % applications', seen_apps;
  end if;
  if seen_persons <> 3 then
    raise exception 'FAIL: staff saw % persons', seen_persons;
  end if;
  if seen_questions <> 0 then
    raise exception 'FAIL: staff could read scoring questions';
  end if;

  raise notice 'PASS: staff isolation orgs=1 apps=3 persons=3 questions=0';
end;
$$;
