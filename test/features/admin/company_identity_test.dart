import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:talex_platform/core/utils/website_uri.dart';
import 'package:talex_platform/features/admin/domain/entities/admin_entities.dart';
import 'package:talex_platform/features/admin/presentation/widgets/admin_widgets.dart';
import 'package:talex_platform/l10n/app_localizations.dart';

void main() {
  test('websiteUri accepts a real site and ignores placeholder text', () {
    expect(websiteUri('talex.com.co')?.toString(), 'https://talex.com.co');
    expect(websiteUri('https://www.3ox.co'), Uri.parse('https://www.3ox.co'));
    expect(websiteUri('Sin sitio web'), isNull);
    expect(websiteUri(''), isNull);
    expect(websiteUri('hola'), isNull);
  });

  testWidgets('company identity shows logo, description and visit link together', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('es'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: CompanyIdentityCard(
            company: Company(
              id: '1',
              name: 'Empresa de prueba',
              status: CompanyStatus.onboarding,
              createdAt: DateTime(2026, 9, 10),
              website: 'talex.com.co',
              description: 'Esta es una descripcion de prueba',
              city: 'Funza',
              region: 'Cundinamarca',
              country: 'Colombia',
            ),
          ),
        ),
      ),
    );

    expect(find.text('PERFIL DE EMPRESA'), findsOneWidget);
    expect(find.text('Empresa de prueba'), findsOneWidget);
    expect(find.text('Funza · Cundinamarca · Colombia'), findsOneWidget);
    expect(find.text('Esta es una descripcion de prueba'), findsOneWidget);
    expect(
      find.text('Visitar sitio web · https://talex.com.co'),
      findsOneWidget,
    );
  });

  testWidgets('placeholder website is not shown as a link', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('es'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: CompanyIdentityCard(
            company: Company(
              id: '1',
              name: 'Gabriel',
              status: CompanyStatus.onboarding,
              createdAt: DateTime(2026, 9, 10),
              website: 'Sin sitio web',
            ),
          ),
        ),
      ),
    );

    expect(find.textContaining('Visitar sitio web'), findsNothing);
  });
}
