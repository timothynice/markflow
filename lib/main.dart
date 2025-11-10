import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'widgets/component_examples/component_example_registry.dart';
import 'routes/go_router_config.dart';
import 'theme.dart';
import 'theme_controller.dart';
import 'features/markdown/services/syntax_highlight_initializer.dart';

/// Entry point for the shadcn/ui Flutter showcase application.
/// This application demonstrates various shadcn/ui components with interactive examples
/// and responsive design.
void main() async {
  // Ensure Flutter framework is initialized
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize all component examples before starting the app
  // This ensures all components are registered and available throughout the app
  ComponentExampleRegistry.registerAll();

  // Initialize syntax highlighting service for enhanced code blocks
  await SyntaxHighlightInitializer.initialize();

  runApp(const MyApp());
}

/// Root widget for the shadcn/ui showcase application.
///
/// This widget sets up the main application structure with:
/// - Go Router for navigation
/// - Standard Flutter theme integration with custom light theme
/// - Responsive design support
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Listen to theme-mode changes and rebuild the app accordingly
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: ThemeController.instance.mode,
      builder: (context, mode, _) {
        return ShadApp.router(
          routerConfig: GoRouterConfig.router,
          themeMode: mode,
          builder: (context, child) {
            final brightness = MediaQuery.maybeOf(context)?.platformBrightness ?? Brightness.light;
            final effective = switch (mode) {
              ThemeMode.dark => darkTheme,
              ThemeMode.light => lightTheme,
              ThemeMode.system => brightness == Brightness.dark ? darkTheme : lightTheme,
            };
            return Theme(data: effective, child: child ?? const SizedBox.shrink());
          },
        );
      },
    );
  }
}
