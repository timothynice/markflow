import 'package:flutter/foundation.dart';
import 'syntax_highlight_service.dart';
import '../../../theme_controller.dart';

/// Initializer for syntax highlighting service with theme integration
class SyntaxHighlightInitializer {
  static bool _isInitialized = false;

  /// Initialize the syntax highlighting service
  /// Should be called during app startup
  static Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      debugPrint('Initializing SyntaxHighlightService...');

      // Initialize the service
      await SyntaxHighlightService.instance.initialize();

      // Preload common languages for better performance
      final isDarkMode = ThemeController.instance.isDarkMode;
      await SyntaxHighlightService.instance.preloadCommonLanguages(
        isDarkMode: isDarkMode,
      );

      // Listen to theme changes and update highlighter cache
      ThemeController.instance.addListener(_onThemeChanged);

      _isInitialized = true;
      debugPrint('SyntaxHighlightService initialized successfully');
    } catch (e) {
      debugPrint('Failed to initialize SyntaxHighlightService: $e');
      // Don't throw - the app should still work without syntax highlighting
    }
  }

  /// Handle theme changes by clearing cache and preloading for new theme
  static void _onThemeChanged() {
    if (!_isInitialized) return;

    debugPrint('Theme changed, updating syntax highlighting cache...');

    // Clear the old cache
    SyntaxHighlightService.instance.clearCache();

    // Preload common languages for the new theme
    final isDarkMode = ThemeController.instance.isDarkMode;
    SyntaxHighlightService.instance.preloadCommonLanguages(
      isDarkMode: isDarkMode,
    ).catchError((e) {
      debugPrint('Failed to preload languages for new theme: $e');
    });
  }

  /// Check if the service is initialized
  static bool get isInitialized => _isInitialized;

  /// Dispose resources
  static void dispose() {
    if (_isInitialized) {
      ThemeController.instance.removeListener(_onThemeChanged);
      _isInitialized = false;
    }
  }
}