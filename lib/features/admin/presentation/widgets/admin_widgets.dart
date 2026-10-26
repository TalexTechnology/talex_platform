import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:talex_platform/core/constants/app_colors.dart';
import 'package:talex_platform/core/constants/app_radii.dart';
import 'package:talex_platform/core/utils/open_url.dart';
import 'package:talex_platform/core/utils/website_uri.dart';
import 'package:talex_platform/core/widgets/talex_ui.dart';
import 'package:talex_platform/features/admin/domain/entities/admin_entities.dart';
import 'package:talex_platform/l10n/app_localizations.dart';
import 'package:talex_platform/l10n/l10n.dart';

class AdminLabels {
  const AdminLabels(this.context);
  final BuildContext context;
  AppLocalizations get l10n => context.l10n;

  String companyStatus(CompanyStatus status) => switch (status) {
    CompanyStatus.active => l10n.companyStatusActive,
    CompanyStatus.onboarding => l10n.companyStatusOnboarding,
    CompanyStatus.inactive => l10n.companyStatusInactive,
    CompanyStatus.atRisk => l10n.companyStatusAtRisk,
    CompanyStatus.suspended => l10n.companyStatusSuspended,
  };

  String processStatus(ProcessStatus status) => switch (status) {
    ProcessStatus.active => l10n.processStatusActive,
    ProcessStatus.closed => l10n.processStatusClosed,
  };

  String evaluation(EvaluationStatus status) => switch (status) {
    EvaluationStatus.invited => l10n.evaluationInvited,
    EvaluationStatus.started => l10n.evaluationStarted,
    EvaluationStatus.inProgress => l10n.evaluationInProgress,
    EvaluationStatus.completed => l10n.evaluationCompleted,
    EvaluationStatus.abandoned => l10n.evaluationAbandoned,
  };

  String deal(DealStage stage) => switch (stage) {
    DealStage.prospect => l10n.dealProspect,
    DealStage.contacted => l10n.dealContacted,
    DealStage.meeting => l10n.dealMeeting,
    DealStage.proposal => l10n.dealProposal,
    DealStage.negotiation => l10n.dealNegotiation,
    DealStage.client => l10n.dealClient,
  };

  String cultureLead(CultureLeadStatus status) => switch (status) {
    CultureLeadStatus.newLead => l10n.cultureLeadStatusNew,
    CultureLeadStatus.contacted => l10n.cultureLeadStatusContacted,
    CultureLeadStatus.qualified => l10n.cultureLeadStatusQualified,
    CultureLeadStatus.discarded => l10n.cultureLeadStatusDiscarded,
  };

  String activity(ActivityKind kind) => switch (kind) {
    ActivityKind.companyCreated => l10n.newCompany,
    ActivityKind.companyActivated => l10n.companyStatusActive,
    ActivityKind.processCreated => l10n.newProcess,
    ActivityKind.vacancyCreated => l10n.createVacancy,
    ActivityKind.respondentInvited => l10n.createRespondent,
    ActivityKind.evaluationStarted => l10n.evaluationStarted,
    ActivityKind.evaluationCompleted => l10n.evaluationCompleted,
    ActivityKind.affinityDetected => l10n.adminAffinity,
    ActivityKind.saleRecorded => l10n.newSale,
    ActivityKind.statusChanged => l10n.statusLabel,
  };

  String alertType(AlertType type) => switch (type) {
    AlertType.risk => l10n.alertRisk,
    AlertType.operational => l10n.alertOperational,
    AlertType.commercial => l10n.alertCommercial,
    AlertType.product => l10n.alertProduct,
    AlertType.opportunity => l10n.alertOpportunity,
  };

  String priority(AlertPriority value) => switch (value) {
    AlertPriority.high => l10n.priorityHigh,
    AlertPriority.medium => l10n.priorityMedium,
    AlertPriority.low => l10n.priorityLow,
  };

  String money(double value) =>
      NumberFormat.simpleCurrency(name: 'USD', decimalDigits: 0).format(value);

  String date(DateTime value) =>
      DateFormat.yMMMd(Localizations.localeOf(context).toLanguageTag()).format(value);
}

class AdminPageHeader extends StatelessWidget {
  const AdminPageHeader({
    super.key,
    required this.title,
    required this.subtitle,
    this.eyebrow,
    this.actions = const [],
  });
  final String title, subtitle;
  final String? eyebrow;
  final List<Widget> actions;
  @override
  Widget build(BuildContext context) => TalexPageHeader(
    title: title,
    subtitle: subtitle,
    eyebrow: eyebrow,
    actions: actions,
  );
}

class AdminPanel extends StatelessWidget {
  const AdminPanel({super.key, required this.child, this.onTap});
  final Widget child;
  final VoidCallback? onTap;
  @override
  Widget build(BuildContext context) => TalexPanel(onTap: onTap, child: child);
}

class AdminEmptyState extends StatelessWidget {
  const AdminEmptyState({super.key, required this.message, this.icon});
  final String message;
  final IconData? icon;
  @override
  Widget build(BuildContext context) => TalexPanel(
    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 56),
    child: Column(
      children: [
        TalexIconBadge(icon ?? Icons.inbox_outlined, size: 52),
        const SizedBox(height: 18),
        Text(
          message,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: AppColors.textMuted,
            fontSize: 15,
            height: 1.6,
          ),
        ),
      ],
    ),
  );
}

class AdminErrorState extends StatelessWidget {
  const AdminErrorState({super.key, required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;
  @override
  Widget build(BuildContext context) => TalexPanel(
    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
    child: Column(
      children: [
        const TalexIconBadge(
          Icons.error_outline,
          tone: TalexTone.danger,
          size: 52,
        ),
        const SizedBox(height: 18),
        Text(
          message,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: AppColors.textMuted,
            fontSize: 15,
            height: 1.6,
          ),
        ),
        const SizedBox(height: 20),
        FilledButton.icon(
          onPressed: onRetry,
          icon: const Icon(Icons.refresh, size: 18),
          label: Text(context.l10n.retry),
        ),
      ],
    ),
  );
}

class AdminStatusChip extends StatelessWidget {
  const AdminStatusChip(this.label, {super.key, this.tone = TalexTone.blue});
  final String label;
  final TalexTone tone;
  @override
  Widget build(BuildContext context) => TalexPill(label, tone: tone);
}

class AdminFunnelView extends StatelessWidget {
  const AdminFunnelView({super.key, required this.funnel});
  final AdminFunnel funnel;
  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final steps = [
      (l10n.funnelCompanies, funnel.companies),
      (l10n.funnelProcesses, funnel.processes),
      (l10n.funnelInvited, funnel.invitedPeople),
      (l10n.funnelStarted, funnel.startedEvaluations),
      (l10n.funnelCompleted, funnel.completedEvaluations),
      (l10n.funnelAffinities, funnel.affinitiesDetected),
      (l10n.funnelDecisions, funnel.decisions),
    ];
    final top = steps.first.$2 == 0 ? 1 : steps.first.$2;
    return TalexPanel(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TalexSectionTitle(l10n.talexFunnel),
          const SizedBox(height: 22),
          for (var i = 0; i < steps.length; i++) ...[
            _FunnelStep(
              label: steps[i].$1,
              value: steps[i].$2,
              share: (steps[i].$2 / top).clamp(0.0, 1.0),
              rate: i == 0 || steps[i - 1].$2 == 0
                  ? null
                  : steps[i].$2 / steps[i - 1].$2,
            ),
            if (i < steps.length - 1) const SizedBox(height: 14),
          ],
        ],
      ),
    );
  }
}

class _FunnelStep extends StatelessWidget {
  const _FunnelStep({
    required this.label,
    required this.value,
    required this.share,
    this.rate,
  });
  final String label;
  final int value;
  final double share;
  final double? rate;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(color: AppColors.textMuted, fontSize: 14),
            ),
          ),
          if (rate != null) ...[
            Text(
              '${(rate! * 100).toStringAsFixed(0)}%',
              style: TextStyle(
                color: AppColors.green,
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 12),
          ],
          Text(
            '$value',
            style: TextStyle(
              color: AppColors.text,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
      const SizedBox(height: 8),
      ClipRRect(
        borderRadius: BorderRadius.circular(AppRadii.pill),
        child: LinearProgressIndicator(
          value: share,
          minHeight: 6,
          color: AppColors.company,
          backgroundColor: AppColors.surface2,
        ),
      ),
    ],
  );
}

class AdminBarChart extends StatelessWidget {
  const AdminBarChart({super.key, required this.points});
  final List<(DateTime, int)> points;
  @override
  Widget build(BuildContext context) {
    if (points.isEmpty) {
      return Text(
        context.l10n.noInformationYet,
        style: TextStyle(color: AppColors.textMuted),
      );
    }
    final max = points.map((item) => item.$2).reduce((a, b) => a > b ? a : b);
    return SizedBox(
      height: 160,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          for (final point in points)
            Expanded(
              child: Tooltip(
                message: '${point.$2}',
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 3),
                  child: Container(
                    height: max == 0 ? 4 : (point.$2 / max) * 140 + 8,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [AppColors.company, Color(0x664F8BF0)],
                      ),
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(6),
                        bottom: Radius.circular(2),
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class AdminEntityCard extends StatelessWidget {
  const AdminEntityCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.trailing,
    this.onTap,
    this.action,
  });
  final String title, subtitle, trailing;
  final VoidCallback? onTap;
  final Widget? action;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: TalexPanel(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 20),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: AppColors.text,
                    fontWeight: FontWeight.w600,
                    fontSize: 17,
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  subtitle,
                  style: TextStyle(color: AppColors.textMuted, fontSize: 14.5),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          AdminStatusChip(trailing),
          ?action,
          if (onTap != null) ...[
            const SizedBox(width: 8),
            Icon(Icons.chevron_right, color: AppColors.textDimmer),
          ],
        ],
      ),
    ),
  );
}

class CompanyLogoView extends StatelessWidget {
  const CompanyLogoView({super.key, this.url, this.size = 72});
  final String? url;
  final double size;

  @override
  Widget build(BuildContext context) {
    final src = url?.trim() ?? '';
    // Los logos suelen venir pensados para fondo claro: se muestran sobre un
    // recuadro blanco suave para que no se pierdan en el tema oscuro.
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: src.isEmpty ? AppColors.surface2 : AppColors.logoBackdrop,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(size * 0.22),
      ),
      padding: EdgeInsets.all(src.isEmpty ? 0 : size * 0.1),
      clipBehavior: Clip.antiAlias,
      child: src.isEmpty
          ? Icon(Icons.apartment_outlined, color: AppColors.textDimmer, size: size * 0.4)
          : Image.network(
              src,
              fit: BoxFit.contain,
              errorBuilder: (_, _, _) => Icon(
                Icons.apartment_outlined,
                color: AppColors.slate,
                size: size * 0.4,
              ),
            ),
    );
  }
}

class CompanyIdentityCard extends StatelessWidget {
  const CompanyIdentityCard({super.key, required this.company});
  final Company company;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final website = websiteUri(company.website);
    final location = [
      company.city,
      company.region,
      company.country,
    ].whereType<String>().where((item) => item.trim().isNotEmpty).join(' · ');
    final description = company.description?.trim() ?? '';
    return TalexPanel(
      padding: const EdgeInsets.all(28),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CompanyLogoView(url: company.logoUrl, size: 88),
          const SizedBox(width: 24),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TalexEyebrow(l10n.companyProfile),
                const SizedBox(height: 10),
                Text(
                  company.name,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.6,
                    color: AppColors.text,
                  ),
                ),
                if (location.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        Icons.place_outlined,
                        size: 16,
                        color: AppColors.textDimmer,
                      ),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          location,
                          style: TextStyle(color: AppColors.textMuted),
                        ),
                      ),
                    ],
                  ),
                ],
                if (description.isNotEmpty) ...[
                  const SizedBox(height: 14),
                  Text(
                    description,
                    style: TextStyle(
                      height: 1.7,
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
                if (website != null) ...[
                  const SizedBox(height: 14),
                  TextButton.icon(
                    onPressed: () => openExternalUrl(website.toString()),
                    style: TextButton.styleFrom(padding: EdgeInsets.zero),
                    icon: const Icon(Icons.open_in_new, size: 16),
                    label: Text('${l10n.visitWebsite} · $website'),
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
