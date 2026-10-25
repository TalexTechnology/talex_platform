import 'dart:async';

import 'package:talex_platform/core/data/http_remote_database.dart';
import 'package:talex_platform/core/data/remote_database.dart';
import 'package:talex_platform/core/supabase/supabase_gateway.dart';
import 'package:talex_platform/features/admin/data/datasources/assessment_question_data_source.dart';
import 'package:talex_platform/features/admin/domain/entities/assessment_question.dart';
import 'package:talex_platform/features/admin/domain/services/assessment_question_defaults.dart';

const affinitySurveySlug = 'affinity-core';
const cultureSurveySlug = 'culture-perception';

final class SupabaseAssessmentQuestionDataSource
    implements AssessmentQuestionDataSource {
  SupabaseAssessmentQuestionDataSource({
    RemoteDatabase? database,
    this.slug = affinitySurveySlug,
  }) : _db = database ?? HttpRemoteDatabase();

  final RemoteDatabase _db;
  final String slug;
  final _changes = StreamController<List<AssessmentQuestion>>.broadcast();

  Future<T> _guard<T>(Future<T> Function() action) => guardSupabase(action);

  List<AssessmentQuestion> _parseBank(dynamic payload) {
    final rows = payload is List ? payload : const [];
    return [
      for (final row in rows)
        if (row is Map)
          assessmentQuestionFromMap(
            '${row['code'] ?? ''}',
            Map<String, dynamic>.from(row),
          ),
    ]..sort((a, b) => a.order.compareTo(b.order));
  }

  Future<List<AssessmentQuestion>> _load() => _guard(() async {
    final payload = await _db.rpc(
      'list_survey_bank',
      params: {'p_slug': slug},
    );
    return _parseBank(payload);
  });

  Future<void> _emit() async {
    final items = await _load();
    if (!_changes.isClosed) _changes.add(items);
  }

  @override
  Stream<List<AssessmentQuestion>> watch() async* {
    yield await _load();
    yield* _changes.stream;
  }

  @override
  Future<void> save(AssessmentQuestion question) => _guard(() async {
    await _db.rpc(
      'upsert_survey_question',
      params: {
        'p_slug': slug,
        'p_question': assessmentQuestionToMap(question),
      },
    );
    await _emit();
  });

  @override
  Future<void> setActive(String code, bool active) => _guard(() async {
    await _db.rpc(
      'set_survey_question_active',
      params: {
        'p_slug': slug,
        'p_code': code,
        'p_active': active,
      },
    );
    await _emit();
  });

  @override
  Future<void> swapOrder(AssessmentQuestion first, AssessmentQuestion second) =>
      _guard(() async {
        await _db.rpc(
          'swap_survey_question_order',
          params: {
            'p_slug': slug,
            'p_code_a': first.code,
            'p_code_b': second.code,
          },
        );
        await _emit();
      });

  @override
  Future<void> delete(String code) => _guard(() async {
    await _db.rpc(
      'delete_survey_question',
      params: {'p_slug': slug, 'p_code': code},
    );
    await _emit();
  });

  @override
  Future<void> saveAll(List<AssessmentQuestion> questions) => _guard(() async {
    await _db.rpc(
      'replace_survey_bank',
      params: {
        'p_slug': slug,
        'p_questions': [
          for (final question in questions) assessmentQuestionToMap(question),
        ],
      },
    );
    await _emit();
  });

  @override
  Future<void> seedDefaults() => saveAll(AssessmentQuestionDefaults.all);

  @override
  Future<void> deleteAll() => saveAll(const []);

  Future<List<Map<String, dynamic>>> listCultureBank() => _guard(() async {
    final payload = await _db.rpc(
      'list_survey_bank',
      params: {'p_slug': cultureSurveySlug},
    );
    final rows = payload is List ? payload : const [];
    return [
      for (final row in rows)
        if (row is Map) Map<String, dynamic>.from(row),
    ];
  });

  Future<void> replaceCultureBank(List<Map<String, dynamic>> questions) =>
      _guard(() async {
        await _db.rpc(
          'replace_survey_bank',
          params: {
            'p_slug': cultureSurveySlug,
            'p_questions': questions,
          },
        );
      });
}
