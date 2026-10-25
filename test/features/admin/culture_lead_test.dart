import 'package:flutter_test/flutter_test.dart';
import 'package:talex_platform/features/admin/data/datasources/admin_data_source.dart';
import 'package:talex_platform/features/admin/data/repositories/admin_repository_impl.dart';
import 'package:talex_platform/features/admin/domain/entities/admin_entities.dart';

void main() {
  test('CultureLead.fromMap parses arrays, nulls, and status safely', () {
    final lead = CultureLead.fromMap({
      'id': 42,
      'company_name': 'Empresa Demo TaleX',
      'employee_range': '11 – 50',
      'perceived_culture': ['Colaborativa', 'Innovadora'],
      'culture_comment': null,
      'email': 'demo.cultura@empresa.com',
      'consent_terms': true,
      'consent_data': 'true',
      'consent_payload': {'accepted': true},
      'utm_source': 'linkedin',
      'utm_medium': 'cpc',
      'utm_campaign': null,
      'source': 'mi-cultura',
      'status': 'new',
      'created_at': '2026-10-24T12:00:00.000Z',
    });

    expect(lead.id, '42');
    expect(lead.companyName, 'Empresa Demo TaleX');
    expect(lead.employeeRange, '11 – 50');
    expect(lead.perceivedCulture, ['Colaborativa', 'Innovadora']);
    expect(lead.cultureComment, isNull);
    expect(lead.email, 'demo.cultura@empresa.com');
    expect(lead.consentTerms, isTrue);
    expect(lead.consentData, isTrue);
    expect(lead.status, CultureLeadStatus.newLead);
    expect(lead.utmLabel, 'linkedin / cpc');
    expect(lead.toMap()['status'], 'new');
  });

  test('CultureLead.fromMap accepts a JSON string for perceived_culture', () {
    final lead = CultureLead.fromMap({
      'id': 'abc',
      'company_name': 'Acme',
      'employee_range': '1 – 10',
      'perceived_culture': '["Ágil","Cercana"]',
      'email': 'a@acme.com',
      'status': 'contacted',
    });

    expect(lead.perceivedCulture, ['Ágil', 'Cercana']);
    expect(lead.status, CultureLeadStatus.contacted);
  });

  test('in-memory admin can list and update culture lead status', () async {
    final source = InMemoryAdminDataSource();
    source.cultureLeads.add(
      CultureLead.fromMap({
        'id': '1',
        'company_name': 'Empresa Demo TaleX',
        'employee_range': '11 – 50',
        'perceived_culture': ['Colaborativa'],
        'email': 'demo.cultura@empresa.com',
        'status': 'new',
        'created_at': '2026-10-24T12:00:00.000Z',
      }),
    );
    final repository = AdminRepositoryImpl(source);

    final listed = await repository.listCultureLeads();
    listed.fold((failure) => fail(failure.message), (items) {
      expect(items, hasLength(1));
      expect(items.single.companyName, 'Empresa Demo TaleX');
      expect(items.single.status, CultureLeadStatus.newLead);
    });

    final updated = await repository.updateCultureLeadStatus(
      id: '1',
      status: CultureLeadStatus.contacted,
    );
    updated.fold((failure) => fail(failure.message), (_) {});

    final after = await repository.listCultureLeads();
    after.fold((failure) => fail(failure.message), (items) {
      expect(items.single.status, CultureLeadStatus.contacted);
    });
  });
}
