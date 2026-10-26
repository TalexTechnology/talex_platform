import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:talex_platform/core/constants/app_colors.dart';
import 'package:talex_platform/core/theme/talex_theme_switcher.dart';
import 'package:talex_platform/core/theme/theme_cubit.dart';
import 'package:talex_platform/l10n/l10n.dart';

/// Centro de [context] en coordenadas globales: de ahí sale el revelado.
Offset themeOriginOf(BuildContext context) {
  final box = context.findRenderObject() as RenderBox?;
  if (box == null || !box.hasSize) return Offset.zero;
  return box.localToGlobal(box.size.center(Offset.zero));
}

// Botón redondo que alterna claro/oscuro. Muestra lo que vas a obtener (sol
// en oscuro, luna en claro) y el ícono gira al cambiar.
class ThemeToggleButton extends StatelessWidget {
  const ThemeToggleButton({super.key, this.size = 40});

  final double size;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final dark = context.select<ThemeCubit, bool>(
      (cubit) => cubit.state.isDark,
    );
    return Tooltip(
      message: dark ? l10n.themeSwitchToLight : l10n.themeSwitchToDark,
      child: Semantics(
        button: true,
        label: dark ? l10n.themeSwitchToLight : l10n.themeSwitchToDark,
        child: Material(
          color: AppColors.surface,
          shape: CircleBorder(side: BorderSide(color: AppColors.border)),
          clipBehavior: Clip.antiAlias,
          child: Builder(
            builder: (context) => InkWell(
              // La captura de pantalla empieza al presionar, no al soltar.
              onTapDown: (_) => TalexThemeSwitcher.of(context).prepare(),
              onTapCancel: () => TalexThemeSwitcher.of(context).cancelPrepare(),
              onTap: () => TalexThemeSwitcher.of(
                context,
              ).toggle(origin: themeOriginOf(context)),
              hoverColor: AppColors.surface2,
              child: SizedBox.square(
                dimension: size,
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 420),
                  switchInCurve: Curves.easeOutBack,
                  switchOutCurve: Curves.easeIn,
                  transitionBuilder: (child, animation) => RotationTransition(
                    turns: Tween<double>(
                      begin: -0.35,
                      end: 0,
                    ).animate(animation),
                    child: ScaleTransition(
                      scale: animation,
                      child: FadeTransition(opacity: animation, child: child),
                    ),
                  ),
                  child: Icon(
                    dark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
                    key: ValueKey(dark),
                    size: size * 0.48,
                    color: dark ? AppColors.warning : AppColors.blue,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// Selector completo de Configuración: sistema, claro u oscuro. El revelado
// sale del centro del selector.
class ThemeModePicker extends StatelessWidget {
  const ThemeModePicker({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final mode = context.select<ThemeCubit, ThemeMode>(
      (cubit) => cubit.state.mode,
    );
    return SegmentedButton<ThemeMode>(
      showSelectedIcon: false,
      segments: [
        ButtonSegment(
          value: ThemeMode.system,
          icon: const Icon(Icons.brightness_auto_outlined, size: 18),
          label: Text(l10n.themeSystem),
        ),
        ButtonSegment(
          value: ThemeMode.light,
          icon: const Icon(Icons.light_mode_outlined, size: 18),
          label: Text(l10n.themeLight),
        ),
        ButtonSegment(
          value: ThemeMode.dark,
          icon: const Icon(Icons.dark_mode_outlined, size: 18),
          label: Text(l10n.themeDark),
        ),
      ],
      selected: {mode},
      onSelectionChanged: (selection) => TalexThemeSwitcher.of(
        context,
      ).setMode(selection.first, origin: themeOriginOf(context)),
    );
  }
}
