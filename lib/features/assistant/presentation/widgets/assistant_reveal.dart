import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:talex_platform/features/assistant/presentation/markdown/assistant_markdown_view.dart';

/// Reveals a finished reply quickly, without asking the model again.
class AssistantReveal extends StatefulWidget {
  const AssistantReveal({
    super.key,
    required this.text,
    required this.onFrame,
    required this.onFinished,
  });

  final String text;
  final ValueChanged<String> onFrame;
  final VoidCallback onFinished;

  @override
  State<AssistantReveal> createState() => _AssistantRevealState();
}

class _AssistantRevealState extends State<AssistantReveal> {
  Timer? _timer;
  int _shown = 0;
  var _finished = false;
  var _started = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _start());
  }

  void _start() {
    if (!mounted || _started) return;
    _started = true;
    final reduced = MediaQuery.disableAnimationsOf(context);
    if (reduced || widget.text.length <= 24) {
      setState(() => _shown = widget.text.length);
      widget.onFrame(widget.text);
      _complete();
      return;
    }
    final step = math.max(12, (widget.text.length / 42).ceil());
    _timer = Timer.periodic(const Duration(milliseconds: 32), (timer) {
      if (!mounted) return;
      final next = math.min(widget.text.length, _shown + step);
      final visible = widget.text.substring(0, next);
      setState(() => _shown = next);
      widget.onFrame(visible);
      if (next >= widget.text.length) {
        timer.cancel();
        _complete();
      }
    });
  }

  void _complete() {
    if (_finished) return;
    _finished = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) widget.onFinished();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final end = _shown.clamp(0, widget.text.length);
    return AssistantMarkdownView(data: widget.text.substring(0, end));
  }
}
