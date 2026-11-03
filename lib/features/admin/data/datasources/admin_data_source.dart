import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:talex_platform/core/error/exceptions.dart';
import 'package:talex_platform/features/admin/domain/entities/admin_entities.dart';
import 'package:talex_platform/features/admin/domain/services/admin_alert_engine.dart';

abstract interface class AdminDataSource {
  Future<AdminDashboardData> getDashboard();
  Future<List<Company>> getCompanies({
    String query,
    CompanyStatus? status,
    bool archivedOnly = false,
  });
  Future<CompanyDetail> getCompany(String id);
  Future<List<TalentProcess>> getProcesses({
    String query,
    String? companyId,
    ProcessStatus? status,
  });
  Future<List<PersonEvaluation>> getPeople({
    String query,
    String? companyId,
    EvaluationStatus? status,
  });
  Future<AffinitySummary> getAffinitySummary({String? companyId});
  Future<List<Deal>> getDeals({String query, DealStage? stage});
  Future<List<CultureLead>> listCultureLeads({
    String query,
    CultureLeadStatus? status,
  });
  Future<void> updateCultureLeadStatus({
    required String id,
    required CultureLeadStatus status,
  });
  Future<(SalesSummary, List<Sale>)> getSales({
    required DateTime from,
    required DateTime to,
  });
  Future<AnalyticsSnapshot> getAnalytics({
    required DateTime from,
    required DateTime to,
  });
  Future<List<AdminAlert>> getAlerts();
  Future<List<AdminUserAccount>> getUsers();
  Future<void> createCompany({
    required String name,
    required CompanyStatus status,
    String? plan,
  });
  Future<void> createProcess({required String companyId, required String name});
  Future<void> createPerson({
    required String companyId,
    required String processId,
    required String displayName,
    required EvaluationStatus status,
    double? affinityScore,
  });
  Future<void> createDeal({
    required String companyId,
    required DealStage stage,
    double? estimatedValue,
    String? ownerName,
    String? nextAction,
  });
  Future<void> createSale({
    required String companyId,
    required double amount,
    String? product,
    bool recurring = false,
  });
  Future<void> updateUserRole({required String userId, required String role});
  Future<void> applyCompanyLifecycle({
    required String id,
    required CompanyLifecycleAction action,
  });
  Future<void> updatePerson({
    required String id,
    required String displayName,
    required EvaluationStatus status,
  });
  Future<void> updateCompany({
    required Company company,
    List<int>? logoBytes,
    String? logoContentType,
  });
}

final class FirebaseAdminDataSource implements AdminDataSource {
  FirebaseAdminDataSource(this._auth, this._firestore);
  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _companies =>
      _firestore.collection('companies');
  CollectionReference<Map<String, dynamic>> get _processes =>
      _firestore.collection('processes');
  CollectionReference<Map<String, dynamic>> get _people =>
      _firestore.collection('people');
  CollectionReference<Map<String, dynamic>> get _deals =>
      _firestore.collection('deals');
  CollectionReference<Map<String, dynamic>> get _sales =>
      _firestore.collection('sales');
  CollectionReference<Map<String, dynamic>> get _activity =>
      _firestore.collection('activity_events');
  CollectionReference<Map<String, dynamic>> get _audit =>
      _firestore.collection('admin_audit_logs');
  CollectionReference<Map<String, dynamic>> get _vacancies =>
      _firestore.collection('vacancies');
  CollectionReference<Map<String, dynamic>> get _candidates =>
      _firestore.collection('candidates');

  Future<T> _guard<T>(Future<T> Function() action) async {
    try {
      await _assertSuperAdmin();
      return await action();
    } on ServerException {
      rethrow;
    } on FirebaseException catch (error) {
      if (error.code == 'permission-denied') {
        throw const ServerException(
          'No tienes permiso para acceder al centro de mando.',
        );
      }
      throw ServerException(
        'No se pudo consultar Firestore (${error.code}). Inténtalo nuevamente.',
      );
    }
  }

  Future<void> _assertSuperAdmin() async {
    final user = _auth.currentUser;
    if (user == null) {
      throw const ServerException('Necesitas iniciar sesión.');
    }
    final doc = await _firestore.collection('users').doc(user.uid).get();
    if (doc.data()?['role'] != 'superadmin') {
      throw const ServerException('Esta sección está reservada a SuperAdmin.');
    }
  }

  DateTime _date(Object? value, [DateTime? fallback]) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return fallback ?? DateTime.fromMillisecondsSinceEpoch(0);
  }

  Company _company(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? const <String, dynamic>{};
    return Company(
      id: doc.id,
      name: (data['name'] as String?) ?? 'Empresa',
      logoUrl: data['logoUrl'] as String?,
      website: data['website'] as String?,
      description: data['description'] as String?,
      nit: data['nit'] as String?,
      sector: data['sector'] as String?,
      size: data['size'] as String?,
      city: data['city'] as String?,
      region: data['region'] as String?,
      country: data['country'] as String?,
      status: CompanyStatus.values.firstWhere(
        (item) => item.name == data['status'],
        orElse: () => CompanyStatus.onboarding,
      ),
      createdAt: _date(data['createdAt'], DateTime.now()),
      lastActivityAt: data['lastActivityAt'] == null
          ? null
          : _date(data['lastActivityAt']),
      activeProcesses: (data['activeProcesses'] as num?)?.toInt() ?? 0,
      invitedPeople: (data['invitedPeople'] as num?)?.toInt() ?? 0,
      startedEvaluations: (data['startedEvaluations'] as num?)?.toInt() ?? 0,
      completedEvaluations:
          (data['completedEvaluations'] as num?)?.toInt() ?? 0,
      affinitiesDetected: (data['affinitiesDetected'] as num?)?.toInt() ?? 0,
      plan: data['plan'] as String?,
      contractValue: (data['contractValue'] as num?)?.toDouble(),
      mrr: (data['mrr'] as num?)?.toDouble(),
      renewalAt: data['renewalAt'] == null ? null : _date(data['renewalAt']),
      commercialStage: DealStage.values
          .where((item) => item.name == data['commercialStage'])
          .firstOrNull,
      archived: data['archived'] == true,
    );
  }

  TalentProcess _process(
    DocumentSnapshot<Map<String, dynamic>> doc, {
    String? companyName,
  }) {
    final data = doc.data() ?? const <String, dynamic>{};
    return TalentProcess(
      id: doc.id,
      companyId: (data['companyId'] as String?) ?? '',
      companyName: companyName ?? (data['companyName'] as String?) ?? '',
      name: (data['name'] as String?) ?? 'Proceso',
      status: ProcessStatus.values.firstWhere(
        (item) => item.name == data['status'],
        orElse: () => ProcessStatus.active,
      ),
      createdAt: _date(data['createdAt'], DateTime.now()),
      closedAt: data['closedAt'] == null ? null : _date(data['closedAt']),
      invitedPeople: (data['invitedPeople'] as num?)?.toInt() ?? 0,
      startedEvaluations: (data['startedEvaluations'] as num?)?.toInt() ?? 0,
      completedEvaluations:
          (data['completedEvaluations'] as num?)?.toInt() ?? 0,
      affinitiesDetected: (data['affinitiesDetected'] as num?)?.toInt() ?? 0,
    );
  }

  Company _decorateCompany(
    Company company, {
    required Iterable<TalentProcess> processes,
    required Iterable<PersonEvaluation> people,
  }) {
    final companyPeople = people.where((item) => item.companyId == company.id);
    final companyProcesses = processes.where(
      (item) => item.companyId == company.id,
    );
    return Company(
      id: company.id,
      name: company.name,
      status: company.status,
      createdAt: company.createdAt,
      logoUrl: company.logoUrl,
      website: company.website,
      description: company.description,
      nit: company.nit,
      sector: company.sector,
      size: company.size,
      city: company.city,
      region: company.region,
      country: company.country,
      lastActivityAt: company.lastActivityAt,
      activeProcesses: companyProcesses
          .where((item) => item.status == ProcessStatus.active)
          .length,
      invitedPeople: companyPeople.length,
      startedEvaluations: companyPeople
          .where(
            (item) =>
                item.status != EvaluationStatus.invited &&
                item.status != EvaluationStatus.abandoned,
          )
          .length,
      completedEvaluations: companyPeople
          .where((item) => item.status == EvaluationStatus.completed)
          .length,
      affinitiesDetected: companyPeople
          .where((item) => item.affinityScore != null)
          .length,
      plan: company.plan,
      contractValue: company.contractValue,
      mrr: company.mrr,
      renewalAt: company.renewalAt,
      commercialStage: company.commercialStage,
      archived: company.archived,
    );
  }

  PersonEvaluation _person(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? const <String, dynamic>{};
    return PersonEvaluation(
      id: doc.id,
      displayName: (data['displayName'] as String?) ?? 'Persona',
      companyId: (data['companyId'] as String?) ?? '',
      companyName: (data['companyName'] as String?) ?? '',
      processId: (data['processId'] as String?) ?? '',
      processName: (data['processName'] as String?) ?? '',
      status: EvaluationStatus.values.firstWhere(
        (item) => item.name == data['status'],
        orElse: () => EvaluationStatus.invited,
      ),
      updatedAt: _date(data['updatedAt'], DateTime.now()),
      affinityScore: (data['affinityScore'] as num?)?.toDouble(),
      email: (data['email'] as String?) ?? '',
    );
  }

  Deal _deal(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? const <String, dynamic>{};
    return Deal(
      id: doc.id,
      companyId: (data['companyId'] as String?) ?? '',
      companyName: (data['companyName'] as String?) ?? '',
      stage: DealStage.values.firstWhere(
        (item) => item.name == data['stage'],
        orElse: () => DealStage.prospect,
      ),
      updatedAt: _date(data['updatedAt'], DateTime.now()),
      estimatedValue: (data['estimatedValue'] as num?)?.toDouble(),
      ownerName: data['ownerName'] as String?,
      nextAction: data['nextAction'] as String?,
      probability: (data['probability'] as num?)?.toDouble(),
    );
  }

  Sale _sale(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? const <String, dynamic>{};
    return Sale(
      id: doc.id,
      companyId: (data['companyId'] as String?) ?? '',
      companyName: (data['companyName'] as String?) ?? '',
      amount: (data['amount'] as num?)?.toDouble() ?? 0,
      soldAt: _date(data['soldAt'], DateTime.now()),
      product: data['product'] as String?,
      recurring: data['recurring'] == true,
    );
  }

  ActivityEvent _event(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? const <String, dynamic>{};
    return ActivityEvent(
      id: doc.id,
      kind: ActivityKind.values.firstWhere(
        (item) => item.name == data['kind'],
        orElse: () => ActivityKind.statusChanged,
      ),
      entityName: (data['entityName'] as String?) ?? '',
      createdAt: _date(data['createdAt'], DateTime.now()),
      companyId: data['companyId'] as String?,
      statusLabel: data['statusLabel'] as String?,
      context: data['context'] as String?,
    );
  }

  TalentProcess _processFromVacancy(
    DocumentSnapshot<Map<String, dynamic>> doc,
    Map<String, String> companyNames,
    List<QueryDocumentSnapshot<Map<String, dynamic>>> candidates,
  ) {
    final data = doc.data() ?? const <String, dynamic>{};
    final companyId = (data['companyId'] as String?) ?? '';
    final related = candidates
        .where((item) => item.data()['vacancyId'] == doc.id)
        .toList();
    final started = related
        .where((item) => item.data()['processStatus'] != 'pending')
        .length;
    final completed = related
        .where((item) => item.data()['evaluationCompleted'] == true)
        .length;
    return TalentProcess(
      id: doc.id,
      companyId: companyId,
      companyName: companyNames[companyId] ?? '',
      name: (data['name'] as String?) ?? 'Vacante',
      status: data['status'] == 'closed'
          ? ProcessStatus.closed
          : ProcessStatus.active,
      createdAt: _date(data['createdAt'], DateTime.now()),
      invitedPeople: related.length,
      startedEvaluations: started,
      completedEvaluations: completed,
      affinitiesDetected: related
          .where(
            (item) =>
                item.data()['companyAffinity'] == 'high' ||
                item.data()['companyAffinity'] == 'medium',
          )
          .length,
    );
  }

  PersonEvaluation _personFromCandidate(
    DocumentSnapshot<Map<String, dynamic>> doc,
    Map<String, String> companyNames,
  ) {
    final data = doc.data() ?? const <String, dynamic>{};
    final companyId = (data['companyId'] as String?) ?? '';
    final statusName = data['processStatus'] as String?;
    final completed = data['evaluationCompleted'] == true;
    final affinity = data['companyAffinity'] as String?;
    return PersonEvaluation(
      id: doc.id,
      displayName: ((data['displayName'] as String?)?.trim().isNotEmpty == true)
          ? data['displayName'] as String
          : ((data['email'] as String?) ?? 'Persona'),
      companyId: companyId,
      companyName: companyNames[companyId] ?? '',
      processId: (data['vacancyId'] as String?) ?? '',
      processName: (data['vacancyName'] as String?) ?? '',
      status: completed
          ? EvaluationStatus.completed
          : statusName == 'inProgress'
          ? EvaluationStatus.inProgress
          : EvaluationStatus.invited,
      updatedAt: _date(data['updatedAt'] ?? data['createdAt'], DateTime.now()),
      affinityScore: switch (affinity) {
        'high' => 85,
        'medium' => 60,
        'low' => 30,
        _ => null,
      },
      email: (data['email'] as String?) ?? '',
    );
  }

  List<ActivityEvent> _activityFromVacancies(
    Iterable<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
    Map<String, String> companyNames,
  ) {
    return [
      for (final doc in docs)
        ActivityEvent(
          id: 'vacancy_${doc.id}',
          kind: ActivityKind.vacancyCreated,
          entityName: (doc.data()['name'] as String?) ?? 'Vacante',
          createdAt: _date(doc.data()['createdAt'], DateTime.now()),
          companyId: doc.data()['companyId'] as String?,
          context: companyNames[doc.data()['companyId'] as String? ?? ''],
        ),
    ];
  }

  List<ActivityEvent> _activityFromCandidates(
    Iterable<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
    Map<String, String> companyNames,
  ) {
    return [
      for (final doc in docs)
        ActivityEvent(
          id: 'candidate_${doc.id}',
          kind: doc.data()['evaluationCompleted'] == true
              ? ActivityKind.evaluationCompleted
              : doc.data()['processStatus'] == 'inProgress'
              ? ActivityKind.evaluationStarted
              : ActivityKind.respondentInvited,
          entityName:
              ((doc.data()['displayName'] as String?)?.trim().isNotEmpty ==
                  true)
              ? doc.data()['displayName'] as String
              : ((doc.data()['email'] as String?) ?? 'Encuestado'),
          createdAt: _date(
            doc.data()['updatedAt'] ?? doc.data()['createdAt'],
            DateTime.now(),
          ),
          companyId: doc.data()['companyId'] as String?,
          context: [
            doc.data()['vacancyName'] as String?,
            companyNames[doc.data()['companyId'] as String? ?? ''],
          ].whereType<String>().where((item) => item.isNotEmpty).join(' · '),
        ),
    ];
  }

  Future<void> _log({
    required ActivityKind kind,
    required String entityName,
    String? companyId,
    String? statusLabel,
    String? context,
  }) async {
    final payload = {
      'kind': kind.name,
      'entityName': entityName,
      'createdAt': FieldValue.serverTimestamp(),
      'companyId': companyId,
      'statusLabel': statusLabel,
      'context': context,
      'actorId': _auth.currentUser?.uid,
    };
    await _activity.add(payload);
    await _audit.add({...payload, 'action': kind.name, 'result': 'ok'});
    if (companyId != null) {
      await _companies.doc(companyId).set({
        'lastActivityAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    }
  }

  Future<void> _refreshCompanyCounters(String companyId) async {
    final processes = await _processes
        .where('companyId', isEqualTo: companyId)
        .get();
    final people = await _people.where('companyId', isEqualTo: companyId).get();
    final mappedProcesses = processes.docs.map(_process);
    final mappedPeople = people.docs.map(_person);
    await _companies.doc(companyId).set({
      'activeProcesses': mappedProcesses
          .where((item) => item.status == ProcessStatus.active)
          .length,
      'invitedPeople': mappedPeople.length,
      'startedEvaluations': mappedPeople
          .where(
            (item) =>
                item.status == EvaluationStatus.started ||
                item.status == EvaluationStatus.inProgress ||
                item.status == EvaluationStatus.completed,
          )
          .length,
      'completedEvaluations': mappedPeople
          .where((item) => item.status == EvaluationStatus.completed)
          .length,
      'affinitiesDetected': mappedPeople
          .where((item) => item.affinityScore != null)
          .length,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  @override
  Future<AdminDashboardData> getDashboard() => _guard(() async {
    final companiesSnap = await _companies.limit(200).get();
    final companies = companiesSnap.docs
        .map(_company)
        .where((item) => !item.archived)
        .toList();
    final processesSnap = await _processes.limit(400).get();
    final peopleSnap = await _people.limit(500).get();
    final dealsSnap = await _deals.limit(200).get();
    final salesSnap = await _sales.limit(200).get();
    final people = peopleSnap.docs.map(_person).toList();
    final deals = dealsSnap.docs.map(_deal).toList();
    final sales = salesSnap.docs.map(_sale).toList();
    final companyNames = {
      for (final company in companies) company.id: company.name,
    };
    final vacanciesSnap = await _vacancies.limit(200).get();
    final candidatesSnap = await _candidates.limit(400).get();
    final vacancyProcesses = vacanciesSnap.docs
        .map(
          (doc) => _processFromVacancy(doc, companyNames, candidatesSnap.docs),
        )
        .toList();
    final candidatePeople = candidatesSnap.docs
        .map((doc) => _personFromCandidate(doc, companyNames))
        .toList();
    final mergedPeople = [
      ...people,
      ...candidatePeople.where(
        (item) => people.every((existing) => existing.id != item.id),
      ),
    ];
    final recentCutoff = DateTime.now().subtract(const Duration(days: 45));
    List<ActivityEvent> activity = [
      ..._activityFromVacancies(vacanciesSnap.docs, companyNames),
      ..._activityFromCandidates(candidatesSnap.docs, companyNames),
      for (final company in companies)
        if (!company.createdAt.isBefore(recentCutoff))
          ActivityEvent(
            id: 'company_${company.id}',
            kind: ActivityKind.companyCreated,
            entityName: company.name,
            createdAt: company.createdAt,
            companyId: company.id,
          ),
    ]..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    if (activity.length > 12) activity = activity.take(12).toList();
    final monthStart = DateTime(DateTime.now().year, DateTime.now().month, 1);
    final periodSales = sales
        .where((item) => !item.soldAt.isBefore(monthStart))
        .fold<double>(0, (acc, item) => acc + item.amount);
    final mrr = sales
        .where((item) => item.recurring)
        .fold<double>(0, (acc, item) => acc + item.amount);
    final metrics = AdminMetrics(
      totalCompanies: companies.length,
      activeCompanies: companies
          .where((item) => item.status == CompanyStatus.active)
          .length,
      evaluatedPeople: mergedPeople
          .where(
            (item) =>
                item.status != EvaluationStatus.invited &&
                item.status != EvaluationStatus.abandoned,
          )
          .length,
      completedEvaluations: mergedPeople
          .where((item) => item.status == EvaluationStatus.completed)
          .length,
      affinitiesDetected: mergedPeople
          .where((item) => item.affinityScore != null)
          .length,
      periodSales: periodSales,
      mrr: mrr,
      companiesAtRisk: companies
          .where((item) => item.status == CompanyStatus.atRisk)
          .length,
    );
    final mergedProcesses = [
      ...processesSnap.docs.map(_process),
      ...vacancyProcesses.where(
        (item) => processesSnap.docs.every((doc) => doc.id != item.id),
      ),
    ];
    final funnel = AdminFunnel(
      companies: companies.length,
      processes: mergedProcesses.length,
      invitedPeople: mergedPeople.length,
      startedEvaluations: mergedPeople
          .where(
            (item) =>
                item.status == EvaluationStatus.started ||
                item.status == EvaluationStatus.inProgress ||
                item.status == EvaluationStatus.completed,
          )
          .length,
      completedEvaluations: metrics.completedEvaluations,
      affinitiesDetected: metrics.affinitiesDetected,
      decisions: mergedPeople
          .where((item) => item.affinityScore != null)
          .length,
    );
    return AdminDashboardData(
      metrics: metrics,
      funnel: funnel,
      activity: activity,
      alerts: AdminAlertEngine.from(
        companies: companies,
        processes: mergedProcesses,
        people: mergedPeople,
        deals: deals,
      ),
    );
  });

  @override
  Future<List<Company>> getCompanies({
    String query = '',
    CompanyStatus? status,
    bool archivedOnly = false,
  }) => _guard(() async {
    final snapshot = await _companies.limit(200).get();
    final raw = snapshot.docs.map(_company).toList();
    final names = {for (final item in raw) item.id: item.name};
    final vacancies = await _vacancies.limit(300).get();
    final candidates = await _candidates.limit(400).get();
    final processes = vacancies.docs
        .map((doc) => _processFromVacancy(doc, names, candidates.docs))
        .toList();
    final people = candidates.docs
        .map((doc) => _personFromCandidate(doc, names))
        .toList();
    return filterCompanies(
      raw.map(
        (item) => _decorateCompany(item, processes: processes, people: people),
      ),
      query: query,
      status: status,
      archivedOnly: archivedOnly,
    );
  });

  @override
  Future<CompanyDetail> getCompany(String id) => _guard(() async {
    final doc = await _companies.doc(id).get();
    if (!doc.exists) {
      throw const ServerException('No se encontró la empresa.');
    }
    final company = _company(doc);
    final processes = await _processes.where('companyId', isEqualTo: id).get();
    final people = await _people.where('companyId', isEqualTo: id).get();
    final vacancies = await _vacancies.where('companyId', isEqualTo: id).get();
    final candidates = await _candidates
        .where('companyId', isEqualTo: id)
        .get();
    final companyNames = {id: company.name};
    final vacancyProcesses = vacancies.docs
        .map((item) => _processFromVacancy(item, companyNames, candidates.docs))
        .toList();
    final mappedProcesses = [
      ...processes.docs.map(
        (item) => _process(item, companyName: company.name),
      ),
      ...vacancyProcesses.where(
        (item) => processes.docs.every((doc) => doc.id != item.id),
      ),
    ];
    final mappedPeople = [
      ...people.docs.map(_person),
      ...candidates.docs.map(
        (item) => _personFromCandidate(item, companyNames),
      ),
    ];
    final events = [
      ..._activityFromVacancies(vacancies.docs, companyNames),
      ..._activityFromCandidates(candidates.docs, companyNames),
    ]..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return CompanyDetail(
      company: _decorateCompany(
        company,
        processes: mappedProcesses,
        people: mappedPeople,
      ),
      processes: mappedProcesses,
      people: mappedPeople,
      activity: events,
    );
  });

  @override
  Future<List<TalentProcess>> getProcesses({
    String query = '',
    String? companyId,
    ProcessStatus? status,
  }) => _guard(() async {
    Query<Map<String, dynamic>> ref = _processes;
    if (companyId != null && companyId.isNotEmpty) {
      ref = ref.where('companyId', isEqualTo: companyId);
    }
    final snapshot = await ref.limit(300).get();
    var items = snapshot.docs.map(_process).toList();
    final companiesSnap = await _companies.limit(200).get();
    final companyNames = {
      for (final doc in companiesSnap.docs)
        doc.id: (doc.data()['name'] as String?) ?? '',
    };
    Query<Map<String, dynamic>> vacanciesQuery = _vacancies;
    if (companyId != null && companyId.isNotEmpty) {
      vacanciesQuery = vacanciesQuery.where('companyId', isEqualTo: companyId);
    }
    final vacancies = await vacanciesQuery.limit(300).get();
    final candidates = await _candidates.limit(400).get();
    items = [
      ...items,
      ...vacancies.docs
          .map((doc) => _processFromVacancy(doc, companyNames, candidates.docs))
          .where((item) => items.every((existing) => existing.id != item.id)),
    ];
    if (status != null) {
      items = items.where((item) => item.status == status).toList();
    }
    final needle = query.trim().toLowerCase();
    if (needle.isNotEmpty) {
      items = items
          .where(
            (item) =>
                item.name.toLowerCase().contains(needle) ||
                item.companyName.toLowerCase().contains(needle),
          )
          .toList();
    }
    items.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return items;
  });

  @override
  Future<List<PersonEvaluation>> getPeople({
    String query = '',
    String? companyId,
    EvaluationStatus? status,
  }) => _guard(() async {
    Query<Map<String, dynamic>> ref = _people;
    if (companyId != null && companyId.isNotEmpty) {
      ref = ref.where('companyId', isEqualTo: companyId);
    }
    final snapshot = await ref.limit(400).get();
    var items = snapshot.docs.map(_person).toList();
    final companiesSnap = await _companies.limit(200).get();
    final companyNames = {
      for (final doc in companiesSnap.docs)
        doc.id: (doc.data()['name'] as String?) ?? '',
    };
    Query<Map<String, dynamic>> candidatesQuery = _candidates;
    if (companyId != null && companyId.isNotEmpty) {
      candidatesQuery = candidatesQuery.where(
        'companyId',
        isEqualTo: companyId,
      );
    }
    final candidates = await candidatesQuery.limit(400).get();
    items = [
      ...items,
      ...candidates.docs
          .map((doc) => _personFromCandidate(doc, companyNames))
          .where((item) => items.every((existing) => existing.id != item.id)),
    ];
    if (status != null) {
      items = items.where((item) => item.status == status).toList();
    }
    final needle = query.trim().toLowerCase();
    if (needle.isNotEmpty) {
      items = items
          .where(
            (item) =>
                item.displayName.toLowerCase().contains(needle) ||
                item.companyName.toLowerCase().contains(needle),
          )
          .toList();
    }
    items.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return items;
  });

  @override
  Future<AffinitySummary> getAffinitySummary({String? companyId}) =>
      _guard(() async {
        final people = await getPeople(companyId: companyId);
        var high = 0, medium = 0, low = 0, unknown = 0;
        for (final person in people) {
          switch (person.band) {
            case AffinityBand.high:
              high++;
            case AffinityBand.medium:
              medium++;
            case AffinityBand.low:
              low++;
            case AffinityBand.unknown:
              unknown++;
          }
        }
        return AffinitySummary(
          high: high,
          medium: medium,
          low: low,
          unknown: unknown,
        );
      });

  @override
  Future<List<Deal>> getDeals({String query = '', DealStage? stage}) =>
      _guard(() async {
        final snapshot = await _deals.limit(200).get();
        var items = snapshot.docs.map(_deal).toList();
        if (stage != null) {
          items = items.where((item) => item.stage == stage).toList();
        }
        final needle = query.trim().toLowerCase();
        if (needle.isNotEmpty) {
          items = items
              .where((item) => item.companyName.toLowerCase().contains(needle))
              .toList();
        }
        items.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
        return items;
      });

  @override
  Future<List<CultureLead>> listCultureLeads({
    String query = '',
    CultureLeadStatus? status,
  }) => _guard(() async => const []);

  @override
  Future<void> updateCultureLeadStatus({
    required String id,
    required CultureLeadStatus status,
  }) => _guard(() async {});

  @override
  Future<(SalesSummary, List<Sale>)> getSales({
    required DateTime from,
    required DateTime to,
  }) => _guard(() async {
    final snapshot = await _sales.limit(400).get();
    final all = snapshot.docs.map(_sale).toList();
    final period = all
        .where(
          (item) => !item.soldAt.isBefore(from) && !item.soldAt.isAfter(to),
        )
        .toList();
    final previousFrom = from.subtract(to.difference(from));
    final previous = all
        .where(
          (item) =>
              !item.soldAt.isBefore(previousFrom) && item.soldAt.isBefore(from),
        )
        .fold<double>(0, (acc, item) => acc + item.amount);
    final periodTotal = period.fold<double>(
      0,
      (acc, item) => acc + item.amount,
    );
    final companies = period.map((item) => item.companyId).toSet().length;
    return (
      SalesSummary(
        periodTotal: periodTotal,
        cumulativeTotal: all.fold<double>(0, (acc, item) => acc + item.amount),
        newCustomers: companies,
        averageTicket: period.isEmpty ? 0 : periodTotal / period.length,
        mrr: all
            .where((item) => item.recurring)
            .fold<double>(0, (acc, item) => acc + item.amount),
        growth: previous == 0
            ? (periodTotal == 0 ? 0 : 1)
            : (periodTotal - previous) / previous,
      ),
      period..sort((a, b) => b.soldAt.compareTo(a.soldAt)),
    );
  });

  @override
  Future<AnalyticsSnapshot> getAnalytics({
    required DateTime from,
    required DateTime to,
  }) => _guard(() async {
    final companies = (await _companies.limit(200).get()).docs.map(_company);
    final processes = (await _processes.limit(400).get()).docs.map(_process);
    final people = (await _people.limit(500).get()).docs.map(_person);
    bool inRange(DateTime date) => !date.isBefore(from) && !date.isAfter(to);
    final daily = <DateTime, int>{};
    for (final event in (await _activity.limit(500).get()).docs.map(_event)) {
      if (!inRange(event.createdAt)) continue;
      final day = DateTime(
        event.createdAt.year,
        event.createdAt.month,
        event.createdAt.day,
      );
      daily[day] = (daily[day] ?? 0) + 1;
    }
    final days = daily.entries.toList()..sort((a, b) => a.key.compareTo(b.key));
    return AnalyticsSnapshot(
      newCompanies: companies.where((item) => inRange(item.createdAt)).length,
      activeCompanies: companies
          .where((item) => item.status == CompanyStatus.active)
          .length,
      evaluatedPeople: people
          .where(
            (item) =>
                inRange(item.updatedAt) &&
                item.status != EvaluationStatus.invited,
          )
          .length,
      startedEvaluations: people
          .where(
            (item) =>
                item.status != EvaluationStatus.invited &&
                item.status != EvaluationStatus.abandoned,
          )
          .length,
      completedEvaluations: people
          .where((item) => item.status == EvaluationStatus.completed)
          .length,
      affinitiesDetected: people
          .where((item) => item.affinityScore != null)
          .length,
      processesCreated: processes
          .where((item) => inRange(item.createdAt))
          .length,
      processesClosed: processes
          .where((item) => item.closedAt != null && inRange(item.closedAt!))
          .length,
      daily: days.map((entry) => (entry.key, entry.value)).toList(),
    );
  });

  @override
  Future<List<AdminAlert>> getAlerts() async {
    final dashboard = await getDashboard();
    final requests = await _surveyResultAlerts();
    return [...requests, ...dashboard.alerts];
  }

  Future<List<AdminAlert>> _surveyResultAlerts() async {
    try {
      final snapshot = await _firestore
          .collection('survey_result_requests')
          .orderBy('requestedAt', descending: true)
          .limit(50)
          .get();
      return [
        for (final doc in snapshot.docs)
          if (doc.data()['status'] == 'pending' || doc.data()['status'] == null)
            () {
              final data = doc.data();
              final person =
                  '${data['displayName'] ?? data['email'] ?? doc.id}';
              final company = data['companyName'] as String?;
              final vacancy = data['vacancyName'] as String?;
              final requestedAt = data['requestedAt'];
              return AdminAlert(
                id: 'result-${doc.id}',
                type: AlertType.operational,
                priority: AlertPriority.high,
                title: person,
                description:
                    '$person quiere conocer el resultado de su encuesta'
                    '${company == null ? '' : ' en $company'}'
                    '${vacancy == null ? '' : ' · $vacancy'}.',
                suggestedAction:
                    'Una persona especializada debe revisar la encuesta y comunicar el resultado.',
                createdAt: requestedAt is Timestamp
                    ? requestedAt.toDate()
                    : DateTime.now(),
                entityName: company,
              );
            }(),
      ];
    } catch (_) {
      return const [];
    }
  }

  @override
  Future<List<AdminUserAccount>> getUsers() => _guard(() async {
    final snapshot = await _firestore.collection('users').limit(200).get();
    return snapshot.docs
        .map(
          (doc) => AdminUserAccount(
            id: doc.id,
            email: (doc.data()['email'] as String?) ?? '',
            role: (doc.data()['role'] as String?) ?? 'user',
            isActive: doc.data()['isActive'] != false,
            displayName: doc.data()['displayName'] as String?,
            companyName: doc.data()['companyName'] as String?,
          ),
        )
        .toList();
  });

  @override
  Future<void> createCompany({
    required String name,
    required CompanyStatus status,
    String? plan,
  }) => _guard(() async {
    final ref = await _companies.add({
      'name': name.trim(),
      'nameLower': name.trim().toLowerCase(),
      'status': status.name,
      'archived': false,
      'plan': plan,
      'createdAt': FieldValue.serverTimestamp(),
      'lastActivityAt': FieldValue.serverTimestamp(),
      'activeProcesses': 0,
      'invitedPeople': 0,
      'startedEvaluations': 0,
      'completedEvaluations': 0,
      'affinitiesDetected': 0,
      'createdBy': _auth.currentUser?.uid,
    });
    await _log(
      kind: ActivityKind.companyCreated,
      entityName: name.trim(),
      companyId: ref.id,
      statusLabel: status.name,
    );
    if (status == CompanyStatus.active) {
      await _log(
        kind: ActivityKind.companyActivated,
        entityName: name.trim(),
        companyId: ref.id,
        statusLabel: status.name,
      );
    }
  });

  @override
  Future<void> createProcess({
    required String companyId,
    required String name,
  }) => _guard(() async {
    final company = _company(await _companies.doc(companyId).get());
    final ref = await _processes.add({
      'companyId': companyId,
      'companyName': company.name,
      'name': name.trim(),
      'status': ProcessStatus.active.name,
      'createdAt': FieldValue.serverTimestamp(),
      'invitedPeople': 0,
      'startedEvaluations': 0,
      'completedEvaluations': 0,
      'affinitiesDetected': 0,
    });
    await _refreshCompanyCounters(companyId);
    await _log(
      kind: ActivityKind.processCreated,
      entityName: name.trim(),
      companyId: companyId,
      context: ref.id,
    );
  });

  @override
  Future<void> createPerson({
    required String companyId,
    required String processId,
    required String displayName,
    required EvaluationStatus status,
    double? affinityScore,
  }) => _guard(() async {
    final company = _company(await _companies.doc(companyId).get());
    final process = _process(await _processes.doc(processId).get());
    await _people.add({
      'displayName': displayName.trim(),
      'companyId': companyId,
      'companyName': company.name,
      'processId': processId,
      'processName': process.name,
      'status': status.name,
      'affinityScore': affinityScore,
      'updatedAt': FieldValue.serverTimestamp(),
      'createdAt': FieldValue.serverTimestamp(),
    });
    await _processes.doc(processId).set({
      'invitedPeople': FieldValue.increment(1),
      if (status != EvaluationStatus.invited &&
          status != EvaluationStatus.abandoned)
        'startedEvaluations': FieldValue.increment(1),
      if (status == EvaluationStatus.completed)
        'completedEvaluations': FieldValue.increment(1),
      if (affinityScore != null) 'affinitiesDetected': FieldValue.increment(1),
    }, SetOptions(merge: true));
    await _refreshCompanyCounters(companyId);
    if (status == EvaluationStatus.started ||
        status == EvaluationStatus.inProgress) {
      await _log(
        kind: ActivityKind.evaluationStarted,
        entityName: displayName.trim(),
        companyId: companyId,
        statusLabel: status.name,
      );
    }
    if (status == EvaluationStatus.completed) {
      await _log(
        kind: ActivityKind.evaluationCompleted,
        entityName: displayName.trim(),
        companyId: companyId,
        statusLabel: status.name,
      );
    }
    if (affinityScore != null) {
      await _log(
        kind: ActivityKind.affinityDetected,
        entityName: displayName.trim(),
        companyId: companyId,
        context: affinityScore.toStringAsFixed(0),
      );
    }
  });

  @override
  Future<void> createDeal({
    required String companyId,
    required DealStage stage,
    double? estimatedValue,
    String? ownerName,
    String? nextAction,
  }) => _guard(() async {
    final company = _company(await _companies.doc(companyId).get());
    await _deals.add({
      'companyId': companyId,
      'companyName': company.name,
      'stage': stage.name,
      'estimatedValue': estimatedValue,
      'ownerName': ownerName,
      'nextAction': nextAction,
      'updatedAt': FieldValue.serverTimestamp(),
    });
    await _companies.doc(companyId).set({
      'commercialStage': stage.name,
      'contractValue': estimatedValue,
    }, SetOptions(merge: true));
    await _log(
      kind: ActivityKind.statusChanged,
      entityName: company.name,
      companyId: companyId,
      statusLabel: stage.name,
      context: 'pipeline',
    );
  });

  @override
  Future<void> createSale({
    required String companyId,
    required double amount,
    String? product,
    bool recurring = false,
  }) => _guard(() async {
    final company = _company(await _companies.doc(companyId).get());
    await _sales.add({
      'companyId': companyId,
      'companyName': company.name,
      'amount': amount,
      'product': product,
      'recurring': recurring,
      'soldAt': FieldValue.serverTimestamp(),
    });
    if (recurring) {
      await _companies.doc(companyId).set({
        'mrr': FieldValue.increment(amount),
      }, SetOptions(merge: true));
    }
    await _log(
      kind: ActivityKind.saleRecorded,
      entityName: company.name,
      companyId: companyId,
      context: amount.toStringAsFixed(0),
    );
  });

  @override
  Future<void> updateUserRole({required String userId, required String role}) =>
      _guard(() async {
        if (role != 'user' && role != 'superadmin') {
          throw const ServerException('Rol no permitido.');
        }
        await _firestore.collection('users').doc(userId).set({
          'role': role,
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
        await _audit.add({
          'action': 'updateUserRole',
          'entityName': userId,
          'context': role,
          'actorId': _auth.currentUser?.uid,
          'createdAt': FieldValue.serverTimestamp(),
          'result': 'ok',
        });
      });

  @override
  Future<void> applyCompanyLifecycle({
    required String id,
    required CompanyLifecycleAction action,
  }) => _guard(() async {
    final doc = await _companies.doc(id).get();
    if (!doc.exists) {
      throw const ServerException('No se encontró la empresa.');
    }
    final company = _company(doc);
    final previous = doc.data()?['statusBeforeArchive'] as String?;
    final payload = <String, dynamic>{
      'updatedAt': FieldValue.serverTimestamp(),
    };
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
        payload['statusBeforeArchive'] = company.status.name;
        payload['archivedAt'] = FieldValue.serverTimestamp();
      case CompanyLifecycleAction.restore:
        final restored = CompanyStatus.values
            .where((item) => item.name == previous)
            .firstOrNull;
        payload['archived'] = false;
        payload['status'] = (restored ?? CompanyStatus.onboarding).name;
        payload['statusBeforeArchive'] = FieldValue.delete();
        payload['archivedAt'] = FieldValue.delete();
    }
    await _companies.doc(id).set(payload, SetOptions(merge: true));
    await _log(
      kind: ActivityKind.statusChanged,
      entityName: company.name,
      companyId: id,
      statusLabel: payload['status'] as String?,
      context: action.name,
    );
  });

  @override
  Future<void> updatePerson({
    required String id,
    required String displayName,
    required EvaluationStatus status,
  }) => _guard(() async {
    final processStatus = switch (status) {
      EvaluationStatus.invited => 'pending',
      EvaluationStatus.started => 'inProgress',
      EvaluationStatus.inProgress => 'inProgress',
      EvaluationStatus.completed => 'completed',
      EvaluationStatus.abandoned => 'rejected',
    };
    await _candidates.doc(id).set({
      'displayName': displayName.trim(),
      'processStatus': processStatus,
      'evaluationCompleted': status == EvaluationStatus.completed,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
    await _people.doc(id).set({
      'displayName': displayName.trim(),
      'status': status.name,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
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
        logoUrl = await ref.getDownloadURL().timeout(
          const Duration(seconds: 8),
        );
      } catch (_) {}
    }
    await _companies.doc(company.id).set({
      'name': company.name.trim(),
      'nameLower': company.name.trim().toLowerCase(),
      'nit': company.nit,
      'website': company.website,
      'logoUrl': logoUrl,
      'description': company.description,
      'sector': company.sector,
      'size': company.size,
      'city': company.city,
      'country': company.country,
      'region': company.region,
      'status': company.status.name,
      'updatedAt': FieldValue.serverTimestamp(),
      'lastActivityAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  });
}

final class InMemoryAdminDataSource implements AdminDataSource {
  final companies = <Company>[];
  final processes = <TalentProcess>[];
  final people = <PersonEvaluation>[];
  final deals = <Deal>[];
  final cultureLeads = <CultureLead>[];
  final sales = <Sale>[];
  final activity = <ActivityEvent>[];
  final users = <AdminUserAccount>[];
  final priorStatus = <String, CompanyStatus>{};

  AdminDashboardData _dashboard() {
    final visible = companies.where((item) => !item.archived).toList();
    final alerts = AdminAlertEngine.from(
      companies: visible,
      processes: processes,
      people: people,
      deals: deals,
    );
    return AdminDashboardData(
      metrics: AdminMetrics(
        totalCompanies: visible.length,
        activeCompanies: visible
            .where((item) => item.status == CompanyStatus.active)
            .length,
        evaluatedPeople: people
            .where((item) => item.status != EvaluationStatus.invited)
            .length,
        completedEvaluations: people
            .where((item) => item.status == EvaluationStatus.completed)
            .length,
        affinitiesDetected: people
            .where((item) => item.affinityScore != null)
            .length,
        periodSales: sales.fold<double>(0, (acc, item) => acc + item.amount),
        mrr: sales
            .where((item) => item.recurring)
            .fold<double>(0, (acc, item) => acc + item.amount),
        companiesAtRisk: visible
            .where((item) => item.status == CompanyStatus.atRisk)
            .length,
      ),
      funnel: AdminFunnel(
        companies: visible.length,
        processes: processes.length,
        invitedPeople: people.length,
        startedEvaluations: people
            .where((item) => item.status != EvaluationStatus.invited)
            .length,
        completedEvaluations: people
            .where((item) => item.status == EvaluationStatus.completed)
            .length,
        affinitiesDetected: people
            .where((item) => item.affinityScore != null)
            .length,
        decisions: people.where((item) => item.affinityScore != null).length,
      ),
      activity: activity.reversed.toList(),
      alerts: alerts,
    );
  }

  @override
  Future<AdminDashboardData> getDashboard() async => _dashboard();

  @override
  Future<List<Company>> getCompanies({
    String query = '',
    CompanyStatus? status,
    bool archivedOnly = false,
  }) async {
    return filterCompanies(
      companies,
      query: query,
      status: status,
      archivedOnly: archivedOnly,
    );
  }

  @override
  Future<CompanyDetail> getCompany(String id) async {
    final company = companies.firstWhere(
      (item) => item.id == id,
      orElse: () => throw const ServerException('No se encontró la empresa.'),
    );
    return CompanyDetail(
      company: company,
      processes: processes.where((item) => item.companyId == id).toList(),
      people: people.where((item) => item.companyId == id).toList(),
      activity: activity.where((item) => item.companyId == id).toList(),
    );
  }

  @override
  Future<List<TalentProcess>> getProcesses({
    String query = '',
    String? companyId,
    ProcessStatus? status,
  }) async {
    var items = [...processes];
    if (companyId != null) {
      items = items.where((item) => item.companyId == companyId).toList();
    }
    if (status != null) {
      items = items.where((item) => item.status == status).toList();
    }
    return items;
  }

  @override
  Future<List<PersonEvaluation>> getPeople({
    String query = '',
    String? companyId,
    EvaluationStatus? status,
  }) async {
    var items = [...people];
    if (companyId != null) {
      items = items.where((item) => item.companyId == companyId).toList();
    }
    if (status != null) {
      items = items.where((item) => item.status == status).toList();
    }
    if (query.trim().isNotEmpty) {
      items = items
          .where(
            (item) =>
                item.displayName.toLowerCase().contains(query.toLowerCase()),
          )
          .toList();
    }
    return items;
  }

  @override
  Future<AffinitySummary> getAffinitySummary({String? companyId}) async {
    final items = await getPeople(companyId: companyId);
    return AffinitySummary(
      high: items.where((item) => item.band == AffinityBand.high).length,
      medium: items.where((item) => item.band == AffinityBand.medium).length,
      low: items.where((item) => item.band == AffinityBand.low).length,
      unknown: items.where((item) => item.band == AffinityBand.unknown).length,
    );
  }

  @override
  Future<List<Deal>> getDeals({String query = '', DealStage? stage}) async {
    var items = [...deals];
    if (stage != null) {
      items = items.where((item) => item.stage == stage).toList();
    }
    return items;
  }

  @override
  Future<List<CultureLead>> listCultureLeads({
    String query = '',
    CultureLeadStatus? status,
  }) async {
    var items = [...cultureLeads];
    if (status != null) {
      items = items.where((item) => item.status == status).toList();
    }
    final needle = query.trim().toLowerCase();
    if (needle.isNotEmpty) {
      items = items
          .where(
            (item) =>
                item.companyName.toLowerCase().contains(needle) ||
                item.email.toLowerCase().contains(needle),
          )
          .toList();
    }
    items.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return items;
  }

  @override
  Future<void> updateCultureLeadStatus({
    required String id,
    required CultureLeadStatus status,
  }) async {
    final index = cultureLeads.indexWhere((item) => item.id == id);
    if (index < 0) return;
    cultureLeads[index] = cultureLeads[index].copyWith(
      status: status,
      updatedAt: DateTime.now(),
    );
  }

  @override
  Future<(SalesSummary, List<Sale>)> getSales({
    required DateTime from,
    required DateTime to,
  }) async {
    final period = sales
        .where(
          (item) => !item.soldAt.isBefore(from) && !item.soldAt.isAfter(to),
        )
        .toList();
    final total = period.fold<double>(0, (acc, item) => acc + item.amount);
    return (
      SalesSummary(
        periodTotal: total,
        cumulativeTotal: sales.fold<double>(
          0,
          (acc, item) => acc + item.amount,
        ),
        newCustomers: period.map((item) => item.companyId).toSet().length,
        averageTicket: period.isEmpty ? 0 : total / period.length,
        mrr: sales
            .where((item) => item.recurring)
            .fold<double>(0, (acc, item) => acc + item.amount),
      ),
      period,
    );
  }

  @override
  Future<AnalyticsSnapshot> getAnalytics({
    required DateTime from,
    required DateTime to,
  }) async => AnalyticsSnapshot(
    newCompanies: companies
        .where((item) => !item.createdAt.isBefore(from))
        .length,
    activeCompanies: companies
        .where((item) => item.status == CompanyStatus.active)
        .length,
    evaluatedPeople: people.length,
    startedEvaluations: people
        .where((item) => item.status != EvaluationStatus.invited)
        .length,
    completedEvaluations: people
        .where((item) => item.status == EvaluationStatus.completed)
        .length,
    affinitiesDetected: people
        .where((item) => item.affinityScore != null)
        .length,
    processesCreated: processes.length,
    processesClosed: processes
        .where((item) => item.status == ProcessStatus.closed)
        .length,
  );

  @override
  Future<List<AdminAlert>> getAlerts() async => _dashboard().alerts;

  @override
  Future<List<AdminUserAccount>> getUsers() async => users;

  @override
  Future<void> createCompany({
    required String name,
    required CompanyStatus status,
    String? plan,
  }) async {
    companies.add(
      Company(
        id: '${companies.length + 1}',
        name: name,
        status: status,
        createdAt: DateTime.now(),
        lastActivityAt: DateTime.now(),
        plan: plan,
      ),
    );
  }

  @override
  Future<void> createProcess({
    required String companyId,
    required String name,
  }) async {
    final company = companies.firstWhere((item) => item.id == companyId);
    processes.add(
      TalentProcess(
        id: '${processes.length + 1}',
        companyId: companyId,
        companyName: company.name,
        name: name,
        status: ProcessStatus.active,
        createdAt: DateTime.now(),
      ),
    );
  }

  @override
  Future<void> createPerson({
    required String companyId,
    required String processId,
    required String displayName,
    required EvaluationStatus status,
    double? affinityScore,
  }) async {
    final company = companies.firstWhere((item) => item.id == companyId);
    final process = processes.firstWhere((item) => item.id == processId);
    people.add(
      PersonEvaluation(
        id: '${people.length + 1}',
        displayName: displayName,
        companyId: companyId,
        companyName: company.name,
        processId: processId,
        processName: process.name,
        status: status,
        updatedAt: DateTime.now(),
        affinityScore: affinityScore,
      ),
    );
  }

  @override
  Future<void> createDeal({
    required String companyId,
    required DealStage stage,
    double? estimatedValue,
    String? ownerName,
    String? nextAction,
  }) async {
    final company = companies.firstWhere((item) => item.id == companyId);
    deals.add(
      Deal(
        id: '${deals.length + 1}',
        companyId: companyId,
        companyName: company.name,
        stage: stage,
        updatedAt: DateTime.now(),
        estimatedValue: estimatedValue,
        ownerName: ownerName,
        nextAction: nextAction,
      ),
    );
  }

  @override
  Future<void> createSale({
    required String companyId,
    required double amount,
    String? product,
    bool recurring = false,
  }) async {
    final company = companies.firstWhere((item) => item.id == companyId);
    sales.add(
      Sale(
        id: '${sales.length + 1}',
        companyId: companyId,
        companyName: company.name,
        amount: amount,
        soldAt: DateTime.now(),
        product: product,
        recurring: recurring,
      ),
    );
  }

  @override
  Future<void> updateUserRole({
    required String userId,
    required String role,
  }) async {
    final index = users.indexWhere((item) => item.id == userId);
    if (index < 0) return;
    final current = users[index];
    users[index] = AdminUserAccount(
      id: current.id,
      email: current.email,
      role: role,
      isActive: current.isActive,
      displayName: current.displayName,
      companyName: current.companyName,
    );
  }

  @override
  Future<void> applyCompanyLifecycle({
    required String id,
    required CompanyLifecycleAction action,
  }) async {
    final index = companies.indexWhere((item) => item.id == id);
    if (index < 0) {
      throw const ServerException('No se encontró la empresa.');
    }
    final current = companies[index];
    switch (action) {
      case CompanyLifecycleAction.disable:
        companies[index] = current.copyWith(
          status: CompanyStatus.inactive,
          archived: false,
        );
      case CompanyLifecycleAction.enable:
        companies[index] = current.copyWith(
          status: CompanyStatus.active,
          archived: false,
        );
      case CompanyLifecycleAction.archive:
        priorStatus[id] = current.status;
        companies[index] = current.copyWith(
          status: CompanyStatus.inactive,
          archived: true,
        );
      case CompanyLifecycleAction.restore:
        companies[index] = current.copyWith(
          status: priorStatus.remove(id) ?? CompanyStatus.onboarding,
          archived: false,
        );
    }
  }

  @override
  Future<void> updatePerson({
    required String id,
    required String displayName,
    required EvaluationStatus status,
  }) async {
    final index = people.indexWhere((item) => item.id == id);
    if (index < 0) return;
    final current = people[index];
    people[index] = PersonEvaluation(
      id: current.id,
      displayName: displayName,
      companyId: current.companyId,
      companyName: current.companyName,
      processId: current.processId,
      processName: current.processName,
      status: status,
      updatedAt: DateTime.now(),
      affinityScore: current.affinityScore,
      email: current.email,
    );
  }

  @override
  Future<void> updateCompany({
    required Company company,
    List<int>? logoBytes,
    String? logoContentType,
  }) async {
    final index = companies.indexWhere((item) => item.id == company.id);
    if (index < 0) return;
    companies[index] = company;
  }
}
