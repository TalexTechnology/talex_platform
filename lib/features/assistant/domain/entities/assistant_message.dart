import 'package:equatable/equatable.dart';

enum AssistantRole { user, assistant }

enum AssistantMessageStatus { complete, streaming, cancelled, failed }

class AssistantMessage extends Equatable {
  const AssistantMessage({
    required this.id,
    required this.role,
    required this.text,
    required this.status,
  });

  final String id;
  final AssistantRole role;
  final String text;
  final AssistantMessageStatus status;

  AssistantMessage copyWith({String? text, AssistantMessageStatus? status}) =>
      AssistantMessage(
        id: id,
        role: role,
        text: text ?? this.text,
        status: status ?? this.status,
      );

  @override
  List<Object?> get props => [id, role, text, status];
}
