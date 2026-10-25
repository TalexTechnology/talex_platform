import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:talex_platform/core/constants/app_colors.dart';
import 'package:talex_platform/core/di/injection.dart';
import 'package:talex_platform/core/services/notification_service.dart';
import 'package:talex_platform/features/admin/data/datasources/assessment_question_data_source.dart';
import 'package:talex_platform/features/admin/data/datasources/supabase_assessment_question_data_source.dart';
import 'package:talex_platform/features/admin/domain/entities/assessment_question.dart';
import 'package:talex_platform/features/admin/domain/services/assessment_question_csv.dart';
import 'package:talex_platform/features/admin/domain/services/assessment_question_defaults.dart';
import 'package:talex_platform/features/admin/presentation/widgets/admin_question_dialogs.dart';
import 'package:talex_platform/features/admin/presentation/widgets/admin_widgets.dart';
import 'package:talex_platform/features/admin/presentation/widgets/survey_preview_dialog.dart';
import 'package:talex_platform/l10n/l10n.dart';

class AdminQuestionsView extends StatefulWidget {
  const AdminQuestionsView({
    super.key,
    this.slug = affinitySurveySlug,
    this.allowSeed = true,
    this.hideUploadWhenFilled = false,
  });

  final String slug;
  final bool allowSeed;
  final bool hideUploadWhenFilled;

  @override
  State<AdminQuestionsView> createState() => _AdminQuestionsViewState();
}

class _AdminQuestionsViewState extends State<AdminQuestionsView> {
  late final AssessmentQuestionDataSource _source =
      SupabaseAssessmentQuestionDataSource(
        database: resolveRemoteDatabase(),
        slug: widget.slug,
      );
  late Stream<List<AssessmentQuestion>> _stream = _source.watch();
  AssessmentFront? _front;
  var _query = '';
  var _busy = false;
  String? _progress;

  bool get _isCulture => widget.slug == cultureSurveySlug;

  List<AssessmentFront> get _fronts => _isCulture
      ? AssessmentFront.cultureFronts
      : AssessmentFront.affinityFronts;

  // [progress] muestra un bloqueo con ese texto mientras dura la operación;
  // se usa en las cargas y borrados masivos.
  Future<void> _run(
    Future<void> Function() action, {
    bool notify = true,
    String? progress,
    String? success,
  }) async {
    final l10n = context.l10n;
    final notifications = getIt<NotificationService>();
    setState(() {
      _busy = true;
      _progress = progress;
    });
    try {
      await action();
      if (notify) notifications.success(success ?? l10n.adminSaved);
    } on Exception {
      notifications.error(l10n.adminQuestionsError);
    } finally {
      if (mounted) {
        setState(() {
          _busy = false;
          _progress = null;
        });
      }
    }
  }

  Future<void> _edit(
    List<AssessmentQuestion> all, [
    AssessmentQuestion? question,
  ]) async {
    final result = await showAssessmentQuestionEditor(
      context,
      existing: all,
      question: question,
      fronts: _fronts,
    );
    if (result == null || result == question || !mounted) return;
    await _run(() => _source.save(result));
  }

  Future<void> _delete(AssessmentQuestion question) async {
    if (!await confirmAssessmentQuestionDelete(context, question)) return;
    if (!mounted) return;
    await _run(() => _source.delete(question.code));
  }

  Future<void> _importCsv(List<AssessmentQuestion> all) async {
    final l10n = context.l10n;
    final notifications = getIt<NotificationService>();
    final picked = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['csv', 'json'],
      withData: true,
    );
    if (picked == null || !mounted) return;
    final List<AssessmentQuestion> questions;
    try {
      final file = picked.files.single;
      final bytes = file.bytes;
      if (bytes == null) {
        throw const AssessmentCsvException(AssessmentCsvError.unreadable);
      }
      questions = AssessmentQuestionCsv.parseUpload(file.name, bytes);
    } on AssessmentCsvException catch (error) {
      notifications.error(assessmentCsvErrorMessage(l10n, error));
      return;
    }
    final existing = {for (final question in all) question.code};
    final confirmed = await confirmAssessmentQuestionsImport(
      context,
      total: questions.length,
      replaced: questions.where((item) => existing.contains(item.code)).length,
    );
    if (!confirmed || !mounted) return;
    await _run(
      () => _source.saveAll(questions),
      progress: l10n.adminQuestionsUploading,
      success: l10n.adminQuestionsUploaded(questions.length),
    );
  }

  Future<void> _deleteAll(int count) async {
    final l10n = context.l10n;
    if (!await confirmAssessmentQuestionsDeleteAll(context, count)) return;
    if (!mounted) return;
    await _run(
      _source.deleteAll,
      progress: l10n.adminQuestionsDeleting,
      success: l10n.adminQuestionsDeletedAll,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final compact = MediaQuery.sizeOf(context).width < 720;
    return StreamBuilder<List<AssessmentQuestion>>(
      stream: _stream,
      builder: (context, snapshot) {
        final all = snapshot.data ?? const <AssessmentQuestion>[];
        final visible = [
          for (final question in all)
            if ((_front == null || question.front == _front) &&
                question.matches(_query))
              question,
        ];
        final Widget body;
        if (snapshot.hasError) {
          body = AdminErrorState(
            message: l10n.adminQuestionsError,
            onRetry: () => setState(() => _stream = _source.watch()),
          );
        } else if (!snapshot.hasData) {
          body = const _QuestionsSkeleton();
        } else if (all.isEmpty) {
          body = Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AdminEmptyState(
                message: _isCulture
                    ? l10n.adminCultureSurveyEmpty
                    : l10n.adminQuestionsEmpty,
                icon: Icons.quiz_outlined,
              ),
              const SizedBox(height: 16),
              Center(
                child: Wrap(
                  spacing: 12,
                  runSpacing: 8,
                  alignment: WrapAlignment.center,
                  children: [
                    FilledButton.icon(
                      onPressed: _busy ? null : () => _importCsv(all),
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.primaryButton,
                      ),
                      icon: const Icon(Icons.upload_file_outlined),
                      label: Text(
                        _isCulture
                            ? l10n.adminQuestionsUploadFile
                            : l10n.adminQuestionsImport,
                      ),
                    ),
                    if (widget.allowSeed)
                      OutlinedButton.icon(
                        onPressed: _busy
                            ? null
                            : () => _run(
                                _source.seedDefaults,
                                progress: l10n.adminQuestionsUploading,
                                success: l10n.adminQuestionsUploaded(
                                  AssessmentQuestionDefaults.all.length,
                                ),
                              ),
                        icon: const Icon(Icons.cloud_upload_outlined),
                        label: Text(
                          l10n.adminQuestionsSeed(
                            AssessmentQuestionDefaults.all.length,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          );
        } else {
          body = Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _Filters(
                all: all,
                fronts: _fronts,
                front: _front,
                onFront: (front) => setState(() => _front = front),
                onQuery: (query) => setState(() => _query = query),
              ),
              const SizedBox(height: 16),
              if (visible.isEmpty)
                AdminEmptyState(
                  message: l10n.adminQuestionsNoResults,
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
                            () => _source.setActive(question.code, active),
                            notify: false,
                          ),
                          onPreview: () => showSurveyPreview(
                            context,
                            all,
                            startCode: question.code,
                          ),
                          onEdit: () => _edit(all, question),
                          onDelete: () => _delete(question),
                          onMoveUp: index == 0
                              ? null
                              : () => _run(
                                  () => _source.swapOrder(
                                    question,
                                    visible[index - 1],
                                  ),
                                  notify: false,
                                ),
                          onMoveDown: index == visible.length - 1
                              ? null
                              : () => _run(
                                  () => _source.swapOrder(
                                    question,
                                    visible[index + 1],
                                  ),
                                  notify: false,
                                ),
                        ),
                      ],
                    ],
                  ),
                ),
            ],
          );
        }
        final page = SingleChildScrollView(
          padding: EdgeInsets.all(compact ? 18 : 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AdminPageHeader(
                title: _isCulture
                    ? l10n.adminCultureSurvey
                    : l10n.adminQuestions,
                subtitle: _isCulture
                    ? l10n.adminCultureSurveySubtitle
                    : l10n.adminQuestionsSubtitle,
                actions: [
                  if (all.isNotEmpty)
                    TextButton.icon(
                      onPressed: _busy ? null : () => _deleteAll(all.length),
                      style: TextButton.styleFrom(
                        foregroundColor: const Color(0xFFB42318),
                      ),
                      icon: const Icon(Icons.delete_sweep_outlined),
                      label: Text(l10n.adminQuestionsDeleteAll),
                    ),
                  if (!widget.hideUploadWhenFilled)
                    OutlinedButton.icon(
                      onPressed: snapshot.hasData && !_busy
                          ? () => _importCsv(all)
                          : null,
                      icon: const Icon(Icons.upload_file_outlined),
                      label: Text(
                        _isCulture
                            ? l10n.adminQuestionsUploadFile
                            : l10n.adminQuestionsImport,
                      ),
                    ),
                  OutlinedButton.icon(
                    onPressed: all.isEmpty
                        ? null
                        : () => showSurveyPreview(context, all),
                    icon: const Icon(Icons.visibility_outlined),
                    label: Text(l10n.adminQuestionsPreview),
                  ),
                  FilledButton.icon(
                    onPressed:
                        snapshot.hasData &&
                            !_busy &&
                            (!widget.hideUploadWhenFilled || all.isNotEmpty)
                        ? () => _edit(all)
                        : null,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primaryButton,
                    ),
                    icon: const Icon(Icons.add),
                    label: Text(l10n.adminQuestionsNew),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              body,
            ],
          ),
        );
        return Stack(
          children: [
            page,
            if (_progress != null)
              Positioned.fill(child: _ProgressOverlay(message: _progress!)),
          ],
        );
      },
    );
  }
}

class _ProgressOverlay extends StatelessWidget {
  const _ProgressOverlay({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) => AbsorbPointer(
    child: ColoredBox(
      color: const Color(0xB3FBF9FA),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.softBorder),
            boxShadow: const [
              BoxShadow(
                color: Color(0x1F071326),
                blurRadius: 24,
                offset: Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2.4),
              ),
              const SizedBox(width: 14),
              Text(
                message,
                style: const TextStyle(
                  color: AppColors.ink,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

class _Filters extends StatelessWidget {
  const _Filters({
    required this.all,
    required this.fronts,
    required this.front,
    required this.onFront,
    required this.onQuery,
  });
  final List<AssessmentQuestion> all;
  final List<AssessmentFront> fronts;
  final AssessmentFront? front;
  final ValueChanged<AssessmentFront?> onFront;
  final ValueChanged<String> onQuery;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    int count(AssessmentFront? value) => value == null
        ? all.length
        : all.where((item) => item.front == value).length;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          onChanged: onQuery,
          decoration: InputDecoration(
            hintText: l10n.adminQuestionsSearch,
            prefixIcon: const Icon(Icons.search),
            filled: true,
            fillColor: Colors.white,
            border: const OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            for (final value in <AssessmentFront?>[null, ...fronts])
              ChoiceChip(
                label: Text(
                  '${value == null ? l10n.adminQuestionsAll : assessmentFrontLabel(l10n, value)} (${count(value)})',
                ),
                selected: front == value,
                onSelected: (_) => onFront(value),
              ),
            Text(
              l10n.adminQuestionsSummary(
                all.where((item) => item.active).length,
                all.length,
              ),
              style: const TextStyle(color: AppColors.muted, fontSize: 13),
            ),
          ],
        ),
      ],
    );
  }
}

// Placeholder con la forma de la lista mientras llega el banco de preguntas.
class _QuestionsSkeleton extends StatefulWidget {
  const _QuestionsSkeleton();

  @override
  State<_QuestionsSkeleton> createState() => _QuestionsSkeletonState();
}

class _QuestionsSkeletonState extends State<_QuestionsSkeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
    lowerBound: 0.45,
  )..repeat(reverse: true);

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _pulse,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _SkeletonBox(height: 56),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final width in const [70.0, 110.0, 96.0, 120.0, 88.0])
                _SkeletonBox(width: width, height: 34),
            ],
          ),
          const SizedBox(height: 16),
          AdminPanel(
            child: Column(
              children: [
                for (var index = 0; index < 6; index++) ...[
                  if (index > 0)
                    const Divider(height: 1, color: AppColors.divider),
                  const Padding(
                    padding: EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            _SkeletonBox(width: 64, height: 24),
                            SizedBox(width: 10),
                            _SkeletonBox(width: 90, height: 14),
                            SizedBox(width: 10),
                            _SkeletonBox(width: 120, height: 14),
                          ],
                        ),
                        SizedBox(height: 12),
                        _SkeletonBox(height: 14),
                        SizedBox(height: 8),
                        FractionallySizedBox(
                          widthFactor: 0.6,
                          child: _SkeletonBox(height: 14),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SkeletonBox extends StatelessWidget {
  const _SkeletonBox({this.width, required this.height});

  final double? width;
  final double height;

  @override
  Widget build(BuildContext context) => Container(
    width: width ?? double.infinity,
    height: height,
    decoration: BoxDecoration(
      color: const Color(0xFFE9EAEE),
      borderRadius: BorderRadius.circular(6),
    ),
  );
}

class _QuestionTile extends StatelessWidget {
  const _QuestionTile({
    required this.question,
    required this.compact,
    required this.busy,
    required this.onToggle,
    required this.onPreview,
    required this.onEdit,
    required this.onDelete,
    required this.onMoveUp,
    required this.onMoveDown,
  });
  final AssessmentQuestion question;
  final bool compact, busy;
  final ValueChanged<bool> onToggle;
  final VoidCallback onPreview, onEdit, onDelete;
  final VoidCallback? onMoveUp, onMoveDown;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    const meta = TextStyle(color: AppColors.muted, fontSize: 13);
    final limit = question.timeLimitSeconds;
    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 10,
          runSpacing: 6,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            AdminStatusChip(question.code),
            Text(assessmentFrontLabel(l10n, question.front), style: meta),
            Text(assessmentFormatLabel(l10n, question.format), style: meta),
            Text(
              question.isPair && question.dimensionB.isNotEmpty
                  ? '${question.dimensionA} / ${question.dimensionB}'
                  : question.dimensionA,
              style: const TextStyle(
                color: AppColors.ink,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.timer_outlined,
                  size: 15,
                  color: AppColors.muted,
                ),
                const SizedBox(width: 3),
                Text(
                  limit == null
                      ? l10n.adminQuestionsNoLimit
                      : l10n.adminQuestionsSeconds(limit),
                  style: meta,
                ),
              ],
            ),
            if (!question.active)
              Text(
                l10n.adminQuestionsInactive,
                style: const TextStyle(
                  color: Color(0xFFB42318),
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        _statement(question.isPair ? 'A' : null, question.statementA),
        if (question.isPair) ...[
          const SizedBox(height: 4),
          _statement('B', question.statementB),
        ],
      ],
    );
    final actions = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Switch(value: question.active, onChanged: busy ? null : onToggle),
        IconButton(
          tooltip: l10n.adminQuestionsPreview,
          onPressed: question.active ? onPreview : null,
          icon: const Icon(Icons.visibility_outlined),
        ),
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
        ),
      ],
    );
    return Opacity(
      opacity: question.active ? 1 : 0.6,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        child: compact
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  content,
                  const SizedBox(height: 6),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: actions,
                  ),
                ],
              )
            : Row(
                children: [
                  Expanded(child: content),
                  const SizedBox(width: 16),
                  actions,
                ],
              ),
      ),
    );
  }

  Widget _statement(String? letter, String text) => Text.rich(
    TextSpan(
      children: [
        if (letter != null)
          TextSpan(
            text: '$letter  ',
            style: const TextStyle(
              color: AppColors.dashboardAccent,
              fontWeight: FontWeight.w700,
            ),
          ),
        TextSpan(text: text),
      ],
    ),
    style: const TextStyle(color: AppColors.ink, fontSize: 15, height: 1.35),
  );
}
