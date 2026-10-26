import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:talex_platform/core/constants/app_colors.dart';
import 'package:talex_platform/core/constants/app_radii.dart';
import 'package:talex_platform/features/admin/domain/entities/assessment_question.dart';
import 'package:talex_platform/features/admin/domain/services/assessment_question_csv.dart';
import 'package:talex_platform/features/admin/domain/services/assessment_question_defaults.dart';
import 'package:talex_platform/l10n/app_localizations.dart';
import 'package:talex_platform/l10n/l10n.dart';

String assessmentFrontLabel(AppLocalizations l10n, AssessmentFront front) =>
    switch (front) {
      AssessmentFront.coreValues => l10n.adminQuestionsFrontValues,
      AssessmentFront.needs => l10n.adminQuestionsFrontNeeds,
      AssessmentFront.capabilities => l10n.adminQuestionsFrontCapabilities,
      AssessmentFront.cultura => l10n.adminQuestionsFrontCultura,
      AssessmentFront.liderazgo => l10n.adminQuestionsFrontLiderazgo,
      AssessmentFront.trabajo => l10n.adminQuestionsFrontTrabajo,
      AssessmentFront.personas => l10n.adminQuestionsFrontPersonas,
      AssessmentFront.apertura => l10n.adminQuestionsFrontApertura,
    };

String assessmentFormatLabel(
  AppLocalizations l10n,
  AssessmentQuestionFormat format,
) => switch (format) {
  AssessmentQuestionFormat.pair => l10n.adminQuestionsFormatPair,
  AssessmentQuestionFormat.experience => l10n.adminQuestionsFormatExperience,
  AssessmentQuestionFormat.scale => l10n.adminQuestionsFormatScale,
  AssessmentQuestionFormat.text => l10n.adminQuestionsFormatText,
  AssessmentQuestionFormat.single => l10n.adminQuestionsFormatSingle,
  AssessmentQuestionFormat.multi => l10n.adminQuestionsFormatMulti,
};

String _codePrefix(AssessmentFront front) => switch (front) {
  AssessmentFront.coreValues => 'V',
  AssessmentFront.needs => 'N',
  AssessmentFront.capabilities => 'C',
  AssessmentFront.cultura => 'CUL',
  AssessmentFront.liderazgo => 'LID',
  AssessmentFront.trabajo => 'TRA',
  AssessmentFront.personas => 'PER',
  AssessmentFront.apertura => 'APE',
};

String suggestQuestionCode(
  AssessmentFront front,
  List<AssessmentQuestion> existing,
) {
  final prefix = _codePrefix(front);
  var highest = 0;
  for (final question in existing) {
    if (!question.code.startsWith(prefix)) continue;
    final number = int.tryParse(question.code.substring(prefix.length)) ?? 0;
    if (number > highest) highest = number;
  }
  return '$prefix${(highest + 1).toString().padLeft(2, '0')}';
}

/// Devuelve la pregunta editada, o null si se cancela.
Future<AssessmentQuestion?> showAssessmentQuestionEditor(
  BuildContext context, {
  required List<AssessmentQuestion> existing,
  AssessmentQuestion? question,
  List<AssessmentFront> fronts = AssessmentFront.affinityFronts,
}) => showDialog<AssessmentQuestion>(
  context: context,
  builder: (_) => _QuestionEditorDialog(
    existing: existing,
    question: question,
    fronts: fronts,
  ),
);

Future<bool> confirmAssessmentQuestionDelete(
  BuildContext context,
  AssessmentQuestion question,
) async {
  final l10n = context.l10n;
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      shape: AppRadii.shape,
      title: Text(l10n.adminQuestionsDeleteTitle),
      content: Text(l10n.adminQuestionsDeleteBody(question.code)),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(false),
          child: Text(l10n.cancel),
        ),
        FilledButton(
          onPressed: () => Navigator.of(dialogContext).pop(true),
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.danger,
            foregroundColor: AppColors.bg,
          ),
          child: Text(l10n.adminQuestionsDelete),
        ),
      ],
    ),
  );
  return confirmed == true;
}

Future<bool> _confirm(
  BuildContext context, {
  required String title,
  required String body,
  required String action,
  bool destructive = false,
}) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      shape: AppRadii.shape,
      title: Text(title),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Text(body),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(false),
          child: Text(dialogContext.l10n.cancel),
        ),
        FilledButton(
          onPressed: () => Navigator.of(dialogContext).pop(true),
          style: FilledButton.styleFrom(
            backgroundColor: destructive ? AppColors.danger : AppColors.green,
                foregroundColor: AppColors.bg,
          ),
          child: Text(action),
        ),
      ],
    ),
  );
  return confirmed == true;
}

Future<bool> confirmAssessmentQuestionsDeleteAll(
  BuildContext context,
  int count,
) => _confirm(
  context,
  title: context.l10n.adminQuestionsDeleteAllTitle,
  body: context.l10n.adminQuestionsDeleteAllBody(count),
  action: context.l10n.adminQuestionsDeleteAll,
  destructive: true,
);

Future<bool> confirmAssessmentQuestionsImport(
  BuildContext context, {
  required int total,
  required int replaced,
}) => _confirm(
  context,
  title: context.l10n.adminQuestionsImportTitle,
  body: context.l10n.adminQuestionsImportBody(
    total,
    total - replaced,
    replaced,
  ),
  action: context.l10n.adminQuestionsImportAction,
);

String assessmentCsvErrorMessage(
  AppLocalizations l10n,
  AssessmentCsvException error,
) => switch (error.error) {
  AssessmentCsvError.unreadable => l10n.adminQuestionsCsvUnreadable,
  AssessmentCsvError.empty => l10n.adminQuestionsCsvEmpty,
  AssessmentCsvError.missingColumns => l10n.adminQuestionsCsvMissingColumns(
    error.detail,
  ),
  AssessmentCsvError.invalidRow => l10n.adminQuestionsCsvInvalidRow(error.row),
  AssessmentCsvError.duplicate => l10n.adminQuestionsCsvDuplicate(
    error.row,
    error.detail,
  ),
};

class _QuestionEditorDialog extends StatefulWidget {
  const _QuestionEditorDialog({
    required this.existing,
    required this.fronts,
    this.question,
  });
  final List<AssessmentQuestion> existing;
  final List<AssessmentFront> fronts;
  final AssessmentQuestion? question;
  @override
  State<_QuestionEditorDialog> createState() => _QuestionEditorDialogState();
}

class _QuestionEditorDialogState extends State<_QuestionEditorDialog> {
  final _formKey = GlobalKey<FormState>();
  late AssessmentFront _front;
  late AssessmentQuestionFormat _format;
  late bool _active;
  late final TextEditingController _code,
      _dimensionA,
      _dimensionB,
      _instruction,
      _statementA,
      _statementB,
      _timeLimit;
  late final List<TextEditingController> _options;

  bool get _isNew => widget.question == null;
  bool get _isPair => _format == AssessmentQuestionFormat.pair;
  bool get _hasOptions => _format != AssessmentQuestionFormat.text;

  @override
  void initState() {
    super.initState();
    final question = widget.question;
    _front = question?.front ?? widget.fronts.first;
    _format = question?.format ?? AssessmentQuestionDefaults.formatFor(_front);
    _active = question?.active ?? true;
    final options =
        question?.options ?? AssessmentQuestionDefaults.optionsFor(_format);
    final timeLimit = question == null
        ? (_isPair ? AssessmentQuestionDefaults.pairTimeLimitSeconds : null)
        : question.timeLimitSeconds;
    _code = TextEditingController(
      text: question?.code ?? suggestQuestionCode(_front, widget.existing),
    );
    _dimensionA = TextEditingController(text: question?.dimensionA);
    _dimensionB = TextEditingController(text: question?.dimensionB);
    _instruction = TextEditingController(
      text:
          question?.instruction ??
          AssessmentQuestionDefaults.instructionFor(_front),
    );
    _statementA = TextEditingController(text: question?.statementA);
    _statementB = TextEditingController(text: question?.statementB);
    _timeLimit = TextEditingController(text: timeLimit?.toString() ?? '');
    _options = [
      for (var index = 0; index < 5; index++)
        TextEditingController(
          text: index < options.length ? options[index] : '',
        ),
    ];
  }

  @override
  void dispose() {
    for (final controller in [
      _code,
      _dimensionA,
      _dimensionB,
      _instruction,
      _statementA,
      _statementB,
      _timeLimit,
      ..._options,
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  // En una pregunta nueva, el frente arrastra código, formato, instrucción y
  // opciones base; al editar no se pisa nada de lo ya escrito.
  void _onFrontChanged(AssessmentFront? front) {
    if (front == null || front == _front) return;
    setState(() {
      if (_isNew) {
        _code.text = suggestQuestionCode(front, widget.existing);
        _instruction.text = AssessmentQuestionDefaults.instructionFor(front);
        _applyFormat(AssessmentQuestionDefaults.formatFor(front));
      }
      _front = front;
    });
  }

  void _applyFormat(AssessmentQuestionFormat format) {
    if (format == _format) return;
    final previous = AssessmentQuestionDefaults.optionsFor(_format);
    final untouched = [
      for (var index = 0; index < 5; index++)
        _options[index].text.trim() ==
            (index < previous.length ? previous[index] : ''),
    ].every((same) => same);
    if (untouched) {
      final next = AssessmentQuestionDefaults.optionsFor(format);
      for (var index = 0; index < 5; index++) {
        _options[index].text = index < next.length ? next[index] : '';
      }
    }
    if (_isNew) {
      _timeLimit.text = format == AssessmentQuestionFormat.pair
          ? '${AssessmentQuestionDefaults.pairTimeLimitSeconds}'
          : '';
    }
    _format = format;
  }

  String? _required(String? value) => value == null || value.trim().isEmpty
      ? context.l10n.adminQuestionsRequired
      : null;

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final existing = widget.question;
    final order =
        existing?.order ??
        widget.existing.fold<int>(
              0,
              (highest, item) => item.order > highest ? item.order : highest,
            ) +
            1;
    Navigator.of(context).pop(
      AssessmentQuestion(
        code: _code.text.trim().toUpperCase(),
        order: order,
        front: _front,
        format: _format,
        dimensionA: _dimensionA.text.trim(),
        dimensionB: _isPair ? _dimensionB.text.trim() : '',
        instruction: _instruction.text.trim(),
        statementA: _statementA.text.trim(),
        statementB: _isPair ? _statementB.text.trim() : '',
        options: _hasOptions
            ? [for (final option in _options) option.text.trim()]
            : const [],
        timeLimitSeconds: int.tryParse(_timeLimit.text.trim()),
        active: _active,
      ),
    );
  }

  InputDecoration _decoration(String label, {String? helper}) =>
      InputDecoration(
        labelText: label,
        helperText: helper,
        alignLabelWithHint: true,
      );

  Widget _text(
    TextEditingController controller,
    String label, {
    int maxLines = 1,
    bool required = true,
  }) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: TextFormField(
      controller: controller,
      minLines: 1,
      maxLines: maxLines,
      decoration: _decoration(label),
      validator: required ? _required : null,
    ),
  );

  Widget _pairRow(bool stacked, Widget first, Widget second) => stacked
      ? Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [first, second],
        )
      : Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: first),
            const SizedBox(width: 12),
            Expanded(child: second),
          ],
        );

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final stacked = MediaQuery.sizeOf(context).width < 640;
    return Dialog(
      insetPadding: const EdgeInsets.all(20),
      shape: AppRadii.shape,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 680),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  _isNew ? l10n.adminQuestionsNew : l10n.adminQuestionsEdit,
                  style: TextStyle(
                    color: AppColors.text,
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 22),
                _pairRow(
                  stacked,
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: DropdownButtonFormField<AssessmentFront>(
                      initialValue: _front,
                      isExpanded: true,
                      decoration: _decoration(l10n.adminQuestionsFront),
                      items: [
                        for (final front in widget.fronts)
                          DropdownMenuItem(
                            value: front,
                            child: Text(assessmentFrontLabel(l10n, front)),
                          ),
                      ],
                      onChanged: _onFrontChanged,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: TextFormField(
                      controller: _code,
                      enabled: _isNew,
                      textCapitalization: TextCapitalization.characters,
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(
                          RegExp('[A-Za-z0-9_-]'),
                        ),
                      ],
                      decoration: _decoration(l10n.adminQuestionsCode),
                      validator: (value) {
                        final code = value?.trim().toUpperCase() ?? '';
                        if (code.isEmpty) return l10n.adminQuestionsRequired;
                        if (_isNew &&
                            widget.existing.any((item) => item.code == code)) {
                          return l10n.adminQuestionsCodeTaken;
                        }
                        return null;
                      },
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: DropdownButtonFormField<AssessmentQuestionFormat>(
                    key: ValueKey(_format),
                    initialValue: _format,
                    isExpanded: true,
                    decoration: _decoration(l10n.adminQuestionsFormat),
                    items: [
                      for (final format in AssessmentQuestionFormat.values)
                        DropdownMenuItem(
                          value: format,
                          child: Text(assessmentFormatLabel(l10n, format)),
                        ),
                    ],
                    onChanged: (format) {
                      if (format != null) setState(() => _applyFormat(format));
                    },
                  ),
                ),
                _text(
                  _instruction,
                  l10n.adminQuestionsInstruction,
                  maxLines: 3,
                ),
                if (_isPair) ...[
                  _pairRow(
                    stacked,
                    _text(_dimensionA, l10n.adminQuestionsDimensionA),
                    _text(_dimensionB, l10n.adminQuestionsDimensionB),
                  ),
                  _text(
                    _statementA,
                    l10n.adminQuestionsStatementA,
                    maxLines: 3,
                  ),
                  _text(
                    _statementB,
                    l10n.adminQuestionsStatementB,
                    maxLines: 3,
                  ),
                ] else ...[
                  _text(_dimensionA, l10n.adminQuestionsDimension),
                  _text(_statementA, l10n.adminQuestionsStatement, maxLines: 3),
                ],
                if (_hasOptions)
                  for (var index = 0; index < _options.length; index++)
                    _text(
                      _options[index],
                      l10n.adminQuestionsOption(index + 1),
                    ),
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: TextFormField(
                    controller: _timeLimit,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: _decoration(
                      l10n.adminQuestionsTimeLimit,
                      helper: l10n.adminQuestionsTimeLimitHint,
                    ),
                    validator: (value) {
                      final text = value?.trim() ?? '';
                      if (text.isEmpty) return null;
                      final seconds = int.tryParse(text);
                      return seconds == null || seconds <= 0
                          ? l10n.adminQuestionsInvalidTime
                          : null;
                    },
                  ),
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(l10n.adminQuestionsActive),
                  value: _active,
                  onChanged: (value) => setState(() => _active = value),
                ),
                const SizedBox(height: 14),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: Text(l10n.cancel),
                    ),
                    const SizedBox(width: 12),
                    FilledButton(
                      onPressed: _submit,
                      child: Text(l10n.saveChanges),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
