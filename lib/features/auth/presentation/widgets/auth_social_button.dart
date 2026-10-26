import 'package:flutter/material.dart';
import 'package:talex_platform/core/constants/app_colors.dart';
import 'package:talex_platform/core/constants/app_radii.dart';

class AuthSocialButton extends StatelessWidget {
  const AuthSocialButton({
    super.key,
    required this.label,
    required this.onPressed,
    required this.icon,
    this.isLoading = false,
    this.height = 48,
    this.foregroundColor,
    this.borderColor,
    this.backgroundColor = Colors.transparent,
  });
  final String label;
  final VoidCallback? onPressed;
  final Widget icon;
  final bool isLoading;
  final double height;
  final Color? foregroundColor;
  final Color? borderColor;
  final Color backgroundColor;
  @override
  Widget build(BuildContext context) => SizedBox(
    height: height,
    child: OutlinedButton.icon(
      onPressed: onPressed,
      icon: isLoading
          ? const SizedBox.square(
              dimension: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : icon,
      label: Text(label),
      style: OutlinedButton.styleFrom(
        backgroundColor: backgroundColor,
        foregroundColor: (foregroundColor ?? AppColors.text),
        side: BorderSide(color: (borderColor ?? AppColors.borderStrong)),
        shape: AppRadii.shape,
        textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
      ),
    ),
  );
}

class GoogleMark extends StatelessWidget {
  const GoogleMark({super.key, this.size = 20});
  final double size;
  @override
  Widget build(BuildContext context) => Container(
    width: size + 6,
    height: size + 6,
    alignment: Alignment.center,
    decoration: const BoxDecoration(
      color: Colors.white,
      shape: BoxShape.circle,
    ),
    child: Text(
      'G',
      style: TextStyle(
        // Azul oficial de Google: es su marca, no un color de TaleX.
        color: const Color(0xFF4285F4),
        fontSize: size * 0.72,
        height: 1,
        fontWeight: FontWeight.w700,
        fontFamily: 'Arial',
      ),
    ),
  );
}
