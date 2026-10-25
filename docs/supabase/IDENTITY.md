# Identidad Firebase Auth → Supabase

Firebase Auth sigue siendo el proveedor de autenticación. El esquema de
Postgres guarda `profiles.firebase_uid` y las políticas RLS leen el claim
`firebase_uid` de un JWT de Supabase. **No se acepta `sub` como uid de
Firebase.**

## Flujo en la app

1. El usuario inicia sesión con Firebase Auth.
2. Flutter llama a la Cloud Function `mintSupabaseSession` (`us-central1`).
3. La Function verifica el ID token con Firebase Admin, crea o actualiza
   `profiles` con el **service role solo en el servidor** y firma un JWT
   con el secreto JWT del proyecto.
4. Claims del JWT:
   - `role = authenticated`
   - `firebase_uid = decoded.uid`
   - `sub = profiles.id` (UUID de Postgres)
5. El cliente inyecta ese token con `Supabase.initialize(accessToken: ...)`.
   No usa `setSession` de GoTrue ni guarda la service role.

`getSupabasePublicConfig` solo devuelve URL y anon key. Si el build de
Colombia Hosting no trae `--dart-define`, la app pide esa Function y
arranca el cliente público igual.

## Secretos

En Functions, nunca en Flutter ni en el bundle web:

- `SUPABASE_JWT_SECRET`
- `SUPABASE_SERVICE_ROLE_KEY`

En el cliente o en GitHub Actions, solo:

- `SUPABASE_URL`
- `SUPABASE_ANON_KEY`

```powershell
firebase functions:secrets:set SUPABASE_JWT_SECRET
firebase functions:secrets:set SUPABASE_SERVICE_ROLE_KEY
firebase deploy --only functions:mintSupabaseSession,functions:getSupabasePublicConfig
```

## Qué hace el esquema

- `public.jwt_firebase_uid()` solo lee `auth.jwt() ->> 'firebase_uid'`.
- `public.current_session_profile()` hidrata rol, empresa y bandera de
  encuesta.
- `profiles.is_superadmin` no se puede autoasignar con el rol `authenticated`.
- El cliente Flutter rechaza `service_role` y `sb_secret_*`.
