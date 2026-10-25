import 'package:flutter/material.dart';
import 'package:talex_platform/core/constants/app_colors.dart';
import 'package:talex_platform/core/di/injection.dart';
import 'package:talex_platform/core/services/notification_service.dart';
import 'package:talex_platform/core/widgets/skeleton.dart';
import 'package:talex_platform/features/admin/data/datasources/culture_question_data_source.dart';
import 'package:talex_platform/features/admin/domain/entities/culture_question.dart';
import 'package:talex_platform/features/admin/presentation/widgets/admin_widgets.dart';
import 'package:talex_platform/features/admin/presentation/widgets/culture_question_dialogs.dart';
import 'package:talex_platform/l10n/l10n.dart';

// Banco de preguntas de la encuesta "Mi cultura". Se abre desde la pestaña
// Mi cultura y vuelve a ella con [onBack].
class AdminCultureQuestionsView extends StatefulWidget {
  const AdminCultureQuestionsView({
    super.key,
    required this.onBack,
    this.source,
  });

  final VoidCallback onBack;
  final CultureQuestionDataSource? source;

  @override
  State<AdminCultureQuestionsView> createState() =>
      _AdminCultureQuestionsViewState();
}

class _AdminCultureQuestionsViewState extends State<AdminCultureQuestionsView> {
  late final CultureQuestionDataSource _source =
      widget.source ?? CultureQuestionDataSource();
  CultureQuestionBank? _bank;
  Object? _loadError;
  var _loading = true;
  var _busy = false;
  var _showInactive = true;
  var _query = '';

  List<CultureQuestion> get _all => _bank?.questions ?? const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _loadError = null;
    });
    try {
      final bank = await _source.list();
      if (!mounted) return;
      setState(() {
        _bank = bank;
        _loading = false;
      });
    } on Object catch (error) {
      if (!mounted) return;
      setState(() {
        _loadError = error;
        _loading = false;
      });
    }
  }

  // Ejecuta un cambio, avisa el resultado y recarga el banco.
  Future<void> _run(
    Future<void> Function() action, {
    bool notify = true,
  }) async {
    final l10n = context.l10n;
    final notifications = getIt<NotificationService>();
    setState(() => _busy = true);
    try {
      await action();
      if (notify) notifications.success(l10n.adminSaved);
    } on Object catch (error) {
      notifications.error(cultureQuestionErrorMessage(l10n, error));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
    if (mounted) await _load();
  }

  Future<void> _edit([CultureQuestion? question]) async {
    final result = await showCultureQuestionEditor(
      context,
      existing: _all,
      question: question,
    );
    if (result == null || !mounted) return;
    if (question == null) {
      await _run(() => _source.create(result));
      return;
    }
    final changes = result.changesFrom(question);
    if (changes.isEmpty) return;
    await _run(() => _source.update(question.code, changes));
  }

  Future<void> _delete(CultureQuestion question) async {
    if (!await confirmCultureQuestionDelete(context, question.code)) return;
    if (!mounted) return;
    await _run(() => _source.delete(question.code));
  }

  Future<void> _editSurvey() async {
    final bank = _bank;
    final result = await showCultureSurveyEditor(
      context,
      title: bank?.title ?? '',
      intro: bank?.intro ?? '',
    );
    if (result == null || !mounted) return;
    await _run(() => _source.updateSurvey(title: result.$1, intro: result.$2));
  }

  // Intercambia dos preguntas visibles; el backend recibe el banco completo
  // (incluidas las ocultas por el filtro) en el nuevo orden.
  Future<void> _swap(CultureQuestion a, CultureQuestion b) async {
    final bank = _bank;
    if (bank == null) return;
    final codes = [for (final item in bank.questions) item.code];
    final i = codes.indexOf(a.code), j = codes.indexOf(b.code);
    if (i < 0 || j < 0) return;
    final reordered = [...bank.questions];
    reordered[i] = b;
    reordered[j] = a;
    setState(
      () => _bank = CultureQuestionBank(
        title: bank.title,
        intro: bank.intro,
        questions: reordered,
      ),
    );
    await _run(
      () => _source.reorder([for (final item in reordered) item.code]),
      notify: false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final compact = MediaQuery.sizeOf(context).width < 720;
    final Widget body;
    if (_loading && _bank == null) {
      body = const Skeleton(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SkeletonBox(height: 96, radius: 12),
            SizedBox(height: 16),
            SkeletonBox(height: 48),
            SizedBox(height: 16),
            SkeletonList(count: 6),
          ],
        ),
      );
    } else if (_loadError != null && _bank == null) {
      body = AdminErrorState(
        message: cultureQuestionLoadErrorMessage(l10n, _loadError!),
        onRetry: _load,
      );
    } else {
      final visible = [
        for (final question in _all)
          if ((_showInactive || question.active) && question.matches(_query))
            question,
      ];
      body = Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _SurveyCard(bank: _bank, onEdit: _busy ? null : _editSurvey),
          const SizedBox(height: 16),
          TextField(
            onChanged: (value) => setState(() => _query = value),
            decoration: InputDecoration(
              hintText: l10n.cultureQuestionsSearch,
              prefixIcon: const Icon(Icons.search),
              filled: true,
              fillColor: Colors.white,
              border: const OutlineInputBorder(),
              isDense: true,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 16,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Switch(
                    value: _showInactive,
                    onChanged: (value) => setState(() => _showInactive = value),
                  ),
                  Text(l10n.cultureQuestionsShowInactive),
                ],
              ),
              Text(
                l10n.adminQuestionsSummary(
                  _all.where((item) => item.active).length,
                  _all.length,
                ),
                style: const TextStyle(color: AppColors.muted, fontSize: 13),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (_all.isEmpty)
            AdminEmptyState(
              message: l10n.cultureQuestionsEmpty,
              icon: Icons.quiz_outlined,
            )
          else if (visible.isEmpty)
            AdminEmptyState(
              message: l10n.cultureQuestionsNoResults,
              icon: Icons.search_off_outlined,
            )
          else
            AdminPanel(
              child: Column(
                children: [
                  for (final (index, question) in visible.indexed) ...[
                    if (index > 0)
                      const Divider(height: 1, color: AppColors.divider),
                    _QuestionTile(
                      question: question,
                      compact: compact,
                      busy: _busy,
                      onToggle: (active) => _run(
                        () => _source.update(question.code, {
                          'is_active': active,
                        }),
                        notify: false,
                      ),
                      onEdit: () => _edit(question),
                      onDelete: () => _delete(question),
                      onMoveUp: index == 0
                          ? null
                          : () => _swap(question, visible[index - 1]),
                      onMoveDown: index == visible.length - 1
                          ? null
                          : () => _swap(question, visible[index + 1]),
                    ),
                  ],
                ],
              ),
            ),
        ],
      );
    }
    return SingleChildScrollView(
      padding: EdgeInsets.all(compact ? 18 : 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: widget.onBack,
              icon: const Icon(Icons.arrow_back),
              label: Text(l10n.cultureQuestionsBack),
            ),
          ),
          const SizedBox(height: 8),
          AdminPageHeader(
            title: l10n.cultureQuestionsTitle,
            subtitle: l10n.cultureQuestionsSubtitle,
            actions: [
              OutlinedButton.icon(
                onPressed: _loading || _busy ? null : _load,
                icon: const Icon(Icons.refresh),
                label: Text(l10n.adminMyCultureRefresh),
              ),
              FilledButton.icon(
                onPressed: _bank == null || _busy ? null : () => _edit(),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primaryButton,
                ),
                icon: const Icon(Icons.add),
                label: Text(l10n.cultureQuestionsNew),
              ),
            ],
          ),
          const SizedBox(height: 24),
          if (_busy || (_loading && _bank != null))
            const Padding(
              padding: EdgeInsets.only(bottom: 12),
              child: LinearProgressIndicator(minHeight: 2),
            ),
          body,
        ],
      ),
    );
  }
}

class _SurveyCard extends StatelessWidget {
  const _SurveyCard({required this.bank, required this.onEdit});

  final CultureQuestionBank? bank;
  final VoidCallback? onEdit;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final title = bank?.title ?? '';
    final intro = bank?.intro ?? '';
    return AdminPanel(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 18, 12, 18),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.cultureQuestionsSurveyTitle,
                    style: const TextStyle(
                      color: AppColors.muted,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    title.isEmpty ? l10n.cultureQuestionsSurveyNoTitle : title,
                    style: TextStyle(
                      color: title.isEmpty ? AppColors.muted : AppColors.ink,
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (intro.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      intro,
                      style: const TextStyle(
                        color: AppColors.subtitle,
                        fontSize: 14.5,
                        height: 1.4,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 12),
            OutlinedButton.icon(
              onPressed: onEdit,
              icon: const Icon(Icons.edit_outlined),
              label: Text(l10n.cultureQuestionsEditSurvey),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuestionTile extends StatelessWidget {
  const _QuestionTile({
    required this.question,
    required this.compact,
    required this.busy,
    required this.onToggle,
    required this.onEdit,
    required this.onDelete,
    required this.onMoveUp,
    required this.onMoveDown,
  });

  final CultureQuestion question;
  final bool compact, busy;
  final ValueChanged<bool> onToggle;
  final VoidCallback onEdit, onDelete;
  final VoidCallback? onMoveUp, onMoveDown;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    const meta = TextStyle(color: AppColors.muted, fontSize: 13);
    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 10,
          runSpacing: 6,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            AdminStatusChip(question.code),
            if (question.sectionTitle.isNotEmpty)
              Text(question.sectionTitle, style: meta),
            if (question.format.isNotEmpty) Text(question.format, style: meta),
            if (question.technique.isNotEmpty)
              Text(question.technique, style: meta),
            if (question.required)
              Text(
                l10n.cultureQuestionsRequiredBadge,
                style: const TextStyle(
                  color: AppColors.ink,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            if (!question.active)
              Text(
                l10n.cultureQuestionsInactive,
                style: const TextStyle(
                  color: Color(0xFFB42318),
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
          ],
        ),
        if (question.name.isNotEmpty) ...[
          const SizedBox(height: 10),
          Text(
            question.name,
            style: const TextStyle(
              color: AppColors.ink,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
        const SizedBox(height: 4),
        Text(
          question.statement,
          style: const TextStyle(
            color: AppColors.ink,
            fontSize: 15,
            height: 1.4,
          ),
        ),
        if (question.instruction.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(
            question.instruction,
            style: const TextStyle(
              color: AppColors.subtitle,
              fontSize: 13.5,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
        if (question.options.isNotEmpty) ...[
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final option in question.options)
                AdminStatusChip(
                  option.dimension.isEmpty
                      ? option.label
                      : '${option.label} · ${option.dimension}',
                ),
            ],
          ),
        ],
      ],
    );
    final actions = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Switch(value: question.active, onChanged: busy ? null : onToggle),
        IconButton(
          tooltip: l10n.adminQuestionsMoveUp,
          onPressed: busy ? null : onMoveUp,
          icon: const Icon(Icons.arrow_upward),
        ),
        IconButton(
          tooltip: l10n.adminQuestionsMoveDown,
          onPressed: busy ? null : onMoveDown,
          icon: const Icon(Icons.arrow_downward),
        ),
        IconButton(
          tooltip: l10n.adminQuestionsEdit,
          onPressed: busy ? null : onEdit,
          icon: const Icon(Icons.edit_outlined),
        ),
        IconButton(
          tooltip: l10n.adminQuestionsDelete,
          onPressed: busy ? null : onDelete,
          icon: const Icon(Icons.delete_outline),
          color: const Color(0xFFB42318),
        ),
      ],
    );
    return Opacity(
      opacity: question.active ? 1 : 0.6,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: compact
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  content,
                  const SizedBox(height: 8),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: actions,
                  ),
                ],
              )
            : Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: content),
                  const SizedBox(width: 12),
                  actions,
                ],
              ),
      ),
    );
  }
}
