import 'package:equatable/equatable.dart';
import 'package:talex_platform/core/error/failure.dart';
import 'package:talex_platform/features/assistant/domain/entities/assistant_brief.dart';

enum AssistantFailureKind { unavailable, timeout, empty, unexpected }

final class AssistantFailure extends Failure {
  const AssistantFailure(this.kind) : super('assistant');

  final AssistantFailureKind kind;

  @override
  List<Object> get props => [kind];
}

class AssistantTurn extends Equatable {
  const AssistantTurn({required this.role, required this.text});

  final String role;
  final String text;

  @override
  List<Object?> get props => [role, text];
}

class AssistantRequest extends Equatable {
  const AssistantRequest({
    required this.question,
    required this.brief,
    this.history = const [],
  });

  final String question;
  final AssistantBrief brief;
  final List<AssistantTurn> history;

  @override
  List<Object?> get props => [question, brief, history];
}

class AssistantReply extends Equatable {
  const AssistantReply({
    required this.markdown,
    this.fromRemote = false,
    this.edit,
  });

  final String markdown;
  final bool fromRemote;
  final CompanyAnswerEdit? edit;

  @override
  List<Object?> get props => [markdown, fromRemote, edit];
}

/// Replacement lists for the answers already stored on the company profile.
class CompanyAnswerEdit extends Equatable {
  const CompanyAnswerEdit({
    required this.values,
    required this.culture,
    required this.standout,
  });

  final List<String> values;
  final List<String> culture;
  final List<String> standout;

  @override
  List<Object?> get props => [values, culture, standout];
}
