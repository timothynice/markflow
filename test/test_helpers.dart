import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mockito/mockito.dart';
import 'package:provider/provider.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:markflow/features/markdown/local_store.dart';
import 'package:markflow/features/markdown/models.dart';
import 'package:markflow/theme_controller.dart';

// Mock classes
class MockMdLocalStore extends Mock implements MdLocalStore {}
class MockGoRouter extends Mock implements GoRouter {}

/// Test helper utilities for consistent test setup across widget and integration tests
class TestHelpers {

  /// Creates a test MaterialApp with proper theme and dependencies
  static Widget createTestApp({
    required Widget child,
    MdLocalStore? mockStore,
    GoRouter? router,
    ThemeController? themeController,
    Size? screenSize,
  }) {
    final testThemeController = themeController ?? ThemeController();

    return ValueListenableBuilder<ThemeMode>(
      valueListenable: testThemeController.listenable,
      builder: (context, themeMode, _) {
        Widget app = MultiProvider(
          providers: [
            Provider<MdLocalStore>.value(value: mockStore ?? MockMdLocalStore()),
            ChangeNotifierProvider<ThemeController>.value(value: testThemeController),
          ],
          child: MaterialApp(
            themeMode: themeMode,
            theme: ThemeData(colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue, brightness: Brightness.light)),
            darkTheme: ThemeData(colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue, brightness: Brightness.dark)),
            home: Scaffold(body: child),
          ),
        );

        // Wrap in MediaQuery with custom screen size if provided
        if (screenSize != null) {
          app = MediaQuery(
            data: MediaQueryData(size: screenSize),
            child: app,
          );
        }

        return app;
      },
    );
  }

  /// Creates a test app with router navigation
  static Widget createTestAppWithRouter({
    required Widget child,
    required GoRouter router,
    MdLocalStore? mockStore,
    ThemeController? themeController,
    Size? screenSize,
  }) {
    final testThemeController = themeController ?? ThemeController();

    return ValueListenableBuilder<ThemeMode>(
      valueListenable: testThemeController.listenable,
      builder: (context, themeMode, _) {
        Widget app = MultiProvider(
          providers: [
            Provider<MdLocalStore>.value(value: mockStore ?? MockMdLocalStore()),
            ChangeNotifierProvider<ThemeController>.value(value: testThemeController),
          ],
          child: MaterialApp.router(
            routerConfig: router,
            themeMode: themeMode,
            theme: ThemeData(colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue, brightness: Brightness.light)),
            darkTheme: ThemeData(colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue, brightness: Brightness.dark)),
          ),
        );

        // Wrap in MediaQuery with custom screen size if provided
        if (screenSize != null) {
          app = MediaQuery(
            data: MediaQueryData(size: screenSize),
            child: app,
          );
        }

        return app;
      },
    );
  }

  /// Creates mock documents for testing
  static List<MdDocument> createMockDocuments() {
    final now = DateTime.now();
    return [
      MdDocument(
        id: 'doc1',
        title: 'First Document',
        content: '# First Document\n\nThis is the first test document.',
        updatedAt: now.subtract(const Duration(hours: 1)),
        versions: [
          MdVersion(
            id: 'v1',
            createdAt: now.subtract(const Duration(hours: 2)),
            content: '# First Document\n\nThis is the first test document.',
          ),
        ],
      ),
      MdDocument(
        id: 'doc2',
        title: 'Second Document',
        content: '# Second Document\n\nThis is the second test document with more content.',
        updatedAt: now.subtract(const Duration(minutes: 30)),
        versions: [
          MdVersion(
            id: 'v2',
            createdAt: now.subtract(const Duration(hours: 1)),
            content: '# Second Document\n\nThis is the second test document.',
          ),
          MdVersion(
            id: 'v3',
            createdAt: now.subtract(const Duration(minutes: 30)),
            content: '# Second Document\n\nThis is the second test document with more content.',
          ),
        ],
      ),
      MdDocument(
        id: 'doc3',
        title: 'Untitled',
        content: '',
        updatedAt: now.subtract(const Duration(days: 1)),
        versions: [
          MdVersion(
            id: 'v4',
            createdAt: now.subtract(const Duration(days: 1)),
            content: '',
          ),
        ],
      ),
    ];
  }

  /// Creates a simple router for testing
  static GoRouter createTestRouter({
    required List<RouteBase> routes,
    String? initialLocation,
  }) {
    return GoRouter(
      routes: routes,
      initialLocation: initialLocation ?? '/',
    );
  }

  /// Screen size constants for responsive testing
  static const Size mobileSize = Size(375, 667);
  static const Size tabletSize = Size(768, 1024);
  static const Size desktopSize = Size(1440, 900);

  /// Pumps and settles with custom duration for animations
  static Future<void> pumpAndSettleWithDelay(
    WidgetTester tester, [
    Duration timeout = const Duration(seconds: 10),
  ]) async {
    await tester.pumpAndSettle(timeout);
    // Additional delay for debounced operations
    await tester.pump(const Duration(milliseconds: 500));
  }

  /// Enters text into a TextField and triggers onChange
  static Future<void> enterText(
    WidgetTester tester,
    Finder textFieldFinder,
    String text,
  ) async {
    await tester.enterText(textFieldFinder, text);
    await tester.pump();
    // Trigger debounced operations
    await tester.pump(const Duration(milliseconds: 500));
  }

  /// Simulates a tap and waits for animations
  static Future<void> tapAndSettle(WidgetTester tester, Finder finder) async {
    await tester.tap(finder);
    await tester.pumpAndSettle();
  }

  /// Verifies accessibility semantics
  static void verifyAccessibilitySemantics(WidgetTester tester, {
    List<String>? expectedLabels,
    List<String>? expectedHints,
    bool? expectsButton,
    bool? expectsTextField,
  }) {
    final semantics = tester.binding.pipelineOwner.semanticsOwner?.rootSemanticsNode;
    expect(semantics, isNotNull);

    if (expectedLabels != null) {
      for (final label in expectedLabels) {
        expect(find.bySemanticsLabel(label), findsWidgets);
      }
    }

    if (expectsButton == true) {
      expect(
        find.byWidgetPredicate((widget) =>
          widget is Semantics &&
          widget.properties.button == true
        ),
        findsAtLeastNWidgets(1),
      );
    }

    if (expectsTextField == true) {
      expect(
        find.byWidgetPredicate((widget) =>
          widget is Semantics &&
          widget.properties.textField == true
        ),
        findsAtLeastNWidgets(1),
      );
    }
  }
}

/// Common test matchers
class TestMatchers {
  static Matcher hasText(String text) => findsOneWidget;
  static Matcher hasIcon(IconData icon) => findsOneWidget;
  static Matcher hasWidget<T>() => findsOneWidget;
  static Matcher hasNWidgets<T>(int count) => findsNWidgets(count);
}

/// Test fixtures for consistent data
class TestFixtures {
  static const String sampleMarkdown = '''
# Sample Document

This is a sample document with **bold** text and *italic* text.

## Features

- List item 1
- List item 2
- List item 3

### Code Block

```dart
void main() {
  print('Hello, World!');
}
```

[Link example](https://flutter.dev)
''';

  static const String longMarkdown = '''
# Very Long Document

This is a very long document that should test scrolling behavior and performance.

Lorem ipsum dolor sit amet, consectetur adipiscing elit. Sed do eiusmod tempor incididunt ut labore et dolore magna aliqua.

## Section 1

Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat.

## Section 2

Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur.

## Section 3

Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum.

## Section 4

Sed ut perspiciatis unde omnis iste natus error sit voluptatem accusantium doloremque laudantium.

## Section 5

Totam rem aperiam, eaque ipsa quae ab illo inventore veritatis et quasi architecto beatae vitae dicta sunt.
''';
}