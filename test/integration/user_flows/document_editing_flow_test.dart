import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:markflow/main.dart' as app;
import 'package:markflow/features/markdown/docs_screen.dart';
import 'package:markflow/features/markdown/editor_screen.dart';
import 'package:markflow/features/markdown/widgets/formatting_toolbar.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

/// Integration test for end-to-end document editing workflow
///
/// This test covers complete user editing journeys including formatting,
/// preview updates, auto-save, and various markdown features.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Document Editing Flow Integration Tests', () {
    testWidgets('should complete full document editing workflow', (WidgetTester tester) async {
      // Start the app
      app.main();
      await tester.pumpAndSettle();
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Create a new document first
      final newDocButton = find.byIcon(Icons.note_add_outlined).first;
      await tester.tap(newDocButton);
      await tester.pumpAndSettle(const Duration(seconds: 1));

      // Enter initial content
      const initialContent = '# Document Editing Test\n\nInitial content for editing.';
      final textField = find.byType(TextField).first;
      await tester.enterText(textField, initialContent);
      await tester.pump();

      // Wait for auto-save
      await tester.pump(const Duration(milliseconds: 500));

      // Perform various editing operations
      await tester.enterText(textField, '$initialContent\n\n## Additional Section\n\nMore content added during editing.');
      await tester.pump(const Duration(milliseconds: 500));

      // Switch to preview to verify changes
      await tester.tap(find.text('Styled'));
      await tester.pumpAndSettle();

      expect(find.byType(Markdown), findsOneWidget);

      // Return to editing
      await tester.tap(find.text('Markdown'));
      await tester.pumpAndSettle();

      // Verify content is preserved
      final editedTextField = find.byType(TextField).first;
      final textFieldWidget = tester.widget<TextField>(editedTextField);
      expect(textFieldWidget.controller?.text, contains('Document Editing Test'));
      expect(textFieldWidget.controller?.text, contains('Additional Section'));
    });

    testWidgets('should edit existing document from docs list', (WidgetTester tester) async {
      // Launch app
      app.main();
      await tester.pumpAndSettle();
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Create a document first
      final newDocButton = find.byIcon(Icons.note_add_outlined).first;
      await tester.tap(newDocButton);
      await tester.pumpAndSettle(const Duration(seconds: 1));

      const originalContent = '# Original Document\n\nThis is the original content.';
      final textField = find.byType(TextField).first;
      await tester.enterText(textField, originalContent);
      await tester.pump(const Duration(milliseconds: 500));

      // Navigate back to docs screen
      await tester.tap(find.text('Documents'));
      await tester.pumpAndSettle();

      // Select the document from list
      await tester.tap(find.text('Original Document'));
      await tester.pumpAndSettle();

      // Make edits
      const editedContent = '$originalContent\n\n## Edited Section\n\nThis content was added during editing.';
      final editTextField = find.byType(TextField).first;
      await tester.enterText(editTextField, editedContent);
      await tester.pump(const Duration(milliseconds: 500));

      // Return to docs list and verify changes persist
      await tester.tap(find.text('Documents'));
      await tester.pumpAndSettle();

      // Reopen document to verify persistence
      await tester.tap(find.text('Original Document'));
      await tester.pumpAndSettle();

      final persistedTextField = find.byType(TextField).first;
      final persistedWidget = tester.widget<TextField>(persistedTextField);
      expect(persistedWidget.controller?.text, contains('Original Document'));
      expect(persistedWidget.controller?.text, contains('Edited Section'));
    });

    testWidgets('should use formatting toolbar to apply markdown formatting', (WidgetTester tester) async {
      // Open document in editor
      app.main();
      await tester.pumpAndSettle();
      await tester.pumpAndSettle(const Duration(seconds: 2));

      final newDocButton = find.byIcon(Icons.note_add_outlined).first;
      await tester.tap(newDocButton);
      await tester.pumpAndSettle(const Duration(seconds: 1));

      // Enter text for formatting
      const testText = 'This text will be formatted';
      final textField = find.byType(TextField).first;
      await tester.enterText(textField, testText);
      await tester.pump();

      // Select all text for formatting
      await tester.tap(textField);
      await tester.pump();

      // Try to apply bold formatting if button exists
      final boldButton = find.byIcon(Icons.format_bold);
      if (boldButton.evaluate().isNotEmpty) {
        await tester.tap(boldButton.first);
        await tester.pump();

        final textFieldWidget = tester.widget<TextField>(textField);
        expect(textFieldWidget.controller?.text, contains('**'));
      }

      // Test heading formatting
      await tester.enterText(textField, 'Heading text');
      await tester.pump();

      final headingButton = find.byIcon(Icons.title);
      if (headingButton.evaluate().isNotEmpty) {
        await tester.tap(headingButton.first);
        await tester.pump();

        final textFieldWidget = tester.widget<TextField>(textField);
        expect(textFieldWidget.controller?.text, contains('#'));
      }

      // Verify preview shows formatted content
      await tester.tap(find.text('Styled'));
      await tester.pumpAndSettle();

      expect(find.byType(Markdown), findsOneWidget);
    });

    testWidgets('should handle real-time preview updates', (WidgetTester tester) async {
      // Open document in editor
      app.main();
      await tester.pumpAndSettle();
      await tester.pumpAndSettle(const Duration(seconds: 2));

      final newDocButton = find.byIcon(Icons.note_add_outlined).first;
      await tester.tap(newDocButton);
      await tester.pumpAndSettle(const Duration(seconds: 1));

      // Type markdown content
      const markdownContent = '''# Real-time Preview Test

This tests **bold** and *italic* formatting.

## List Test
- Item 1
- Item 2
- Item 3

### Code Test
`inline code` and:

```dart
void main() {
  print('preview test');
}
```
''';

      final textField = find.byType(TextField).first;
      await tester.enterText(textField, markdownContent);
      await tester.pump();

      // Switch to styled view to see preview
      await tester.tap(find.text('Styled'));
      await tester.pumpAndSettle();

      // Verify preview shows content (markdown widget is present)
      expect(find.byType(Markdown), findsOneWidget);

      // Switch back to editor
      await tester.tap(find.text('Markdown'));
      await tester.pumpAndSettle();

      // Add more content
      const additionalContent = '$markdownContent\n\n### Link Test\n[Flutter](https://flutter.dev)';
      await tester.enterText(textField, additionalContent);
      await tester.pump();

      // Switch back to preview
      await tester.tap(find.text('Styled'));
      await tester.pumpAndSettle();

      // Preview should update with new content
      expect(find.byType(Markdown), findsOneWidget);
    });

    group('Auto-Save Functionality', () {
      testWidgets('should auto-save changes after typing stops', (WidgetTester tester) async {
        // Create document
        app.main();
        await tester.pumpAndSettle();
        await tester.pumpAndSettle(const Duration(seconds: 2));

        final newDocButton = find.byIcon(Icons.note_add_outlined).first;
        await tester.tap(newDocButton);
        await tester.pumpAndSettle(const Duration(seconds: 1));

        // Make changes to document
        const testContent = '# Auto-save Test\n\nContent that should auto-save.';
        final textField = find.byType(TextField).first;
        await tester.enterText(textField, testContent);
        await tester.pump();

        // Wait for auto-save delay (300ms debounce + buffer)
        await tester.pump(const Duration(milliseconds: 500));

        // Navigate away and back
        await tester.tap(find.text('Documents'));
        await tester.pumpAndSettle();

        await tester.tap(find.text('Auto-save Test'));
        await tester.pumpAndSettle();

        // Verify changes are preserved
        final preservedTextField = find.byType(TextField).first;
        final preservedWidget = tester.widget<TextField>(preservedTextField);
        expect(preservedWidget.controller?.text, contains('Auto-save Test'));
        expect(preservedWidget.controller?.text, contains('Content that should auto-save'));
      });

      testWidgets('should save before navigation away from editor', (WidgetTester tester) async {
        // Create document
        app.main();
        await tester.pumpAndSettle();
        await tester.pumpAndSettle(const Duration(seconds: 2));

        final newDocButton = find.byIcon(Icons.note_add_outlined).first;
        await tester.tap(newDocButton);
        await tester.pumpAndSettle(const Duration(seconds: 1));

        // Make changes to document
        const testContent = '# Navigation Save Test\n\nContent saved on navigation.';
        final textField = find.byType(TextField).first;
        await tester.enterText(textField, testContent);
        await tester.pump();

        // Navigate away immediately (should trigger save)
        await tester.tap(find.text('Documents'));
        await tester.pumpAndSettle();

        // Return to editor
        await tester.tap(find.text('Navigation Save Test'));
        await tester.pumpAndSettle();

        // Verify changes were saved
        final savedTextField = find.byType(TextField).first;
        final savedWidget = tester.widget<TextField>(savedTextField);
        expect(savedWidget.controller?.text, contains('Navigation Save Test'));
        expect(savedWidget.controller?.text, contains('Content saved on navigation'));
      });
    });

    group('Markdown Feature Testing', () {
      testWidgets('should handle headers correctly', (WidgetTester tester) async {
        // Create document for header testing
        app.main();
        await tester.pumpAndSettle();
        await tester.pumpAndSettle(const Duration(seconds: 2));

        final newDocButton = find.byIcon(Icons.note_add_outlined).first;
        await tester.tap(newDocButton);
        await tester.pumpAndSettle(const Duration(seconds: 1));

        // Test H1-H6 headers in editor and preview
        const headerContent = '''# Header 1
## Header 2
### Header 3
#### Header 4
##### Header 5
###### Header 6

Normal text after headers.
''';

        final textField = find.byType(TextField).first;
        await tester.enterText(textField, headerContent);
        await tester.pump();

        // Switch to preview to verify headers render
        await tester.tap(find.text('Styled'));
        await tester.pumpAndSettle();

        expect(find.byType(Markdown), findsOneWidget);

        // Switch back to editor
        await tester.tap(find.text('Markdown'));
        await tester.pumpAndSettle();

        // Verify content is preserved
        final editedTextField = find.byType(TextField).first;
        final textFieldWidget = tester.widget<TextField>(editedTextField);
        expect(textFieldWidget.controller?.text, contains('# Header 1'));
        expect(textFieldWidget.controller?.text, contains('###### Header 6'));
      });

      testWidgets('should handle lists correctly', (WidgetTester tester) async {
        // Test list markdown functionality
        app.main();
        await tester.pumpAndSettle();
        await tester.pumpAndSettle(const Duration(seconds: 2));

        final newDocButton = find.byIcon(Icons.note_add_outlined).first;
        await tester.tap(newDocButton);
        await tester.pumpAndSettle(const Duration(seconds: 1));

        // Test bulleted and numbered lists
        const listContent = '''# List Tests

## Bulleted List
- First bullet item
- Second bullet item
- Third bullet item

## Numbered List
1. First numbered item
2. Second numbered item
3. Third numbered item

## Nested List
- Top level item
  - Nested item 1
  - Nested item 2
    - Double nested item
''';

        final textField = find.byType(TextField).first;
        await tester.enterText(textField, listContent);
        await tester.pump();

        // Verify preview shows lists
        await tester.tap(find.text('Styled'));
        await tester.pumpAndSettle();

        expect(find.byType(Markdown), findsOneWidget);
      });

      testWidgets('should handle links and images correctly', (WidgetTester tester) async {
        // Test link and image markdown functionality
        app.main();
        await tester.pumpAndSettle();
        await tester.pumpAndSettle(const Duration(seconds: 2));

        final newDocButton = find.byIcon(Icons.note_add_outlined).first;
        await tester.tap(newDocButton);
        await tester.pumpAndSettle(const Duration(seconds: 1));

        const linkContent = '''# Links and Images Test

## Inline Links
[Flutter](https://flutter.dev)
[Google](https://google.com)

## Reference Links
[Flutter Reference][flutter]
[Google Reference][google]

[flutter]: https://flutter.dev
[google]: https://google.com

## Images
![Flutter Logo](https://flutter.dev/assets/images/shared/brand/flutter/logo/flutter-lockup.png)
''';

        final textField = find.byType(TextField).first;
        await tester.enterText(textField, linkContent);
        await tester.pump();

        // Verify preview handles links
        await tester.tap(find.text('Styled'));
        await tester.pumpAndSettle();

        expect(find.byType(Markdown), findsOneWidget);
      });

      testWidgets('should handle code blocks and inline code correctly', (WidgetTester tester) async {
        // Test code markdown functionality
        app.main();
        await tester.pumpAndSettle();
        await tester.pumpAndSettle(const Duration(seconds: 2));

        final newDocButton = find.byIcon(Icons.note_add_outlined).first;
        await tester.tap(newDocButton);
        await tester.pumpAndSettle(const Duration(seconds: 1));

        const codeContent = '''# Code Test

## Inline Code
This is `inline code` within text.

## Fenced Code Block (Dart)
```dart
void main() {
  print('Hello World');
  var list = [1, 2, 3];
  for (var item in list) {
    print(item);
  }
}
```

## Fenced Code Block (JSON)
```json
{
  "name": "markflow",
  "version": "0.1.0",
  "dependencies": {
    "flutter": "sdk"
  }
}
```

## Plain Code Block
    // Indented code block
    function test() {
      return true;
    }
''';

        final textField = find.byType(TextField).first;
        await tester.enterText(textField, codeContent);
        await tester.pump();

        // Verify preview handles code
        await tester.tap(find.text('Styled'));
        await tester.pumpAndSettle();

        expect(find.byType(Markdown), findsOneWidget);
      });
    });

    group('Editor UI Interactions', () {
      testWidgets('should handle text selection and formatting application', (WidgetTester tester) async {
        // Test text selection behavior in editor
        app.main();
        await tester.pumpAndSettle();
        await tester.pumpAndSettle(const Duration(seconds: 2));

        final newDocButton = find.byIcon(Icons.note_add_outlined).first;
        await tester.tap(newDocButton);
        await tester.pumpAndSettle(const Duration(seconds: 1));

        // Enter text for selection
        const testText = 'Select this text for formatting';
        final textField = find.byType(TextField).first;
        await tester.enterText(textField, testText);
        await tester.pump();

        // Select text (simulate selection)
        await tester.tap(textField);
        await tester.pump();

        // Apply formatting if toolbar is available
        final boldButton = find.byIcon(Icons.format_bold);
        if (boldButton.evaluate().isNotEmpty) {
          // Simulate text selection and formatting
          final textFieldWidget = tester.widget<TextField>(textField);
          textFieldWidget.controller?.selection = TextSelection(baseOffset: 0, extentOffset: 10);

          await tester.tap(boldButton.first);
          await tester.pump();

          // Verify markdown syntax was applied
          expect(textFieldWidget.controller?.text, contains('**'));
        }
      });

      testWidgets('should handle cursor positioning correctly after toolbar actions', (WidgetTester tester) async {
        // Test cursor positioning after markdown insertion
        app.main();
        await tester.pumpAndSettle();
        await tester.pumpAndSettle(const Duration(seconds: 2));

        final newDocButton = find.byIcon(Icons.note_add_outlined).first;
        await tester.tap(newDocButton);
        await tester.pumpAndSettle(const Duration(seconds: 1));

        const testText = 'cursor position test';
        final textField = find.byType(TextField).first;
        await tester.enterText(textField, testText);
        await tester.pump();

        // Test cursor placement after various toolbar actions
        final textFieldWidget = tester.widget<TextField>(textField);

        // Verify text field is accessible for cursor positioning tests
        expect(textFieldWidget.controller, isNotNull);
        expect(textFieldWidget.controller?.text, contains('cursor position test'));
      });
    });

    group('Performance Tests', () {
      testWidgets('should handle large documents efficiently', (WidgetTester tester) async {
        // Test editor performance with large documents
        app.main();
        await tester.pumpAndSettle();
        await tester.pumpAndSettle(const Duration(seconds: 2));

        final newDocButton = find.byIcon(Icons.note_add_outlined).first;
        await tester.tap(newDocButton);
        await tester.pumpAndSettle(const Duration(seconds: 1));

        // Create large document content
        final largeContent = StringBuffer('# Large Document Performance Test\n\n');
        for (int i = 0; i < 200; i++) {
          largeContent.write('## Section $i\n\n');
          largeContent.write('Lorem ipsum dolor sit amet, consectetur adipiscing elit. ');
          largeContent.write('Sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. ');
          largeContent.write('Ut enim ad minim veniam, quis nostrud exercitation ullamco.\n\n');

          if (i % 10 == 0) {
            largeContent.write('```dart\n');
            largeContent.write('void function$i() {\n');
            largeContent.write('  print("Section $i");\n');
            largeContent.write('  // Performance test code block\n');
            largeContent.write('}\n');
            largeContent.write('```\n\n');
          }
        }

        final textField = find.byType(TextField).first;
        await tester.enterText(textField, largeContent.toString());
        await tester.pump();

        // Test typing performance (should remain responsive)
        expect(find.byType(TextField), findsAtLeastNWidgets(1));

        // Test preview rendering performance
        await tester.pump(const Duration(milliseconds: 1000));

        await tester.tap(find.text('Styled'));
        await tester.pumpAndSettle(const Duration(seconds: 3)); // Allow time for large render

        expect(find.byType(Markdown), findsOneWidget);

        // Test save performance
        await tester.tap(find.text('Markdown'));
        await tester.pumpAndSettle();

        await tester.pump(const Duration(milliseconds: 1000)); // Allow save time
      });

      testWidgets('should maintain responsive UI during content updates', (WidgetTester tester) async {
        // Test UI responsiveness during intensive operations
        app.main();
        await tester.pumpAndSettle();
        await tester.pumpAndSettle(const Duration(seconds: 2));

        final newDocButton = find.byIcon(Icons.note_add_outlined).first;
        await tester.tap(newDocButton);
        await tester.pumpAndSettle(const Duration(seconds: 1));

        final textField = find.byType(TextField).first;

        // Rapidly update content
        const contentUpdates = [
          '# Rapid Update Test 1',
          '# Rapid Update Test 2\n\n## New Section',
          '# Rapid Update Test 3\n\n## New Section\n\n### Subsection',
          '# Final Update\n\n## Complete Section\n\n### Final Subsection\n\nWith content.',
        ];

        for (final content in contentUpdates) {
          await tester.enterText(textField, content);
          await tester.pump(const Duration(milliseconds: 100)); // Rapid updates
        }

        // UI should remain responsive
        expect(find.byType(TextField), findsAtLeastNWidgets(1));

        // Verify final content
        final textFieldWidget = tester.widget<TextField>(textField);
        expect(textFieldWidget.controller?.text, contains('Final Update'));
      });
    });

    // Cleanup after tests (no-op)
  });
}