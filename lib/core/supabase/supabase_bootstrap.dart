import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:talex_platform/core/supabase/supabase_config.dart';
import 'package:talex_platform/core/supabase/supabase_session.dart';

typedef SupabaseInitializer =
    Future<void> Function({
      required String url,
      required String publishableKey,
      Future<String?> Function()? accessToken,
    });

Future<void> _defaultInitializer({
  required String url,
  required String publishableKey,
  Future<String?> Function()? accessToken,
}) {
  return Supabase.initialize(
    url: url,
    publishableKey: publishableKey,
    accessToken: accessToken,
  );
}

/// Arranca el cliente público si hay URL y anon key.
///
/// Firebase Auth sigue siendo el login. El JWT de Supabase lo emite
/// `mintSupabaseSession` y se inyecta con [accessToken].
Future<bool> bootstrapSupabase([
  SupabaseConfig config = SupabaseConfig.fromEnvironment,
  SupabaseInitializer initialize = _defaultInitializer,
  Future<String?> Function()? accessToken,
]) async {
  if (!config.isConfigured) return false;
  try {
    await initialize(
      url: config.url,
      publishableKey: config.anonKey,
      accessToken: accessToken ?? SupabaseAccessToken.instance.current,
    );
    return true;
  } on Object catch (error, stackTrace) {
    FlutterError.reportError(
      FlutterErrorDetails(
        exception: error,
        stack: stackTrace,
        library: 'talex supabase bootstrap',
        context: ErrorDescription(
          'Supabase is optional. Firebase will continue.',
        ),
      ),
    );
    return false;
  }
}

bool get isSupabaseReady {
  try {
    return Supabase.instance.isInitialized;
  } on Object {
    return false;
  }
}
