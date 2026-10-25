import 'dart:async';
import 'dart:typed_data';

import 'package:dartz/dartz.dart';
import 'package:talex_platform/core/auth/user_role.dart';
import 'package:talex_platform/core/error/exceptions.dart';
import 'package:talex_platform/core/error/failure.dart';
import 'package:talex_platform/features/talent/data/datasources/talent_data_source.dart';
import 'package:talex_platform/features/talent/data/services/invite_email_service.dart';
import 'package:talex_platform/features/talent/domain/entities/talent_entities.dart';
import 'package:talex_platform/features/talent/domain/repositories/talent_repository.dart';
import 'package:talex_platform/features/talent/domain/talent_error_codes.dart';

final class TalentRepositoryImpl implements TalentRepository {
  const TalentRepositoryImpl(this._source, [this._email]);
  final TalentDataSource _source;
  final InviteEmailService? _email;

  Future<Either<Failure, T>> _guard<T>(Future<T> Function() action) async {
    try {
      return Right(await action());
    } on ServerException catch (error) {
      return Left(ServerFailure(error.message));
    } catch (_) {
      return const Left(
        UnexpectedFailure(TalentErrorCodes.unexpected),
      );
    }
  }

  @override
  Future<Either<Failure, TalentSnapshot>> loadCompany(String companyId) =>
      _guard(() => _source.loadCompany(companyId));

  @override
  Future<Either<Failure, Unit>> saveCompanyProfile(CompanyProfile profile) =>
      _guard(() async {
        await _source.saveCompanyProfile(profile);
        return unit;
      });

  @override
  Future<Either<Failure, Unit>> createVacancy(Vacancy vacancy) =>
      _guard(() async {
        await _source.createVacancy(vacancy);
        return unit;
      });

  @override
  Future<Either<Failure, String>> createRespondent({
    required String companyId,
    required String vacancyId,
    required String email,
    required String documentNumber,
    String? displayName,
  }) => _guard(
    () => _source.createRespondent(
      companyId: companyId,
      vacancyId: vacancyId,
      email: email,
      documentNumber: documentNumber,
      displayName: displayName,
    ),
  );

  @override
  Future<Either<Failure, String>> provisionCompany({
    required CompanyProfile profile,
    required String recruiterFirstName,
    required String recruiterLastName,
    required String recruiterEmail,
    Uint8List? logoBytes,
    String? logoContentType,
  }) => _guard(
    () => _source.provisionCompany(
      profile: profile,
      recruiterFirstName: recruiterFirstName,
      recruiterLastName: recruiterLastName,
      recruiterEmail: recruiterEmail,
      logoBytes: logoBytes,
      logoContentType: logoContentType,
    ),
  );

  @override
  Future<Either<Failure, Unit>> activateWithPin({required String pin}) =>
      _guard(() async {
        await _source.activateWithPin(pin: pin);
        return unit;
      });

  @override
  Future<Either<Failure, String>> redeemRespondentInvite({
    required String token,
  }) =>
      _guard(
        () => _source.redeemRespondentInvite(token: token),
      );

  @override
  Future<Either<Failure, String>> inviteRecruiter({
    required String companyId,
    required String email,
    required String firstName,
    required String lastName,
    UserRole role = UserRole.recruiter,
  }) => _guard(
    () => _source.inviteRecruiter(
      companyId: companyId,
      email: email,
      firstName: firstName,
      lastName: lastName,
      role: role,
    ),
  );

  @override
  Future<Either<Failure, Unit>> updateCandidateStatus({
    required String candidateId,
    required CandidateProcessStatus status,
  }) => _guard(() async {
    await _source.updateCandidateStatus(
      candidateId: candidateId,
      status: status,
    );
    return unit;
  });

  @override
  Future<Either<Failure, Unit>> updateCandidate({
    required String candidateId,
    required String displayName,
    required String documentNumber,
    required String vacancyId,
  }) => _guard(() async {
    await _source.updateCandidate(
      candidateId: candidateId,
      displayName: displayName,
      documentNumber: documentNumber,
      vacancyId: vacancyId,
    );
    return unit;
  });

  @override
  Future<Either<Failure, Unit>> deleteCandidate(String candidateId) =>
      _guard(() async {
        await _source.deleteCandidate(candidateId);
        return unit;
      });

  @override
  Future<Either<Failure, RespondentSession>> loadRespondentSession() =>
      _guard(_source.loadRespondentSession);

  @override
  Future<Either<Failure, Unit>> saveAnswer({
    required String candidateId,
    required String questionId,
    required int value,
  }) => _guard(() async {
    await _source.saveAnswer(
      candidateId: candidateId,
      questionId: questionId,
      value: value,
    );
    return unit;
  });

  @override
  Future<Either<Failure, TalentCandidate>> completeEvaluation(
    String candidateId, {
    String locale = 'es',
  }) => _guard(() async {
    final candidate = await _source.completeEvaluation(candidateId);
    final mail = _email?.sendAssessmentComplete(
      to: candidate.email,
      firstName: (candidate.displayName ?? '').split(' ').first,
      companyName: '',
      locale: locale,
      vacancyName: candidate.vacancyName,
    );
    if (mail != null) unawaited(mail);
    return candidate;
  });

  @override
  Future<Either<Failure, Unit>> requestSurveyResult(String candidateId) =>
      _guard(() async {
        await _source.requestSurveyResult(candidateId);
        return unit;
      });

  @override
  Future<Either<Failure, CandidateReport>> loadCandidateReport(
    String candidateId,
  ) => _guard(() => _source.loadCandidateReport(candidateId));

  @override
  Future<Either<Failure, AffinityAnalysis>> loadAffinityAnalysis(
    String candidateId,
  ) => _guard(() => _source.loadAffinityAnalysis(candidateId));

  @override
  Future<Either<Failure, AffinityAnalysis>> requestAffinityAnalysis(
    String candidateId,
  ) => _guard(() => _source.requestAffinityAnalysis(candidateId));

  @override
  Future<Either<Failure, Unit>> saveAssessmentKind({
    required String candidateId,
    required AssessmentKind kind,
  }) => _guard(() async {
    await _source.saveAssessmentKind(candidateId: candidateId, kind: kind);
    return unit;
  });

  @override
  Future<Either<Failure, Unit>> changePassword(String newPassword) =>
      _guard(() async {
        await _source.changePassword(newPassword);
        return unit;
      });

  @override
  Future<Either<Failure, List<DnaCatalogEntry>>> loadDnaCatalog() =>
      _guard(_source.loadDnaCatalog);

  @override
  Future<Either<Failure, Unit>> deleteDnaCatalogOption({
    required String type,
    required String label,
  }) => _guard(() async {
    await _source.deleteDnaCatalogOption(type: type, label: label);
    return unit;
  });
}
