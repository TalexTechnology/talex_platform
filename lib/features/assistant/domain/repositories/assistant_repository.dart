import 'package:dartz/dartz.dart';
import 'package:talex_platform/core/error/failure.dart';
import 'package:talex_platform/features/assistant/domain/entities/assistant_reply.dart';

abstract interface class AssistantRepository {
  Future<Either<Failure, AssistantReply>> reply(AssistantRequest request);
}
