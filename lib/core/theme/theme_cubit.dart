import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:talex_platform/core/constants/app_colors.dart';

class ThemeState extends Equatable {
  const ThemeState({required this.mode, required this.brightness});

  /// Lo que eligió la persona (claro, oscuro o el del sistema).
  final ThemeMode mode;

  /// El brillo que se está mostrando, ya resuelto si [mode] es del sistema.
  final Brightness brightness;

  bool get isDark => brightness == Brightness.dark;

  @override
  List<Object?> get props => [mode, brightness];
}

// Tema de la plataforma. Guarda la elección como el idioma ([LocaleCubit]) y
// mantiene [AppColors] apuntando a la paleta que corresponde. Si la elección
// es "sistema", sigue los cambios de claro/oscuro del dispositivo.
class ThemeCubit extends Cubit<ThemeState> with WidgetsBindingObserver {
  ThemeCubit(this._prefs)
    : super(
        const ThemeState(mode: ThemeMode.dark, brightness: Brightness.dark),
      ) {
    WidgetsBinding.instance.addObserver(this);
  }

  static const _key = 'talex.theme';
  final SharedPreferences _prefs;

  void load() {
    final mode = switch (_prefs.getString(_key)) {
      'light' => ThemeMode.light,
      'system' => ThemeMode.system,
      // Sin elección guardada se usa el oscuro, el de la marca.
      _ => ThemeMode.dark,
    };
    _apply(mode);
  }

  Future<void> setMode(ThemeMode mode) async {
    await _prefs.setString(_key, mode.name);
    _apply(mode);
  }

  /// Pasa al brillo contrario del que se ve ahora, como elección explícita.
  Future<void> toggle() =>
      setMode(state.isDark ? ThemeMode.light : ThemeMode.dark);

  @override
  void didChangePlatformBrightness() {
    if (state.mode == ThemeMode.system) _apply(ThemeMode.system);
  }

  void _apply(ThemeMode mode) {
    final brightness = switch (mode) {
      ThemeMode.light => Brightness.light,
      ThemeMode.dark => Brightness.dark,
      ThemeMode.system =>
        WidgetsBinding.instance.platformDispatcher.platformBrightness,
    };
    AppColors.use(
      brightness == Brightness.dark ? TalexPalette.dark : TalexPalette.light,
    );
    emit(ThemeState(mode: mode, brightness: brightness));
  }

  @override
  Future<void> close() {
    WidgetsBinding.instance.removeObserver(this);
    return super.close();
  }
}
