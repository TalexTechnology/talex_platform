import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:talex_platform/core/supabase/supabase_bootstrap.dart';
import 'package:talex_platform/core/supabase/supabase_config.dart';

String _legacyJwt(String role) {
  String encode(Map<String, Object> payload) =>
      base64Url.encode(utf8.encode(jsonEncode(payload))).replaceAll('=', '');
  return '${encode({'alg': 'HS256'})}.${encode({'role': role})}.signature';
}

void main() {
  test('rejects an empty or local misconfiguration', () {
    expect(const SupabaseConfig(url: '', anonKey: 'x').isConfigured, isFalse);
    expect(
      const SupabaseConfig(
        url: 'https://demo.supabase.co',
        anonKey: '',
      ).isConfigured,
      isFalse,
    );
  });

  test('accepts a hosted project with a publishable key', () {
    expect(
      const SupabaseConfig(
        url: 'https://inyjehqhrrneiufitwch.supabase.co',
        anonKey: 'sb_publishable_test',
      ).isConfigured,
      isTrue,
    );
  });

  test('accepts local Supabase with a publishable key', () {
    expect(
      const SupabaseConfig(
        url: 'http://127.0.0.1:54321',
        anonKey: 'sb_publishable_local',
      ).isConfigured,
      isTrue,
    );
  });

  test('rejects service role material in the Flutter client', () {
    expect(
      SupabaseConfig.isPublicAnonKey('sb_secret_should_never_ship'),
      isFalse,
    );
    expect(
      const SupabaseConfig(
        url: 'https://inyjehqhrrneiufitwch.supabase.co',
        anonKey: 'sb_secret_should_never_ship',
      ).isConfigured,
      isFalse,
    );
    expect(
      SupabaseConfig(
        url: 'https://inyjehqhrrneiufitwch.supabase.co',
        anonKey: _legacyJwt('service_role'),
      ).isConfigured,
      isFalse,
    );
    expect(SupabaseConfig.isPublicAnonKey(_legacyJwt('anon')), isTrue);
  });

  test('environment config is empty unless dart-define is passed', () {
    expect(SupabaseConfig.fromEnvironment.isConfigured, isFalse);
  });

  test('optional bootstrap does not start without a public key', () async {
    final started = await bootstrapSupabase(
      const SupabaseConfig(url: '', anonKey: ''),
      ({required url, required publishableKey, accessToken}) async {
        fail('initializer must not run');
      },
    );
    expect(started, isFalse);
  });

  test('optional bootstrap keeps Firebase available if Supabase fails', () async {
    final errors = <Object>[];
    final previous = FlutterError.onError;
    FlutterError.onError = (details) => errors.add(details.exception);
    addTearDown(() => FlutterError.onError = previous);

    final started = await bootstrapSupabase(
      const SupabaseConfig(
        url: 'https://inyjehqhrrneiufitwch.supabase.co',
        anonKey: 'sb_publishable_test',
      ),
      ({required url, required publishableKey, accessToken}) async {
        throw Exception('supabase unavailable');
      },
    );

    expect(started, isFalse);
    expect(errors, isNotEmpty);
  });
}
