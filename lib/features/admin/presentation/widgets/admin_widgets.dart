import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:talex_platform/core/constants/app_colors.dart';
import 'package:talex_platform/core/constants/app_radii.dart';
import 'package:talex_platform/core/utils/open_url.dart';
import 'package:talex_platform/core/utils/website_uri.dart';
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
    this.actions = const [],
  });
  final String title, subtitle;
  final List<Widget> actions;
  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).width < 720;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          title,
          style: TextStyle(
            color: AppColors.ink,
            fontSize: compact ? 32 : 40,
            height: 1.1,
            fontWeight: FontWeight.w700,
            letterSpacing: -1.2,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          subtitle,
          style: const TextStyle(
            color: AppColors.subtitle,
            fontSize: 16,
            height: 1.4,
          ),
        ),
        if (actions.isNotEmpty) ...[
          const SizedBox(height: 16),
          Align(
            alignment: Alignment.centerRight,
            child: Wrap(spacing: 12, runSpacing: 8, children: actions),
          ),
        ],
      ],
    );
  }
}

class AdminPanel extends StatelessWidget {
  const AdminPanel({super.key, required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      color: Colors.white,
      border: Border.all(color: const Color(0xFFC9CBD1)),
      borderRadius: AppRadii.border,
    ),
    child: child,
  );
}

class AdminEmptyState extends StatelessWidget {
  const AdminEmptyState({super.key, required this.message, this.icon});
  final String message;
  final IconData? icon;
  @override
  Widget build(BuildContext context) => AdminPanel(
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 56),
      child: Column(
        children: [
          Icon(
            icon ?? Icons.inbox_outlined,
            size: 44,
            color: AppColors.dashboardAccent,
          ),
          const SizedBox(height: 16),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.subtitle, fontSize: 15),
          ),
        ],
      ),
    ),
  );
}

class AdminErrorState extends StatelessWidget {
  const AdminErrorState({super.key, required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;
  @override
  Widget build(BuildContext context) => AdminPanel(
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
      child: Column(
        children: [
          const Icon(Icons.error_outline, size: 44, color: Color(0xFFB42318)),
          const SizedBox(height: 16),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.subtitle, fontSize: 15),
          ),
          const SizedBox(height: 18),
          FilledButton(
            onPressed: onRetry,
            style: FilledButton.styleFrom(backgroundColor: AppColors.primaryButton),
            child: Text(context.l10n.retry),
          ),
        ],
      ),
    ),
  );
}

class AdminStatusChip extends StatelessWidget {
  const AdminStatusChip(this.label, {super.key});
  final String label;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    decoration: BoxDecoration(
      color: const Color(0xFFF0EFFF),
      borderRadius: AppRadii.border,
    ),
    child: Text(
      label,
      style: const TextStyle(
        color: AppColors.dashboardAccent,
        fontSize: 12,
        fontWeight: FontWeight.w600,
      ),
    ),
  );
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
    return AdminPanel(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.talexFunnel,
              style: const TextStyle(
                color: AppColors.ink,
                fontSize: 22,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 18),
            for (var i = 0; i < steps.length; i++) ...[
              _FunnelStep(
                label: steps[i].$1,
                value: steps[i].$2,
                rate: i == 0 || steps[i - 1].$2 == 0
                    ? null
                    : steps[i].$2 / steps[i - 1].$2,
              ),
              if (i < steps.length - 1)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 6),
                  child: Icon(Icons.south, size: 16, color: AppColors.muted),
                ),
            ],
          ],
        ),
      ),
    );
  }
}

class _FunnelStep extends StatelessWidget {
  const _FunnelStep({required this.label, required this.value, this.rate});
  final String label;
  final int value;
  final double? rate;
  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(
        child: Text(
          label,
          style: const TextStyle(color: AppColors.ink, fontWeight: FontWeight.w600),
        ),
      ),
      Text(
        '$value',
        style: const TextStyle(
          color: AppColors.ink,
          fontSize: 20,
          fontWeight: FontWeight.w700,
        ),
      ),
      if (rate != null) ...[
        const SizedBox(width: 10),
        Text(
          '${(rate! * 100).toStringAsFixed(0)}%',
          style: const TextStyle(color: AppColors.positive, fontWeight: FontWeight.w600),
        ),
      ],
    ],
  );
}

class AdminBarChart extends StatelessWidget {
  const AdminBarChart({super.key, required this.points});
  final List<(DateTime, int)> points;
  @override
  Widget build(BuildContext context) {
    if (points.isEmpty) {
      return Text(context.l10n.noInformationYet, style: const TextStyle(color: AppColors.subtitle));
    }
    final max = points.map((item) => item.$2).reduce((a, b) => a > b ? a : b);
    return SizedBox(
      height: 160,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          for (final point in points)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 3),
                child: Container(
                  height: max == 0 ? 4 : (point.$2 / max) * 140 + 8,
                  decoration: BoxDecoration(
                    color: AppColors.dashboardAccent.withValues(alpha: 0.75),
                    borderRadius: BorderRadius.circular(4),
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
    child: Material(
      color: Colors.white,
      borderRadius: AppRadii.border,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadii.border,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 20),
          decoration: BoxDecoration(
            border: Border.all(color: const Color(0xFFD1D1D6)),
            borderRadius: AppRadii.border,
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: AppColors.ink,
                        fontWeight: FontWeight.w600,
                        fontSize: 18,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(subtitle, style: const TextStyle(color: AppColors.subtitle, fontSize: 15)),
                  ],
                ),
              ),
              AdminStatusChip(trailing),
              ?action,
              if (onTap != null) const Icon(Icons.chevron_right, color: AppColors.accent),
            ],
          ),
        ),
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
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFD1D1D6)),
        borderRadius: AppRadii.border,
      ),
      clipBehavior: Clip.antiAlias,
      child: src.isEmpty
          ? Icon(Icons.apartment_outlined, color: AppColors.muted, size: size * 0.4)
          : Image.network(
              src,
              fit: BoxFit.contain,
              errorBuilder: (_, _, _) =>
                  Icon(Icons.apartment_outlined, color: AppColors.muted, size: size * 0.4),
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
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFD1D1D6)),
        borderRadius: AppRadii.border,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CompanyLogoView(url: company.logoUrl, size: 88),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.companyProfile,
                  style: const TextStyle(color: AppColors.muted, fontSize: 13),
                ),
                const SizedBox(height: 4),
                Text(
                  company.name,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: AppColors.ink,
                  ),
                ),
                if (location.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(location, style: const TextStyle(color: AppColors.subtitle)),
                ],
                if (description.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Text(
                    description,
                    style: const TextStyle(height: 1.45, color: AppColors.ink),
                  ),
                ],
                if (website != null) ...[
                  const SizedBox(height: 12),
                  TextButton.icon(
                    onPressed: () => openExternalUrl(website.toString()),
                    icon: const Icon(Icons.open_in_new, size: 18),
                    label: Text(l10n.visitWebsite),
                  ),
                  Text(
                    website.toString(),
                    style: const TextStyle(color: AppColors.muted, fontSize: 13),
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
