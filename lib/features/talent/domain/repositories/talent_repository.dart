import 'dart:typed_data';

import 'package:dartz/dartz.dart';
import 'package:talex_platform/core/auth/user_role.dart';
import 'package:talex_platform/core/error/failure.dart';
import 'package:talex_platform/features/talent/domain/entities/talent_entities.dart';

abstract interface class TalentRepository {
  Future<Either<Failure, TalentSnapshot>> loadCompany(String companyId);
  Future<Either<Failure, Unit>> saveCompanyProfile(CompanyProfile profile);
  Future<Either<Failure, Unit>> createVacancy(Vacancy vacancy);
  Future<Either<Failure, String>> createRespondent({
    required String companyId,
    required String vacancyId,
    required String email,
    required String documentNumber,
    String? displayName,
  });
  Future<Either<Failure, String>> provisionCompany({
    required CompanyProfile profile,
    required String recruiterFirstName,
    required String recruiterLastName,
    required String recruiterEmail,
    Uint8List? logoBytes,
    String? logoContentType,
  });
  Future<Either<Failure, Unit>> activateWithPin({required String pin});
  Future<Either<Failure, String>> redeemRespondentInvite({
    required String token,
  });
  Future<Either<Failure, String>> inviteRecruiter({
    required String companyId,
    required String email,
    required String firstName,
    required String lastName,
    UserRole role = UserRole.recruiter,
  });
  Future<Either<Failure, Unit>> updateCandidateStatus({
    required String candidateId,
    required CandidateProcessStatus status,
  });
  Future<Either<Failure, Unit>> updateCandidate({
    required String candidateId,
    required String displayName,
    required String documentNumber,
    required String vacancyId,
  });
  Future<Either<Failure, Unit>> deleteCandidate(String candidateId);
  Future<Either<Failure, RespondentSession>> loadRespondentSession();
  Future<Either<Failure, Unit>> saveAnswer({
    required String candidateId,
    required String questionId,
    required int value,
  });
  Future<Either<Failure, TalentCandidate>> completeEvaluation(
    String candidateId, {
    String locale = 'es',
  });
  Future<Either<Failure, Unit>> requestSurveyResult(String candidateId);
  Future<Either<Failure, CandidateReport>> loadCandidateReport(String candidateId);
  Future<Either<Failure, AffinityAnalysis>> loadAffinityAnalysis(
    String candidateId,
  );
  Future<Either<Failure, AffinityAnalysis>> requestAffinityAnalysis(
    String candidateId,
  );
  Future<Either<Failure, Unit>> saveAssessmentKind({
    required String candidateId,
    required AssessmentKind kind,
  });
  Future<Either<Failure, Unit>> changePassword(String newPassword);
  Future<Either<Failure, List<DnaCatalogEntry>>> loadDnaCatalog();
  Future<Either<Failure, Unit>> deleteDnaCatalogOption({
    required String type,
    required String label,
  });
}
