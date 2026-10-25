import 'dart:async';

import 'package:flutter/material.dart';
import 'package:talex_platform/core/constants/app_colors.dart';
import 'package:talex_platform/core/constants/app_radii.dart';
import 'package:talex_platform/features/admin/domain/entities/assessment_question.dart';
import 'package:talex_platform/features/admin/presentation/widgets/admin_question_dialogs.dart';
import 'package:talex_platform/l10n/l10n.dart';

/// Simula la encuesta tal como la vería un encuestado. No guarda respuestas.
Future<void> showSurveyPreview(
  BuildContext context,
  List<AssessmentQuestion> questions, {
  String? startCode,
}) => showDialog<void>(
  context: context,
  builder: (_) => _SurveyPreviewDialog(
    questions: questions.where((item) => item.active).toList(),
    startCode: startCode,
  ),
);

class _SurveyPreviewDialog extends StatefulWidget {
  const _SurveyPreviewDialog({required this.questions, this.startCode});
  final List<AssessmentQuestion> questions;
  final String? startCode;
  @override
  State<_SurveyPreviewDialog> createState() => _SurveyPreviewDialogState();
}

class _SurveyPreviewDialogState extends State<_SurveyPreviewDialog> {
  static const _mobileWidth = 390.0;
  static const _desktopWidth = 760.0;

  final _picks = <String, int>{};
  var _index = 0;
  var _mobile = false;
  int? _remaining;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    final start = widget.questions.indexWhere(
      (item) => item.code == widget.startCode,
    );
    if (start > 0) _index = start;
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    _timer?.cancel();
    _remaining = widget.questions.isEmpty
        ? null
        : widget.questions[_index].timeLimitSeconds;
    if (_remaining == null) return;
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      setState(() => _remaining = _remaining! - 1);
      if (_remaining! <= 0) timer.cancel();
    });
  }

  void _goTo(int index) {
    setState(() => _index = index);
    _startTimer();
  }

  void _restart() {
    _picks.clear();
    _goTo(0);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final size = MediaQuery.sizeOf(context);
    final questions = widget.questions;
    return Dialog(
      insetPadding: const EdgeInsets.all(16),
      shape: AppRadii.shape,
      backgroundColor: const Color(0xFFEDEEF1),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: 920, maxHeight: size.height),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 8, 8),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.adminQuestionsPreviewTitle,
                          style: const TextStyle(
                            color: AppColors.ink,
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          l10n.adminQuestionsPreviewNote,
                          style: const TextStyle(
                            color: AppColors.muted,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (size.width >= 560)
                    SegmentedButton<bool>(
                      showSelectedIcon: false,
                      segments: [
                        ButtonSegment(
                          value: false,
                          icon: const Icon(Icons.desktop_windows_outlined),
                          label: Text(l10n.adminQuestionsDeviceDesktop),
                        ),
                        ButtonSegment(
                          value: true,
                          icon: const Icon(Icons.smartphone_outlined),
                          label: Text(l10n.adminQuestionsDeviceMobile),
                        ),
                      ],
                      selected: {_mobile},
                      onSelectionChanged: (value) =>
                          setState(() => _mobile = value.first),
                    ),
                  IconButton(
                    tooltip: l10n.close,
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ),
            if (questions.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    _adminCaption(context, questions[_index]),
                    style: const TextStyle(
                      color: AppColors.subtitle,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                child: Center(
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 220),
                    curve: Curves.easeOut,
                    width: _mobile ? _mobileWidth : _desktopWidth,
                    clipBehavior: Clip.antiAlias,
                    decoration: BoxDecoration(
                      color: AppColors.dashboardBackground,
                      borderRadius: AppRadii.border,
                      border: Border.all(color: AppColors.border),
                    ),
                    child: questions.isEmpty
                        ? Center(
                            child: Padding(
                              padding: const EdgeInsets.all(32),
                              child: Text(
                                l10n.adminQuestionsPreviewEmpty,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  color: AppColors.subtitle,
                                ),
                              ),
                            ),
                          )
                        : _QuestionScreen(
                            question: questions[_index],
                            index: _index,
                            total: questions.length,
                            compact: _mobile || size.width < 560,
                            remaining: _remaining,
                            selected: _picks[questions[_index].code],
                            onPick: (value) => setState(
                              () => _picks[questions[_index].code] = value,
                            ),
                            onBack: _index == 0
                                ? null
                                : () => _goTo(_index - 1),
                            onNext: _index == questions.length - 1
                                ? null
                                : () => _goTo(_index + 1),
                            onRestart: _restart,
                          ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _adminCaption(BuildContext context, AssessmentQuestion question) => [
    question.code,
    assessmentFrontLabel(context.l10n, question.front),
    if (question.isPair && question.dimensionB.isNotEmpty)
      '${question.dimensionA} / ${question.dimensionB}'
    else
      question.dimensionA,
  ].join('  ·  ');
}

class _QuestionScreen extends StatelessWidget {
  const _QuestionScreen({
    required this.question,
    required this.index,
    required this.total,
    required this.compact,
    required this.remaining,
    required this.selected,
    required this.onPick,
    required this.onBack,
    required this.onNext,
    required this.onRestart,
  });
  final AssessmentQuestion question;
  final int index, total;
  final bool compact;
  final int? remaining, selected;
  final ValueChanged<int> onPick;
  final VoidCallback? onBack, onNext;
  final VoidCallback onRestart;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final padding = compact ? 18.0 : 32.0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(padding, padding, padding, 0),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      l10n.questionProgress(index + 1, total),
                      style: const TextStyle(color: AppColors.subtitle),
                    ),
                  ),
                  if (remaining != null) _TimerChip(seconds: remaining!),
                ],
              ),
              const SizedBox(height: 12),
              LinearProgressIndicator(value: (index + 1) / total),
            ],
          ),
        ),
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) => SingleChildScrollView(
              padding: EdgeInsets.all(padding),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight - padding * 2,
                ),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 540),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          question.instruction,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 13,
                            height: 1.4,
                            letterSpacing: 0.1,
                            color: AppColors.muted,
                          ),
                        ),
                        const SizedBox(height: 28),
                        if (question.isPair)
                          _PairScale(
                            question: question,
                            selected: selected,
                            onPick: onPick,
                          )
                        else ...[
                          Text(
                            question.statementA,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 17,
                              height: 1.4,
                              fontWeight: FontWeight.w500,
                              color: AppColors.ink,
                            ),
                          ),
                          const SizedBox(height: 22),
                          _SegmentBar(
                            count: question.options.length,
                            labels: question.options,
                            selected: selected,
                            onPick: onPick,
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        Padding(
          padding: EdgeInsets.fromLTRB(padding, 0, padding, padding),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: OutlinedButton(
                  onPressed: onBack,
                  child: Text(l10n.goBack),
                ),
              ),
              const SizedBox(width: 12),
              Flexible(
                child: onNext == null
                    ? FilledButton(
                        onPressed: onRestart,
                        child: Text(l10n.adminQuestionsRestart),
                      )
                    : FilledButton(onPressed: onNext, child: Text(l10n.next)),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// Escala bipolar tipo CliftonStrengths: los dos enunciados arriba, uno en cada
// extremo, y debajo una barra fina dividida en cinco para marcar qué tan cerca
// se está de cada uno. Sin letras ni etiquetas: solo los textos.
class _PairScale extends StatelessWidget {
  const _PairScale({
    required this.question,
    required this.selected,
    required this.onPick,
  });
  final AssessmentQuestion question;
  final int? selected;
  final ValueChanged<int> onPick;

  @override
  Widget build(BuildContext context) {
    final count = question.options.length;
    final middle = (count + 1) / 2;
    Widget statement(String text, TextAlign align, bool leaning) => Expanded(
      child: AnimatedDefaultTextStyle(
        duration: const Duration(milliseconds: 160),
        textAlign: align,
        style: TextStyle(
          fontSize: 14.5,
          height: 1.45,
          fontWeight: FontWeight.w500,
          color: leaning ? AppColors.primaryButton : AppColors.ink,
        ),
        child: Text(text),
      ),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            statement(
              question.statementA,
              TextAlign.left,
              selected != null && selected! < middle,
            ),
            const SizedBox(width: 28),
            statement(
              question.statementB,
              TextAlign.right,
              selected != null && selected! > middle,
            ),
          ],
        ),
        const SizedBox(height: 14),
        _SegmentBar(count: count, selected: selected, onPick: onPick),
      ],
    );
  }
}

class _SegmentBar extends StatelessWidget {
  const _SegmentBar({
    required this.count,
    required this.selected,
    required this.onPick,
    this.labels,
  });
  final int count;
  final int? selected;
  final ValueChanged<int> onPick;
  final List<String>? labels;

  @override
  Widget build(BuildContext context) => Container(
    height: labels == null ? 30 : 40,
    clipBehavior: Clip.antiAlias,
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: AppColors.softBorder),
      boxShadow: const [
        BoxShadow(
          color: Color(0x0F071326),
          blurRadius: 10,
          offset: Offset(0, 2),
        ),
      ],
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var index = 0; index < count; index++) ...[
          if (index > 0)
            const VerticalDivider(width: 1, color: AppColors.softBorder),
          Expanded(
            child: Semantics(
              button: true,
              selected: selected == index + 1,
              label: labels?[index] ?? '${index + 1} / $count',
              child: Material(
                color: selected == index + 1
                    ? AppColors.primaryButton
                    : Colors.white,
                child: InkWell(
                  key: ValueKey('scale-${index + 1}'),
                  onTap: () => onPick(index + 1),
                  child: Center(
                    child: labels == null
                        ? null
                        : Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 3),
                            child: Text(
                              labels![index],
                              textAlign: TextAlign.center,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 11.5,
                                height: 1.15,
                                fontWeight: FontWeight.w500,
                                color: selected == index + 1
                                    ? Colors.white
                                    : AppColors.subtitle,
                              ),
                            ),
                          ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ],
    ),
  );
}

class _TimerChip extends StatelessWidget {
  const _TimerChip({required this.seconds});
  final int seconds;

  @override
  Widget build(BuildContext context) {
    final expired = seconds <= 0;
    final color = expired || seconds <= 5
        ? const Color(0xFFB42318)
        : AppColors.subtitle;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.timer_outlined, size: 18, color: color),
        const SizedBox(width: 4),
        Text(
          expired
              ? context.l10n.adminQuestionsTimeUp
              : context.l10n.adminQuestionsSeconds(seconds),
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.w600,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
      ],
    );
  }
}
