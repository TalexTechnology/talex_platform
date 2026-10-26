import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:talex_platform/core/constants/app_colors.dart';
import 'package:talex_platform/core/di/injection.dart';
import 'package:talex_platform/core/services/notification_service.dart';
import 'package:talex_platform/core/widgets/talex_auth_frame.dart';
import 'package:talex_platform/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:talex_platform/features/talent/presentation/bloc/talent_bloc.dart';
import 'package:talex_platform/features/talent/presentation/talent_error_message.dart';
import 'package:talex_platform/l10n/l10n.dart';

class TalentPasswordPage extends StatefulWidget {
  const TalentPasswordPage({super.key});
  @override
  State<TalentPasswordPage> createState() => _TalentPasswordPageState();
}

class _TalentPasswordPageState extends State<TalentPasswordPage> {
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  var _obscure = true;

  @override
  void dispose() {
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  void _submit() {
    final l10n = context.l10n;
    if (_password.text.length < 6) {
      getIt<NotificationService>().error(l10n.passwordLengthError);
      return;
    }
    if (_password.text != _confirm.text) {
      getIt<NotificationService>().error(l10n.passwordsDoNotMatch);
      return;
    }
    context.read<TalentBloc>().add(TalentPasswordChanged(_password.text));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return BlocListener<TalentBloc, TalentState>(
      listenWhen: (previous, current) =>
          current.passwordChanged || previous.failure != current.failure,
      listener: (context, state) {
        if (state.failure != null) {
          getIt<NotificationService>().error(
            talentErrorMessage(context.l10n, state.failure!.message),
          );
        }
        if (state.passwordChanged) {
          context.read<AuthBloc>().add(const AuthSessionRequested());
        }
      },
      child: TalexAuthFrame(
        title: l10n.mustChangePasswordTitle,
        onBack: () => context.read<AuthBloc>().add(const AuthSignOutRequested()),
        child: Column(
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
            const SizedBox(height: 28),
            FilledButton(
              onPressed: _submit,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.green,
                minimumSize: const Size.fromHeight(48),
              ),
              child: Text(l10n.continueAction),
            ),
          ],
        ),
      ),
    );
  }
}
