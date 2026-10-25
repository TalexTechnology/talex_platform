import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:talex_platform/core/widgets/talex_logo.dart';
import 'package:talex_platform/features/assistant/domain/entities/assistant_brief.dart';
import 'package:talex_platform/features/assistant/domain/entities/assistant_message.dart';
import 'package:talex_platform/features/assistant/presentation/assistant_style.dart';
import 'package:talex_platform/features/assistant/presentation/assistant_text.dart';
import 'package:talex_platform/features/assistant/presentation/bloc/assistant_bloc.dart';
import 'package:talex_platform/features/assistant/presentation/bloc/assistant_event.dart';
import 'package:talex_platform/features/assistant/presentation/bloc/assistant_state.dart';
import 'package:talex_platform/features/assistant/presentation/widgets/assistant_composer_field.dart';
import 'package:talex_platform/features/assistant/presentation/widgets/assistant_message_tile.dart';

class AssistantPanel extends StatefulWidget {
  const AssistantPanel({super.key, required this.brief, required this.onClose});

  final AssistantBrief brief;
  final VoidCallback onClose;

  @override
  State<AssistantPanel> createState() => _AssistantPanelState();
}

class _AssistantPanelState extends State<AssistantPanel>
    with SingleTickerProviderStateMixin {
  final _scroll = ScrollController();
  final _composer = GlobalKey<AssistantComposerFieldState>();
  late final AnimationController _entrance;
  AssistantBloc? _bloc;
  String? _visible;
  String? _pending;
  var _pinned = true;

  @override
  void initState() {
    super.initState();
    _entrance = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 180),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (MediaQuery.disableAnimationsOf(context)) {
        _entrance.value = 1;
      } else {
        _entrance.forward();
      }
      _follow(force: true);
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _bloc = context.read<AssistantBloc>();
    if (MediaQuery.disableAnimationsOf(context)) {
      _entrance.value = 1;
    } else if (_entrance.value == 0 && !_entrance.isAnimating) {
      _entrance.forward();
    }
  }

  @override
  void dispose() {
    final bloc = _bloc;
    if (bloc != null &&
        !bloc.isClosed &&
        bloc.state.phase == AssistantPhase.revealing) {
      final streaming = bloc.state.messages.where(
        (message) => message.status == AssistantMessageStatus.streaming,
      );
      if (streaming.isNotEmpty) {
        bloc.add(
          AssistantRevealSettled(
            id: streaming.last.id,
            visible: streaming.last.text,
            finished: true,
          ),
        );
      }
    }
    _entrance.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _follow({bool force = false}) {
    if (!force && !_pinned) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scroll.hasClients) return;
      if (!force && !_pinned) return;
      final target = _scroll.position.maxScrollExtent;
      if ((_scroll.offset - target).abs() < 1) return;
      _scroll.jumpTo(target);
    });
  }

  void _onScroll(ScrollNotification notification) {
    if (notification.metrics.axis != Axis.vertical) return;
    if (notification is ScrollUpdateNotification &&
        notification.dragDetails != null) {
      final metrics = notification.metrics;
      _pinned = metrics.maxScrollExtent - metrics.pixels <= 72;
    } else if (notification is ScrollEndNotification) {
      final metrics = notification.metrics;
      _pinned = metrics.maxScrollExtent - metrics.pixels <= 72;
    }
  }

  void _submit(String text) {
    final bloc = context.read<AssistantBloc>();
    if (bloc.state.busy) return;
    _pending = text.trim();
    _pinned = true;
    bloc.add(AssistantMessageSent(text, widget.brief));
    _follow(force: true);
  }

  void _stop() {
    final bloc = context.read<AssistantBloc>();
    final revealing = bloc.state.phase == AssistantPhase.revealing;
    bloc.add(
      AssistantGenerationCancelled(
        visible: revealing ? (_visible ?? '') : null,
      ),
    );
  }

  void _acceptDraft(AssistantState state) {
    final pending = _pending;
    if (pending == null) return;
    final accepted = state.messages.any(
      (message) =>
          message.role == AssistantRole.user && message.text == pending,
    );
    if (!accepted) return;
    _composer.currentState?.clearIf(pending);
    _pending = null;
  }

  @override
  Widget build(BuildContext context) {
    final copy = AssistantText.of(context);
    final reduced = MediaQuery.disableAnimationsOf(context);
    return FadeTransition(
      opacity: reduced ? kAlwaysCompleteAnimation : _entrance,
      child: SlideTransition(
        position:
            Tween<Offset>(
              begin: reduced ? Offset.zero : const Offset(0.04, 0),
              end: Offset.zero,
            ).animate(
              CurvedAnimation(parent: _entrance, curve: Curves.easeOutCubic),
            ),
        child: Material(
          color: AssistantStyle.canvas,
          child: DecoratedBox(
            decoration: const BoxDecoration(
              border: Border(left: BorderSide(color: AssistantStyle.line)),
            ),
            child: BlocConsumer<AssistantBloc, AssistantState>(
              listenWhen: (previous, current) =>
                  previous.messages.length != current.messages.length ||
                  previous.phase != current.phase,
              listener: (context, state) {
                _acceptDraft(state);
                _follow();
              },
              builder: (context, state) {
                return Column(
                  children: [
                    _Header(
                      copy: copy,
                      phase: state.phase,
                      canReset:
                          state.messages.isNotEmpty ||
                          state.busy ||
                          state.failure != null,
                      onReset: () => context.read<AssistantBloc>().add(
                        const AssistantConversationReset(),
                      ),
                      onClose: widget.onClose,
                    ),
                    Expanded(
                      child: NotificationListener<ScrollNotification>(
                        onNotification: (notification) {
                          _onScroll(notification);
                          return false;
                        },
                        child: AnimatedSwitcher(
                          duration: reduced
                              ? Duration.zero
                              : const Duration(milliseconds: 180),
                          child: state.messages.isEmpty
                              ? _Welcome(
                                  key: const ValueKey('assistant-welcome'),
                                  copy: copy,
                                  brief: widget.brief,
                                  enabled: !state.busy,
                                  onSuggestion: _submit,
                                )
                              : _Thread(
                                  key: const ValueKey('assistant-thread'),
                                  scroll: _scroll,
                                  state: state,
                                  copy: copy,
                                  onRetry: () =>
                                      context.read<AssistantBloc>().add(
                                        AssistantRetryRequested(widget.brief),
                                      ),
                                  onRevealFrame: (visible) {
                                    _visible = visible;
                                    _follow();
                                  },
                                  onRevealFinished: (id) {
                                    context.read<AssistantBloc>().add(
                                      AssistantRevealSettled(
                                        id: id,
                                        visible: _visible ?? '',
                                        finished: true,
                                      ),
                                    );
                                  },
                                ),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                      child: AssistantComposerField(
                        key: _composer,
                        busy: state.busy,
                        onSubmit: _submit,
                        onStop: _stop,
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.copy,
    required this.phase,
    required this.canReset,
    required this.onReset,
    required this.onClose,
  });

  final AssistantText copy;
  final AssistantPhase phase;
  final bool canReset;
  final VoidCallback onReset;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final status = switch (phase) {
      AssistantPhase.awaiting => copy.consulting,
      AssistantPhase.revealing => copy.writing,
      AssistantPhase.idle => copy.available,
    };
    final live = phase != AssistantPhase.idle;
    return DecoratedBox(
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AssistantStyle.line)),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
        child: Row(
          children: [
            const TaleXitoMark(size: 32),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    copy.name,
                    style: AssistantStyle.body.copyWith(
                      fontWeight: FontWeight.w700,
                      height: 1.1,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      Container(
                        width: 7,
                        height: 7,
                        decoration: BoxDecoration(
                          color: live
                              ? AssistantStyle.blue
                              : AssistantStyle.green,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          status,
                          overflow: TextOverflow.ellipsis,
                          style: AssistantStyle.body.copyWith(
                            fontSize: 12,
                            height: 1.2,
                            color: AssistantStyle.muted,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            IconButton(
              tooltip: copy.newConversation,
              onPressed: canReset ? onReset : null,
              icon: const Icon(Icons.add_comment_outlined),
            ),
            IconButton(
              tooltip: copy.closeLabel,
              onPressed: onClose,
              icon: const Icon(Icons.close),
            ),
          ],
        ),
      ),
    );
  }
}

class _Welcome extends StatelessWidget {
  const _Welcome({
    super.key,
    required this.copy,
    required this.brief,
    required this.enabled,
    required this.onSuggestion,
  });

  final AssistantText copy;
  final AssistantBrief brief;
  final bool enabled;
  final ValueChanged<String> onSuggestion;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 28, 20, 12),
      children: [
        Text(
          copy.welcomeTitle,
          style: AssistantStyle.body.copyWith(
            fontSize: 22,
            height: 1.25,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          copy.welcomeBody,
          style: AssistantStyle.body.copyWith(color: AssistantStyle.muted),
        ),
        const SizedBox(height: 22),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final suggestion in copy.suggestions(brief.audience))
              _Suggestion(
                label: suggestion,
                onTap: enabled ? () => onSuggestion(suggestion) : null,
              ),
          ],
        ),
      ],
    );
  }
}

class _Suggestion extends StatelessWidget {
  const _Suggestion({required this.label, required this.onTap});

  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      shape: const StadiumBorder(),
      child: InkWell(
        customBorder: const StadiumBorder(),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
          decoration: const ShapeDecoration(
            shape: StadiumBorder(side: BorderSide(color: AssistantStyle.line)),
          ),
          child: Text(
            label,
            style: AssistantStyle.body.copyWith(fontSize: 13.5),
          ),
        ),
      ),
    );
  }
}

class _Thread extends StatelessWidget {
  const _Thread({
    super.key,
    required this.scroll,
    required this.state,
    required this.copy,
    required this.onRetry,
    required this.onRevealFrame,
    required this.onRevealFinished,
  });

  final ScrollController scroll;
  final AssistantState state;
  final AssistantText copy;
  final VoidCallback onRetry;
  final ValueChanged<String> onRevealFrame;
  final ValueChanged<String> onRevealFinished;

  @override
  Widget build(BuildContext context) {
    final failed = state.messages.lastIndexWhere(
      (message) => message.status == AssistantMessageStatus.failed,
    );
    return ListView.builder(
      controller: scroll,
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 8),
      itemCount: state.messages.length,
      itemBuilder: (context, index) {
        final message = state.messages[index];
        final showFailure = index == failed && state.failure != null;
        return AssistantMessageTile(
          key: ValueKey(message.id),
          message: message,
          failureText: showFailure ? copy.failure(state.failure!) : null,
          onRetry: showFailure ? onRetry : null,
          onRevealFrame: onRevealFrame,
          onRevealFinished: onRevealFinished,
        );
      },
    );
  }
}
