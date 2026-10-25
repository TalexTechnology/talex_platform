import 'dart:convert';

/// Credenciales públicas de Supabase inyectadas en compile-time.
///
/// No pongas la publishable key en el código. Arranca con:
/// `--dart-define=SUPABASE_URL=... --dart-define=SUPABASE_ANON_KEY=...`
///
/// La service role y las claves `sb_secret_` nunca son válidas en Flutter.
class SupabaseConfig {
  const SupabaseConfig({required this.url, required this.anonKey});

  final String url;
  final String anonKey;

  static const fromEnvironment = SupabaseConfig(
    url: String.fromEnvironment('SUPABASE_URL'),
    anonKey: String.fromEnvironment('SUPABASE_ANON_KEY'),
  );

  static final _legacyJwt = RegExp(r'^[A-Za-z0-9_-]+\.[A-Za-z0-9_-]+\.[A-Za-z0-9_-]+$');

  bool get isConfigured => _isAllowedUrl(url) && isPublicAnonKey(anonKey);

  static bool _isAllowedUrl(String value) {
    if (value.startsWith('https://') && value.contains('supabase.co')) {
      return true;
    }
    return value.startsWith('http://127.0.0.1:') ||
        value.startsWith('http://localhost:');
  }

  static bool isPublicAnonKey(String key) {
    final value = key.trim();
    if (value.isEmpty || value.contains(' ')) return false;
    final lower = value.toLowerCase();
    if (lower.contains('service_role') || lower.startsWith('sb_secret_')) {
      return false;
    }
    if (lower.startsWith('sb_publishable_')) return true;
    return _legacyJwt.hasMatch(value) && _legacyRole(value) == 'anon';
  }

  static String? _legacyRole(String jwt) {
    try {
      final payload = jwt.split('.')[1];
      final normalized = base64Url.normalize(payload);
      final decoded = jsonDecode(utf8.decode(base64Url.decode(normalized)));
      if (decoded is! Map) return null;
      final role = decoded['role'];
      return role is String ? role : null;
    } on Object {
      return null;
    }
  }
}
