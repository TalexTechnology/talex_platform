import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:talex_platform/features/admin/domain/entities/assessment_question.dart';
import 'package:talex_platform/features/admin/domain/services/assessment_question_defaults.dart';
import 'package:talex_platform/features/admin/presentation/widgets/admin_question_dialogs.dart';
import 'package:talex_platform/features/admin/presentation/widgets/survey_preview_dialog.dart';
import 'package:talex_platform/l10n/app_localizations.dart';

Future<void> _open(
  WidgetTester tester,
  Size size,
  Future<void> Function(BuildContext context) show,
) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      locale: const Locale('es'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Builder(
        builder: (context) => TextButton(
          onPressed: () => show(context),
          child: const Text('open'),
        ),
      ),
    ),
  );
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
}

void main() {
  const all = AssessmentQuestionDefaults.all;

  for (final size in const [Size(1280, 800), Size(380, 700)]) {
    testWidgets('preview walks pair and experience questions at $size', (
      tester,
    ) async {
      await _open(
        tester,
        size,
        (context) => showSurveyPreview(context, all, startCode: 'N12'),
      );
      expect(find.text('Pregunta 40 de 48'), findsOneWidget);
      expect(find.text(all[39].statementB), findsOneWidget);
      expect(find.text('20 s'), findsOneWidget);
      expect(find.text('A'), findsNothing);
      expect(find.text('B'), findsNothing);
      Color fill() => tester
          .widget<Material>(
            find
                .ancestor(
                  of: find.byKey(const ValueKey('scale-2')),
                  matching: find.byType(Material),
                )
                .first,
          )
          .color!;
      expect(fill(), Colors.white);
      await tester.ensureVisible(find.byKey(const ValueKey('scale-2')));
      await tester.tap(find.byKey(const ValueKey('scale-2')));
      await tester.pump();
      expect(fill(), isNot(Colors.white));
      expect(find.text('Más la A que la B'), findsNothing);
      await tester.pump(const Duration(seconds: 20));
      expect(find.text('Tiempo agotado'), findsOneWidget);

      await tester.tap(find.text('Siguiente'));
      await tester.pumpAndSettle();
      expect(find.text('Pregunta 41 de 48'), findsOneWidget);
      expect(find.text(all[40].statementA), findsOneWidget);
      expect(find.text('Nunca'), findsOneWidget);
      expect(find.text('Siempre'), findsOneWidget);
      await tester.ensureVisible(find.byKey(const ValueKey('scale-4')));
      await tester.tap(find.byKey(const ValueKey('scale-4')));
      await tester.pump();
      expect(find.text('Con frecuencia'), findsOneWidget);
      expect(find.byIcon(Icons.timer_outlined), findsNothing);
    });
  }

  testWidgets('preview skips inactive questions', (tester) async {
    final questions = [
      all[0],
      AssessmentQuestion(
        code: all[1].code,
        order: 2,
        front: all[1].front,
        format: all[1].format,
        dimensionA: all[1].dimensionA,
        instruction: all[1].instruction,
        statementA: all[1].statementA,
        options: all[1].options,
        active: false,
      ),
    ];
    await _open(
      tester,
      const Size(1280, 800),
      (context) => showSurveyPreview(context, questions),
    );
    expect(find.text('Pregunta 1 de 1'), findsOneWidget);
    expect(find.text('Reiniciar'), findsOneWidget);
  });

  testWidgets('editor creates a question and rejects a duplicate code', (
    tester,
  ) async {
    AssessmentQuestion? result;
    await _open(tester, const Size(1280, 1400), (context) async {
      result = await showAssessmentQuestionEditor(context, existing: all);
    });
    expect(find.text('V29'), findsOneWidget);
    await tester.enterText(find.widgetWithText(TextFormField, 'Código'), 'v01');
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Dimensión A'),
      'Estabilidad',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Dimensión B'),
      'Autonomía',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Enunciado A'),
      'Frase A',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Enunciado B'),
      'Frase B',
    );
    await tester.tap(find.text('Guardar cambios'));
    await tester.pumpAndSettle();
    expect(
      find.text('Ya existe una pregunta con este código.'),
      findsOneWidget,
    );
    expect(result, isNull);

    await tester.enterText(find.widgetWithText(TextFormField, 'Código'), 'v29');
    await tester.tap(find.text('Guardar cambios'));
    await tester.pumpAndSettle();
    expect(result?.code, 'V29');
    expect(result?.order, 49);
    expect(result?.timeLimitSeconds, 20);
    expect(result?.options, AssessmentQuestionDefaults.pairOptions);
  });
}
