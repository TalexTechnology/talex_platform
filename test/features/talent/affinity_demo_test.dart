import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:talex_platform/features/talent/domain/services/affinity_demo_link.dart';
import 'package:talex_platform/features/talent/domain/services/assessment_catalog.dart';
import 'package:talex_platform/features/talent/presentation/pages/affinity_demo_page.dart';
import 'package:talex_platform/l10n/app_localizations.dart';
import 'package:talex_platform/l10n/app_localizations_es.dart';

void main() {
  test('recognizes the demo route by path or fragment', () {
    expect(
      AffinityDemoLink.matches(
        Uri.parse('https://platform.talex.com.co/afinidad/demo'),
      ),
      isTrue,
    );
    expect(
      AffinityDemoLink.matches(
        Uri.parse('https://platform.talex.com.co/#/afinidad/demo'),
      ),
      isTrue,
    );
    expect(
      AffinityDemoLink.matches(Uri.parse('https://platform.talex.com.co/')),
      isFalse,
    );
    expect(
      AffinityDemoLink.url(
        base: Uri.parse('https://platform.talex.com.co/#/x'),
      ),
      'https://platform.talex.com.co/afinidad/demo',
    );
  });

  // Sin TalentBloc en el árbol: si el demo intentara guardar algo, fallaría.
  testWidgets('the demo can be completed end to end without saving', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1200, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final l10n = AppLocalizationsEs();
    await tester.pumpWidget(
      const MaterialApp(
        locale: Locale('es'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: AffinityDemoPage(),
      ),
    );
    await tester.pumpAndSettle();

    // Bienvenida y pantalla de inicio con los datos de ejemplo.
    await tester.tap(find.text(l10n.respondentWelcomeAction));
    await tester.pumpAndSettle();
    expect(find.text(l10n.affinityDemoCompany), findsOneWidget);
    await tester.tap(find.text(l10n.startAssessment));
    await tester.pumpAndSettle();

    final total = AssessmentCatalog.allIds.length;
    for (var i = 0; i < total; i++) {
      expect(find.text(l10n.questionProgress(i + 1, total)), findsOneWidget);
      await tester.tap(find.byKey(ValueKey('answer-${i % 5 + 1}')));
      await tester.pumpAndSettle();
      await tester.tap(find.text(i == total - 1 ? l10n.finish : l10n.next));
      await tester.pumpAndSettle();
    }

    expect(find.text(l10n.assessmentFinishedTitle), findsOneWidget);
    await tester.tap(find.text(l10n.surveyResultRequest));
    await tester.pumpAndSettle();
    expect(find.text(l10n.surveyResultRequested), findsOneWidget);

    // "Cerrar sesión" reinicia el demo.
    await tester.tap(find.text(l10n.signOut));
    await tester.pumpAndSettle();
    expect(find.text(l10n.respondentWelcomeAction), findsOneWidget);
  });
}
