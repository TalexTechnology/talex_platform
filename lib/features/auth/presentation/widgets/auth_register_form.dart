import 'package:flutter/material.dart';
import 'package:talex_platform/core/constants/app_colors.dart';
import 'package:talex_platform/core/constants/app_radii.dart';
import 'package:talex_platform/features/auth/presentation/widgets/auth_field.dart';
import 'package:talex_platform/features/auth/presentation/widgets/auth_social_button.dart';

class AuthRegisterForm extends StatelessWidget {
  const AuthRegisterForm({
    super.key,
    required this.formKey,
    required this.nameController,
    required this.emailController,
    required this.pinController,
    required this.passwordController,
    required this.confirmPasswordController,
    required this.onSubmit,
    required this.onLogin,
    this.onGoogleSignUp,
    this.isLoading = false,
    this.isGoogleLoading = false,
    this.title = 'Create your account',
    this.subtitle = 'Create your account to get started with TaleX.',
    this.nameLabel = 'Full Name',
    this.nameHint = 'Jane Doe',
    this.emailLabel = 'Email address',
    this.emailHint = 'jane@company.com',
    this.pinLabel = 'Invitation PIN',
    this.pinHint = '6-digit PIN',
    this.passwordLabel = 'Password',
    this.confirmPasswordLabel = 'Confirm password',
    this.submitText = 'Sign up',
    this.dividerText = 'Or continue with',
    this.googleSignUpText = 'Sign up with Google',
    this.accountPrompt = 'Already have an account?',
    this.loginText = 'Log in',
    this.requiredError = 'This field is required',
    this.emailError = 'Enter a valid email',
    this.passwordError = 'At least 6 characters',
    this.passwordMismatchError = 'The passwords do not match.',
  });
  final GlobalKey<FormState> formKey;
  final TextEditingController nameController,
      emailController,
      pinController,
      passwordController,
      confirmPasswordController;
  final VoidCallback onSubmit, onLogin;
  final VoidCallback? onGoogleSignUp;
  final bool isLoading, isGoogleLoading;
  final String title,
      subtitle,
      nameLabel,
      nameHint,
      emailLabel,
      emailHint,
      pinLabel,
      pinHint,
      passwordLabel,
      confirmPasswordLabel,
      submitText,
      dividerText,
      googleSignUpText,
      accountPrompt,
      loginText,
      requiredError,
      emailError,
      passwordError,
      passwordMismatchError;

  @override
  Widget build(BuildContext context) => Form(
    key: formKey,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          title,
          style: TextStyle(
            color: AppColors.text,
            fontSize: 30,
            height: 1.1,
            fontWeight: FontWeight.w700,
            letterSpacing: -1,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          subtitle,
          style: TextStyle(
            color: AppColors.textMuted,
            fontSize: 15.5,
            height: 1.6,
          ),
        ),
        const SizedBox(height: 28),
        _field(nameLabel, nameHint, nameController, validator: _required),
        const SizedBox(height: 18),
        _field(
          emailLabel,
          emailHint,
          emailController,
          keyboardType: TextInputType.emailAddress,
          validator: (value) =>
              value == null || !value.contains('@') ? emailError : null,
        ),
        const SizedBox(height: 18),
        _field(
          pinLabel,
          pinHint,
          pinController,
          keyboardType: TextInputType.number,
          validator: (value) =>
              (value?.trim().length ?? 0) != 6 ? pinHint : null,
        ),
        const SizedBox(height: 18),
        _field(
          passwordLabel,
          '••••••••',
          passwordController,
          obscureText: true,
          validator: (value) => (value?.length ?? 0) < 6 ? passwordError : null,
        ),
        const SizedBox(height: 18),
        _field(
          confirmPasswordLabel,
          '••••••••',
          confirmPasswordController,
          obscureText: true,
          validator: (value) =>
              value != passwordController.text ? passwordMismatchError : null,
          onSubmitted: (_) => onSubmit(),
        ),
        const SizedBox(height: 32),
        SizedBox(
          height: 48,
          child: FilledButton(
            onPressed: isLoading || isGoogleLoading ? null : onSubmit,
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.green,
              disabledBackgroundColor: AppColors.green,
              shape: AppRadii.shape,
            ),
            child: isLoading
                ? SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.textOnGreen,
                    ),
                  )
                : Text(submitText),
          ),
        ),
        const SizedBox(height: 24),
        Row(
          children: [
            Expanded(child: Divider(color: AppColors.border)),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Text(
                dividerText,
                style: TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Expanded(child: Divider(color: AppColors.border)),
          ],
        ),
        const SizedBox(height: 20),
        AuthSocialButton(
          label: googleSignUpText,
          onPressed: isLoading || isGoogleLoading ? null : onGoogleSignUp,
          icon: const GoogleMark(),
          isLoading: isGoogleLoading,
          height: 44,
        ),
        const SizedBox(height: 18),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Flexible(
              child: Text(
                accountPrompt,
                style: TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 15,
                ),
              ),
            ),
            TextButton(
              onPressed: onLogin,
              style: TextButton.styleFrom(foregroundColor: AppColors.blue),
              child: Text(loginText),
            ),
          ],
        ),
      ],
    ),
  );

  String? _required(String? value) =>
      value == null || value.trim().isEmpty ? requiredError : null;

  Widget _field(
    String label,
    String hint,
    TextEditingController controller, {
    TextInputType? keyboardType,
    bool obscureText = false,
    FormFieldValidator<String>? validator,
    ValueChanged<String>? onSubmitted,
  }) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      AuthFieldLabel(label),
      const SizedBox(height: 8),
      AuthField(
        controller: controller,
        hint: hint,
        keyboardType: keyboardType,
        obscureText: obscureText,
        validator: validator,
        onSubmitted: onSubmitted,
        height: 45,
      ),
    ],
  );
}
