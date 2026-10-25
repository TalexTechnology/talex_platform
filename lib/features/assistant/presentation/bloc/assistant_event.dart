import 'package:equatable/equatable.dart';
import 'package:talex_platform/features/assistant/domain/entities/assistant_brief.dart';

sealed class AssistantEvent extends Equatable {
  const AssistantEvent();

  @override
  List<Object?> get props => [];
}

class AssistantMessageSent extends AssistantEvent {
  const AssistantMessageSent(this.text, this.brief);

  final String text;
  final AssistantBrief brief;

  @override
  List<Object?> get props => [text, brief];
}

class AssistantRetryRequested extends AssistantEvent {
  const AssistantRetryRequested(this.brief);

  final AssistantBrief brief;

  @override
  List<Object?> get props => [brief];
}

class AssistantGenerationCancelled extends AssistantEvent {
  const AssistantGenerationCancelled({this.visible});

  /// Text already shown when the user stops a reveal.
  ///
  /// Null keeps whatever the message currently stores, which is empty while
  /// the answer is still being requested.
  final String? visible;

  @override
  List<Object?> get props => [visible];
}

class AssistantRevealSettled extends AssistantEvent {
  const AssistantRevealSettled({
    required this.id,
    required this.visible,
    required this.finished,
  });

  final String id;
  final String visible;
  final bool finished;

  @override
  List<Object?> get props => [id, visible, finished];
}

class AssistantConversationReset extends AssistantEvent {
  const AssistantConversationReset();
}
