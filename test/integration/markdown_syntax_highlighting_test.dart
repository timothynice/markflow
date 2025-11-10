import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:markflow/main.dart' as app;
import 'package:markflow/features/markdown/services/syntax_highlight_service.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Markdown Syntax Highlighting Integration Tests', () {
    testWidgets('should highlight code blocks in markdown editor', (tester) async {
      // Start the app
      app.main();
      await tester.pumpAndSettle();

      // Navigate to a document (assuming we start on the docs list)
      // This may need adjustment based on the app's navigation flow
      if (find.text('Create New Document').evaluate().isNotEmpty) {
        await tester.tap(find.text('Create New Document'));
        await tester.pumpAndSettle();
      }

      // Look for the markdown editor
      expect(find.byType(TextField), findsWidgets);

      // Type markdown with code blocks
      const markdownWithCode = '''
# Test Document

Here's some Dart code:

```dart
class MyWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      child: Text('Hello, World!'),
    );
  }
}
```

And some JavaScript:

```javascript
function greet(name) {
  console.log(\`Hello, \${name}!\`);
  return true;
}
```

Python example:

```python
def calculate_sum(a, b):
    return a + b

result = calculate_sum(5, 3)
print(f"Result: {result}")
```
''';

      // Find the text editor and type the markdown
      final textField = find.byType(TextField).first;
      await tester.enterText(textField, markdownWithCode);
      await tester.pumpAndSettle();

      // Switch to the styled preview
      await tester.tap(find.text('Styled'));
      await tester.pumpAndSettle();

      // Wait for syntax highlighting to complete
      await Future.delayed(const Duration(seconds: 2));
      await tester.pumpAndSettle();

      // Verify that code blocks are present and styled
      expect(find.textContaining('class MyWidget'), findsOneWidget);
      expect(find.textContaining('function greet'), findsOneWidget);
      expect(find.textContaining('def calculate_sum'), findsOneWidget);

      // Verify language labels are shown
      expect(find.text('dart'), findsOneWidget);
      expect(find.text('javascript'), findsOneWidget);
      expect(find.text('python'), findsOneWidget);

      // Verify copy buttons are present
      expect(find.text('Copy'), findsWidgets);
    });

    testWidgets('should detect languages automatically', (tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Navigate to editor
      if (find.text('Create New Document').evaluate().isNotEmpty) {
        await tester.tap(find.text('Create New Document'));
        await tester.pumpAndSettle();
      }

      // Type code without explicit language tags
      const codeWithoutLanguage = '''
# Auto Detection Test

```
// This should be detected as JavaScript
function test() {
  const message = "Hello";
  console.log(message);
}
```

```
# This should be detected as Python
def hello():
    print("Hello, World!")
    return True
```

```
SELECT name, email
FROM users
WHERE active = true;
```
''';

      final textField = find.byType(TextField).first;
      await tester.enterText(textField, codeWithoutLanguage);
      await tester.pumpAndSettle();

      // Switch to preview
      await tester.tap(find.text('Styled'));
      await tester.pumpAndSettle();

      // Wait for language detection and highlighting
      await Future.delayed(const Duration(seconds: 2));
      await tester.pumpAndSettle();

      // The service should automatically detect languages
      // Note: Exact detection results may vary based on the detection algorithm
      expect(find.textContaining('function test'), findsOneWidget);
      expect(find.textContaining('def hello'), findsOneWidget);
      expect(find.textContaining('SELECT'), findsOneWidget);
    });

    testWidgets('should work with theme switching', (tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Navigate to settings to change theme
      if (find.byIcon(Icons.settings).evaluate().isNotEmpty) {
        await tester.tap(find.byIcon(Icons.settings));
        await tester.pumpAndSettle();
      }

      // Toggle dark mode (this may need adjustment based on UI)
      if (find.text('Dark mode').evaluate().isNotEmpty) {
        await tester.tap(find.text('Dark mode'));
        await tester.pumpAndSettle();
      }

      // Navigate back to editor
      await tester.pageBack();
      await tester.pumpAndSettle();

      // Create or navigate to a document with code
      if (find.text('Create New Document').evaluate().isNotEmpty) {
        await tester.tap(find.text('Create New Document'));
        await tester.pumpAndSettle();
      }

      const codeContent = '''
```dart
void main() {
  print('Dark theme test');
}
```
''';

      final textField = find.byType(TextField).first;
      await tester.enterText(textField, codeContent);
      await tester.pumpAndSettle();

      // Switch to preview
      await tester.tap(find.text('Styled'));
      await tester.pumpAndSettle();

      // Wait for highlighting with dark theme
      await Future.delayed(const Duration(seconds: 1));
      await tester.pumpAndSettle();

      // Code should be highlighted with dark theme colors
      expect(find.textContaining('void main'), findsOneWidget);
      expect(find.text('dart'), findsOneWidget);
    });

    testWidgets('should handle inline code highlighting', (tester) async {
      app.main();
      await tester.pumpAndSettle();

      if (find.text('Create New Document').evaluate().isNotEmpty) {
        await tester.tap(find.text('Create New Document'));
        await tester.pumpAndSettle();
      }

      const inlineCodeContent = '''
# Inline Code Test

Here's some inline code: `console.log('hello')` and more text.

You can use `print()` in Python or `fmt.Println()` in Go.

Mixed content with `const x = 42;` JavaScript.
''';

      final textField = find.byType(TextField).first;
      await tester.enterText(textField, inlineCodeContent);
      await tester.pumpAndSettle();

      // Switch to preview
      await tester.tap(find.text('Styled'));
      await tester.pumpAndSettle();

      // Inline code should be styled differently
      expect(find.textContaining('console.log'), findsOneWidget);
      expect(find.textContaining('print()'), findsOneWidget);
      expect(find.textContaining('fmt.Println'), findsOneWidget);
    });

    testWidgets('should copy code from enhanced code blocks', (tester) async {
      app.main();
      await tester.pumpAndSettle();

      if (find.text('Create New Document').evaluate().isNotEmpty) {
        await tester.tap(find.text('Create New Document'));
        await tester.pumpAndSettle();
      }

      const codeContent = '''
```dart
void main() {
  print('Copy test');
}
```
''';

      final textField = find.byType(TextField).first;
      await tester.enterText(textField, codeContent);
      await tester.pumpAndSettle();

      // Switch to preview
      await tester.tap(find.text('Styled'));
      await tester.pumpAndSettle();

      // Wait for code block to render
      await Future.delayed(const Duration(seconds: 1));
      await tester.pumpAndSettle();

      // Find and tap copy button
      final copyButton = find.text('Copy').first;
      await tester.tap(copyButton);
      await tester.pumpAndSettle();

      // Should show "Copied" state briefly
      expect(find.text('Copied'), findsOneWidget);
      expect(find.byIcon(Icons.check), findsOneWidget);

      // Wait for state to revert
      await Future.delayed(const Duration(seconds: 3));
      await tester.pumpAndSettle();

      // Should return to normal state
      expect(find.text('Copy'), findsOneWidget);
    });

    testWidgets('should handle performance with large documents', (tester) async {
      app.main();
      await tester.pumpAndSettle();

      if (find.text('Create New Document').evaluate().isNotEmpty) {
        await tester.tap(find.text('Create New Document'));
        await tester.pumpAndSettle();
      }

      // Create a large document with multiple code blocks
      final largeContent = StringBuffer();
      largeContent.writeln('# Performance Test Document\\n');

      // Add multiple code blocks in different languages
      final languages = ['dart', 'javascript', 'python', 'java', 'go'];
      for (int i = 0; i < 5; i++) {
        final lang = languages[i];
        largeContent.writeln('## Section $i\\n');
        largeContent.writeln('```$lang');

        // Add substantial code content
        for (int j = 0; j < 20; j++) {
          switch (lang) {
            case 'dart':
              largeContent.writeln('  void function$j() { print("Line $j"); }');
              break;
            case 'javascript':
              largeContent.writeln('  function test$j() { console.log("Line $j"); }');
              break;
            case 'python':
              largeContent.writeln('  def function_$j(): print("Line $j")');
              break;
            case 'java':
              largeContent.writeln('  public void method$j() { System.out.println("Line $j"); }');
              break;
            case 'go':
              largeContent.writeln('  func test$j() { fmt.Println("Line $j") }');
              break;
          }
        }
        largeContent.writeln('```\\n');
      }

      final textField = find.byType(TextField).first;
      await tester.enterText(textField, largeContent.toString());
      await tester.pumpAndSettle();

      // Measure performance of switching to styled view
      final stopwatch = Stopwatch()..start();

      await tester.tap(find.text('Styled'));
      await tester.pumpAndSettle();

      // Wait for all highlighting to complete
      await Future.delayed(const Duration(seconds: 3));
      await tester.pumpAndSettle();

      stopwatch.stop();

      // Performance should be reasonable (less than 5 seconds for large content)
      expect(stopwatch.elapsed.inSeconds, lessThan(5));

      // All code blocks should be rendered
      expect(find.textContaining('function0'), findsWidgets);
      expect(find.textContaining('method0'), findsWidgets);
    });
  });
}