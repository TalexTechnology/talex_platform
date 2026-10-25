part of 'admin_bloc.dart';

enum AdminViewStatus { initial, loading, submitting, success, failure }

enum AdminOperation { saved }

@CopyWith(copyWithNull: true)
class AdminState extends Equatable {
  const AdminState({
    this.status = AdminViewStatus.initial,
    this.section = AdminSection.dashboard,
    this.failure,
    this.operation,
    this.query = '',
    this.period = AnalyticsPeriod.d30,
    this.customFrom,
    this.customTo,
    this.metrics,
    this.funnel,
    this.activity = const [],
    this.alerts = const [],
    this.companies = const [],
    this.companyStatus,
    this.archivedOnly = false,
    this.selectedCompany,
    this.showCompanyDetail = false,
    this.selectedPerson,
    this.selectedProcess,
    this.processes = const [],
    this.processStatus,
    this.people = const [],
    this.evaluationStatus,
    this.affinity,
    this.deals = const [],
    this.dealStage,
    this.cultureLeads = const [],
    this.cultureLeadStatus,
    this.sales = const [],
    this.salesSummary,
    this.analytics,
    this.users = const [],
    this.xebecMessages = const [],
  });

  final AdminViewStatus status;
  final AdminSection section;
  final Failure? failure;
  final AdminOperation? operation;
  final String query;
  final AnalyticsPeriod period;
  final DateTime? customFrom, customTo;
  final AdminMetrics? metrics;
  final AdminFunnel? funnel;
  final List<ActivityEvent> activity;
  final List<AdminAlert> alerts;
  final List<Company> companies;
  final CompanyStatus? companyStatus;
  final bool archivedOnly;
  final CompanyDetail? selectedCompany;
  final bool showCompanyDetail;
  final PersonEvaluation? selectedPerson;
  final TalentProcess? selectedProcess;
  final List<TalentProcess> processes;
  final ProcessStatus? processStatus;
  final List<PersonEvaluation> people;
  final EvaluationStatus? evaluationStatus;
  final AffinitySummary? affinity;
  final List<Deal> deals;
  final DealStage? dealStage;
  final List<CultureLead> cultureLeads;
  final CultureLeadStatus? cultureLeadStatus;
  final List<Sale> sales;
  final SalesSummary? salesSummary;
  final AnalyticsSnapshot? analytics;
  final List<AdminUserAccount> users;
  final List<XebecMessage> xebecMessages;

  @override
  List<Object?> get props => [
    status,
    section,
    failure,
    operation,
    query,
    period,
    customFrom,
    customTo,
    metrics,
    funnel,
    activity,
    alerts,
    companies,
    companyStatus,
    archivedOnly,
    selectedCompany,
    showCompanyDetail,
    selectedPerson,
    selectedProcess,
    processes,
    processStatus,
    people,
    evaluationStatus,
    affinity,
    deals,
    dealStage,
    cultureLeads,
    cultureLeadStatus,
    sales,
    salesSummary,
    analytics,
    users,
    xebecMessages,
  ];
}
