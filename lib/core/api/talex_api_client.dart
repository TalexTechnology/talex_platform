import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'package:talex_platform/core/api/local_api_config.dart';
import 'package:talex_platform/core/error/exceptions.dart';
import 'package:talex_platform/features/talent/domain/talent_error_codes.dart';

class TalexApiClient {
  TalexApiClient({
    LocalApiConfig? config,
    FirebaseAuth? auth,
    http.Client? httpClient,
  }) : _baseUrl = (config ?? LocalApiConfig.fromEnvironment).url.replaceAll(
         RegExp(r'/$'),
         '',
       ),
       _auth = auth ?? FirebaseAuth.instance,
       _http = httpClient ?? http.Client();

  final String _baseUrl;
  final FirebaseAuth _auth;
  final http.Client _http;

  Future<dynamic> rpc(String name, {Map<String, dynamic>? params}) {
    return send('POST', '/v1/rpc/$name', body: params ?? {});
  }

  Future<List<dynamic>> send(
    String method,
    String path, {
    Map<String, String>? query,
    Object? body,
  }) async {
    final token = await _auth.currentUser?.getIdToken();
    if (token == null || token.isEmpty) {
      throw const ServerException(TalentErrorCodes.needSignIn);
    }
    final uri = Uri.parse('$_baseUrl$path').replace(queryParameters: query);
    final request = http.Request(method, uri)
      ..headers.addAll({
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      });
    if (body != null && method != 'GET') {
      request.body = jsonEncode(body);
    }
    final streamed = await _http.send(request);
    final response = await http.Response.fromStream(streamed);
    final decoded = response.body.isEmpty
        ? null
        : jsonDecode(response.body);
    if (response.statusCode >= 400) {
      final code = decoded is Map ? '${decoded['code'] ?? ''}' : '';
      throw ServerException(code.isEmpty ? TalentErrorCodes.unexpected : code);
    }
    if (decoded is List) return decoded;
    if (decoded == null) return const [];
    return [decoded];
  }
}
