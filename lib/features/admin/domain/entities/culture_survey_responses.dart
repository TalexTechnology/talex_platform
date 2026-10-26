import 'dart:math';

import 'package:equatable/equatable.dart';

// Respuestas de la encuesta de cultura de una empresa
// (GET /api/cultura/{id}/respuestas).
//
// Son anónimas: al leerlas se descartan el id de sesión y la fecha, y el orden
// se baraja. De cada persona solo queda su grupo (líder o empleado) y el mapa
// código de pregunta → valor.

class CultureChoice extends Equatable {
  const CultureChoice({required this.id, required this.label});

  final String id;
  final String label;

  @override
  List<Object?> get props => [id, label];
}

class CultureSurveyQuestion extends Equatable {
  const CultureSurveyQuestion({
    required this.code,
    required this.statement,
    required this.format,
    this.name,
    this.options = const [],
    this.items = const [],
    this.scale = const [],
  });

  final String code;
  final String statement;
  final String format;
  final String? name;
  final List<CultureChoice> options;
  final List<CultureChoice> items;
  final List<CultureChoice> scale;

  /// Etiqueta legible de una opción, ítem o punto de escala; si no se
  /// conoce, el id.
  String labelOf(String id) {
    for (final choice in [...options, ...items, ...scale]) {
      if (choice.id == id) return choice.label;
    }
    return id;
  }

  @override
  List<Object?> get props => [code, statement, format, options, items, scale];
}

/// Respuesta anónima de una persona.
class CultureResponse extends Equatable {
  const CultureResponse({required this.answers, this.group});

  /// "lider" o "empleado", según cómo se describió la persona.
  final String? group;

  /// Código de pregunta → valor tal como se guardó.
  final Map<String, Map<String, dynamic>> answers;

  @override
  List<Object?> get props => [group, answers];
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
  });

  static const leaders = 'lider';
  static const employees = 'empleado';

  final List<CultureSurveyQuestion> questions;
  final List<CultureResponse> responses;

  int get respondentCount => responses.length;

  int countOf(String group) =>
      responses.where((response) => response.group == group).length;

  /// Solo las respuestas de [group] (o todas si es null).
  CultureSurveyResponses only(String? group) => group == null
      ? this
      : CultureSurveyResponses(
          questions: questions,
          responses: [
            for (final response in responses)
              if (response.group == group) response,
          ],
        );

  factory CultureSurveyResponses.fromApi(
    Map<String, dynamic> map, {
    Random? random,
  }) {
    final builders = <String, _QuestionBuilder>{};
    final responses = <CultureResponse>[];
    for (final person in _list(map['respondentes'])) {
      final answers = <String, Map<String, dynamic>>{};
      for (final item in _list(person['respuestas'])) {
        final code = '${item['code'] ?? ''}';
        if (code.isEmpty) continue;
        final builder = builders.putIfAbsent(
          code,
          () => _QuestionBuilder(item),
        );
        final value = item['value'] is Map
            ? Map<String, dynamic>.from(item['value'] as Map)
            : <String, dynamic>{};
        builder.learn(value, '${item['lectura'] ?? ''}');
        answers[code] = value;
      }
      final group = '${person['grupo'] ?? ''}'.trim();
      responses.add(
        CultureResponse(answers: answers, group: group.isEmpty ? null : group),
      );
    }
    // El orden de llegada no debe delatar a nadie.
    responses.shuffle(random ?? Random.secure());
    return CultureSurveyResponses(
      questions: [for (final builder in builders.values) builder.build()],
      responses: responses,
    );
  }

  List<Map<String, dynamic>> _answersTo(CultureSurveyQuestion question) => [
    for (final response in responses) ?response.answers[question.code],
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
    return [
      for (final item in question.items)
        (
          item.label,
          _tally(question, [
            for (final answer in answers)
              if (answer['ratings'] is Map)
                '${(answer['ratings'] as Map)[item.id] ?? ''}',
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
    return [
      for (final option in question.options)
        (option.label, countIn('yes', option.id), countIn('no', option.id)),
    ]..sort((a, b) => (b.$2 - b.$3).compareTo(a.$2 - a.$3));
  }

  /// Respuestas abiertas, sin vacíos.
  List<String> texts(CultureSurveyQuestion question) => [
    for (final answer in _answersTo(question))
      if ('${answer['value_text'] ?? answer['value'] ?? ''}'.trim().isNotEmpty)
        '${answer['value_text'] ?? answer['value']}'.trim(),
  ];

  /// Resumen en texto de la respuesta de una persona a una pregunta.
  String describe(CultureSurveyQuestion question, CultureResponse response) {
    final answer = response.answers[question.code];
    if (answer == null) return '';
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
    if (order != null && order.isNotEmpty) {
      // Toda la escala, incluso los puntos que nadie eligió, en su orden.
      final ids = [for (final choice in order) choice.id];
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
  List<Object?> get props => [questions, responses];
}

// Arma una pregunta a partir de las respuestas. El API no manda el catálogo de
// opciones, así que las etiquetas se aprenden de la "lectura" de cada
// respuesta: en más/menos probable y sí/no, la dimensión entre paréntesis.
class _QuestionBuilder {
  _QuestionBuilder(Map<String, dynamic> item)
    : code = '${item['code']}',
      name = _text(item['name']),
      statement = '${item['statement'] ?? ''}',
      format = '${item['format'] ?? ''}';

  final String code;
  final String? name;
  final String statement;
  final String format;
  final _options = <String, String>{};
  final _items = <String, String>{};
  final _scale = <String, String>{};

  static const _scaleOrder = ['vive', 'medias', 'pared'];
  static final _parenthetical = RegExp(r'\(([^()]*)\)');

  void learn(Map<String, dynamic> value, String reading) {
    switch (format) {
      case 'single':
        final id = '${value['value'] ?? ''}';
        if (id.isNotEmpty && reading.isNotEmpty) _options[id] = reading;
      case 'most_least':
        final parts = reading.split('Menos probable:');
        _learnLast('${value['most'] ?? ''}', parts.first);
        if (parts.length > 1) {
          _learnLast(
            '${value['least'] ?? ''}',
            parts[1].split('Pronóstico').first,
          );
        }
      case 'pick_yes_no':
        final parts = reading.split('No espere:');
        _learnAll(value['yes'], parts.first);
        if (parts.length > 1) _learnAll(value['no'], parts[1]);
      case 'value_coherence':
        for (final item in _list(value['items'])) {
          final id = '${item['id'] ?? ''}';
          if (id.isNotEmpty) _items[id] = '${item['label'] ?? id}';
        }
        final ratings = value['ratings'] is Map
            ? Map<String, dynamic>.from(value['ratings'] as Map)
            : const <String, dynamic>{};
        for (final pair in reading.split(';')) {
          final split = pair.indexOf(':');
          if (split < 0) continue;
          final label = pair.substring(0, split).trim();
          final scaleLabel = pair.substring(split + 1).trim();
          final itemId = _items.entries
              .where((entry) => entry.value == label)
              .map((entry) => entry.key)
              .firstOrNull;
          final scaleId = itemId == null ? null : ratings[itemId];
          if (scaleId != null) _scale['$scaleId'] = scaleLabel;
        }
    }
  }

  void _learnLast(String id, String text) {
    final matches = _parenthetical.allMatches(text).toList();
    if (id.isEmpty || matches.isEmpty) return;
    _options[id] = matches.last.group(1)!.trim();
  }

  void _learnAll(Object? ids, String text) {
    if (ids is! List) return;
    final labels = [
      for (final match in _parenthetical.allMatches(text)) match.group(1)!,
    ];
    for (final (index, id) in ids.indexed) {
      if (index < labels.length) _options['$id'] = labels[index].trim();
    }
  }

  CultureSurveyQuestion build() {
    final scaleIds = _scale.keys.toList()
      ..sort((a, b) {
        int rank(String id) {
          final index = _scaleOrder.indexOf(id);
          return index < 0 ? _scaleOrder.length : index;
        }

        return rank(a).compareTo(rank(b));
      });
    return CultureSurveyQuestion(
      code: code,
      name: name,
      statement: statement,
      format: format,
      options: [
        for (final entry in _options.entries)
          CultureChoice(id: entry.key, label: entry.value),
      ],
      items: [
        for (final entry in _items.entries)
          CultureChoice(id: entry.key, label: entry.value),
      ],
      scale: [
        for (final id in scaleIds) CultureChoice(id: id, label: _scale[id]!),
      ],
    );
  }
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
