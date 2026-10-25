# Diccionario de datos TaleX (PostgreSQL)

Todas las tablas de negocio tienen RLS forzado. El rol `anon` no tiene
privilegios DML sobre tablas. Las escrituras autenticadas no están
concedidas: el service role las hace en servidor hasta que exista un JWT
con `firebase_uid`.

## Identidad y tenancy

| Tabla | Columna | Tipo | Relación / nota |
|---|---|---|---|
| profiles | id | uuid PK | Usuario de plataforma. |
| profiles | firebase_uid | text unique | Compatibilidad con Firebase Auth. No es el correo. |
| profiles | email | text unique | Siempre `lower(trim(email))`. Unicidad de contacto, no de identidad. |
| profiles | is_superadmin | boolean | Rol global. El cliente no puede escribirlo. |
| organizations | status | text | `active`, `onboarding`, `inactive`, `atRisk`, `suspended`. |
| organizations | plan, contract_value, mrr, renewal_at, commercial_stage, last_activity_at, archived_at | varios | Campos que ya consume el panel admin. |
| memberships | role | text | `company_admin`, `company_lead`, `people_ops`, `recruiter`, `hiring_manager`. |
| memberships | legacy_role | text | Valor original de Firestore (`ceo`, `hr`, …). |
| legacy_role_map | | | Correspondencia documentada y reversible. |
| legacy_company_status_map | | | Correspondencia de estados. |

## Cultura declarada

| Tabla | Uso |
|---|---|
| organization_culture_versions | Instantánea inmutable salvo `is_current`. |
| dna_catalog_entries | Catálogo. `organization_id` nulo = semilla global. |

La encuesta pública no escribe estas tablas.

## Vacantes y postulaciones

| Tabla | Uso |
|---|---|
| vacancies | Vacante. Unique `(id, organization_id)` para FKs compuestas. |
| persons | Identidad por correo normalizado. `document_number` **no** es único. |
| persons | `linked_profile_id` opcional si la misma persona es staff. No se rellena solo. |
| applications | Postulación. FK `(vacancy_id, organization_id)`. Incluye `assessment_kind` y `vacancy_name`. |
| application_status_events | Historial de `process_status` con la misma empresa. |

Una persona no puede tener dos postulaciones a la misma vacante de la misma
empresa (`unique (organization_id, vacancy_id, person_id)`).

## Motor de encuestas

| Tabla / vista | Uso |
|---|---|
| survey_templates | `affinity` o `culture_perception`. |
| survey_versions | Inmutable en `published`. Solo puede pasar a `retired`. |
| survey_questions | Incluye `dimension_a` / `dimension_b`. Superadmin lee y escribe vía RPC. |
| survey_published_questions | Vista sin dimensiones, solo afinidad publicada. |
| survey_scoring_questions | Vista con frentes y dimensiones. Gemini y el editor leen de aquí. |
| replace_survey_bank / upsert_survey_question | Carga o edita `affinity-core` y `culture-perception`. |
| survey_sessions | Afinidad: postulación y empresa, sin enlace público. Percepción: enlace y empresa, sin postulación. |
| survey_answers | Instantánea de código, enunciado y etiqueta. |
| survey_submission_keys | Idempotencia de la RPC pública. |

## Percepción pública

| Tabla / función | Uso |
|---|---|
| public_survey_links | Token de ≥32 bytes aleatorios, guardado como SHA-256. `max_responses` / `response_count`. |
| culture_perception_results | Participación ligada a la cultura vigente. Sin puntajes inventados. |
| open_culture_survey(token) | RPC anónima: preguntas, sin `organizationId`. |
| submit_culture_survey(token, answers, locale, idempotency_key) | RPC anónima: valida, guarda y no crea sesión si falta cultura vigente. |
| create_public_survey_link(...) | Solo service role / superusuario. |

## Evaluaciones

| Tabla | Uso |
|---|---|
| affinity_evaluations | Cierre de afinidad + `dimension_scores`. El algoritmo sigue en Functions. |
| evaluation_reports | Informe Gemini, con `confidence`, `data_gaps`, `model` y `prompt_version`. |

## Operación

| Tabla | Uso |
|---|---|
| activation_invites | Invitaciones. `vacancy_id`, nombre, documento, vencimientos. `pin_hash` / `token_hash` no se conceden a miembros. |
| activation_invites | `pin_algorithm`: `fnv1a32` (actual en Firebase) o `bfcrypt` (nuevo en Postgres). |
| firebase_id_map | `collection` + `firebase_id` → `postgres_id`, unique también al revés. |
| activity_events | Actividad del panel admin. |
| audit_logs | El check recorre claves anidadas y no distingue mayúsculas. |
