import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:talex_platform/core/data/remote_database.dart';
import 'package:talex_platform/core/error/exceptions.dart';
import 'package:talex_platform/features/talent/domain/talent_error_codes.dart';

final class SupabaseRemoteDatabase implements RemoteDatabase {
  SupabaseRemoteDatabase([SupabaseClient? client]) : _client = client;

  final SupabaseClient? _client;
  SupabaseClient get _db => _client ?? Supabase.instance.client;

  @override
  RemoteQuery from(String table) => SupabaseRemoteQuery(_db.from(table));

  @override
  Future<dynamic> rpc(String fn, {Map<String, dynamic>? params}) {
    return _db.rpc(fn, params: params);
  }
}

final class SupabaseRemoteQuery implements RemoteQuery {
  SupabaseRemoteQuery(this._query);

  dynamic _query;

  Future<List<dynamic>> get _future async {
    final result = await _query;
    if (result is List) return result;
    return [?result];
  }

  @override
  RemoteQuery select([String columns = '*']) {
    _query = _query.select(columns);
    return this;
  }

  @override
  RemoteQuery eq(String column, Object? value) {
    _query = _query.eq(column, value);
    return this;
  }

  @override
  RemoteQuery order(String column, {bool ascending = true}) {
    _query = _query.order(column, ascending: ascending);
    return this;
  }

  @override
  RemoteQuery limit(int count) {
    _query = _query.limit(count);
    return this;
  }

  @override
  RemoteQuery update(Map<String, dynamic> values) {
    _query = _query.update(values);
    return this;
  }

  @override
  RemoteQuery insert(Map<String, dynamic> values) {
    _query = _query.insert(values);
    return this;
  }

  @override
  RemoteQuery delete() {
    _query = _query.delete();
    return this;
  }

  @override
  Future<Map<String, dynamic>?> maybeSingle() async {
    final result = await _query.maybeSingle();
    return result == null ? null : Map<String, dynamic>.from(result as Map);
  }

  @override
  Future<Map<String, dynamic>> single() async {
    final result = await _query.single();
    if (result is Map<String, dynamic>) return result;
    if (result is Map) return Map<String, dynamic>.from(result);
    throw const ServerException(TalentErrorCodes.unexpected);
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
