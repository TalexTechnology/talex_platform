import 'package:flutter/material.dart';
import 'package:talex_platform/core/widgets/theme_toggle_button.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:talex_platform/core/constants/app_colors.dart';
import 'package:talex_platform/core/di/injection.dart';
import 'package:talex_platform/core/responsive/responsive_layout.dart';
import 'package:talex_platform/core/services/notification_service.dart';
import 'package:talex_platform/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:talex_platform/core/widgets/language_selector.dart';
import 'package:talex_platform/core/widgets/talex_logo.dart';
import 'package:talex_platform/core/widgets/talex_ui.dart';
import 'package:talex_platform/features/auth/presentation/pages/recover_access_page.dart';
import 'package:talex_platform/features/auth/presentation/pages/register_page.dart';
import 'package:talex_platform/features/auth/presentation/widgets/auth_widgets.dart';
import 'package:talex_platform/features/talent/presentation/talent_error_message.dart';
import 'package:talex_platform/l10n/l10n.dart';

class AuthPage extends StatefulWidget {
  const AuthPage({super.key});
  static const routeName = '/login';
  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    context.read<AuthBloc>().add(
      AuthSignInRequested(email: _email.text.trim(), password: _password.text),
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state.status == AuthStatus.passwordResetSent) {
          getIt<NotificationService>().success(context.l10n.resetEmailSent);
          return;
        }
        final raw = state.failure?.message;
        final mapped = raw != null && raw.startsWith('error')
            ? talentErrorMessage(context.l10n, raw)
            : raw;
        if (state.status == AuthStatus.googleFailure) {
          getIt<NotificationService>().error(
            mapped == null || mapped.isEmpty
                ? context.l10n.googleSignInError
                : mapped,
          );
          return;
        }
        if (mapped == null || mapped.isEmpty) return;
        getIt<NotificationService>().error(mapped);
      },
      child: TalexGlow(
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final size = ResponsiveLayout.of(context, constraints);
              final wide = size.screenSize == ScreenSize.expanded;
              final form = _form(context, size, showLogo: !wide);
              return SingleChildScrollView(
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minWidth: constraints.maxWidth,
                    minHeight: constraints.maxHeight,
                  ),
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: wide ? 64 : size.horizontalPadding,
                      vertical: size.verticalPadding,
                    ),
                    child: wide
                        ? Center(
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 1180),
                              child: Row(
                                children: [
                                  const Expanded(child: AuthBrandPanel()),
                                  const SizedBox(width: 72),
                                  SizedBox(width: 460, child: form),
                                ],
                              ),
                            ),
                          )
                        : Center(
                            child: ConstrainedBox(
                              constraints: BoxConstraints(
                                maxWidth: size.cardMaxWidth,
                              ),
                              child: form,
                            ),
                          ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    ),
  );

  Widget _form(
    BuildContext context,
    ResponsiveLayout size, {
    required bool showLogo,
  }) {
    final l10n = context.l10n;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            if (showLogo)
              const TalexLogo(width: 120, height: 36)
            else
              const Spacer(),
            if (showLogo) const Spacer(),
            const LanguageSelector(compact: true),
            const SizedBox(width: 12),
            const ThemeToggleButton(size: 36),
          ],
        ),
        SizedBox(height: size.isCompact ? 24 : 28),
        BlocBuilder<AuthBloc, AuthState>(
          builder: (context, state) {
            final raw = state.failure?.message;
            final mapped = raw != null && raw.startsWith('error')
                ? talentErrorMessage(l10n, raw)
                : raw;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AuthLoginCard(
                  formKey: _formKey,
                  emailController: _email,
                  passwordController: _password,
                  onSubmit: _submit,
                  onForgot: () {
                    final email = _email.text.trim();
                    if (!email.contains('@')) {
                      getIt<NotificationService>().error(l10n.validEmailError);
                      return;
                    }
                    Navigator.of(
                      context,
                    ).pushNamed(RecoverAccessPage.routeName, arguments: email);
                  },
                  isLoading: state.status == AuthStatus.loading,
                  isSocialLoading: state.status == AuthStatus.googleLoading,
                  eyebrow: l10n.authSignInEyebrow,
                  title: l10n.secureSignIn,
                  emailLabel: l10n.workEmail,
                  emailHint: l10n.emailHint,
                  passwordLabel: l10n.password,
                  forgotText: l10n.forgotPassword,
                  submitText: l10n.signIn,
                  dividerText: l10n.continueWith,
                  socialText: l10n.signInGoogle,
                  width: double.infinity,
                  padding: EdgeInsets.all(size.cardPadding),
                  onSocialPressed:
                      state.status == AuthStatus.loading ||
                          state.status == AuthStatus.googleLoading
                      ? null
                      : () => context.read<AuthBloc>().add(
                          const AuthGoogleSignInRequested(awaitInvitePin: true),
                        ),
                  emailValidator: (value) =>
                      value == null || !value.contains('@')
                      ? l10n.validEmailError
                      : null,
                  passwordValidator: (value) => (value?.length ?? 0) < 6
                      ? l10n.passwordLengthError
                      : null,
                ),
                if (mapped != null && mapped.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text(
                    mapped,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppColors.danger,
                      fontSize: 13,
                    ),
                  ),
                ],
              ],
            );
          },
        ),
        const SizedBox(height: 20),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: EdgeInsets.only(top: 1),
              child: Icon(
                Icons.mail_outline,
                size: 16,
                color: AppColors.textDimmer,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                l10n.assessmentSignInHint,
                style: TextStyle(
                  color: AppColors.textDimmer,
                  fontSize: 13,
                  height: 1.55,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              l10n.newToTalex,
              style: TextStyle(
                color: AppColors.textMuted,
                fontSize: 13.5,
              ),
            ),
            TextButton(
              onPressed: () =>
                  Navigator.of(context).pushNamed(RegisterPage.routeName),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.green,
                padding: const EdgeInsets.symmetric(horizontal: 6),
              ),
              child: Text(l10n.createAccountLink),
            ),
          ],
        ),
        SizedBox(height: size.isCompact ? 20 : 28),
        AuthLegalFooter(
          privacyText: l10n.privacyPolicy,
          termsText: l10n.termsOfService,
        ),
      ],
    );
  }
}
