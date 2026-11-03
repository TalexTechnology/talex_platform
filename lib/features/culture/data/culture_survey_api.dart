import 'dart:convert';
import 'dart:async';
import 'dart:math';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:talex_platform/core/api/local_api_config.dart';

class CultureSurveyApi {
  CultureSurveyApi({http.Client? httpClient, LocalApiConfig? config})
    : _http = httpClient ?? http.Client(),
      _baseUrl = (config ?? LocalApiConfig.fromEnvironment).url.replaceAll(
        RegExp(r'/$'),
        '',
      );

  final http.Client _http;
  final String _baseUrl;
  final String _visitId = _randomId();
  final Map<String, Future<String>> _visitors = {};

  static String _randomId() => List.generate(
    24,
    (_) => Random.secure().nextInt(256).toRadixString(16).padLeft(2, '0'),
  ).join();

  Future<String> _visitorId(
    String organizationId,
  ) => _visitors.putIfAbsent(organizationId, () async {
    final fallback = _randomId();
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = 'talex.cultureVisitor.$organizationId';
      final previous = prefs.getString(key);
      if (previous != null) return previous;
      await prefs.setString(key, fallback);
    } catch (_) {
      // El diagnóstico funciona también cuando el almacenamiento está bloqueado.
    }
    return fallback;
  });

  Future<void> track(String organizationId, String event) async {
    try {
      await _http
          .post(
            Uri.parse(
              '$_baseUrl/api/cultura/${Uri.encodeComponent(organizationId)}/visitas',
            ),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'event': event,
              'visitorId': await _visitorId(organizationId),
              'visitId': _visitId,
            }),
          )
          .timeout(const Duration(seconds: 8));
    } catch (_) {
      // Un fallo de métricas nunca impide responder la encuesta.
    }
  }

  Future<Map<String, dynamic>> load(String organizationId) async {
    final response = await _http.get(
      Uri.parse('$_baseUrl/api/cultura/${Uri.encodeComponent(organizationId)}'),
    );
    final body = _decode(response.body);
    if (response.statusCode >= 400) {
      throw Exception(body['message'] ?? 'No encontramos este diagnóstico.');
    }
    unawaited(track(organizationId, 'opened'));
    return body;
  }

  Future<void> submit(
    String organizationId,
    Map<String, dynamic> answers,
  ) async {
    final response = await _http.post(
      Uri.parse('$_baseUrl/api/cultura/${Uri.encodeComponent(organizationId)}'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'answers': answers}),
    );
    if (response.statusCode >= 400) {
      final body = _decode(response.body);
      throw Exception(body['message'] ?? 'No pudimos guardar las respuestas.');
    }
  }

  Map<String, dynamic> _decode(String raw) {
    if (raw.isEmpty) return const {};
    final decoded = jsonDecode(raw);
    return decoded is Map ? Map<String, dynamic>.from(decoded) : const {};
  }
}
