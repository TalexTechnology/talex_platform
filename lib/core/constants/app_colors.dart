import 'package:flutter/material.dart';

// Tokens de marca de TaleX, los mismos de la landing (src/styles/tokens.css).
// Regla central: azul = empresa · verde = candidato · donde se cruzan = el fit.
// Nunca uses un hex suelto en un widget: usa el token.
//
// Cada token existe en versión oscura (la de la landing) y clara. Los widgets
// leen [AppColors], que apunta a la paleta del tema activo; [ThemeCubit] la
// cambia y reconstruye la app.
@immutable
class TalexPalette {
  const TalexPalette._({
    required this.brightness,
    required this.brandBlue,
    required this.brandGreen,
    required this.brandSlate,
    required this.blue,
    required this.blueDim,
    required this.green,
    required this.greenHover,
    required this.greenDim,
    required this.slate,
    required this.company,
    required this.candidate,
    required this.good,
    required this.warning,
    required this.warningDim,
    required this.danger,
    required this.dangerDim,
    required this.bg,
    required this.bgAlt,
    required this.bgRaised,
    required this.bgOverlay,
    required this.surface,
    required this.surface2,
    required this.border,
    required this.borderStrong,
    required this.text,
    required this.textMuted,
    required this.textDimmer,
    required this.textOnGreen,
    required this.shadow,
    required this.scrim,
    required this.logoBackdrop,
  });

  final Brightness brightness;
  final Color brandBlue;
  final Color brandGreen;
  final Color brandSlate;
  final Color blue;
  final Color blueDim;
  final Color green;
  final Color greenHover;
  final Color greenDim;
  final Color slate;
  final Color company;
  final Color candidate;
  final Color good;
  final Color warning;
  final Color warningDim;
  final Color danger;
  final Color dangerDim;
  final Color bg;
  final Color bgAlt;
  final Color bgRaised;
  final Color bgOverlay;
  final Color surface;
  final Color surface2;
  final Color border;
  final Color borderStrong;
  final Color text;
  final Color textMuted;
  final Color textDimmer;
  final Color textOnGreen;
  final Color shadow;
  final Color scrim;
  final Color logoBackdrop;

  bool get isDark => brightness == Brightness.dark;

  static const dark = TalexPalette._(
    brightness: Brightness.dark,
    brandBlue: Color(0xFF3573DE),
    brandGreen: Color(0xFFA4E765),
    brandSlate: Color(0xFF7E94B3),
    blue: Color(0xFF6FA0F5),
    blueDim: Color(0x244F8BF0),
    green: Color(0xFFA4E765),
    greenHover: Color(0xFFB5EE80),
    greenDim: Color(0x1FA4E765),
    slate: Color(0xFF7E94B3),
    company: Color(0xFF4F8BF0),
    candidate: Color(0xFF64A82F),
    good: Color(0xFFA4E765),
    warning: Color(0xFFF2B84B),
    warningDim: Color(0x24F2B84B),
    danger: Color(0xFFF2777A),
    dangerDim: Color(0x24F2777A),
    bg: Color(0xFF0B1528),
    bgAlt: Color(0xFF0F1C33),
    bgRaised: Color(0xFF13223D),
    bgOverlay: Color(0xFF182A49),
    surface: Color(0x0BFFFFFF),
    surface2: Color(0x13FFFFFF),
    border: Color(0x17FFFFFF),
    borderStrong: Color(0x29FFFFFF),
    text: Color(0xFFEEF1F6),
    textMuted: Color(0xA3EEF1F6),
    textDimmer: Color(0x6BEEF1F6),
    textOnGreen: Color(0xFF0B1528),
    shadow: Color(0x66000000),
    scrim: Color(0xB30B1528),
    logoBackdrop: Color(0xFFEEF1F6),
  );

  static const light = TalexPalette._(
    brightness: Brightness.light,
    brandBlue: Color(0xFF3573DE),
    brandGreen: Color(0xFFA4E765),
    brandSlate: Color(0xFF7E94B3),
    blue: Color(0xFF2F64C9),
    blueDim: Color(0x1A3573DE),
    green: Color(0xFF3F8A1C),
    greenHover: Color(0xFF4A9A22),
    greenDim: Color(0x1A3F8A1C),
    slate: Color(0xFF5B6F8C),
    company: Color(0xFF3573DE),
    candidate: Color(0xFF4E8F1F),
    good: Color(0xFF3F8A1C),
    warning: Color(0xFFB06A0A),
    warningDim: Color(0x1FB06A0A),
    danger: Color(0xFFC23B3B),
    dangerDim: Color(0x1AC23B3B),
    bg: Color(0xFFF5F7FB),
    bgAlt: Color(0xFFFFFFFF),
    bgRaised: Color(0xFFFFFFFF),
    bgOverlay: Color(0xFFFFFFFF),
    surface: Color(0x0A0B1528),
    surface2: Color(0x120B1528),
    border: Color(0x1A0B1528),
    borderStrong: Color(0x2E0B1528),
    text: Color(0xFF0B1528),
    textMuted: Color(0xB30B1528),
    textDimmer: Color(0x8C0B1528),
    textOnGreen: Color(0xFFFFFFFF),
    shadow: Color(0x1F0B1528),
    scrim: Color(0xB3F5F7FB),
    logoBackdrop: Color(0xFFFFFFFF),
  );
}

abstract final class AppColors {
  static TalexPalette _palette = TalexPalette.dark;

  /// Paleta activa. Solo la cambia [ThemeCubit] con [use].
  static TalexPalette get palette => _palette;

  static void use(TalexPalette palette) => _palette = palette;

  static bool get isDark => _palette.isDark;

  // Marca (logo).
  static Color get brandBlue => _palette.brandBlue;
  static Color get brandGreen => _palette.brandGreen;
  static Color get brandSlate => _palette.brandSlate;

  // Acentos de UI: texto, íconos y enlaces.
  static Color get blue => _palette.blue;
  static Color get blueDim => _palette.blueDim;
  static Color get green => _palette.green;
  static Color get greenHover => _palette.greenHover;
  static Color get greenDim => _palette.greenDim;
  static Color get slate => _palette.slate;

  // Gráficos: empresa vs. candidato.
  static Color get company => _palette.company;
  static Color get candidate => _palette.candidate;

  // Estados (siempre acompañados de ícono + texto).
  static Color get good => _palette.good;
  static Color get warning => _palette.warning;
  static Color get warningDim => _palette.warningDim;
  static Color get danger => _palette.danger;
  static Color get dangerDim => _palette.dangerDim;

  // Fondo y superficies.
  static Color get bg => _palette.bg;
  static Color get bgAlt => _palette.bgAlt;
  static Color get bgRaised => _palette.bgRaised;
  static Color get bgOverlay => _palette.bgOverlay;
  static Color get surface => _palette.surface;
  static Color get surface2 => _palette.surface2;
  static Color get border => _palette.border;
  static Color get borderStrong => _palette.borderStrong;

  // Texto.
  static Color get text => _palette.text;
  static Color get textMuted => _palette.textMuted;
  static Color get textDimmer => _palette.textDimmer;
  static Color get textOnGreen => _palette.textOnGreen;

  // Sombras y velos.
  static Color get shadow => _palette.shadow;
  static Color get scrim => _palette.scrim;

  // Recuadro claro tras los logos de empresas (vienen pensados para fondo claro).
  static Color get logoBackdrop => _palette.logoBackdrop;
}

// Paleta clara anterior. Solo la usan los formularios de preguntas de las
// encuestas (afinidad y cultura), que no forman parte del rediseño.
abstract final class LegacyColors {
  static const ink = Color(0xFF071326);
  static const muted = Color(0xFF76777C);
  static const brandBlue = Color(0xFF1D7BD6);
  static const brandGreen = Color(0xFF8DC53F);
  static const background = Color(0xFFFBF9FA);
  static const subtitle = Color(0xFF45464A);
  static const border = Color(0xFFBFC1C8);
  static const fieldFill = Color(0xFFF3F8FD);
  static const fieldBorder = Color(0xFFC5DCF0);
  static const softBorder = Color(0xFFDEDEDE);
  static const danger = Color(0xFFB42318);
}
