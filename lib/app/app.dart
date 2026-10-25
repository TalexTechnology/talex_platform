import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:web/web.dart' as web;

import 'package:talex_platform/core/theme/talex_theme.dart';
import 'package:talex_platform/core/di/injection.dart';
import 'package:talex_platform/core/locale/locale_cubit.dart';
import 'package:talex_platform/core/services/notification_service.dart';
import 'package:talex_platform/features/admin/presentation/bloc/admin_bloc.dart';
import 'package:talex_platform/features/admin/presentation/pages/admin_shell.dart';
import 'package:talex_platform/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:talex_platform/features/auth/presentation/pages/auth_page.dart';
import 'package:talex_platform/features/auth/presentation/pages/recover_access_page.dart';
import 'package:talex_platform/features/auth/presentation/pages/register_page.dart';
import 'package:talex_platform/features/dashboard/presentation/pages/dashboard_page.dart';
import 'package:talex_platform/features/invitations/presentation/bloc/invitation_bloc.dart';
import 'package:talex_platform/features/talent/presentation/bloc/talent_bloc.dart';
import 'package:talex_platform/features/talent/presentation/pages/company_shell.dart';
import 'package:talex_platform/features/talent/domain/services/assessment_invite_link.dart';
import 'package:talex_platform/features/talent/presentation/pages/respondent_shell.dart';
import 'package:talex_platform/l10n/app_localizations.dart';

class TalexApp extends StatefulWidget {
  const TalexApp({super.key});

  @override
  State<TalexApp> createState() => _TalexAppState();
}

class _TalexAppState extends State<TalexApp> {
  bool _respondentInviteProcessed = false;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _processRespondentInvite();
    });
  }

  void _processRespondentInvite() {
    if (_respondentInviteProcessed) {
      return;
    }

    final token = _getRespondentInviteToken();

    if (token == null || token.isEmpty) {
      return;
    }

    _respondentInviteProcessed = true;

    context.read<AuthBloc>().add(
      AuthRespondentInviteRequested(token),
    );
  }

  String? _getRespondentInviteToken() {
    return AssessmentInviteLink.tokenFromUri(Uri.base) ??
        AssessmentInviteLink.tokenFromFragment(web.window.location.hash);
  }

  void _clearRespondentInviteUrl() {
    web.window.history.replaceState(
      null,
      '',
      web.window.location.pathname +
          web.window.location.search,
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<LocaleCubit, Locale>(
      builder: (context, locale) => MaterialApp(
        navigatorKey: getIt<NotificationService>().navigatorKey,
        title: 'TaleX',
        debugShowCheckedModeBanner: false,
        locale: locale,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        theme: talexTheme(),
        routes: {
          AuthPage.routeName: (_) => const AuthPage(),
          RegisterPage.routeName: (_) => const RegisterPage(),
        },
        onGenerateRoute: (settings) {
          if (settings.name == RecoverAccessPage.routeName) {
            final email = settings.arguments is String
                ? settings.arguments as String
                : '';

            return MaterialPageRoute(
              settings: settings,
              builder: (_) => RecoverAccessPage(
                initialEmail: email,
              ),
            );
          }

          return null;
        },
        home: BlocListener<AuthBloc, AuthState>(
          listenWhen: (previous, current) =>
              previous.status != current.status,
          listener: (context, state) {
            if (state.status == AuthStatus.authenticated &&
                _respondentInviteProcessed) {
              _clearRespondentInviteUrl();
            }
          },
          child: BlocBuilder<AuthBloc, AuthState>(
            builder: (context, state) => switch (state.status) {
              AuthStatus.authenticated => _AuthenticatedHome(
                state: state,
              ),

              AuthStatus.initial ||
              AuthStatus.loading => const Scaffold(
                body: Center(
                  child: CircularProgressIndicator(),
                ),
              ),

              AuthStatus.needsInvitePin => const RegisterPage(),

              _ => const AuthPage(),
            },
          ),
        ),
      ),
    );
  }
}

class _AuthenticatedHome extends StatelessWidget {
  const _AuthenticatedHome({
    required this.state,
  });

  final AuthState state;

  @override
  Widget build(BuildContext context) {
    final user = state.user;

    if (user?.isSuperAdmin == true) {
      return BlocProvider(
        create: (_) {
          configureAdminDependencies();

          return getIt<AdminBloc>()
            ..add(const AdminDashboardRequested());
        },
        child: const AdminShell(),
      );
    }

    if (user?.isRespondent == true) {
      configureTalentDependencies();

      return BlocProvider(
        create: (_) => getIt<TalentBloc>()
          ..add(const TalentRespondentSessionLoaded()),
        child: RespondentShell(
          mustChangePassword: user?.mustChangePassword ?? false,
        ),
      );
    }

    final companyId = user?.companyId;

    if (user != null &&
        user.isCompanyStaff &&
        companyId != null) {
      configureTalentDependencies();

      return BlocProvider(
        create: (_) => getIt<TalentBloc>()
          ..add(TalentLoaded(companyId)),
        child: CompanyShell(
          companyId: companyId,
          mustChangePassword: user.mustChangePassword,
          mustReviewCompanyDna: user.mustReviewCompanyDna,
        ),
      );
    }

    return BlocProvider(
      create: (_) {
        configureInvitationDependencies();

        return getIt<InvitationBloc>()
          ..add(const InvitationsRequested());
      },
      child: const DashboardPage(),
    );
  }
}