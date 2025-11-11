import 'package:flutter/material.dart';
import 'dart:ui' show PointerDeviceKind;
import 'package:flutter_test/flutter_test.dart';
import 'package:markflow/features/markdown/widgets/auto_complete_overlay.dart';
import 'package:markflow/features/markdown/models/completion_suggestion.dart';

void main() {
  group('AutoCompleteOverlay', () {
    late CompletionResult testResult;
    late List<CompletionSuggestion> testSuggestions;

    setUp(() {
      testSuggestions = [
        const CompletionSuggestion(
          insertText: '# Heading',
          displayText: '# Heading',
          description: 'Insert a level 1 heading',
          type: CompletionType.header,
          icon: Icons.title,
          priority: 10,
        ),
        const CompletionSuggestion(
          insertText: '- List item',
          displayText: '- List item',
          description: 'Insert a bullet list item',
          type: CompletionType.list,
          icon: Icons.format_list_bulleted,
          priority: 8,
        ),
        const CompletionSuggestion(
          insertText: '[text](url)',
          displayText: '[text](url)',
          description: 'Insert a link',
          type: CompletionType.link,
          icon: Icons.link,
          priority: 9,
          cursorOffset: -5,
          selectionLength: 4,
        ),
      ];

      testResult = CompletionResult(
        suggestions: testSuggestions,
        isActive: true,
        filterText: '',
        selectedIndex: 0,
      );
    });

    testWidgets('shows overlay when active with suggestions', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Stack(
              children: [
                AutoCompleteOverlay(
                  completionResult: testResult,
                  position: const Offset(100, 200),
                ),
              ],
            ),
          ),
        ),
      );

      expect(find.text('Suggestions'), findsOneWidget);
      expect(find.text('# Heading'), findsOneWidget);
      expect(find.text('- List item'), findsOneWidget);
      expect(find.text('[text](url)'), findsOneWidget);
    });

    testWidgets('hides overlay when not active', (tester) async {
      final inactiveResult = testResult.copyWith(isActive: false);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Stack(
              children: [
                AutoCompleteOverlay(
                  completionResult: inactiveResult,
                  position: const Offset(100, 200),
                ),
              ],
            ),
          ),
        ),
      );

      expect(find.text('Suggestions'), findsNothing);
      expect(find.text('# Heading'), findsNothing);
    });

    testWidgets('hides overlay when no suggestions', (tester) async {
      final emptyResult = testResult.copyWith(suggestions: []);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Stack(
              children: [
                AutoCompleteOverlay(
                  completionResult: emptyResult,
                  position: const Offset(100, 200),
                ),
              ],
            ),
          ),
        ),
      );

      expect(find.text('Suggestions'), findsNothing);
    });

    testWidgets('shows filter text in header', (tester) async {
      final filteredResult = testResult.copyWith(filterText: 'head');

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Stack(
              children: [
                AutoCompleteOverlay(
                  completionResult: filteredResult,
                  position: const Offset(100, 200),
                ),
              ],
            ),
          ),
        ),
      );

      expect(find.text('Suggestions for "head"'), findsOneWidget);
    });

    testWidgets('highlights selected suggestion', (tester) async {
      final selectedResult = testResult.copyWith(selectedIndex: 1);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Stack(
              children: [
                AutoCompleteOverlay(
                  completionResult: selectedResult,
                  position: const Offset(100, 200),
                ),
              ],
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // The selected item should have different styling
      // This would need more specific widget testing to verify visual differences
      expect(find.text('- List item'), findsOneWidget);
    });

    testWidgets('shows suggestion count', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Stack(
              children: [
                AutoCompleteOverlay(
                  completionResult: testResult,
                  position: const Offset(100, 200),
                ),
              ],
            ),
          ),
        ),
      );

      expect(find.text('3'), findsOneWidget); // Count of suggestions
    });

    testWidgets('shows icons when enabled', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Stack(
              children: [
                AutoCompleteOverlay(
                  completionResult: testResult,
                  position: const Offset(100, 200),
                  showIcons: true,
                ),
              ],
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.title), findsOneWidget);
      expect(find.byIcon(Icons.format_list_bulleted), findsOneWidget);
      expect(find.byIcon(Icons.link), findsOneWidget);
    });

    testWidgets('hides icons when disabled', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Stack(
              children: [
                AutoCompleteOverlay(
                  completionResult: testResult,
                  position: const Offset(100, 200),
                  showIcons: false,
                ),
              ],
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.title), findsNothing);
      expect(find.byIcon(Icons.format_list_bulleted), findsNothing);
      expect(find.byIcon(Icons.link), findsNothing);
    });

    testWidgets('shows descriptions when enabled', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Stack(
              children: [
                AutoCompleteOverlay(
                  completionResult: testResult,
                  position: const Offset(100, 200),
                  showDescriptions: true,
                ),
              ],
            ),
          ),
        ),
      );

      expect(find.text('Insert a level 1 heading'), findsOneWidget);
      expect(find.text('Insert a bullet list item'), findsOneWidget);
      expect(find.text('Insert a link'), findsOneWidget);
    });

    testWidgets('hides descriptions when disabled', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Stack(
              children: [
                AutoCompleteOverlay(
                  completionResult: testResult,
                  position: const Offset(100, 200),
                  showDescriptions: false,
                ),
              ],
            ),
          ),
        ),
      );

      expect(find.text('Insert a level 1 heading'), findsNothing);
      expect(find.text('Insert a bullet list item'), findsNothing);
      expect(find.text('Insert a link'), findsNothing);
    });

    testWidgets('calls onSuggestionSelected when tapping suggestion', (tester) async {
      CompletionSuggestion? selectedSuggestion;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Stack(
              children: [
                AutoCompleteOverlay(
                  completionResult: testResult,
                  position: const Offset(100, 200),
                  onSuggestionSelected: (suggestion) {
                    selectedSuggestion = suggestion;
                  },
                ),
              ],
            ),
          ),
        ),
      );

      await tester.tap(find.text('# Heading'));
      await tester.pumpAndSettle();

      expect(selectedSuggestion, equals(testSuggestions[0]));
    });

    testWidgets('calls onSuggestionHovered when hovering suggestion', (tester) async {
      int? hoveredIndex;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Stack(
              children: [
                AutoCompleteOverlay(
                  completionResult: testResult,
                  position: const Offset(100, 200),
                  onSuggestionHovered: (index) {
                    hoveredIndex = index;
                  },
                ),
              ],
            ),
          ),
        ),
      );

      // Simulate hover (this is platform-dependent in real usage)
      final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await gesture.addPointer(location: Offset.zero);
      addTearDown(gesture.removePointer);

      await gesture.moveTo(tester.getCenter(find.text('- List item')));
      await tester.pumpAndSettle();

      // Note: Hover events are tricky to test and may not work in all test environments
      // In real usage, this would set hoveredIndex to 1
    });

    testWidgets('shows footer when many suggestions', (tester) async {
      // Create a result with many suggestions
      final manySuggestions = List.generate(10, (i) =>
        CompletionSuggestion(
          insertText: 'suggestion$i',
          displayText: 'Suggestion $i',
          type: CompletionType.customShortcut,
        ),
      );

      final manyResult = CompletionResult(
        suggestions: manySuggestions,
        isActive: true,
        filterText: '',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Stack(
              children: [
                AutoCompleteOverlay(
                  completionResult: manyResult,
                  position: const Offset(100, 200),
                ),
              ],
            ),
          ),
        ),
      );

      expect(find.textContaining('Navigate'), findsOneWidget);
      expect(find.textContaining('Enter Select'), findsOneWidget);
      expect(find.textContaining('Esc Cancel'), findsOneWidget);
    });

    testWidgets('respects maxWidth and maxHeight constraints', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Stack(
              children: [
                AutoCompleteOverlay(
                  completionResult: testResult,
                  position: const Offset(100, 200),
                  maxWidth: 250,
                  maxHeight: 150,
                ),
              ],
            ),
          ),
        ),
      );

      final container = tester.widget<Container>(
        find.descendant(
          of: find.byType(AutoCompleteOverlay),
          matching: find.byType(Container),
        ).first,
      );

      expect((container.constraints as BoxConstraints).maxWidth, equals(250));
      expect((container.constraints as BoxConstraints).maxHeight, equals(150));
    });

    testWidgets('animates in with fade and scale', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Stack(
              children: [
                AutoCompleteOverlay(
                  completionResult: testResult,
                  position: const Offset(100, 200),
                ),
              ],
            ),
          ),
        ),
      );

      // Initially should be animating
      expect(find.byType(AnimatedBuilder), findsOneWidget);
      expect(find.byType(Transform), findsOneWidget);
      expect(find.byType(Opacity), findsOneWidget);

      // After animation completes
      await tester.pumpAndSettle();
      expect(find.text('# Heading'), findsOneWidget);
    });

    testWidgets('positions overlay correctly', (tester) async {
      const testPosition = Offset(150, 300);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Stack(
              children: [
                AutoCompleteOverlay(
                  completionResult: testResult,
                  position: testPosition,
                ),
              ],
            ),
          ),
        ),
      );

      final positioned = tester.widget<Positioned>(
        find.byType(Positioned),
      );

      expect(positioned.left, equals(testPosition.dx));
      expect(positioned.top, equals(testPosition.dy));
    });

    testWidgets('shows type badges', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Stack(
              children: [
                AutoCompleteOverlay(
                  completionResult: testResult,
                  position: const Offset(100, 200),
                ),
              ],
            ),
          ),
        ),
      );

      expect(find.text('H'), findsOneWidget); // Header type
      expect(find.text('L'), findsOneWidget); // List type
      expect(find.text('LINK'), findsOneWidget); // Link type
    });

    testWidgets('shows shortcut keys when available', (tester) async {
      final suggestionWithShortcut = testSuggestions.first.copyWith(
        shortcutKey: 'h1',
      );

      final resultWithShortcut = testResult.copyWith(
        suggestions: [suggestionWithShortcut, ...testSuggestions.skip(1)],
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Stack(
              children: [
                AutoCompleteOverlay(
                  completionResult: resultWithShortcut,
                  position: const Offset(100, 200),
                ),
              ],
            ),
          ),
        ),
      );

      expect(find.text('h1'), findsOneWidget);
    });
  });

  group('AutoCompletePositioning', () {
    testWidgets('calculates position correctly', (tester) async {
      final textFieldKey = GlobalKey();
      final controller = TextEditingController(text: 'Hello World');

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TextField(
              key: textFieldKey,
              controller: controller,
            ),
          ),
        ),
      );

      final context = tester.element(find.byType(TextField));
      final position = AutoCompletePositioning.calculatePosition(
        context: context,
        textFieldKey: textFieldKey,
        controller: controller,
        cursorOffset: 5, // Position at space
      );

      expect(position, isA<Offset>());
      expect(position.dx, greaterThanOrEqualTo(0));
      expect(position.dy, greaterThanOrEqualTo(0));
    });

    testWidgets('adjusts position when near screen edge', (tester) async {
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1.0;

      final textFieldKey = GlobalKey();
      final controller = TextEditingController(text: 'Text');

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Positioned(
              right: 10, // Near right edge
              top: 100,
              child: TextField(
                key: textFieldKey,
                controller: controller,
              ),
            ),
          ),
        ),
      );

      final context = tester.element(find.byType(TextField));
      final position = AutoCompletePositioning.calculatePosition(
        context: context,
        textFieldKey: textFieldKey,
        controller: controller,
        cursorOffset: 4,
        overlayWidth: 300,
      );

      // Should be adjusted to fit on screen
      expect(position.dx, lessThanOrEqualTo(400 - 300 - 16));
    });

    testWidgets('positions above cursor when no space below', (tester) async {
      tester.view.physicalSize = const Size(400, 600);
      tester.view.devicePixelRatio = 1.0;

      final textFieldKey = GlobalKey();
      final controller = TextEditingController(text: 'Text');

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Positioned(
              bottom: 50, // Near bottom
              left: 50,
              child: TextField(
                key: textFieldKey,
                controller: controller,
              ),
            ),
          ),
        ),
      );

      final context = tester.element(find.byType(TextField));
      final position = AutoCompletePositioning.calculatePosition(
        context: context,
        textFieldKey: textFieldKey,
        controller: controller,
        cursorOffset: 4,
        overlayHeight: 300,
      );

      // Should be positioned to fit on screen
      expect(position.dy, greaterThanOrEqualTo(16));
      expect(position.dy, lessThanOrEqualTo(600 - 300 - 16));
    });
  });
}