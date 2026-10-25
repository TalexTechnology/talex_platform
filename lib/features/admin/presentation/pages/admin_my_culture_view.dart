import 'package:flutter/material.dart';
import 'package:talex_platform/core/constants/app_colors.dart';
import 'package:talex_platform/features/admin/data/datasources/culture_report_data_source.dart';
import 'package:talex_platform/features/admin/domain/entities/culture_organization_report.dart';
import 'package:talex_platform/features/admin/presentation/widgets/admin_widgets.dart';
import 'package:talex_platform/l10n/l10n.dart';

// Pestaña "Mi cultura": leads de la landing /micultura agrupados por empresa.
class AdminMyCultureView extends StatefulWidget {
  const AdminMyCultureView({super.key, this.source});

  final CultureReportDataSource? source;

  @override
  State<AdminMyCultureView> createState() => _AdminMyCultureViewState();
}

class _AdminMyCultureViewState extends State<AdminMyCultureView> {
  late final CultureReportDataSource _source =
      widget.source ?? CultureReportDataSource();
  late Future<CultureOrganizationReport> _report = _source.load();
  var _query = '';

  void _reload() => setState(() => _report = _source.load());

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final compact = MediaQuery.sizeOf(context).width < 720;
    return FutureBuilder<CultureOrganizationReport>(
      future: _report,
      builder: (context, snapshot) {
        final loading = snapshot.connectionState != ConnectionState.done;
        final report = snapshot.data;
        final Widget body;
        if (loading) {
          body = const Padding(
            padding: EdgeInsets.all(56),
            child: Center(child: CircularProgressIndicator()),
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
                  fillColor: Colors.white,
                  border: const OutlineInputBorder(),
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
                title: l10n.adminSurveysMyCulture,
                subtitle: l10n.adminMyCultureSubtitle,
                actions: [
                  OutlinedButton.icon(
                    onPressed: loading ? null : _reload,
                    icon: const Icon(Icons.refresh),
                    label: Text(l10n.adminMyCultureRefresh),
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
              style: const TextStyle(
                color: AppColors.ink,
                fontSize: 28,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(color: AppColors.subtitle, fontSize: 14),
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
    return AdminPanel(
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
          childrenPadding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          expandedCrossAxisAlignment: CrossAxisAlignment.start,
          title: Text(
            group.unassigned
                ? l10n.adminMyCultureUnassigned
                : (group.name ?? ''),
            style: const TextStyle(
              color: AppColors.ink,
              fontWeight: FontWeight.w600,
              fontSize: 18,
            ),
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(
              details.join(' · '),
              style: const TextStyle(color: AppColors.subtitle, fontSize: 14),
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
                    style: const TextStyle(
                      color: AppColors.subtitle,
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
                const Divider(height: 20, color: AppColors.divider),
              _LeadRow(item: item),
            ],
          ],
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
                style: const TextStyle(
                  color: AppColors.ink,
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
                style: const TextStyle(
                  color: AppColors.subtitle,
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
      style: const TextStyle(
        color: AppColors.muted,
        fontSize: 12.5,
        fontWeight: FontWeight.w600,
      ),
    ),
  );
}
