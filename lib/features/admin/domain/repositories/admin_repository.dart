import 'package:dartz/dartz.dart';
import 'package:talex_platform/core/error/failure.dart';
import 'package:talex_platform/core/usecase/usecase.dart';
import 'package:talex_platform/features/admin/domain/entities/admin_entities.dart';

abstract interface class AdminRepository {
  Future<Either<Failure, AdminDashboardData>> getDashboard();
  Future<Either<Failure, List<Company>>> getCompanies({
    String query,
    CompanyStatus? status,
    bool archivedOnly = false,
  });
  Future<Either<Failure, CompanyDetail>> getCompany(String id);
  Future<Either<Failure, List<TalentProcess>>> getProcesses({
    String query,
    String? companyId,
    ProcessStatus? status,
  });
  Future<Either<Failure, List<PersonEvaluation>>> getPeople({
    String query,
    String? companyId,
    EvaluationStatus? status,
  });
  Future<Either<Failure, AffinitySummary>> getAffinitySummary({String? companyId});
  Future<Either<Failure, List<Deal>>> getDeals({String query, DealStage? stage});
  Future<Either<Failure, List<CultureLead>>> listCultureLeads({
    String query,
    CultureLeadStatus? status,
  });
  Future<Either<Failure, Unit>> updateCultureLeadStatus({
    required String id,
    required CultureLeadStatus status,
  });
  Future<Either<Failure, (SalesSummary, List<Sale>)>> getSales({
    required DateTime from,
    required DateTime to,
  });
  Future<Either<Failure, AnalyticsSnapshot>> getAnalytics({
    required DateTime from,
    required DateTime to,
  });
  Future<Either<Failure, List<AdminAlert>>> getAlerts();
  Future<Either<Failure, List<AdminUserAccount>>> getUsers();
  Future<Either<Failure, Unit>> createCompany({
    required String name,
    required CompanyStatus status,
    String? plan,
  });
  Future<Either<Failure, Unit>> createProcess({
    required String companyId,
    required String name,
  });
  Future<Either<Failure, Unit>> createPerson({
    required String companyId,
    required String processId,
    required String displayName,
    required EvaluationStatus status,
    double? affinityScore,
  });
  Future<Either<Failure, Unit>> createDeal({
    required String companyId,
    required DealStage stage,
    double? estimatedValue,
    String? ownerName,
    String? nextAction,
  });
  Future<Either<Failure, Unit>> createSale({
    required String companyId,
    required double amount,
    String? product,
    bool recurring = false,
  });
  Future<Either<Failure, Unit>> updateUserRole({
    required String userId,
    required String role,
  });
  Future<Either<Failure, Unit>> applyCompanyLifecycle({
    required String id,
    required CompanyLifecycleAction action,
  });
  Future<Either<Failure, Unit>> updatePerson({
    required String id,
    required String displayName,
    required EvaluationStatus status,
  });
  Future<Either<Failure, Unit>> updateCompany({
    required Company company,
    List<int>? logoBytes,
    String? logoContentType,
  });
}

class GetAdminDashboard implements UseCase<AdminDashboardData, NoParams> {
  const GetAdminDashboard(this._repository);
  final AdminRepository _repository;
  @override
  Future<Either<Failure, AdminDashboardData>> call(NoParams params) =>
      _repository.getDashboard();
}
