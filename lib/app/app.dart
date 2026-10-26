import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:web/web.dart' as web;

import 'package:talex_platform/core/theme/talex_theme.dart';
import 'package:talex_platform/core/theme/talex_theme_switcher.dart';
import 'package:talex_platform/core/theme/theme_cubit.dart';
import 'package:talex_platform/core/widgets/talex_splash.dart';
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
import 'package:talex_platform/features/talent/domain/services/affinity_demo_link.dart';
import 'package:talex_platform/features/talent/domain/services/assessment_invite_link.dart';
import 'package:talex_platform/features/talent/presentation/pages/affinity_demo_page.dart';
import 'package:talex_platform/features/culture/domain/culture_survey_link.dart';
import 'package:talex_platform/features/culture/presentation/pages/company_culture_survey_page.dart';
import 'package:talex_platform/features/talent/presentation/pages/respondent_shell.dart';
import 'package:talex_platform/l10n/app_localizations.dart';

class TalexApp extends StatefulWidget {
  const TalexApp({super.key});

  @override
  State<TalexApp> createState() => _TalexAppState();
}

class _TalexAppState extends State<TalexApp> {
  bool _respondentInviteProcessed = false;
  // Último estado de sesión resuelto; dice si la carga actual es un
  // arranque, un inicio o un cierre de sesión.
  AuthStatus? _lastSettled;

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

  String? _cultureOrganizationId() {
    final fromWindow = Uri.tryParse(web.window.location.href);
    return CultureSurveyLink.organizationIdFromUri(fromWindow ?? Uri.base) ??
        CultureSurveyLink.organizationIdFromUri(Uri.base) ??
        CultureSurveyLink.organizationIdFromFragment(web.window.location.hash);
  }

  void _clearRespondentInviteUrl() {
    web.window.history.replaceState(
      null,
      '',
      web.window.location.pathname +
          web.window.location.search,
    );
  }

  // Mensajes de la pantalla de carga según lo que esté pasando.
  List<String> _loadingMessages(AppLocalizations l10n) {
    if (_respondentInviteProcessed) {
      return [l10n.splashValidatingInvite, l10n.splashPreparingAssessment];
    }
    return switch (_lastSettled) {
      null => [
        l10n.splashVerifyingSession,
        l10n.splashLoadingSettings,
        l10n.splashPreparingWorkspace,
      ],
      AuthStatus.authenticated => [l10n.splashSigningOut],
      _ => [
        l10n.splashSigningIn,
        l10n.splashLoadingSettings,
        l10n.splashPreparingWorkspace,
      ],
    };
  }

  @override
  Widget build(BuildContext context) {
    context.select<ThemeCubit, Brightness>((cubit) => cubit.state.brightness);
    return BlocBuilder<LocaleCubit, Locale>(
      builder: (context, locale) => MaterialApp(
        navigatorKey: getIt<NotificationService>().navigatorKey,
        title: 'TaleX',
        debugShowCheckedModeBanner: false,
        locale: locale,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        // talexTheme() lee la paleta activa; el select de ThemeCubit de arriba
        // reconstruye la app cuando cambia el brillo.
        theme: talexTheme(),
        // El cambio lo anima TalexThemeSwitcher, no la interpolación de Material.
        themeAnimationDuration: Duration.zero,
        builder: (context, child) =>
            TalexThemeSwitcher(child: child ?? const SizedBox.shrink()),
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
        home: AffinityDemoLink.matches(Uri.base)
            ? const AffinityDemoPage()
            : _cultureOrganizationId() != null
            ? CompanyCultureSurveyPage(organizationId: _cultureOrganizationId()!)
            : BlocListener<AuthBloc, AuthState>(
          listenWhen: (previous, current) =>
              previous.status != current.status,
          listener: (context, state) {
            if (state.status == AuthStatus.authenticated &&
                _respondentInviteProcessed) {
              _clearRespondentInviteUrl();
            }
            if (state.status != AuthStatus.initial &&
                state.status != AuthStatus.loading) {
              _lastSettled = state.status;
            }
          },
          child: BlocBuilder<AuthBloc, AuthState>(
            builder: (context, state) => switch (state.status) {
              AuthStatus.authenticated => _AuthenticatedHome(
                state: state,
              ),

              AuthStatus.initial || AuthStatus.loading => TalexSplash(
                messages: _loadingMessages(AppLocalizations.of(context)),
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