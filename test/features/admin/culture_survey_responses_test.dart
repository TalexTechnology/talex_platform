import 'package:flutter_test/flutter_test.dart';
import 'package:talex_platform/features/admin/domain/entities/culture_survey_responses.dart';

void main() {
  final data = CultureSurveyResponses.fromMap({
    'title': 'Encuesta',
    'questions': [
      {
        'code': 'Q1',
        'statement': '¿Cómo se decide?',
        'format': 'single',
        'options': [
          {'id': 'a', 'label': 'Consenso'},
          {'id': 'b', 'label': 'Jefe'},
        ],
      },
      {
        'code': 'Q2',
        'statement': 'Más y menos probable',
        'format': 'most_least',
        'options': [
          {'id': 'x', 'label': 'X'},
          {'id': 'y', 'label': 'Y'},
        ],
      },
      {
        'code': 'Q3',
        'statement': 'Valores',
        'format': 'value_coherence',
        'items': [
          {'id': 'v1', 'label': 'Respeto'},
        ],
        'scale': [
          {'id': 'vive', 'label': 'Se vive'},
          {'id': 'pared', 'label': 'Solo en la pared'},
        ],
      },
      {'code': 'Q4', 'statement': 'Frase', 'format': 'text'},
    ],
    'responses': [
      {
        'answers': {
          'Q1': {'value': 'a'},
          'Q2': {'most': 'x', 'least': 'y', 'forecast': 40},
          'Q3': {
            'ratings': {'v1': 'vive'},
          },
          'Q4': {'value_text': 'Nos ayudamos'},
        },
      },
      {
        'answers': {
          'Q1': {'value': 'a'},
          'Q2': {'most': 'y', 'least': 'x', 'forecast': 60},
          'Q3': {
            'ratings': {'v1': 'pared'},
          },
          'Q4': {'value_text': ' '},
        },
      },
    ],
  });

  test('counts single choice including options nobody picked', () {
    final question = data.questions[0];
    expect(data.respondentCount, 2);
    expect(data.single(question), const [
      CultureTally(label: 'Consenso', count: 2),
      CultureTally(label: 'Jefe', count: 0),
    ]);
  });

  test('splits most and least likely and averages the forecast', () {
    final result = data.mostLeast(data.questions[1]);
    expect(result.most.map((t) => t.count), [1, 1]);
    expect(result.least.map((t) => t.count), [1, 1]);
    expect(result.forecast, 50);
  });

  test('distributes value ratings on the scale order', () {
    final [(label, tallies)] = data.coherence(data.questions[2]);
    expect(label, 'Respeto');
    expect(tallies.map((t) => t.label), ['Se vive', 'Solo en la pared']);
    expect(tallies.map((t) => t.count), [1, 1]);
  });

  test('keeps only non-empty open answers', () {
    expect(data.texts(data.questions[3]), ['Nos ayudamos']);
  });

  test('describes one person answer with labels, not ids', () {
    expect(data.describe(data.questions[0], data.responses.first), 'Consenso');
    expect(
      data.describe(data.questions[2], data.responses.first),
      'Respeto: Se vive',
    );
  });
}
