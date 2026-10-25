import 'dart:convert';

import 'package:http/http.dart' as http;
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

  Future<Map<String, dynamic>> load(String organizationId) async {
    final response = await _http.get(
      Uri.parse('$_baseUrl/api/cultura/${Uri.encodeComponent(organizationId)}'),
    );
    final body = _decode(response.body);
    if (response.statusCode >= 400) {
      throw Exception(body['message'] ?? 'No encontramos este diagnóstico.');
    }
    return body;
  }

  Future<void> submit(String organizationId, Map<String, dynamic> answers) async {
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
