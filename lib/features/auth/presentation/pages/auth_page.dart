import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:talex_platform/core/constants/app_colors.dart';
import 'package:talex_platform/core/di/injection.dart';
import 'package:talex_platform/core/responsive/responsive_layout.dart';
import 'package:talex_platform/core/services/notification_service.dart';
import 'package:talex_platform/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:talex_platform/core/widgets/language_selector.dart';
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
    backgroundColor: AppColors.background,
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
      child: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final size = ResponsiveLayout.of(context, constraints);
            return SingleChildScrollView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minWidth: constraints.maxWidth,
                  minHeight: constraints.maxHeight,
                ),
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: size.horizontalPadding,
                    vertical: size.verticalPadding,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const Align(
                        alignment: Alignment.centerRight,
                        child: LanguageSelector(compact: true),
                      ),
                      AuthBrandHeader(
                        logoWidth: size.logoWidth,
                        logoHeight: size.logoHeight,
                      ),
                      SizedBox(height: size.isCompact ? 26 : 34),
                      Center(
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            maxWidth: size.cardMaxWidth,
                          ),
                          child: BlocBuilder<AuthBloc, AuthState>(
                            builder: (context, state) {
                              final raw = state.failure?.message;
                              final mapped = raw != null && raw.startsWith('error')
                                  ? talentErrorMessage(context.l10n, raw)
                                  : raw;
                              return Column(
                                children: [
                                  AuthLoginCard(
                              formKey: _formKey,
                              emailController: _email,
                              passwordController: _password,
                              onSubmit: _submit,
                              onForgot: () {
                                final email = _email.text.trim();
                                if (!email.contains('@')) {
                                  getIt<NotificationService>().error(
                                    context.l10n.validEmailError,
                                  );
                                  return;
                                }
                                Navigator.of(context).pushNamed(
                                  RecoverAccessPage.routeName,
                                  arguments: email,
                                );
                              },
                              isLoading: state.status == AuthStatus.loading,
                              isSocialLoading:
                                  state.status == AuthStatus.googleLoading,
                              title: context.l10n.secureSignIn,
                              emailLabel: context.l10n.workEmail,
                              emailHint: context.l10n.emailHint,
                              passwordLabel: context.l10n.password,
                              forgotText: context.l10n.forgotPassword,
                              submitText: context.l10n.signIn,
                              dividerText: context.l10n.continueWith,
                              socialText: context.l10n.signInGoogle,
                              width: double.infinity,
                              padding: EdgeInsets.all(size.cardPadding),
                              onSocialPressed:
                                  state.status == AuthStatus.loading ||
                                      state.status == AuthStatus.googleLoading
                                  ? null
                                  : () => context.read<AuthBloc>().add(
                                      const AuthGoogleSignInRequested(
                                        awaitInvitePin: true,
                                      ),
                                    ),
                              emailValidator: (value) =>
                                  value == null || !value.contains('@')
                                  ? context.l10n.validEmailError
                                  : null,
                              passwordValidator: (value) =>
                                  (value?.length ?? 0) < 6
                                  ? context.l10n.passwordLengthError
                                  : null,
                            ),
                                  if (mapped != null && mapped.isNotEmpty) ...[
                                    const SizedBox(height: 12),
                                    Text(
                                      mapped,
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(
                                        color: Color(0xFFB42318),
                                        fontSize: 13,
                                      ),
                                    ),
                                  ],
                                ],
                              );
                            },
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        context.l10n.assessmentSignInHint,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: AppColors.subtitle,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 14),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            context.l10n.newToTalex,
                            style: const TextStyle(
                              color: AppColors.subtitle,
                              fontSize: 13,
                            ),
                          ),
                          TextButton(
                            onPressed: () => Navigator.of(
                              context,
                            ).pushNamed(RegisterPage.routeName),
                            style: TextButton.styleFrom(
                              foregroundColor: AppColors.accent,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                              ),
                            ),
                            child: Text(context.l10n.createAccountLink),
                          ),
                        ],
                      ),
                      SizedBox(height: size.isCompact ? 26 : 38),
                      AuthLegalFooter(
                        privacyText: context.l10n.privacyPolicy,
                        termsText: context.l10n.termsOfService,
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    ),
  );
}
