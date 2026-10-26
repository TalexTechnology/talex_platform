import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:talex_platform/core/constants/app_colors.dart';
import 'package:talex_platform/core/constants/app_radii.dart';

// Tema de TaleX, alineado con la landing: superficies elevadas con borde
// sutil, verde de marca para la acción principal e Inter en todo. Se arma con
// la paleta activa de [AppColors] (oscura o clara).
ThemeData talexTheme() {
  final brightness = AppColors.palette.brightness;
  final control = RoundedRectangleBorder(borderRadius: AppRadii.border);
  final card = RoundedRectangleBorder(
    borderRadius: AppRadii.card,
    side: BorderSide(color: AppColors.border),
  );
  final scheme = ColorScheme(
    brightness: brightness,
    primary: AppColors.green,
    onPrimary: AppColors.textOnGreen,
    primaryContainer: AppColors.greenDim,
    onPrimaryContainer: AppColors.green,
    secondary: AppColors.blue,
    onSecondary: AppColors.bg,
    secondaryContainer: AppColors.blueDim,
    onSecondaryContainer: AppColors.blue,
    tertiary: AppColors.warning,
    onTertiary: AppColors.bg,
    error: AppColors.danger,
    onError: AppColors.bg,
    errorContainer: AppColors.dangerDim,
    onErrorContainer: AppColors.danger,
    surface: AppColors.bg,
    onSurface: AppColors.text,
    onSurfaceVariant: AppColors.textMuted,
    surfaceContainerLowest: AppColors.bg,
    surfaceContainerLow: AppColors.bgAlt,
    surfaceContainer: AppColors.bgRaised,
    surfaceContainerHigh: AppColors.bgRaised,
    surfaceContainerHighest: AppColors.bgOverlay,
    surfaceTint: Colors.transparent,
    outline: AppColors.borderStrong,
    outlineVariant: AppColors.border,
    inverseSurface: AppColors.text,
    onInverseSurface: AppColors.bg,
    inversePrimary: AppColors.candidate,
    shadow: AppColors.shadow,
    scrim: AppColors.scrim,
  );
  final base = ThemeData(
    useMaterial3: true,
    brightness: brightness,
    colorScheme: scheme,
  );
  final text = GoogleFonts.interTextTheme(
    base.textTheme,
  ).apply(bodyColor: AppColors.text, displayColor: AppColors.text);
  OutlineInputBorder field(Color color, [double width = 1]) =>
      OutlineInputBorder(
        borderRadius: AppRadii.border,
        borderSide: BorderSide(color: color, width: width),
      );
  const buttonText = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    letterSpacing: 0,
  );
  const buttonPadding = EdgeInsets.symmetric(horizontal: 22, vertical: 16);
  return base.copyWith(
    textTheme: text,
    primaryTextTheme: text,
    scaffoldBackgroundColor: AppColors.bg,
    canvasColor: AppColors.bg,
    dividerColor: AppColors.border,
    splashFactory: InkSparkle.splashFactory,
    hoverColor: AppColors.surface,
    highlightColor: Colors.transparent,
    focusColor: AppColors.surface2,
    iconTheme: IconThemeData(color: AppColors.textMuted),
    dividerTheme: DividerThemeData(
      color: AppColors.border,
      thickness: 1,
      space: 1,
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: AppColors.bg,
      foregroundColor: AppColors.text,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      shape: Border(bottom: BorderSide(color: AppColors.border)),
      titleTextStyle: text.titleMedium?.copyWith(fontWeight: FontWeight.w600),
    ),
    cardTheme: CardThemeData(
      color: AppColors.bgRaised,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      shape: card,
      margin: EdgeInsets.zero,
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: AppColors.bgRaised,
      surfaceTintColor: Colors.transparent,
      shape: card,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      titleTextStyle: text.titleLarge?.copyWith(
        fontWeight: FontWeight.w700,
        letterSpacing: -0.4,
      ),
      contentTextStyle: text.bodyMedium?.copyWith(
        color: AppColors.textMuted,
        height: 1.6,
      ),
    ),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: AppColors.bgRaised,
      surfaceTintColor: Colors.transparent,
      modalBackgroundColor: AppColors.bgRaised,
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.green,
        foregroundColor: AppColors.textOnGreen,
        disabledBackgroundColor: AppColors.surface2,
        disabledForegroundColor: AppColors.textDimmer,
        shape: control,
        textStyle: buttonText,
        padding: buttonPadding,
        minimumSize: const Size(0, 46),
      ).copyWith(overlayColor: const WidgetStatePropertyAll(Color(0x14FFFFFF))),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.surface2,
        foregroundColor: AppColors.text,
        elevation: 0,
        shape: control,
        textStyle: buttonText,
        padding: buttonPadding,
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.text,
        disabledForegroundColor: AppColors.textDimmer,
        side: BorderSide(color: AppColors.borderStrong),
        shape: control,
        textStyle: buttonText,
        padding: buttonPadding,
        minimumSize: const Size(0, 46),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: AppColors.blue,
        disabledForegroundColor: AppColors.textDimmer,
        shape: control,
        textStyle: buttonText,
      ),
    ),
    iconButtonTheme: IconButtonThemeData(
      style: IconButton.styleFrom(
        foregroundColor: AppColors.textMuted,
        highlightColor: AppColors.surface2,
      ),
    ),
    segmentedButtonTheme: SegmentedButtonThemeData(
      style: SegmentedButton.styleFrom(
        foregroundColor: AppColors.textMuted,
        selectedForegroundColor: AppColors.textOnGreen,
        selectedBackgroundColor: AppColors.green,
        side: BorderSide(color: AppColors.borderStrong),
        shape: control,
        textStyle: buttonText,
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.surface,
      hoverColor: AppColors.surface2,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      labelStyle: TextStyle(color: AppColors.textMuted),
      floatingLabelStyle: TextStyle(color: AppColors.blue),
      hintStyle: TextStyle(color: AppColors.textDimmer),
      helperStyle: TextStyle(color: AppColors.textDimmer),
      prefixIconColor: AppColors.textDimmer,
      suffixIconColor: AppColors.textDimmer,
      errorStyle: TextStyle(color: AppColors.danger),
      border: field(AppColors.border),
      enabledBorder: field(AppColors.border),
      disabledBorder: field(AppColors.border),
      focusedBorder: field(AppColors.blue, 1.5),
      errorBorder: field(AppColors.danger),
      focusedErrorBorder: field(AppColors.danger, 1.5),
    ),
    textSelectionTheme: TextSelectionThemeData(
      cursorColor: AppColors.green,
      selectionColor: AppColors.blueDim,
      selectionHandleColor: AppColors.green,
    ),
    chipTheme: ChipThemeData(
      backgroundColor: AppColors.surface,
      selectedColor: AppColors.greenDim,
      disabledColor: AppColors.surface,
      side: BorderSide(color: AppColors.border),
      shape: const StadiumBorder(),
      labelStyle: text.labelMedium?.copyWith(color: AppColors.text),
      secondaryLabelStyle: text.labelMedium?.copyWith(color: AppColors.green),
      checkmarkColor: AppColors.green,
      iconTheme: IconThemeData(color: AppColors.textMuted, size: 16),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    ),
    tabBarTheme: TabBarThemeData(
      labelColor: AppColors.text,
      unselectedLabelColor: AppColors.textDimmer,
      indicatorColor: AppColors.green,
      indicatorSize: TabBarIndicatorSize.label,
      dividerColor: AppColors.border,
      labelStyle: text.titleSmall?.copyWith(fontWeight: FontWeight.w600),
      unselectedLabelStyle: text.titleSmall,
      overlayColor: WidgetStatePropertyAll(AppColors.surface),
    ),
    listTileTheme: ListTileThemeData(
      iconColor: AppColors.textMuted,
      textColor: AppColors.text,
      selectedColor: AppColors.green,
      selectedTileColor: AppColors.greenDim,
    ),
    expansionTileTheme: ExpansionTileThemeData(
      iconColor: AppColors.textMuted,
      collapsedIconColor: AppColors.textDimmer,
      textColor: AppColors.text,
      collapsedTextColor: AppColors.text,
    ),
    checkboxTheme: CheckboxThemeData(
      fillColor: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.selected)
            ? AppColors.green
            : Colors.transparent,
      ),
      checkColor: WidgetStatePropertyAll(AppColors.textOnGreen),
      side: BorderSide(color: AppColors.borderStrong, width: 1.5),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
    ),
    radioTheme: RadioThemeData(
      fillColor: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.selected)
            ? AppColors.green
            : AppColors.borderStrong,
      ),
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.selected)
            ? AppColors.textOnGreen
            : AppColors.textMuted,
      ),
      trackColor: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.selected)
            ? AppColors.green
            : AppColors.surface2,
      ),
      trackOutlineColor: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.selected)
            ? Colors.transparent
            : AppColors.borderStrong,
      ),
    ),
    progressIndicatorTheme: ProgressIndicatorThemeData(
      color: AppColors.green,
      linearTrackColor: AppColors.surface2,
      circularTrackColor: Colors.transparent,
    ),
    sliderTheme: SliderThemeData(
      activeTrackColor: AppColors.green,
      inactiveTrackColor: AppColors.surface2,
      thumbColor: AppColors.green,
    ),
    tooltipTheme: TooltipThemeData(
      decoration: BoxDecoration(
        color: AppColors.bgOverlay,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.borderStrong),
      ),
      textStyle: text.bodySmall?.copyWith(color: AppColors.text),
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: AppColors.bgOverlay,
      contentTextStyle: text.bodyMedium?.copyWith(color: AppColors.text),
      actionTextColor: AppColors.green,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
        borderRadius: AppRadii.border,
        side: BorderSide(color: AppColors.borderStrong),
      ),
    ),
    popupMenuTheme: PopupMenuThemeData(
      color: AppColors.bgOverlay,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: AppRadii.border,
        side: BorderSide(color: AppColors.borderStrong),
      ),
      textStyle: text.bodyMedium,
    ),
    menuTheme: MenuThemeData(
      style: MenuStyle(
        backgroundColor: WidgetStatePropertyAll(AppColors.bgOverlay),
        surfaceTintColor: WidgetStatePropertyAll(Colors.transparent),
        side: WidgetStatePropertyAll(BorderSide(color: AppColors.borderStrong)),
      ),
    ),
    dropdownMenuTheme: DropdownMenuThemeData(
      textStyle: text.bodyMedium,
      menuStyle: MenuStyle(
        backgroundColor: WidgetStatePropertyAll(AppColors.bgOverlay),
        surfaceTintColor: WidgetStatePropertyAll(Colors.transparent),
      ),
    ),
    datePickerTheme: DatePickerThemeData(
      backgroundColor: AppColors.bgRaised,
      surfaceTintColor: Colors.transparent,
      headerForegroundColor: AppColors.text,
      shape: card,
    ),
    scrollbarTheme: ScrollbarThemeData(
      thumbColor: WidgetStatePropertyAll(AppColors.borderStrong),
      radius: Radius.circular(8),
    ),
    badgeTheme: BadgeThemeData(
      backgroundColor: AppColors.green,
      textColor: AppColors.textOnGreen,
    ),
    navigationRailTheme: NavigationRailThemeData(
      backgroundColor: AppColors.bgAlt,
      indicatorColor: AppColors.greenDim,
      selectedIconTheme: IconThemeData(color: AppColors.green),
      unselectedIconTheme: IconThemeData(color: AppColors.textDimmer),
    ),
    drawerTheme: DrawerThemeData(
      backgroundColor: AppColors.bgAlt,
      surfaceTintColor: Colors.transparent,
    ),
  );
}

// Tema claro anterior, solo para los formularios de preguntas de las
// encuestas, que conservan su diseño.
ThemeData talexLegacyTheme() {
  const radius = 12.0;
  final shape = RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(radius),
  );
  return ThemeData(
    colorScheme: ColorScheme.fromSeed(
      seedColor: LegacyColors.brandBlue,
      primary: LegacyColors.brandBlue,
      surface: LegacyColors.background,
    ),
    useMaterial3: true,
    scaffoldBackgroundColor: LegacyColors.background,
    cardTheme: CardThemeData(
      color: Colors.white,
      elevation: 0,
      shape: shape,
      margin: EdgeInsets.zero,
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: Colors.white,
      shape: shape,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: LegacyColors.brandBlue,
        foregroundColor: Colors.white,
        shape: shape,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(shape: shape),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: LegacyColors.ink,
        side: const BorderSide(color: LegacyColors.border),
        shape: shape,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: LegacyColors.brandBlue,
        shape: shape,
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: LegacyColors.fieldFill,
      labelStyle: const TextStyle(color: LegacyColors.subtitle),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radius),
        borderSide: const BorderSide(color: LegacyColors.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radius),
        borderSide: const BorderSide(color: LegacyColors.fieldBorder),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radius),
        borderSide: const BorderSide(color: LegacyColors.brandBlue, width: 1.5),
      ),
    ),
  );
}
