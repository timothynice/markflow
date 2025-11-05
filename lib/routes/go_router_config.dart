import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import '../features/markdown/editor_screen.dart';
import '../features/markdown/docs_screen.dart';
import '../screens/settings_screen.dart';

/// GoRouter configuration for the application
class GoRouterConfig {
  static final GoRouter router = GoRouter(
    // Start the app on the Documents list
    initialLocation: '/',
    routes: [
      // Home route
      GoRoute(
        path: '/',
        name: 'home',
        pageBuilder: (context, state) => NoTransitionPage(
          child: const DocumentsScreen(),
        ),
      ),

      // Markdown editor route with document id
      GoRoute(
        path: '/markdown/:id',
        name: 'markdown',
        pageBuilder: (context, state) {
          final id = state.pathParameters['id']!;
          return NoTransitionPage(
            child: MarkdownEditorScreen(docId: id),
          );
        },
      ),

      // Documents list route
      GoRoute(
        path: '/docs',
        name: 'docs',
        pageBuilder: (context, state) => NoTransitionPage(
          child: const DocumentsScreen(),
        ),
      ),

      // Settings route
      GoRoute(
        path: '/settings',
        name: 'settings',
        pageBuilder: (context, state) => NoTransitionPage(
          child: const SettingsScreen(),
        ),
      ),
    ],
    errorBuilder: (context, state) {
      // Unknown routes fall back to Documents list
      return const DocumentsScreen();
    },
  );
}

/// Route constants for type-safe navigation
class AppRoutes {
  static const String home = '/';
  static const String markdown = '/markdown';
  static const String docs = '/docs';
  static const String settings = '/settings';

  /// Validate if route is valid
  static bool isValidRoute(String routePath) {
    return routePath == home || routePath == markdown || routePath == docs || routePath == settings;
  }
}
