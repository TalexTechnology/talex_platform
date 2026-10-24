import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:talex_platform/core/constants/app_colors.dart';
import 'package:talex_platform/core/di/injection.dart';
import 'package:talex_platform/core/services/notification_service.dart';
import 'package:talex_platform/core/widgets/language_selector.dart';
import 'package:talex_platform/features/admin/domain/entities/admin_entities.dart';
import 'package:talex_platform/features/admin/presentation/bloc/admin_bloc.dart';
import 'package:talex_platform/features/assistant/presentation/assistant_host.dart';
import 'package:talex_platform/features/assistant/presentation/assistant_text.dart';
import 'package:talex_platform/features/assistant/presentation/brief/assistant_brief_builder.dart';
import 'package:talex_platform/features/admin/presentation/pages/admin_views.dart';
import 'package:talex_platform/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:talex_platform/features/dashboard/presentation/widgets/dashboard_widgets.dart';
import 'package:talex_platform/l10n/l10n.dart';

class AdminShell extends StatefulWidget {
  const AdminShell({super.key});
  @override
  State<AdminShell> createState() => _AdminShellState();
}

class _AdminShellState extends State<AdminShell> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();

  static const _sections = [
    AdminSection.dashboard,
    AdminSection.companies,
    AdminSection.processes,
    AdminSection.people,
    AdminSection.affinity,
    AdminSection.commercial,
    AdminSection.sales,
    AdminSection.analytics,
    AdminSection.alerts,
    // AdminSection.xebec,
    AdminSection.questions,
    AdminSection.cultureSurvey,
    AdminSection.settings,
  ];

  List<DashboardNavItem> _items(BuildContext context) {
    final l10n = context.l10n;
    return [
      DashboardNavItem(l10n.adminCommandCenter, Icons.space_dashboard_outlined),
      DashboardNavItem(l10n.adminCompanies, Icons.apartment_outlined),
      DashboardNavItem(l10n.adminProcesses, Icons.account_tree_outlined),
      DashboardNavItem(l10n.adminPeople, Icons.groups_outlined),
      DashboardNavItem(l10n.adminAffinity, Icons.hub_outlined),
      DashboardNavItem(l10n.adminCommercial, Icons.handshake_outlined),
      DashboardNavItem(l10n.adminSales, Icons.payments_outlined),
      DashboardNavItem(l10n.adminAnalytics, Icons.insights_outlined),
      DashboardNavItem(l10n.adminAlerts, Icons.notifications_active_outlined),
      // DashboardNavItem(l10n.adminXebec, Icons.bolt_outlined),
      DashboardNavItem(l10n.adminQuestions, Icons.quiz_outlined),
      DashboardNavItem(l10n.adminCultureSurvey, Icons.diversity_3_outlined),
      DashboardNavItem(l10n.adminSettings, Icons.settings_outlined),
    ];
  }

  void _select(int index) {
    context.read<AdminBloc>().add(AdminSectionSelected(_sections[index]));
    if (_scaffoldKey.currentState?.isDrawerOpen ?? false) {
      Navigator.of(context).pop();
    }
  }

  void _search(String query, AdminSection section) {
    final bloc = context.read<AdminBloc>();
    switch (section) {
      case AdminSection.companies:
        bloc.add(AdminCompaniesRequested(query: query));
      case AdminSection.processes:
        bloc.add(AdminProcessesRequested(query: query));
      case AdminSection.people:
        bloc.add(AdminPeopleRequested(query: query));
      case AdminSection.commercial:
        bloc.add(AdminDealsRequested(query: query));
      default:
        break;
    }
  }

  @override
  Widget build(BuildContext context) => BlocListener<AdminBloc, AdminState>(
    listenWhen: (previous, current) =>
        previous.operation != current.operation ||
        previous.failure != current.failure,
    listener: (context, state) {
      final notifications = getIt<NotificationService>();
      if (state.failure != null) {
        notifications.error(state.failure!.message);
      } else if (state.operation == AdminOperation.saved) {
        notifications.success(context.l10n.adminSaved);
      }
    },
    child: BlocBuilder<AdminBloc, AdminState>(
      builder: (context, state) {
        final desktop = MediaQuery.sizeOf(context).width >= 1000;
        final sidebar = DashboardSidebar(
          items: _items(context),
          footerItems: [
            DashboardNavItem(context.l10n.support, Icons.help_outline),
            DashboardNavItem(
              context.l10n.documentation,
              Icons.menu_book_outlined,
            ),
          ],
          selectedIndex: _sections
              .indexOf(state.section)
              .clamp(0, _sections.length - 1),
          onSelected: _select,
        );
        return AssistantHost(
          brief: AssistantBriefBuilder.admin(
            Localizations.localeOf(context).languageCode,
          ),
          builder: (context, openAssistant, assistantOpen) => Scaffold(
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
                        searchHint: context.l10n.adminSearchHint,
                        signOutLabel: context.l10n.signOut,
                        showMenu: !desktop,
                        onMenu: () => _scaffoldKey.currentState?.openDrawer(),
                        onSignOut: () => context.read<AuthBloc>().add(
                          const AuthSignOutRequested(),
                        ),
                        onSearch: (query) => _search(query, state.section),
                        onNotifications: () =>
                            _select(_sections.indexOf(AdminSection.alerts)),
                        trailing: const LanguageSelector(compact: true),
                        assistantTooltip: AssistantText.of(context).openLabel,
                        assistantLabel: AssistantText.of(context).name,
                        assistantOpen: assistantOpen,
                        onAssistant: openAssistant,
                      ),
                      const Expanded(child: AdminSectionView()),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    ),
  );
}
