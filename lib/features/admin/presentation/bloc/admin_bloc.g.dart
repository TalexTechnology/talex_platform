// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'admin_bloc.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$AdminStateCWProxy {
  AdminState status(AdminViewStatus status);

  AdminState section(AdminSection section);

  AdminState failure(Failure? failure);

  AdminState operation(AdminOperation? operation);

  AdminState query(String query);

  AdminState period(AnalyticsPeriod period);

  AdminState customFrom(DateTime? customFrom);

  AdminState customTo(DateTime? customTo);

  AdminState metrics(AdminMetrics? metrics);

  AdminState funnel(AdminFunnel? funnel);

  AdminState activity(List<ActivityEvent> activity);

  AdminState alerts(List<AdminAlert> alerts);

  AdminState companies(List<Company> companies);

  AdminState companyStatus(CompanyStatus? companyStatus);

  AdminState archivedOnly(bool archivedOnly);

  AdminState selectedCompany(CompanyDetail? selectedCompany);

  AdminState showCompanyDetail(bool showCompanyDetail);

  AdminState selectedPerson(PersonEvaluation? selectedPerson);

  AdminState selectedProcess(TalentProcess? selectedProcess);

  AdminState processes(List<TalentProcess> processes);

  AdminState processStatus(ProcessStatus? processStatus);

  AdminState people(List<PersonEvaluation> people);

  AdminState evaluationStatus(EvaluationStatus? evaluationStatus);

  AdminState affinity(AffinitySummary? affinity);

  AdminState deals(List<Deal> deals);

  AdminState dealStage(DealStage? dealStage);

  AdminState cultureLeads(List<CultureLead> cultureLeads);

  AdminState cultureLeadStatus(CultureLeadStatus? cultureLeadStatus);

  AdminState sales(List<Sale> sales);

  AdminState salesSummary(SalesSummary? salesSummary);

  AdminState analytics(AnalyticsSnapshot? analytics);

  AdminState users(List<AdminUserAccount> users);

  AdminState xebecMessages(List<XebecMessage> xebecMessages);

  /// Creates a new instance with the provided field values.
  /// Passing `null` to a nullable field nullifies it, while `null` for a non-nullable field is ignored. To update a single field use `AdminState(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// AdminState(...).copyWith(id: 12, name: "My name")
  /// ```
  AdminState call({
    AdminViewStatus status,
    AdminSection section,
    Failure? failure,
    AdminOperation? operation,
    String query,
    AnalyticsPeriod period,
    DateTime? customFrom,
    DateTime? customTo,
    AdminMetrics? metrics,
    AdminFunnel? funnel,
    List<ActivityEvent> activity,
    List<AdminAlert> alerts,
    List<Company> companies,
    CompanyStatus? companyStatus,
    bool archivedOnly,
    CompanyDetail? selectedCompany,
    bool showCompanyDetail,
    PersonEvaluation? selectedPerson,
    TalentProcess? selectedProcess,
    List<TalentProcess> processes,
    ProcessStatus? processStatus,
    List<PersonEvaluation> people,
    EvaluationStatus? evaluationStatus,
    AffinitySummary? affinity,
    List<Deal> deals,
    DealStage? dealStage,
    List<CultureLead> cultureLeads,
    CultureLeadStatus? cultureLeadStatus,
    List<Sale> sales,
    SalesSummary? salesSummary,
    AnalyticsSnapshot? analytics,
    List<AdminUserAccount> users,
    List<XebecMessage> xebecMessages,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfAdminState.copyWith(...)` or call `instanceOfAdminState.copyWith.fieldName(value)` for a single field.
class _$AdminStateCWProxyImpl implements _$AdminStateCWProxy {
  const _$AdminStateCWProxyImpl(this._value);

  final AdminState _value;

  @override
  AdminState status(AdminViewStatus status) => call(status: status);

  @override
  AdminState section(AdminSection section) => call(section: section);

  @override
  AdminState failure(Failure? failure) => call(failure: failure);

  @override
  AdminState operation(AdminOperation? operation) => call(operation: operation);

  @override
  AdminState query(String query) => call(query: query);

  @override
  AdminState period(AnalyticsPeriod period) => call(period: period);

  @override
  AdminState customFrom(DateTime? customFrom) => call(customFrom: customFrom);

  @override
  AdminState customTo(DateTime? customTo) => call(customTo: customTo);

  @override
  AdminState metrics(AdminMetrics? metrics) => call(metrics: metrics);

  @override
  AdminState funnel(AdminFunnel? funnel) => call(funnel: funnel);

  @override
  AdminState activity(List<ActivityEvent> activity) => call(activity: activity);

  @override
  AdminState alerts(List<AdminAlert> alerts) => call(alerts: alerts);

  @override
  AdminState companies(List<Company> companies) => call(companies: companies);

  @override
  AdminState companyStatus(CompanyStatus? companyStatus) =>
      call(companyStatus: companyStatus);

  @override
  AdminState archivedOnly(bool archivedOnly) => call(archivedOnly: archivedOnly);

  @override
  AdminState selectedCompany(CompanyDetail? selectedCompany) =>
      call(selectedCompany: selectedCompany);

  @override
  AdminState showCompanyDetail(bool showCompanyDetail) =>
      call(showCompanyDetail: showCompanyDetail);

  @override
  AdminState selectedPerson(PersonEvaluation? selectedPerson) =>
      call(selectedPerson: selectedPerson);

  @override
  AdminState selectedProcess(TalentProcess? selectedProcess) =>
      call(selectedProcess: selectedProcess);

  @override
  AdminState processes(List<TalentProcess> processes) =>
      call(processes: processes);

  @override
  AdminState processStatus(ProcessStatus? processStatus) =>
      call(processStatus: processStatus);

  @override
  AdminState people(List<PersonEvaluation> people) => call(people: people);

  @override
  AdminState evaluationStatus(EvaluationStatus? evaluationStatus) =>
      call(evaluationStatus: evaluationStatus);

  @override
  AdminState affinity(AffinitySummary? affinity) => call(affinity: affinity);

  @override
  AdminState deals(List<Deal> deals) => call(deals: deals);

  @override
  AdminState dealStage(DealStage? dealStage) => call(dealStage: dealStage);

  @override
  AdminState cultureLeads(List<CultureLead> cultureLeads) =>
      call(cultureLeads: cultureLeads);

  @override
  AdminState cultureLeadStatus(CultureLeadStatus? cultureLeadStatus) =>
      call(cultureLeadStatus: cultureLeadStatus);

  @override
  AdminState sales(List<Sale> sales) => call(sales: sales);

  @override
  AdminState salesSummary(SalesSummary? salesSummary) =>
      call(salesSummary: salesSummary);

  @override
  AdminState analytics(AnalyticsSnapshot? analytics) =>
      call(analytics: analytics);

  @override
  AdminState users(List<AdminUserAccount> users) => call(users: users);

  @override
  AdminState xebecMessages(List<XebecMessage> xebecMessages) =>
      call(xebecMessages: xebecMessages);

  /// Creates a new instance with the provided field values.
  /// Passing `null` to a nullable field nullifies it, while `null` for a non-nullable field is ignored. To update a single field use `AdminState(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// AdminState(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  AdminState call({
    Object? status = const $CopyWithPlaceholder(),
    Object? section = const $CopyWithPlaceholder(),
    Object? failure = const $CopyWithPlaceholder(),
    Object? operation = const $CopyWithPlaceholder(),
    Object? query = const $CopyWithPlaceholder(),
    Object? period = const $CopyWithPlaceholder(),
    Object? customFrom = const $CopyWithPlaceholder(),
    Object? customTo = const $CopyWithPlaceholder(),
    Object? metrics = const $CopyWithPlaceholder(),
    Object? funnel = const $CopyWithPlaceholder(),
    Object? activity = const $CopyWithPlaceholder(),
    Object? alerts = const $CopyWithPlaceholder(),
    Object? companies = const $CopyWithPlaceholder(),
    Object? companyStatus = const $CopyWithPlaceholder(),
    Object? archivedOnly = const $CopyWithPlaceholder(),
    Object? selectedCompany = const $CopyWithPlaceholder(),
    Object? showCompanyDetail = const $CopyWithPlaceholder(),
    Object? selectedPerson = const $CopyWithPlaceholder(),
    Object? selectedProcess = const $CopyWithPlaceholder(),
    Object? processes = const $CopyWithPlaceholder(),
    Object? processStatus = const $CopyWithPlaceholder(),
    Object? people = const $CopyWithPlaceholder(),
    Object? evaluationStatus = const $CopyWithPlaceholder(),
    Object? affinity = const $CopyWithPlaceholder(),
    Object? deals = const $CopyWithPlaceholder(),
    Object? dealStage = const $CopyWithPlaceholder(),
    Object? cultureLeads = const $CopyWithPlaceholder(),
    Object? cultureLeadStatus = const $CopyWithPlaceholder(),
    Object? sales = const $CopyWithPlaceholder(),
    Object? salesSummary = const $CopyWithPlaceholder(),
    Object? analytics = const $CopyWithPlaceholder(),
    Object? users = const $CopyWithPlaceholder(),
    Object? xebecMessages = const $CopyWithPlaceholder(),
  }) {
    return AdminState(
      status: status == const $CopyWithPlaceholder() || status == null
          ? _value.status
          // ignore: cast_nullable_to_non_nullable
          : status as AdminViewStatus,
      section: section == const $CopyWithPlaceholder() || section == null
          ? _value.section
          // ignore: cast_nullable_to_non_nullable
          : section as AdminSection,
      failure: failure == const $CopyWithPlaceholder()
          ? _value.failure
          // ignore: cast_nullable_to_non_nullable
          : failure as Failure?,
      operation: operation == const $CopyWithPlaceholder()
          ? _value.operation
          // ignore: cast_nullable_to_non_nullable
          : operation as AdminOperation?,
      query: query == const $CopyWithPlaceholder() || query == null
          ? _value.query
          // ignore: cast_nullable_to_non_nullable
          : query as String,
      period: period == const $CopyWithPlaceholder() || period == null
          ? _value.period
          // ignore: cast_nullable_to_non_nullable
          : period as AnalyticsPeriod,
      customFrom: customFrom == const $CopyWithPlaceholder()
          ? _value.customFrom
          // ignore: cast_nullable_to_non_nullable
          : customFrom as DateTime?,
      customTo: customTo == const $CopyWithPlaceholder()
          ? _value.customTo
          // ignore: cast_nullable_to_non_nullable
          : customTo as DateTime?,
      metrics: metrics == const $CopyWithPlaceholder()
          ? _value.metrics
          // ignore: cast_nullable_to_non_nullable
          : metrics as AdminMetrics?,
      funnel: funnel == const $CopyWithPlaceholder()
          ? _value.funnel
          // ignore: cast_nullable_to_non_nullable
          : funnel as AdminFunnel?,
      activity: activity == const $CopyWithPlaceholder() || activity == null
          ? _value.activity
          // ignore: cast_nullable_to_non_nullable
          : activity as List<ActivityEvent>,
      alerts: alerts == const $CopyWithPlaceholder() || alerts == null
          ? _value.alerts
          // ignore: cast_nullable_to_non_nullable
          : alerts as List<AdminAlert>,
      companies: companies == const $CopyWithPlaceholder() || companies == null
          ? _value.companies
          // ignore: cast_nullable_to_non_nullable
          : companies as List<Company>,
      companyStatus: companyStatus == const $CopyWithPlaceholder()
          ? _value.companyStatus
          // ignore: cast_nullable_to_non_nullable
          : companyStatus as CompanyStatus?,
      archivedOnly:
          archivedOnly == const $CopyWithPlaceholder() || archivedOnly == null
          ? _value.archivedOnly
          // ignore: cast_nullable_to_non_nullable
          : archivedOnly as bool,
      selectedCompany: selectedCompany == const $CopyWithPlaceholder()
          ? _value.selectedCompany
          // ignore: cast_nullable_to_non_nullable
          : selectedCompany as CompanyDetail?,
      showCompanyDetail:
          showCompanyDetail == const $CopyWithPlaceholder() ||
              showCompanyDetail == null
          ? _value.showCompanyDetail
          // ignore: cast_nullable_to_non_nullable
          : showCompanyDetail as bool,
      selectedPerson: selectedPerson == const $CopyWithPlaceholder()
          ? _value.selectedPerson
          // ignore: cast_nullable_to_non_nullable
          : selectedPerson as PersonEvaluation?,
      selectedProcess: selectedProcess == const $CopyWithPlaceholder()
          ? _value.selectedProcess
          // ignore: cast_nullable_to_non_nullable
          : selectedProcess as TalentProcess?,
      processes: processes == const $CopyWithPlaceholder() || processes == null
          ? _value.processes
          // ignore: cast_nullable_to_non_nullable
          : processes as List<TalentProcess>,
      processStatus: processStatus == const $CopyWithPlaceholder()
          ? _value.processStatus
          // ignore: cast_nullable_to_non_nullable
          : processStatus as ProcessStatus?,
      people: people == const $CopyWithPlaceholder() || people == null
          ? _value.people
          // ignore: cast_nullable_to_non_nullable
          : people as List<PersonEvaluation>,
      evaluationStatus: evaluationStatus == const $CopyWithPlaceholder()
          ? _value.evaluationStatus
          // ignore: cast_nullable_to_non_nullable
          : evaluationStatus as EvaluationStatus?,
      affinity: affinity == const $CopyWithPlaceholder()
          ? _value.affinity
          // ignore: cast_nullable_to_non_nullable
          : affinity as AffinitySummary?,
      deals: deals == const $CopyWithPlaceholder() || deals == null
          ? _value.deals
          // ignore: cast_nullable_to_non_nullable
          : deals as List<Deal>,
      dealStage: dealStage == const $CopyWithPlaceholder()
          ? _value.dealStage
          // ignore: cast_nullable_to_non_nullable
          : dealStage as DealStage?,
      cultureLeads:
          cultureLeads == const $CopyWithPlaceholder() || cultureLeads == null
          ? _value.cultureLeads
          // ignore: cast_nullable_to_non_nullable
          : cultureLeads as List<CultureLead>,
      cultureLeadStatus: cultureLeadStatus == const $CopyWithPlaceholder()
          ? _value.cultureLeadStatus
          // ignore: cast_nullable_to_non_nullable
          : cultureLeadStatus as CultureLeadStatus?,
      sales: sales == const $CopyWithPlaceholder() || sales == null
          ? _value.sales
          // ignore: cast_nullable_to_non_nullable
          : sales as List<Sale>,
      salesSummary: salesSummary == const $CopyWithPlaceholder()
          ? _value.salesSummary
          // ignore: cast_nullable_to_non_nullable
          : salesSummary as SalesSummary?,
      analytics: analytics == const $CopyWithPlaceholder()
          ? _value.analytics
          // ignore: cast_nullable_to_non_nullable
          : analytics as AnalyticsSnapshot?,
      users: users == const $CopyWithPlaceholder() || users == null
          ? _value.users
          // ignore: cast_nullable_to_non_nullable
          : users as List<AdminUserAccount>,
      xebecMessages:
          xebecMessages == const $CopyWithPlaceholder() || xebecMessages == null
          ? _value.xebecMessages
          // ignore: cast_nullable_to_non_nullable
          : xebecMessages as List<XebecMessage>,
    );
  }
}

extension $AdminStateCopyWith on AdminState {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfAdminState.copyWith(...)` or `instanceOfAdminState.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$AdminStateCWProxy get copyWith => _$AdminStateCWProxyImpl(this);

  /// Returns a copy of the object with the selected fields set to `null`.
  /// A flag set to `false` leaves the field unchanged. Prefer `copyWith(field: null)` or `copyWith.fieldName(null)` for single-field updates.
  ///
  /// Example:
  /// ```dart
  /// AdminState(...).copyWithNull(firstField: true, secondField: true)
  /// ```
  AdminState copyWithNull({
    bool failure = false,
    bool operation = false,
    bool customFrom = false,
    bool customTo = false,
    bool metrics = false,
    bool funnel = false,
    bool companyStatus = false,
    bool selectedCompany = false,
    bool selectedPerson = false,
    bool selectedProcess = false,
    bool processStatus = false,
    bool evaluationStatus = false,
    bool affinity = false,
    bool dealStage = false,
    bool cultureLeadStatus = false,
    bool salesSummary = false,
    bool analytics = false,
  }) {
    return AdminState(
      status: status,
      section: section,
      failure: failure == true ? null : this.failure,
      operation: operation == true ? null : this.operation,
      query: query,
      period: period,
      customFrom: customFrom == true ? null : this.customFrom,
      customTo: customTo == true ? null : this.customTo,
      metrics: metrics == true ? null : this.metrics,
      funnel: funnel == true ? null : this.funnel,
      activity: activity,
      alerts: alerts,
      companies: companies,
      companyStatus: companyStatus == true ? null : this.companyStatus,
      archivedOnly: archivedOnly,
      selectedCompany: selectedCompany == true ? null : this.selectedCompany,
      showCompanyDetail: showCompanyDetail,
      selectedPerson: selectedPerson == true ? null : this.selectedPerson,
      selectedProcess: selectedProcess == true ? null : this.selectedProcess,
      processes: processes,
      processStatus: processStatus == true ? null : this.processStatus,
      people: people,
      evaluationStatus: evaluationStatus == true ? null : this.evaluationStatus,
      affinity: affinity == true ? null : this.affinity,
      deals: deals,
      dealStage: dealStage == true ? null : this.dealStage,
      cultureLeads: cultureLeads,
      cultureLeadStatus: cultureLeadStatus == true
          ? null
          : this.cultureLeadStatus,
      sales: sales,
      salesSummary: salesSummary == true ? null : this.salesSummary,
      analytics: analytics == true ? null : this.analytics,
      users: users,
      xebecMessages: xebecMessages,
    );
  }
}
