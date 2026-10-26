import 'package:talex_platform/core/api/talex_api_client.dart';
import 'package:talex_platform/core/data/http_remote_database.dart';
import 'package:talex_platform/core/data/remote_database.dart';
import 'package:talex_platform/core/supabase/supabase_gateway.dart';
import 'package:talex_platform/features/admin/domain/entities/culture_organization_report.dart';
import 'package:talex_platform/features/admin/domain/entities/culture_survey_responses.dart';

final class CultureReportDataSource {
  CultureReportDataSource({RemoteDatabase? database, TalexApiClient? api})
    : _db = database ?? HttpRemoteDatabase(),
      _api = api ?? TalexApiClient();

  final RemoteDatabase _db;
  final TalexApiClient _api;

  Future<CultureOrganizationReport> load() => guardSupabase(() async {
    final payload = await _db.rpc('culture_leads_by_organization');
    return CultureOrganizationReport.fromMap(
      payload is Map ? Map<String, dynamic>.from(payload) : const {},
    );
  });

  /// Respuestas anónimas de la encuesta de cultura de [organizationId]. Va
  /// con el token de sesión del admin (TalexApiClient).
  Future<CultureSurveyResponses> responses(String organizationId) async {
    final rows = await _api.send(
      'GET',
      '/api/cultura/${Uri.encodeComponent(organizationId)}/respuestas',
    );
    final payload = rows.firstOrNull;
    return CultureSurveyResponses.fromApi(
      payload is Map ? Map<String, dynamic>.from(payload) : const {},
    );
  }
}
