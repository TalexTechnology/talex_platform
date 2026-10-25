import 'package:equatable/equatable.dart';

enum AssessmentFront {
  coreValues('values'),
  needs('needs'),
  capabilities('capabilities'),
  cultura('cultura'),
  liderazgo('liderazgo'),
  trabajo('trabajo'),
  personas('personas'),
  apertura('apertura');

  const AssessmentFront(this.key);
  final String key;

  bool get isAffinity =>
      this == coreValues || this == needs || this == capabilities;

  bool get isCulture => !isAffinity;

  static const affinityFronts = [
    coreValues,
    needs,
    capabilities,
  ];

  static const cultureFronts = [
    cultura,
    liderazgo,
    trabajo,
    personas,
    apertura,
  ];
}

enum AssessmentQuestionFormat { pair, experience, scale, text, single, multi }

class AssessmentQuestion extends Equatable {
  const AssessmentQuestion({
    required this.code,
    required this.order,
    required this.front,
    required this.format,
    required this.dimensionA,
    required this.instruction,
    required this.statementA,
    required this.options,
    this.dimensionB = '',
    this.statementB = '',
    this.timeLimitSeconds,
    this.active = true,
  });
  final String code,
      dimensionA,
      dimensionB,
      instruction,
      statementA,
      statementB;
  final int order;
  final AssessmentFront front;
  final AssessmentQuestionFormat format;
  final List<String> options;
  final int? timeLimitSeconds;
  final bool active;

  bool get isPair => format == AssessmentQuestionFormat.pair;

  bool matches(String query) {
    final needle = query.trim().toLowerCase();
    if (needle.isEmpty) return true;
    return [
      code,
      dimensionA,
      dimensionB,
      statementA,
      statementB,
    ].any((value) => value.toLowerCase().contains(needle));
  }

  @override
  List<Object?> get props => [
    code,
    order,
    front,
    format,
    dimensionA,
    dimensionB,
    instruction,
    statementA,
    statementB,
    options,
    timeLimitSeconds,
    active,
  ];
}
