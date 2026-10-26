import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:talex_platform/core/constants/app_colors.dart';
import 'package:talex_platform/core/utils/local_storage.dart';
import 'package:talex_platform/core/utils/open_url.dart';
import 'package:talex_platform/core/widgets/skeleton.dart';
import 'package:talex_platform/features/admin/data/datasources/culture_question_data_source.dart';
import 'package:talex_platform/features/admin/data/datasources/culture_report_data_source.dart';
import 'package:talex_platform/features/admin/domain/entities/culture_organization_report.dart';
import 'package:talex_platform/features/admin/presentation/pages/admin_culture_questions_view.dart';
import 'package:talex_platform/features/admin/presentation/widgets/admin_widgets.dart';
import 'package:talex_platform/features/culture/domain/culture_survey_link.dart';
import 'package:talex_platform/l10n/l10n.dart';

// Abre en otra pestaña el banco activo como si fuera la encuesta, sin empresa.
// window.open va sin awaits de por medio para que el navegador no lo bloquee.
void _openSurveyPreview(Map<String, dynamic> bank) {
  writeLocalStorage(CultureSurveyLink.previewStorageKey, jsonEncode(bank));
  openExternalUrl(CultureSurveyLink.previewUrl(base: Uri.base));
}

// Pestaña "Mi cultura": leads de la landing /micultura agrupados por empresa.
class AdminMyCultureView extends StatefulWidget {
  const AdminMyCultureView({super.key, this.source, this.questions});

  final CultureReportDataSource? source;
  final CultureQuestionDataSource? questions;

  @override
  State<AdminMyCultureView> createState() => _AdminMyCultureViewState();
}

class _AdminMyCultureViewState extends State<AdminMyCultureView> {
  late final CultureReportDataSource _source =
      widget.source ?? CultureReportDataSource();
  late final CultureQuestionDataSource _questions =
      widget.questions ?? CultureQuestionDataSource();
  late Future<CultureOrganizationReport> _report = _source.load();
  // Se precarga para abrir la pestaña de la vista previa sin esperar la red.
  Map<String, dynamic>? _preview;
  var _query = '';
  var _showQuestions = false;

  @override
  void initState() {
    super.initState();
    _loadPreview();
  }

  Future<void> _loadPreview() async {
    try {
      final preview = await _questions.preview();
      if (mounted) setState(() => _preview = preview);
    } catch (_) {
      // Sin banco no hay vista previa; el botón queda deshabilitado.
    }
  }

  void _reload() {
    setState(() {
      _report = _source.load();
    });
    _loadPreview();
  }

  @override
  Widget build(BuildContext context) {
    if (_showQuestions) {
      return AdminCultureQuestionsView(
        onBack: () => setState(() => _showQuestions = false),
      );
    }
    final l10n = context.l10n;
    final compact = MediaQuery.sizeOf(context).width < 720;
    return FutureBuilder<CultureOrganizationReport>(
      future: _report,
      builder: (context, snapshot) {
        final loading = snapshot.connectionState != ConnectionState.done;
        final report = snapshot.data;
        final preview = _preview;
        final Widget body;
        if (loading) {
          body = const Skeleton(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SkeletonStats(),
                SizedBox(height: 20),
                SkeletonBox(height: 48),
                SizedBox(height: 16),
                SkeletonList(count: 4, separate: true),
              ],
            ),
          );
        } else if (snapshot.hasError || report == null) {
          body = AdminErrorState(
            message: l10n.adminMyCultureError,
            onRetry: _reload,
          );
        } else if (report.groups.isEmpty) {
          body = AdminEmptyState(
            message: l10n.adminMyCultureEmpty,
            icon: Icons.diversity_3_outlined,
          );
        } else {
          final visible = [
            for (final group in report.groups)
              if (group.matches(_query)) group,
          ];
          body = Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  _Stat(
                    label: l10n.adminMyCultureOrganizations,
                    value: report.organizationCount,
                  ),
                  _Stat(
                    label: l10n.adminMyCultureLeads,
                    value: report.leadCount,
                  ),
                  _Stat(
                    label: l10n.adminMyCultureResponded,
                    value: report.respondedCount,
                  ),
                  _Stat(
                    label: l10n.adminMyCultureUnassigned,
                    value: report.unassignedLeads,
                  ),
                ],
              ),
              const SizedBox(height: 20),
              TextField(
                onChanged: (value) => setState(() => _query = value),
                decoration: InputDecoration(
                  hintText: l10n.adminMyCultureSearch,
                  prefixIcon: const Icon(Icons.search),
                  filled: true,
                  isDense: true,
                ),
              ),
              const SizedBox(height: 16),
              if (visible.isEmpty)
                AdminEmptyState(
                  message: l10n.adminMyCultureNoResults,
                  icon: Icons.search_off_outlined,
                )
              else
                for (final group in visible)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _OrganizationCard(group: group),
                  ),
            ],
          );
        }
        return SingleChildScrollView(
          padding: EdgeInsets.all(compact ? 18 : 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AdminPageHeader(
                eyebrow: context.l10n.adminEyebrow,
                title: l10n.adminSurveysMyCulture,
                subtitle: l10n.adminMyCultureSubtitle,
                actions: [
                  OutlinedButton.icon(
                    onPressed: loading ? null : _reload,
                    icon: const Icon(Icons.refresh, size: 18),
                    label: Text(l10n.adminMyCultureRefresh),
                  ),
                  OutlinedButton.icon(
                    onPressed: preview == null
                        ? null
                        : () => _openSurveyPreview(preview),
                    icon: const Icon(Icons.play_circle_outline, size: 18),
                    label: Text(l10n.cultureSurveyPreview),
                  ),
                  FilledButton.icon(
                    onPressed: () => setState(() => _showQuestions = true),
                    icon: const Icon(Icons.quiz_outlined, size: 18),
                    label: Text(l10n.cultureQuestionsOpen),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              body,
            ],
          ),
        );
      },
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value});

  final String label;
  final int value;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: 180,
    child: AdminPanel(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '$value',
              style: TextStyle(
                color: AppColors.text,
                fontSize: 28,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(color: AppColors.textMuted, fontSize: 14),
            ),
          ],
        ),
      ),
    ),
  );
}

class _OrganizationCard extends StatelessWidget {
  const _OrganizationCard({required this.group});

  final CultureOrganizationGroup group;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final labels = AdminLabels(context);
    final summary = group.summary;
    final details = [
      if (group.sizeLabel != null)
        '${l10n.cultureLeadEmployees}: ${group.sizeLabel}',
      l10n.adminMyCultureLeadCount(summary.leadCount),
      l10n.adminMyCultureRespondedCount(
        summary.respondedCount,
        summary.leadCount,
      ),
      if (summary.lastLeadAt != null)
        '${l10n.adminMyCultureLastLead}: ${labels.date(summary.lastLeadAt!.toLocal())}',
    ];
    // El Material transparente deja que el splash del ExpansionTile se pinte
    // encima del fondo blanco del panel y no debajo.
    return AdminPanel(
      child: Material(
        color: Colors.transparent,
        child: Theme(
          data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
          child: ExpansionTile(
            shape: const Border(),
            collapsedShape: const Border(),
            tilePadding: const EdgeInsets.symmetric(
              horizontal: 20,
              vertical: 6,
            ),
            childrenPadding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            expandedCrossAxisAlignment: CrossAxisAlignment.start,
            title: Text(
              group.unassigned
                  ? l10n.adminMyCultureUnassigned
                  : (group.name ?? ''),
              style: TextStyle(
                color: AppColors.text,
                fontWeight: FontWeight.w600,
                fontSize: 18,
              ),
            ),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                details.join(' · '),
                style: TextStyle(color: AppColors.textMuted, fontSize: 14),
              ),
            ),
            children: [
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
                if (index > 0)
                  Divider(height: 20, color: AppColors.border),
                _LeadRow(item: item),
              ],
            ],
          ),
        ),
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
                style: TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 13.5,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        AdminStatusChip(
          item.responded
              ? l10n.adminMyCultureRespondedBadge
              : l10n.adminMyCulturePending,
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
