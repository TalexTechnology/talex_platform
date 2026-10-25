import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:talex_platform/core/constants/app_colors.dart';
import 'package:talex_platform/core/di/injection.dart';
import 'package:talex_platform/core/services/notification_service.dart';
import 'package:talex_platform/core/widgets/pin_entry.dart';
import 'package:talex_platform/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:talex_platform/features/auth/presentation/widgets/auth_widgets.dart';
import 'package:talex_platform/features/talent/domain/services/pin_hasher.dart';
import 'package:talex_platform/features/talent/presentation/talent_error_message.dart';
import 'package:talex_platform/l10n/l10n.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});
  static const routeName = '/register';
  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _pin = TextEditingController();
  final _password = TextEditingController();
  final _confirmPassword = TextEditingController();
  final _googlePin = TextEditingController();
  final _googlePinFocus = FocusNode();

  var _googlePinStep = false;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _pin.dispose();
    _password.dispose();
    _confirmPassword.dispose();
    _googlePin.dispose();
    _googlePinFocus.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    context.read<AuthBloc>().add(
      AuthSignUpRequested(
        email: _email.text.trim(),
        password: _password.text,
        displayName: _name.text.trim(),
        pin: _pin.text.trim(),
      ),
    );
  }

  void _submitGooglePin() {
    final pin = _googlePin.text.trim();
    if (pin.length != InvitePin.length) return;
    context.read<AuthBloc>().add(AuthInvitePinSubmitted(pin));
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppColors.white,
    body: BlocConsumer<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state.status == AuthStatus.needsInvitePin) {
          setState(() => _googlePinStep = true);
        }
        if (state.status == AuthStatus.unauthenticated) {
          setState(() => _googlePinStep = false);
        }
        if (state.status == AuthStatus.authenticated) {
          Navigator.of(context).popUntil((route) => route.isFirst);
        }
        if (state.failure case final failure?) {
          getIt<NotificationService>().error(
            talentErrorMessage(context.l10n, failure.message),
          );
        }
      },
      builder: (context, state) {
        final waitingPin =
            _googlePinStep || state.status == AuthStatus.needsInvitePin;
        return SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final desktop = constraints.maxWidth >= 900;
              final form = waitingPin
                  ? _GooglePinStep(
                      controller: _googlePin,
                      focusNode: _googlePinFocus,
                      loading: state.status == AuthStatus.loading,
                      onSubmit: _submitGooglePin,
                      onBack: () => context.read<AuthBloc>().add(
                        const AuthSignOutRequested(),
                      ),
                    )
                  : AuthRegisterForm(
                      formKey: _formKey,
                      nameController: _name,
                      emailController: _email,
                      pinController: _pin,
                      passwordController: _password,
                      confirmPasswordController: _confirmPassword,
                      onSubmit: _submit,
                      onLogin: () => Navigator.of(context).pop(),
                      onGoogleSignUp: () {
                        _googlePin.text = _pin.text.trim();
                        context.read<AuthBloc>().add(
                          const AuthGoogleSignInRequested(awaitInvitePin: true),
                        );
                      },
                      isLoading: state.status == AuthStatus.loading,
                      isGoogleLoading: state.status == AuthStatus.googleLoading,
                      title: context.l10n.createAccount,
                      subtitle: context.l10n.registerSubtitle,
                      nameLabel: context.l10n.fullName,
                      nameHint: context.l10n.fullNameHint,
                      emailLabel: context.l10n.workEmail,
                      emailHint: context.l10n.emailHint,
                      pinLabel: context.l10n.activationPin,
                      pinHint: context.l10n.registerPinHint,
                      passwordLabel: context.l10n.password,
                      confirmPasswordLabel: context.l10n.confirmPassword,
                      submitText: context.l10n.signUp,
                      dividerText: context.l10n.continueWith,
                      googleSignUpText: context.l10n.signUpGoogle,
                      accountPrompt: context.l10n.alreadyHaveAccount,
                      loginText: context.l10n.logIn,
                      requiredError: context.l10n.requiredField,
                      emailError: context.l10n.validEmailError,
                      passwordError: context.l10n.passwordLengthError,
                      passwordMismatchError: context.l10n.passwordsDoNotMatch,
                    );
              if (!desktop) {
                return SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 32,
                  ),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 520),
                      child: form,
                    ),
                  ),
                );
              }
              return Row(
                children: [
                  Expanded(
                    child: AuthTestimonialPanel(
                      quote: context.l10n.testimonial,
                    ),
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 64,
                        vertical: 48,
                      ),
                      child: Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 520),
                          child: form,
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        );
      },
    ),
  );
}

class _GooglePinStep extends StatelessWidget {
  const _GooglePinStep({
    required this.controller,
    required this.focusNode,
    required this.loading,
    required this.onSubmit,
    required this.onBack,
  });
  final TextEditingController controller;
  final FocusNode focusNode;
  final bool loading;
  final VoidCallback onSubmit;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          l10n.googlePinTitle,
          style: const TextStyle(
            color: AppColors.ink,
            fontSize: 34,
            fontWeight: FontWeight.w700,
            letterSpacing: -1,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          l10n.googlePinSubtitle,
          style: const TextStyle(color: AppColors.subtitle, fontSize: 16),
        ),
        const SizedBox(height: 28),
        PinEntry(controller: controller, focusNode: focusNode, onComplete: onSubmit),
        const SizedBox(height: 8),
        Text(
          l10n.activatePinHint,
          style: const TextStyle(color: AppColors.muted, fontSize: 13),
        ),
        const SizedBox(height: 32),
        SizedBox(
          height: 44,
          child: FilledButton(
            onPressed: loading ? null : onSubmit,
            child: loading
                ? const SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : Text(l10n.activateAccount),
          ),
        ),
        const SizedBox(height: 12),
        TextButton(onPressed: loading ? null : onBack, child: Text(l10n.goBack)),
      ],
    );
  }
}
