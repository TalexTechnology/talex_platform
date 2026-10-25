import 'package:equatable/equatable.dart';

// Banco de preguntas de la encuesta "Mi cultura" que responden los
// colaboradores de cada empresa (endpoints `*_culture_question*`).

class CultureOption extends Equatable {
  const CultureOption({
    required this.id,
    required this.label,
    this.dimension = '',
  });

  final String id;
  final String label;
  final String dimension;

  factory CultureOption.fromMap(Map<String, dynamic> map) => CultureOption(
    id: _text(map['id']),
    label: _text(map['label']),
    dimension: _text(map['dimension']),
  );

  Map<String, dynamic> toMap() => {
    'id': id,
    'label': label,
    if (dimension.isNotEmpty) 'dimension': dimension,
  };

  @override
  List<Object?> get props => [id, label, dimension];
}

class CultureQuestion extends Equatable {
  const CultureQuestion({
    required this.code,
    required this.statement,
    this.name = '',
    this.instruction = '',
    this.format = '',
    this.optionsSource = '',
    this.section = '',
    this.sectionTitle = '',
    this.technique = '',
    this.required = true,
    this.active = true,
    this.options = const [],
  });

  final String code;
  final String name;
  final String statement;
  final String instruction;
  final String format;
  final String optionsSource;
  final String section;
  final String sectionTitle;
  final String technique;
  final bool required;
  final bool active;
  final List<CultureOption> options;

  factory CultureQuestion.fromMap(Map<String, dynamic> map) => CultureQuestion(
    code: _text(map['code']),
    name: _text(map['name']),
    statement: _text(map['statement']),
    instruction: _text(map['instruction']),
    format: _text(map['format']),
    optionsSource: _text(map['options_source']),
    section: _text(map['section']),
    sectionTitle: _text(map['section_title']),
    technique: _text(map['technique']),
    required: map['required'] is bool ? map['required'] as bool : true,
    active: map['is_active'] is bool ? map['is_active'] as bool : true,
    options: [
      if (map['options'] is List)
        for (final item in map['options'] as List)
          if (item is Map)
            CultureOption.fromMap(Map<String, dynamic>.from(item)),
    ],
  );

  Map<String, dynamic> toMap() => {
    'code': code,
    if (name.isNotEmpty) 'name': name,
    'statement': statement,
    if (instruction.isNotEmpty) 'instruction': instruction,
    if (format.isNotEmpty) 'format': format,
    if (optionsSource.isNotEmpty) 'options_source': optionsSource,
    if (section.isNotEmpty) 'section': section,
    if (sectionTitle.isNotEmpty) 'section_title': sectionTitle,
    if (technique.isNotEmpty) 'technique': technique,
    'required': required,
    'is_active': active,
    'options': [for (final option in options) option.toMap()],
  };

  /// Solo los campos que cambiaron respecto a [original], para
  /// `update_culture_question` (que edita únicamente lo que se manda).
  Map<String, dynamic> changesFrom(CultureQuestion original) {
    final next = toMap()..remove('code');
    final previous = original.toMap()..remove('code');
    final keys = {...next.keys, ...previous.keys};
    return {
      for (final key in keys)
        if ('${next[key]}' != '${previous[key]}')
          key: next[key] ?? (key == 'options' ? const [] : ''),
    };
  }

  bool matches(String query) {
    final needle = query.trim().toLowerCase();
    if (needle.isEmpty) return true;
    return [
      code,
      name,
      statement,
      sectionTitle,
      technique,
    ].any((value) => value.toLowerCase().contains(needle));
  }

  @override
  List<Object?> get props => [
    code,
    name,
    statement,
    instruction,
    format,
    optionsSource,
    section,
    sectionTitle,
    technique,
    required,
    active,
    options,
  ];
}

class CultureQuestionBank extends Equatable {
  const CultureQuestionBank({
    required this.questions,
    this.title = '',
    this.intro = '',
  });

  final String title;
  final String intro;
  final List<CultureQuestion> questions;

  // La respuesta puede ser la lista de preguntas o un objeto que la envuelve
  // junto al título y la intro de la encuesta; se aceptan ambas formas.
  factory CultureQuestionBank.fromRows(List<dynamic> rows) {
    Map<String, dynamic>? container;
    var items = rows;
    if (rows.length == 1 && rows.first is Map) {
      final map = Map<String, dynamic>.from(rows.first as Map);
      if (!map.containsKey('code')) {
        container = map;
        final list = map['questions'] ?? map['items'] ?? map['data'];
        items = list is List ? list : const [];
      }
    }
    final survey = container?['survey'] is Map
        ? Map<String, dynamic>.from(container!['survey'] as Map)
        : container;
    final indexed = [
      for (final (index, item) in items.indexed)
        if (item is Map) (index, Map<String, dynamic>.from(item)),
    ]..sort((a, b) => _order(a.$2, a.$1).compareTo(_order(b.$2, b.$1)));
    return CultureQuestionBank(
      title: _text(survey?['title']),
      intro: _text(survey?['intro']),
      questions: [for (final (_, map) in indexed) CultureQuestion.fromMap(map)],
    );
  }

  @override
  List<Object?> get props => [title, intro, questions];
}

num _order(Map<String, dynamic> map, int fallback) {
  for (final key in const ['order', 'position', 'sort_order']) {
    if (map[key] is num) return map[key] as num;
  }
  return fallback;
}

String _text(Object? value) => value == null ? '' : '$value'.trim();
