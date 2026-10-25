import 'package:flutter/material.dart';
import 'package:talex_platform/core/constants/app_colors.dart';

/// Visual tokens for Xebec. Colors come from the TaleX theme so the chat
/// stays on the same blue and green as the rest of the product.
abstract final class AssistantStyle {
  static const blue = AppColors.brandBlue;
  static const green = AppColors.brandGreen;
  static const ink = AppColors.ink;
  static const muted = AppColors.subtitle;
  static const canvas = AppColors.background;
  static const wash = AppColors.fieldFill;
  static const line = AppColors.softBorder;
  static const codeFill = Color(0xFFF4F7FB);
  static const userRadius = BorderRadius.only(
    topLeft: Radius.circular(18),
    topRight: Radius.circular(18),
    bottomLeft: Radius.circular(18),
    bottomRight: Radius.circular(6),
  );

  static const body = TextStyle(
    color: ink,
    fontSize: 15,
    height: 1.5,
    fontWeight: FontWeight.w400,
  );
  static const userBody = TextStyle(
    color: Colors.white,
    fontSize: 15,
    height: 1.45,
    fontWeight: FontWeight.w400,
  );
  static const meta = TextStyle(
    color: blue,
    fontSize: 12,
    height: 1.2,
    fontWeight: FontWeight.w700,
    letterSpacing: 0.2,
  );
}
