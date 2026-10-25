import { readFileSync, readdirSync } from 'node:fs';
import { dirname, resolve } from 'node:path';
import { fileURLToPath } from 'node:url';

const root = resolve(dirname(fileURLToPath(import.meta.url)), '..', '..');
const migrationsDir = resolve(root, 'supabase/migrations');
const files = {
  preamble: resolve(root, 'supabase/tests/preamble.sql'),
  seed: resolve(root, 'supabase/seed.sql'),
  tests: resolve(root, 'supabase/tests/phase_a_security.sql'),
  writes: resolve(root, 'supabase/tests/phase_e_writes.sql'),
  surveys: resolve(root, 'supabase/tests/phase_f_surveys.sql'),
  culture: resolve(root, 'supabase/tests/phase_g_culture_survey.sql'),
};

async function loadPglite() {
  const { PGlite } = await import('@electric-sql/pglite');
  const candidates = [
    '@electric-sql/pglite/pgcrypto',
    '@electric-sql/pglite/contrib/pgcrypto',
  ];
  for (const id of candidates) {
    try {
      const mod = await import(id);
      return new PGlite({ extensions: { pgcrypto: mod.pgcrypto ?? mod.default } });
    } catch {
      // Try the next export path.
    }
  }
  return new PGlite();
}

async function exec(db, label, sql) {
  try {
    await db.exec(sql);
    console.log(`ok  ${label}`);
  } catch (error) {
    console.error(`FAIL ${label}`);
    console.error(error.message);
    process.exitCode = 1;
    throw error;
  }
}

const db = await loadPglite();
await exec(db, 'preamble', readFileSync(files.preamble, 'utf8'));
await exec(db, 'create extension pgcrypto', `
  create schema if not exists extensions;
  do $$
  begin
    begin
      execute 'create extension if not exists pgcrypto with schema extensions';
    exception
      when others then
        begin
          execute 'create extension if not exists pgcrypto';
        exception
          when others then
            null;
        end;
    end;
  end
  $$;
`);
for (const name of readdirSync(migrationsDir).filter((item) => item.endsWith('.sql')).sort()) {
  await exec(db, name, readFileSync(resolve(migrationsDir, name), 'utf8'));
}
await exec(db, 'seed first pass', readFileSync(files.seed, 'utf8'));
await exec(db, 'seed second pass', readFileSync(files.seed, 'utf8'));
await exec(db, 'phase A security tests', readFileSync(files.tests, 'utf8'));
await exec(db, 'phase E write tests', readFileSync(files.writes, 'utf8'));
await exec(db, 'phase F survey bank tests', readFileSync(files.surveys, 'utf8'));
await exec(db, 'phase G culture survey tests', readFileSync(files.culture, 'utf8'));

if (process.exitCode) {
  process.exit(process.exitCode);
}
console.log('ok  all disposable Postgres checks passed');
await db.close?.();
