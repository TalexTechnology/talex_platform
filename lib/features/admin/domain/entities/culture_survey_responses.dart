import 'package:equatable/equatable.dart';

// Respuestas anónimas de la encuesta de cultura de una empresa
// (rpc culture_survey_responses). No hay datos de quién respondió: cada
// respuesta es solo el mapa código de pregunta → valor, en orden aleatorio.

class CultureChoice extends Equatable {
  const CultureChoice({required this.id, required this.label});

  final String id;
  final String label;

  factory CultureChoice.fromMap(Map<String, dynamic> map) => CultureChoice(
    id: '${map['id'] ?? ''}',
    label: '${map['label'] ?? map['id'] ?? ''}',
  );

  @override
  List<Object?> get props => [id, label];
}

class CultureSurveyQuestion extends Equatable {
  const CultureSurveyQuestion({
    required this.code,
    required this.statement,
    required this.format,
    this.name,
    this.sectionTitle,
    this.options = const [],
    this.items = const [],
    this.scale = const [],
  });

  final String code;
  final String statement;
  final String format;
  final String? name;
  final String? sectionTitle;
  final List<CultureChoice> options;
  final List<CultureChoice> items;
  final List<CultureChoice> scale;

  factory CultureSurveyQuestion.fromMap(Map<String, dynamic> map) =>
      CultureSurveyQuestion(
        code: '${map['code'] ?? ''}',
        statement: '${map['statement'] ?? ''}',
        format: '${map['format'] ?? ''}',
        name: _text(map['name']),
        sectionTitle: _text(map['sectionTitle']),
        options: _choices(map['options']),
        items: _choices(map['items']),
        scale: _choices(map['scale']),
      );

  /// Etiqueta legible de una opción o ítem; si ya no existe, el id.
  String labelOf(String id) {
    for (final choice in [...options, ...items, ...scale]) {
      if (choice.id == id) return choice.label;
    }
    return id;
  }

  @override
  List<Object?> get props => [code, statement, format, options, items, scale];
}

/// Conteo de una opción dentro de una pregunta.
class CultureTally extends Equatable {
  const CultureTally({required this.label, required this.count});

  final String label;
  final int count;

  @override
  List<Object?> get props => [label, count];
}

class CultureSurveyResponses extends Equatable {
  const CultureSurveyResponses({
    required this.questions,
    required this.responses,
    this.title,
  });

  final String? title;
  final List<CultureSurveyQuestion> questions;

  /// Una entrada por persona: código de pregunta → valor tal como se guardó.
  final List<Map<String, dynamic>> responses;

  int get respondentCount => responses.length;

  factory CultureSurveyResponses.fromMap(Map<String, dynamic> map) =>
      CultureSurveyResponses(
        title: _text(map['title']),
        questions: [
          for (final item in _list(map['questions']))
            CultureSurveyQuestion.fromMap(item),
        ],
        responses: [
          for (final item in _list(map['responses']))
            item['answers'] is Map
                ? Map<String, dynamic>.from(item['answers'] as Map)
                : const <String, dynamic>{},
        ],
      );

  List<Map<String, dynamic>> _answersTo(CultureSurveyQuestion question) => [
    for (final response in responses)
      if (response[question.code] is Map)
        Map<String, dynamic>.from(response[question.code] as Map),
  ];

  int answeredCount(CultureSurveyQuestion question) =>
      _answersTo(question).length;

  /// Opción única: cuántas personas eligieron cada opción.
  List<CultureTally> single(CultureSurveyQuestion question) => _tally(
    question,
    [for (final answer in _answersTo(question)) '${answer['value'] ?? ''}'],
  );

  /// Más/menos probable: conteos por opción para cada extremo.
  ({List<CultureTally> most, List<CultureTally> least, double? forecast})
  mostLeast(CultureSurveyQuestion question) {
    final answers = _answersTo(question);
    final forecasts = [
      for (final answer in answers)
        if (answer['forecast'] is num) (answer['forecast'] as num).toDouble(),
    ];
    return (
      most: _tally(question, [for (final a in answers) '${a['most'] ?? ''}']),
      least: _tally(question, [for (final a in answers) '${a['least'] ?? ''}']),
      forecast: forecasts.isEmpty
          ? null
          : forecasts.reduce((a, b) => a + b) / forecasts.length,
    );
  }

  /// Coherencia de valores: por cada valor declarado, cuántos eligieron cada
  /// punto de la escala.
  List<(String, List<CultureTally>)> coherence(CultureSurveyQuestion question) {
    final answers = _answersTo(question);
    final itemIds = question.items.isNotEmpty
        ? [for (final item in question.items) item.id]
        : {
            for (final answer in answers)
              if (answer['ratings'] is Map)
                ...(answer['ratings'] as Map).keys.map((key) => '$key'),
          }.toList();
    return [
      for (final id in itemIds)
        (
          question.labelOf(id),
          _tally(question, [
            for (final answer in answers)
              if (answer['ratings'] is Map)
                '${(answer['ratings'] as Map)[id] ?? ''}',
          ], order: question.scale),
        ),
    ];
  }

  /// Sí/no: por opción, cuántos la marcaron como "sí" y como "no".
  List<(String, int, int)> yesNo(CultureSurveyQuestion question) {
    final answers = _answersTo(question);
    int countIn(String key, String id) => answers
        .where((a) => a[key] is List && (a[key] as List).contains(id))
        .length;
    final ids = question.options.isNotEmpty
        ? [for (final option in question.options) option.id]
        : {
            for (final a in answers)
              for (final key in const ['yes', 'no'])
                if (a[key] is List) ...(a[key] as List).map((id) => '$id'),
          }.toList();
    return [
      for (final id in ids)
        (question.labelOf(id), countIn('yes', id), countIn('no', id)),
    ]..sort((a, b) => (b.$2 - b.$3).compareTo(a.$2 - a.$3));
  }

  /// Respuestas abiertas, sin vacíos.
  List<String> texts(CultureSurveyQuestion question) => [
    for (final answer in _answersTo(question))
      if ('${answer['value_text'] ?? answer['value'] ?? ''}'.trim().isNotEmpty)
        '${answer['value_text'] ?? answer['value']}'.trim(),
  ];

  /// Resumen en texto de la respuesta de una persona a una pregunta.
  String describe(
    CultureSurveyQuestion question,
    Map<String, dynamic> response,
  ) {
    final raw = response[question.code];
    if (raw is! Map) return '';
    final answer = Map<String, dynamic>.from(raw);
    String labels(Object? ids) =>
        ids is List ? ids.map((id) => question.labelOf('$id')).join(', ') : '';
    return switch (question.format) {
      'most_least' => [
        '+ ${question.labelOf('${answer['most'] ?? ''}')}',
        '− ${question.labelOf('${answer['least'] ?? ''}')}',
        if (answer['forecast'] is num) '${answer['forecast']}%',
      ].join('  ·  '),
      'value_coherence' when answer['ratings'] is Map =>
        (answer['ratings'] as Map).entries
            .map(
              (entry) =>
                  '${question.labelOf('${entry.key}')}: ${question.labelOf('${entry.value}')}',
            )
            .join('  ·  '),
      'pick_yes_no' => [
        '✓ ${labels(answer['yes'])}',
        '✕ ${labels(answer['no'])}',
      ].join('\n'),
      'text' => '${answer['value_text'] ?? answer['value'] ?? ''}',
      _ => question.labelOf('${answer['value'] ?? answer['value_text'] ?? ''}'),
    };
  }

  List<CultureTally> _tally(
    CultureSurveyQuestion question,
    List<String> picks, {
    List<CultureChoice>? order,
  }) {
    final counts = <String, int>{};
    for (final id in picks) {
      if (id.isEmpty) continue;
      counts[id] = (counts[id] ?? 0) + 1;
    }
    final base =
        order ?? (question.options.isNotEmpty ? question.options : null);
    if (base != null) {
      // Todas las opciones, incluso las que nadie eligió, en su orden.
      final ids = [for (final choice in base) choice.id];
      for (final id in counts.keys) {
        if (!ids.contains(id)) ids.add(id);
      }
      return [
        for (final id in ids)
          CultureTally(label: question.labelOf(id), count: counts[id] ?? 0),
      ];
    }
    return [
      for (final entry in counts.entries)
        CultureTally(label: question.labelOf(entry.key), count: entry.value),
    ]..sort((a, b) => b.count.compareTo(a.count));
  }

  @override
  List<Object?> get props => [title, questions, responses];
}

String? _text(Object? value) {
  final text = value == null ? '' : '$value'.trim();
  return text.isEmpty ? null : text;
}

List<Map<String, dynamic>> _list(Object? value) => [
  if (value is List)
    for (final item in value)
      if (item is Map) Map<String, dynamic>.from(item),
];

List<CultureChoice> _choices(Object? value) => [
  for (final item in _list(value)) CultureChoice.fromMap(item),
];
