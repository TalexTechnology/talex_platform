import 'package:flutter_test/flutter_test.dart';
import 'package:talex_platform/features/admin/data/datasources/assessment_question_data_source.dart';
import 'package:talex_platform/features/admin/domain/entities/assessment_question.dart';
import 'package:talex_platform/features/admin/domain/services/assessment_question_csv.dart';
import 'package:talex_platform/features/admin/domain/services/assessment_question_defaults.dart';
import 'package:talex_platform/features/admin/presentation/widgets/admin_question_dialogs.dart';

void main() {
  const all = AssessmentQuestionDefaults.all;

  test('base catalog holds the 48 questions of the three fronts', () {
    int count(AssessmentFront front) =>
        all.where((item) => item.front == front).length;
    expect(all, hasLength(48));
    expect(count(AssessmentFront.coreValues), 28);
    expect(count(AssessmentFront.needs), 12);
    expect(count(AssessmentFront.capabilities), 8);
    expect(all.map((item) => item.code).toSet(), hasLength(48));
    expect(all.map((item) => item.order), List.generate(48, (i) => i + 1));
  });

  test('pairs carry two statements and a time limit, experience does not', () {
    for (final question in all) {
      expect(question.options, hasLength(5));
      expect(question.statementA, isNotEmpty);
      expect(question.statementB.isNotEmpty, question.isPair);
      expect(question.dimensionB.isNotEmpty, question.isPair);
      expect(question.timeLimitSeconds, question.isPair ? 20 : null);
    }
  });

  test('questions survive the Firestore map round trip', () {
    for (final question in all) {
      expect(
        assessmentQuestionFromMap(
          question.code,
          assessmentQuestionToMap(question),
        ),
        question,
      );
    }
  });

  test('questions survive the Postgres bank payload Gemini reads', () {
    final question = all.first;
    expect(
      assessmentQuestionFromMap(question.code, {
        'code': question.code,
        'order': question.order,
        'front': question.front.key,
        'format': question.format.name,
        'dimensionA': question.dimensionA,
        'dimensionB': question.dimensionB,
        'instruction': question.instruction,
        'statementA': question.statementA,
        'statementB': question.statementB,
        'options': question.options,
        'timeLimitSeconds': question.timeLimitSeconds,
        'active': question.active,
      }),
      question,
    );
  });

  test('new codes continue the numbering of their front', () {
    expect(suggestQuestionCode(AssessmentFront.coreValues, all), 'V29');
    expect(suggestQuestionCode(AssessmentFront.needs, all), 'N13');
    expect(suggestQuestionCode(AssessmentFront.capabilities, const []), 'C01');
  });

  group('CSV import', () {
    const header =
        'n,codigo,frente,dimension_A,dimension_B,formato,instruccion,'
        'enunciado_A,enunciado_B,opcion_1,opcion_2,opcion_3,opcion_4,opcion_5,'
        'tiempo_limite_seg';

    test('reads the template format, quotes and option prefixes', () {
      final questions = AssessmentQuestionCsv.parse(
        '﻿$header\r\n'
        '29,n01,2 · Necesidades,Pago,Estabilidad,Par de enunciados,'
        '"Si tuviera que elegir, ¿cuál?",Frase A,"Frase ""B""",'
        '1 = Claramente la A,2 = Más la A que la B,3 = Ambas por igual,'
        '4 = Más la B que la A,5 = Claramente la B,20\r\n'
        '\r\n'
        '41,C01,3 · Capacidades,Conocimiento,,Enunciado de experiencia,'
        'Instrucción,He resuelto problemas,,1 = Nunca,2 = Rara vez,'
        '3 = Algunas veces,4 = Con frecuencia,5 = Siempre,\r\n',
      );
      expect(questions, hasLength(2));
      final pair = questions.first;
      expect(pair.code, 'N01');
      expect(pair.order, 29);
      expect(pair.front, AssessmentFront.needs);
      expect(pair.isPair, isTrue);
      expect(pair.instruction, 'Si tuviera que elegir, ¿cuál?');
      expect(pair.statementB, 'Frase "B"');
      expect(pair.options, AssessmentQuestionDefaults.pairOptions);
      expect(pair.timeLimitSeconds, 20);
      final experience = questions.last;
      expect(experience.front, AssessmentFront.capabilities);
      expect(experience.isPair, isFalse);
      expect(experience.options, AssessmentQuestionDefaults.frequencyOptions);
      expect(experience.timeLimitSeconds, isNull);
    });

    test('accepts semicolon files with only the required columns', () {
      final questions = AssessmentQuestionCsv.parse(
        'codigo;frente;enunciado_A;enunciado_B\n'
        'V01;1 · Valores;Frase A;Frase B\n'
        'C01;Capacidades;He hecho algo;\n',
      );
      expect(questions.map((item) => item.order), [1, 2]);
      expect(questions.first.isPair, isTrue);
      expect(
        questions.first.instruction,
        AssessmentQuestionDefaults.valuesInstruction,
      );
      expect(questions.last.isPair, isFalse);
      expect(
        questions.last.options,
        AssessmentQuestionDefaults.frequencyOptions,
      );
    });

    AssessmentCsvException failure(String csv) {
      try {
        AssessmentQuestionCsv.parse(csv);
      } on AssessmentCsvException catch (error) {
        return error;
      }
      fail('expected an AssessmentCsvException');
    }

    test('reports what is wrong and where', () {
      expect(failure('').error, AssessmentCsvError.empty);
      expect(failure('$header\n').error, AssessmentCsvError.empty);
      final columns = failure('codigo,frente\nV01,1\n');
      expect(columns.error, AssessmentCsvError.missingColumns);
      expect(columns.detail, 'enunciado_a');
      final invalid = failure(
        'codigo,frente,enunciado_A\nV01,1,Frase\n,1,Otra\n',
      );
      expect(invalid.error, AssessmentCsvError.invalidRow);
      expect(invalid.row, 3);
      final duplicate = failure(
        'codigo,frente,enunciado_A\nV01,1,Frase\nv01,1,Otra\n',
      );
      expect(duplicate.error, AssessmentCsvError.duplicate);
      expect(duplicate.detail, 'V01');
    });
  });
}
