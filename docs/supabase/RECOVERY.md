# Respaldo, carga y reversión

Carga inicial de Firestore → Postgres ejecutada el 2026-10-24 con
`supabase/tests/import_firestore.mjs`. Firestore no se modificó. Un
`pg_dump` suelto no basta como única estrategia de recuperación.

## 1. Respaldo de origen (Firestore + Auth + Storage)

Antes de cualquier copia:

1. Exportar Firestore a un bucket de GCS con
   `gcloud firestore export gs://<bucket>/talex-export-<fecha>`.
2. Guardar el nombre del export y el `operationId`.
3. Contar documentos por colección (`users`, `companies`, `vacancies`,
   `candidates`, `evaluations`, `affinity_analyses`, `assessment_questions`,
   `activation_invites`, `activity_events`, `admin_audit_logs`,
   `dna_catalog`, `survey_result_requests`).
4. Exportar la lista de uids de Firebase Auth (`auth:export`) sin contraseñas
   en texto claro.
5. No se copia Storage en esta fase. Los `logo_url` se conservan como URL.

Verificar el export restaurándolo en un proyecto Firebase desechable o
leyendo una muestra de cada colección. Si el export no se puede leer, no se
sigue.

## 2. Respaldo de destino (Postgres)

1. Proyecto Supabase **distinto** del que use datos reales, o una base local
   (`supabase/config.toml`).
2. `pg_dump --format=custom --no-owner --file=backup-pre-load.dump` del
   esquema ya migrado y vacío (o con seed).
3. Guardar el hash del dump y la revisión git de
   `supabase/migrations/20261024180000_init_talex.sql`.

Limitación: el plan Free de Supabase no es alta disponibilidad. El dump
vive fuera de ese proyecto (disco del operador o bucket privado).

## 3. Orden de carga

1. `legacy_role_map` / `legacy_company_status_map` (ya van en la migración).
2. `profiles` (`firebase_uid` = uid de Auth, nunca el correo como llave).
3. `organizations`.
4. `memberships` (usando `legacy_role` para `ceo`/`hr`).
5. `organization_culture_versions` v1 `is_current`.
6. `dna_catalog_entries`.
7. `vacancies`.
8. `persons` (una fila por correo normalizado). Conflictos de
   `document_number` se registran, no se fusionan.
9. `applications` (`firebase_candidate_id` = id de `candidates`).
10. `application_status_events` (estado actual como primer evento).
11. `survey_templates` / versiones / preguntas (banco de afinidad).
12. `survey_sessions` + `survey_answers` + `affinity_evaluations`.
13. `evaluation_reports`.
14. `activation_invites` (`pin_algorithm = fnv1a32` para hashes actuales).
15. `activity_events` y `audit_logs` (sin secretos).
16. `firebase_id_map` en cada paso.

Cada lote escribe `firebase_id_map(collection, firebase_id, postgres_id)`
antes de pasar al siguiente. Si un lote falla, se detiene la carga.

## 4. Rechazos y duplicados

| Conflicto | Tratamiento |
|---|---|
| Mismo correo, distinta capitalización | Un `persons` / `profiles`. El correo queda en minúsculas. |
| Mismo `document_number`, distinto correo | Dos personas. Fila en el registro de importación `document_conflict`. |
| Mismo correo, distinto documento | No fusionar. Rechazar la segunda persona y anotar ambos documentos. |
| `candidates` sin `companyId` o `vacancyId` válido | Rechazar la postulación. |
| `evaluations` sin candidato | Rechazar. |
| Empresa con status desconocido | Rechazar. No inventar `active`. |
| Rol desconocido | Rechazar la membresía. El perfil puede crearse sin membership. |

Los rechazos se guardan en un archivo de importación (JSONL) con el id de
Firestore, la tabla destino y el motivo. No se silencian.

## 5. Validación mínima

1. Conteos: `companies` = `organizations`, `vacancies`, `candidates` =
   `applications`.
2. Toda application tiene person y vacancy de la misma organization.
3. Toda evaluation `completed=true` tiene session `completed` y snapshots
   de enunciado.
4. Ningún `person` es visible vía RLS a una empresa sin application propia.
5. `firebase_id_map` cubre cada documento aceptado.
6. Los informes conservan `confidence`, `data_gaps`, `model` y
   `prompt_version`.

## 6. Reversión

La reversión **no borra** tablas que ya tengan filas nuevas de producto.

1. Si la carga no llegó a usarse por la app (solo el job de importación
   escribió): restaurar `backup-pre-load.dump` en el entorno desechable.
2. Si alguna fila nació después de la carga: no ejecutar `DROP` ni
   `TRUNCATE`. Marcar el lote con `import_batch` (pendiente de añadir en
   fase D) y borrar solo ese lote, con autorización expresa.
3. Firestore, Auth, Storage y Functions no se tocan. Siguen siendo la
   fuente operativa.

Este procedimiento de restore con dump se probará en la base desechable
cuando se autorice un ensayo de carga. Las pruebas de fase A/B no copian
datos de producción y por eso no ejecutan `pg_dump` contra el proyecto
remoto.
