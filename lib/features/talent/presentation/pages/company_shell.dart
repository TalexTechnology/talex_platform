import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:talex_platform/core/constants/app_colors.dart';
import 'package:talex_platform/core/di/injection.dart';
import 'package:talex_platform/core/services/notification_service.dart';
import 'package:talex_platform/core/widgets/language_selector.dart';
import 'package:talex_platform/features/assistant/domain/entities/assistant_reply.dart';
import 'package:talex_platform/features/assistant/presentation/assistant_host.dart';
import 'package:talex_platform/features/assistant/presentation/assistant_text.dart';
import 'package:talex_platform/features/assistant/presentation/brief/assistant_brief_builder.dart';
import 'package:talex_platform/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:talex_platform/features/dashboard/presentation/widgets/dashboard_widgets.dart';
import 'package:talex_platform/features/settings/presentation/pages/settings_view.dart';
import 'package:talex_platform/features/talent/domain/entities/talent_entities.dart';
import 'package:talex_platform/features/talent/domain/services/dna_catalog.dart';
import 'package:talex_platform/features/talent/presentation/bloc/talent_bloc.dart';
import 'package:talex_platform/features/talent/presentation/pages/talent_candidate_result_view.dart';
import 'package:talex_platform/features/talent/presentation/pages/talent_views.dart';
import 'package:talex_platform/features/talent/presentation/pages/talent_password_page.dart';
import 'package:talex_platform/features/talent/presentation/talent_error_message.dart';
import 'package:talex_platform/l10n/l10n.dart';

class CompanyShell extends StatefulWidget {
  const CompanyShell({
    super.key,
    required this.companyId,
    required this.mustChangePassword,
    required this.mustReviewCompanyDna,
  });
  final String companyId;
  final bool mustChangePassword;
  final bool mustReviewCompanyDna;
  @override
  State<CompanyShell> createState() => _CompanyShellState();
}

class _CompanyShellState extends State<CompanyShell> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();

  List<DashboardNavItem> _items(BuildContext context) {
    final l10n = context.l10n;
    return [
      DashboardNavItem(l10n.dashboard, Icons.dashboard_outlined),
      DashboardNavItem(l10n.vacancy, Icons.work_outline),
      DashboardNavItem(l10n.candidate, Icons.groups_outlined),
      DashboardNavItem(l10n.results, Icons.analytics_outlined),
      DashboardNavItem(l10n.team, Icons.manage_accounts_outlined),
      DashboardNavItem(l10n.companyProfile, Icons.apartment_outlined),
      DashboardNavItem(l10n.settings, Icons.settings_outlined),
    ];
  }

  @override
  Widget build(BuildContext context) {
    if (widget.mustChangePassword) {
      return const TalentPasswordPage();
    }
    return BlocListener<TalentBloc, TalentState>(
      listenWhen: (previous, current) =>
          previous.generatedPin != current.generatedPin ||
          previous.respondentInvited != current.respondentInvited ||
          previous.candidateNotice != current.candidateNotice ||
          previous.failure != current.failure,
      listener: (context, state) {
        final notifications = getIt<NotificationService>();
        if (state.failure != null) {
          notifications.error(
            talentErrorMessage(context.l10n, state.failure!.message),
          );
        } else if (state.generatedPin != null) {
          notifications.success(
            context.l10n.invitePinReady(state.generatedPin!),
          );
        } else if (state.candidateNotice == TalentCandidateNotice.updated) {
          notifications.success(context.l10n.candidateUpdated);
        } else if (state.candidateNotice == TalentCandidateNotice.deleted) {
          notifications.success(context.l10n.candidateDeleted);
        } else if (state.respondentInvited) {
          notifications.success(context.l10n.respondentInviteSent);
        }
      },
      child: BlocBuilder<TalentBloc, TalentState>(
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
            selectedIndex: state.section.index,
            onSelected: (index) {
              context.read<TalentBloc>().add(
                TalentSectionSelected(TalentSection.values[index]),
              );
              if (_scaffoldKey.currentState?.isDrawerOpen ?? false) {
                Navigator.pop(context);
              }
            },
          );
          return AssistantHost(
            brief: AssistantBriefBuilder.company(
              snapshot: state.snapshot,
              status: state.status,
              locale: Localizations.localeOf(context).languageCode,
            ),
            onAnswerEdit: (edit) => _saveAnswers(context, edit),
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
                          child: state.candidateReport != null
                              ? TalentCandidateResultView(
                                  report: state.candidateReport!,
                                )
                              : switch (state.section) {
                                  TalentSection.dashboard =>
                                    TalentDashboardView(state: state),
                                  TalentSection.vacancies =>
                                    TalentVacanciesView(state: state),
                                  TalentSection.candidates =>
                                    TalentCandidatesView(state: state),
                                  TalentSection.reports => TalentReportsView(
                                    state: state,
                                  ),
                                  TalentSection.team => TalentTeamView(
                                    state: state,
                                  ),
                                  TalentSection.profile => TalentProfileView(
                                    state: state,
                                  ),
                                  TalentSection.settings =>
                                    const SettingsView(),
                                },
                        ),
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

  void _saveAnswers(BuildContext context, CompanyAnswerEdit edit) {
    final bloc = context.read<TalentBloc>();
    final profile = bloc.state.snapshot.profile;
    final id = bloc.state.companyId ?? profile?.id;
    if (profile == null || id == null) return;
    bloc.add(
      TalentProfileSaved(
        CompanyProfile(
          id: id,
          name: profile.name,
          nit: profile.nit,
          logoUrl: profile.logoUrl,
          sector: profile.sector,
          size: profile.size,
          city: profile.city,
          country: profile.country,
          region: profile.region,
          website: profile.website,
          description: profile.description,
          values: joinDnaList(edit.values),
          culture: joinDnaList(edit.culture),
          standoutPeople: joinDnaList(edit.standout),
          soughtCharacteristics: profile.soughtCharacteristics,
          customValues: profile.customValues,
          customCulture: profile.customCulture,
          customStandout: profile.customStandout,
          customAreas: profile.customAreas,
        ),
      ),
    );
  }
}
