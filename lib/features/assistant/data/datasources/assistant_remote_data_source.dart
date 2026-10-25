import 'package:cloud_functions/cloud_functions.dart';
import 'package:talex_platform/features/assistant/domain/entities/assistant_reply.dart';

class AssistantRemoteException implements Exception {
  const AssistantRemoteException(this.code, {required this.permanent});

  final String code;
  final bool permanent;
}

/// Talks to the `askAssistant` callable.
///
/// The model key stays in the Cloud Function secret `GEMINI_API_KEY`, the same
/// secret already used by affinity analysis. This client never receives it.
abstract interface class AssistantRemoteDataSource {
  Future<String> ask({
    required AssistantRequest request,
    required String reference,
    required Map<String, Object?> context,
  });
}

class CallableAssistantDataSource implements AssistantRemoteDataSource {
  CallableAssistantDataSource(this._functions);

  final FirebaseFunctions _functions;

  static const callableName = 'askAssistant';

  @override
  Future<String> ask({
    required AssistantRequest request,
    required String reference,
    required Map<String, Object?> context,
  }) async {
    try {
      final callable = _functions.httpsCallable(
        callableName,
        options: HttpsCallableOptions(timeout: const Duration(seconds: 20)),
      );
      final response = await callable.call<Object?>({
        'question': request.question,
        'locale': request.brief.locale,
        'history': request.history
            .map((turn) => {'role': turn.role, 'text': turn.text})
            .toList(),
        'reference': reference,
        'context': context,
      });
      final data = response.data;
      if (data is String) return data;
      if (data is Map) {
        final text = data['text'];
        if (text is String) return text;
      }
      throw const AssistantRemoteException('unexpected', permanent: false);
    } on AssistantRemoteException {
      rethrow;
    } on FirebaseFunctionsException catch (error) {
      throw AssistantRemoteException(
        error.code,
        permanent: _permanent(error.code),
      );
    } catch (_) {
      throw const AssistantRemoteException('unavailable', permanent: false);
    }
  }

  static bool _permanent(String code) =>
      code == 'not-found' ||
      code == 'unimplemented' ||
      code == 'failed-precondition' ||
      code == 'permission-denied' ||
      code == 'unauthenticated';
}
