# Supabase para TaleX

El esquema está en `supabase/migrations/`. **Postgres es la base operativa**
de empresas, vacantes, postulaciones, respuestas e informes. Firebase Auth,
Storage, SMTP, Gemini y el hosting en Colombia Hosting no cambian.

El proyecto remoto es `inyjehqhrrneiufitwch`. No vuelvas a ejecutar
`db push` a ciegas: las siguientes migraciones deben ser archivos nuevos.

## Qué usa la app

- Login: Firebase Auth.
- Datos: Supabase vía JWT emitido por `mintSupabaseSession`.
- Archivos: Firebase Storage.
- Correos y Gemini: Cloud Functions.
- Preguntas, respuestas, cultura de empresa e informe Gemini: Postgres.
  La cultura de la empresa sale de las respuestas de su encuesta de
  valores (varias personas se guardan y se agregan). Gemini compara al
  candidato contra esa cultura. El formulario de cultura se puede subir
  cuando esté listo.

Si Supabase no arranca, GetIt vuelve a los data sources de Firestore para
no tumbar Auth.

## Arranque local

```powershell
flutter run --dart-define=SUPABASE_URL=https://xxxx.supabase.co --dart-define=SUPABASE_ANON_KEY=sb_publishable_...
```

En producción, el workflow de Colombia Hosting pasa esas dos variables
desde GitHub Secrets. Si faltan, la app pide `getSupabasePublicConfig`.

## Pruebas del esquema

```powershell
cd supabase/tests
npm install
npm test
```

Aplica todas las migraciones, corre `seed.sql` dos veces, `phase_a_security.sql`
`phase_e_writes.sql` y `phase_f_surveys.sql` en Postgres desechable.

Para cargar la encuesta de percepción cultural, edita
`supabase/surveys/culture-perception.example.json` y corre:

```powershell
node supabase/tests/upload_survey_bank.mjs culture-perception supabase/surveys/culture-perception.example.json
```

## Credenciales

- **Publishable / anon key:** cliente y `--dart-define`. Nunca en git.
- **Service role y JWT secret:** solo servidor. `SupabaseConfig` rechaza
  la service role en Flutter.
- Desarrollo y producción deben ser proyectos distintos cuando existan
  datos reales.

## SQL

- Editor: *SQL Editor* del dashboard.
- CLI: `supabase db query --linked --file supabase/migrations/....sql`
- No concedáis tablas a `anon`. No pongáis `USING (true)` en tablas privadas.

## Colaboración

1. Las migraciones viven en git.
2. `supabase db diff` / `db pull` solo para revisar.
3. El service role no se pega en el chat ni en un `.env` commiteado.
