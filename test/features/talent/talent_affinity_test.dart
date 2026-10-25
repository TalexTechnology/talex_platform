import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:talex_platform/core/auth/user_role.dart';
import 'package:talex_platform/features/talent/domain/entities/talent_entities.dart';
import 'package:talex_platform/features/talent/domain/services/dna_catalog.dart';
import 'package:talex_platform/features/talent/domain/services/pin_hasher.dart';
import 'package:talex_platform/features/talent/presentation/company_options.dart';
import 'package:talex_platform/l10n/app_localizations_en.dart';
import 'package:talex_platform/l10n/app_localizations_es.dart';

void main() {
  group('PinHasher', () {
    test('is stable for the same pin and email', () {
      expect(
        PinHasher.hash('123456', 'Ada@TaleX.com'),
        PinHasher.hash('123456', 'ada@talex.com'),
      );
    });

    test('changes when the pin changes', () {
      expect(
        PinHasher.hash('123456', 'ada@talex.com'),
        isNot(PinHasher.hash('654321', 'ada@talex.com')),
      );
    });
  });

  group('affinityLevelFromAverage', () {
    test('maps qualitative levels without percentages', () {
      expect(affinityLevelFromAverage(null), AffinityLevel.unknown);
      expect(affinityLevelFromAverage(4), AffinityLevel.high);
      expect(affinityLevelFromAverage(3), AffinityLevel.medium);
      expect(affinityLevelFromAverage(2.9), AffinityLevel.low);
    });
  });

  test('Colombia location data includes 32 departments', () {
    final raw = File('assets/location/colombia.json').readAsStringSync();
    final data = jsonDecode(raw) as List<dynamic>;
    expect(data, hasLength(32));
    final names = [
      for (final item in data) (item as Map)['departamento'] as String,
    ];
    expect(names, containsAll(['Antioquia', 'Cundinamarca', 'Valle del Cauca']));
  });

    test('company culture is present when the survey left values or culture', () {
    const empty = CompanyProfile(id: 'c1', name: 'Acme');
    expect(empty.hasCompanyDna, isFalse);
    const filled = CompanyProfile(
      id: 'c1',
      name: 'Acme',
      values: 'Integridad',
      culture: 'Colaboración',
      standoutPeople: 'Autonomía',
    );
    expect(filled.hasCompanyDna, isTrue);
    expect(
      const CompanyProfile(id: 'c1', name: 'Acme', values: 'Respeto').hasCompanyDna,
      isTrue,
    );
  });

  test('DNA catalog includes shared presets for values, culture and standout', () {
    expect(dnaValuePresets, isNotEmpty);
    expect(dnaCulturePresets, isNotEmpty);
    expect(dnaStandoutPresets, isNotEmpty);
    expect(
      dnaValueOptions(languageCode: 'es'),
      containsAll(['Integridad', 'Transparencia', 'Inclusión']),
    );
    expect(
      dnaCultureOptions(languageCode: 'en'),
      containsAll(['Agile', 'Data-driven', 'Customer-centered']),
    );
  });

  test('recruiter PIN expires after 15 minutes', () {
    final now = DateTime(2026, 9, 1, 12);
    expect(
      InvitePin.isExpired(
        expiresAt: now.add(const Duration(minutes: 14)),
        now: now,
      ),
      isFalse,
    );
    expect(
      InvitePin.isExpired(
        expiresAt: now.subtract(const Duration(seconds: 1)),
        now: now,
      ),
      isTrue,
    );
    expect(InvitePin.lifetime, const Duration(minutes: 15));
  });

  test('team list excludes respondents', () {
    expect(
      isCompanyStaffInvite(kind: 'recruiter', role: 'recruiter'),
      isTrue,
    );
    expect(
      isCompanyStaffInvite(kind: 'recruiter', role: 'company_admin'),
      isTrue,
    );
    expect(
      isCompanyStaffInvite(kind: 'respondent', role: 'respondent'),
      isFalse,
    );
    expect(isCompanyStaffInvite(kind: null, role: 'respondent'), isFalse);
    expect(UserRoleX.parse('company_lead'), UserRole.companyLead);
    expect(UserRoleX.parse('hiring_manager').isCompanyStaffRole, isTrue);
  });

  test('vacancy areas follow the company sector', () {
    final l10n = AppLocalizationsEs();
    final tech = vacancyAreasForSector(l10n, l10n.technologyIndustry);
    expect(tech.map((item) => item.label), contains(l10n.areaEngineering));
    expect(tech.map((item) => item.label), contains(l10n.areaPeople));
    final health = vacancyAreasForSector(l10n, l10n.sectorHealth);
    expect(health.map((item) => item.label), contains(l10n.areaClinical));
    expect(health.map((item) => item.label), isNot(contains(l10n.areaEngineering)));
    expect(vacancyWorkModeNeedsCity(VacancyWorkMode.onsite), isTrue);
    expect(vacancyWorkModeNeedsCity(VacancyWorkMode.remote), isFalse);
    expect(vacancyWorkModeNeedsCity(VacancyWorkMode.hybrid), isTrue);
    expect(
      resolveCompanySizeId('1–10 empleados', AppLocalizationsEn()),
      CompanySizeId.size1to10,
    );
    expect(
      vacancySeniorityLabel(AppLocalizationsEn(), VacancySeniority.mid),
      'Intermediate',
    );
    expect(
      vacancySeniorityLabel(l10n, VacancySeniority.mid),
      'Intermedio',
    );
  });
}
