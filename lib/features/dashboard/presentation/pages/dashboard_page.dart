import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:talex_platform/core/constants/app_colors.dart';
import 'package:talex_platform/core/widgets/language_selector.dart';
import 'package:talex_platform/features/assistant/presentation/assistant_host.dart';
import 'package:talex_platform/features/assistant/presentation/assistant_text.dart';
import 'package:talex_platform/features/assistant/presentation/brief/assistant_brief_builder.dart';
import 'package:talex_platform/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:talex_platform/features/dashboard/presentation/widgets/dashboard_widgets.dart';
import 'package:talex_platform/l10n/l10n.dart';
import 'package:talex_platform/features/settings/presentation/pages/settings_view.dart';
import 'package:talex_platform/features/invitations/presentation/pages/invitations_view.dart';
import 'package:talex_platform/features/invitations/presentation/bloc/invitation_bloc.dart';
import 'package:talex_platform/features/invitations/presentation/widgets/create_invitation_dialog.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});
  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  int _selectedIndex = 0;

  void _selectSection(int index) {
    if (index != 0 && index != 1 && index != 6) return;
    setState(() => _selectedIndex = index);
    if (_scaffoldKey.currentState?.isDrawerOpen ?? false) {
      Navigator.of(context).pop();
    }
  }

  void _openCreateInvitation() {
    final invitationBloc = context.read<InvitationBloc>();
    showDialog<void>(
      context: context,
      builder: (_) => BlocProvider.value(
        value: invitationBloc,
        child: const CreateInvitationDialog(),
      ),
    );
  }

  List<DashboardNavItem> _navigation(BuildContext context) => [
    DashboardNavItem(context.l10n.dashboard, Icons.dashboard_outlined),
    DashboardNavItem(context.l10n.roles, Icons.work_outline),
    DashboardNavItem(context.l10n.candidates, Icons.groups_outlined),
    DashboardNavItem(
      context.l10n.assessments,
      Icons.assignment_turned_in_outlined,
    ),
    DashboardNavItem(context.l10n.managers, Icons.manage_accounts_outlined),
    DashboardNavItem(context.l10n.reports, Icons.analytics_outlined),
    DashboardNavItem(context.l10n.settings, Icons.settings_outlined),
  ];

  @override
  Widget build(BuildContext context) {
    final brief = AssistantBriefBuilder.workspace(
      invitations: context.watch<InvitationBloc>().state.invitations,
      locale: Localizations.localeOf(context).languageCode,
    );
    return AssistantHost(
      brief: brief,
      builder: (context, openAssistant, assistantOpen) => LayoutBuilder(
        builder: (context, constraints) {
          final desktop = constraints.maxWidth >= 1000;
          final sidebar = DashboardSidebar(
            items: _navigation(context),
            footerItems: [
              DashboardNavItem(context.l10n.support, Icons.help_outline),
              DashboardNavItem(
                context.l10n.documentation,
                Icons.menu_book_outlined,
              ),
            ],
            selectedIndex: _selectedIndex,
            onSelected: _selectSection,
          );
          return Scaffold(
            key: _scaffoldKey,
            backgroundColor: AppColors.dashboardBackground,
            drawer: desktop ? null : Drawer(width: 270, child: sidebar),
            body: Row(
              children: [
                if (desktop) sidebar,
                Expanded(
                  child: Column(
                    children: [
                      DashboardTopBar(
                        searchHint: context.l10n.searchHint,
                        signOutLabel: context.l10n.signOut,
                        showMenu: !desktop,
                        onMenu: () => _scaffoldKey.currentState?.openDrawer(),
                        onSignOut: () => context.read<AuthBloc>().add(
                          const AuthSignOutRequested(),
                        ),
                        trailing: const LanguageSelector(compact: true),
                        assistantTooltip: AssistantText.of(context).openLabel,
                        assistantLabel: AssistantText.of(context).name,
                        assistantOpen: assistantOpen,
                        onAssistant: openAssistant,
                      ),
                      Expanded(
                        child: switch (_selectedIndex) {
                          1 => InvitationsView(onCreate: _openCreateInvitation),
                          6 => const SettingsView(),
                          _ => _DashboardContent(
                            onEnablePerson: _openCreateInvitation,
                          ),
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _DashboardContent extends StatelessWidget {
  const _DashboardContent({required this.onEnablePerson});
  final VoidCallback onEnablePerson;
  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final narrow = constraints.maxWidth < 720;
      final medium = constraints.maxWidth < 1250;
      final padding = narrow ? 18.0 : 40.0;
      final columns = narrow
          ? 1
          : medium
          ? 2
          : 4;
      final cardWidth =
          (constraints.maxWidth - padding * 2 - (columns - 1) * 24) / columns;
      final metrics = [
        DashboardMetricCard(
          title: context.l10n.activeRoles,
          value: '32',
          caption: '↗ ${context.l10n.thisWeekChange}',
          icon: Icons.work_outline,
          captionColor: AppColors.positive,
        ),
        DashboardMetricCard(
          title: context.l10n.evaluatedCandidates,
          value: '18',
          caption: context.l10n.thisMonthChange,
          icon: Icons.mark_email_unread_outlined,
          captionColor: AppColors.positive,
        ),
        DashboardMetricCard(
          title: context.l10n.averageFitScore,
          value: '7',
          caption: context.l10n.stableTopRoles,
          icon: Icons.pending_actions_outlined,
        ),
        DashboardMetricCard(
          title: context.l10n.hiringVelocity,
          value: '126',
          caption: '↗ ${context.l10n.daysFromQuarter}',
          icon: Icons.task_alt_outlined,
          captionColor: AppColors.positive,
        ),
      ];
      final matches = TopMatchesCard(
        title: context.l10n.topMatches,
        viewAll: context.l10n.viewAll,
        candidates: [
          CandidateMatch(
            'GR',
            'Gabriel Ramirez',
            context.l10n.logicalReasoningAssessment,
            context.l10n.statusCompleted,
          ),
          CandidateMatch(
            'MR',
            'Marcus Reed',
            context.l10n.decisionMakingAssessment,
            context.l10n.statusInProgress,
          ),
          CandidateMatch(
            'EL',
            'Elena Lopez',
            context.l10n.problemSolvingAssessment,
            context.l10n.statusPending,
          ),
        ],
      );
      final actions = PendingActionsCard(
        title: context.l10n.pendingActions,
        actions: [
          PendingActionItem(
            context.l10n.reviewRequirements,
            context.l10n.completedToday,
            Icons.fact_check_outlined,
          ),
          PendingActionItem(
            context.l10n.finalApproval,
            context.l10n.expiresTomorrow,
            Icons.how_to_reg_outlined,
          ),
          PendingActionItem(
            context.l10n.scheduleInterview,
            context.l10n.connectionInterrupted,
            Icons.schedule_outlined,
          ),
        ],
      );
      return SingleChildScrollView(
        padding: EdgeInsets.all(padding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              runSpacing: 18,
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.l10n.overview,
                      style: TextStyle(
                        color: AppColors.ink,
                        fontSize: narrow ? 34 : 42,
                        height: 1,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -1.5,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      context.l10n.overviewSubtitle,
                      style: const TextStyle(
                        color: AppColors.subtitle,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
                Wrap(
                  spacing: 12,
                  children: [
                    OutlinedButton(
                      onPressed: onEnablePerson,
                      child: Text(context.l10n.generateReport),
                    ),
                    FilledButton.icon(
                      onPressed: () {},
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.primaryButton,
                      ),
                      icon: const Icon(Icons.add),
                      label: Text(context.l10n.newRole),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 34),
            Wrap(
              spacing: 24,
              runSpacing: 24,
              children: metrics
                  .map((card) => SizedBox(width: cardWidth, child: card))
                  .toList(),
            ),
            const SizedBox(height: 36),
            if (medium) ...[
              matches,
              const SizedBox(height: 24),
              actions,
            ] else
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(flex: 2, child: matches),
                  const SizedBox(width: 24),
                  Expanded(child: actions),
                ],
              ),
            const SizedBox(height: 40),
          ],
        ),
      );
    },
  );
}
