import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:talex_platform/features/assistant/domain/entities/assistant_brief.dart';
import 'package:talex_platform/features/assistant/domain/entities/assistant_message.dart';
import 'package:talex_platform/features/assistant/domain/entities/assistant_reply.dart';
import 'package:talex_platform/features/assistant/domain/repositories/assistant_repository.dart';
import 'package:talex_platform/features/assistant/presentation/bloc/assistant_event.dart';
import 'package:talex_platform/features/assistant/presentation/bloc/assistant_state.dart';

class AssistantBloc extends Bloc<AssistantEvent, AssistantState> {
  AssistantBloc({required AssistantRepository repository})
    : _repository = repository,
      super(const AssistantState()) {
    on<AssistantMessageSent>(_onSent);
    on<AssistantRetryRequested>(_onRetry);
    on<AssistantGenerationCancelled>(_onCancelled);
    on<AssistantRevealSettled>(_onSettled);
    on<AssistantConversationReset>(_onReset);
  }

  final AssistantRepository _repository;
  int _sequence = 0;
  int _generation = 0;
  bool _accepting = false;

  Future<void> _onSent(
    AssistantMessageSent event,
    Emitter<AssistantState> emit,
  ) async {
    final text = event.text.trim();
    if (text.isEmpty || _accepting || state.busy) return;
    final user = AssistantMessage(
      id: _nextId(),
      role: AssistantRole.user,
      text: text,
      status: AssistantMessageStatus.complete,
    );
    final assistantId = _nextId();
    await _ask(
      emit: emit,
      brief: event.brief,
      question: text,
      messages: [...state.messages, user],
      assistantId: assistantId,
    );
  }

  Future<void> _onRetry(
    AssistantRetryRequested event,
    Emitter<AssistantState> emit,
  ) async {
    if (_accepting || state.busy) return;
    final failedIndex = state.messages.lastIndexWhere(
      (message) => message.status == AssistantMessageStatus.failed,
    );
    if (failedIndex < 0) return;
    final question = _previousUserText(state.messages, failedIndex);
    if (question == null) return;
    final assistantId = _nextId();
    await _ask(
      emit: emit,
      brief: event.brief,
      question: question,
      messages: [
        for (var index = 0; index < state.messages.length; index++)
          if (index != failedIndex) state.messages[index],
      ],
      assistantId: assistantId,
    );
  }

  Future<void> _ask({
    required Emitter<AssistantState> emit,
    required AssistantBrief brief,
    required String question,
    required List<AssistantMessage> messages,
    required String assistantId,
  }) async {
    _accepting = true;
    final generation = ++_generation;
    final placeholder = AssistantMessage(
      id: assistantId,
      role: AssistantRole.assistant,
      text: '',
      status: AssistantMessageStatus.streaming,
    );
    emit(
      state.copyWith(
        phase: AssistantPhase.awaiting,
        messages: [...messages, placeholder],
        clearFailure: true,
      ),
    );
    final result = await _repository.reply(
      AssistantRequest(
        question: question,
        brief: brief,
        history: _history(messages),
      ),
    );
    _accepting = false;
    if (emit.isDone || isClosed || generation != _generation) return;
    result.fold(
      (failure) {
        final kind = failure is AssistantFailure
            ? failure.kind
            : AssistantFailureKind.unexpected;
        emit(
          state.copyWith(
            phase: AssistantPhase.idle,
            failure: kind,
            messages: _replace(
              state.messages,
              assistantId,
              placeholder.copyWith(status: AssistantMessageStatus.failed),
            ),
          ),
        );
      },
      (reply) {
        final markdown = reply.markdown.trim();
        if (markdown.isEmpty) {
          emit(
            state.copyWith(
              phase: AssistantPhase.idle,
              failure: AssistantFailureKind.empty,
              messages: _replace(
                state.messages,
                assistantId,
                placeholder.copyWith(status: AssistantMessageStatus.failed),
              ),
            ),
          );
          return;
        }
        emit(
          state.copyWith(
            phase: AssistantPhase.revealing,
            messages: _replace(
              state.messages,
              assistantId,
              placeholder.copyWith(text: markdown),
            ),
            clearFailure: true,
            pendingEdit: reply.edit,
            editToken: reply.edit == null
                ? state.editToken
                : state.editToken + 1,
          ),
        );
      },
    );
  }

  void _onCancelled(
    AssistantGenerationCancelled event,
    Emitter<AssistantState> emit,
  ) {
    if (!state.busy && !_accepting) return;
    _generation++;
    _accepting = false;
    emit(
      state.copyWith(
        phase: AssistantPhase.idle,
        messages: [
          for (final message in state.messages)
            if (message.status == AssistantMessageStatus.streaming)
              message.copyWith(
                status: AssistantMessageStatus.cancelled,
                text: event.visible ?? message.text,
              )
            else
              message,
        ],
        clearFailure: true,
      ),
    );
  }

  void _onSettled(AssistantRevealSettled event, Emitter<AssistantState> emit) {
    final current = _find(state.messages, event.id);
    if (current == null) return;
    if (event.finished) {
      if (current.status != AssistantMessageStatus.streaming) return;
      emit(
        state.copyWith(
          phase: AssistantPhase.idle,
          messages: _replace(
            state.messages,
            event.id,
            current.copyWith(status: AssistantMessageStatus.complete),
          ),
        ),
      );
      return;
    }
    if (current.status != AssistantMessageStatus.cancelled) return;
    if (current.text == event.visible) return;
    emit(
      state.copyWith(
        messages: _replace(
          state.messages,
          event.id,
          current.copyWith(text: event.visible),
        ),
      ),
    );
  }

  void _onReset(
    AssistantConversationReset event,
    Emitter<AssistantState> emit,
  ) {
    if (state.messages.isEmpty && !state.busy && state.failure == null) {
      return;
    }
    _generation++;
    _accepting = false;
    emit(const AssistantState());
  }

  @override
  Future<void> close() {
    _generation++;
    _accepting = false;
    return super.close();
  }

  String _nextId() => 'm${_sequence++}';

  List<AssistantTurn> _history(List<AssistantMessage> messages) {
    final turns = <AssistantTurn>[];
    for (final message in messages) {
      if (message.status != AssistantMessageStatus.complete) continue;
      if (message.text.trim().isEmpty) continue;
      turns.add(
        AssistantTurn(
          role: message.role == AssistantRole.user ? 'user' : 'assistant',
          text: message.text.trim(),
        ),
      );
    }
    if (turns.length <= 8) return turns;
    return turns.sublist(turns.length - 8);
  }

  String? _previousUserText(List<AssistantMessage> messages, int before) {
    for (var index = before - 1; index >= 0; index--) {
      final message = messages[index];
      if (message.role == AssistantRole.user &&
          message.text.trim().isNotEmpty) {
        return message.text.trim();
      }
    }
    return null;
  }

  AssistantMessage? _find(List<AssistantMessage> messages, String id) {
    for (final message in messages) {
      if (message.id == id) return message;
    }
    return null;
  }

  List<AssistantMessage> _replace(
    List<AssistantMessage> messages,
    String id,
    AssistantMessage next,
  ) => [
    for (final message in messages)
      if (message.id == id) next else message,
  ];
}
