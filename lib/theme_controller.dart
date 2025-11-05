import 'package:flutter/material.dart';

/// A simple, app-wide theme controller based on ValueNotifier.
///
/// Settings screen can update [mode]; MyApp listens and rebuilds ShadApp.
class ThemeController {
  ThemeController._();
  static final ThemeController instance = ThemeController._();

  /// Current theme mode. Defaults to light.
  final ValueNotifier<ThemeMode> mode = ValueNotifier(ThemeMode.light);

  void setLight() => mode.value = ThemeMode.light;
  void setDark() => mode.value = ThemeMode.dark;
  void setSystem() => mode.value = ThemeMode.system;
}
