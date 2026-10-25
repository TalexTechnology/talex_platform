# Mapeo Firestore → PostgreSQL

Carga inicial ejecutada el 2026-10-24 sobre el proyecto `inyjehqhrrneiufitwch`.
La app ya lee y escribe el dominio de talento y admin en Postgres. Firestore
queda para Auth, Storage, SMTP y recuperación de contraseña. El análisis
de afinidad lee y escribe solo en Postgres. Conteos aceptados:
1 empresa, 1 vacante, 3 postulaciones, 48 preguntas, 1 evaluación, 1 informe.

| Origen Firestore | Destino Postgres | Regla |
|---|---|---|
| `users/{uid}` | `profiles` + `memberships` | `firebase_uid = uid`. Superadmin → `profiles.is_superadmin`. Staff → membership. Respondent no crea membership. |
| `users.role` | `legacy_role_map` | `ceo` → membership `company_lead` con `legacy_role=ceo`. `hr` → `people_ops` / `hr`. `user` → perfil sin membership. |
| `companies/{id}` | `organizations` | `firebase_id = id`. Status según `legacy_company_status_map` (`onboarding`, `atRisk` se conservan). |
| `companies` valores/cultura | `organization_culture_versions` v1 `is_current` | Snapshot del documento actual (`valuesList` / `cultureList` / `standoutList`). |
| `companies.plan`, `mrr`, `contractValue`, `commercialStage`, `lastActivityAt`, `archivedAt` | mismas columnas snake_case | Solo si el documento las trae. |
| `dna_catalog/{id}` | `dna_catalog_entries` | `source` y `organization_id` si existe. |
| `vacancies/{id}` | `vacancies` | `firebase_id = id`. |
| `candidates/{id}` | `persons` + `applications` | Persona por correo normalizado. Postulación con `firebase_candidate_id = id`, `assessment_kind`, `vacancy_name`. |
| `evaluations/{candidateId}` | `survey_sessions` + `survey_answers` + `affinity_evaluations` | Gemini lee estas respuestas en Postgres. |
| `affinity_analyses/{id}` | `evaluation_reports` | Gemini escribe el informe aquí. Conserva `confidence`, `dataGaps`, `model`, `promptVersion`. |
| `assessment_questions/{code}` | `survey_questions` + `survey_options` | Plantilla `affinity-core`. Gemini las lee en `survey_scoring_questions`. La encuesta `culture-perception` queda estructurada y vacía para cargar preguntas. |
| `activation_invites/{email}` | `activation_invites` | El id deja de ser el email. `pin_algorithm=fnv1a32`. Conserva `vacancyId`, nombres, documento, vencimientos. |
| `survey_result_requests/{id}` | `applications.result_requested` | |
| `config/superadmin` | `profiles.is_superadmin` | Lista de emails, aplicada por el job de importación, no por RLS. |
| `admin_audit_logs` | `audit_logs` | Sin secretos. |
| `activity_events` | `activity_events` | `kind`, `entityName`, `companyId`, `context`. |
| `processes`, `people`, `deals`, `sales` | Fuera de alcance | No se migran en esta fase. El MRR y la etapa comercial que ya viven en `companies` sí se copian. |

## Roles (reversible)

| Firestore | Membership | Superadmin | Notas |
|---|---|---|---|
| `superadmin` | no | sí | |
| `respondent` | no | no | |
| `user` | no | no | Estado previo a la invitación. |
| `company_admin` | `company_admin` | no | |
| `company_lead` | `company_lead` | no | |
| `ceo` | `company_lead` | no | `legacy_role=ceo` |
| `people_ops` | `people_ops` | no | |
| `hr` | `people_ops` | no | `legacy_role=hr` |
| `recruiter` | `recruiter` | no | |
| `hiring_manager` | `hiring_manager` | no | |

No se cambian permisos por el alias: el import solo traduce el nombre
al check de `memberships.role`.

## Validación mínima después de una carga real (pendiente)

1. Conteos: companies = organizations, vacancies, candidates = applications.
2. Toda application tiene person y vacancy de la misma organization.
3. Toda evaluation con `completed=true` tiene session completed y snapshots.
4. Ningún person es visible vía RLS a una empresa sin application propia.
