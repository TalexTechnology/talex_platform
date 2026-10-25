import 'package:equatable/equatable.dart';
import 'package:talex_platform/features/assistant/domain/entities/assistant_message.dart';
import 'package:talex_platform/features/assistant/domain/entities/assistant_reply.dart';

enum AssistantPhase { idle, awaiting, revealing }

class AssistantState extends Equatable {
  const AssistantState({
    this.messages = const [],
    this.phase = AssistantPhase.idle,
    this.failure,
    this.pendingEdit,
    this.editToken = 0,
  });

  final List<AssistantMessage> messages;
  final AssistantPhase phase;
  final AssistantFailureKind? failure;
  final CompanyAnswerEdit? pendingEdit;
  final int editToken;

  bool get busy => phase != AssistantPhase.idle;

  AssistantState copyWith({
    List<AssistantMessage>? messages,
    AssistantPhase? phase,
    AssistantFailureKind? failure,
    bool clearFailure = false,
    CompanyAnswerEdit? pendingEdit,
    int? editToken,
  }) => AssistantState(
    messages: messages ?? this.messages,
    phase: phase ?? this.phase,
    failure: clearFailure ? null : (failure ?? this.failure),
    pendingEdit: pendingEdit ?? this.pendingEdit,
    editToken: editToken ?? this.editToken,
  );

  @override
  List<Object?> get props => [messages, phase, failure, pendingEdit, editToken];
}
