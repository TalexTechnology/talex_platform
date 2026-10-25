select
  (select count(*) from public.organizations) as organizations,
  (select count(*) from public.vacancies) as vacancies,
  (select count(*) from public.applications) as applications,
  (select count(*) from public.persons) as persons,
  (select count(*) from public.profiles) as profiles,
  (select count(*) from public.memberships) as memberships,
  (select count(*) from public.survey_questions) as questions,
  (select count(*) from public.survey_sessions) as sessions,
  (select count(*) from public.survey_answers) as answers,
  (select count(*) from public.affinity_evaluations) as evaluations,
  (select count(*) from public.evaluation_reports) as reports,
  (select count(*) from public.activation_invites) as invites,
  (select count(*) from public.firebase_id_map) as id_map;

select count(*) as mismatched_applications
from public.applications a
join public.vacancies v on v.id = a.vacancy_id
where v.organization_id <> a.organization_id;

select count(*) as completed_without_session
from public.applications a
left join public.survey_sessions s
  on s.application_id = a.id
 and s.status = 'completed'
where a.evaluation_completed
  and s.id is null;

select count(*) as answers_without_snapshot
from public.survey_answers
where statement_a is null or statement_a = '';

select count(*) as reports_with_model
from public.evaluation_reports
where model is not null or prompt_version is not null;
