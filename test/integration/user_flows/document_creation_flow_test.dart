import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:markflow/main.dart' as app;
import 'package:markflow/features/markdown/docs_screen.dart';
import 'package:markflow/features/markdown/editor_screen.dart';
import 'package:markflow/features/markdown/widgets/formatting_toolbar.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

/// Integration test for end-to-end document creation workflow
///
/// This test covers the complete user journey from launching the app
/// to creating a new document and editing it.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Document Creation Flow Integration Tests', () {
    testWidgets('should complete full document creation flow from docs screen', (WidgetTester tester) async {
      // Start the app
      app.main();
      await tester.pumpAndSettle();

      // Wait for app initialization
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Should be on docs/home screen
      expect(find.byType(DocumentsScreen), findsOneWidget);

      // Find and tap the "New Document" button
      // On mobile, look for the floating action button
      Finder newDocButton = find.byIcon(Icons.note_add_outlined);

      // If not found, try desktop layout button
      if (newDocButton.evaluate().isEmpty) {
        newDocButton = find.byIcon(Icons.add);
      }

      expect(newDocButton, findsOneWidget);
      await tester.tap(newDocButton);
      await tester.pumpAndSettle(const Duration(seconds: 1));

      // Should navigate to editor screen for new document
      expect(find.byType(MarkdownEditorScreen), findsOneWidget);

      // Should show formatting toolbar
      expect(find.byType(FormattingToolbar), findsOneWidget);

      // Should show tab bar with Markdown and Styled tabs
      expect(find.text('Markdown'), findsOneWidget);
      expect(find.text('Styled'), findsOneWidget);

      // Should show text editor in first tab (default)
      expect(find.byType(TextField), findsAtLeastNWidgets(1));
    });

    testWidgets('should create new document from home screen', (WidgetTester tester) async {
      // Launch app
      app.main();
      await tester.pumpAndSettle();
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Navigate to create new document
      final newDocButton = find.byIcon(Icons.note_add_outlined).first;
      await tester.tap(newDocButton);
      await tester.pumpAndSettle(const Duration(seconds: 1));

      // Enter content in editor
      const testContent = '# Home Created Document\n\nThis was created from home screen.';
      final textField = find.byType(TextField).first;
      await tester.enterText(textField, testContent);
      await tester.pump();

      // Wait for auto-save
      await tester.pump(const Duration(milliseconds: 500));

      // Verify document is saved by navigating back and checking
      await tester.tap(find.text('Documents'));
      await tester.pumpAndSettle();

      expect(find.text('Home Created Document'), findsOneWidget);
    });

    testWidgets('should create new document from docs screen and verify in list', (WidgetTester tester) async {
      // Launch app
      app.main();
      await tester.pumpAndSettle();
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Navigate to docs screen (already there by default)
      expect(find.byType(DocumentsScreen), findsOneWidget);

      // Tap create new document button
      final newDocButton = find.byIcon(Icons.note_add_outlined).first;
      await tester.tap(newDocButton);
      await tester.pumpAndSettle(const Duration(seconds: 1));

      // Enter content in editor
      const testContent = '# Docs Screen Document\n\nCreated from docs screen with content.';
      final textField = find.byType(TextField).first;
      await tester.enterText(textField, testContent);
      await tester.pump();

      // Wait for auto-save
      await tester.pump(const Duration(milliseconds: 500));

      // Navigate back to docs screen
      await tester.tap(find.text('Documents'));
      await tester.pumpAndSettle();

      // Verify new document appears in list
      expect(find.text('Docs Screen Document'), findsOneWidget);
    });

    testWidgets('should auto-save document during editing', (WidgetTester tester) async {
      // Create new document
      app.main();
      await tester.pumpAndSettle();
      await tester.pumpAndSettle(const Duration(seconds: 2));

      final newDocButton = find.byIcon(Icons.note_add_outlined).first;
      await tester.tap(newDocButton);
      await tester.pumpAndSettle(const Duration(seconds: 1));

      // Enter content
      const testContent = '# Auto-Save Test\n\nThis content should be auto-saved.';
      final textField = find.byType(TextField).first;
      await tester.enterText(textField, testContent);
      await tester.pump();

      // Wait for auto-save delay (300ms debounce + buffer)
      await tester.pump(const Duration(milliseconds: 500));

      // Navigate away
      await tester.tap(find.text('Documents'));
      await tester.pumpAndSettle();

      // Navigate back
      await tester.tap(find.text('Auto-Save Test'));
      await tester.pumpAndSettle();

      // Verify content is preserved
      final preservedTextField = find.byType(TextField).first;
      final textFieldWidget = tester.widget<TextField>(preservedTextField);
      expect(textFieldWidget.controller?.text, contains('Auto-Save Test'));
      expect(textFieldWidget.controller?.text, contains('This content should be auto-saved'));
    });

    testWidgets('should handle document creation with special characters in title', (WidgetTester tester) async {
      // Create document with special characters in title
      app.main();
      await tester.pumpAndSettle();
      await tester.pumpAndSettle(const Duration(seconds: 2));

      final newDocButton = find.byIcon(Icons.note_add_outlined).first;
      await tester.tap(newDocButton);
      await tester.pumpAndSettle(const Duration(seconds: 1));

      // Enter content with special characters in title
      const specialTitle = '# Spéciäl Chãracters & Symbols! @#\$%';
      const content = '$specialTitle\n\nDocument with unicode and special characters: 你好, 🚀, €, £, ¥';

      final textField = find.byType(TextField).first;
      await tester.enterText(textField, content);
      await tester.pump();

      // Wait for auto-save
      await tester.pump(const Duration(milliseconds: 500));

      // Verify title is handled correctly in UI and storage
      await tester.tap(find.text('Documents'));
      await tester.pumpAndSettle();

      // Look for the document with special characters (title should be derived)
      expect(find.textContaining('Spéciäl Chãracters'), findsOneWidget);

      // Verify navigation and retrieval work properly
      await tester.tap(find.textContaining('Spéciäl Chãracters').first);
      await tester.pumpAndSettle();

      final retrievedTextField = find.byType(TextField).first;
      final textFieldWidget = tester.widget<TextField>(retrievedTextField);
      expect(textFieldWidget.controller?.text, contains('Spéciäl Chãracters'));
      expect(textFieldWidget.controller?.text, contains('你好, 🚀, €, £, ¥'));
    });

    testWidgets('should create document with markdown content and verify preview', (WidgetTester tester) async {
      // Create new document
      app.main();
      await tester.pumpAndSettle();
      await tester.pumpAndSettle(const Duration(seconds: 2));

      final newDocButton = find.byIcon(Icons.note_add_outlined).first;
      await tester.tap(newDocButton);
      await tester.pumpAndSettle(const Duration(seconds: 1));

      // Enter markdown syntax (headers, lists, links, etc.)
      const markdownContent = '''# Markdown Preview Test

This document tests **bold**, *italic*, and `code` formatting.

## Features List

- Bullet point one
- Bullet point two
- Bullet point three

### Numbered List

1. First item
2. Second item
3. Third item

### Code Block

```dart
void main() {
  print('Hello, Markdown!');
}
```

### Link

[Flutter](https://flutter.dev) is awesome!
''';

      final textField = find.byType(TextField).first;
      await tester.enterText(textField, markdownContent);
      await tester.pump();

      // Verify preview pane shows rendered content correctly
      await tester.tap(find.text('Styled'));
      await tester.pumpAndSettle();

      expect(find.byType(Markdown), findsOneWidget);

      // Save and reload document
      await tester.tap(find.text('Documents'));
      await tester.pumpAndSettle();

      // Find and reopen the document
      await tester.tap(find.text('Markdown Preview Test'));
      await tester.pumpAndSettle();

      // Verify content is preserved
      final preservedTextField = find.byType(TextField).first;
      final textFieldWidget = tester.widget<TextField>(preservedTextField);
      expect(textFieldWidget.controller?.text, contains('Markdown Preview Test'));
      expect(textFieldWidget.controller?.text, contains('**bold**'));
      expect(textFieldWidget.controller?.text, contains('[Flutter](https://flutter.dev)'));

      // Verify preview is still working
      await tester.tap(find.text('Styled'));
      await tester.pumpAndSettle();
      expect(find.byType(Markdown), findsOneWidget);
    });

    group('Performance Tests', () {
      testWidgets('should create large document efficiently', (WidgetTester tester) async {
        // Test performance with large document creation
        app.main();
        await tester.pumpAndSettle();
        await tester.pumpAndSettle(const Duration(seconds: 2));

        final newDocButton = find.byIcon(Icons.note_add_outlined).first;
        await tester.tap(newDocButton);
        await tester.pumpAndSettle(const Duration(seconds: 1));

        // Create document with substantial content
        final largeContent = StringBuffer('# Large Document Test\n\n');
        for (int i = 0; i < 100; i++) {
          largeContent.write('## Section $i\n\n');
          largeContent.write('Lorem ipsum dolor sit amet, consectetur adipiscing elit. ');
          largeContent.write('Sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. ');
          largeContent.write('Ut enim ad minim veniam, quis nostrud exercitation ullamco.\n\n');
        }

        final textField = find.byType(TextField).first;
        await tester.enterText(textField, largeContent.toString());
        await tester.pump();

        // Verify reasonable performance during editing (no specific assertion, just that it completes)
        expect(find.byType(TextField), findsAtLeastNWidgets(1));

        // Test save performance is acceptable
        await tester.pump(const Duration(milliseconds: 1000)); // Allow time for save

        // Switch to preview to test rendering performance
        await tester.tap(find.text('Styled'));
        await tester.pumpAndSettle();

        expect(find.byType(Markdown), findsOneWidget);
      });

      testWidgets('should handle rapid editing without lag', (WidgetTester tester) async {
        // Test editor performance with rapid text input
        app.main();
        await tester.pumpAndSettle();
        await tester.pumpAndSettle(const Duration(seconds: 2));

        final newDocButton = find.byIcon(Icons.note_add_outlined).first;
        await tester.tap(newDocButton);
        await tester.pumpAndSettle(const Duration(seconds: 1));

        final textField = find.byType(TextField).first;

        // Simulate rapid typing
        const rapidText = [
          'Rapid typing test',
          'Adding more content quickly',
          'And even more content',
          'Testing performance',
          'Final rapid addition'
        ];

        for (final text in rapidText) {
          await tester.enterText(textField, text);
          await tester.pump(const Duration(milliseconds: 50)); // Rapid succession
        }

        // Verify UI responsiveness - should still be functional
        expect(find.byType(TextField), findsAtLeastNWidgets(1));

        final textFieldWidget = tester.widget<TextField>(textField);
        expect(textFieldWidget.controller?.text, contains('Final rapid addition'));
      });
    });

    group('Cross-Platform Tests', () {
      testWidgets('should work consistently across different screen sizes', (WidgetTester tester) async {
        // Test mobile screen size
        await tester.binding.setSurfaceSize(const Size(375, 667)); // Mobile

        app.main();
        await tester.pumpAndSettle();
        await tester.pumpAndSettle(const Duration(seconds: 2));

        // Mobile layout test
        final newDocButton = find.byIcon(Icons.note_add_outlined);
        expect(newDocButton, findsOneWidget);
        await tester.tap(newDocButton);
        await tester.pumpAndSettle();

        expect(find.byType(MarkdownEditorScreen), findsOneWidget);
        expect(find.byType(TextField), findsAtLeastNWidgets(1));

        // Test tablet size
        await tester.binding.setSurfaceSize(const Size(768, 1024)); // Tablet
        await tester.pumpAndSettle();

        // Should still work
        expect(find.byType(TextField), findsAtLeastNWidgets(1));

        // Test desktop size
        await tester.binding.setSurfaceSize(const Size(1440, 900)); // Desktop
        await tester.pumpAndSettle();

        // Desktop may show split view, but editor should still be accessible
        expect(find.byType(TextField), findsAtLeastNWidgets(1));
      });

      testWidgets('should handle platform-specific behaviors correctly', (WidgetTester tester) async {
        // Test document creation with platform considerations
        app.main();
        await tester.pumpAndSettle();
        await tester.pumpAndSettle(const Duration(seconds: 2));

        final newDocButton = find.byIcon(Icons.note_add_outlined).first;
        await tester.tap(newDocButton);
        await tester.pumpAndSettle(const Duration(seconds: 1));

        const platformTestContent = '''# Platform Test

This document tests platform-specific behaviors:

- File saving
- Keyboard shortcuts
- Navigation patterns

## Web Specific
Testing web-specific functionality.

## Mobile Specific
Testing mobile-specific functionality.
''';

        final textField = find.byType(TextField).first;
        await tester.enterText(textField, platformTestContent);
        await tester.pump();

        // Test auto-save works regardless of platform
        await tester.pump(const Duration(milliseconds: 500));

        // Navigate and verify persistence
        await tester.tap(find.text('Documents'));
        await tester.pumpAndSettle();

        expect(find.text('Platform Test'), findsOneWidget);
      });
    });

    // Cleanup after tests (no-op)
  });
}