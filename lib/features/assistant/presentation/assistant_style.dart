import 'package:flutter/material.dart';
import 'package:talex_platform/core/constants/app_colors.dart';

/// Visual tokens for Xebec. Colors come from the TaleX theme so the chat
/// stays on the same blue and green as the rest of the product.
abstract final class AssistantStyle {
  static Color get blue => AppColors.blue;
  static Color get green => AppColors.green;
  static Color get ink => AppColors.text;
  static Color get muted => AppColors.textMuted;
  static Color get canvas => AppColors.bgAlt;
  static Color get wash => AppColors.surface;
  static Color get line => AppColors.border;
  static Color get codeFill => AppColors.bg;
  static Color get bubble => AppColors.brandBlue;
  static const userRadius = BorderRadius.only(
    topLeft: Radius.circular(18),
    topRight: Radius.circular(18),
    bottomLeft: Radius.circular(18),
    bottomRight: Radius.circular(6),
  );

  static TextStyle get body => TextStyle(
    color: ink,
    fontSize: 15,
    height: 1.5,
    fontWeight: FontWeight.w400,
  );
  static TextStyle get userBody => TextStyle(
    color: Colors.white,
    fontSize: 15,
    height: 1.45,
    fontWeight: FontWeight.w400,
  );
  static TextStyle get meta => TextStyle(
    color: blue,
    fontSize: 12,
    height: 1.2,
    fontWeight: FontWeight.w700,
    letterSpacing: 0.2,
  );
}
