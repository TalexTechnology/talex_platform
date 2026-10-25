import 'package:talex_platform/core/api/talex_api_client.dart';
import 'package:talex_platform/features/admin/domain/entities/culture_question.dart';

// Usa el cliente HTTP directo (no RemoteDatabase.rpc) porque rpc colapsa una
// lista de un solo elemento en ese elemento, y aquí la forma importa.
final class CultureQuestionDataSource {
  CultureQuestionDataSource({TalexApiClient? client})
    : _client = client ?? TalexApiClient();

  final TalexApiClient _client;

  Future<List<dynamic>> _rpc(String name, [Map<String, dynamic>? params]) =>
      _client.send('POST', '/v1/rpc/$name', body: params ?? const {});

  // Siempre con las desactivadas: reordenar exige mandar todo el banco.
  Future<CultureQuestionBank> list() async => CultureQuestionBank.fromRows(
    await _rpc('list_culture_questions', {'p_include_inactive': true}),
  );

  Future<void> create(CultureQuestion question) =>
      _rpc('create_culture_question', {'p_question': question.toMap()});

  Future<void> update(String code, Map<String, dynamic> changes) =>
      _rpc('update_culture_question', {'p_code': code, 'p_question': changes});

  Future<void> delete(String code) =>
      _rpc('delete_culture_question', {'p_code': code});

  Future<void> reorder(List<String> codes) =>
      _rpc('reorder_culture_questions', {'p_codes': codes});

  Future<void> updateSurvey({required String title, required String intro}) =>
      _rpc('update_culture_survey', {'p_title': title, 'p_intro': intro});
}
