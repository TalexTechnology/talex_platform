import 'dart:developer' as developer;

import 'package:cloud_functions/cloud_functions.dart';
import 'package:dartz/dartz.dart';
import 'package:talex_platform/core/error/failure.dart';
import 'package:talex_platform/features/talent/domain/talent_error_codes.dart';

class InviteEmailService {
  InviteEmailService(this._functions);

  final FirebaseFunctions _functions;

  Future<Either<Failure, Unit>> sendRecruiterPin({
    required String to,
    required String firstName,
    required String companyName,
    required String pin,
    required String locale,
    String? appUrl,
    String situation = 'company_new_user',
  }) =>
      _sendInviteEmail(
        type: 'recruiter_pin',
        to: to,
        firstName: firstName,
        companyName: companyName,
        pin: pin,
        locale: locale,
        appUrl: appUrl,
        situation: situation,
      );

  Future<Either<Failure, Unit>> sendRespondentInvite({
    required String to,
    required String firstName,
    required String companyName,
    required String token,
    required String locale,
    String? vacancyName,
    String? appUrl,
    String situation = 'respondent_invite',
  }) =>
      _sendInviteEmail(
        type: 'respondent_invite',
        to: to,
        firstName: firstName,
        companyName: companyName,
        token: token,
        locale: locale,
        appUrl: appUrl,
        vacancyName: vacancyName,
        situation: situation,
      );

  Future<Either<Failure, Unit>> sendAssessmentComplete({
    required String to,
    required String firstName,
    required String companyName,
    required String locale,
    String? vacancyName,
    String? appUrl,
  }) =>
      _sendInviteEmail(
        type: 'assessment_complete',
        to: to,
        firstName: firstName,
        companyName: companyName,
        locale: locale,
        appUrl: appUrl,
        vacancyName: vacancyName,
        situation: 'respondent_complete',
      );

  Future<Either<Failure, Unit>> _sendInviteEmail({
    required String type,
    required String to,
    required String firstName,
    required String companyName,
    String? pin,
    String? token,
    required String locale,
    String? appUrl,
    String? vacancyName,
    String? situation,
  }) async {
    try {
      final callable = _functions.httpsCallable(
        'sendInviteEmail',
        options: HttpsCallableOptions(
          timeout: const Duration(seconds: 12),
        ),
      );

      await callable.call({
        'type': type,
        'to': to,
        'firstName': firstName,
        'companyName': companyName,
        'pin': pin,
        'token': token,
        'locale': locale,
        'vacancyName': vacancyName,
        'situation': situation,
        'appUrl': appUrl ?? Uri.base.origin,
      });

      return const Right(unit);
    } on FirebaseFunctionsException catch (error) {
      developer.log(
        'sendInviteEmail failed',
        error: '${error.code}: ${error.message}',
        name: 'InviteEmailService',
      );

      if (error.code == 'failed-precondition' ||
          error.code == 'not-found' ||
          error.code == 'unimplemented') {
        return const Left(
          ServerFailure(TalentErrorCodes.emailNotConfigured),
        );
      }

      return const Left(
        ServerFailure(TalentErrorCodes.emailSendFailed),
      );
    } catch (error, stack) {
      developer.log(
        'sendInviteEmail unexpected',
        error: error,
        stackTrace: stack,
        name: 'InviteEmailService',
      );

      return const Left(
        ServerFailure(TalentErrorCodes.emailSendFailed),
      );
    }
  }
}