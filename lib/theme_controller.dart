import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';

/// A simple, app-wide theme controller based on ValueNotifier.
///
/// Settings screen can update [mode]; MyApp listens and rebuilds ShadApp.
class ThemeController extends ChangeNotifier {
  ThemeController._() {
    // Bridge inner notifier to ChangeNotifier
    mode.addListener(() => notifyListeners());
  }
  static final ThemeController instance = ThemeController._();
  factory ThemeController() => instance;

  /// Current theme mode. Defaults to light.
  final ValueNotifier<ThemeMode> mode = ValueNotifier(ThemeMode.light);

  /// Expose a listenable for widgets that expect a ValueListenable<ThemeMode>
  ValueListenable<ThemeMode> get listenable => mode;

  void setLight() => mode.value = ThemeMode.light;
  void setDark() => mode.value = ThemeMode.dark;
  void setSystem() => mode.value = ThemeMode.system;

  // Convenience for code that needs a quick answer without BuildContext
  bool get isDarkMode {
    if (mode.value == ThemeMode.dark) return true;
    if (mode.value == ThemeMode.light) return false;
    final platformBrightness = WidgetsBinding.instance.platformDispatcher.platformBrightness;
    return platformBrightness == Brightness.dark;
  }
}
