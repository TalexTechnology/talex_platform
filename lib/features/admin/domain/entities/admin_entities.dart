import 'package:equatable/equatable.dart';

enum CompanyStatus { active, onboarding, inactive, atRisk, suspended }

enum CompanyLifecycleAction { disable, enable, archive, restore }

enum ProcessStatus { active, closed }

enum EvaluationStatus { invited, started, inProgress, completed, abandoned }

enum AffinityBand { high, medium, low, unknown }

enum DealStage { prospect, contacted, meeting, proposal, negotiation, client }

enum ActivityKind {
  companyCreated,
  companyActivated,
  processCreated,
    vacancyCreated,
    respondentInvited,
    evaluationStarted,
  evaluationCompleted,
  affinityDetected,
  saleRecorded,
  statusChanged,
}

enum AlertType { risk, operational, commercial, product, opportunity }

enum AlertPriority { high, medium, low }

enum AnalyticsPeriod { d7, d30, d90, m12, custom }

enum AdminSection {
  dashboard,
  companies,
  processes,
  people,
  affinity,
  commercial,
  sales,
  analytics,
  alerts,
  xebec,
  questions,
  cultureSurvey,
  settings,
}

AffinityBand affinityBandFor(double? score) {
  if (score == null) return AffinityBand.unknown;
  if (score >= 80) return AffinityBand.high;
  if (score >= 50) return AffinityBand.medium;
  return AffinityBand.low;
}

class Company extends Equatable {
  const Company({
    required this.id,
    required this.name,
    required this.status,
    required this.createdAt,
    this.logoUrl,
    this.website,
    this.description,
    this.nit,
    this.sector,
    this.size,
    this.city,
    this.region,
    this.country,
    this.lastActivityAt,
    this.activeProcesses = 0,
    this.invitedPeople = 0,
    this.startedEvaluations = 0,
    this.completedEvaluations = 0,
    this.affinitiesDetected = 0,
    this.plan,
    this.contractValue,
    this.mrr,
    this.renewalAt,
    this.commercialStage,
    this.archived = false,
  });
  final String id, name;
  final CompanyStatus status;
  final DateTime createdAt;
  final DateTime? lastActivityAt, renewalAt;
  final String? logoUrl,
      website,
      description,
      nit,
      sector,
      size,
      city,
      region,
      country,
      plan;
  final int activeProcesses,
      invitedPeople,
      startedEvaluations,
      completedEvaluations,
      affinitiesDetected;
  final double? contractValue, mrr;
  final DealStage? commercialStage;
  final bool archived;
  bool get isDisabled =>
      status == CompanyStatus.inactive || status == CompanyStatus.suspended;

  Company copyWith({
    CompanyStatus? status,
    bool? archived,
    DateTime? lastActivityAt,
  }) => Company(
    id: id,
    name: name,
    status: status ?? this.status,
    createdAt: createdAt,
    logoUrl: logoUrl,
    website: website,
    description: description,
    nit: nit,
    sector: sector,
    size: size,
    city: city,
    region: region,
    country: country,
    lastActivityAt: lastActivityAt ?? this.lastActivityAt,
    activeProcesses: activeProcesses,
    invitedPeople: invitedPeople,
    startedEvaluations: startedEvaluations,
    completedEvaluations: completedEvaluations,
    affinitiesDetected: affinitiesDetected,
    plan: plan,
    contractValue: contractValue,
    mrr: mrr,
    renewalAt: renewalAt,
    commercialStage: commercialStage,
    archived: archived ?? this.archived,
  );

  @override
  List<Object?> get props => [
    id,
    name,
    status,
    lastActivityAt,
    archived,
    logoUrl,
    website,
  ];
}

List<Company> filterCompanies(
  Iterable<Company> companies, {
  String query = '',
  CompanyStatus? status,
  bool archivedOnly = false,
}) {
  var items = companies.where((item) => item.archived == archivedOnly).toList();
  if (!archivedOnly && status != null) {
    items = items.where((item) => item.status == status).toList();
  }
  final needle = query.trim().toLowerCase();
  if (needle.isNotEmpty) {
    items = items
        .where((item) => item.name.toLowerCase().contains(needle))
        .toList();
  }
  items.sort((a, b) => b.createdAt.compareTo(a.createdAt));
  return items;
}

class TalentProcess extends Equatable {
  const TalentProcess({
    required this.id,
    required this.companyId,
    required this.companyName,
    required this.name,
    required this.status,
    required this.createdAt,
    this.closedAt,
    this.invitedPeople = 0,
    this.startedEvaluations = 0,
    this.completedEvaluations = 0,
    this.affinitiesDetected = 0,
  });
  final String id, companyId, companyName, name;
  final ProcessStatus status;
  final DateTime createdAt;
  final DateTime? closedAt;
  final int invitedPeople,
      startedEvaluations,
      completedEvaluations,
      affinitiesDetected;
  @override
  List<Object?> get props => [id, companyId, name, status];
}

class PersonEvaluation extends Equatable {
  const PersonEvaluation({
    required this.id,
    required this.displayName,
    required this.companyId,
    required this.companyName,
    required this.processId,
    required this.processName,
    required this.status,
    required this.updatedAt,
    this.affinityScore,
    this.email = '',
  });
  final String id, displayName, companyId, companyName, processId, processName;
  final String email;
  final EvaluationStatus status;
  final DateTime updatedAt;
  final double? affinityScore;
  AffinityBand get band => affinityBandFor(affinityScore);
  @override
  List<Object?> get props => [id, displayName, status, affinityScore, email];
}

class Deal extends Equatable {
  const Deal({
    required this.id,
    required this.companyId,
    required this.companyName,
    required this.stage,
    required this.updatedAt,
    this.estimatedValue,
    this.ownerName,
    this.nextAction,
    this.probability,
  });
  final String id, companyId, companyName;
  final DealStage stage;
  final DateTime updatedAt;
  final double? estimatedValue, probability;
  final String? ownerName, nextAction;
  @override
  List<Object?> get props => [id, companyId, stage, estimatedValue];
}

class Sale extends Equatable {
  const Sale({
    required this.id,
    required this.companyId,
    required this.companyName,
    required this.amount,
    required this.soldAt,
    this.product,
    this.recurring = false,
  });
  final String id, companyId, companyName;
  final String? product;
  final double amount;
  final DateTime soldAt;
  final bool recurring;
  @override
  List<Object?> get props => [id, companyId, amount, soldAt];
}

class ActivityEvent extends Equatable {
  const ActivityEvent({
    required this.id,
    required this.kind,
    required this.entityName,
    required this.createdAt,
    this.companyId,
    this.statusLabel,
    this.context,
  });
  final String id, entityName;
  final ActivityKind kind;
  final DateTime createdAt;
  final String? companyId, statusLabel, context;
  @override
  List<Object?> get props => [id, kind, entityName, createdAt];
}

class AdminAlert extends Equatable {
  const AdminAlert({
    required this.id,
    required this.type,
    required this.priority,
    required this.title,
    required this.description,
    required this.suggestedAction,
    required this.createdAt,
    this.entityName,
  });
  final String id, title, description, suggestedAction;
  final AlertType type;
  final AlertPriority priority;
  final DateTime createdAt;
  final String? entityName;
  @override
  List<Object?> get props => [id, type, title];
}

class AdminMetrics extends Equatable {
  const AdminMetrics({
    this.totalCompanies = 0,
    this.activeCompanies = 0,
    this.evaluatedPeople = 0,
    this.completedEvaluations = 0,
    this.affinitiesDetected = 0,
    this.periodSales = 0,
    this.mrr = 0,
    this.companiesAtRisk = 0,
  });
  final int totalCompanies,
      activeCompanies,
      evaluatedPeople,
      completedEvaluations,
      affinitiesDetected,
      companiesAtRisk;
  final double periodSales, mrr;
  @override
  List<Object?> get props => [
    totalCompanies,
    activeCompanies,
    evaluatedPeople,
    completedEvaluations,
    affinitiesDetected,
    periodSales,
    mrr,
    companiesAtRisk,
  ];
}

class AdminFunnel extends Equatable {
  const AdminFunnel({
    this.companies = 0,
    this.processes = 0,
    this.invitedPeople = 0,
    this.startedEvaluations = 0,
    this.completedEvaluations = 0,
    this.affinitiesDetected = 0,
    this.decisions = 0,
  });
  final int companies,
      processes,
      invitedPeople,
      startedEvaluations,
      completedEvaluations,
      affinitiesDetected,
      decisions;
  @override
  List<Object?> get props => [
    companies,
    processes,
    invitedPeople,
    startedEvaluations,
    completedEvaluations,
    affinitiesDetected,
    decisions,
  ];
}

class AffinitySummary extends Equatable {
  const AffinitySummary({
    this.high = 0,
    this.medium = 0,
    this.low = 0,
    this.unknown = 0,
  });
  final int high, medium, low, unknown;
  int get total => high + medium + low + unknown;
  @override
  List<Object?> get props => [high, medium, low, unknown];
}

class SalesSummary extends Equatable {
  const SalesSummary({
    this.periodTotal = 0,
    this.cumulativeTotal = 0,
    this.newCustomers = 0,
    this.averageTicket = 0,
    this.mrr = 0,
    this.growth = 0,
  });
  final double periodTotal, cumulativeTotal, averageTicket, mrr, growth;
  final int newCustomers;
  @override
  List<Object?> get props => [
    periodTotal,
    cumulativeTotal,
    newCustomers,
    averageTicket,
    mrr,
    growth,
  ];
}

class AnalyticsSnapshot extends Equatable {
  const AnalyticsSnapshot({
    this.newCompanies = 0,
    this.activeCompanies = 0,
    this.evaluatedPeople = 0,
    this.startedEvaluations = 0,
    this.completedEvaluations = 0,
    this.affinitiesDetected = 0,
    this.processesCreated = 0,
    this.processesClosed = 0,
    this.daily = const [],
  });
  final int newCompanies,
      activeCompanies,
      evaluatedPeople,
      startedEvaluations,
      completedEvaluations,
      affinitiesDetected,
      processesCreated,
      processesClosed;
  final List<(DateTime, int)> daily;
  double get completionRate => startedEvaluations == 0
      ? 0
      : completedEvaluations / startedEvaluations;
  @override
  List<Object?> get props => [
    newCompanies,
    activeCompanies,
    evaluatedPeople,
    startedEvaluations,
    completedEvaluations,
    affinitiesDetected,
    processesCreated,
    processesClosed,
    daily,
  ];
}

class CompanyDetail extends Equatable {
  const CompanyDetail({
    required this.company,
    this.processes = const [],
    this.activity = const [],
    this.people = const [],
  });
  final Company company;
  final List<TalentProcess> processes;
  final List<ActivityEvent> activity;
  final List<PersonEvaluation> people;
  @override
  List<Object?> get props => [company, processes, activity, people];
}

class AdminUserAccount extends Equatable {
  const AdminUserAccount({
    required this.id,
    required this.email,
    required this.role,
    required this.isActive,
    this.displayName,
    this.companyName,
  });
  final String id, email, role;
  final bool isActive;
  final String? displayName, companyName;
  @override
  List<Object?> get props => [id, email, role, isActive];
}

class XebecMessage extends Equatable {
  const XebecMessage({required this.fromXebec, required this.text});
  final bool fromXebec;
  final String text;
  @override
  List<Object?> get props => [fromXebec, text];
}

class AdminDashboardData extends Equatable {
  const AdminDashboardData({
    required this.metrics,
    required this.funnel,
    required this.activity,
    required this.alerts,
  });
  final AdminMetrics metrics;
  final AdminFunnel funnel;
  final List<ActivityEvent> activity;
  final List<AdminAlert> alerts;
  @override
  List<Object?> get props => [metrics, funnel, activity, alerts];
}
