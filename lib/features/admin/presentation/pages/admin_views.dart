import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:talex_platform/core/constants/app_colors.dart';
import 'package:talex_platform/core/constants/app_radii.dart';
import 'package:talex_platform/features/admin/domain/entities/admin_entities.dart';
import 'package:talex_platform/features/admin/presentation/bloc/admin_bloc.dart';
import 'package:talex_platform/features/admin/data/datasources/supabase_assessment_question_data_source.dart';
import 'package:talex_platform/features/admin/presentation/pages/admin_questions_view.dart';
import 'package:talex_platform/features/admin/presentation/widgets/admin_dialogs.dart';
import 'package:talex_platform/features/admin/presentation/widgets/provision_company_dialog.dart';
import 'package:talex_platform/features/admin/presentation/widgets/admin_widgets.dart';
import 'package:talex_platform/features/dashboard/presentation/widgets/dashboard_widgets.dart';
import 'package:talex_platform/features/settings/presentation/widgets/settings_widgets.dart';
import 'package:talex_platform/l10n/l10n.dart';

class AdminSectionView extends StatelessWidget {
  const AdminSectionView({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AdminBloc, AdminState>(
      builder: (context, state) {
        if (state.section == AdminSection.questions ||
            state.section == AdminSection.cultureSurvey) {
          return AdminQuestionsView(
            slug: state.section == AdminSection.cultureSurvey
                ? cultureSurveySlug
                : affinitySurveySlug,
            allowSeed: state.section != AdminSection.cultureSurvey,
            hideUploadWhenFilled: state.section == AdminSection.cultureSurvey,
          );
        }
        if (state.status == AdminViewStatus.initial ||
            (state.status == AdminViewStatus.loading &&
                state.companies.isEmpty &&
                state.metrics == null &&
                state.processes.isEmpty &&
                state.people.isEmpty)) {
          return const Center(child: CircularProgressIndicator());
        }
        if (state.status == AdminViewStatus.failure) {
          return Padding(
            padding: const EdgeInsets.all(32),
            child: AdminErrorState(
              message: state.failure?.message ?? context.l10n.noInformationYet,
              onRetry: () => context.read<AdminBloc>().add(
                AdminSectionSelected(state.section),
              ),
            ),
          );
        }
        return switch (state.section) {
          AdminSection.dashboard => AdminDashboardView(state: state),
          AdminSection.companies =>
            state.showCompanyDetail && state.selectedCompany != null
                ? AdminCompanyDetailView(detail: state.selectedCompany!)
                : AdminCompaniesView(state: state),
          AdminSection.processes =>
            state.selectedProcess != null
                ? AdminProcessDetailView(
                    process: state.selectedProcess!,
                    people: state.people
                        .where(
                          (item) => item.processId == state.selectedProcess!.id,
                        )
                        .toList(),
                  )
                : AdminProcessesView(state: state),
          AdminSection.people =>
            state.selectedPerson != null
                ? AdminPersonDetailView(person: state.selectedPerson!)
                : AdminPeopleView(state: state),
          AdminSection.affinity => AdminAffinityView(state: state),
          AdminSection.commercial => AdminPipelineView(state: state),
          AdminSection.sales => AdminSalesView(state: state),
          AdminSection.analytics => AdminAnalyticsView(state: state),
          AdminSection.alerts => AdminAlertsView(state: state),
          AdminSection.xebec => AdminXebecView(state: state),
          AdminSection.questions => const AdminQuestionsView(),
          AdminSection.cultureSurvey => const AdminQuestionsView(
            slug: cultureSurveySlug,
            allowSeed: false,
            hideUploadWhenFilled: true,
          ),
          AdminSection.settings => AdminSettingsView(state: state),
        };
      },
    );
  }
}

class _Page extends StatelessWidget {
  const _Page({required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).width < 720;
    return SingleChildScrollView(
      padding: EdgeInsets.all(compact ? 18 : 40),
      child: child,
    );
  }
}

class AdminDashboardView extends StatelessWidget {
  const AdminDashboardView({super.key, required this.state});
  final AdminState state;
  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final metrics = state.metrics ?? const AdminMetrics();
    final labels = AdminLabels(context);
    final compact = MediaQuery.sizeOf(context).width < 720;
    final medium = MediaQuery.sizeOf(context).width < 1250;
    return _Page(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AdminPageHeader(
            title: l10n.adminCommandCenter,
            subtitle: l10n.adminCommandSubtitle,
          ),
          const SizedBox(height: 28),
          LayoutBuilder(
            builder: (context, constraints) {
              final columns = compact
                  ? 1
                  : medium
                  ? 2
                  : 4;
              final width =
                  (constraints.maxWidth - (columns - 1) * 24) / columns;
              final cards = [
                DashboardMetricCard(
                  title: l10n.kpiTotalCompanies,
                  value: '${metrics.totalCompanies}',
                  caption: l10n.noData,
                  icon: Icons.apartment_outlined,
                ),
                DashboardMetricCard(
                  title: l10n.kpiActiveCompanies,
                  value: '${metrics.activeCompanies}',
                  caption: l10n.kpiActiveCompanies,
                  icon: Icons.verified_outlined,
                  captionColor: AppColors.positive,
                ),
                DashboardMetricCard(
                  title: l10n.kpiEvaluatedPeople,
                  value: '${metrics.evaluatedPeople}',
                  caption: l10n.kpiEvaluatedPeople,
                  icon: Icons.groups_outlined,
                ),
                DashboardMetricCard(
                  title: l10n.kpiCompletedEvaluations,
                  value: '${metrics.completedEvaluations}',
                  caption: l10n.kpiCompletedEvaluations,
                  icon: Icons.task_alt_outlined,
                  captionColor: AppColors.positive,
                ),
                DashboardMetricCard(
                  title: l10n.kpiAffinities,
                  value: '${metrics.affinitiesDetected}',
                  caption: l10n.adminAffinity,
                  icon: Icons.hub_outlined,
                ),
                DashboardMetricCard(
                  title: l10n.kpiPeriodSales,
                  value: labels.money(metrics.periodSales),
                  caption: l10n.salesPeriod,
                  icon: Icons.payments_outlined,
                ),
                DashboardMetricCard(
                  title: l10n.kpiMrr,
                  value: labels.money(metrics.mrr),
                  caption: l10n.kpiMrr,
                  icon: Icons.trending_up,
                ),
                DashboardMetricCard(
                  title: l10n.kpiAtRisk,
                  value: '${metrics.companiesAtRisk}',
                  caption: l10n.alertRisk,
                  icon: Icons.warning_amber_outlined,
                ),
              ];
              return Wrap(
                spacing: 24,
                runSpacing: 24,
                children: cards
                    .map((card) => SizedBox(width: width, child: card))
                    .toList(),
              );
            },
          ),
          const SizedBox(height: 28),
          if (medium) ...[
            AdminFunnelView(funnel: state.funnel ?? const AdminFunnel()),
            const SizedBox(height: 24),
            _ActivityPanel(state: state),
            const SizedBox(height: 24),
            _AlertsPreview(state: state),
          ] else
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: AdminFunnelView(
                    funnel: state.funnel ?? const AdminFunnel(),
                  ),
                ),
                const SizedBox(width: 24),
                Expanded(
                  flex: 2,
                  child: Column(
                    children: [
                      _ActivityPanel(state: state),
                      const SizedBox(height: 24),
                      _AlertsPreview(state: state),
                    ],
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

class _ActivityPanel extends StatelessWidget {
  const _ActivityPanel({required this.state});
  final AdminState state;
  @override
  Widget build(BuildContext context) {
    final labels = AdminLabels(context);
    return AdminPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              context.l10n.recentActivity,
              style: const TextStyle(
                color: AppColors.ink,
                fontSize: 22,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const Divider(height: 1),
          if (state.activity.isEmpty)
            Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                context.l10n.noActivity,
                style: const TextStyle(color: AppColors.subtitle),
              ),
            )
          else
            ...state.activity
                .take(12)
                .map(
                  (item) => ListTile(
                    leading: Icon(switch (item.kind) {
                      ActivityKind.vacancyCreated => Icons.work_outline,
                      ActivityKind.respondentInvited =>
                        Icons.person_add_alt_1_outlined,
                      ActivityKind.evaluationCompleted =>
                        Icons.task_alt_outlined,
                      ActivityKind.evaluationStarted =>
                        Icons.play_circle_outline,
                      ActivityKind.companyCreated => Icons.apartment_outlined,
                      _ => Icons.timeline_outlined,
                    }, color: AppColors.dashboardAccent),
                    title: Text(item.entityName),
                    subtitle: Text(
                      [
                        labels.activity(item.kind),
                        if (item.context != null && item.context!.isNotEmpty)
                          item.context,
                        labels.date(item.createdAt),
                      ].join(' · '),
                    ),
                    trailing: item.statusLabel == null
                        ? null
                        : AdminStatusChip(item.statusLabel!),
                  ),
                ),
        ],
      ),
    );
  }
}

class _AlertsPreview extends StatelessWidget {
  const _AlertsPreview({required this.state});
  final AdminState state;
  @override
  Widget build(BuildContext context) {
    final labels = AdminLabels(context);
    final alerts = state.alerts.take(4).toList();
    return AdminPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              context.l10n.adminAlerts,
              style: const TextStyle(
                color: AppColors.ink,
                fontSize: 22,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const Divider(height: 1),
          if (alerts.isEmpty)
            Padding(
              padding: const EdgeInsets.all(24),
              child: Text(context.l10n.noAlerts),
            )
          else
            ...alerts.map(
              (item) => ListTile(
                title: Text(item.title),
                subtitle: Text(item.description),
                trailing: AdminStatusChip(labels.priority(item.priority)),
              ),
            ),
        ],
      ),
    );
  }
}

class AdminCompaniesView extends StatelessWidget {
  const AdminCompaniesView({super.key, required this.state});
  final AdminState state;
  @override
  Widget build(BuildContext context) {
    final labels = AdminLabels(context);
    final compact = MediaQuery.sizeOf(context).width < 800;
    return _Page(
      child: Column(
        children: [
          AdminPageHeader(
            title: context.l10n.adminCompanies,
            subtitle: context.l10n.adminCommandSubtitle,
            actions: [
              FilledButton.icon(
                onPressed: () => showProvisionCompanyDialog(context),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primaryButton,
                ),
                icon: const Icon(Icons.add),
                label: Text(context.l10n.newCompany),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Wrap(
            spacing: 8,
            children: [
              _FilterChip(
                label: context.l10n.filterAll,
                selected: state.companyStatus == null && !state.archivedOnly,
                onTap: () => context.read<AdminBloc>().add(
                  AdminCompaniesRequested(query: state.query),
                ),
              ),
              ...CompanyStatus.values.map(
                (status) => _FilterChip(
                  label: labels.companyStatus(status),
                  selected:
                      state.companyStatus == status && !state.archivedOnly,
                  onTap: () => context.read<AdminBloc>().add(
                    AdminCompaniesRequested(query: state.query, status: status),
                  ),
                ),
              ),
              _FilterChip(
                label: context.l10n.filterArchived,
                selected: state.archivedOnly,
                onTap: () => context.read<AdminBloc>().add(
                  AdminCompaniesRequested(
                    query: state.query,
                    archivedOnly: true,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 22),
          if (state.companies.isEmpty)
            AdminEmptyState(
              message: state.archivedOnly
                  ? context.l10n.noArchivedCompanies
                  : context.l10n.noCompanies,
            )
          else if (compact)
            ...state.companies.map(
              (company) => AdminEntityCard(
                title: company.name,
                subtitle:
                    '${context.l10n.lastActivity}: ${labels.date(company.lastActivityAt ?? company.createdAt)}',
                trailing: labels.companyStatus(company.status),
                action: _CompanyOverflowMenu(company),
                onTap: () => context.read<AdminBloc>().add(
                  AdminCompanyOpened(company.id),
                ),
              ),
            )
          else
            AdminPanel(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  showCheckboxColumn: false,
                  columns: [
                    DataColumn(label: Text(context.l10n.adminCompanies)),
                    DataColumn(label: Text(context.l10n.statusLabel)),
                    DataColumn(
                      label: Text(context.l10n.adminProcesses),
                      numeric: true,
                    ),
                    DataColumn(
                      label: Text(context.l10n.funnelInvited),
                      numeric: true,
                    ),
                    DataColumn(
                      label: Text(context.l10n.funnelStarted),
                      numeric: true,
                    ),
                    DataColumn(
                      label: Text(context.l10n.funnelCompleted),
                      numeric: true,
                    ),
                    DataColumn(
                      label: Text(context.l10n.kpiAffinities),
                      numeric: true,
                    ),
                    DataColumn(label: Text(context.l10n.lastActivity)),
                    DataColumn(label: Text(context.l10n.companyActions)),
                  ],
                  rows: [
                    for (final company in state.companies)
                      DataRow(
                        onSelectChanged: (_) => context.read<AdminBloc>().add(
                          AdminCompanyOpened(company.id),
                        ),
                        cells: [
                          DataCell(
                            Row(
                              children: [
                                CompanyLogoView(url: company.logoUrl, size: 32),
                                const SizedBox(width: 10),
                                Flexible(child: Text(company.name)),
                              ],
                            ),
                            onTap: () => context.read<AdminBloc>().add(
                              AdminCompanyOpened(company.id),
                            ),
                          ),
                          DataCell(Text(labels.companyStatus(company.status))),
                          DataCell(Text('${company.activeProcesses}')),
                          DataCell(Text('${company.invitedPeople}')),
                          DataCell(Text('${company.startedEvaluations}')),
                          DataCell(Text('${company.completedEvaluations}')),
                          DataCell(Text('${company.affinitiesDetected}')),
                          DataCell(
                            Text(
                              labels.date(
                                company.lastActivityAt ?? company.createdAt,
                              ),
                            ),
                          ),
                          DataCell(_CompanyOverflowMenu(company)),
                        ],
                      ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class AdminCompanyDetailView extends StatelessWidget {
  const AdminCompanyDetailView({super.key, required this.detail});
  final CompanyDetail detail;
  @override
  Widget build(BuildContext context) {
    final company = detail.company;
    final labels = AdminLabels(context);
    return _Page(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextButton.icon(
            onPressed: () =>
                context.read<AdminBloc>().add(const AdminCompanyClosed()),
            icon: const Icon(Icons.arrow_back),
            label: Text(context.l10n.backToCompanies),
          ),
          const SizedBox(height: 8),
          AdminPageHeader(
            title: company.name,
            subtitle:
                '${labels.companyStatus(company.status)} · ${context.l10n.joinedAt} ${labels.date(company.createdAt)}',
            actions: [
              FilledButton.icon(
                onPressed: () => showAdminEditCompany(context, company),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primaryButton,
                ),
                icon: const Icon(Icons.edit_outlined),
                label: Text(context.l10n.editCompany),
              ),
              _CompanyOverflowMenu(company),
            ],
          ),
          const SizedBox(height: 24),
          CompanyIdentityCard(company: company),
          const SizedBox(height: 24),
          Wrap(
            spacing: 16,
            runSpacing: 16,
            children: [
              _Stat(context.l10n.adminProcesses, '${company.activeProcesses}'),
              _Stat(context.l10n.funnelInvited, '${company.invitedPeople}'),
              _Stat(
                context.l10n.funnelCompleted,
                '${company.completedEvaluations}',
              ),
              _Stat(
                context.l10n.kpiAffinities,
                '${company.affinitiesDetected}',
              ),
            ],
          ),
          const SizedBox(height: 24),
          SettingsSection(
            title: context.l10n.companyCommercial,
            description: context.l10n.adminCommercial,
            icon: Icons.handshake_outlined,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${context.l10n.plan}: ${company.plan ?? context.l10n.noData}',
                ),
                const SizedBox(height: 8),
                Text(
                  '${context.l10n.estimatedValue}: ${company.contractValue == null ? context.l10n.noData : labels.money(company.contractValue!)}',
                ),
                const SizedBox(height: 8),
                Text(
                  '${context.l10n.kpiMrr}: ${company.mrr == null ? context.l10n.noData : labels.money(company.mrr!)}',
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Text(
            context.l10n.adminProcesses,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w600,
              color: AppColors.ink,
            ),
          ),
          const SizedBox(height: 12),
          if (detail.processes.isEmpty)
            AdminEmptyState(message: context.l10n.noProcesses)
          else
            ...detail.processes.map(
              (item) => AdminEntityCard(
                title: item.name,
                subtitle:
                    '${labels.processStatus(item.status)} · ${labels.date(item.createdAt)}',
                trailing: '${item.completedEvaluations}/${item.invitedPeople}',
                onTap: () {
                  final bloc = context.read<AdminBloc>();
                  bloc
                    ..add(const AdminSectionSelected(AdminSection.processes))
                    ..add(AdminProcessOpened(item));
                },
              ),
            ),
          const SizedBox(height: 24),
          Text(
            context.l10n.adminPeople,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w600,
              color: AppColors.ink,
            ),
          ),
          const SizedBox(height: 12),
          if (detail.people.isEmpty)
            AdminEmptyState(message: context.l10n.noPeople)
          else
            ...detail.people.map(
              (item) => AdminEntityCard(
                title: item.displayName,
                subtitle: item.processName,
                trailing: labels.evaluation(item.status),
                onTap: () {
                  final bloc = context.read<AdminBloc>();
                  bloc
                    ..add(const AdminSectionSelected(AdminSection.people))
                    ..add(AdminPersonOpened(item));
                },
              ),
            ),
          const SizedBox(height: 24),
          Text(
            context.l10n.recentActivity,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w600,
              color: AppColors.ink,
            ),
          ),
          const SizedBox(height: 12),
          if (detail.activity.isEmpty)
            AdminEmptyState(message: context.l10n.noActivity)
          else
            ...detail.activity.map(
              (item) => AdminEntityCard(
                title: item.entityName,
                subtitle: labels.date(item.createdAt),
                trailing: labels.activity(item.kind),
              ),
            ),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat(this.label, this.value);
  final String label, value;
  @override
  Widget build(BuildContext context) => SizedBox(
    width: 240,
    child: DashboardMetricCard(
      title: label,
      value: value,
      caption: '',
      icon: Icons.insights_outlined,
    ),
  );
}

class AdminProcessesView extends StatelessWidget {
  const AdminProcessesView({super.key, required this.state});
  final AdminState state;
  @override
  Widget build(BuildContext context) {
    final labels = AdminLabels(context);
    return _Page(
      child: Column(
        children: [
          AdminPageHeader(
            title: context.l10n.adminProcesses,
            subtitle: context.l10n.adminCommandSubtitle,
            actions: [
              FilledButton.icon(
                onPressed: () async {
                  final companies = state.companies.isEmpty
                      ? await _ensureCompanies(context)
                      : state.companies;
                  if (!context.mounted) return;
                  await showAdminCreateProcess(context, companies);
                },
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primaryButton,
                ),
                icon: const Icon(Icons.add),
                label: Text(context.l10n.newProcess),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            children: [
              _FilterChip(
                label: context.l10n.filterAll,
                selected: state.processStatus == null,
                onTap: () => context.read<AdminBloc>().add(
                  const AdminProcessesRequested(),
                ),
              ),
              ...ProcessStatus.values.map(
                (status) => _FilterChip(
                  label: labels.processStatus(status),
                  selected: state.processStatus == status,
                  onTap: () => context.read<AdminBloc>().add(
                    AdminProcessesRequested(status: status),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          if (state.processes.isEmpty)
            AdminEmptyState(message: context.l10n.noProcesses)
          else
            ...state.processes.map(
              (item) => AdminEntityCard(
                title: item.name,
                subtitle:
                    '${item.companyName} · ${labels.date(item.createdAt)}',
                trailing: labels.processStatus(item.status),
                onTap: () =>
                    context.read<AdminBloc>().add(AdminProcessOpened(item)),
              ),
            ),
        ],
      ),
    );
  }
}

class AdminPeopleView extends StatelessWidget {
  const AdminPeopleView({super.key, required this.state});
  final AdminState state;
  @override
  Widget build(BuildContext context) {
    final labels = AdminLabels(context);
    return _Page(
      child: Column(
        children: [
          AdminPageHeader(
            title: context.l10n.adminPeople,
            subtitle: context.l10n.noPeople,
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            children: EvaluationStatus.values
                .map(
                  (status) => _FilterChip(
                    label: labels.evaluation(status),
                    selected: state.evaluationStatus == status,
                    onTap: () => context.read<AdminBloc>().add(
                      AdminPeopleRequested(status: status),
                    ),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 20),
          if (state.people.isEmpty)
            AdminEmptyState(message: context.l10n.noPeople)
          else
            ...state.people.map(
              (item) => AdminEntityCard(
                title: item.displayName,
                subtitle: '${item.companyName} · ${item.processName}',
                trailing: labels.evaluation(item.status),
                onTap: () =>
                    context.read<AdminBloc>().add(AdminPersonOpened(item)),
              ),
            ),
        ],
      ),
    );
  }
}

class AdminAffinityView extends StatelessWidget {
  const AdminAffinityView({super.key, required this.state});
  final AdminState state;
  @override
  Widget build(BuildContext context) {
    final summary = state.affinity ?? const AffinitySummary();
    return _Page(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AdminPageHeader(
            title: context.l10n.adminAffinity,
            subtitle: context.l10n.adminCommandSubtitle,
          ),
          const SizedBox(height: 24),
          Wrap(
            spacing: 16,
            runSpacing: 16,
            children: [
              _Stat(context.l10n.affinityHigh, '${summary.high}'),
              _Stat(context.l10n.affinityMedium, '${summary.medium}'),
              _Stat(context.l10n.affinityLow, '${summary.low}'),
              _Stat(context.l10n.affinityUnknown, '${summary.unknown}'),
            ],
          ),
          const SizedBox(height: 24),
          if (state.people.where((item) => item.affinityScore != null).isEmpty)
            AdminEmptyState(message: context.l10n.noInformationYet)
          else
            ...state.people
                .where((item) => item.affinityScore != null)
                .map(
                  (item) => AdminEntityCard(
                    title: item.displayName,
                    subtitle: '${item.companyName} · ${item.processName}',
                    trailing: item.affinityScore!.toStringAsFixed(0),
                  ),
                ),
        ],
      ),
    );
  }
}

class AdminPipelineView extends StatelessWidget {
  const AdminPipelineView({super.key, required this.state});
  final AdminState state;
  @override
  Widget build(BuildContext context) {
    final labels = AdminLabels(context);
    return _Page(
      child: Column(
        children: [
          AdminPageHeader(
            title: context.l10n.adminCommercial,
            subtitle: context.l10n.adminCommandSubtitle,
            actions: [
              FilledButton.icon(
                onPressed: () async {
                  final companies = state.companies.isEmpty
                      ? await _ensureCompanies(context)
                      : state.companies;
                  if (!context.mounted) return;
                  await showAdminCreateDeal(context, companies);
                },
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primaryButton,
                ),
                icon: const Icon(Icons.add),
                label: Text(context.l10n.newDeal),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            children: DealStage.values
                .map(
                  (stage) => _FilterChip(
                    label: labels.deal(stage),
                    selected: state.dealStage == stage,
                    onTap: () => context.read<AdminBloc>().add(
                      AdminDealsRequested(stage: stage),
                    ),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 20),
          if (state.deals.isEmpty)
            AdminEmptyState(message: context.l10n.noDeals)
          else
            ...state.deals.map(
              (item) => AdminEntityCard(
                title: item.companyName,
                subtitle:
                    '${item.ownerName ?? context.l10n.noData} · ${item.nextAction ?? context.l10n.noData}',
                trailing:
                    '${labels.deal(item.stage)} · ${item.estimatedValue == null ? context.l10n.noData : labels.money(item.estimatedValue!)}',
              ),
            ),
        ],
      ),
    );
  }
}

class AdminSalesView extends StatelessWidget {
  const AdminSalesView({super.key, required this.state});
  final AdminState state;
  @override
  Widget build(BuildContext context) {
    final labels = AdminLabels(context);
    final summary = state.salesSummary ?? const SalesSummary();
    return _Page(
      child: Column(
        children: [
          AdminPageHeader(
            title: context.l10n.adminSales,
            subtitle: context.l10n.adminCommandSubtitle,
            actions: [
              FilledButton.icon(
                onPressed: () async {
                  final companies = state.companies.isEmpty
                      ? await _ensureCompanies(context)
                      : state.companies;
                  if (!context.mounted) return;
                  await showAdminCreateSale(context, companies);
                },
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primaryButton,
                ),
                icon: const Icon(Icons.add),
                label: Text(context.l10n.newSale),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _PeriodChips(state: state),
          const SizedBox(height: 20),
          Wrap(
            spacing: 16,
            runSpacing: 16,
            children: [
              _Stat(
                context.l10n.salesPeriod,
                labels.money(summary.periodTotal),
              ),
              _Stat(
                context.l10n.salesCumulative,
                labels.money(summary.cumulativeTotal),
              ),
              _Stat(context.l10n.newCustomers, '${summary.newCustomers}'),
              _Stat(
                context.l10n.averageTicket,
                labels.money(summary.averageTicket),
              ),
              _Stat(context.l10n.kpiMrr, labels.money(summary.mrr)),
              _Stat(
                context.l10n.growth,
                '${(summary.growth * 100).toStringAsFixed(0)}%',
              ),
            ],
          ),
          const SizedBox(height: 24),
          if (state.sales.isEmpty)
            AdminEmptyState(message: context.l10n.noSales)
          else
            ...state.sales.map(
              (item) => AdminEntityCard(
                title: item.companyName,
                subtitle: item.product ?? labels.date(item.soldAt),
                trailing: labels.money(item.amount),
              ),
            ),
        ],
      ),
    );
  }
}

class AdminAnalyticsView extends StatelessWidget {
  const AdminAnalyticsView({super.key, required this.state});
  final AdminState state;
  @override
  Widget build(BuildContext context) {
    final analytics = state.analytics ?? const AnalyticsSnapshot();
    return _Page(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AdminPageHeader(
            title: context.l10n.adminAnalytics,
            subtitle: context.l10n.adminCommandSubtitle,
          ),
          const SizedBox(height: 16),
          _PeriodChips(state: state, analytics: true),
          const SizedBox(height: 20),
          Wrap(
            spacing: 16,
            runSpacing: 16,
            children: [
              _Stat(
                context.l10n.kpiTotalCompanies,
                '${analytics.newCompanies}',
              ),
              _Stat(
                context.l10n.kpiActiveCompanies,
                '${analytics.activeCompanies}',
              ),
              _Stat(
                context.l10n.kpiEvaluatedPeople,
                '${analytics.evaluatedPeople}',
              ),
              _Stat(
                context.l10n.funnelStarted,
                '${analytics.startedEvaluations}',
              ),
              _Stat(
                context.l10n.funnelCompleted,
                '${analytics.completedEvaluations}',
              ),
              _Stat(
                context.l10n.completionRate,
                '${(analytics.completionRate * 100).toStringAsFixed(0)}%',
              ),
              _Stat(
                context.l10n.kpiAffinities,
                '${analytics.affinitiesDetected}',
              ),
              _Stat(
                context.l10n.funnelProcesses,
                '${analytics.processesCreated}',
              ),
            ],
          ),
          const SizedBox(height: 24),
          AdminPanel(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    context.l10n.activityByDay,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: AppColors.ink,
                    ),
                  ),
                  const SizedBox(height: 16),
                  AdminBarChart(points: analytics.daily),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class AdminAlertsView extends StatelessWidget {
  const AdminAlertsView({super.key, required this.state});
  final AdminState state;
  @override
  Widget build(BuildContext context) {
    final labels = AdminLabels(context);
    return _Page(
      child: Column(
        children: [
          AdminPageHeader(
            title: context.l10n.adminAlerts,
            subtitle: context.l10n.adminCommandSubtitle,
          ),
          const SizedBox(height: 20),
          if (state.alerts.isEmpty)
            AdminEmptyState(message: context.l10n.noAlerts)
          else
            ...state.alerts.map(
              (item) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: AdminPanel(
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(20),
                    title: Text(
                      '${item.title} · ${labels.alertType(item.type)}',
                    ),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        '${item.description}\n${context.l10n.suggestedAction}: ${item.suggestedAction}',
                      ),
                    ),
                    trailing: AdminStatusChip(labels.priority(item.priority)),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class AdminXebecView extends StatefulWidget {
  const AdminXebecView({super.key, required this.state});
  final AdminState state;
  @override
  State<AdminXebecView> createState() => _AdminXebecViewState();
}

class _AdminXebecViewState extends State<AdminXebecView> {
  final _controller = TextEditingController();
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _Page(
      child: Column(
        children: [
          AdminPageHeader(
            title: context.l10n.adminXebec,
            subtitle: context.l10n.xebecSubtitle,
          ),
          const SizedBox(height: 20),
          AdminPanel(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  if (widget.state.xebecMessages.isEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 24),
                      child: Text(
                        context.l10n.xebecEmpty,
                        style: const TextStyle(color: AppColors.subtitle),
                      ),
                    )
                  else
                    ...widget.state.xebecMessages.map(
                      (item) => Align(
                        alignment: item.fromXebec
                            ? Alignment.centerLeft
                            : Alignment.centerRight,
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(14),
                          constraints: const BoxConstraints(maxWidth: 640),
                          decoration: BoxDecoration(
                            color: item.fromXebec
                                ? const Color(0xFFF0EFFF)
                                : const Color(0xFFF4F2F3),
                            borderRadius: AppRadii.border,
                          ),
                          child: Text(item.text),
                        ),
                      ),
                    ),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _controller,
                          decoration: InputDecoration(
                            hintText: context.l10n.xebecPlaceholder,
                            border: const OutlineInputBorder(),
                          ),
                          onSubmitted: (value) {
                            if (value.trim().isEmpty) return;
                            context.read<AdminBloc>().add(
                              AdminXebecAsked(value.trim()),
                            );
                            _controller.clear();
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      FilledButton(
                        onPressed: () {
                          final value = _controller.text.trim();
                          if (value.isEmpty) return;
                          context.read<AdminBloc>().add(AdminXebecAsked(value));
                          _controller.clear();
                        },
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.primaryButton,
                        ),
                        child: Text(context.l10n.askXebec),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class AdminSettingsView extends StatelessWidget {
  const AdminSettingsView({super.key, required this.state});
  final AdminState state;
  @override
  Widget build(BuildContext context) {
    return _Page(
      child: Column(
        children: [
          AdminPageHeader(
            title: context.l10n.adminSettings,
            subtitle: context.l10n.adminSettingsSubtitle,
          ),
          const SizedBox(height: 24),
          SettingsSection(
            title: context.l10n.roleLabel,
            description: context.l10n.superAdminHelp,
            icon: Icons.shield_outlined,
            child: const SizedBox.shrink(),
          ),
          const SizedBox(height: 24),
          if (state.users.isEmpty)
            AdminEmptyState(message: context.l10n.noInformationYet)
          else
            ...state.users.map(
              (user) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: AdminPanel(
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(18),
                    title: Text(
                      user.displayName?.isNotEmpty == true
                          ? user.displayName!
                          : user.email,
                    ),
                    subtitle: Text(
                      '${user.email} · ${user.companyName ?? context.l10n.noData}',
                    ),
                    trailing: _RoleSelector(
                      role: user.role,
                      onChanged: (role) => context.read<AdminBloc>().add(
                        AdminUserRoleUpdated(userId: user.id, role: role),
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

class _RoleSelector extends StatelessWidget {
  const _RoleSelector({required this.role, required this.onChanged});
  final String role;
  final ValueChanged<String> onChanged;

  static const _superadmin = 'superadmin';
  static const _user = 'user';

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final elevated = role == _superadmin;
    final options = [
      (
        _superadmin,
        Icons.shield_outlined,
        l10n.adminRoleSuperadmin,
        l10n.adminRoleSuperadminHelp,
      ),
      (_user, Icons.person_outline, l10n.adminRoleUser, l10n.adminRoleUserHelp),
    ];
    final current = options.where((item) => item.$1 == role).firstOrNull;
    return PopupMenuButton<String>(
      tooltip: l10n.adminRoleChange,
      position: PopupMenuPosition.under,
      offset: const Offset(0, 6),
      elevation: 10,
      shadowColor: const Color(0x33071326),
      color: Colors.white,
      surfaceTintColor: Colors.transparent,
      padding: EdgeInsets.zero,
      menuPadding: const EdgeInsets.all(6),
      constraints: const BoxConstraints(minWidth: 300, maxWidth: 320),
      shape: RoundedRectangleBorder(
        borderRadius: AppRadii.border,
        side: const BorderSide(color: AppColors.softBorder),
      ),
      onSelected: (value) {
        if (value != role) onChanged(value);
      },
      itemBuilder: (context) => [
        for (final (value, icon, title, help) in options)
          PopupMenuItem(
            value: value,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            child: Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: value == role
                        ? AppColors.fieldFill
                        : const Color(0xFFF4F4F6),
                    borderRadius: BorderRadius.circular(9),
                  ),
                  child: Icon(
                    icon,
                    size: 18,
                    color: value == role
                        ? AppColors.dashboardAccent
                        : AppColors.subtitle,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          color: AppColors.ink,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        help,
                        style: const TextStyle(
                          color: AppColors.muted,
                          fontSize: 12.5,
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  Icons.check,
                  size: 18,
                  color: value == role
                      ? AppColors.dashboardAccent
                      : Colors.transparent,
                ),
              ],
            ),
          ),
      ],
      child: Container(
        height: 36,
        padding: const EdgeInsets.only(left: 10, right: 6),
        decoration: BoxDecoration(
          color: elevated ? AppColors.fieldFill : Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: elevated ? AppColors.fieldBorder : AppColors.softBorder,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              current?.$2 ?? Icons.badge_outlined,
              size: 16,
              color: elevated ? AppColors.dashboardAccent : AppColors.subtitle,
            ),
            const SizedBox(width: 7),
            Text(
              current?.$3 ?? role,
              style: TextStyle(
                color: elevated ? AppColors.dashboardAccent : AppColors.ink,
                fontSize: 13.5,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 4),
            const Icon(
              Icons.keyboard_arrow_down_rounded,
              size: 18,
              color: AppColors.muted,
            ),
          ],
        ),
      ),
    );
  }
}

class _PeriodChips extends StatelessWidget {
  const _PeriodChips({required this.state, this.analytics = false});
  final AdminState state;
  final bool analytics;
  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final items = [
      (AnalyticsPeriod.d7, l10n.period7),
      (AnalyticsPeriod.d30, l10n.period30),
      (AnalyticsPeriod.d90, l10n.period90),
      (AnalyticsPeriod.m12, l10n.period12m),
    ];
    return Wrap(
      spacing: 8,
      children: items
          .map(
            (item) => _FilterChip(
              label: item.$2,
              selected: state.period == item.$1,
              onTap: () => context.read<AdminBloc>().add(
                analytics
                    ? AdminAnalyticsRequested(period: item.$1)
                    : AdminSalesRequested(period: item.$1),
              ),
            ),
          )
          .toList(),
    );
  }
}

class _CompanyOverflowMenu extends StatelessWidget {
  const _CompanyOverflowMenu(this.company);
  final Company company;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return PopupMenuButton<CompanyLifecycleAction>(
      tooltip: l10n.companyActions,
      onSelected: (action) =>
          showCompanyLifecycleDialog(context, company: company, action: action),
      itemBuilder: (context) => [
        if (!company.archived && !company.isDisabled)
          PopupMenuItem(
            value: CompanyLifecycleAction.disable,
            child: Text(l10n.disableCompany),
          ),
        if (!company.archived && company.isDisabled)
          PopupMenuItem(
            value: CompanyLifecycleAction.enable,
            child: Text(l10n.enableCompany),
          ),
        if (!company.archived)
          PopupMenuItem(
            value: CompanyLifecycleAction.archive,
            child: Text(l10n.archiveCompany),
          ),
        if (company.archived)
          PopupMenuItem(
            value: CompanyLifecycleAction.restore,
            child: Text(l10n.restoreCompany),
          ),
      ],
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });
  final String label;
  final bool selected;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => ChoiceChip(
    label: Text(label),
    selected: selected,
    onSelected: (_) => onTap(),
    selectedColor: const Color(0xFFEAE8EB),
  );
}

class AdminPersonDetailView extends StatefulWidget {
  const AdminPersonDetailView({super.key, required this.person});
  final PersonEvaluation person;
  @override
  State<AdminPersonDetailView> createState() => _AdminPersonDetailViewState();
}

class _AdminPersonDetailViewState extends State<AdminPersonDetailView> {
  late final TextEditingController _name;
  late EvaluationStatus _status;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.person.displayName);
    _status = widget.person.status;
  }

  @override
  void didUpdateWidget(AdminPersonDetailView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.person != widget.person) {
      _name.text = widget.person.displayName;
      _status = widget.person.status;
    }
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final labels = AdminLabels(context);
    final person = widget.person;
    return _Page(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextButton.icon(
            onPressed: () =>
                context.read<AdminBloc>().add(const AdminPersonClosed()),
            icon: const Icon(Icons.arrow_back),
            label: Text(context.l10n.backToPeople),
          ),
          const SizedBox(height: 8),
          AdminPageHeader(
            title: person.displayName,
            subtitle: '${person.companyName} · ${person.processName}',
          ),
          const SizedBox(height: 20),
          Wrap(
            spacing: 16,
            runSpacing: 16,
            children: [
              _Stat(context.l10n.statusLabel, labels.evaluation(person.status)),
              _Stat(
                context.l10n.emailAddress,
                person.email.isEmpty ? context.l10n.noData : person.email,
              ),
              _Stat(
                context.l10n.adminAffinity,
                person.affinityScore?.toStringAsFixed(0) ?? context.l10n.noData,
              ),
            ],
          ),
          const SizedBox(height: 24),
          TextField(
            controller: _name,
            decoration: InputDecoration(labelText: context.l10n.fullName),
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<EvaluationStatus>(
            key: ValueKey(_status),
            initialValue: _status,
            decoration: InputDecoration(labelText: context.l10n.statusLabel),
            items: [
              for (final status in EvaluationStatus.values)
                DropdownMenuItem(
                  value: status,
                  child: Text(labels.evaluation(status)),
                ),
            ],
            onChanged: (value) {
              if (value != null) setState(() => _status = value);
            },
          ),
          const SizedBox(height: 20),
          FilledButton(
            onPressed: () => context.read<AdminBloc>().add(
              AdminPersonUpdated(
                id: person.id,
                displayName: _name.text.trim(),
                status: _status,
              ),
            ),
            child: Text(context.l10n.saveChanges),
          ),
        ],
      ),
    );
  }
}

class AdminProcessDetailView extends StatelessWidget {
  const AdminProcessDetailView({
    super.key,
    required this.process,
    required this.people,
  });
  final TalentProcess process;
  final List<PersonEvaluation> people;

  @override
  Widget build(BuildContext context) {
    final labels = AdminLabels(context);
    final presented = people
        .where((item) => item.status == EvaluationStatus.completed)
        .length;
    final pending = people
        .where((item) => item.status == EvaluationStatus.invited)
        .length;
    return _Page(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextButton.icon(
            onPressed: () =>
                context.read<AdminBloc>().add(const AdminProcessClosed()),
            icon: const Icon(Icons.arrow_back),
            label: Text(context.l10n.backToProcesses),
          ),
          const SizedBox(height: 8),
          AdminPageHeader(title: process.name, subtitle: process.companyName),
          const SizedBox(height: 20),
          Wrap(
            spacing: 16,
            runSpacing: 16,
            children: [
              _Stat(context.l10n.adminCompanies, process.companyName),
              _Stat(context.l10n.funnelInvited, '${people.length}'),
              _Stat(context.l10n.presentedPeople, '$presented'),
              _Stat(context.l10n.pendingPeople, '$pending'),
              _Stat(
                context.l10n.statusLabel,
                labels.processStatus(process.status),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Text(
            context.l10n.adminPeople,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w600,
              color: AppColors.ink,
            ),
          ),
          const SizedBox(height: 12),
          if (people.isEmpty)
            AdminEmptyState(message: context.l10n.noPeople)
          else
            ...people.map(
              (item) => AdminEntityCard(
                title: item.displayName,
                subtitle: labels.evaluation(item.status),
                trailing:
                    item.affinityScore?.toStringAsFixed(0) ??
                    context.l10n.noData,
                onTap: () {
                  final bloc = context.read<AdminBloc>();
                  bloc
                    ..add(const AdminSectionSelected(AdminSection.people))
                    ..add(AdminPersonOpened(item));
                },
              ),
            ),
        ],
      ),
    );
  }
}

Future<List<Company>> _ensureCompanies(BuildContext context) async {
  final bloc = context.read<AdminBloc>();
  if (bloc.state.companies.isNotEmpty) return bloc.state.companies;
  bloc.add(const AdminCompaniesRequested());
  await bloc.stream.firstWhere(
    (state) =>
        state.status == AdminViewStatus.success ||
        state.status == AdminViewStatus.failure,
  );
  return bloc.state.companies;
}
