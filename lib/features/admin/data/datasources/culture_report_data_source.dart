import 'package:talex_platform/core/data/http_remote_database.dart';
import 'package:talex_platform/core/data/remote_database.dart';
import 'package:talex_platform/core/supabase/supabase_gateway.dart';
import 'package:talex_platform/features/admin/domain/entities/culture_organization_report.dart';

final class CultureReportDataSource {
  CultureReportDataSource({RemoteDatabase? database})
    : _db = database ?? HttpRemoteDatabase();

  final RemoteDatabase _db;

  Future<CultureOrganizationReport> load() => guardSupabase(() async {
    final payload = await _db.rpc('culture_leads_by_organization');
    return CultureOrganizationReport.fromMap(
      payload is Map ? Map<String, dynamic>.from(payload) : const {},
    );
  });
}
