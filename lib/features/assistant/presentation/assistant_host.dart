import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:talex_platform/core/di/injection.dart';
import 'package:talex_platform/features/assistant/domain/entities/assistant_brief.dart';
import 'package:talex_platform/features/assistant/domain/entities/assistant_reply.dart';
import 'package:talex_platform/features/assistant/presentation/bloc/assistant_bloc.dart';
import 'package:talex_platform/features/assistant/presentation/bloc/assistant_state.dart';
import 'package:talex_platform/features/assistant/presentation/pages/assistant_panel.dart';

typedef AssistantShellBuilder =
    Widget Function(
      BuildContext context,
      VoidCallback toggleAssistant,
      bool assistantOpen,
    );

/// Owns one conversation for the surrounding workspace and opens Xebec over it.
class AssistantHost extends StatefulWidget {
  const AssistantHost({
    super.key,
    required this.brief,
    required this.builder,
    this.onAnswerEdit,
  });

  final AssistantBrief brief;
  final AssistantShellBuilder builder;
  final ValueChanged<CompanyAnswerEdit>? onAnswerEdit;

  @override
  State<AssistantHost> createState() => _AssistantHostState();
}

class _AssistantHostState extends State<AssistantHost> {
  late final AssistantBloc _bloc;
  var _open = false;

  @override
  void initState() {
    super.initState();
    configureAssistantDependencies();
    _bloc = getIt<AssistantBloc>();
  }

  @override
  void dispose() {
    _bloc.close();
    super.dispose();
  }

  void _toggle() => setState(() => _open = !_open);

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final panelWidth = size.width < 760
        ? size.width
        : math.min(460.0, size.width * 0.4);
    final keyboard = MediaQuery.viewInsetsOf(context).bottom;
    return BlocProvider.value(
      value: _bloc,
      child: BlocListener<AssistantBloc, AssistantState>(
        listenWhen: (previous, current) =>
            previous.editToken != current.editToken,
        listener: (context, state) {
          final edit = state.pendingEdit;
          if (edit != null) widget.onAnswerEdit?.call(edit);
        },
        child: Builder(
        builder: (context) => Stack(
          children: [
            widget.builder(context, _toggle, _open),
            if (_open)
              Positioned(
                top: 0,
                right: 0,
                bottom: keyboard,
                width: panelWidth,
                child: AssistantPanel(brief: widget.brief, onClose: _toggle),
              ),
          ],
        ),
        ),
      ),
    );
  }
}
