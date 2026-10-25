/// Puerto de persistencia usado por los data sources.
///
/// Supabase (producción) y la API local (MySQL) implementan el mismo contrato
/// para no duplicar mapeos de dominio.
abstract interface class RemoteDatabase {
  RemoteQuery from(String table);
  Future<dynamic> rpc(String fn, {Map<String, dynamic>? params});
}

abstract interface class RemoteQuery implements Future<List<dynamic>> {
  RemoteQuery select([String columns = '*']);
  RemoteQuery eq(String column, Object? value);
  RemoteQuery order(String column, {bool ascending = true});
  RemoteQuery limit(int count);
  RemoteQuery update(Map<String, dynamic> values);
  RemoteQuery insert(Map<String, dynamic> values);
  RemoteQuery delete();
  Future<Map<String, dynamic>?> maybeSingle();
  Future<Map<String, dynamic>> single();
}
