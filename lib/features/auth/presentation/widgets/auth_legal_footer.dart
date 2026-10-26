import 'package:flutter/material.dart';
import 'package:talex_platform/core/constants/app_colors.dart';
import 'package:talex_platform/core/utils/open_url.dart';

class AuthLegalFooter extends StatelessWidget {
  const AuthLegalFooter({
    super.key,
    this.privacyText = 'Privacy Policy',
    this.termsText = 'Terms of Service',
    this.onPrivacyPressed,
    this.onTermsPressed,
    this.textStyle,
    this.separator = '•',
    this.spacing = 14,
  });
  final String privacyText;
  final String termsText;
  final VoidCallback? onPrivacyPressed;
  final VoidCallback? onTermsPressed;
  final TextStyle? textStyle;
  final String separator;
  final double spacing;
  @override
  Widget build(BuildContext context) {
    final style =
        textStyle ??
        TextStyle(
          color: AppColors.textDimmer,
          fontSize: 13,
          fontWeight: FontWeight.w500,
        );
    return Wrap(
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        TextButton(
          onPressed:
              onPrivacyPressed ??
              () => openExternalUrl('https://www.talex.com.co/privacidad'),
          style: TextButton.styleFrom(
            padding: EdgeInsets.zero,
            minimumSize: Size.zero,
            textStyle: style,
            foregroundColor: style.color,
          ),
          child: Text(privacyText),
        ),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: spacing),
          child: Text(
            separator,
            style: TextStyle(color: AppColors.textDimmer),
          ),
        ),
        TextButton(
          onPressed:
              onTermsPressed ??
              () => openExternalUrl('https://www.talex.com.co/terminos'),
          style: TextButton.styleFrom(
            padding: EdgeInsets.zero,
            minimumSize: Size.zero,
            textStyle: style,
            foregroundColor: style.color,
          ),
          child: Text(termsText),
        ),
      ],
    );
  }
}
