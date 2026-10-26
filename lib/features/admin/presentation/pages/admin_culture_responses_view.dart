import 'package:flutter/material.dart';
import 'package:talex_platform/core/constants/app_colors.dart';
import 'package:talex_platform/core/constants/app_radii.dart';
import 'package:talex_platform/core/widgets/skeleton.dart';
import 'package:talex_platform/core/widgets/talex_ui.dart';
import 'package:talex_platform/features/admin/data/datasources/culture_report_data_source.dart';
import 'package:talex_platform/features/admin/domain/entities/culture_organization_report.dart';
import 'package:talex_platform/features/admin/domain/entities/culture_survey_responses.dart';
import 'package:talex_platform/features/admin/presentation/widgets/admin_widgets.dart';
import 'package:talex_platform/l10n/l10n.dart';

// Detalle de "Mi cultura" para una empresa: lo que respondió su equipo en la
// encuesta de cultura. Las respuestas son anónimas: se muestran agregadas por
// pregunta o numeradas por persona, sin ningún dato de quién respondió.
class AdminCultureResponsesView extends StatefulWidget {
  const AdminCultureResponsesView({
    super.key,
    required this.group,
    required this.source,
    required this.onBack,
  });

  final CultureOrganizationGroup group;
  final CultureReportDataSource source;
  final VoidCallback onBack;

  @override
  State<AdminCultureResponsesView> createState() =>
      _AdminCultureResponsesViewState();
}

class _AdminCultureResponsesViewState extends State<AdminCultureResponsesView> {
  // El grupo sin empresa asignada no tiene encuesta: solo leads.
  late Future<CultureSurveyResponses>? _responses = _load();
  var _byPerson = false;

  Future<CultureSurveyResponses>? _load() {
    final id = widget.group.id;
    return id == null ? null : widget.source.responses(id);
  }

  void _reload() => setState(() => _responses = _load());

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final labels = AdminLabels(context);
    final group = widget.group;
    final compact = MediaQuery.sizeOf(context).width < 720;
    final details = [
      if (group.sizeLabel != null)
        '${l10n.cultureLeadEmployees}: ${group.sizeLabel}',
      if (group.summary.lastLeadAt != null)
        '${l10n.adminMyCultureLastLead}: ${labels.date(group.summary.lastLeadAt!.toLocal())}',
    ];
    return SingleChildScrollView(
      padding: EdgeInsets.all(compact ? 18 : 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: widget.onBack,
              icon: const Icon(Icons.arrow_back, size: 18),
              label: Text(l10n.cultureResponsesBack),
            ),
          ),
          const SizedBox(height: 12),
          AdminPageHeader(
            eyebrow: l10n.adminSurveysMyCulture,
            title: group.unassigned
                ? l10n.adminMyCultureUnassigned
                : (group.name ?? ''),
            subtitle: details.join(' · '),
          ),
          const SizedBox(height: 24),
          if (_responses != null)
            FutureBuilder<CultureSurveyResponses>(
              future: _responses,
              builder: (context, snapshot) {
                if (snapshot.connectionState != ConnectionState.done) {
                  return const Skeleton(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        SkeletonStats(),
                        SizedBox(height: 20),
                        SkeletonList(count: 4, separate: true),
                      ],
                    ),
                  );
                }
                final data = snapshot.data;
                if (snapshot.hasError || data == null) {
                  return AdminErrorState(
                    message: l10n.cultureResponsesError,
                    onRetry: _reload,
                  );
                }
                return _content(context, data);
              },
            ),
          if (group.leads.isNotEmpty) ...[
            const SizedBox(height: 32),
            _LeadSection(group: group),
          ],
        ],
      ),
    );
  }

  Widget _content(BuildContext context, CultureSurveyResponses data) {
    final l10n = context.l10n;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          spacing: 16,
          runSpacing: 16,
          children: [
            TalexStat(
              label: l10n.cultureResponsesRespondents,
              value: '${data.respondentCount}',
              icon: Icons.groups_outlined,
              tone: TalexTone.green,
              width: 220,
            ),
            TalexStat(
              label: l10n.cultureResponsesQuestions,
              value: '${data.questions.length}',
              icon: Icons.quiz_outlined,
              width: 220,
            ),
          ],
        ),
        const SizedBox(height: 16),
        _AnonymityNote(text: l10n.cultureResponsesAnonymous),
        const SizedBox(height: 24),
        if (data.respondentCount == 0)
          AdminEmptyState(
            message: l10n.cultureResponsesEmpty,
            icon: Icons.hourglass_empty,
          )
        else ...[
          Align(
            alignment: Alignment.centerLeft,
            child: SegmentedButton<bool>(
              showSelectedIcon: false,
              segments: [
                ButtonSegment(
                  value: false,
                  icon: const Icon(Icons.bar_chart, size: 18),
                  label: Text(l10n.cultureResponsesSummary),
                ),
                ButtonSegment(
                  value: true,
                  icon: const Icon(Icons.person_outline, size: 18),
                  label: Text(l10n.cultureResponsesIndividual),
                ),
              ],
              selected: {_byPerson},
              onSelectionChanged: (value) =>
                  setState(() => _byPerson = value.first),
            ),
          ),
          const SizedBox(height: 20),
          if (_byPerson)
            for (final (index, response) in data.responses.indexed)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _PersonCard(
                  index: index + 1,
                  data: data,
                  response: response,
                ),
              )
          else
            for (final (index, question) in data.questions.indexed)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _QuestionCard(
                  number: index + 1,
                  question: question,
                  data: data,
                ),
              ),
        ],
      ],
    );
  }
}

class _AnonymityNote extends StatelessWidget {
  const _AnonymityNote({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) => TalexPanel(
    color: AppColors.blueDim,
    borderColor: AppColors.blue.withValues(alpha: 0.25),
    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
    child: Row(
      children: [
        Icon(Icons.lock_outline, size: 18, color: AppColors.blue),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: TextStyle(color: AppColors.text, fontSize: 14, height: 1.5),
          ),
        ),
      ],
    ),
  );
}

class _QuestionCard extends StatelessWidget {
  const _QuestionCard({
    required this.number,
    required this.question,
    required this.data,
  });

  final int number;
  final CultureSurveyQuestion question;
  final CultureSurveyResponses data;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final answered = data.answeredCount(question);
    return TalexPanel(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              TalexEyebrow(
                [
                  '$number',
                  if (question.sectionTitle != null) question.sectionTitle!,
                ].join(' · '),
              ),
              const Spacer(),
              Text(
                l10n.cultureResponsesAnswered(answered, data.respondentCount),
                style: TextStyle(color: AppColors.textDimmer, fontSize: 12.5),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            question.statement,
            style: TextStyle(
              color: AppColors.text,
              fontSize: 17,
              height: 1.45,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 18),
          if (answered == 0)
            Text(
              l10n.cultureResponsesNoAnswers,
              style: TextStyle(color: AppColors.textMuted),
            )
          else
            _QuestionResults(question: question, data: data, total: answered),
        ],
      ),
    );
  }
}

class _QuestionResults extends StatelessWidget {
  const _QuestionResults({
    required this.question,
    required this.data,
    required this.total,
  });

  final CultureSurveyQuestion question;
  final CultureSurveyResponses data;
  final int total;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    switch (question.format) {
      case 'most_least':
        final result = data.mostLeast(question);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _Legend(
              entries: [
                (AppColors.green, l10n.cultureResponsesMost),
                (AppColors.warning, l10n.cultureResponsesLeast),
              ],
            ),
            const SizedBox(height: 14),
            for (final (index, most) in result.most.indexed) ...[
              _DualBar(
                label: most.label,
                first: most.count,
                second: index < result.least.length
                    ? result.least[index].count
                    : 0,
                total: total,
              ),
              const SizedBox(height: 12),
            ],
            if (result.forecast != null)
              Text(
                l10n.cultureResponsesForecast(
                  result.forecast!.toStringAsFixed(0),
                ),
                style: TextStyle(color: AppColors.textMuted, fontSize: 13.5),
              ),
          ],
        );
      case 'value_coherence':
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (final (item, tallies) in data.coherence(question)) ...[
              Text(
                item,
                style: TextStyle(
                  color: AppColors.text,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              _StackedBar(tallies: tallies, total: total),
              const SizedBox(height: 16),
            ],
          ],
        );
      case 'pick_yes_no':
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _Legend(
              entries: [
                (AppColors.green, l10n.cultureResponsesYes),
                (AppColors.danger, l10n.cultureResponsesNo),
              ],
            ),
            const SizedBox(height: 14),
            for (final (label, yes, no) in data.yesNo(question)) ...[
              _DualBar(
                label: label,
                first: yes,
                second: no,
                total: total,
                secondColor: AppColors.danger,
              ),
              const SizedBox(height: 12),
            ],
          ],
        );
      case 'text':
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (final text in data.texts(question))
              Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: AppRadii.border,
                  border: Border(
                    left: BorderSide(color: AppColors.green, width: 3),
                  ),
                ),
                child: Text(
                  '“$text”',
                  style: TextStyle(
                    color: AppColors.text,
                    fontSize: 14.5,
                    height: 1.55,
                  ),
                ),
              ),
          ],
        );
      default:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (final tally in data.single(question)) ...[
              _Bar(label: tally.label, count: tally.count, total: total),
              const SizedBox(height: 12),
            ],
          ],
        );
    }
  }
}

class _Legend extends StatelessWidget {
  const _Legend({required this.entries});
  final List<(Color, String)> entries;

  @override
  Widget build(BuildContext context) => Wrap(
    spacing: 16,
    children: [
      for (final (color, label) in entries)
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(color: AppColors.textMuted, fontSize: 12.5),
            ),
          ],
        ),
    ],
  );
}

String _percent(int count, int total) =>
    total == 0 ? '0%' : '${(count * 100 / total).round()}%';

class _Bar extends StatelessWidget {
  const _Bar({required this.label, required this.count, required this.total});

  final String label;
  final int count;
  final int total;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Row(
        children: [
          Expanded(
            child: Text(label, style: TextStyle(color: AppColors.text)),
          ),
          Text(
            '$count · ${_percent(count, total)}',
            style: TextStyle(
              color: AppColors.textMuted,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
      const SizedBox(height: 6),
      _Track(value: total == 0 ? 0 : count / total, color: AppColors.company),
    ],
  );
}

class _DualBar extends StatelessWidget {
  const _DualBar({
    required this.label,
    required this.first,
    required this.second,
    required this.total,
    this.secondColor,
  });

  final String label;
  final int first;
  final int second;
  final int total;
  final Color? secondColor;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Row(
        children: [
          Expanded(
            child: Text(label, style: TextStyle(color: AppColors.text)),
          ),
          Text(
            '$first',
            style: TextStyle(
              color: AppColors.green,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
          Text(' / ', style: TextStyle(color: AppColors.textDimmer)),
          Text(
            '$second',
            style: TextStyle(
              color: secondColor ?? AppColors.warning,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
      const SizedBox(height: 6),
      _Track(value: total == 0 ? 0 : first / total, color: AppColors.green),
      const SizedBox(height: 3),
      _Track(
        value: total == 0 ? 0 : second / total,
        color: secondColor ?? AppColors.warning,
      ),
    ],
  );
}

class _StackedBar extends StatelessWidget {
  const _StackedBar({required this.tallies, required this.total});

  final List<CultureTally> tallies;
  final int total;

  @override
  Widget build(BuildContext context) {
    final palette = [
      AppColors.green,
      AppColors.company,
      AppColors.warning,
      AppColors.danger,
      AppColors.slate,
    ];
    final shown = [
      for (final (index, tally) in tallies.indexed)
        if (tally.count > 0) (tally, palette[index % palette.length]),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: SizedBox(
            height: 10,
            child: Row(
              children: [
                for (final (tally, color) in shown)
                  Expanded(
                    flex: tally.count,
                    child: ColoredBox(color: color),
                  ),
                if (shown.isEmpty)
                  Expanded(child: ColoredBox(color: AppColors.surface2)),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 14,
          runSpacing: 4,
          children: [
            for (final (index, tally) in tallies.indexed)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: palette[index % palette.length],
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '${tally.label} · ${tally.count} (${_percent(tally.count, total)})',
                    style: TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 12.5,
                    ),
                  ),
                ],
              ),
          ],
        ),
      ],
    );
  }
}

class _Track extends StatelessWidget {
  const _Track({required this.value, required this.color});
  final double value;
  final Color color;

  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: BorderRadius.circular(4),
    child: LinearProgressIndicator(
      value: value.clamp(0.0, 1.0),
      minHeight: 6,
      color: color,
      backgroundColor: AppColors.surface2,
    ),
  );
}

class _PersonCard extends StatelessWidget {
  const _PersonCard({
    required this.index,
    required this.data,
    required this.response,
  });

  final int index;
  final CultureSurveyResponses data;
  final Map<String, dynamic> response;

  @override
  Widget build(BuildContext context) {
    final answered = [
      for (final question in data.questions)
        if (data.describe(question, response).trim().isNotEmpty) question,
    ];
    return TalexPanel(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const TalexIconBadge(
                Icons.person_outline,
                tone: TalexTone.green,
                size: 34,
              ),
              const SizedBox(width: 12),
              TalexSectionTitle(context.l10n.cultureResponsesPerson(index)),
            ],
          ),
          const SizedBox(height: 16),
          for (final (i, question) in answered.indexed) ...[
            if (i > 0) const TalexDivider(height: 24),
            Text(
              question.statement,
              style: TextStyle(color: AppColors.textMuted, fontSize: 13.5),
            ),
            const SizedBox(height: 4),
            Text(
              data.describe(question, response),
              style: TextStyle(
                color: AppColors.text,
                fontWeight: FontWeight.w600,
                height: 1.5,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// Lo que dejó la empresa en la landing /micultura (no es anónimo: es el
// contacto que pidió el diagnóstico, no las respuestas del equipo).
class _LeadSection extends StatelessWidget {
  const _LeadSection({required this.group});
  final CultureOrganizationGroup group;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final summary = group.summary;
    return TalexPanel(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TalexSectionTitle(l10n.cultureResponsesLead),
          const SizedBox(height: 18),
          if (summary.perceivedCulture.isNotEmpty) ...[
            _Label(l10n.cultureLeadTraits),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final trait in summary.perceivedCulture)
                  AdminStatusChip(
                    trait.pct == null
                        ? trait.label
                        : '${trait.label} · ${trait.pct!.round()}%',
                  ),
              ],
            ),
            const SizedBox(height: 16),
          ],
          if (summary.comments.isNotEmpty) ...[
            _Label(l10n.adminMyCultureComments),
            for (final comment in summary.comments)
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Text(
                  '“${comment.comment}”',
                  style: TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 14.5,
                    height: 1.4,
                  ),
                ),
              ),
            const SizedBox(height: 10),
          ],
          _Label(l10n.adminMyCultureLeads),
          for (final (index, item) in group.leads.indexed) ...[
            if (index > 0) const TalexDivider(height: 20),
            _LeadRow(item: item),
          ],
        ],
      ),
    );
  }
}

class _LeadRow extends StatelessWidget {
  const _LeadRow({required this.item});

  final CultureReportLead item;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final labels = AdminLabels(context);
    final lead = item.lead;
    final emailStatus = switch (item.emailStatus) {
      'sent' => l10n.adminMyCultureEmailSent,
      'skipped' => l10n.adminMyCultureEmailSkipped,
      'failed' => l10n.adminMyCultureEmailFailed,
      _ => null,
    };
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                [?item.contactName, lead.email].join(' · '),
                style: TextStyle(
                  color: AppColors.text,
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                [
                  lead.companyName,
                  if (lead.employeeRange.isNotEmpty) lead.employeeRange,
                  if (lead.perceivedCulture.isNotEmpty) lead.cultureTraitsLabel,
                  labels.date(lead.createdAt.toLocal()),
                  ?emailStatus,
                ].join(' · '),
                style: TextStyle(color: AppColors.textMuted, fontSize: 13.5),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        AdminStatusChip(
          item.responded
              ? l10n.adminMyCultureRespondedBadge
              : l10n.adminMyCulturePending,
          tone: item.responded ? TalexTone.green : TalexTone.neutral,
        ),
      ],
    );
  }
}

class _Label extends StatelessWidget {
  const _Label(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Text(
      text,
      style: TextStyle(
        color: AppColors.textDimmer,
        fontSize: 12.5,
        fontWeight: FontWeight.w600,
      ),
    ),
  );
}
