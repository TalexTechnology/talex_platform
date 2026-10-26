import 'package:flutter/material.dart';
import 'package:talex_platform/core/widgets/talex_ui.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:talex_platform/core/constants/app_colors.dart';
import 'package:talex_platform/core/di/injection.dart';
import 'package:talex_platform/core/services/notification_service.dart';
import 'package:talex_platform/core/services/pdf_saver.dart';
import 'package:talex_platform/core/widgets/affinity_badge.dart';
import 'package:talex_platform/core/widgets/content_width.dart';
import 'package:talex_platform/features/admin/presentation/widgets/admin_widgets.dart';
import 'package:talex_platform/features/talent/data/services/candidate_report_pdf.dart';
import 'package:talex_platform/features/talent/domain/entities/talent_entities.dart';
import 'package:talex_platform/features/talent/presentation/bloc/talent_bloc.dart';
import 'package:talex_platform/features/talent/presentation/company_options.dart';
import 'package:talex_platform/features/talent/presentation/pages/talent_views.dart';
import 'package:talex_platform/features/talent/presentation/widgets/talent_dialogs.dart';
import 'package:talex_platform/l10n/l10n.dart';

class TalentCandidateResultView extends StatelessWidget {
  const TalentCandidateResultView({super.key, required this.report});
  final CandidateReport report;

  Future<void> _download(BuildContext context) async {
    final l10n = context.l10n;
    final bytes = await const CandidateReportPdf().build(
      l10n: l10n,
      report: report,
      processLabel: processStatusLabel(context, report.candidate.processStatus),
      affinityLabel: (level) => affinityWord(context, level),
    );
    final name = report.candidate.displayName?.trim().isNotEmpty == true
        ? report.candidate.displayName!
        : report.candidate.email;
    savePdfBytes(bytes, 'talex-${name.replaceAll(' ', '_')}.pdf');
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final candidate = report.candidate;
    final labels = AdminLabels(context);
    final document = candidate.documentNumber.trim();
    final masked = document.length <= 4
        ? '••••'
        : '••••${document.substring(document.length - 4)}';
    return SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: ContentWidth(
        maxWidth: 760,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: () => context.read<TalentBloc>().add(
                  const TalentCandidateClosed(),
                ),
                icon: const Icon(Icons.arrow_back),
                label: Text(l10n.backToResults),
              ),
            ),
            AdminPageHeader(
              eyebrow: context.l10n.companyEyebrow,
              title: candidate.displayName?.trim().isNotEmpty == true
                  ? candidate.displayName!
                  : candidate.email,
              subtitle: l10n.candidateResultTitle,
              actions: [
                OutlinedButton.icon(
                  onPressed: () => showEditCandidateDialog(context, candidate),
                  icon: const Icon(Icons.edit_outlined),
                  label: Text(l10n.editCandidate),
                ),
                OutlinedButton.icon(
                  onPressed: () => showDeleteCandidateDialog(context, candidate),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.danger,
                  ),
                  icon: const Icon(Icons.delete_outline),
                  label: Text(l10n.deleteCandidate),
                ),
                FilledButton.icon(
                  onPressed: () async {
                    try {
                      await _download(context);
                    } catch (_) {
                      if (context.mounted) {
                        getIt<NotificationService>().error(l10n.errorUnexpected);
                      }
                    }
                  },
                  icon: const Icon(Icons.picture_as_pdf_outlined),
                  label: Text(l10n.downloadPdf),
                ),
              ],
            ),
            const SizedBox(height: 20),
            AdminPanel(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Wrap(
                  spacing: 40,
                  runSpacing: 18,
                  children: [
                    _Fact(l10n.emailAddress, candidate.email),
                    _Fact(l10n.documentNumber, masked),
                    _Fact(l10n.vacancy, candidate.vacancyName),
                    if (report.company != null)
                      _Fact(l10n.companyName, report.company!.name),
                    _Fact(l10n.lastActivity, labels.date(candidate.updatedAt)),
                    _Fact(
                      l10n.candidateProcessStatus,
                      processStatusLabel(context, candidate.processStatus),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            _AffinityCard(report: report),
            const SizedBox(height: 8),
            Text(
              l10n.affinityMockNote,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.textDimmer,
                fontSize: 13,
                height: 1.4,
              ),
            ),
            if (report.answers.isNotEmpty) ...[
              const SizedBox(height: 24),
              TalexSectionTitle(l10n.fullSummaryTitle),
              const SizedBox(height: 12),
              for (final id in AssessmentCatalog.allIds)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: AdminPanel(
                    child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          assessmentQuestionLabel(l10n, id),
                          style: TextStyle(
                            color: AppColors.textMuted,
                            fontSize: 13.5,
                            height: 1.5,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          report.answers[id] == null
                              ? l10n.noData
                              : assessmentAnswerLabel(l10n, id, report.answers[id]!),
                          style: TextStyle(
                            color: AppColors.text,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    ),
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }
}

class _AffinityCard extends StatelessWidget {
  const _AffinityCard({required this.report});
  final CandidateReport report;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final candidate = report.candidate;
    final analysis = report.analysis;
    final running = context.select<TalentBloc, bool>(
      (bloc) => bloc.state.analysisRunning,
    );
    final pending = running || analysis.isPending;
    final level = analysis.hasResult ? analysis.level : candidate.companyAffinity;
    return AdminPanel(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            TalexEyebrow(l10n.affinityWithCompany),
            const SizedBox(height: 14),
            AffinityBadge(level),
            if (analysis.hasResult && analysis.score != null) ...[
              const SizedBox(height: 10),
              Text(
                l10n.affinityScoreValue(analysis.score!),
                style: TextStyle(
                  color: AppColors.text,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
            const SizedBox(height: 14),
            if (pending) ...[
              const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              const SizedBox(height: 10),
            ],
            Text(
              pending
                  ? l10n.affinityAnalysisPending
                  : affinityAnalysisMessage(
                      l10n,
                      analysis,
                      evaluationCompleted: candidate.evaluationCompleted,
                    ),
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textMuted, height: 1.4),
            ),
            if (analysis.hasResult && !pending) ...[
              _InsightSection(
                title: l10n.affinityAlignmentsTitle,
                icon: Icons.check,
                color: AppColors.good,
                insights: analysis.alignments,
              ),
              _InsightSection(
                title: l10n.affinityDifferencesTitle,
                icon: Icons.change_history,
                color: AppColors.warning,
                insights: analysis.differences,
              ),
              _TextSection(
                title: l10n.affinityTopicsTitle,
                items: analysis.conversationTopics,
              ),
              if (analysis.guidance.trim().isNotEmpty)
                _TextSection(
                  title: l10n.affinityGuidanceTitle,
                  items: [analysis.guidance.trim()],
                ),
            ],
          ],
        ),
      ),
    );
  }
}

class _InsightSection extends StatelessWidget {
  const _InsightSection({
    required this.title,
    required this.icon,
    required this.color,
    required this.insights,
  });
  final String title;
  final IconData icon;
  final Color color;
  final List<AffinityInsight> insights;

  @override
  Widget build(BuildContext context) {
    if (insights.isEmpty) return const SizedBox.shrink();
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.only(top: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: AppColors.text,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          for (final item in insights)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(icon, size: 18, color: color),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text.rich(
                      TextSpan(
                        children: [
                          TextSpan(
                            text: '${item.aspect}. ',
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          TextSpan(text: item.evidence),
                        ],
                      ),
                      style: TextStyle(
                        color: AppColors.textMuted,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _TextSection extends StatelessWidget {
  const _TextSection({required this.title, required this.items});
  final String title;
  final List<String> items;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.only(top: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: AppColors.text,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          for (final item in items)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Text(
                '• $item',
                style: TextStyle(color: AppColors.textMuted, height: 1.4),
              ),
            ),
        ],
      ),
    );
  }
}

class _Fact extends StatelessWidget {
  const _Fact(this.label, this.value);
  final String label, value;

  @override
  Widget build(BuildContext context) => ConstrainedBox(
    constraints: const BoxConstraints(minWidth: 160, maxWidth: 280),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: TextStyle(color: AppColors.textDimmer, fontSize: 12.5),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            color: AppColors.text,
            fontSize: 14.5,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    ),
  );
}
