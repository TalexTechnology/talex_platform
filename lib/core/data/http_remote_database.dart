import 'dart:async';

import 'package:talex_platform/core/api/talex_api_client.dart';
import 'package:talex_platform/core/data/remote_database.dart';
import 'package:talex_platform/core/error/exceptions.dart';
import 'package:talex_platform/features/talent/domain/talent_error_codes.dart';

final class HttpRemoteDatabase implements RemoteDatabase {
  HttpRemoteDatabase([TalexApiClient? client])
    : _client = client ?? TalexApiClient();

  final TalexApiClient _client;

  @override
  RemoteQuery from(String table) => HttpRemoteQuery(_client, table);

  @override
  Future<dynamic> rpc(String fn, {Map<String, dynamic>? params}) async {
    final rows = await _client.rpc(fn, params: params);
    if (rows.isEmpty) return null;
    return rows.length == 1 ? rows.first : rows;
  }
}

final class HttpRemoteQuery implements RemoteQuery {
  HttpRemoteQuery(this._client, this._table);

  final TalexApiClient _client;
  final String _table;
  String _select = '*';
  final Map<String, String> _equals = {};
  String? _order;
  int? _limit;
  String _method = 'GET';
  Map<String, dynamic>? _payload;

  Map<String, String> get _query {
    return {
      if (_select != '*') 'select': _select,
      'order': ?_order,
      if (_limit != null) 'limit': '$_limit',
      for (final entry in _equals.entries) 'eq.${entry.key}': entry.value,
    };
  }

  Future<List<dynamic>> get _future {
    return _client.send(
      _method,
      '/v1/data/$_table',
      query: _query,
      body: _payload,
    );
  }

  @override
  RemoteQuery select([String columns = '*']) {
    _select = columns;
    return this;
  }

  @override
  RemoteQuery eq(String column, Object? value) {
    _equals[column] = '$value';
    return this;
  }

  @override
  RemoteQuery order(String column, {bool ascending = true}) {
    _order = '$column.${ascending ? 'asc' : 'desc'}';
    return this;
  }

  @override
  RemoteQuery limit(int count) {
    _limit = count;
    return this;
  }

  @override
  RemoteQuery update(Map<String, dynamic> values) {
    _method = 'PATCH';
    _payload = values;
    return this;
  }

  @override
  RemoteQuery insert(Map<String, dynamic> values) {
    _method = 'POST';
    _payload = values;
    return this;
  }

  @override
  RemoteQuery delete() {
    _method = 'DELETE';
    return this;
  }

  @override
  Future<Map<String, dynamic>?> maybeSingle() async {
    final rows = await _future;
    if (rows.isEmpty) return null;
    final first = rows.first;
    return first is Map ? Map<String, dynamic>.from(first) : null;
  }

  @override
  Future<Map<String, dynamic>> single() async {
    final row = await maybeSingle();
    if (row == null) {
      throw const ServerException(TalentErrorCodes.unexpected);
    }
    return row;
  }

  @override
  Stream<List<dynamic>> asStream() => _future.asStream();

  @override
  Future<List<dynamic>> catchError(
    Function onError, {
    bool Function(Object error)? test,
  }) {
    return _future.catchError(onError, test: test);
  }

  @override
  Future<R> then<R>(
    FutureOr<R> Function(List<dynamic> value) onValue, {
    Function? onError,
  }) {
    return _future.then(onValue, onError: onError);
  }

  @override
  Future<List<dynamic>> timeout(
    Duration timeLimit, {
    FutureOr<List<dynamic>> Function()? onTimeout,
  }) {
    return _future.timeout(timeLimit, onTimeout: onTimeout);
  }

  @override
  Future<List<dynamic>> whenComplete(FutureOr<void> Function() action) {
    return _future.whenComplete(action);
  }
}
