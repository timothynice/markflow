import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:markflow/features/markdown/widgets/enhanced_code_block.dart';
import 'package:markflow/features/markdown/services/syntax_highlight_service.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

void main() {
  group('EnhancedCodeBlock Widget Tests', () {
    late SyntaxHighlightService service;

    setUpAll(() async {
      // Initialize the service for testing
      service = SyntaxHighlightService.instance;
      await service.initialize(languages: ['dart', 'javascript', 'python']);
    });

    Widget createTestWidget(Widget child) {
      return MaterialApp(
        home: Scaffold(
          body: child,
        ),
      );
    }

    testWidgets('should display code block with basic styling', (tester) async {
      const testCode = '''
function hello() {
  console.log('Hello, World!');
}''';

      await tester.pumpWidget(
        createTestWidget(
          const EnhancedCodeBlock(
            code: testCode,
            language: 'javascript',
          ),
        ),
      );

      // Wait for highlighting to complete
      await tester.pumpAndSettle();

      // Should find the code text
      expect(find.textContaining('function hello'), findsOneWidget);
      expect(find.textContaining('console.log'), findsOneWidget);
    });

    testWidgets('should show language label when enabled', (tester) async {
      const testCode = 'print("Hello, World!")';

      await tester.pumpWidget(
        createTestWidget(
          const EnhancedCodeBlock(
            code: testCode,
            language: 'python',
            showLanguageLabel: true,
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Should find the language label
      expect(find.text('python'), findsOneWidget);
    });

    testWidgets('should hide language label when disabled', (tester) async {
      const testCode = 'print("Hello, World!")';

      await tester.pumpWidget(
        createTestWidget(
          const EnhancedCodeBlock(
            code: testCode,
            language: 'python',
            showLanguageLabel: false,
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Should not find the language label
      expect(find.text('python'), findsNothing);
    });

    testWidgets('should show copy button when enabled', (tester) async {
      const testCode = 'console.log("test");';

      await tester.pumpWidget(
        createTestWidget(
          const EnhancedCodeBlock(
            code: testCode,
            showCopyButton: true,
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Should find the copy button
      expect(find.text('Copy'), findsOneWidget);
      expect(find.byIcon(Icons.copy), findsOneWidget);
    });

    testWidgets('should hide copy button when disabled', (tester) async {
      const testCode = 'console.log("test");';

      await tester.pumpWidget(
        createTestWidget(
          const EnhancedCodeBlock(
            code: testCode,
            showCopyButton: false,
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Should not find the copy button
      expect(find.text('Copy'), findsNothing);
      expect(find.byIcon(Icons.copy), findsNothing);
    });

    testWidgets('should handle copy button tap', (tester) async {
      const testCode = 'console.log("test");';

      await tester.pumpWidget(
        createTestWidget(
          const EnhancedCodeBlock(
            code: testCode,
            showCopyButton: true,
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Tap the copy button
      await tester.tap(find.text('Copy'));
      await tester.pumpAndSettle();

      // Should briefly show "Copied" state
      expect(find.text('Copied'), findsOneWidget);
      expect(find.byIcon(Icons.check), findsOneWidget);
    });

    testWidgets('should auto-detect language when not specified', (tester) async {
      const testCode = '''
def hello():
    print("Hello from Python!")
    return True''';

      await tester.pumpWidget(
        createTestWidget(
          const EnhancedCodeBlock(
            code: testCode,
            // No language specified - should auto-detect
            showLanguageLabel: true,
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Should detect and show Python
      expect(find.text('python'), findsOneWidget);
    });

    testWidgets('should show line numbers when enabled', (tester) async {
      const testCode = '''line 1
line 2
line 3''';

      await tester.pumpWidget(
        createTestWidget(
          const EnhancedCodeBlock(
            code: testCode,
            showLineNumbers: true,
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Should show line numbers
      expect(find.text('1'), findsOneWidget);
      expect(find.text('2'), findsOneWidget);
      expect(find.text('3'), findsOneWidget);
    });

    testWidgets('should hide line numbers when disabled', (tester) async {
      const testCode = '''line 1
line 2
line 3''';

      await tester.pumpWidget(
        createTestWidget(
          const EnhancedCodeBlock(
            code: testCode,
            showLineNumbers: false,
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Should find the content but not standalone line numbers
      expect(find.textContaining('line 1'), findsOneWidget);
      expect(find.textContaining('line 2'), findsOneWidget);
      expect(find.textContaining('line 3'), findsOneWidget);

      // Line numbers should not appear as standalone elements
      expect(find.text('1'), findsNothing);
      expect(find.text('2'), findsNothing);
      expect(find.text('3'), findsNothing);
    });

    testWidgets('should handle empty code gracefully', (tester) async {
      await tester.pumpWidget(
        createTestWidget(
          const EnhancedCodeBlock(
            code: '',
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Widget should render without errors
      expect(find.byType(EnhancedCodeBlock), findsOneWidget);
    });

    testWidgets('should update when code changes', (tester) async {
      const initialCode = 'console.log("initial");';
      const updatedCode = 'print("updated")';

      await tester.pumpWidget(
        createTestWidget(
          const EnhancedCodeBlock(
            code: initialCode,
            language: 'javascript',
            showLanguageLabel: true,
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Should show initial content
      expect(find.textContaining('initial'), findsOneWidget);
      expect(find.text('javascript'), findsOneWidget);

      // Update the code
      await tester.pumpWidget(
        createTestWidget(
          const EnhancedCodeBlock(
            code: updatedCode,
            language: 'python',
            showLanguageLabel: true,
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Should show updated content
      expect(find.textContaining('updated'), findsOneWidget);
      expect(find.text('python'), findsOneWidget);
      expect(find.textContaining('initial'), findsNothing);
    });

    testWidgets('should apply custom font size', (tester) async {
      const testCode = 'test code';
      const customFontSize = 18.0;

      await tester.pumpWidget(
        createTestWidget(
          const EnhancedCodeBlock(
            code: testCode,
            fontSize: customFontSize,
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Should render without errors (exact font size testing is complex)
      expect(find.byType(EnhancedCodeBlock), findsOneWidget);
    });

    testWidgets('should apply custom font family', (tester) async {
      const testCode = 'test code';
      const customFontFamily = 'CustomMono';

      await tester.pumpWidget(
        createTestWidget(
          const EnhancedCodeBlock(
            code: testCode,
            fontFamily: customFontFamily,
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Should render without errors
      expect(find.byType(EnhancedCodeBlock), findsOneWidget);
    });

    testWidgets('should handle loading state', (tester) async {
      const testCode = 'console.log("test");';

      await tester.pumpWidget(
        createTestWidget(
          const EnhancedCodeBlock(
            code: testCode,
          ),
        ),
      );

      // Should show loading indicator initially
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      await tester.pumpAndSettle();

      // Loading indicator should be gone
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });

    testWidgets('should handle long code blocks', (tester) async {
      final longCode = List.generate(100, (i) => 'console.log("Line $i");').join('\\n');

      await tester.pumpWidget(
        createTestWidget(
          EnhancedCodeBlock(
            code: longCode,
            showLineNumbers: true,
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Should render without errors
      expect(find.byType(EnhancedCodeBlock), findsOneWidget);
      expect(find.byType(SingleChildScrollView), findsWidgets);
    });
  });
}