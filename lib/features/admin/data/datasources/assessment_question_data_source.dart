import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:talex_platform/features/admin/domain/entities/assessment_question.dart';
import 'package:talex_platform/features/admin/domain/services/assessment_question_defaults.dart';

Map<String, dynamic> assessmentQuestionToMap(AssessmentQuestion question) => {
  'code': question.code,
  'order': question.order,
  'front': question.front.key,
  'format': question.format.name,
  'dimensionA': question.dimensionA,
  'dimensionB': question.isPair ? question.dimensionB : '',
  'instruction': question.instruction,
  'statementA': question.statementA,
  'statementB': question.isPair ? question.statementB : '',
  'options': question.options,
  'timeLimitSeconds': question.timeLimitSeconds,
  'active': question.active,
};

AssessmentQuestion assessmentQuestionFromMap(
  String id,
  Map<String, dynamic> data,
) {
  final front = AssessmentFront.values.firstWhere(
    (item) => item.key == data['front'] || item.key == data['section'],
    orElse: () => AssessmentFront.coreValues,
  );
  final format = AssessmentQuestionFormat.values.firstWhere(
    (item) => item.name == data['format'],
    orElse: () => AssessmentQuestionDefaults.formatFor(front),
  );
  final options = [
    for (final item in data['options'] as List? ?? const []) '$item',
  ];
  return AssessmentQuestion(
    code: id,
    order: (data['order'] as num?)?.toInt() ?? 0,
    front: front,
    format: format,
    dimensionA: data['dimensionA'] as String? ?? data['dimension_a'] as String? ?? '',
    dimensionB: data['dimensionB'] as String? ?? data['dimension_b'] as String? ?? '',
    instruction: data['instruction'] as String? ?? '',
    statementA:
        data['statementA'] as String? ?? data['statement_a'] as String? ?? '',
    statementB:
        data['statementB'] as String? ?? data['statement_b'] as String? ?? '',
    options: options.isEmpty
        ? AssessmentQuestionDefaults.optionsFor(format)
        : options,
    timeLimitSeconds:
        (data['timeLimitSeconds'] as num?)?.toInt() ??
        (data['time_limit_seconds'] as num?)?.toInt(),
    active: data['active'] as bool? ?? data['is_active'] as bool? ?? true,
  );
}

abstract interface class AssessmentQuestionDataSource {
  Stream<List<AssessmentQuestion>> watch();
  Future<void> save(AssessmentQuestion question);
  Future<void> setActive(String code, bool active);
  Future<void> swapOrder(AssessmentQuestion first, AssessmentQuestion second);
  Future<void> delete(String code);
  Future<void> saveAll(List<AssessmentQuestion> questions);
  Future<void> seedDefaults();
  Future<void> deleteAll();
}

final class FirebaseAssessmentQuestionDataSource
    implements AssessmentQuestionDataSource {
  FirebaseAssessmentQuestionDataSource(this._firestore);
  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _questions =>
      _firestore.collection('assessment_questions');

  Map<String, dynamic> _stamped(Map<String, dynamic> data) => {
    ...data,
    'updatedAt': FieldValue.serverTimestamp(),
  };

  @override
  Stream<List<AssessmentQuestion>> watch() => _questions
      .orderBy('order')
      .snapshots()
      .map(
        (snapshot) => [
          for (final doc in snapshot.docs)
            assessmentQuestionFromMap(doc.id, doc.data()),
        ],
      );

  @override
  Future<void> save(AssessmentQuestion question) => _questions
      .doc(question.code)
      .set(_stamped(assessmentQuestionToMap(question)));

  @override
  Future<void> setActive(String code, bool active) =>
      _questions.doc(code).update(_stamped({'active': active}));

  @override
  Future<void> swapOrder(AssessmentQuestion first, AssessmentQuestion second) {
    final batch = _firestore.batch()
      ..update(_questions.doc(first.code), _stamped({'order': second.order}))
      ..update(_questions.doc(second.code), _stamped({'order': first.order}));
    return batch.commit();
  }

  @override
  Future<void> delete(String code) => _questions.doc(code).delete();

  static const _batchSize = 400;

  @override
  Future<void> saveAll(List<AssessmentQuestion> questions) async {
    for (var start = 0; start < questions.length; start += _batchSize) {
      final batch = _firestore.batch();
      for (final question in questions.skip(start).take(_batchSize)) {
        batch.set(
          _questions.doc(question.code),
          _stamped(assessmentQuestionToMap(question)),
        );
      }
      await batch.commit();
    }
  }

  @override
  Future<void> seedDefaults() => saveAll(AssessmentQuestionDefaults.all);

  @override
  Future<void> deleteAll() async {
    final docs = (await _questions.get()).docs;
    for (var start = 0; start < docs.length; start += _batchSize) {
      final batch = _firestore.batch();
      for (final doc in docs.skip(start).take(_batchSize)) {
        batch.delete(doc.reference);
      }
      await batch.commit();
    }
  }
}
