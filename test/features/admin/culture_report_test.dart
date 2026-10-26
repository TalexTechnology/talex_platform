import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:talex_platform/core/theme/talex_theme.dart';
import 'package:talex_platform/features/admin/domain/entities/culture_report.dart';
import 'package:talex_platform/features/admin/presentation/pages/admin_culture_report_view.dart';
import 'package:talex_platform/l10n/app_localizations.dart';

CultureReport _fixture() => CultureReport.fromMap(
  jsonDecode(File('test/fixtures/culture_report.json').readAsStringSync())
      as Map<String, dynamic>,
);

void main() {
  test('reads the analyzed report', () {
    final report = _fixture();
    expect(report.hasReport, isTrue);
    expect(report.organizationName, 'EMpresa de Prueba');
    expect(report.coverage.reached, isTrue);
    expect(report.sealStatus, 'no_validada');
    expect(report.alignment, 88);
    expect(report.mirrorValues.first.leaders, 0.48);
    expect(report.declaredValues.last.verdict, 'solo_en_la_pared');
    expect(report.recommendations.map((item) => item.$1), [1, 2]);
    expect(report.doingBadly.single.$3, 13);
  });

  test('plain text drops technical marks from backend sentences', () {
    expect(
      plainReportText(
        'Cultura real (empleados n=15): Respeto por las personas. '
        'Sello: no_validada.',
      ),
      'Cultura real: Respeto por las personas. Sello: en camino.',
    );
    expect(
      plainReportText('Competitividad: brecha 0.23 (moderada). C01–C08. Líderes n=5; empleados n=15.'),
      'Competitividad: brecha 0.23.',
    );
  });

  test('humanizes report codes', () {
    expect(humanizeReportCode('no_validada'), 'No validada');
    expect(humanizeReportCode('30_dias'), '30 días');
  });

  test('a report still being collected has no analysis', () {
    final report = CultureReport.fromMap(const {
      'status': 'collecting',
      'coverage': {'respondents': 3, 'needed': 20, 'percent': 15},
    });
    expect(report.hasReport, isFalse);
    expect(report.coverage.respondents, 3);
  });

  testWidgets('renders every block without layout errors', (tester) async {
    tester.view.physicalSize = const Size(1400, 9000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        theme: talexLegacyTheme(),
        locale: const Locale('es'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: SingleChildScrollView(
            child: CultureReportBody(report: _fixture(), fallbackName: ''),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(
      find.text(
        'Aquí se vive respeto por las personas, no tanto orientación a resultados',
      ),
      findsOneWidget,
    );
    expect(find.text('Cultura cercana y innovadora'), findsOneWidget);
    expect(find.text('Paso 1'), findsOneWidget);
    // El sello TaleX está desactivado por ahora.
    expect(find.text('Sello en camino'), findsNothing);
    expect(find.text('Sello TaleX'), findsNothing);
    // Sin jerga técnica en pantalla.
    expect(find.textContaining('n=15'), findsNothing);
    expect(find.textContaining('C01–C08'), findsNothing);
    expect(find.textContaining('no_validada'), findsNothing);
  });

  testWidgets('fits a phone screen without overflow', (tester) async {
    tester.view.physicalSize = const Size(390, 12000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        theme: talexLegacyTheme(),
        locale: const Locale('es'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(18),
            child: CultureReportBody(report: _fixture(), fallbackName: ''),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}
