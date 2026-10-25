const crypto = require('crypto');
const {onCall, HttpsError} = require('firebase-functions/v2/https');
const {defineString} = require('firebase-functions/params');
const admin = require('firebase-admin');

const supabaseUrlParam = defineString('SUPABASE_URL', {default: ''});
const supabaseAnonParam = defineString('SUPABASE_ANON_KEY', {default: ''});

const SESSION_TTL_SECONDS = 60 * 60;

function env(name, fallback = '') {
  return String(process.env[name] || fallback || '').trim();
}

function supabaseUrl() {
  return env('SUPABASE_URL', supabaseUrlParam.value());
}

function supabaseAnonKey() {
  return env('SUPABASE_ANON_KEY', supabaseAnonParam.value());
}

function supabaseServiceKey() {
  return env('SUPABASE_SERVICE_ROLE_KEY');
}

function jwtSecret() {
  return env('SUPABASE_JWT_SECRET');
}

function base64Url(value) {
  return Buffer.from(value).toString('base64url');
}

function signSupabaseJwt({profileId, firebaseUid, email}) {
  const secret = jwtSecret();
  if (!secret) {
    throw new HttpsError('failed-precondition', 'Supabase JWT secret is not configured.');
  }
  const now = Math.floor(Date.now() / 1000);
  const payload = {
    aud: 'authenticated',
    exp: now + SESSION_TTL_SECONDS,
    iat: now,
    iss: `${supabaseUrl().replace(/\/$/, '')}/auth/v1`,
    sub: profileId,
    role: 'authenticated',
    firebase_uid: firebaseUid,
    email,
  };
  const header = base64Url(JSON.stringify({alg: 'HS256', typ: 'JWT'}));
  const body = base64Url(JSON.stringify(payload));
  const signature = crypto
    .createHmac('sha256', secret)
    .update(`${header}.${body}`)
    .digest('base64url');
  return {
    accessToken: `${header}.${body}.${signature}`,
    expiresAt: new Date((now + SESSION_TTL_SECONDS) * 1000).toISOString(),
    profileId,
  };
}

async function supabaseRest(path, {method = 'GET', body, prefer} = {}) {
  const url = supabaseUrl();
  const key = supabaseServiceKey();
  if (!url || !key) {
    throw new HttpsError('failed-precondition', 'Supabase service credentials are missing.');
  }
  const headers = {
    apikey: key,
    Authorization: `Bearer ${key}`,
    'Content-Type': 'application/json',
  };
  if (prefer) headers.Prefer = prefer;
  const response = await fetch(`${url.replace(/\/$/, '')}/rest/v1/${path}`, {
    method,
    headers,
    body: body == null ? undefined : JSON.stringify(body),
  });
  const text = await response.text();
  if (!response.ok) {
    throw new HttpsError(
      'internal',
      `supabase_rest_${response.status}`,
    );
  }
  if (!text) return null;
  try {
    return JSON.parse(text);
  } catch (_) {
    return text;
  }
}

async function upsertProfile({uid, email, displayName, firestoreUser}) {
  const normalized = String(email || '').trim().toLowerCase();
  if (!normalized.includes('@')) {
    throw new HttpsError('failed-precondition', 'Authenticated email is required.');
  }
  const payload = {
    firebase_uid: uid,
    email: normalized,
    display_name: displayName || firestoreUser?.displayName || null,
    is_active: true,
    is_superadmin: firestoreUser?.role === 'superadmin',
    must_change_password: firestoreUser?.mustChangePassword === true,
    must_review_company_dna: firestoreUser?.mustReviewCompanyDna === true,
    document_number: firestoreUser?.documentNumber || null,
  };
  const rows = await supabaseRest(
    'profiles?on_conflict=email',
    {
      method: 'POST',
      prefer: 'return=representation,resolution=merge-duplicates',
      body: payload,
    },
  );
  const profile = Array.isArray(rows) ? rows[0] : rows;
  if (!profile?.id) {
    throw new HttpsError('internal', 'Could not upsert the Supabase profile.');
  }
  if (profile.firebase_uid !== uid) {
    await supabaseRest(`profiles?id=eq.${profile.id}`, {
      method: 'PATCH',
      prefer: 'return=representation',
      body: {firebase_uid: uid},
    });
  }
  return profile;
}

async function linkRespondent(uid, tokenHash) {
  if (!tokenHash) return;
  const url = supabaseUrl();
  const key = supabaseServiceKey();
  if (!url || !key) return;
  await fetch(`${url.replace(/\/$/, '')}/rest/v1/rpc/link_respondent_profile`, {
    method: 'POST',
    headers: {
      apikey: key,
      Authorization: `Bearer ${key}`,
      'Content-Type': 'application/json',
    },
    body: JSON.stringify({
      p_firebase_uid: uid,
      p_token_hash: tokenHash,
    }),
  });
}

exports.signSupabaseJwt = signSupabaseJwt;
exports.upsertProfile = upsertProfile;
exports.linkRespondent = linkRespondent;

exports.getSupabasePublicConfig = onCall(
  {
    region: 'us-central1',
    cors: true,
    invoker: 'public',
  },
  async () => {
    const url = supabaseUrl();
    const anonKey = supabaseAnonKey();
    if (!url || !anonKey || anonKey.includes('service_role') || anonKey.startsWith('sb_secret_')) {
      throw new HttpsError('failed-precondition', 'Supabase public config is not available.');
    }
    return {url, anonKey};
  },
);

exports.mintSupabaseSession = onCall(
  {
    region: 'us-central1',
    cors: true,
    timeoutSeconds: 30,
  },
  async (request) => {
    if (!request.auth) {
      throw new HttpsError('unauthenticated', 'Sign in required.');
    }
    const uid = request.auth.uid;
    const email = request.auth.token.email;
    const displayName = request.auth.token.name;
    const userDoc = await admin.firestore().collection('users').doc(uid).get();
    const profile = await upsertProfile({
      uid,
      email,
      displayName,
      firestoreUser: userDoc.data() || {},
    });
    return signSupabaseJwt({
      profileId: profile.id,
      firebaseUid: uid,
      email: profile.email || email,
    });
  },
);
