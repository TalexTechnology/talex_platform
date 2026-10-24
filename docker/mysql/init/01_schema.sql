-- TaleX MySQL 8 schema. Same domain as Postgres; RLS lives in the local API.
CREATE DATABASE IF NOT EXISTS talex CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE talex;
SET NAMES utf8mb4;
SET time_zone = '+00:00';

CREATE TABLE IF NOT EXISTS legacy_role_map (
  firestore_role VARCHAR(64) PRIMARY KEY,
  membership_role VARCHAR(64) NULL,
  creates_membership TINYINT(1) NOT NULL,
  is_superadmin TINYINT(1) NOT NULL DEFAULT 0,
  notes TEXT NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS legacy_company_status_map (
  firestore_status VARCHAR(64) PRIMARY KEY,
  postgres_status VARCHAR(64) NOT NULL,
  notes TEXT NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS profiles (
  id CHAR(36) PRIMARY KEY,
  firebase_uid VARCHAR(128) NULL,
  email VARCHAR(255) NOT NULL,
  display_name VARCHAR(255) NULL,
  is_active TINYINT(1) NOT NULL DEFAULT 1,
  is_superadmin TINYINT(1) NOT NULL DEFAULT 0,
  must_change_password TINYINT(1) NOT NULL DEFAULT 0,
  must_review_company_dna TINYINT(1) NOT NULL DEFAULT 0,
  document_number VARCHAR(64) NULL,
  created_at DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
  updated_at DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6) ON UPDATE CURRENT_TIMESTAMP(6),
  UNIQUE KEY profiles_firebase_uid (firebase_uid),
  UNIQUE KEY profiles_email_unique (email)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS organizations (
  id CHAR(36) PRIMARY KEY,
  firebase_id VARCHAR(128) NULL,
  name VARCHAR(255) NOT NULL,
  nit VARCHAR(64) NULL,
  logo_url TEXT NULL,
  sector VARCHAR(128) NULL,
  size_label VARCHAR(64) NULL,
  city VARCHAR(128) NULL,
  country VARCHAR(128) NULL,
  region VARCHAR(128) NULL,
  website VARCHAR(255) NULL,
  description TEXT NULL,
  status VARCHAR(32) NOT NULL DEFAULT 'onboarding',
  archived TINYINT(1) NOT NULL DEFAULT 0,
  archived_at DATETIME(6) NULL,
  status_before_archive VARCHAR(32) NULL,
  plan VARCHAR(64) NULL,
  contract_value DECIMAL(14,2) NULL,
  mrr DECIMAL(14,2) NULL,
  renewal_at DATETIME(6) NULL,
  commercial_stage VARCHAR(32) NULL,
  last_activity_at DATETIME(6) NULL,
  created_at DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
  updated_at DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6) ON UPDATE CURRENT_TIMESTAMP(6),
  UNIQUE KEY organizations_firebase_id (firebase_id),
  CONSTRAINT organizations_status_chk CHECK (status IN ('active','onboarding','inactive','atRisk','suspended'))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS memberships (
  id CHAR(36) PRIMARY KEY,
  organization_id CHAR(36) NOT NULL,
  profile_id CHAR(36) NOT NULL,
  role VARCHAR(32) NOT NULL,
  legacy_role VARCHAR(32) NULL,
  is_active TINYINT(1) NOT NULL DEFAULT 1,
  created_at DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
  updated_at DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6) ON UPDATE CURRENT_TIMESTAMP(6),
  UNIQUE KEY memberships_org_profile (organization_id, profile_id),
  KEY memberships_profile_idx (profile_id, is_active),
  CONSTRAINT memberships_org_fk FOREIGN KEY (organization_id) REFERENCES organizations (id),
  CONSTRAINT memberships_profile_fk FOREIGN KEY (profile_id) REFERENCES profiles (id),
  CONSTRAINT memberships_role_chk CHECK (role IN ('company_admin','company_lead','people_ops','recruiter','hiring_manager'))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS organization_culture_versions (
  id CHAR(36) PRIMARY KEY,
  organization_id CHAR(36) NOT NULL,
  version_number INT NOT NULL,
  values_list JSON NOT NULL,
  culture_list JSON NOT NULL,
  standout_list JSON NOT NULL,
  sought_characteristics TEXT NULL,
  is_current TINYINT(1) NOT NULL DEFAULT 0,
  published_by CHAR(36) NULL,
  published_at DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
  UNIQUE KEY culture_org_version (organization_id, version_number),
  UNIQUE KEY culture_id_org (id, organization_id),
  KEY culture_org_current (organization_id, is_current),
  CONSTRAINT culture_org_fk FOREIGN KEY (organization_id) REFERENCES organizations (id),
  CONSTRAINT culture_published_by_fk FOREIGN KEY (published_by) REFERENCES profiles (id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS dna_catalog_entries (
  id CHAR(36) PRIMARY KEY,
  type VARCHAR(32) NOT NULL,
  label_es VARCHAR(255) NOT NULL,
  label_en VARCHAR(255) NULL,
  source VARCHAR(32) NOT NULL DEFAULT 'seed',
  organization_id CHAR(36) NULL,
  firebase_id VARCHAR(128) NULL,
  created_at DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
  UNIQUE KEY dna_firebase_id (firebase_id),
  CONSTRAINT dna_org_fk FOREIGN KEY (organization_id) REFERENCES organizations (id),
  CONSTRAINT dna_type_chk CHECK (type IN ('values','culture','standout','area')),
  CONSTRAINT dna_source_chk CHECK (source IN ('seed','company'))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS vacancies (
  id CHAR(36) PRIMARY KEY,
  organization_id CHAR(36) NOT NULL,
  firebase_id VARCHAR(128) NULL,
  name VARCHAR(255) NOT NULL,
  status VARCHAR(16) NOT NULL DEFAULT 'active',
  area VARCHAR(128) NULL,
  description TEXT NULL,
  city VARCHAR(128) NULL,
  country VARCHAR(128) NULL,
  region VARCHAR(128) NULL,
  work_mode VARCHAR(64) NULL,
  contract_type VARCHAR(64) NULL,
  seniority VARCHAR(64) NULL,
  role_profile TEXT NULL,
  created_by CHAR(36) NULL,
  created_at DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
  updated_at DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6) ON UPDATE CURRENT_TIMESTAMP(6),
  UNIQUE KEY vacancies_id_org (id, organization_id),
  UNIQUE KEY vacancies_firebase_id (firebase_id),
  KEY vacancies_org_status_idx (organization_id, status),
  CONSTRAINT vacancies_org_fk FOREIGN KEY (organization_id) REFERENCES organizations (id),
  CONSTRAINT vacancies_created_by_fk FOREIGN KEY (created_by) REFERENCES profiles (id),
  CONSTRAINT vacancies_status_chk CHECK (status IN ('active','closed'))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS persons (
  id CHAR(36) PRIMARY KEY,
  email VARCHAR(255) NOT NULL,
  document_number VARCHAR(64) NULL,
  display_name VARCHAR(255) NULL,
  linked_profile_id CHAR(36) NULL,
  created_at DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
  updated_at DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6) ON UPDATE CURRENT_TIMESTAMP(6),
  UNIQUE KEY persons_email_unique (email),
  KEY persons_document_idx (document_number),
  CONSTRAINT persons_linked_fk FOREIGN KEY (linked_profile_id) REFERENCES profiles (id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS applications (
  id CHAR(36) PRIMARY KEY,
  organization_id CHAR(36) NOT NULL,
  vacancy_id CHAR(36) NOT NULL,
  person_id CHAR(36) NOT NULL,
  firebase_candidate_id VARCHAR(128) NULL,
  vacancy_name VARCHAR(255) NULL,
  process_status VARCHAR(32) NOT NULL DEFAULT 'pending',
  assessment_kind VARCHAR(32) NULL,
  company_affinity VARCHAR(16) NOT NULL DEFAULT 'unknown',
  vacancy_affinity VARCHAR(16) NOT NULL DEFAULT 'unknown',
  evaluation_completed TINYINT(1) NOT NULL DEFAULT 0,
  result_requested TINYINT(1) NOT NULL DEFAULT 0,
  result_requested_at DATETIME(6) NULL,
  created_at DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
  updated_at DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6) ON UPDATE CURRENT_TIMESTAMP(6),
  UNIQUE KEY applications_id_org (id, organization_id),
  UNIQUE KEY applications_org_vacancy_person (organization_id, vacancy_id, person_id),
  UNIQUE KEY applications_firebase_candidate (firebase_candidate_id),
  KEY applications_org_status_idx (organization_id, process_status),
  KEY applications_person_idx (person_id),
  CONSTRAINT applications_person_fk FOREIGN KEY (person_id) REFERENCES persons (id),
  CONSTRAINT applications_vacancy_org_fk FOREIGN KEY (vacancy_id, organization_id) REFERENCES vacancies (id, organization_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS application_status_events (
  id CHAR(36) PRIMARY KEY,
  application_id CHAR(36) NOT NULL,
  organization_id CHAR(36) NOT NULL,
  from_status VARCHAR(32) NULL,
  to_status VARCHAR(32) NOT NULL,
  changed_by CHAR(36) NULL,
  changed_at DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
  KEY application_status_events_application_idx (application_id),
  CONSTRAINT application_events_app_fk FOREIGN KEY (application_id, organization_id) REFERENCES applications (id, organization_id),
  CONSTRAINT application_events_changed_fk FOREIGN KEY (changed_by) REFERENCES profiles (id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS survey_templates (
  id CHAR(36) PRIMARY KEY,
  slug VARCHAR(64) NOT NULL,
  purpose VARCHAR(32) NOT NULL,
  title VARCHAR(255) NOT NULL,
  description TEXT NULL,
  created_at DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
  updated_at DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6) ON UPDATE CURRENT_TIMESTAMP(6),
  UNIQUE KEY survey_templates_slug (slug),
  CONSTRAINT survey_templates_purpose_chk CHECK (purpose IN ('affinity','culture_perception'))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS survey_versions (
  id CHAR(36) PRIMARY KEY,
  template_id CHAR(36) NOT NULL,
  version_number INT NOT NULL,
  status VARCHAR(16) NOT NULL DEFAULT 'draft',
  published_at DATETIME(6) NULL,
  created_at DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
  UNIQUE KEY survey_versions_template_number (template_id, version_number),
  CONSTRAINT survey_versions_template_fk FOREIGN KEY (template_id) REFERENCES survey_templates (id),
  CONSTRAINT survey_versions_status_chk CHECK (status IN ('draft','published','retired'))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS survey_sections (
  id CHAR(36) PRIMARY KEY,
  version_id CHAR(36) NOT NULL,
  code VARCHAR(64) NOT NULL,
  title VARCHAR(255) NOT NULL,
  sort_order INT NOT NULL DEFAULT 0,
  UNIQUE KEY survey_sections_version_code (version_id, code),
  CONSTRAINT survey_sections_version_fk FOREIGN KEY (version_id) REFERENCES survey_versions (id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS survey_questions (
  id CHAR(36) PRIMARY KEY,
  section_id CHAR(36) NOT NULL,
  code VARCHAR(64) NOT NULL,
  format VARCHAR(32) NOT NULL,
  instruction TEXT NULL,
  statement_a TEXT NOT NULL,
  statement_b TEXT NULL,
  dimension_a VARCHAR(128) NULL,
  dimension_b VARCHAR(128) NULL,
  time_limit_seconds INT NULL,
  sort_order INT NOT NULL DEFAULT 0,
  is_required TINYINT(1) NOT NULL DEFAULT 1,
  is_active TINYINT(1) NOT NULL DEFAULT 1,
  UNIQUE KEY survey_questions_section_code (section_id, code),
  CONSTRAINT survey_questions_section_fk FOREIGN KEY (section_id) REFERENCES survey_sections (id),
  CONSTRAINT survey_questions_format_chk CHECK (format IN ('pair','experience','single','multi','scale','text'))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS survey_options (
  id CHAR(36) PRIMARY KEY,
  question_id CHAR(36) NOT NULL,
  value_int INT NOT NULL,
  label VARCHAR(255) NOT NULL,
  sort_order INT NOT NULL DEFAULT 0,
  UNIQUE KEY survey_options_question_value (question_id, value_int),
  CONSTRAINT survey_options_question_fk FOREIGN KEY (question_id) REFERENCES survey_questions (id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS public_survey_links (
  id CHAR(36) PRIMARY KEY,
  organization_id CHAR(36) NOT NULL,
  version_id CHAR(36) NOT NULL,
  token_hash VARCHAR(128) NOT NULL,
  status VARCHAR(16) NOT NULL DEFAULT 'active',
  expires_at DATETIME(6) NULL,
  max_responses INT NOT NULL DEFAULT 1000,
  response_count INT NOT NULL DEFAULT 0,
  created_by CHAR(36) NULL,
  created_at DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
  UNIQUE KEY public_survey_links_id_org (id, organization_id),
  UNIQUE KEY public_survey_links_token (token_hash),
  CONSTRAINT public_survey_links_org_fk FOREIGN KEY (organization_id) REFERENCES organizations (id),
  CONSTRAINT public_survey_links_version_fk FOREIGN KEY (version_id) REFERENCES survey_versions (id),
  CONSTRAINT public_survey_links_created_fk FOREIGN KEY (created_by) REFERENCES profiles (id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS survey_sessions (
  id CHAR(36) PRIMARY KEY,
  version_id CHAR(36) NOT NULL,
  purpose VARCHAR(32) NOT NULL,
  organization_id CHAR(36) NOT NULL,
  application_id CHAR(36) NULL,
  person_id CHAR(36) NULL,
  public_link_id CHAR(36) NULL,
  locale VARCHAR(8) NOT NULL DEFAULT 'es',
  status VARCHAR(16) NOT NULL DEFAULT 'in_progress',
  started_at DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
  completed_at DATETIME(6) NULL,
  UNIQUE KEY survey_sessions_id_org (id, organization_id),
  KEY survey_sessions_org_purpose_idx (organization_id, purpose, status),
  KEY survey_sessions_application_idx (application_id),
  CONSTRAINT survey_sessions_version_fk FOREIGN KEY (version_id) REFERENCES survey_versions (id),
  CONSTRAINT survey_sessions_org_fk FOREIGN KEY (organization_id) REFERENCES organizations (id),
  CONSTRAINT survey_sessions_person_fk FOREIGN KEY (person_id) REFERENCES persons (id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS survey_answers (
  id CHAR(36) PRIMARY KEY,
  session_id CHAR(36) NOT NULL,
  question_id CHAR(36) NOT NULL,
  value_int INT NULL,
  value_text TEXT NULL,
  question_code VARCHAR(64) NULL,
  format VARCHAR(32) NULL,
  statement_a TEXT NULL,
  statement_b TEXT NULL,
  option_label VARCHAR(255) NULL,
  created_at DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
  updated_at DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6) ON UPDATE CURRENT_TIMESTAMP(6),
  UNIQUE KEY survey_answers_session_question (session_id, question_id),
  CONSTRAINT survey_answers_session_fk FOREIGN KEY (session_id) REFERENCES survey_sessions (id),
  CONSTRAINT survey_answers_question_fk FOREIGN KEY (question_id) REFERENCES survey_questions (id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS survey_submission_keys (
  id CHAR(36) PRIMARY KEY,
  public_link_id CHAR(36) NOT NULL,
  key_hash VARCHAR(128) NOT NULL,
  session_id CHAR(36) NOT NULL,
  created_at DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
  UNIQUE KEY survey_submission_keys_link_hash (public_link_id, key_hash),
  CONSTRAINT survey_submission_keys_link_fk FOREIGN KEY (public_link_id) REFERENCES public_survey_links (id),
  CONSTRAINT survey_submission_keys_session_fk FOREIGN KEY (session_id) REFERENCES survey_sessions (id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS culture_perception_results (
  id CHAR(36) PRIMARY KEY,
  session_id CHAR(36) NOT NULL,
  organization_id CHAR(36) NOT NULL,
  culture_version_id CHAR(36) NULL,
  processed_at DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
  notes TEXT NULL,
  UNIQUE KEY culture_perception_results_session (session_id),
  CONSTRAINT culture_results_session_org_fk FOREIGN KEY (session_id, organization_id) REFERENCES survey_sessions (id, organization_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS affinity_evaluations (
  id CHAR(36) PRIMARY KEY,
  application_id CHAR(36) NOT NULL,
  session_id CHAR(36) NULL,
  organization_id CHAR(36) NOT NULL,
  firebase_evaluation_id VARCHAR(128) NULL,
  status VARCHAR(16) NOT NULL DEFAULT 'in_progress',
  dimension_scores JSON NULL,
  completed_at DATETIME(6) NULL,
  created_at DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
  updated_at DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6) ON UPDATE CURRENT_TIMESTAMP(6),
  UNIQUE KEY affinity_evaluations_application (application_id),
  UNIQUE KEY affinity_evaluations_id_org (id, organization_id),
  UNIQUE KEY affinity_evaluations_firebase (firebase_evaluation_id),
  CONSTRAINT affinity_evaluations_app_fk FOREIGN KEY (application_id, organization_id) REFERENCES applications (id, organization_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS evaluation_reports (
  id CHAR(36) PRIMARY KEY,
  evaluation_id CHAR(36) NOT NULL,
  application_id CHAR(36) NOT NULL,
  organization_id CHAR(36) NOT NULL,
  status VARCHAR(32) NOT NULL DEFAULT 'pending',
  level VARCHAR(16) NULL,
  score INT NULL,
  confidence VARCHAR(16) NULL,
  summary TEXT NULL,
  alignments JSON NOT NULL,
  differences JSON NOT NULL,
  conversation_topics JSON NOT NULL,
  guidance TEXT NULL,
  data_gaps JSON NOT NULL,
  model VARCHAR(128) NULL,
  prompt_version VARCHAR(64) NULL,
  error_code VARCHAR(64) NULL,
  analyzed_at DATETIME(6) NULL,
  created_at DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
  updated_at DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6) ON UPDATE CURRENT_TIMESTAMP(6),
  UNIQUE KEY evaluation_reports_evaluation (evaluation_id),
  CONSTRAINT evaluation_reports_eval_fk FOREIGN KEY (evaluation_id, organization_id) REFERENCES affinity_evaluations (id, organization_id),
  CONSTRAINT evaluation_reports_app_fk FOREIGN KEY (application_id, organization_id) REFERENCES applications (id, organization_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS activation_invites (
  id CHAR(36) PRIMARY KEY,
  email VARCHAR(255) NOT NULL,
  organization_id CHAR(36) NOT NULL,
  vacancy_id CHAR(36) NULL,
  kind VARCHAR(16) NOT NULL,
  role VARCHAR(32) NULL,
  token_hash VARCHAR(128) NULL,
  pin_hash VARCHAR(128) NULL,
  pin_algorithm VARCHAR(16) NOT NULL DEFAULT 'fnv1a32',
  used TINYINT(1) NOT NULL DEFAULT 0,
  application_id CHAR(36) NULL,
  first_name VARCHAR(128) NULL,
  last_name VARCHAR(128) NULL,
  document_number VARCHAR(64) NULL,
  pin_expires_at DATETIME(6) NULL,
  token_expires_at DATETIME(6) NULL,
  expires_at DATETIME(6) NULL,
  created_at DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
  updated_at DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6) ON UPDATE CURRENT_TIMESTAMP(6),
  UNIQUE KEY activation_invites_token (token_hash),
  KEY activation_invites_email_idx (email),
  KEY activation_invites_org_idx (organization_id),
  CONSTRAINT activation_invites_org_fk FOREIGN KEY (organization_id) REFERENCES organizations (id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS firebase_id_map (
  collection VARCHAR(64) NOT NULL,
  firebase_id VARCHAR(128) NOT NULL,
  postgres_id CHAR(36) NOT NULL,
  created_at DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
  PRIMARY KEY (collection, firebase_id),
  UNIQUE KEY firebase_id_map_collection_pg (collection, postgres_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS activity_events (
  id CHAR(36) PRIMARY KEY,
  firebase_id VARCHAR(128) NULL,
  organization_id CHAR(36) NULL,
  actor_profile_id CHAR(36) NULL,
  kind VARCHAR(64) NOT NULL,
  entity_name VARCHAR(255) NOT NULL,
  status_label VARCHAR(64) NULL,
  context TEXT NULL,
  created_at DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
  UNIQUE KEY activity_events_firebase (firebase_id),
  KEY activity_events_org_created_idx (organization_id, created_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS audit_logs (
  id CHAR(36) PRIMARY KEY,
  actor_profile_id CHAR(36) NULL,
  organization_id CHAR(36) NULL,
  action VARCHAR(64) NOT NULL,
  entity VARCHAR(64) NOT NULL,
  entity_id CHAR(36) NULL,
  metadata JSON NOT NULL,
  created_at DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS deals (
  id CHAR(36) PRIMARY KEY,
  organization_id CHAR(36) NOT NULL,
  stage VARCHAR(32) NOT NULL,
  estimated_value DECIMAL(14,2) NULL,
  owner_name VARCHAR(255) NULL,
  next_action VARCHAR(255) NULL,
  probability DECIMAL(5,2) NULL,
  created_at DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
  updated_at DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6) ON UPDATE CURRENT_TIMESTAMP(6),
  CONSTRAINT deals_org_fk FOREIGN KEY (organization_id) REFERENCES organizations (id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS sales (
  id CHAR(36) PRIMARY KEY,
  organization_id CHAR(36) NOT NULL,
  amount DECIMAL(14,2) NOT NULL,
  product VARCHAR(255) NULL,
  recurring TINYINT(1) NOT NULL DEFAULT 0,
  sold_at DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
  created_at DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
  CONSTRAINT sales_org_fk FOREIGN KEY (organization_id) REFERENCES organizations (id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
