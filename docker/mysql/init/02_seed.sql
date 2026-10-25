CREATE DATABASE IF NOT EXISTS talex CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE talex;
SET NAMES utf8mb4;

INSERT INTO legacy_role_map (firestore_role, membership_role, creates_membership, is_superadmin, notes) VALUES
  ('superadmin', NULL, 0, 1, 'Global flag on profiles.is_superadmin.'),
  ('respondent', NULL, 0, 0, 'Candidate session. No membership.'),
  ('user', NULL, 0, 0, 'Placeholder after Google sign-in.'),
  ('company_admin', 'company_admin', 1, 0, 'Identity mapping.'),
  ('company_lead', 'company_lead', 1, 0, 'Identity mapping.'),
  ('ceo', 'company_lead', 1, 0, 'Legacy alias.'),
  ('people_ops', 'people_ops', 1, 0, 'Identity mapping.'),
  ('hr', 'people_ops', 1, 0, 'Legacy alias.'),
  ('recruiter', 'recruiter', 1, 0, 'Identity mapping.'),
  ('hiring_manager', 'hiring_manager', 1, 0, 'Identity mapping.')
ON DUPLICATE KEY UPDATE notes = VALUES(notes);

INSERT INTO legacy_company_status_map (firestore_status, postgres_status, notes) VALUES
  ('active', 'active', 'Identity mapping.'),
  ('onboarding', 'onboarding', 'Default when a company is provisioned.'),
  ('inactive', 'inactive', 'Identity mapping.'),
  ('atRisk', 'atRisk', 'Preserve camelCase from CompanyStatus.name.'),
  ('suspended', 'suspended', 'Identity mapping.')
ON DUPLICATE KEY UPDATE notes = VALUES(notes);

INSERT INTO survey_templates (id, slug, purpose, title, description) VALUES
  (
    '11111111-1111-1111-1111-111111111111',
    'affinity-core',
    'affinity',
    'Encuesta de afinidad TaleX',
    'Valores, necesidades y experiencias. Gemini lee este banco.'
  ),
  (
    '22222222-2222-2222-2222-222222222222',
    'culture-perception',
    'culture_perception',
    'Percepción cultural TaleX',
    'Formulario de valores/cultura de la empresa. Listo para cargar preguntas.'
  )
ON DUPLICATE KEY UPDATE title = VALUES(title);

INSERT INTO survey_versions (id, template_id, version_number, status, published_at) VALUES
  (
    '11111111-1111-4111-8111-111111111112',
    '11111111-1111-1111-1111-111111111111',
    1,
    'published',
    CURRENT_TIMESTAMP(6)
  ),
  (
    '22222222-2222-4222-8222-222222222223',
    '22222222-2222-2222-2222-222222222222',
    1,
    'draft',
    NULL
  )
ON DUPLICATE KEY UPDATE status = VALUES(status);

INSERT INTO survey_sections (id, version_id, code, title, sort_order) VALUES
  ('11111111-1111-4111-8111-111111111113', '11111111-1111-4111-8111-111111111112', 'values', 'Valores', 1),
  ('11111111-1111-4111-8111-111111111114', '11111111-1111-4111-8111-111111111112', 'needs', 'Necesidades', 2),
  ('11111111-1111-4111-8111-111111111115', '11111111-1111-4111-8111-111111111112', 'capabilities', 'Experiencias', 3),
  ('22222222-2222-4222-8222-222222222224', '22222222-2222-4222-8222-222222222223', 'cultura', 'Cultura vivida', 1),
  ('22222222-2222-4222-8222-222222222225', '22222222-2222-4222-8222-222222222223', 'liderazgo', 'Liderazgo y decisiones', 2),
  ('22222222-2222-4222-8222-222222222226', '22222222-2222-4222-8222-222222222223', 'trabajo', 'Forma de trabajar', 3),
  ('22222222-2222-4222-8222-222222222227', '22222222-2222-4222-8222-222222222223', 'personas', 'Personas y relaciones', 4),
  ('22222222-2222-4222-8222-222222222228', '22222222-2222-4222-8222-222222222223', 'apertura', 'Comentarios abiertos', 5)
ON DUPLICATE KEY UPDATE title = VALUES(title);
