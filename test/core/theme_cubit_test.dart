import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:talex_platform/core/constants/app_colors.dart';
import 'package:talex_platform/core/theme/theme_cubit.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<ThemeCubit> cubitWith(Map<String, Object> saved) async {
    SharedPreferences.setMockInitialValues(saved);
    return ThemeCubit(await SharedPreferences.getInstance())..load();
  }

  tearDown(() => AppColors.use(TalexPalette.dark));

  test('starts dark when nothing is saved', () async {
    final cubit = await cubitWith({});
    expect(cubit.state.mode, ThemeMode.dark);
    expect(AppColors.isDark, isTrue);
    await cubit.close();
  });

  test('toggle switches the palette and remembers the choice', () async {
    final cubit = await cubitWith({});
    await cubit.toggle();
    expect(cubit.state.brightness, Brightness.light);
    expect(AppColors.bg, TalexPalette.light.bg);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('talex.theme'), 'light');
    await cubit.close();
  });

  test('restores a saved light theme', () async {
    final cubit = await cubitWith({'talex.theme': 'light'});
    expect(cubit.state.isDark, isFalse);
    expect(AppColors.text, TalexPalette.light.text);
    await cubit.close();
  });
}
