import 'package:dartz/dartz.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:talex_platform/core/error/failure.dart';
import 'package:talex_platform/features/admin/domain/entities/admin_entities.dart';
import 'package:talex_platform/features/admin/domain/repositories/admin_repository.dart';
import 'package:talex_platform/features/admin/domain/services/xebec_interpreter.dart';

part 'admin_event.dart';
part 'admin_state.dart';
part 'admin_bloc.g.dart';

class AdminBloc extends Bloc<AdminEvent, AdminState> {
  AdminBloc({required AdminRepository repository})
    : _repository = repository,
      super(const AdminState()) {
    on<AdminSectionSelected>(_onSection);
    on<AdminDashboardRequested>(_onDashboard);
    on<AdminCompaniesRequested>(_onCompanies);
    on<AdminCompanyOpened>(_onCompanyOpened);
    on<AdminCompanyClosed>(_onCompanyClosed);
    on<AdminCompanyUpdated>(_onCompanyUpdated);
    on<AdminPersonOpened>(_onPersonOpened);
    on<AdminPersonClosed>(_onPersonClosed);
    on<AdminPersonUpdated>(_onPersonUpdated);
    on<AdminProcessOpened>(_onProcessOpened);
    on<AdminProcessClosed>(_onProcessClosed);
    on<AdminProcessesRequested>(_onProcesses);
    on<AdminPeopleRequested>(_onPeople);
    on<AdminAffinityRequested>(_onAffinity);
    on<AdminDealsRequested>(_onDeals);
    on<AdminSalesRequested>(_onSales);
    on<AdminAnalyticsRequested>(_onAnalytics);
    on<AdminAlertsRequested>(_onAlerts);
    on<AdminUsersRequested>(_onUsers);
    on<AdminXebecAsked>(_onXebec);
    on<AdminCompanyCreated>(_onCreateCompany);
    on<AdminProcessCreated>(_onCreateProcess);
    on<AdminPersonCreated>(_onCreatePerson);
    on<AdminDealCreated>(_onCreateDeal);
    on<AdminSaleCreated>(_onCreateSale);
    on<AdminUserRoleUpdated>(_onUpdateRole);
    on<AdminCompanyLifecycleRequested>(_onCompanyLifecycle);
  }

  final AdminRepository _repository;

  DateTimeRange _range(AdminState current) {
    final now = DateTime.now();
    return switch (current.period) {
      AnalyticsPeriod.d7 => DateTimeRange(now.subtract(const Duration(days: 7)), now),
      AnalyticsPeriod.d30 => DateTimeRange(now.subtract(const Duration(days: 30)), now),
      AnalyticsPeriod.d90 => DateTimeRange(now.subtract(const Duration(days: 90)), now),
      AnalyticsPeriod.m12 => DateTimeRange(now.subtract(const Duration(days: 365)), now),
      AnalyticsPeriod.custom => DateTimeRange(
        current.customFrom ?? now.subtract(const Duration(days: 30)),
        current.customTo ?? now,
      ),
    };
  }

  Future<void> _onSection(
    AdminSectionSelected event,
    Emitter<AdminState> emit,
  ) async {
    emit(
      state.copyWith(
        section: event.section,
        showCompanyDetail: false,
        operation: null,
      ).copyWithNull(selectedPerson: true, selectedProcess: true),
    );
    switch (event.section) {
      case AdminSection.dashboard:
        add(const AdminDashboardRequested());
      case AdminSection.companies:
        add(const AdminCompaniesRequested());
      case AdminSection.processes:
        add(const AdminProcessesRequested());
      case AdminSection.people:
        add(const AdminPeopleRequested());
      case AdminSection.affinity:
        add(const AdminAffinityRequested());
      case AdminSection.commercial:
        add(const AdminDealsRequested());
      case AdminSection.sales:
        add(const AdminSalesRequested());
      case AdminSection.analytics:
        add(const AdminAnalyticsRequested());
      case AdminSection.alerts:
        add(const AdminAlertsRequested());
      case AdminSection.xebec:
        if (state.metrics == null) add(const AdminDashboardRequested());
      case AdminSection.questions:
      case AdminSection.cultureSurvey:
        break;
      case AdminSection.settings:
        add(const AdminUsersRequested());
    }
  }

  Future<void> _emitFailure(Failure failure, Emitter<AdminState> emit) async {
    emit(
      state.copyWith(
        status: AdminViewStatus.failure,
        failure: failure,
        operation: null,
      ),
    );
  }

  Future<void> _onDashboard(
    AdminDashboardRequested event,
    Emitter<AdminState> emit,
  ) async {
    emit(state.copyWith(status: AdminViewStatus.loading, failure: null, operation: null));
    final result = await _repository.getDashboard();
    result.fold((failure) => _emitFailure(failure, emit), (data) {
      emit(
        state.copyWith(
          status: AdminViewStatus.success,
          metrics: data.metrics,
          funnel: data.funnel,
          activity: data.activity,
          alerts: data.alerts,
          failure: null,
        ),
      );
    });
  }

  Future<void> _onCompanies(
    AdminCompaniesRequested event,
    Emitter<AdminState> emit,
  ) async {
    emit(
      state.copyWith(
        status: state.companies.isEmpty
            ? AdminViewStatus.loading
            : AdminViewStatus.success,
        query: event.query,
        companyStatus: event.status,
        archivedOnly: event.archivedOnly,
        failure: null,
      ),
    );
    final result = await _repository.getCompanies(
      query: event.query,
      status: event.status,
      archivedOnly: event.archivedOnly,
    );
    result.fold(
      (failure) => _emitFailure(failure, emit),
      (items) => emit(
        state.copyWith(
          status: AdminViewStatus.success,
          companies: items,
          failure: null,
        ),
      ),
    );
  }

  Future<void> _onCompanyOpened(
    AdminCompanyOpened event,
    Emitter<AdminState> emit,
  ) async {
    emit(state.copyWith(status: AdminViewStatus.loading, failure: null));
    final result = await _repository.getCompany(event.id);
    result.fold(
      (failure) => _emitFailure(failure, emit),
      (detail) => emit(
        state.copyWith(
          status: AdminViewStatus.success,
          selectedCompany: detail,
          showCompanyDetail: true,
          failure: null,
        ),
      ),
    );
  }

  Future<void> _onCompanyClosed(
    AdminCompanyClosed event,
    Emitter<AdminState> emit,
  ) async {
    emit(state.copyWith(showCompanyDetail: false, section: AdminSection.companies));
    add(
      AdminCompaniesRequested(
        query: state.query,
        status: state.companyStatus,
        archivedOnly: state.archivedOnly,
      ),
    );
  }

  Future<void> _onCompanyUpdated(
    AdminCompanyUpdated event,
    Emitter<AdminState> emit,
  ) async {
    final result = await _repository.updateCompany(
      company: event.company,
      logoBytes: event.logoBytes,
      logoContentType: event.logoContentType,
    );
    await result.fold((failure) async => _emitFailure(failure, emit), (_) async {
      final refreshed = await _repository.getCompany(event.company.id);
      refreshed.fold(
        (failure) => _emitFailure(failure, emit),
        (detail) => emit(
          state.copyWith(
            status: AdminViewStatus.success,
            selectedCompany: detail,
            showCompanyDetail: true,
            operation: AdminOperation.saved,
            failure: null,
          ),
        ),
      );
    });
  }

  Future<void> _onPersonOpened(
    AdminPersonOpened event,
    Emitter<AdminState> emit,
  ) async {
    emit(state.copyWith(selectedPerson: event.person, failure: null));
  }

  Future<void> _onPersonClosed(
    AdminPersonClosed event,
    Emitter<AdminState> emit,
  ) async {
    emit(state.copyWithNull(selectedPerson: true));
  }

  Future<void> _onPersonUpdated(
    AdminPersonUpdated event,
    Emitter<AdminState> emit,
  ) async {
    final result = await _repository.updatePerson(
      id: event.id,
      displayName: event.displayName,
      status: event.status,
    );
    await result.fold((failure) async => _emitFailure(failure, emit), (_) async {
      final refreshed = await _repository.getPeople(
        query: state.query,
        status: state.evaluationStatus,
      );
      refreshed.fold(
        (failure) => _emitFailure(failure, emit),
        (items) => emit(
          state.copyWith(
            status: AdminViewStatus.success,
            people: items,
            selectedPerson: items
                .where((item) => item.id == event.id)
                .firstOrNull,
            operation: AdminOperation.saved,
            failure: null,
          ),
        ),
      );
    });
  }

  Future<void> _onProcessOpened(
    AdminProcessOpened event,
    Emitter<AdminState> emit,
  ) async {
    emit(state.copyWith(selectedProcess: event.process, failure: null));
    final result = await _repository.getPeople(
      companyId: event.process.companyId,
    );
    result.fold(
      (failure) => emit(state.copyWith(failure: failure)),
      (items) => emit(
        state.copyWith(
          selectedProcess: event.process,
          people: items,
          failure: null,
        ),
      ),
    );
  }

  Future<void> _onProcessClosed(
    AdminProcessClosed event,
    Emitter<AdminState> emit,
  ) async {
    emit(state.copyWithNull(selectedProcess: true));
  }

  Future<void> _onProcesses(
    AdminProcessesRequested event,
    Emitter<AdminState> emit,
  ) async {
    emit(state.copyWith(status: AdminViewStatus.loading, query: event.query));
    final result = await _repository.getProcesses(
      query: event.query,
      companyId: event.companyId,
      status: event.status,
    );
    result.fold(
      (failure) => _emitFailure(failure, emit),
      (items) => emit(
        state.copyWith(
          status: AdminViewStatus.success,
          processes: items,
          processStatus: event.status,
          failure: null,
        ),
      ),
    );
  }

  Future<void> _onPeople(
    AdminPeopleRequested event,
    Emitter<AdminState> emit,
  ) async {
    emit(state.copyWith(status: AdminViewStatus.loading, query: event.query));
    final result = await _repository.getPeople(
      query: event.query,
      companyId: event.companyId,
      status: event.status,
    );
    result.fold(
      (failure) => _emitFailure(failure, emit),
      (items) => emit(
        state.copyWith(
          status: AdminViewStatus.success,
          people: items,
          evaluationStatus: event.status,
          failure: null,
        ),
      ),
    );
  }

  Future<void> _onAffinity(
    AdminAffinityRequested event,
    Emitter<AdminState> emit,
  ) async {
    emit(state.copyWith(status: AdminViewStatus.loading));
    final summary = await _repository.getAffinitySummary(companyId: event.companyId);
    final people = await _repository.getPeople(companyId: event.companyId);
    summary.fold((failure) => _emitFailure(failure, emit), (value) {
      people.fold(
        (failure) => _emitFailure(failure, emit),
        (items) => emit(
          state.copyWith(
            status: AdminViewStatus.success,
            affinity: value,
            people: items,
            failure: null,
          ),
        ),
      );
    });
  }

  Future<void> _onDeals(
    AdminDealsRequested event,
    Emitter<AdminState> emit,
  ) async {
    emit(state.copyWith(status: AdminViewStatus.loading, query: event.query));
    final result = await _repository.getDeals(query: event.query, stage: event.stage);
    result.fold(
      (failure) => _emitFailure(failure, emit),
      (items) => emit(
        state.copyWith(
          status: AdminViewStatus.success,
          deals: items,
          dealStage: event.stage,
          failure: null,
        ),
      ),
    );
  }

  Future<void> _onSales(
    AdminSalesRequested event,
    Emitter<AdminState> emit,
  ) async {
    emit(state.copyWith(status: AdminViewStatus.loading, period: event.period ?? state.period));
    final range = _range(state.copyWith(period: event.period ?? state.period));
    final result = await _repository.getSales(from: range.start, to: range.end);
    result.fold(
      (failure) => _emitFailure(failure, emit),
      (value) => emit(
        state.copyWith(
          status: AdminViewStatus.success,
          salesSummary: value.$1,
          sales: value.$2,
          failure: null,
        ),
      ),
    );
  }

  Future<void> _onAnalytics(
    AdminAnalyticsRequested event,
    Emitter<AdminState> emit,
  ) async {
    emit(
      state.copyWith(
        status: AdminViewStatus.loading,
        period: event.period ?? state.period,
        customFrom: event.from,
        customTo: event.to,
      ),
    );
    final range = _range(
      state.copyWith(
        period: event.period ?? state.period,
        customFrom: event.from,
        customTo: event.to,
      ),
    );
    final result = await _repository.getAnalytics(from: range.start, to: range.end);
    result.fold(
      (failure) => _emitFailure(failure, emit),
      (value) => emit(
        state.copyWith(
          status: AdminViewStatus.success,
          analytics: value,
          failure: null,
        ),
      ),
    );
  }

  Future<void> _onAlerts(
    AdminAlertsRequested event,
    Emitter<AdminState> emit,
  ) async {
    emit(state.copyWith(status: AdminViewStatus.loading));
    final result = await _repository.getAlerts();
    result.fold(
      (failure) => _emitFailure(failure, emit),
      (items) => emit(
        state.copyWith(status: AdminViewStatus.success, alerts: items, failure: null),
      ),
    );
  }

  Future<void> _onUsers(
    AdminUsersRequested event,
    Emitter<AdminState> emit,
  ) async {
    emit(state.copyWith(status: AdminViewStatus.loading));
    final result = await _repository.getUsers();
    result.fold(
      (failure) => _emitFailure(failure, emit),
      (items) => emit(
        state.copyWith(status: AdminViewStatus.success, users: items, failure: null),
      ),
    );
  }

  Future<void> _onXebec(AdminXebecAsked event, Emitter<AdminState> emit) async {
    if (state.metrics == null) {
      final dashboard = await _repository.getDashboard();
      await dashboard.fold((failure) async => _emitFailure(failure, emit), (
        data,
      ) async {
        emit(
          state.copyWith(
            metrics: data.metrics,
            alerts: data.alerts,
            activity: data.activity,
          ),
        );
      });
    }
    final companies = state.companies.isEmpty
        ? await _repository.getCompanies()
        : Right<Failure, List<Company>>(state.companies);
    final deals = state.deals.isEmpty
        ? await _repository.getDeals()
        : Right<Failure, List<Deal>>(state.deals);
    final companyList = companies.getOrElse(() => const []);
    final dealList = deals.getOrElse(() => const []);
    final answer = XebecInterpreter.answer(
      question: event.question,
      metrics: state.metrics ?? const AdminMetrics(),
      companies: companyList,
      deals: dealList,
      activity: state.activity,
      alerts: state.alerts,
    );
    emit(
      state.copyWith(
        xebecMessages: [
          ...state.xebecMessages,
          XebecMessage(fromXebec: false, text: event.question),
          XebecMessage(fromXebec: true, text: answer),
        ],
        status: AdminViewStatus.success,
      ),
    );
  }

  Future<void> _afterWrite(
    Emitter<AdminState> emit,
    Future<dynamic> Function() action,
  ) async {
    emit(state.copyWith(status: AdminViewStatus.submitting, failure: null, operation: null));
    final result = await action();
    await result.fold((Failure failure) async => _emitFailure(failure, emit), (
      _,
    ) async {
      emit(state.copyWith(operation: AdminOperation.saved, status: AdminViewStatus.success));
      add(AdminSectionSelected(state.section));
    });
  }

  Future<void> _onCreateCompany(
    AdminCompanyCreated event,
    Emitter<AdminState> emit,
  ) => _afterWrite(
    emit,
    () => _repository.createCompany(
      name: event.name,
      status: event.status,
      plan: event.plan,
    ),
  );

  Future<void> _onCreateProcess(
    AdminProcessCreated event,
    Emitter<AdminState> emit,
  ) => _afterWrite(
    emit,
    () => _repository.createProcess(companyId: event.companyId, name: event.name),
  );

  Future<void> _onCreatePerson(
    AdminPersonCreated event,
    Emitter<AdminState> emit,
  ) => _afterWrite(
    emit,
    () => _repository.createPerson(
      companyId: event.companyId,
      processId: event.processId,
      displayName: event.displayName,
      status: event.status,
      affinityScore: event.affinityScore,
    ),
  );

  Future<void> _onCreateDeal(
    AdminDealCreated event,
    Emitter<AdminState> emit,
  ) => _afterWrite(
    emit,
    () => _repository.createDeal(
      companyId: event.companyId,
      stage: event.stage,
      estimatedValue: event.estimatedValue,
      ownerName: event.ownerName,
      nextAction: event.nextAction,
    ),
  );

  Future<void> _onCreateSale(
    AdminSaleCreated event,
    Emitter<AdminState> emit,
  ) => _afterWrite(
    emit,
    () => _repository.createSale(
      companyId: event.companyId,
      amount: event.amount,
      product: event.product,
      recurring: event.recurring,
    ),
  );

  Future<void> _onUpdateRole(
    AdminUserRoleUpdated event,
    Emitter<AdminState> emit,
  ) => _afterWrite(
    emit,
    () => _repository.updateUserRole(userId: event.userId, role: event.role),
  );

  Future<void> _onCompanyLifecycle(
    AdminCompanyLifecycleRequested event,
    Emitter<AdminState> emit,
  ) async {
    emit(
      state.copyWith(
        status: AdminViewStatus.submitting,
        failure: null,
        operation: null,
      ),
    );
    final result = await _repository.applyCompanyLifecycle(
      id: event.id,
      action: event.action,
    );
    await result.fold((failure) async => _emitFailure(failure, emit), (_) async {
      emit(
        state.copyWith(
          operation: AdminOperation.saved,
          status: AdminViewStatus.success,
        ),
      );
      if (event.action == CompanyLifecycleAction.archive) {
        emit(state.copyWith(showCompanyDetail: false));
        add(
          AdminCompaniesRequested(
            query: state.query,
            status: state.companyStatus,
            archivedOnly: state.archivedOnly,
          ),
        );
        return;
      }
      if (state.showCompanyDetail) {
        add(AdminCompanyOpened(event.id));
        return;
      }
      add(
        AdminCompaniesRequested(
          query: state.query,
          status: state.companyStatus,
          archivedOnly: state.archivedOnly,
        ),
      );
    });
  }
}

class DateTimeRange {
  const DateTimeRange(this.start, this.end);
  final DateTime start, end;
}
