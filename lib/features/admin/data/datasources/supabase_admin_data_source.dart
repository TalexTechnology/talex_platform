import 'dart:typed_data';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:talex_platform/core/data/http_remote_database.dart';
import 'package:talex_platform/core/data/remote_database.dart';
import 'package:talex_platform/core/error/exceptions.dart';
import 'package:talex_platform/core/supabase/supabase_gateway.dart';
import 'package:talex_platform/features/admin/data/datasources/admin_data_source.dart';
import 'package:talex_platform/features/admin/domain/entities/admin_entities.dart';
import 'package:talex_platform/features/admin/domain/services/admin_alert_engine.dart';

final class SupabaseAdminDataSource implements AdminDataSource {
  SupabaseAdminDataSource(this._auth, {RemoteDatabase? database})
    : _db = database ?? HttpRemoteDatabase();

  final FirebaseAuth _auth;
  final RemoteDatabase _db;

  Future<T> _guard<T>(Future<T> Function() action) => guardSupabase(() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) throw const ServerException('Necesitas iniciar sesión.');
    return action();
  });

  String _orgPublicId(Map<String, dynamic> org) => publicEntityId(org);

  Company _company(
    Map<String, dynamic> org, {
    required List<TalentProcess> processes,
    required List<PersonEvaluation> people,
  }) {
    final id = _orgPublicId(org);
    final companyPeople = people.where((item) => item.companyId == id);
    final companyProcesses = processes.where((item) => item.companyId == id);
    return Company(
      id: id,
      name: (org['name'] as String?) ?? 'Empresa',
      logoUrl: org['logo_url'] as String?,
      website: org['website'] as String?,
      description: org['description'] as String?,
      nit: org['nit'] as String?,
      sector: org['sector'] as String?,
      size: org['size_label'] as String?,
      city: org['city'] as String?,
      region: org['region'] as String?,
      country: org['country'] as String?,
      status: CompanyStatus.values.firstWhere(
        (item) => item.name == org['status'],
        orElse: () => CompanyStatus.onboarding,
      ),
      createdAt: parseSupabaseDate(org['created_at']),
      lastActivityAt: parseOptionalSupabaseDate(org['last_activity_at']),
      activeProcesses: companyProcesses
          .where((item) => item.status == ProcessStatus.active)
          .length,
      invitedPeople: companyPeople.length,
      startedEvaluations: companyPeople
          .where((item) => item.status != EvaluationStatus.invited)
          .length,
      completedEvaluations: companyPeople
          .where((item) => item.status == EvaluationStatus.completed)
          .length,
      affinitiesDetected: companyPeople
          .where((item) => item.affinityScore != null)
          .length,
      plan: org['plan'] as String?,
      contractValue: (org['contract_value'] as num?)?.toDouble(),
      mrr: (org['mrr'] as num?)?.toDouble(),
      renewalAt: parseOptionalSupabaseDate(org['renewal_at']),
      commercialStage: DealStage.values
          .where((item) => item.name == org['commercial_stage'])
          .firstOrNull,
      archived: org['archived'] == true,
    );
  }

  EvaluationStatus _evaluationStatus(String? processStatus, bool completed) {
    if (completed || processStatus == 'completed') {
      return EvaluationStatus.completed;
    }
    return switch (processStatus) {
      'pending' => EvaluationStatus.invited,
      'rejected' => EvaluationStatus.abandoned,
      'inProgress' => EvaluationStatus.inProgress,
      _ => EvaluationStatus.started,
    };
  }

  Future<_AdminSnapshot> _snapshot() async {
    final results = await Future.wait([
      _db.from('organizations').select(),
      _db.from('vacancies').select(),
      _db.from('applications').select('*, persons(display_name, email)'),
      _db.from('evaluation_reports').select('application_id, score, level'),
      _db.from('activity_events').select().order('created_at', ascending: false),
      _db.from('deals').select(),
      _db.from('sales').select(),
    ]);
    final orgs = results[0].cast<Map<String, dynamic>>();
    final vacancies = results[1].cast<Map<String, dynamic>>();
    final applications = results[2].cast<Map<String, dynamic>>();
    final reports = results[3].cast<Map<String, dynamic>>();
    final events = results[4].cast<Map<String, dynamic>>();
    final deals = results[5].cast<Map<String, dynamic>>();
    final sales = results[6].cast<Map<String, dynamic>>();

    final orgById = {for (final org in orgs) '${org['id']}': org};
    final vacancyById = {for (final row in vacancies) '${row['id']}': row};
    final reportByApp = {
      for (final row in reports) '${row['application_id']}': row,
    };

    final processes = [
      for (final vacancy in vacancies)
        TalentProcess(
          id: publicEntityId(vacancy),
          companyId: _orgPublicId(
            orgById['${vacancy['organization_id']}'] ??
                {'id': vacancy['organization_id']},
          ),
          companyName:
              (orgById['${vacancy['organization_id']}']?['name'] as String?) ??
              '',
          name: (vacancy['name'] as String?) ?? 'Proceso',
          status: vacancy['status'] == 'closed'
              ? ProcessStatus.closed
              : ProcessStatus.active,
          createdAt: parseSupabaseDate(vacancy['created_at']),
          invitedPeople: applications
              .where((item) => item['vacancy_id'] == vacancy['id'])
              .length,
          startedEvaluations: applications
              .where(
                (item) =>
                    item['vacancy_id'] == vacancy['id'] &&
                    item['process_status'] != 'pending',
              )
              .length,
          completedEvaluations: applications
              .where(
                (item) =>
                    item['vacancy_id'] == vacancy['id'] &&
                    item['evaluation_completed'] == true,
              )
              .length,
          affinitiesDetected: applications
              .where(
                (item) =>
                    item['vacancy_id'] == vacancy['id'] &&
                    reportByApp['${item['id']}']?['score'] != null,
              )
              .length,
        ),
    ];

    final people = [
      for (final app in applications)
        PersonEvaluation(
          id: publicEntityId(app, firebaseKey: 'firebase_candidate_id'),
          displayName:
              ((app['persons'] as Map?)?['display_name'] as String?) ??
              ((app['persons'] as Map?)?['email'] as String?) ??
              'Persona',
          email: ((app['persons'] as Map?)?['email'] as String?) ?? '',
          companyId: _orgPublicId(
            orgById['${app['organization_id']}'] ??
                {'id': app['organization_id']},
          ),
          companyName:
              (orgById['${app['organization_id']}']?['name'] as String?) ?? '',
          processId: publicEntityId(
            vacancyById['${app['vacancy_id']}'] ?? {'id': app['vacancy_id']},
          ),
          processName: (app['vacancy_name'] as String?) ??
              (vacancyById['${app['vacancy_id']}']?['name'] as String?) ??
              '',
          status: _evaluationStatus(
            app['process_status'] as String?,
            app['evaluation_completed'] == true,
          ),
          updatedAt: parseSupabaseDate(app['updated_at']),
          affinityScore: (reportByApp['${app['id']}']?['score'] as num?)
              ?.toDouble(),
        ),
    ];

    final companies = [
      for (final org in orgs)
        _company(org, processes: processes, people: people),
    ];

    final mappedDeals = [
      for (final row in deals)
        Deal(
          id: '${row['id']}',
          companyId: _orgPublicId(
            orgById['${row['organization_id']}'] ??
                {'id': row['organization_id']},
          ),
          companyName:
              (orgById['${row['organization_id']}']?['name'] as String?) ?? '',
          stage: DealStage.values.firstWhere(
            (item) => item.name == row['stage'],
            orElse: () => DealStage.prospect,
          ),
          updatedAt: parseSupabaseDate(row['updated_at']),
          estimatedValue: (row['estimated_value'] as num?)?.toDouble(),
          ownerName: row['owner_name'] as String?,
          nextAction: row['next_action'] as String?,
          probability: (row['probability'] as num?)?.toDouble(),
        ),
    ];

    final mappedSales = [
      for (final row in sales)
        Sale(
          id: '${row['id']}',
          companyId: _orgPublicId(
            orgById['${row['organization_id']}'] ??
                {'id': row['organization_id']},
          ),
          companyName:
              (orgById['${row['organization_id']}']?['name'] as String?) ?? '',
          amount: (row['amount'] as num?)?.toDouble() ?? 0,
          soldAt: parseSupabaseDate(row['sold_at']),
          product: row['product'] as String?,
          recurring: row['recurring'] == true,
        ),
    ];

    final activity = [
      for (final row in events)
        ActivityEvent(
          id: '${row['id']}',
          kind: ActivityKind.values.firstWhere(
            (item) => item.name == row['kind'],
            orElse: () => ActivityKind.statusChanged,
          ),
          entityName: (row['entity_name'] as String?) ?? '',
          createdAt: parseSupabaseDate(row['created_at']),
          companyId: row['organization_id'] == null
              ? null
              : _orgPublicId(
                  orgById['${row['organization_id']}'] ??
                      {'id': row['organization_id']},
                ),
          statusLabel: row['status_label'] as String?,
          context: row['context'] as String?,
        ),
    ];

    return _AdminSnapshot(
      companies: companies,
      processes: processes,
      people: people,
      deals: mappedDeals,
      sales: mappedSales,
      activity: activity,
    );
  }

  Future<String> _orgUuid(String id) async {
    if (isUuid(id)) {
      final row = await _db
          .from('organizations')
          .select('id')
          .eq('id', id)
          .maybeSingle();
      if (row != null) return '${row['id']}';
    }
    final row = await _db
        .from('organizations')
        .select('id')
        .eq('firebase_id', id)
        .maybeSingle();
    if (row == null) throw const ServerException('No se encontró la empresa.');
    return '${row['id']}';
  }

  @override
  Future<AdminDashboardData> getDashboard() => _guard(() async {
    final snap = await _snapshot();
    final visible = snap.companies.where((item) => !item.archived).toList();
    return AdminDashboardData(
      metrics: AdminMetrics(
        totalCompanies: visible.length,
        activeCompanies: visible
            .where((item) => item.status == CompanyStatus.active)
            .length,
        evaluatedPeople: snap.people
            .where((item) => item.status != EvaluationStatus.invited)
            .length,
        completedEvaluations: snap.people
            .where((item) => item.status == EvaluationStatus.completed)
            .length,
        affinitiesDetected: snap.people
            .where((item) => item.affinityScore != null)
            .length,
        periodSales: snap.sales.fold<double>(0, (acc, item) => acc + item.amount),
        mrr: snap.sales
            .where((item) => item.recurring)
            .fold<double>(0, (acc, item) => acc + item.amount),
        companiesAtRisk: visible
            .where((item) => item.status == CompanyStatus.atRisk)
            .length,
      ),
      funnel: AdminFunnel(
        companies: visible.length,
        processes: snap.processes.length,
        invitedPeople: snap.people.length,
        startedEvaluations: snap.people
            .where((item) => item.status != EvaluationStatus.invited)
            .length,
        completedEvaluations: snap.people
            .where((item) => item.status == EvaluationStatus.completed)
            .length,
        affinitiesDetected: snap.people
            .where((item) => item.affinityScore != null)
            .length,
        decisions: snap.people.where((item) => item.affinityScore != null).length,
      ),
      activity: snap.activity,
      alerts: AdminAlertEngine.from(
        companies: visible,
        processes: snap.processes,
        people: snap.people,
        deals: snap.deals,
      ),
    );
  });

  @override
  Future<List<Company>> getCompanies({
    String query = '',
    CompanyStatus? status,
    bool archivedOnly = false,
  }) => _guard(() async {
    final snap = await _snapshot();
    return filterCompanies(
      snap.companies,
      query: query,
      status: status,
      archivedOnly: archivedOnly,
    );
  });

  @override
  Future<CompanyDetail> getCompany(String id) => _guard(() async {
    final snap = await _snapshot();
    final company = snap.companies.firstWhere(
      (item) => item.id == id,
      orElse: () => throw const ServerException('No se encontró la empresa.'),
    );
    return CompanyDetail(
      company: company,
      processes: snap.processes.where((item) => item.companyId == id).toList(),
      people: snap.people.where((item) => item.companyId == id).toList(),
      activity: snap.activity.where((item) => item.companyId == id).toList(),
    );
  });

  @override
  Future<List<TalentProcess>> getProcesses({
    String query = '',
    String? companyId,
    ProcessStatus? status,
  }) => _guard(() async {
    var items = (await _snapshot()).processes;
    if (companyId != null) {
      items = items.where((item) => item.companyId == companyId).toList();
    }
    if (status != null) {
      items = items.where((item) => item.status == status).toList();
    }
    final needle = query.trim().toLowerCase();
    if (needle.isNotEmpty) {
      items = items
          .where((item) => item.name.toLowerCase().contains(needle))
          .toList();
    }
    return items;
  });

  @override
  Future<List<PersonEvaluation>> getPeople({
    String query = '',
    String? companyId,
    EvaluationStatus? status,
  }) => _guard(() async {
    var items = (await _snapshot()).people;
    if (companyId != null) {
      items = items.where((item) => item.companyId == companyId).toList();
    }
    if (status != null) {
      items = items.where((item) => item.status == status).toList();
    }
    final needle = query.trim().toLowerCase();
    if (needle.isNotEmpty) {
      items = items
          .where(
            (item) =>
                item.displayName.toLowerCase().contains(needle) ||
                item.email.toLowerCase().contains(needle),
          )
          .toList();
    }
    return items;
  });

  @override
  Future<AffinitySummary> getAffinitySummary({String? companyId}) =>
      _guard(() async {
        var people = (await _snapshot()).people;
        if (companyId != null) {
          people = people.where((item) => item.companyId == companyId).toList();
        }
        return AffinitySummary(
          high: people.where((item) => item.band == AffinityBand.high).length,
          medium: people.where((item) => item.band == AffinityBand.medium).length,
          low: people.where((item) => item.band == AffinityBand.low).length,
          unknown: people
              .where((item) => item.band == AffinityBand.unknown)
              .length,
        );
      });

  @override
  Future<List<Deal>> getDeals({String query = '', DealStage? stage}) =>
      _guard(() async {
        var items = (await _snapshot()).deals;
        if (stage != null) {
          items = items.where((item) => item.stage == stage).toList();
        }
        final needle = query.trim().toLowerCase();
        if (needle.isNotEmpty) {
          items = items
              .where((item) => item.companyName.toLowerCase().contains(needle))
              .toList();
        }
        return items;
      });

  @override
  Future<(SalesSummary, List<Sale>)> getSales({
    required DateTime from,
    required DateTime to,
  }) => _guard(() async {
    final sales = (await _snapshot()).sales
        .where(
          (item) =>
              !item.soldAt.isBefore(from) && !item.soldAt.isAfter(to),
        )
        .toList();
    final total = sales.fold<double>(0, (acc, item) => acc + item.amount);
    return (
      SalesSummary(
        periodTotal: total,
        cumulativeTotal: total,
        newCustomers: sales.map((item) => item.companyId).toSet().length,
        averageTicket: sales.isEmpty ? 0 : total / sales.length,
        mrr: sales
            .where((item) => item.recurring)
            .fold<double>(0, (acc, item) => acc + item.amount),
      ),
      sales,
    );
  });

  @override
  Future<AnalyticsSnapshot> getAnalytics({
    required DateTime from,
    required DateTime to,
  }) => _guard(() async {
    final snap = await _snapshot();
    bool inRange(DateTime value) =>
        !value.isBefore(from) && !value.isAfter(to);
    return AnalyticsSnapshot(
      newCompanies: snap.companies.where((item) => inRange(item.createdAt)).length,
      activeCompanies: snap.companies
          .where((item) => item.status == CompanyStatus.active)
          .length,
      evaluatedPeople: snap.people
          .where((item) => item.status != EvaluationStatus.invited)
          .length,
      startedEvaluations: snap.people
          .where((item) => item.status != EvaluationStatus.invited)
          .length,
      completedEvaluations: snap.people
          .where((item) => item.status == EvaluationStatus.completed)
          .length,
      affinitiesDetected: snap.people
          .where((item) => item.affinityScore != null)
          .length,
      processesCreated: snap.processes
          .where((item) => inRange(item.createdAt))
          .length,
      processesClosed: snap.processes
          .where((item) => item.status == ProcessStatus.closed)
          .length,
    );
  });

  @override
  Future<List<AdminAlert>> getAlerts() async {
    final dashboard = await getDashboard();
    return dashboard.alerts;
  }

  @override
  Future<List<AdminUserAccount>> getUsers() => _guard(() async {
    final profiles = await _db
        .from('profiles')
        .select('id, firebase_uid, email, display_name, is_active, is_superadmin, memberships(role, legacy_role, organizations(name))');
    return [
      for (final row in profiles)
        AdminUserAccount(
          id: '${row['firebase_uid'] ?? row['id']}',
          email: (row['email'] as String?) ?? '',
          role: row['is_superadmin'] == true
              ? 'superadmin'
              : ((row['memberships'] as List?)?.isNotEmpty == true
                    ? '${(((row['memberships'] as List).first as Map)['legacy_role'] ?? ((row['memberships'] as List).first as Map)['role'])}'
                    : 'user'),
          isActive: row['is_active'] != false,
          displayName: row['display_name'] as String?,
          companyName:
              ((((row['memberships'] as List?)?.firstOrNull as Map?)?['organizations']
                      as Map?)?['name']
                  as String?),
        ),
    ];
  });

  @override
  Future<void> createCompany({
    required String name,
    required CompanyStatus status,
    String? plan,
  }) => _guard(() async {
    await _db.from('organizations').insert({
      'name': name.trim(),
      'status': status.name,
      'plan': plan,
      'archived': false,
    });
  });

  @override
  Future<void> createProcess({
    required String companyId,
    required String name,
  }) => _guard(() async {
    final orgId = await _orgUuid(companyId);
    await _db.from('vacancies').insert({
      'organization_id': orgId,
      'name': name.trim(),
      'status': 'active',
    });
  });

  @override
  Future<void> createPerson({
    required String companyId,
    required String processId,
    required String displayName,
    required EvaluationStatus status,
    double? affinityScore,
  }) => _guard(() async {
    final orgId = await _orgUuid(companyId);
    final vacancy = isUuid(processId)
        ? await _db.from('vacancies').select().eq('id', processId).maybeSingle()
        : await _db
              .from('vacancies')
              .select()
              .eq('firebase_id', processId)
              .maybeSingle();
    if (vacancy == null) {
      throw const ServerException('No se encontró el proceso.');
    }
    final email =
        '${displayName.trim().toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '.')}@talex.local';
    final person = await _db
        .from('persons')
        .insert({
          'email': email,
          'display_name': displayName.trim(),
        })
        .select()
        .single();
    await _db.from('applications').insert({
      'organization_id': orgId,
      'vacancy_id': vacancy['id'],
      'person_id': person['id'],
      'vacancy_name': vacancy['name'],
      'process_status': status == EvaluationStatus.completed
          ? 'completed'
          : status == EvaluationStatus.invited
          ? 'pending'
          : 'inProgress',
      'evaluation_completed': status == EvaluationStatus.completed,
    });
  });

  @override
  Future<void> createDeal({
    required String companyId,
    required DealStage stage,
    double? estimatedValue,
    String? ownerName,
    String? nextAction,
  }) => _guard(() async {
    final orgId = await _orgUuid(companyId);
    await _db.from('deals').insert({
      'organization_id': orgId,
      'stage': stage.name,
      'estimated_value': estimatedValue,
      'owner_name': ownerName,
      'next_action': nextAction,
    });
    await _db
        .from('organizations')
        .update({
          'commercial_stage': stage.name,
          'contract_value': estimatedValue,
        })
        .eq('id', orgId);
  });

  @override
  Future<void> createSale({
    required String companyId,
    required double amount,
    String? product,
    bool recurring = false,
  }) => _guard(() async {
    final orgId = await _orgUuid(companyId);
    await _db.from('sales').insert({
      'organization_id': orgId,
      'amount': amount,
      'product': product,
      'recurring': recurring,
    });
    if (recurring) {
      await _db.from('organizations').update({'mrr': amount}).eq('id', orgId);
    }
  });

  @override
  Future<void> updateUserRole({
    required String userId,
    required String role,
  }) => _guard(() async {
    if (role != 'user' && role != 'superadmin') {
      throw const ServerException('Rol no permitido.');
    }
    final query = _db
        .from('profiles')
        .update({'is_superadmin': role == 'superadmin'});
    if (isUuid(userId)) {
      await query.eq('id', userId);
    } else {
      await query.eq('firebase_uid', userId);
    }
  });

  @override
  Future<void> applyCompanyLifecycle({
    required String id,
    required CompanyLifecycleAction action,
  }) => _guard(() async {
    final orgId = await _orgUuid(id);
    final current = await _db
        .from('organizations')
        .select()
        .eq('id', orgId)
        .single();
    final payload = <String, dynamic>{};
    switch (action) {
      case CompanyLifecycleAction.disable:
        payload['archived'] = false;
        payload['status'] = CompanyStatus.inactive.name;
      case CompanyLifecycleAction.enable:
        payload['archived'] = false;
        payload['status'] = CompanyStatus.active.name;
      case CompanyLifecycleAction.archive:
        payload['archived'] = true;
        payload['status'] = CompanyStatus.inactive.name;
        payload['status_before_archive'] = current['status'];
        payload['archived_at'] = DateTime.now().toIso8601String();
      case CompanyLifecycleAction.restore:
        payload['archived'] = false;
        payload['status'] =
            current['status_before_archive'] ?? CompanyStatus.onboarding.name;
        payload['archived_at'] = null;
    }
    await _db.from('organizations').update(payload).eq('id', orgId);
  });

  @override
  Future<void> updatePerson({
    required String id,
    required String displayName,
    required EvaluationStatus status,
  }) => _guard(() async {
    final app = isUuid(id)
        ? await _db.from('applications').select().eq('id', id).maybeSingle()
        : await _db
              .from('applications')
              .select()
              .eq('firebase_candidate_id', id)
              .maybeSingle();
    if (app == null) return;
    await _db
        .from('persons')
        .update({'display_name': displayName.trim()})
        .eq('id', app['person_id']);
    await _db
        .from('applications')
        .update({
          'process_status': status == EvaluationStatus.completed
              ? 'completed'
              : status == EvaluationStatus.invited
              ? 'pending'
              : status == EvaluationStatus.abandoned
              ? 'rejected'
              : 'inProgress',
          'evaluation_completed': status == EvaluationStatus.completed,
        })
        .eq('id', app['id']);
  });

  @override
  Future<void> updateCompany({
    required Company company,
    List<int>? logoBytes,
    String? logoContentType,
  }) => _guard(() async {
    var logoUrl = company.logoUrl?.trim();
    if (logoUrl != null && logoUrl.isEmpty) logoUrl = null;
    final bytes = logoBytes == null ? null : Uint8List.fromList(logoBytes);
    if (bytes != null && bytes.isNotEmpty) {
      try {
        final ref = FirebaseStorage.instance.ref('company_logos/${company.id}');
        await ref
            .putData(
              bytes,
              SettableMetadata(contentType: logoContentType ?? 'image/png'),
            )
            .timeout(const Duration(seconds: 15));
        logoUrl = await ref.getDownloadURL().timeout(const Duration(seconds: 8));
      } on Object {
        // Keep the previous URL if Storage fails.
      }
    }
    final orgId = await _orgUuid(company.id);
    await _db
        .from('organizations')
        .update({
          'name': company.name.trim(),
          'nit': company.nit,
          'website': company.website,
          'logo_url': logoUrl,
          'description': company.description,
          'sector': company.sector,
          'size_label': company.size,
          'city': company.city,
          'country': company.country,
          'region': company.region,
          'status': company.status.name,
          'last_activity_at': DateTime.now().toIso8601String(),
        })
        .eq('id', orgId);
  });
}

class _AdminSnapshot {
  const _AdminSnapshot({
    required this.companies,
    required this.processes,
    required this.people,
    required this.deals,
    required this.sales,
    required this.activity,
  });
  final List<Company> companies;
  final List<TalentProcess> processes;
  final List<PersonEvaluation> people;
  final List<Deal> deals;
  final List<Sale> sales;
  final List<ActivityEvent> activity;
}
