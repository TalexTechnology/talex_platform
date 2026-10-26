import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:talex_platform/features/admin/domain/entities/culture_survey_responses.dart';

// Recorte del formato real de GET /api/cultura/{id}/respuestas.
Map<String, dynamic> _payload() => {
  'organizationId': 'org-1',
  'organizationName': 'Empresa de prueba',
  'respondentes': [
    {
      'respondente': 'persona_1',
      'sessionId': 'a13fde14',
      'completedAt': '2026-10-26T01:37:12.687Z',
      'grupo': 'empleado',
      'respuestas': [
        {
          'code': 'A01',
          'name': 'Complete la frase',
          'statement': 'Complete la frase',
          'format': 'text',
          'value': {'value_text': 'quiere aprender'},
          'lectura': 'quiere aprender',
        },
        {
          'code': 'C02',
          'name': 'El último ascenso',
          'statement': '¿Qué pesó más?',
          'format': 'most_least',
          'value': {'most': 'innovacion', 'least': 'personas', 'forecast': 75},
          'lectura':
              'Más probable: Se atrevió con una idea nueva (Innovación y riesgo). '
              'Menos probable: Su equipo la aprecia (Respeto por las personas). '
              'Pronóstico 75%.',
        },
        {
          'code': 'D01',
          'name': 'El letrero honesto',
          'statement': '¿Cuáles se viven?',
          'format': 'value_coherence',
          'value': {
            'ratings': {'colaborativa': 'vive', 'exigente': 'pared'},
            'items': [
              {'id': 'colaborativa', 'label': 'Colaborativa'},
              {'id': 'exigente', 'label': 'Exigente'},
            ],
          },
          'lectura': 'Colaborativa: Se vive; Exigente: Solo en la pared',
        },
        {
          'code': 'K02',
          'name': 'Su lugar',
          'statement': '¿Cuál describe mejor su rol?',
          'format': 'single',
          'value': {'value': 'profesional'},
          'lectura': 'Profesional o técnico',
        },
        {
          'code': 'O01',
          'name': 'Lo que gana uno',
          'statement': '¿Qué 4 cosas le diría?',
          'format': 'pick_yes_no',
          'value': {
            'yes': ['crecimiento', 'autonomia'],
            'no': ['carga'],
          },
          'lectura':
              'Sí ofrece: Posibilidad real de subir (Crecimiento profesional), '
              'Libertad para organizarse (Autonomía). '
              'No espere: Salir a una hora razonable (Carga de trabajo sostenible).',
        },
      ],
    },
    {
      'respondente': 'persona_2',
      'sessionId': '10b239c2',
      'completedAt': '2026-10-26T01:33:54.892Z',
      'grupo': 'lider',
      'respuestas': [
        {
          'code': 'C02',
          'name': 'El último ascenso',
          'statement': '¿Qué pesó más?',
          'format': 'most_least',
          'value': {
            'most': 'competitividad',
            'least': 'personas',
            'forecast': 25,
          },
          'lectura':
              'Más probable: Le ganó un cliente (Competitividad). '
              'Menos probable: Su equipo la aprecia (Respeto por las personas). '
              'Pronóstico 25%.',
        },
        {
          'code': 'D01',
          'name': 'El letrero honesto',
          'statement': '¿Cuáles se viven?',
          'format': 'value_coherence',
          'value': {
            'ratings': {'colaborativa': 'medias', 'exigente': 'pared'},
            'items': [
              {'id': 'colaborativa', 'label': 'Colaborativa'},
              {'id': 'exigente', 'label': 'Exigente'},
            ],
          },
          'lectura': 'Colaborativa: A medias; Exigente: Solo en la pared',
        },
        {
          'code': 'K02',
          'name': 'Su lugar',
          'statement': '¿Cuál describe mejor su rol?',
          'format': 'single',
          'value': {'value': 'jefe'},
          'lectura': 'Jefe o coordinador',
        },
      ],
    },
  ],
};

void main() {
  final data = CultureSurveyResponses.fromApi(_payload(), random: Random(1));
  CultureSurveyQuestion question(String code) =>
      data.questions.firstWhere((item) => item.code == code);

  test('reads every respondent and their group, without session data', () {
    expect(data.respondentCount, 2);
    expect(data.countOf(CultureSurveyResponses.leaders), 1);
    expect(data.countOf(CultureSurveyResponses.employees), 1);
    expect(data.only(CultureSurveyResponses.leaders).respondentCount, 1);
    expect(
      data.questions.map((item) => item.code),
      ['A01', 'C02', 'D01', 'K02', 'O01'],
    );
  });

  test('learns dimension labels from the reading of most/least', () {
    final result = data.mostLeast(question('C02'));
    expect(result.least, const [
      CultureTally(label: 'Respeto por las personas', count: 2),
    ]);
    expect(
      result.most.map((tally) => tally.label),
      containsAll(['Innovación y riesgo', 'Competitividad']),
    );
    expect(result.forecast, 50);
  });

  test('orders the value scale and counts each rating', () {
    final rows = data.coherence(question('D01'));
    final (label, tallies) = rows.first;
    expect(label, 'Colaborativa');
    expect(tallies.map((t) => t.label), [
      'Se vive',
      'A medias',
      'Solo en la pared',
    ]);
    expect(tallies.map((t) => t.count), [1, 1, 0]);
    expect(rows.last.$2.last, const CultureTally(
      label: 'Solo en la pared',
      count: 2,
    ));
  });

  test('labels single choices with the reading and yes/no with dimensions', () {
    expect(
      data.single(question('K02')).map((t) => t.label),
      containsAll(['Profesional o técnico', 'Jefe o coordinador']),
    );
    expect(data.yesNo(question('O01')), [
      ('Crecimiento profesional', 1, 0),
      ('Autonomía', 1, 0),
      ('Carga de trabajo sostenible', 0, 1),
    ]);
  });

  test('keeps open answers and describes a person with labels', () {
    expect(data.texts(question('A01')), ['quiere aprender']);
    final employee = data.responses.firstWhere(
      (response) => response.group == CultureSurveyResponses.employees,
    );
    expect(data.describe(question('K02'), employee), 'Profesional o técnico');
  });
}
