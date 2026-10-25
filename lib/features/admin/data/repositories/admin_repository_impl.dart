import 'package:dartz/dartz.dart';
import 'package:talex_platform/core/error/exceptions.dart';
import 'package:talex_platform/core/error/failure.dart';
import 'package:talex_platform/features/admin/data/datasources/admin_data_source.dart';
import 'package:talex_platform/features/admin/domain/entities/admin_entities.dart';
import 'package:talex_platform/features/admin/domain/repositories/admin_repository.dart';

final class AdminRepositoryImpl implements AdminRepository {
  const AdminRepositoryImpl(this._source);
  final AdminDataSource _source;

  Future<Either<Failure, T>> _guard<T>(Future<T> Function() action) async {
    try {
      return Right(await action());
    } on ServerException catch (error) {
      return Left(ServerFailure(error.message));
    } catch (_) {
      return const Left(
        UnexpectedFailure(
          'No se pudo completar la operación. Inténtalo nuevamente.',
        ),
      );
    }
  }

  @override
  Future<Either<Failure, AdminDashboardData>> getDashboard() =>
      _guard(_source.getDashboard);

  @override
  Future<Either<Failure, List<Company>>> getCompanies({
    String query = '',
    CompanyStatus? status,
    bool archivedOnly = false,
  }) => _guard(
    () => _source.getCompanies(
      query: query,
      status: status,
      archivedOnly: archivedOnly,
    ),
  );

  @override
  Future<Either<Failure, CompanyDetail>> getCompany(String id) =>
      _guard(() => _source.getCompany(id));

  @override
  Future<Either<Failure, List<TalentProcess>>> getProcesses({
    String query = '',
    String? companyId,
    ProcessStatus? status,
  }) => _guard(
    () => _source.getProcesses(query: query, companyId: companyId, status: status),
  );

  @override
  Future<Either<Failure, List<PersonEvaluation>>> getPeople({
    String query = '',
    String? companyId,
    EvaluationStatus? status,
  }) => _guard(
    () => _source.getPeople(query: query, companyId: companyId, status: status),
  );

  @override
  Future<Either<Failure, AffinitySummary>> getAffinitySummary({
    String? companyId,
  }) => _guard(() => _source.getAffinitySummary(companyId: companyId));

  @override
  Future<Either<Failure, List<Deal>>> getDeals({
    String query = '',
    DealStage? stage,
  }) => _guard(() => _source.getDeals(query: query, stage: stage));

  @override
  Future<Either<Failure, List<CultureLead>>> listCultureLeads({
    String query = '',
    CultureLeadStatus? status,
  }) => _guard(() => _source.listCultureLeads(query: query, status: status));

  @override
  Future<Either<Failure, Unit>> updateCultureLeadStatus({
    required String id,
    required CultureLeadStatus status,
  }) => _guard(() async {
    await _source.updateCultureLeadStatus(id: id, status: status);
    return unit;
  });

  @override
  Future<Either<Failure, (SalesSummary, List<Sale>)>> getSales({
    required DateTime from,
    required DateTime to,
  }) => _guard(() => _source.getSales(from: from, to: to));

  @override
  Future<Either<Failure, AnalyticsSnapshot>> getAnalytics({
    required DateTime from,
    required DateTime to,
  }) => _guard(() => _source.getAnalytics(from: from, to: to));

  @override
  Future<Either<Failure, List<AdminAlert>>> getAlerts() =>
      _guard(_source.getAlerts);

  @override
  Future<Either<Failure, List<AdminUserAccount>>> getUsers() =>
      _guard(_source.getUsers);

  @override
  Future<Either<Failure, Unit>> createCompany({
    required String name,
    required CompanyStatus status,
    String? plan,
  }) => _guard(() async {
    await _source.createCompany(name: name, status: status, plan: plan);
    return unit;
  });

  @override
  Future<Either<Failure, Unit>> createProcess({
    required String companyId,
    required String name,
  }) => _guard(() async {
    await _source.createProcess(companyId: companyId, name: name);
    return unit;
  });

  @override
  Future<Either<Failure, Unit>> createPerson({
    required String companyId,
    required String processId,
    required String displayName,
    required EvaluationStatus status,
    double? affinityScore,
  }) => _guard(() async {
    await _source.createPerson(
      companyId: companyId,
      processId: processId,
      displayName: displayName,
      status: status,
      affinityScore: affinityScore,
    );
    return unit;
  });

  @override
  Future<Either<Failure, Unit>> createDeal({
    required String companyId,
    required DealStage stage,
    double? estimatedValue,
    String? ownerName,
    String? nextAction,
  }) => _guard(() async {
    await _source.createDeal(
      companyId: companyId,
      stage: stage,
      estimatedValue: estimatedValue,
      ownerName: ownerName,
      nextAction: nextAction,
    );
    return unit;
  });

  @override
  Future<Either<Failure, Unit>> createSale({
    required String companyId,
    required double amount,
    String? product,
    bool recurring = false,
  }) => _guard(() async {
    await _source.createSale(
      companyId: companyId,
      amount: amount,
      product: product,
      recurring: recurring,
    );
    return unit;
  });

  @override
  Future<Either<Failure, Unit>> updateUserRole({
    required String userId,
    required String role,
  }) => _guard(() async {
    await _source.updateUserRole(userId: userId, role: role);
    return unit;
  });

  @override
  Future<Either<Failure, Unit>> applyCompanyLifecycle({
    required String id,
    required CompanyLifecycleAction action,
  }) => _guard(() async {
    await _source.applyCompanyLifecycle(id: id, action: action);
    return unit;
  });

  @override
  Future<Either<Failure, Unit>> updatePerson({
    required String id,
    required String displayName,
    required EvaluationStatus status,
  }) => _guard(() async {
    await _source.updatePerson(
      id: id,
      displayName: displayName,
      status: status,
    );
    return unit;
  });

  @override
  Future<Either<Failure, Unit>> updateCompany({
    required Company company,
    List<int>? logoBytes,
    String? logoContentType,
  }) => _guard(() async {
    await _source.updateCompany(
      company: company,
      logoBytes: logoBytes,
      logoContentType: logoContentType,
    );
    return unit;
  });
}
