# Diagnóstico TaleX → PostgreSQL / Supabase

Fecha: 2026-10-24. Fuente: código del repositorio, no una copia de producción.
Actualizado tras aplicar el esquema en el proyecto remoto
`inyjehqhrrneiufitwch`. El esquema existe en git y en esa base; **no**
sustituye a Firestore como persistencia de la app.

## Arquitectura actual

- Cliente: Flutter web, Clean Architecture por feature, BLoC, GetIt, `Either` para errores.
- Persistencia viva: Cloud Firestore (`nam5`) + Firebase Auth + Storage + Cloud Functions (Node 20, `us-central1`).
- Correo: SMTP en Functions. Análisis de afinidad: Gemini en Functions. Chat TaleXito: Functions.
- Despliegue web: GitHub Actions → FTP a Colombia Hosting (`platform.talex.com.co`).
- Destino relacional: esquema en `supabase/migrations/`. El cliente Flutter
  puede abrir un cliente anónimo opcional; los data sources siguen en Firebase.

La app **no se puede apuntar a Supabase de un golpe**. Los data sources
(`FirebaseTalentDataSource`, `FirebaseAuthRemoteDataSource`,
`FirebaseAdminDataSource`) y las rules de Firestore son la fuente de verdad.

## Modelo de datos actual (Firestore)

| Colección | Qué representa | Relación real |
|---|---|---|
| `users` | Cuenta + rol + `companyId` | Un usuario, una empresa. El rol vive en el documento. |
| `companies` | Empresa + ADN declarado (valores, cultura, destacados) | Cultura y ficha en el mismo documento. |
| `vacancies` | Vacante | `companyId`. |
| `candidates` | Persona **y** postulación a la vez | `companyId` + `vacancyId` + email. |
| `evaluations` | Respuestas 1–5 + `dimensionScores` | id = `candidateId`. |
| `affinity_analyses` | Informe Gemini | id = `candidateId`. Solo lo escribe el backend. |
| `assessment_questions` | Banco global de preguntas | Lo edita el superadmin. |
| `activation_invites` | Invitación, id = email | Una invitación activa por correo. |
| `dna_catalog` | Catálogo de etiquetas | Global + extras de empresa. |
| `survey_result_requests` | Pedido de resultados | id = `candidateId`. |
| `config/superadmin` | Lista de emails superadmin | |
| `activity_events`, `admin_audit_logs` | Actividad superadmin | |
| `processes`, `people`, `deals`, `sales` | Restos del panel comercial | Poco acoplados al flujo de afinidad. |

Auth: Firebase Auth. El candidato entra con custom token al abrir el link. El personal de empresa entra con email/contraseña o Google.

## Problemas encontrados (modelo Firestore)

1. **Candidato = postulación.** El mismo correo en otra vacante crea otro documento. No hay entidad de persona reutilizable.
2. **Un usuario, una empresa.** `users.companyId` impide membresías múltiples.
3. **Cultura sin historial.** Editar el perfil de empresa sobrescribe valores y cultura.
4. **Respuestas sin versión.** `evaluations.answers` es un mapa. Si cambia el banco de preguntas, el histórico no sabe qué versión se respondió.
5. **Invitación indexada por email.** Un correo no puede tener dos invitaciones vivas.
6. **Autorización en el cliente.** Firestore rules son el backend de permisos.
7. **ADN y encuesta se mezclan en el producto.** No existe encuesta pública de percepción en producción.
8. **IDs de Firestore** no son UUID. Hay que mapearlos.

## Modelo propuesto (ya corregido en el SQL de git)

- `profiles` + `memberships` + `organizations`
- `persons` + `applications`
- `organization_culture_versions`
- Motor `survey_*` para afinidad y percepción
- `affinity_evaluations` + `evaluation_reports` (Gemini no se toca)
- Encuesta pública solo por RPC
- FKs compuestas para impedir cruces entre empresas
- Instantáneas de enunciado en `survey_answers`

## Qué no se hace en esta fase

- No se migra Firebase Auth.
- No se cambian los data sources de Flutter.
- No se copian datos de producción.
- No se inventa el cuestionario ni el algoritmo de percepción cultural.
- No se pone la publishable key en el código.
- No se aplica el SQL al proyecto remoto.
- No se añade la Function de intercambio de JWT hasta que se autorice.

## Riesgos que siguen abiertos

- No hay ensayo de `pg_dump` / restore contra un proyecto alojado.
- El intercambio Firebase → JWT de Supabase está diseñado, no implementado.
- `PinHasher` de Firebase sigue siendo FNV-1a 32-bit; el corte a `bfcrypt` no está aprobado.
- Firestore puede haber sobrescrito enunciados antiguos: la carga solo puede congelar el texto actual.

Hace falta confirmación explícita antes de copiar datos, de aplicar el SQL
remoto o de apagar Firestore.
