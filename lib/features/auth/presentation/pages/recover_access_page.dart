import 'package:flutter/material.dart';
import 'package:talex_platform/core/constants/app_colors.dart';
import 'package:talex_platform/core/di/injection.dart';
import 'package:talex_platform/core/services/notification_service.dart';
import 'package:talex_platform/core/widgets/pin_entry.dart';
import 'package:talex_platform/core/widgets/talex_auth_frame.dart';
import 'package:talex_platform/features/auth/data/services/password_recovery_service.dart';
import 'package:talex_platform/features/talent/domain/services/pin_hasher.dart';
import 'package:talex_platform/features/talent/presentation/talent_error_message.dart';
import 'package:talex_platform/l10n/app_localizations.dart';
import 'package:talex_platform/l10n/l10n.dart';

class RecoverAccessPage extends StatefulWidget {
  const RecoverAccessPage({super.key, this.initialEmail = ''});
  static const routeName = '/recover';
  final String initialEmail;

  @override
  State<RecoverAccessPage> createState() => _RecoverAccessPageState();
}

enum _RecoverStep { email, pin, password, done }

class _RecoverAccessPageState extends State<RecoverAccessPage> {
  late final TextEditingController _email;
  final _pin = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  final _pinFocus = FocusNode();
  var _step = _RecoverStep.email;
  var _loading = false;
  var _obscure = true;
  String? _resetToken;

  @override
  void initState() {
    super.initState();
    _email = TextEditingController(text: widget.initialEmail);
    _pin.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _email.dispose();
    _pin.dispose();
    _password.dispose();
    _confirm.dispose();
    _pinFocus.dispose();
    super.dispose();
  }

  String _title(AppLocalizations l10n) => switch (_step) {
    _RecoverStep.email => l10n.recoverPasswordTitle,
    _RecoverStep.pin => l10n.recoverPinTitle,
    _RecoverStep.password => l10n.mustChangePasswordTitle,
    _RecoverStep.done => l10n.recoverSuccessTitle,
  };

  void _goBack() {
    if (_step == _RecoverStep.pin) {
      setState(() => _step = _RecoverStep.email);
      return;
    }
    if (_step == _RecoverStep.password) {
      setState(() => _step = _RecoverStep.pin);
      return;
    }
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
      return;
    }
    Navigator.of(context).pushReplacementNamed('/login');
  }

  Future<void> _requestPin() async {
    final l10n = context.l10n;
    final email = _email.text.trim();
    if (!email.contains('@')) {
      getIt<NotificationService>().error(l10n.validEmailError);
      return;
    }
    setState(() => _loading = true);
    final result = await getIt<PasswordRecoveryService>().requestPin(
      email: email,
      locale: Localizations.localeOf(context).languageCode,
    );
    if (!mounted) return;
    setState(() => _loading = false);
    result.fold(
      (failure) => getIt<NotificationService>().error(
        talentErrorMessage(l10n, failure.message),
      ),
      (_) {
        setState(() => _step = _RecoverStep.pin);
        getIt<NotificationService>().success(l10n.recoverPinSent);
      },
    );
  }

  Future<void> _verifyPin() async {
    final l10n = context.l10n;
    final pin = _pin.text.trim();
    if (pin.length != InvitePin.length) return;
    setState(() => _loading = true);
    final result = await getIt<PasswordRecoveryService>().verifyPin(
      email: _email.text.trim(),
      pin: pin,
    );
    if (!mounted) return;
    setState(() => _loading = false);
    result.fold(
      (failure) {
        _pin.clear();
        getIt<NotificationService>().error(
          talentErrorMessage(l10n, failure.message),
        );
      },
      (token) => setState(() {
        _resetToken = token;
        _step = _RecoverStep.password;
      }),
    );
  }

  Future<void> _complete() async {
    final l10n = context.l10n;
    final token = _resetToken;
    if (token == null) return;
    if (_password.text.length < 6) {
      getIt<NotificationService>().error(l10n.passwordLengthError);
      return;
    }
    if (_password.text != _confirm.text) {
      getIt<NotificationService>().error(l10n.passwordsDoNotMatch);
      return;
    }
    setState(() => _loading = true);
    final result = await getIt<PasswordRecoveryService>().complete(
      email: _email.text.trim(),
      resetToken: token,
      password: _password.text,
    );
    if (!mounted) return;
    setState(() => _loading = false);
    result.fold(
      (failure) => getIt<NotificationService>().error(
        talentErrorMessage(l10n, failure.message),
      ),
      (_) => setState(() => _step = _RecoverStep.done),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return TalexAuthFrame(
      title: _title(l10n),
      onBack: _goBack,
      child: switch (_step) {
        _RecoverStep.email => _emailStep(l10n),
        _RecoverStep.pin => _pinStep(l10n),
        _RecoverStep.password => _passwordStep(l10n),
        _RecoverStep.done => _doneStep(l10n),
      },
    );
  }

  Widget _emailStep(AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          l10n.recoverPasswordSubtitle,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: AppColors.textMuted,
            height: 1.45,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 24),
        TextField(
          controller: _email,
          keyboardType: TextInputType.emailAddress,
          autofillHints: const [AutofillHints.email],
          textInputAction: TextInputAction.done,
          onSubmitted: (_) {
            if (!_loading) _requestPin();
          },
          decoration: InputDecoration(
            labelText: l10n.emailAddress,
            prefixIcon: const Icon(Icons.mail_outline),
          ),
        ),
        const SizedBox(height: 24),
        FilledButton(
          onPressed: _loading ? null : _requestPin,
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.green,
            minimumSize: const Size.fromHeight(48),
          ),
          child: _loading
              ? SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.textOnGreen,
                  ),
                )
              : Text(l10n.recoverContinue),
        ),
      ],
    );
  }

  Widget _pinStep(AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          l10n.recoverPinSubtitle,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: AppColors.textMuted,
            height: 1.45,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          _email.text.trim(),
          textAlign: TextAlign.center,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: AppColors.text,
          ),
        ),
        const SizedBox(height: 24),
        PinEntry(
          controller: _pin,
          focusNode: _pinFocus,
          onComplete: _loading ? null : _verifyPin,
        ),
        const SizedBox(height: 8),
        Text(
          l10n.recoverPinHint,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: AppColors.textDimmer,
            fontSize: 13,
            height: 1.4,
          ),
        ),
        const SizedBox(height: 24),
        FilledButton(
          onPressed: _loading || _pin.text.trim().length != InvitePin.length
              ? null
              : _verifyPin,
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.green,
            minimumSize: const Size.fromHeight(48),
          ),
          child: _loading
              ? SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.textOnGreen,
                  ),
                )
              : Text(l10n.recoverVerifyPin),
        ),
        TextButton(
          onPressed: _loading ? null : _requestPin,
          child: Text(l10n.recoverResendPin),
        ),
      ],
    );
  }

  Widget _passwordStep(AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          l10n.mustChangePasswordSubtitle,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: AppColors.textMuted,
            height: 1.45,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 24),
        TextField(
          controller: _password,
          obscureText: _obscure,
          decoration: InputDecoration(
            labelText: l10n.createPassword,
            suffixIcon: IconButton(
              onPressed: () => setState(() => _obscure = !_obscure),
              icon: Icon(
                _obscure
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined,
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _confirm,
          obscureText: _obscure,
          decoration: InputDecoration(labelText: l10n.confirmPassword),
        ),
        const SizedBox(height: 24),
        FilledButton(
          onPressed: _loading ? null : _complete,
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.green,
            minimumSize: const Size.fromHeight(48),
          ),
          child: _loading
              ? SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.textOnGreen,
                  ),
                )
              : Text(l10n.recoverUpdatePassword),
        ),
      ],
    );
  }

  Widget _doneStep(AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Icon(
          Icons.check_circle_outline,
          color: AppColors.brandGreen,
          size: 56,
        ),
        const SizedBox(height: 16),
        Text(
          l10n.recoverSuccessBody,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: AppColors.textMuted,
            height: 1.45,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 24),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(),
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.green,
            minimumSize: const Size.fromHeight(48),
          ),
          child: Text(l10n.signIn),
        ),
      ],
    );
  }
}
