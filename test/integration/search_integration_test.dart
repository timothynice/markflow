import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:markflow/main.dart' as app;
import 'package:markflow/features/markdown/widgets/search_replace_overlay.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Search Integration Tests', () {
    testWidgets('Complete search workflow', (tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Navigate to editor (assuming we start at docs screen)
      // This might need adjustment based on app routing
      try {
        final createButton = find.text('New Document').first;
        await tester.tap(createButton);
        await tester.pumpAndSettle();
      } catch (e) {
        // If direct navigation isn't available, we'll use keyboard shortcut
      }

      // Enter some test content
      final editorField = find.byType(TextField).last; // Editor text field
      await tester.enterText(editorField, '''
# Test Document

This is a test document with several test words.
We will search for the word "test" in this content.

## Another Section

More test content here.
Testing the search functionality thoroughly.
''');
      await tester.pumpAndSettle();

      // Open search overlay using keyboard shortcut
      await tester.sendKeyEvent(LogicalKeyboardKey.meta);
      await tester.sendKeyEvent(LogicalKeyboardKey.keyF);
      await tester.pumpAndSettle();

      // Search overlay should be visible
      expect(find.text('Search...'), findsOneWidget);

      // Enter search query
      final searchField = find.byType(TextField).first;
      await tester.enterText(searchField, 'test');
      await tester.pumpAndSettle();

      // Should show match count
      expect(find.textContaining('/'), findsOneWidget); // Match counter format

      // Test navigation between matches
      final nextButton = find.byIcon(Icons.keyboard_arrow_down);
      await tester.tap(nextButton);
      await tester.pumpAndSettle();

      final prevButton = find.byIcon(Icons.keyboard_arrow_up);
      await tester.tap(prevButton);
      await tester.pumpAndSettle();

      // Test search options
      final caseButton = find.byIcon(Icons.search);
      await tester.tap(caseButton);
      await tester.pumpAndSettle();

      // Test replace functionality
      final expandButton = find.byIcon(Icons.unfold_more);
      await tester.tap(expandButton);
      await tester.pumpAndSettle();

      expect(find.text('Replace with...'), findsOneWidget);

      final replaceField = find.widgetWithText(TextField, 'Replace with...');
      await tester.enterText(replaceField, 'exam');
      await tester.pumpAndSettle();

      // Test replace current
      final replaceButton = find.text('Replace');
      await tester.tap(replaceButton);
      await tester.pumpAndSettle();

      // Close search
      final closeButton = find.byIcon(Icons.close);
      await tester.tap(closeButton);
      await tester.pumpAndSettle();

      // Search overlay should be hidden
      expect(find.text('Search...'), findsNothing);
    });

    testWidgets('Keyboard navigation workflow', (tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Navigate to editor
      try {
        final createButton = find.text('New Document').first;
        await tester.tap(createButton);
        await tester.pumpAndSettle();
      } catch (e) {
        // Continue with keyboard shortcuts
      }

      // Enter test content
      final editorField = find.byType(TextField).last;
      await tester.enterText(editorField, '''
First test line.
Second test line.
Third test line.
''');
      await tester.pumpAndSettle();

      // Open search with Cmd+F
      await tester.sendKeyDownEvent(LogicalKeyboardKey.meta);
      await tester.sendKeyDownEvent(LogicalKeyboardKey.keyF);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.keyF);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.meta);
      await tester.pumpAndSettle();

      // Enter search query
      final searchField = find.byType(TextField).first;
      await tester.enterText(searchField, 'test');
      await tester.pumpAndSettle();

      // Use F3 to navigate to next match
      await tester.sendKeyEvent(LogicalKeyboardKey.f3);
      await tester.pumpAndSettle();

      // Use Shift+F3 to navigate to previous match
      await tester.sendKeyDownEvent(LogicalKeyboardKey.shift);
      await tester.sendKeyDownEvent(LogicalKeyboardKey.f3);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.f3);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.shift);
      await tester.pumpAndSettle();

      // Close with Escape
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();

      expect(find.text('Search...'), findsNothing);
    });

    testWidgets('Regex search workflow', (tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Navigate to editor
      try {
        final createButton = find.text('New Document').first;
        await tester.tap(createButton);
        await tester.pumpAndSettle();
      } catch (e) {
        // Continue
      }

      // Enter test content with patterns
      final editorField = find.byType(TextField).last;
      await tester.enterText(editorField, '''
Email: test@example.com
Phone: (555) 123-4567
Date: 2023-12-25
URL: https://example.com
''');
      await tester.pumpAndSettle();

      // Open search
      await tester.sendKeyDownEvent(LogicalKeyboardKey.meta);
      await tester.sendKeyDownEvent(LogicalKeyboardKey.keyF);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.keyF);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.meta);
      await tester.pumpAndSettle();

      // Enable regex mode
      final regexButton = find.text('.*');
      await tester.tap(regexButton);
      await tester.pumpAndSettle();

      // Search for email pattern
      final searchField = find.byType(TextField).first;
      await tester.enterText(searchField, r'\w+@\w+\.\w+');
      await tester.pumpAndSettle();

      // Should find email
      expect(find.textContaining('1'), findsOneWidget); // Match count

      // Search for phone pattern
      await tester.enterText(searchField, r'\(\d{3}\) \d{3}-\d{4}');
      await tester.pumpAndSettle();

      // Should find phone
      expect(find.textContaining('1'), findsOneWidget);

      // Close search
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
    });

    testWidgets('Search history workflow', (tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Navigate to editor
      try {
        final createButton = find.text('New Document').first;
        await tester.tap(createButton);
        await tester.pumpAndSettle();
      } catch (e) {
        // Continue
      }

      final editorField = find.byType(TextField).last;
      await tester.enterText(editorField, '''
Content with various words: hello, world, test, example.
''');
      await tester.pumpAndSettle();

      // Perform several searches to build history
      for (final query in ['hello', 'world', 'test']) {
        // Open search
        await tester.sendKeyDownEvent(LogicalKeyboardKey.meta);
        await tester.sendKeyDownEvent(LogicalKeyboardKey.keyF);
        await tester.sendKeyUpEvent(LogicalKeyboardKey.keyF);
        await tester.sendKeyUpEvent(LogicalKeyboardKey.meta);
        await tester.pumpAndSettle();

        // Enter query
        final searchField = find.byType(TextField).first;
        await tester.enterText(searchField, query);
        await tester.pumpAndSettle();

        // Close search
        await tester.sendKeyEvent(LogicalKeyboardKey.escape);
        await tester.pumpAndSettle();
      }

      // Open search again
      await tester.sendKeyDownEvent(LogicalKeyboardKey.meta);
      await tester.sendKeyDownEvent(LogicalKeyboardKey.keyF);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.keyF);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.meta);
      await tester.pumpAndSettle();

      // Open history
      final historyButton = find.byIcon(Icons.history);
      if (historyButton.evaluate().isNotEmpty) {
        await tester.tap(historyButton);
        await tester.pumpAndSettle();

        // Should show previous searches
        expect(find.text('test'), findsOneWidget);
        expect(find.text('world'), findsOneWidget);

        // Select from history
        await tester.tap(find.text('test'));
        await tester.pumpAndSettle();

        // Should perform search
        expect(find.textContaining('/'), findsOneWidget);
      }

      // Close search
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
    });

    testWidgets('Replace all workflow', (tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Navigate to editor
      try {
        final createButton = find.text('New Document').first;
        await tester.tap(createButton);
        await tester.pumpAndSettle();
      } catch (e) {
        // Continue
      }

      final editorField = find.byType(TextField).last;
      await tester.enterText(editorField, '''
Replace this word: old
Another old word here.
Final old word to replace.
''');
      await tester.pumpAndSettle();

      // Open search
      await tester.sendKeyDownEvent(LogicalKeyboardKey.meta);
      await tester.sendKeyDownEvent(LogicalKeyboardKey.keyF);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.keyF);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.meta);
      await tester.pumpAndSettle();

      // Search for 'old'
      final searchField = find.byType(TextField).first;
      await tester.enterText(searchField, 'old');
      await tester.pumpAndSettle();

      // Should find multiple matches
      expect(find.textContaining('3'), findsOneWidget); // Should find 3 matches

      // Expand replace
      final expandButton = find.byIcon(Icons.unfold_more);
      await tester.tap(expandButton);
      await tester.pumpAndSettle();

      // Enter replacement
      final replaceField = find.widgetWithText(TextField, 'Replace with...');
      await tester.enterText(replaceField, 'new');
      await tester.pumpAndSettle();

      // Replace all
      final replaceAllButton = find.text('All');
      await tester.tap(replaceAllButton);
      await tester.pumpAndSettle();

      // Close search
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();

      // Verify replacements occurred
      final editorText = tester.widget<TextField>(editorField);
      expect(editorText.controller?.text.contains('new'), isTrue);
      expect(editorText.controller?.text.contains('old'), isFalse);
    });

    testWidgets('Mobile search workflow', (tester) async {
      // Set mobile screen size
      await tester.binding.setSurfaceSize(const Size(375, 812));

      app.main();
      await tester.pumpAndSettle();

      // Navigate to editor
      try {
        final createButton = find.text('New Document').first;
        await tester.tap(createButton);
        await tester.pumpAndSettle();
      } catch (e) {
        // Continue
      }

      final editorField = find.byType(TextField).last;
      await tester.enterText(editorField, 'Mobile test content for searching.');
      await tester.pumpAndSettle();

      // Look for search button in navigation
      final searchButton = find.text('Search');
      if (searchButton.evaluate().isNotEmpty) {
        await tester.tap(searchButton);
        await tester.pumpAndSettle();

        // Mobile overlay should appear
        expect(find.byType(MobileSearchOverlay), findsOneWidget);

        // Enter search query
        final mobileSearchField = find.byType(TextField).first;
        await tester.enterText(mobileSearchField, 'test');
        await tester.pumpAndSettle();

        // Should show match counter
        expect(find.textContaining('/'), findsOneWidget);

        // Test replace toggle
        final replaceToggle = find.text('Replace');
        await tester.tap(replaceToggle);
        await tester.pumpAndSettle();

        expect(find.text('Replace with...'), findsOneWidget);

        // Close mobile search
        final closeButton = find.byIcon(Icons.close);
        await tester.tap(closeButton);
        await tester.pumpAndSettle();
      }

      // Reset screen size
      await tester.binding.setSurfaceSize(null);
    });

    testWidgets('Error handling workflow', (tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Navigate to editor
      try {
        final createButton = find.text('New Document').first;
        await tester.tap(createButton);
        await tester.pumpAndSettle();
      } catch (e) {
        // Continue
      }

      final editorField = find.byType(TextField).last;
      await tester.enterText(editorField, 'Content for error testing.');
      await tester.pumpAndSettle();

      // Open search
      await tester.sendKeyDownEvent(LogicalKeyboardKey.meta);
      await tester.sendKeyDownEvent(LogicalKeyboardKey.keyF);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.keyF);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.meta);
      await tester.pumpAndSettle();

      // Enable regex mode
      final regexButton = find.text('.*');
      await tester.tap(regexButton);
      await tester.pumpAndSettle();

      // Enter invalid regex
      final searchField = find.byType(TextField).first;
      await tester.enterText(searchField, '[unclosed');
      await tester.pumpAndSettle();

      // Should show error message
      expect(find.textContaining('error'), findsOneWidget, reason: 'Should show regex error');

      // Fix the regex
      await tester.enterText(searchField, 'Content');
      await tester.pumpAndSettle();

      // Should clear error and show matches
      expect(find.textContaining('/'), findsOneWidget);

      // Close search
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
    });
  });
}