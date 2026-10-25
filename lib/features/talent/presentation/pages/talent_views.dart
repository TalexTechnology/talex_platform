import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:talex_platform/core/auth/user_role.dart';
import 'package:talex_platform/core/constants/app_colors.dart';
import 'package:talex_platform/core/widgets/affinity_badge.dart';
import 'package:talex_platform/core/widgets/content_width.dart';
import 'package:talex_platform/features/admin/presentation/widgets/admin_widgets.dart';
import 'package:talex_platform/features/dashboard/presentation/widgets/dashboard_widgets.dart';
import 'package:talex_platform/features/talent/domain/entities/talent_entities.dart';
import 'package:talex_platform/features/talent/domain/services/company_insights.dart';
import 'package:talex_platform/features/talent/presentation/bloc/talent_bloc.dart';
import 'package:talex_platform/core/widgets/app_select_field.dart';
import 'package:talex_platform/core/widgets/location_picker.dart';
import 'package:talex_platform/core/widgets/logo_field.dart';
import 'package:talex_platform/features/talent/domain/services/dna_catalog.dart';
import 'package:talex_platform/features/talent/presentation/company_options.dart';
import 'package:talex_platform/features/talent/presentation/widgets/talent_dialogs.dart';
import 'package:talex_platform/l10n/l10n.dart';

String affinityWord(BuildContext context, AffinityLevel level) {
  final l10n = context.l10n;
  return switch (level) {
    AffinityLevel.high => l10n.priorityHigh,
    AffinityLevel.medium => l10n.priorityMedium,
    AffinityLevel.low => l10n.priorityLow,
    AffinityLevel.unknown => l10n.affinityUnknown,
  };
}

String processStatusLabel(BuildContext context, CandidateProcessStatus status) {
  final l10n = context.l10n;
  return switch (status) {
    CandidateProcessStatus.pending => l10n.statusPending,
    CandidateProcessStatus.inProgress => l10n.statusInProgress,
    CandidateProcessStatus.completed => l10n.evaluationCompleted,
    CandidateProcessStatus.inReview => l10n.statusInReview,
    CandidateProcessStatus.shortlisted => l10n.statusShortlisted,
    CandidateProcessStatus.interview => l10n.statusInterview,
    CandidateProcessStatus.finalist => l10n.statusFinalist,
    CandidateProcessStatus.hired => l10n.statusHired,
    CandidateProcessStatus.rejected => l10n.statusRejected,
  };
}

class TalentDashboardView extends StatelessWidget {
  const TalentDashboardView({super.key, required this.state});
  final TalentState state;
  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final snap = state.snapshot;
    if (state.status == TalentViewStatus.loading) {
      return const Center(child: CircularProgressIndicator());
    }
    final insights = CompanyInsights(snap);
    void openCandidates() => context.read<TalentBloc>().add(
      const TalentSectionSelected(TalentSection.candidates),
    );
    void openReports() => context.read<TalentBloc>().add(
      const TalentSectionSelected(TalentSection.reports),
    );
    final alerts = <PendingActionItem>[
      if (insights.readyToReview.isNotEmpty)
        PendingActionItem(
          l10n.dashboardReadyToReview(insights.readyToReview.length),
          insights.readyToReview
              .take(3)
              .map((item) => item.displayName?.trim().isNotEmpty == true
                  ? item.displayName!
                  : item.email)
              .join(' · '),
          Icons.fact_check_outlined,
          onTap: openReports,
        ),
      if (insights.pendingToStart > 0)
        PendingActionItem(
          l10n.dashboardPendingToStart(insights.pendingToStart),
          l10n.candidatesSubtitle,
          Icons.hourglass_empty_outlined,
          onTap: openCandidates,
        ),
      if (insights.stalled.isNotEmpty)
        PendingActionItem(
          l10n.dashboardStalledAssessments(insights.stalled.length),
          insights.stalled
              .take(3)
              .map((item) => item.vacancyName)
              .join(' · '),
          Icons.schedule_outlined,
          onTap: openCandidates,
        ),
    ];
    return SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: ContentWidth(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AdminPageHeader(title: l10n.dashboard, subtitle: l10n.overviewSubtitle),
            const SizedBox(height: 24),
            Wrap(
              spacing: 16,
              runSpacing: 16,
              children: [
                _metric(l10n.activeVacancies, '${snap.activeVacancies}'),
                _metric(l10n.closedVacancies, '${snap.closedVacancies}'),
                _metric(l10n.candidate, '${snap.candidates.length}'),
                _metric(l10n.pendingAssessments, '${snap.pendingAssessments}'),
                _metric(l10n.completedAssessments, '${snap.completedAssessments}'),
                _metric(l10n.affinityHigh, '${snap.highCount}'),
                _metric(l10n.affinityMedium, '${snap.mediumCount}'),
                _metric(l10n.affinityLow, '${snap.lowCount}'),
              ],
            ),
            const SizedBox(height: 24),
            PendingActionsCard(
              title: l10n.pendingActions,
              actions: alerts.isEmpty
                  ? [
                      PendingActionItem(
                        l10n.dashboardAlertsEmpty,
                        l10n.overviewSubtitle,
                        Icons.check_circle_outline,
                      ),
                    ]
                  : alerts,
            ),
            const SizedBox(height: 24),
            if (insights.recent.isEmpty)
              AdminPanel(
                child: Text(
                  l10n.dashboardRecentEmpty,
                  style: const TextStyle(color: AppColors.subtitle, height: 1.4),
                ),
              )
            else
              TopMatchesCard(
                title: l10n.topMatches,
                viewAll: l10n.viewAll,
                onViewAll: openCandidates,
                onCandidateTap: (_) => openCandidates(),
                candidates: [
                  for (final item in insights.recent)
                    CandidateMatch(
                      _candidateInitials(item),
                      item.displayName?.trim().isNotEmpty == true
                          ? item.displayName!
                          : item.email,
                      item.vacancyName,
                      processStatusLabel(context, item.processStatus),
                    ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _metric(String title, String value) => SizedBox(
    width: 240,
    child: DashboardMetricCard(
      title: title,
      value: value,
      caption: '',
      icon: Icons.bar_chart_outlined,
    ),
  );
}

String _candidateInitials(TalentCandidate item) {
  final name = item.displayName?.trim() ?? '';
  if (name.isNotEmpty) {
    final parts = name.split(RegExp(r'\s+')).where((part) => part.isNotEmpty);
    final letters = parts.map((part) => part[0]).take(2).join();
    if (letters.isNotEmpty) return letters.toUpperCase();
  }
  final email = item.email.trim();
  if (email.length >= 2) return email.substring(0, 2).toUpperCase();
  return '?';
}

class TalentVacanciesView extends StatelessWidget {
  const TalentVacanciesView({super.key, required this.state});
  final TalentState state;
  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: ContentWidth(
        child: Column(
        children: [
          AdminPageHeader(
            title: l10n.vacancy,
            subtitle: l10n.vacanciesSubtitle,
            actions: [
              FilledButton.icon(
                onPressed: state.companyId == null
                    ? null
                    : () => showCreateVacancyDialog(
                        context,
                        state.companyId!,
                        company: state.snapshot.profile,
                      ),
                style: FilledButton.styleFrom(backgroundColor: AppColors.primaryButton),
                icon: const Icon(Icons.add),
                label: Text(l10n.createVacancy),
              ),
            ],
          ),
          const SizedBox(height: 20),
          if (state.snapshot.vacancies.isEmpty)
            AdminEmptyState(message: l10n.noVacancies)
          else
            ...state.snapshot.vacancies.map((item) {
              // Simplificado: Solo mostramos el área si fue seleccionada
              final areaLabel = (item.area != null && item.area!.isNotEmpty)
                  ? vacancyAreaLabel(l10n, item.area)
                  : null;
                  
              final related = state.snapshot.candidates
                  .where((candidate) => candidate.vacancyId == item.id)
                  .toList();
              final completed = related.where((c) => c.evaluationCompleted).length;
              final inProgress = related
                  .where(
                    (c) => c.processStatus == CandidateProcessStatus.inProgress,
                  )
                  .length;
              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: AdminPanel(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                item.name,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.ink,
                                ),
                              ),
                            ),
                            AdminStatusChip(
                              item.status == VacancyStatus.active
                                  ? l10n.processStatusActive
                                  : l10n.processStatusClosed,
                            ),
                          ],
                        ),
                        if (areaLabel != null) ...[
                          const SizedBox(height: 6),
                          Text(
                            areaLabel,
                            style: const TextStyle(color: AppColors.subtitle),
                          ),
                        ],
                        if (item.description != null &&
                            item.description!.trim().isNotEmpty) ...[
                          const SizedBox(height: 12),
                          Text(item.description!.trim()),
                        ],
                        const SizedBox(height: 16),
                        Text(
                          l10n.vacancyInsights,
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            color: AppColors.ink,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          related.isEmpty
                              ? l10n.vacancyInsightsEmpty
                              : l10n.vacancyInsightsCounts(
                                  related.length,
                                  inProgress,
                                  completed,
                                ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
        ],
      ),
      ),
    );
  }
}

class TalentCandidatesView extends StatelessWidget {
  const TalentCandidatesView({super.key, required this.state});
  final TalentState state;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final items = state.filteredCandidates;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: ContentWidth(
        child: Column(
        children: [
          AdminPageHeader(
            title: l10n.candidate,
            subtitle: l10n.candidatesSubtitle,
            actions: [
              FilledButton.icon(
                onPressed: state.snapshot.vacancies.isEmpty
                    ? null
                    : () => showCreateRespondentDialog(context, state),
                style: FilledButton.styleFrom(backgroundColor: AppColors.primaryButton),
                icon: const Icon(Icons.add),
                label: Text(l10n.createRespondent),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 8,
            runSpacing: 8,
            children: [
              FilterChip(
                label: Text(l10n.filterAll),
                selected: state.vacancyFilterId == null &&
                    state.processFilter == null &&
                    state.affinityFilter == null,
                onSelected: (_) => context.read<TalentBloc>().add(
                  const TalentFilterChanged(
                    clearVacancy: true,
                    clearProcess: true,
                    clearAffinity: true,
                  ),
                ),
              ),
              ...state.snapshot.vacancies.map(
                (vacancy) => FilterChip(
                  label: Text(vacancy.name),
                  selected: state.vacancyFilterId == vacancy.id,
                  onSelected: (_) => context.read<TalentBloc>().add(
                    TalentFilterChanged(vacancyId: vacancy.id),
                  ),
                ),
              ),
              ...CandidateProcessStatus.values.map(
                (status) => FilterChip(
                  label: Text(processStatusLabel(context, status)),
                  selected: state.processFilter == status,
                  onSelected: (_) => context.read<TalentBloc>().add(
                    TalentFilterChanged(processStatus: status),
                  ),
                ),
              ),
              FilterChip(
                label: Text(l10n.priorityHigh),
                selected: state.affinityFilter == AffinityLevel.high,
                onSelected: (_) => context.read<TalentBloc>().add(
                  const TalentFilterChanged(affinity: AffinityLevel.high),
                ),
              ),
              FilterChip(
                label: Text(l10n.priorityMedium),
                selected: state.affinityFilter == AffinityLevel.medium,
                onSelected: (_) => context.read<TalentBloc>().add(
                  const TalentFilterChanged(affinity: AffinityLevel.medium),
                ),
              ),
              FilterChip(
                label: Text(l10n.priorityLow),
                selected: state.affinityFilter == AffinityLevel.low,
                onSelected: (_) => context.read<TalentBloc>().add(
                  const TalentFilterChanged(affinity: AffinityLevel.low),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          if (items.isEmpty)
            AdminEmptyState(message: l10n.noCandidates)
          else
            ...items.map((item) {
              final name = item.displayName?.trim().isNotEmpty == true
                  ? item.displayName!
                  : item.email;
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: AdminPanel(
                  child: InkWell(
                    onTap: () => context.read<TalentBloc>().add(
                      TalentCandidateOpened(item.id),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  name,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.ink,
                                    fontSize: 16,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${item.vacancyName} · ${processStatusLabel(context, item.processStatus)}',
                                  style: const TextStyle(
                                    color: AppColors.subtitle,
                                    height: 1.35,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 16),
                          Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    l10n.affinityCompany,
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: AppColors.muted,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  AffinityBadge(item.companyAffinity),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }),
        ],
      ),
      ),
    );
  }
}

class TalentReportsView extends StatelessWidget {
  const TalentReportsView({super.key, required this.state});
  final TalentState state;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final completed = state.snapshot.candidates
        .where((item) => item.evaluationCompleted)
        .toList();
    return SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: ContentWidth(
        child: Column(
          children: [
            AdminPageHeader(title: l10n.results, subtitle: l10n.resultsSubtitle),
            const SizedBox(height: 20),
            if (completed.isEmpty)
              AdminEmptyState(message: l10n.vacancyInsightsEmpty)
            else
              ...completed.map((item) {
                final name = item.displayName?.trim().isNotEmpty == true
                    ? item.displayName!
                    : item.email;
                return AdminEntityCard(
                  title: name,
                  subtitle:
                      '${item.vacancyName} · ${l10n.affinityCompany} ${affinityWord(context, item.companyAffinity)}',
                  trailing: l10n.evaluationCompleted,
                  onTap: () => context.read<TalentBloc>().add(
                    TalentCandidateOpened(item.id),
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }
}

class TalentTeamView extends StatelessWidget {
  const TalentTeamView({super.key, required this.state});
  final TalentState state;
  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: ContentWidth(
        child: Column(
        children: [
          AdminPageHeader(
            title: l10n.team,
            subtitle: l10n.teamSubtitle,
            actions: [
              FilledButton.icon(
                onPressed: state.companyId == null
                    ? null
                    : () => showInviteRecruiterDialog(
                        context,
                        state.companyId!,
                        companyName: state.snapshot.profile?.name,
                      ),
                style: FilledButton.styleFrom(backgroundColor: AppColors.primaryButton),
                icon: const Icon(Icons.person_add_alt_1),
                label: Text(l10n.inviteRecruiter),
              ),
            ],
          ),
          const SizedBox(height: 20),
          if (state.snapshot.team.isEmpty)
            AdminEmptyState(message: l10n.noTeamMembers)
          else
            ...state.snapshot.team.map((item) {
              final roleLabel = teamRoleLabel(l10n, UserRoleX.parse(item.role));
              return AdminEntityCard(
                title: item.displayName?.isNotEmpty == true
                    ? item.displayName!
                    : item.email,
                subtitle: '${item.email} · $roleLabel',
                trailing: item.inviteUsed ? l10n.invitationUsed : l10n.invitationPending,
              );
            }),
        ],
      ),
      ),
    );
  }
}

class TalentProfileView extends StatefulWidget {
  const TalentProfileView({super.key, required this.state});
  final TalentState state;
  @override
  State<TalentProfileView> createState() => _TalentProfileViewState();
}

class _TalentProfileViewState extends State<TalentProfileView> {
  late final TextEditingController _name;
  late final TextEditingController _nit;
  late final TextEditingController _website;
  late final TextEditingController _description;
  late List<String> _values;
  late List<String> _culture;
  late List<String> _standout;
  String? _sector;
  String? _size;
  late LocationValue _location;
  late String? _logoUrl;

  @override
  void initState() {
    super.initState();
    final profile = widget.state.snapshot.profile;
    _name = TextEditingController(text: profile?.name ?? '');
    _nit = TextEditingController(text: profile?.nit ?? '');
    _sector = profile?.sector;
    _size = profile?.size;
    _location = LocationValue(
      country: profile?.country ?? 'Colombia',
      region: profile?.region,
      city: profile?.city,
    );
    _website = TextEditingController(text: profile?.website ?? '');
    _logoUrl = profile?.logoUrl;
    _description = TextEditingController(text: profile?.description ?? '');
    _values = parseDnaList(profile?.values);
    _culture = parseDnaList(profile?.culture);
    _standout = parseDnaList(profile?.standoutPeople);
  }

  @override
  void dispose() {
    _name.dispose();
    _nit.dispose();
    _website.dispose();
    _description.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final id = widget.state.companyId;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: ContentWidth(
        maxWidth: 760,
        child: Column(
        children: [
          AdminPageHeader(
            title: l10n.companyProfile,
            subtitle: l10n.companyProfileSubtitle,
          ),
          const SizedBox(height: 20),
          _field(l10n.companyName, _name),
          _field(l10n.nit, _nit),
          AppSelectField(
            label: l10n.sector,
            value: resolveCompanySectorId(_sector, l10n),
            options: companySectors(l10n),
            onChanged: (value) => setState(() => _sector = value),
          ),
          AppSelectField(
            label: l10n.companySize,
            value: resolveCompanySizeId(_size, l10n),
            options: companySizes(l10n),
            onChanged: (value) => setState(() => _size = value),
          ),
          LocationPicker(
            initial: _location,
            onChanged: (value) => _location = value,
          ),
          _field(l10n.website, _website),
          LogoField(
            initialUrl: _logoUrl,
            onChanged: (value) => _logoUrl = value.url,
          ),
          _field(l10n.description, _description, lines: 3),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: FilledButton(
              onPressed: id == null ? null : _save,
              style: FilledButton.styleFrom(backgroundColor: AppColors.primaryButton),
              child: Text(l10n.saveChanges),
            ),
          ),
        ],
      ),
      ),
    );
  }

  void _save() {
    final id = widget.state.companyId;
    if (id == null) return;
    final l10n = context.l10n;
    context.read<TalentBloc>().add(
      TalentProfileSaved(
        CompanyProfile(
          id: id,
          name: _name.text.trim(),
          nit: _nit.text.trim(),
          sector: resolveCompanySectorId(_sector, l10n) ?? _sector,
          size: resolveCompanySizeId(_size, l10n) ?? _size,
          country: _location.country,
          region: _location.region,
          city: _location.city,
          website: _website.text.trim(),
          logoUrl: _logoUrl,
          description: _description.text.trim(),
          values: joinDnaList(_values),
          culture: joinDnaList(_culture),
          standoutPeople: joinDnaList(_standout),
          customValues: widget.state.snapshot.profile?.customValues ?? const [],
          customCulture: widget.state.snapshot.profile?.customCulture ?? const [],
          customStandout: widget.state.snapshot.profile?.customStandout ?? const [],
          customAreas: widget.state.snapshot.profile?.customAreas ?? const [],
        ),
      ),
    );
  }

  Widget _field(String label, TextEditingController controller, {int lines = 1}) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 14),
        child: TextField(
          controller: controller,
          maxLines: lines,
          decoration: InputDecoration(
            labelText: label,
            border: const OutlineInputBorder(),
          ),
        ),
      );
}
