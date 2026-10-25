const test = require('node:test');
const assert = require('node:assert/strict');

process.env.SUPABASE_URL = 'https://example.supabase.co';
process.env.SUPABASE_JWT_SECRET = 'test-jwt-secret';

const {signSupabaseJwt} = require('../supabase_session');

test('minted JWT carries firebase_uid and the Postgres profile id as sub', () => {
  const session = signSupabaseJwt({
    profileId: '11111111-2222-3333-4444-555555555555',
    firebaseUid: 'firebase-uid-1',
    email: 'staff@example.com',
  });
  const payload = JSON.parse(
    Buffer.from(session.accessToken.split('.')[1], 'base64url').toString('utf8'),
  );
  assert.equal(payload.role, 'authenticated');
  assert.equal(payload.firebase_uid, 'firebase-uid-1');
  assert.equal(payload.sub, '11111111-2222-3333-4444-555555555555');
  assert.notEqual(payload.sub, payload.firebase_uid);
  assert.equal(payload.email, 'staff@example.com');
  assert.ok(session.expiresAt);
});
