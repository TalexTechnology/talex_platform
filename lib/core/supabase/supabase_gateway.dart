import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:talex_platform/core/error/exceptions.dart';
import 'package:talex_platform/features/talent/domain/talent_error_codes.dart';

const uuidPattern =
    r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$';

bool isUuid(String value) => RegExp(uuidPattern).hasMatch(value);

DateTime parseSupabaseDate(Object? value) {
  if (value is DateTime) return value;
  if (value is String && value.isNotEmpty) {
    return DateTime.tryParse(value) ?? DateTime.now();
  }
  return DateTime.now();
}

DateTime? parseOptionalSupabaseDate(Object? value) {
  if (value is DateTime) return value;
  if (value is String && value.isNotEmpty) return DateTime.tryParse(value);
  return null;
}

String publicEntityId(Map<String, dynamic> row, {String firebaseKey = 'firebase_id'}) {
  final firebaseId = '${row[firebaseKey] ?? ''}'.trim();
  if (firebaseId.isNotEmpty) return firebaseId;
  return '${row['id']}';
}

Never throwSupabase(Object error) {
  if (error is ServerException) throw error;
  final message = error is PostgrestException ? error.message : error.toString();
  if (message.contains('permission_denied') || message.contains('42501')) {
    throw const ServerException(TalentErrorCodes.permissionDenied);
  }
  if (message.contains('need_sign_in')) {
    throw const ServerException(TalentErrorCodes.needSignIn);
  }
  if (message.contains('invite_missing')) {
    throw const ServerException(TalentErrorCodes.inviteMissing);
  }
  if (message.contains('invite_used')) {
    throw const ServerException(TalentErrorCodes.inviteUsed);
  }
  if (message.contains('invalid_pin')) {
    throw const ServerException(TalentErrorCodes.invalidPin);
  }
  if (message.contains('pin_expired')) {
    throw const ServerException(TalentErrorCodes.pinExpired);
  }
  if (message.contains('assessment_missing')) {
    throw const ServerException(TalentErrorCodes.assessmentMissing);
  }
  if (message.contains('company')) {
    throw const ServerException(TalentErrorCodes.companyNotFound);
  }
  throw const ServerException(TalentErrorCodes.unexpected);
}

Future<T> guardSupabase<T>(Future<T> Function() action) async {
  try {
    return await action();
  } on ServerException {
    rethrow;
  } on Object catch (error) {
    throwSupabase(error);
  }
}
