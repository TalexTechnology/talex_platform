import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:talex_platform/core/constants/app_colors.dart';
import 'package:talex_platform/core/constants/app_radii.dart';
import 'package:talex_platform/core/error/exceptions.dart';
import 'package:talex_platform/features/admin/domain/entities/culture_question.dart';
import 'package:talex_platform/features/talent/domain/talent_error_codes.dart';
import 'package:talex_platform/l10n/app_localizations.dart';
import 'package:talex_platform/l10n/l10n.dart';

/// Mensaje para los errores de los endpoints de preguntas de cultura.
String cultureQuestionErrorMessage(AppLocalizations l10n, Object error) {
  if (error is! ServerException) return l10n.cultureQuestionsErrorGeneric;
  return switch (error.message) {
    'need_sign_in' ||
    TalentErrorCodes.needSignIn => l10n.cultureQuestionsErrorSignIn,
    'permission_denied' => l10n.cultureQuestionsErrorPermission,
    'question_not_found' => l10n.cultureQuestionsErrorNotFound,
    'duplicate' => l10n.cultureQuestionsErrorDuplicate,
    'invalid_question' =>
      error.detail == null
          ? l10n.cultureQuestionsErrorInvalidGeneric
          : l10n.cultureQuestionsErrorInvalid(error.detail!),
    'codes_mismatch' => l10n.cultureQuestionsErrorCodesMismatch,
    'unknown_rpc' => l10n.cultureQuestionsErrorNotDeployed,
    _ => l10n.cultureQuestionsErrorGeneric,
  };
}

/// Mensaje al no poder cargar el banco. Agrega la causa: un código conocido
/// se traduce; uno desconocido (p. ej. el endpoint no existe en ese backend) se
/// muestra tal cual para poder diagnosticarlo.
String cultureQuestionLoadErrorMessage(AppLocalizations l10n, Object error) {
  final reason = cultureQuestionErrorMessage(l10n, error);
  if (reason != l10n.cultureQuestionsErrorGeneric) {
    return '${l10n.cultureQuestionsErrorLoad}\n$reason';
  }
  if (error is ServerException) {
    final raw = [
      error.message,
      ?error.detail,
    ].where((item) => item.isNotEmpty).toSet().join(' · ');
    return '${l10n.cultureQuestionsErrorLoad}\n($raw)';
  }
  return '${l10n.cultureQuestionsErrorLoad}\n($error)';
}

/// Devuelve la pregunta editada, o null si se cancela.
Future<CultureQuestion?> showCultureQuestionEditor(
  BuildContext context, {
  required List<CultureQuestion> existing,
  CultureQuestion? question,
}) => showDialog<CultureQuestion>(
  context: context,
  builder: (_) =>
      _CultureQuestionEditor(existing: existing, question: question),
);

Future<bool> confirmCultureQuestionDelete(
  BuildContext context,
  String code,
) async {
  final l10n = context.l10n;
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      shape: AppRadii.shape,
      title: Text(l10n.adminQuestionsDeleteTitle),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Text(l10n.cultureQuestionsDeleteBody(code)),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(false),
          child: Text(l10n.cancel),
        ),
        FilledButton(
          onPressed: () => Navigator.of(dialogContext).pop(true),
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xFFB42318),
          ),
          child: Text(l10n.adminQuestionsDelete),
        ),
      ],
    ),
  );
  return confirmed == true;
}

/// Devuelve (título, intro), o null si se cancela.
Future<(String, String)?> showCultureSurveyEditor(
  BuildContext context, {
  required String title,
  required String intro,
}) => showDialog<(String, String)>(
  context: context,
  builder: (_) => _SurveyEditor(title: title, intro: intro),
);

InputDecoration _decoration(String label) => InputDecoration(
  labelText: label,
  border: const OutlineInputBorder(),
  alignLabelWithHint: true,
);

Widget _dialogFrame({
  required String title,
  required Widget child,
  required List<Widget> actions,
  double maxWidth = 720,
}) => Dialog(
  insetPadding: const EdgeInsets.all(20),
  shape: AppRadii.shape,
  child: ConstrainedBox(
    constraints: BoxConstraints(maxWidth: maxWidth),
    child: SingleChildScrollView(
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: AppColors.ink,
              fontSize: 24,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 22),
          child,
          const SizedBox(height: 14),
          Row(mainAxisAlignment: MainAxisAlignment.end, children: actions),
        ],
      ),
    ),
  ),
);

class _SurveyEditor extends StatefulWidget {
  const _SurveyEditor({required this.title, required this.intro});
  final String title, intro;

  @override
  State<_SurveyEditor> createState() => _SurveyEditorState();
}

class _SurveyEditorState extends State<_SurveyEditor> {
  final _formKey = GlobalKey<FormState>();
  late final _title = TextEditingController(text: widget.title);
  late final _intro = TextEditingController(text: widget.intro);

  @override
  void dispose() {
    _title.dispose();
    _intro.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return _dialogFrame(
      title: l10n.cultureQuestionsEditSurvey,
      maxWidth: 620,
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            TextFormField(
              controller: _title,
              decoration: _decoration(l10n.cultureQuestionsSurveyTitle),
              validator: (value) => value == null || value.trim().isEmpty
                  ? l10n.adminQuestionsRequired
                  : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _intro,
              minLines: 3,
              maxLines: 8,
              decoration: _decoration(l10n.cultureQuestionsSurveyIntro),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.cancel),
        ),
        const SizedBox(width: 12),
        FilledButton(
          onPressed: () {
            if (!(_formKey.currentState?.validate() ?? false)) return;
            Navigator.of(context).pop((_title.text.trim(), _intro.text.trim()));
          },
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.primaryButton,
          ),
          child: Text(l10n.saveChanges),
        ),
      ],
    );
  }
}

class _OptionFields {
  _OptionFields([CultureOption? option])
    : id = TextEditingController(text: option?.id),
      label = TextEditingController(text: option?.label),
      dimension = TextEditingController(text: option?.dimension);

  final TextEditingController id, label, dimension;

  bool get isEmpty =>
      id.text.trim().isEmpty &&
      label.text.trim().isEmpty &&
      dimension.text.trim().isEmpty;

  // Sin ID escrito se deriva del texto: "Trabajo en equipo" → trabajo_en_equipo.
  String get resolvedId {
    final typed = id.text.trim();
    if (typed.isNotEmpty) return typed;
    const accents = {
      'á': 'a',
      'é': 'e',
      'í': 'i',
      'ó': 'o',
      'ú': 'u',
      'ü': 'u',
      'ñ': 'n',
    };
    final plain = label.text
        .trim()
        .toLowerCase()
        .split('')
        .map((char) => accents[char] ?? char);
    return plain
        .join()
        .replaceAll(RegExp('[^a-z0-9]+'), '_')
        .replaceAll(RegExp(r'^_+|_+$'), '');
  }

  void dispose() {
    id.dispose();
    label.dispose();
    dimension.dispose();
  }
}

class _CultureQuestionEditor extends StatefulWidget {
  const _CultureQuestionEditor({required this.existing, this.question});
  final List<CultureQuestion> existing;
  final CultureQuestion? question;

  @override
  State<_CultureQuestionEditor> createState() => _CultureQuestionEditorState();
}

class _CultureQuestionEditorState extends State<_CultureQuestionEditor> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _code,
      _name,
      _statement,
      _instruction,
      _format,
      _optionsSource,
      _section,
      _sectionTitle,
      _technique;
  late final List<_OptionFields> _options;
  late bool _required, _active;

  bool get _isNew => widget.question == null;

  @override
  void initState() {
    super.initState();
    final question = widget.question;
    _code = TextEditingController(text: question?.code);
    _name = TextEditingController(text: question?.name);
    _statement = TextEditingController(text: question?.statement);
    _instruction = TextEditingController(text: question?.instruction);
    _format = TextEditingController(
      text: question?.format ?? _mostUsed((item) => item.format),
    );
    _optionsSource = TextEditingController(
      text: question?.optionsSource ?? _mostUsed((item) => item.optionsSource),
    );
    _section = TextEditingController(text: question?.section);
    _sectionTitle = TextEditingController(text: question?.sectionTitle);
    _technique = TextEditingController(text: question?.technique);
    _options = [
      for (final option in question?.options ?? const <CultureOption>[])
        _OptionFields(option),
      if (question == null) ...[_OptionFields(), _OptionFields()],
    ];
    _required = question?.required ?? true;
    _active = question?.active ?? true;
  }

  @override
  void dispose() {
    for (final controller in [
      _code,
      _name,
      _statement,
      _instruction,
      _format,
      _optionsSource,
      _section,
      _sectionTitle,
      _technique,
    ]) {
      controller.dispose();
    }
    for (final option in _options) {
      option.dispose();
    }
    super.dispose();
  }

  // Valor más frecuente en el banco, como punto de partida de una pregunta
  // nueva.
  String _mostUsed(String Function(CultureQuestion) read) {
    final counts = <String, int>{};
    for (final question in widget.existing) {
      final value = read(question);
      if (value.isNotEmpty) counts[value] = (counts[value] ?? 0) + 1;
    }
    if (counts.isEmpty) return '';
    return (counts.entries.toList()..sort((a, b) => b.value - a.value))
        .first
        .key;
  }

  List<String> _used(String Function(CultureQuestion) read) => {
    for (final question in widget.existing)
      if (read(question).isNotEmpty) read(question),
  }.toList();

  // Al elegir una sección ya usada se completa su título.
  void _pickSection(String section) {
    setState(() {
      _section.text = section;
      final match = widget.existing.where(
        (item) => item.section == section && item.sectionTitle.isNotEmpty,
      );
      if (match.isNotEmpty) _sectionTitle.text = match.first.sectionTitle;
    });
  }

  String? _requiredText(String? value) => value == null || value.trim().isEmpty
      ? context.l10n.adminQuestionsRequired
      : null;

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    Navigator.of(context).pop(
      CultureQuestion(
        code: _code.text.trim().toUpperCase(),
        name: _name.text.trim(),
        statement: _statement.text.trim(),
        instruction: _instruction.text.trim(),
        format: _format.text.trim(),
        optionsSource: _optionsSource.text.trim(),
        section: _section.text.trim(),
        sectionTitle: _sectionTitle.text.trim(),
        technique: _technique.text.trim(),
        required: _required,
        active: _active,
        options: [
          for (final option in _options)
            if (!option.isEmpty)
              CultureOption(
                id: option.resolvedId,
                label: option.label.text.trim(),
                dimension: option.dimension.text.trim(),
              ),
        ],
      ),
    );
  }

  Widget _field(
    TextEditingController controller,
    String label, {
    int maxLines = 1,
    bool required = false,
    List<String> suggestions = const [],
    ValueChanged<String>? onSuggestion,
  }) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          controller: controller,
          minLines: 1,
          maxLines: maxLines,
          decoration: _decoration(label),
          validator: required ? _requiredText : null,
        ),
        if (suggestions.isNotEmpty) ...[
          const SizedBox(height: 6),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(
                context.l10n.cultureQuestionsUsed,
                style: const TextStyle(color: AppColors.muted, fontSize: 12),
              ),
              for (final value in suggestions)
                ActionChip(
                  label: Text(value, style: const TextStyle(fontSize: 12)),
                  visualDensity: VisualDensity.compact,
                  onPressed: () => onSuggestion != null
                      ? onSuggestion(value)
                      : setState(() => controller.text = value),
                ),
            ],
          ),
        ],
      ],
    ),
  );

  Widget _pair(bool stacked, Widget first, Widget second) => stacked
      ? Column(children: [first, second])
      : Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: first),
            const SizedBox(width: 12),
            Expanded(child: second),
          ],
        );

  Widget _optionRow(int index, bool stacked) {
    final l10n = context.l10n;
    final option = _options[index];
    final id = TextFormField(
      controller: option.id,
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp('[a-z0-9_-]')),
      ],
      decoration: _decoration(l10n.cultureQuestionsOptionId),
      validator: (_) {
        if (option.isEmpty) return null;
        final mine = option.resolvedId;
        final repeated = _options.where(
          (other) => !other.isEmpty && other.resolvedId == mine,
        );
        return repeated.length > 1 ? l10n.cultureQuestionsOptionIdTaken : null;
      },
    );
    final label = TextFormField(
      controller: option.label,
      decoration: _decoration(l10n.cultureQuestionsOptionLabel),
      validator: (value) => option.isEmpty ? null : _requiredText(value),
    );
    final dimension = TextFormField(
      controller: option.dimension,
      decoration: _decoration(l10n.cultureQuestionsOptionDimension),
    );
    final remove = IconButton(
      tooltip: l10n.cultureQuestionsRemoveOption,
      onPressed: () => setState(() => _options.removeAt(index).dispose()),
      icon: const Icon(Icons.close),
    );
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: stacked
          ? Column(
              children: [
                label,
                const SizedBox(height: 8),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: id),
                    const SizedBox(width: 8),
                    Expanded(child: dimension),
                    remove,
                  ],
                ),
              ],
            )
          : Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(width: 150, child: id),
                const SizedBox(width: 8),
                Expanded(flex: 3, child: label),
                const SizedBox(width: 8),
                Expanded(flex: 2, child: dimension),
                remove,
              ],
            ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final stacked = MediaQuery.sizeOf(context).width < 640;
    return _dialogFrame(
      title: _isNew ? l10n.cultureQuestionsNew : l10n.adminQuestionsEdit,
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _pair(
              stacked,
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: TextFormField(
                  controller: _code,
                  enabled: _isNew,
                  textCapitalization: TextCapitalization.characters,
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp('[A-Za-z0-9_-]')),
                  ],
                  decoration: _decoration(l10n.cultureQuestionsCode),
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
              _field(_name, l10n.cultureQuestionsName),
            ),
            _field(
              _statement,
              l10n.cultureQuestionsStatement,
              maxLines: 4,
              required: true,
            ),
            _field(_instruction, l10n.cultureQuestionsInstruction, maxLines: 3),
            _pair(
              stacked,
              _field(
                _format,
                l10n.cultureQuestionsFormat,
                required: true,
                suggestions: _used((item) => item.format),
              ),
              _field(
                _optionsSource,
                l10n.cultureQuestionsOptionsSource,
                suggestions: _used((item) => item.optionsSource),
              ),
            ),
            _pair(
              stacked,
              _field(
                _section,
                l10n.cultureQuestionsSection,
                suggestions: _used((item) => item.section),
                onSuggestion: _pickSection,
              ),
              _field(_sectionTitle, l10n.cultureQuestionsSectionTitle),
            ),
            _field(
              _technique,
              l10n.cultureQuestionsTechnique,
              suggestions: _used((item) => item.technique),
            ),
            const SizedBox(height: 6),
            Text(
              l10n.cultureQuestionsOptions,
              style: const TextStyle(
                color: AppColors.ink,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            for (var index = 0; index < _options.length; index++)
              _optionRow(index, stacked),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: () => setState(() => _options.add(_OptionFields())),
                icon: const Icon(Icons.add),
                label: Text(l10n.cultureQuestionsAddOption),
              ),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(l10n.cultureQuestionsRequiredField),
              value: _required,
              onChanged: (value) => setState(() => _required = value),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(l10n.cultureQuestionsActive),
              value: _active,
              onChanged: (value) => setState(() => _active = value),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.cancel),
        ),
        const SizedBox(width: 12),
        FilledButton(
          onPressed: _submit,
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.primaryButton,
          ),
          child: Text(l10n.saveChanges),
        ),
      ],
    );
  }
}
