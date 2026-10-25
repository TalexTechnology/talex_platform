import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:talex_platform/core/widgets/talex_logo.dart';
import 'package:talex_platform/features/assistant/domain/entities/assistant_message.dart';
import 'package:talex_platform/features/assistant/presentation/assistant_style.dart';
import 'package:talex_platform/features/assistant/presentation/assistant_text.dart';
import 'package:talex_platform/features/assistant/presentation/markdown/assistant_markdown_view.dart';
import 'package:talex_platform/features/assistant/presentation/widgets/assistant_reveal.dart';
import 'package:talex_platform/features/assistant/presentation/widgets/assistant_typing_indicator.dart';

class AssistantMessageTile extends StatefulWidget {
  const AssistantMessageTile({
    super.key,
    required this.message,
    required this.failureText,
    required this.onRetry,
    required this.onRevealFrame,
    required this.onRevealFinished,
  });

  final AssistantMessage message;
  final String? failureText;
  final VoidCallback? onRetry;
  final ValueChanged<String> onRevealFrame;
  final ValueChanged<String> onRevealFinished;

  @override
  State<AssistantMessageTile> createState() => _AssistantMessageTileState();
}

class _AssistantMessageTileState extends State<AssistantMessageTile>
    with SingleTickerProviderStateMixin {
  late final AnimationController _entrance;

  @override
  void initState() {
    super.initState();
    _entrance = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 180),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _entrance.value = 1;
    } else if (_entrance.value == 0 && !_entrance.isAnimating) {
      _entrance.forward();
    }
  }

  @override
  void dispose() {
    _entrance.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final message = widget.message;
    final user = message.role == AssistantRole.user;
    return FadeTransition(
      opacity: CurvedAnimation(parent: _entrance, curve: Curves.easeOut),
      child: RepaintBoundary(
        child: Padding(
          padding: const EdgeInsets.only(bottom: 22),
          child: user ? _user(message.text) : _assistant(context, message),
        ),
      ),
    );
  }

  Widget _user(String text) {
    return Align(
      alignment: Alignment.centerRight,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: math.min(520, MediaQuery.sizeOf(context).width * 0.82),
        ),
        child: DecoratedBox(
          decoration: const BoxDecoration(
            color: AssistantStyle.blue,
            borderRadius: AssistantStyle.userRadius,
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: SelectableText(text, style: AssistantStyle.userBody),
          ),
        ),
      ),
    );
  }

  Widget _assistant(BuildContext context, AssistantMessage message) {
    final copy = AssistantText.of(context);
    final waiting =
        message.status == AssistantMessageStatus.streaming &&
        message.text.isEmpty;
    final revealing =
        message.status == AssistantMessageStatus.streaming &&
        message.text.isNotEmpty;
    return Semantics(
      liveRegion: message.status == AssistantMessageStatus.complete,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const TaleXitoMark(size: 18),
              const SizedBox(width: 8),
              Text(copy.name, style: AssistantStyle.meta),
            ],
          ),
          const SizedBox(height: 6),
          if (waiting)
            const AssistantTypingIndicator()
          else if (revealing)
            AssistantReveal(
              text: message.text,
              onFrame: widget.onRevealFrame,
              onFinished: () => widget.onRevealFinished(message.id),
            )
          else if (message.text.trim().isNotEmpty)
            AssistantMarkdownView(data: message.text),
          if (message.status == AssistantMessageStatus.cancelled)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                copy.cancelled,
                style: AssistantStyle.body.copyWith(
                  fontSize: 12,
                  height: 1.2,
                  color: AssistantStyle.muted,
                ),
              ),
            ),
          if (message.status == AssistantMessageStatus.failed &&
              widget.failureText != null)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.failureText!,
                    style: AssistantStyle.body.copyWith(
                      fontSize: 13.5,
                      color: AssistantStyle.muted,
                    ),
                  ),
                  if (widget.onRetry != null)
                    TextButton(
                      onPressed: widget.onRetry,
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 0),
                        minimumSize: const Size(0, 36),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: Text(copy.retry),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
