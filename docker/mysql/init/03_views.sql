CREATE DATABASE IF NOT EXISTS talex CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE talex;
SET NAMES utf8mb4;

CREATE OR REPLACE VIEW survey_scoring_questions AS
SELECT
  q.id,
  q.code,
  q.format,
  q.statement_a,
  q.statement_b,
  q.dimension_a,
  q.dimension_b,
  q.sort_order,
  q.is_active,
  s.code AS section_code,
  s.title AS section_title,
  v.id AS version_id,
  t.slug,
  t.purpose
FROM survey_questions q
JOIN survey_sections s ON s.id = q.section_id
JOIN survey_versions v ON v.id = s.version_id
JOIN survey_templates t ON t.id = v.template_id
WHERE q.is_active = 1;

CREATE OR REPLACE VIEW current_culture_versions AS
SELECT
  organization_id,
  values_list,
  culture_list,
  standout_list,
  sought_characteristics,
  version_number,
  published_at
FROM organization_culture_versions
WHERE is_current = 1;
