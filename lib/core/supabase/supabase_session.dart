import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:talex_platform/core/supabase/supabase_config.dart';

/// Holds the server-minted Supabase JWT. The publishable key never becomes
/// a user session; PostgREST reads this token via [current].
class SupabaseAccessToken {
  SupabaseAccessToken({
    FirebaseFunctions? functions,
    DateTime Function()? clock,
  }) : _functions = functions,
       _clock = clock ?? DateTime.now;

  static final instance = SupabaseAccessToken();

  final FirebaseFunctions? _functions;
  final DateTime Function() _clock;
  String? _token;
  DateTime? _expiresAt;

  FirebaseFunctions get _callable =>
      _functions ?? FirebaseFunctions.instanceFor(region: 'us-central1');

  Future<String?> current() async {
    final token = _token;
    final expiresAt = _expiresAt;
    if (token != null &&
        expiresAt != null &&
        expiresAt.isAfter(_clock().add(const Duration(minutes: 2)))) {
      return token;
    }
    if (FirebaseAuth.instance.currentUser == null) return token;
    try {
      await refresh();
    } on Object {
      return token;
    }
    return _token;
  }

  Future<void> refresh() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      clear();
      return;
    }
    final result = await _callable.httpsCallable('mintSupabaseSession').call();
    final data = Map<String, dynamic>.from(result.data as Map);
    final token = data['accessToken'] as String?;
    if (token == null || token.isEmpty) {
      throw StateError('mintSupabaseSession returned an empty token');
    }
    _token = token;
    _expiresAt = DateTime.tryParse('${data['expiresAt'] ?? ''}');
  }

  void clear() {
    _token = null;
    _expiresAt = null;
  }

  bool get hasToken => _token != null;
}

Future<SupabaseConfig> resolveSupabaseConfig({
  SupabaseConfig config = SupabaseConfig.fromEnvironment,
  FirebaseFunctions? functions,
}) async {
  if (config.isConfigured) return config;
  try {
    final result = await (functions ??
            FirebaseFunctions.instanceFor(region: 'us-central1'))
        .httpsCallable('getSupabasePublicConfig')
        .call();
    final data = Map<String, dynamic>.from(result.data as Map);
    final resolved = SupabaseConfig(
      url: '${data['url'] ?? ''}',
      anonKey: '${data['anonKey'] ?? ''}',
    );
    return resolved.isConfigured ? resolved : config;
  } on Object {
    return config;
  }
}
