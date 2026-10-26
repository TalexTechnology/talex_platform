import 'package:flutter/material.dart';
import 'package:talex_platform/core/constants/app_colors.dart';
import 'package:talex_platform/core/constants/app_icons.dart';
import 'package:talex_platform/core/constants/app_radii.dart';
import 'package:talex_platform/core/widgets/talex_ui.dart';
import 'package:talex_platform/features/auth/presentation/widgets/auth_field.dart';
import 'package:talex_platform/features/auth/presentation/widgets/auth_social_button.dart';

class AuthLoginCard extends StatelessWidget {
  const AuthLoginCard({
    super.key,
    required this.formKey,
    required this.emailController,
    required this.passwordController,
    required this.onSubmit,
    required this.onForgot,
    this.isLoading = false,
    this.isSocialLoading = false,
    this.onSocialPressed,
    this.title = 'Secure Sign In',
    this.emailLabel = 'Email address',
    this.emailHint = 'email@example.com',
    this.passwordLabel = 'Password',
    this.passwordHint = '••••••••',
    this.forgotText = 'Forgot password?',
    this.submitText = 'Sign In',
    this.dividerText = 'Or continue with',
    this.socialText = 'Sign in with Google',
    this.width = 448,
    this.padding = const EdgeInsets.fromLTRB(32, 36, 32, 32),
    this.backgroundColor,
    this.borderColor,
    this.submitColor,
    this.eyebrow,
    this.emailValidator,
    this.passwordValidator,
    this.socialIcon = const GoogleMark(),
  });
  final GlobalKey<FormState> formKey;
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final VoidCallback onSubmit;
  final VoidCallback onForgot;
  final VoidCallback? onSocialPressed;
  final bool isLoading;
  final bool isSocialLoading;
  final String title,
      emailLabel,
      emailHint,
      passwordLabel,
      passwordHint,
      forgotText,
      submitText,
      dividerText,
      socialText;
  final double width;
  final EdgeInsetsGeometry padding;
  final Color? backgroundColor, borderColor, submitColor;
  final FormFieldValidator<String>? emailValidator;
  final FormFieldValidator<String>? passwordValidator;
  final Widget socialIcon;
  final String? eyebrow;

  @override
  Widget build(BuildContext context) => Container(
    width: width,
    padding: padding,
    decoration: BoxDecoration(
      color: (backgroundColor ?? AppColors.bgRaised),
      borderRadius: AppRadii.card,
      border: Border.all(color: (borderColor ?? AppColors.border)),
      boxShadow: [
        BoxShadow(
          color: AppColors.shadow,
          blurRadius: 48,
          offset: Offset(0, 24),
        ),
      ],
    ),
    child: Form(
      key: formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (eyebrow != null) ...[
            TalexEyebrow(eyebrow!),
            const SizedBox(height: 12),
          ],
          Text(
            title,
            style: TextStyle(
              color: AppColors.text,
              fontSize: 28,
              fontWeight: FontWeight.w700,
              letterSpacing: -.9,
            ),
          ),
          const SizedBox(height: 28),
          AuthFieldLabel(emailLabel),
          const SizedBox(height: 8),
          AuthField(
            controller: emailController,
            hint: emailHint,
            icon: AppIcons.email,
            keyboardType: TextInputType.emailAddress,
            validator: emailValidator,
          ),
          const SizedBox(height: 22),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              AuthFieldLabel(passwordLabel),
              TextButton(
                onPressed: onForgot,
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.blue,
                  padding: EdgeInsets.zero,
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  textStyle: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                child: Text(forgotText),
              ),
            ],
          ),
          const SizedBox(height: 8),
          AuthField(
            controller: passwordController,
            hint: passwordHint,
            icon: AppIcons.password,
            obscureText: true,
            onSubmitted: (_) => onSubmit(),
            validator: passwordValidator,
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 48,
            child: FilledButton(
              onPressed: isLoading ? null : onSubmit,
              style: FilledButton.styleFrom(
                backgroundColor: (submitColor ?? AppColors.green),
                disabledBackgroundColor: (submitColor ?? AppColors.green),
              ),
              child: isLoading
                  ? SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.textOnGreen,
                      ),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(submitText),
                        const SizedBox(width: 8),
                        const Icon(Icons.arrow_forward, size: 18),
                      ],
                    ),
            ),
          ),
          const SizedBox(height: 25),
          Row(
            children: [
              Expanded(child: Divider(color: AppColors.border)),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 9),
                child: Text(
                  dividerText,
                  style: TextStyle(
                    color: AppColors.textDimmer,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              Expanded(child: Divider(color: AppColors.border)),
            ],
          ),
          const SizedBox(height: 24),
          AuthSocialButton(
            label: socialText,
            onPressed: isSocialLoading ? null : onSocialPressed,
            icon: socialIcon,
            isLoading: isSocialLoading,
          ),
        ],
      ),
    ),
  );
}
