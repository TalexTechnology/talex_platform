import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:talex_platform/features/assistant/presentation/assistant_style.dart';
import 'package:talex_platform/features/assistant/presentation/assistant_text.dart';

class AssistantSendIntent extends Intent {
  const AssistantSendIntent();
}

class AssistantComposerField extends StatefulWidget {
  const AssistantComposerField({
    super.key,
    required this.busy,
    required this.onSubmit,
    required this.onStop,
  });

  final bool busy;
  final ValueChanged<String> onSubmit;
  final VoidCallback onStop;

  @override
  State<AssistantComposerField> createState() => AssistantComposerFieldState();
}

class AssistantComposerFieldState extends State<AssistantComposerField> {
  final _controller = TextEditingController();
  final _focus = FocusNode();

  @override
  void dispose() {
    _controller.dispose();
    _focus.dispose();
    super.dispose();
  }

  void clearIf(String text) {
    if (_controller.text.trim() == text) _controller.clear();
  }

  void _submit() {
    final text = _controller.text.trim();
    if (text.isEmpty || widget.busy) return;
    widget.onSubmit(text);
  }

  @override
  Widget build(BuildContext context) {
    final copy = AssistantText.of(context);
    final wide = MediaQuery.sizeOf(context).width >= 600;
    final canSend = _controller.text.trim().isNotEmpty && !widget.busy;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: Shortcuts(
                shortcuts: const {
                  SingleActivator(LogicalKeyboardKey.enter):
                      AssistantSendIntent(),
                },
                child: Actions(
                  actions: {
                    AssistantSendIntent: CallbackAction<AssistantSendIntent>(
                      onInvoke: (_) {
                        _submit();
                        return null;
                      },
                    ),
                  },
                  child: TextField(
                    key: const ValueKey('assistant-input'),
                    controller: _controller,
                    focusNode: _focus,
                    minLines: 1,
                    maxLines: 6,
                    maxLength: 2000,
                    textInputAction: TextInputAction.newline,
                    keyboardType: TextInputType.multiline,
                    style: AssistantStyle.body,
                    onChanged: (_) => setState(() {}),
                    decoration: InputDecoration(
                      hintText: copy.placeholder,
                      counterText: '',
                      filled: true,
                      fillColor: AssistantStyle.wash,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(18),
                        borderSide: const BorderSide(
                          color: AssistantStyle.line,
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(18),
                        borderSide: const BorderSide(
                          color: AssistantStyle.line,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(18),
                        borderSide: const BorderSide(
                          color: AssistantStyle.blue,
                          width: 1.4,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            _SendButton(
              busy: widget.busy,
              enabled: widget.busy || canSend,
              tooltip: widget.busy ? copy.stop : copy.send,
              onPressed: widget.busy
                  ? widget.onStop
                  : (canSend ? _submit : null),
            ),
          ],
        ),
        if (wide) ...[
          const SizedBox(height: 8),
          Text(
            copy.enterHint,
            style: AssistantStyle.body.copyWith(
              fontSize: 12,
              height: 1.2,
              color: AssistantStyle.muted,
            ),
          ),
        ],
      ],
    );
  }
}

class _SendButton extends StatelessWidget {
  const _SendButton({
    required this.busy,
    required this.enabled,
    required this.tooltip,
    required this.onPressed,
  });

  final bool busy;
  final bool enabled;
  final String tooltip;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final background = !enabled
        ? AssistantStyle.line
        : busy
        ? Colors.white
        : AssistantStyle.blue;
    final foreground = busy ? AssistantStyle.ink : Colors.white;
    return Tooltip(
      message: tooltip,
      child: Material(
        color: background,
        shape: const CircleBorder(),
        child: InkWell(
          key: const ValueKey('assistant-send'),
          customBorder: const CircleBorder(),
          onTap: onPressed,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 140),
            width: 44,
            height: 44,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: busy ? Border.all(color: AssistantStyle.line) : null,
            ),
            child: Icon(
              busy ? Icons.stop_rounded : Icons.arrow_upward_rounded,
              color: enabled ? foreground : AssistantStyle.muted,
              size: 20,
            ),
          ),
        ),
      ),
    );
  }
}
