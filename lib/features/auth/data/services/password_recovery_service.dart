import 'package:cloud_functions/cloud_functions.dart';
import 'package:dartz/dartz.dart';
import 'package:talex_platform/core/error/failure.dart';
import 'package:talex_platform/features/talent/domain/talent_error_codes.dart';

class PasswordRecoveryService {
  PasswordRecoveryService(this._functions);
  final FirebaseFunctions _functions;

  Future<Either<Failure, Unit>> requestPin({
    required String email,
    required String locale,
  }) => _call('requestPasswordReset', {
    'email': email.trim().toLowerCase(),
    'locale': locale,
  });

  Future<Either<Failure, String>> verifyPin({
    required String email,
    required String pin,
  }) async {
    final result = await _invoke('verifyPasswordResetPin', {
      'email': email.trim().toLowerCase(),
      'pin': pin.trim(),
    });
    return result.fold(Left.new, (data) {
      final token = data['resetToken'] as String?;
      if (token == null || token.isEmpty) {
        return const Left(ServerFailure(TalentErrorCodes.invalidPin));
      }
      return Right(token);
    });
  }

  Future<Either<Failure, Unit>> complete({
    required String email,
    required String resetToken,
    required String password,
  }) => _call('completePasswordReset', {
    'email': email.trim().toLowerCase(),
    'resetToken': resetToken,
    'password': password,
  });

  Future<Either<Failure, Unit>> _call(
    String name,
    Map<String, dynamic> payload,
  ) async {
    final result = await _invoke(name, payload);
    return result.fold(Left.new, (_) => const Right(unit));
  }

  Future<Either<Failure, Map<String, dynamic>>> _invoke(
    String name,
    Map<String, dynamic> payload,
  ) async {
    try {
      final callable = _functions.httpsCallable(
        name,
        options: HttpsCallableOptions(timeout: const Duration(seconds: 55)),
      );
      final response = await callable.call(payload);
      final data = response.data;
      if (data is Map) {
        return Right(Map<String, dynamic>.from(data));
      }
      return const Right(<String, dynamic>{});
    } on FirebaseFunctionsException catch (error) {
      return Left(ServerFailure(_map(error)));
    } catch (_) {
      return const Left(ServerFailure(TalentErrorCodes.unexpected));
    }
  }

  String _map(FirebaseFunctionsException error) {
    final message = error.message ?? '';
    if (message.contains('resetCooldown')) {
      return TalentErrorCodes.resetCooldown;
    }
    if (message.contains('tooManyAttempts') ||
        error.code == 'resource-exhausted') {
      return TalentErrorCodes.resetTooManyAttempts;
    }
    if (message.contains('pinExpired') || message.contains('expired')) {
      return TalentErrorCodes.pinExpired;
    }
    if (message.contains('passwordTooShort')) {
      return TalentErrorCodes.passwordTooShort;
    }
    if (message.contains('accountNotFound')) {
      return TalentErrorCodes.accountNotFound;
    }
    if (message.contains('invalidPin') || error.code == 'invalid-argument') {
      return TalentErrorCodes.invalidPin;
    }
    if (error.code == 'failed-precondition') {
      return TalentErrorCodes.emailNotConfigured;
    }
    if (error.code == 'not-found') {
      return TalentErrorCodes.invalidPin;
    }
    return TalentErrorCodes.emailSendFailed;
  }
}
