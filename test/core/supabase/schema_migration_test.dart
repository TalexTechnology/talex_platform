import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  late String sql;
  late String writes;
  late String banks;
  late String culture;

  setUpAll(() {
    sql = File(
      'supabase/migrations/20261024180000_init_talex.sql',
    ).readAsStringSync();
    writes = File(
      'supabase/migrations/20261024193000_app_write_access.sql',
    ).readAsStringSync();
    banks = File(
      'supabase/migrations/20261024194500_survey_banks.sql',
    ).readAsStringSync();
    culture = File(
      'supabase/migrations/20261024201500_culture_from_survey.sql',
    ).readAsStringSync();
  });

  test('creates the tenancy, application and survey tables', () {
    for (final table in [
      'profiles',
      'organizations',
      'memberships',
      'organization_culture_versions',
      'vacancies',
      'persons',
      'applications',
      'application_status_events',
      'survey_templates',
      'survey_versions',
      'survey_sections',
      'survey_questions',
      'survey_options',
      'survey_sessions',
      'survey_answers',
      'survey_submission_keys',
      'public_survey_links',
      'culture_perception_results',
      'affinity_evaluations',
      'evaluation_reports',
      'activation_invites',
      'firebase_id_map',
      'activity_events',
      'audit_logs',
      'legacy_role_map',
      'legacy_company_status_map',
    ]) {
      expect(sql, contains('create table public.$table'));
      expect(sql, contains('alter table public.$table enable row level security'));
    }
  });

  test('keeps one application per person, vacancy and company', () {
    expect(sql, contains('unique (organization_id, vacancy_id, person_id)'));
    expect(
      sql,
      contains('foreign key (vacancy_id, organization_id)'),
    );
  });

  test('does not grant private tables to anon', () {
    expect(
      sql,
      contains('revoke all on all tables in schema public from public, anon, authenticated'),
    );
    expect(
      sql,
      contains('grant execute on function public.open_culture_survey(text) to anon, authenticated'),
    );
    expect(
      sql,
      contains(
        'grant execute on function public.submit_culture_survey(text, jsonb, text, text) to anon, authenticated',
      ),
    );
  });

  test('does not use a Firebase sub fallback or open survey policies', () {
    expect(sql.contains("auth.jwt() ->> 'sub'"), isFalse);
    expect(writes.contains("auth.jwt() ->> 'sub'"), isFalse);
    expect(
      sql.contains(
        'create policy survey_questions_read on public.survey_questions\n'
        '  for select to authenticated using (true)',
      ),
      isFalse,
    );
  });

  test('builds company culture from every values survey response', () {
    expect(culture, contains('organization_survey_culture'));
    expect(culture, contains('submit_company_culture_survey'));
    expect(culture, contains('refresh_organization_culture_from_survey'));
  });

  test('keeps both survey banks in Postgres for Gemini and culture upload', () {
    expect(banks, contains('create or replace view public.survey_scoring_questions'));
    expect(banks, contains("('culture-perception', 'cultura', 'Cultura vivida', 1)"));
    expect(banks, contains('create or replace function public.replace_survey_bank('));
    expect(banks, contains('create or replace function public.upsert_survey_question('));
  });

  test('adds authenticated write RPCs and respondent self-access', () {
    expect(writes, contains('create or replace function public.current_session_profile()'));
    expect(writes, contains('create or replace function public.activate_invite_pin(p_pin text)'));
    expect(writes, contains('create or replace function public.save_affinity_answer('));
    expect(writes, contains('owns_application'));
    expect(
      writes,
      contains('grant insert, update, delete on public.applications to authenticated'),
    );
  });
}
