import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:talex_platform/features/culture/data/culture_survey_api.dart';
import 'package:talex_platform/features/admin/domain/entities/culture_organization_report.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'tracking reuses a visitor across reloads and separates companies',
    () async {
      SharedPreferences.setMockInitialValues({});
      final bodies = <Map<String, dynamic>>[];
      final client = MockClient((request) async {
        bodies.add(jsonDecode(request.body) as Map<String, dynamic>);
        return http.Response('{}', 200);
      });
      final api = CultureSurveyApi(httpClient: client);
      await api.track('company-a', 'opened');
      await api.track('company-a', 'started');
      final reloaded = CultureSurveyApi(httpClient: client);
      await reloaded.track('company-a', 'opened');
      await reloaded.track('company-b', 'opened');
      expect(bodies[0]['visitorId'], bodies[1]['visitorId']);
      expect(bodies[0]['visitId'], bodies[1]['visitId']);
      expect(bodies[0]['visitorId'], bodies[2]['visitorId']);
      expect(bodies[0]['visitId'], isNot(bodies[2]['visitId']));
      expect(bodies[2]['visitorId'], isNot(bodies[3]['visitorId']));
    },
  );

  test('metrics failure does not block the survey', () async {
    SharedPreferences.setMockInitialValues({});
    final api = CultureSurveyApi(
      httpClient: MockClient((_) async {
        throw Exception('offline');
      }),
    );
    await expectLater(api.track('company-a', 'opened'), completes);
  });

  test('admin supports old records and exact headcount with tracking', () {
    final legacy = CultureOrganizationGroup.fromMap({
      'organization': {'id': 'old', 'size_label': '1 – 50'},
    });
    expect(legacy.employeeLabel, '1 – 50');
    expect(legacy.tracking.visits, 0);
    expect(legacy.tracking.sharedConfirmedAt, isNull);
    final current = CultureOrganizationGroup.fromMap({
      'organization': {
        'id': 'new',
        'employee_count': 35,
        'size_label': '1 – 50',
      },
      'surveyRespondents': 7,
      'tracking': {
        'visits': 12,
        'uniqueVisitors': 9,
        'startedVisits': 8,
        'sharedConfirmedAt': '2026-11-03T17:00:00.000Z',
      },
    });
    expect(current.employeeLabel, '35');
    expect(current.tracking.uniqueVisitors, 9);
    expect(current.surveyRespondents, 7);
    expect(current.tracking.sharedConfirmedAt, isNotNull);
  });
}
