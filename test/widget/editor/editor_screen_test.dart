import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:markflow/features/markdown/editor_screen.dart';
import 'package:markflow/features/markdown/local_store.dart';
import 'package:markflow/features/markdown/models.dart';
import 'package:markflow/features/markdown/widgets/formatting_toolbar.dart';
import 'package:mockito/mockito.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

import '../../test_helpers.dart';

class MockMdLocalStore extends Mock implements MdLocalStore {}

void main() {
  group('Editor Screen Widget Tests', () {
    late MockMdLocalStore mockStore;
    late MdDocument testDocument;

    setUp(() {
      mockStore = MockMdLocalStore();
      testDocument = MdDocument(
        id: 'test-doc',
        title: 'Test Document',
        content: TestFixtures.sampleMarkdown,
        updatedAt: DateTime.now(),
        versions: [
          MdVersion(
            id: 'v1',
            createdAt: DateTime.now(),
            content: TestFixtures.sampleMarkdown,
          ),
        ],
      );

      // Setup mock behavior
      when(mockStore.findById('test-doc')).thenAnswer((_) async => testDocument);
      when(mockStore.load()).thenAnswer((_) async => testDocument);
      when(mockStore.save(any)).thenAnswer((_) async {});
    });

    testWidgets('should render markdown editor screen with basic layout', (WidgetTester tester) async {
      await tester.pumpWidget(
        TestHelpers.createTestApp(
          child: const MarkdownEditorScreen(docId: 'test-doc'),
          mockStore: mockStore,
        ),
      );

      // Wait for document to load
      await TestHelpers.pumpAndSettleWithDelay(tester);

      // Verify basic structure
      expect(find.byType(DefaultTabController), findsOneWidget);
      expect(find.byType(FormattingToolbar), findsOneWidget);
      expect(find.byType(TabBarView), findsOneWidget);
      expect(find.text('Markdown'), findsOneWidget);
      expect(find.text('Styled'), findsOneWidget);
    });

    testWidgets('should display editor tab with text field on desktop', (WidgetTester tester) async {
      await tester.pumpWidget(
        TestHelpers.createTestApp(
          child: const MarkdownEditorScreen(docId: 'test-doc'),
          mockStore: mockStore,
          screenSize: TestHelpers.desktopSize,
        ),
      );

      await TestHelpers.pumpAndSettleWithDelay(tester);

      // Should show text field in first tab (editor mode)
      expect(find.byType(TextField), findsAtLeastNWidgets(1));

      // Verify content is loaded
      final textField = find.byType(TextField).first;
      expect(tester.widget<TextField>(textField).controller?.text, contains('Sample Document'));
    });

    testWidgets('should display styled preview in second tab', (WidgetTester tester) async {
      await tester.pumpWidget(
        TestHelpers.createTestApp(
          child: const MarkdownEditorScreen(docId: 'test-doc'),
          mockStore: mockStore,
        ),
      );

      await TestHelpers.pumpAndSettleWithDelay(tester);

      // Switch to styled tab
      await TestHelpers.tapAndSettle(tester, find.text('Styled'));

      // Verify markdown rendering
      expect(find.byType(Markdown), findsOneWidget);
    });

    testWidgets('should show navigation bar when showTopNav is true', (WidgetTester tester) async {
      await tester.pumpWidget(
        TestHelpers.createTestApp(
          child: const MarkdownEditorScreen(docId: 'test-doc', showTopNav: true),
          mockStore: mockStore,
        ),
      );

      await TestHelpers.pumpAndSettleWithDelay(tester);

      expect(find.byType(ResponsiveNavBar), findsOneWidget);
      expect(find.text('Documents'), findsOneWidget);
    });

    testWidgets('should hide navigation bar when showTopNav is false', (WidgetTester tester) async {
      await tester.pumpWidget(
        TestHelpers.createTestApp(
          child: const MarkdownEditorScreen(docId: 'test-doc', showTopNav: false),
          mockStore: mockStore,
        ),
      );

      await TestHelpers.pumpAndSettleWithDelay(tester);

      expect(find.byType(ResponsiveNavBar), findsNothing);
    });

    group('Editor Functionality', () {
      testWidgets('should handle text input and trigger auto-save', (WidgetTester tester) async {
        await tester.pumpWidget(
          TestHelpers.createTestApp(
            child: const MarkdownEditorScreen(docId: 'test-doc'),
            mockStore: mockStore,
          ),
        );

        await TestHelpers.pumpAndSettleWithDelay(tester);

        // Find the text field and enter text
        final textField = find.byType(TextField).first;
        await TestHelpers.enterText(tester, textField, '# New Content\n\nThis is new content.');

        // Wait for debounced auto-save
        await tester.pump(const Duration(milliseconds: 400));

        // Verify save was called
        verify(mockStore.save(any)).called(greaterThan(0));
      });

      testWidgets('should update preview when content changes', (WidgetTester tester) async {
        await tester.pumpWidget(
          TestHelpers.createTestApp(
            child: const MarkdownEditorScreen(docId: 'test-doc'),
            mockStore: mockStore,
          ),
        );

        await TestHelpers.pumpAndSettleWithDelay(tester);

        // Switch to styled tab first
        await TestHelpers.tapAndSettle(tester, find.text('Styled'));

        // Now switch back to editor and change content
        await TestHelpers.tapAndSettle(tester, find.text('Markdown'));

        const newContent = '# Updated Title\n\nThis is updated content.';
        final textField = find.byType(TextField).first;
        await TestHelpers.enterText(tester, textField, newContent);

        // Switch back to styled tab to see preview
        await TestHelpers.tapAndSettle(tester, find.text('Styled'));

        // The markdown widget should reflect the new content through ValueListenableBuilder
        expect(find.byType(Markdown), findsOneWidget);
      });

      testWidgets('should support keyboard shortcuts for formatting', (WidgetTester tester) async {
        await tester.pumpWidget(
          TestHelpers.createTestApp(
            child: const MarkdownEditorScreen(docId: 'test-doc'),
            mockStore: mockStore,
          ),
        );

        await TestHelpers.pumpAndSettleWithDelay(tester);

        final textField = find.byType(TextField).first;
        await tester.tap(textField);

        // Clear existing content and add test text
        await TestHelpers.enterText(tester, textField, 'test text');

        // Select all text
        await tester.sendKeyDownEvent(LogicalKeyboardKey.meta);
        await tester.sendKeyEvent(LogicalKeyboardKey.keyA);
        await tester.sendKeyUpEvent(LogicalKeyboardKey.meta);

        // Apply bold formatting with Cmd+B
        await tester.sendKeyDownEvent(LogicalKeyboardKey.meta);
        await tester.sendKeyEvent(LogicalKeyboardKey.keyB);
        await tester.sendKeyUpEvent(LogicalKeyboardKey.meta);

        await tester.pump();

        // Verify bold formatting was applied
        final textFieldWidget = tester.widget<TextField>(textField);
        expect(textFieldWidget.controller?.text, contains('**'));
      });
    });

    group('Toolbar Integration', () {
      testWidgets('should display formatting toolbar with all buttons', (WidgetTester tester) async {
        await tester.pumpWidget(
          TestHelpers.createTestApp(
            child: const MarkdownEditorScreen(docId: 'test-doc'),
            mockStore: mockStore,
          ),
        );

        await TestHelpers.pumpAndSettleWithDelay(tester);

        // Verify toolbar is present
        expect(find.byType(FormattingToolbar), findsOneWidget);

        // Look for toolbar buttons (they should be icon buttons)
        expect(find.byType(IconButton), findsAtLeastNWidgets(5));
      });

      testWidgets('should apply bold formatting when toolbar button pressed', (WidgetTester tester) async {
        await tester.pumpWidget(
          TestHelpers.createTestApp(
            child: const MarkdownEditorScreen(docId: 'test-doc'),
            mockStore: mockStore,
          ),
        );

        await TestHelpers.pumpAndSettleWithDelay(tester);

        // Clear content and add test text
        final textField = find.byType(TextField).first;
        await TestHelpers.enterText(tester, textField, 'test');

        // Select the text
        final textFieldWidget = tester.widget<TextField>(textField);
        textFieldWidget.controller?.selection = TextSelection(baseOffset: 0, extentOffset: 4);

        // Find and tap bold button (usually first in toolbar)
        final boldButton = find.byIcon(Icons.format_bold).first;
        await TestHelpers.tapAndSettle(tester, boldButton);

        // Verify bold formatting was applied
        expect(textFieldWidget.controller?.text, contains('**test**'));
      });
    });

    group('Document Management', () {
      testWidgets('should load document by ID on initialization', (WidgetTester tester) async {
        await tester.pumpWidget(
          TestHelpers.createTestApp(
            child: const MarkdownEditorScreen(docId: 'test-doc'),
            mockStore: mockStore,
          ),
        );

        await TestHelpers.pumpAndSettleWithDelay(tester);

        // Verify store was called to find document by ID
        verify(mockStore.findById('test-doc')).called(1);

        // Verify content is displayed
        final textField = find.byType(TextField).first;
        expect(tester.widget<TextField>(textField).controller?.text, contains('Sample Document'));
      });

      testWidgets('should handle missing document gracefully', (WidgetTester tester) async {
        // Setup mock to return null for missing document
        when(mockStore.findById('missing-doc')).thenAnswer((_) async => null);
        when(mockStore.load()).thenAnswer((_) async => testDocument);

        await tester.pumpWidget(
          TestHelpers.createTestApp(
            child: const MarkdownEditorScreen(docId: 'missing-doc'),
            mockStore: mockStore,
          ),
        );

        await TestHelpers.pumpAndSettleWithDelay(tester);

        // Should fallback to load() method
        verify(mockStore.load()).called(1);
      });

      testWidgets('should save document changes periodically', (WidgetTester tester) async {
        await tester.pumpWidget(
          TestHelpers.createTestApp(
            child: const MarkdownEditorScreen(docId: 'test-doc'),
            mockStore: mockStore,
          ),
        );

        await TestHelpers.pumpAndSettleWithDelay(tester);

        // Make changes to content
        final textField = find.byType(TextField).first;
        await TestHelpers.enterText(tester, textField, 'Modified content');

        // Wait for debounced auto-save (300ms + buffer)
        await tester.pump(const Duration(milliseconds: 400));

        // Verify save was called
        verify(mockStore.save(any)).called(greaterThan(0));
      });
    });

    group('Responsive Behavior', () {
      testWidgets('should adapt to mobile screen size', (WidgetTester tester) async {
        await tester.pumpWidget(
          TestHelpers.createTestApp(
            child: const MarkdownEditorScreen(docId: 'test-doc'),
            mockStore: mockStore,
            screenSize: TestHelpers.mobileSize,
          ),
        );

        await TestHelpers.pumpAndSettleWithDelay(tester);

        // On mobile, layout should be compact
        expect(find.byType(TabBarView), findsOneWidget);
        expect(find.byType(TextField), findsAtLeastNWidgets(1));
      });

      testWidgets('should adapt to desktop screen size', (WidgetTester tester) async {
        await tester.pumpWidget(
          TestHelpers.createTestApp(
            child: const MarkdownEditorScreen(docId: 'test-doc'),
            mockStore: mockStore,
            screenSize: TestHelpers.desktopSize,
          ),
        );

        await TestHelpers.pumpAndSettleWithDelay(tester);

        // Desktop should have full layout
        expect(find.byType(TabBarView), findsOneWidget);
        expect(find.byType(FormattingToolbar), findsOneWidget);
      });
    });

    group('Accessibility', () {
      testWidgets('should provide semantic labels for main components', (WidgetTester tester) async {
        await tester.pumpWidget(
          TestHelpers.createTestApp(
            child: const MarkdownEditorScreen(docId: 'test-doc'),
            mockStore: mockStore,
          ),
        );

        await TestHelpers.pumpAndSettleWithDelay(tester);

        // Verify semantic structure is present
        TestHelpers.verifyAccessibilitySemantics(
          tester,
          expectsTextField: true,
          expectsButton: true,
        );
      });

      testWidgets('should support keyboard navigation', (WidgetTester tester) async {
        await tester.pumpWidget(
          TestHelpers.createTestApp(
            child: const MarkdownEditorScreen(docId: 'test-doc'),
            mockStore: mockStore,
          ),
        );

        await TestHelpers.pumpAndSettleWithDelay(tester);

        // Test Tab navigation
        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await tester.pump();

        // Focus should move to next focusable element
        expect(tester.binding.focusManager.primaryFocus, isNotNull);
      });
    });

    group('Tab Navigation', () {
      testWidgets('should switch between markdown and styled views', (WidgetTester tester) async {
        await tester.pumpWidget(
          TestHelpers.createTestApp(
            child: const MarkdownEditorScreen(docId: 'test-doc'),
            mockStore: mockStore,
          ),
        );

        await TestHelpers.pumpAndSettleWithDelay(tester);

        // Initially should show markdown editor
        expect(find.byType(TextField), findsAtLeastNWidgets(1));

        // Switch to styled view
        await TestHelpers.tapAndSettle(tester, find.text('Styled'));
        expect(find.byType(Markdown), findsOneWidget);

        // Switch back to markdown view
        await TestHelpers.tapAndSettle(tester, find.text('Markdown'));
        expect(find.byType(TextField), findsAtLeastNWidgets(1));
      });

      testWidgets('should trigger save when switching to styled view', (WidgetTester tester) async {
        await tester.pumpWidget(
          TestHelpers.createTestApp(
            child: const MarkdownEditorScreen(docId: 'test-doc'),
            mockStore: mockStore,
          ),
        );

        await TestHelpers.pumpAndSettleWithDelay(tester);

        // Make a change
        final textField = find.byType(TextField).first;
        await TestHelpers.enterText(tester, textField, 'Changed content');

        // Switch to styled view (should trigger save)
        await TestHelpers.tapAndSettle(tester, find.text('Styled'));

        // Verify save was called
        verify(mockStore.save(any)).called(greaterThan(0));
      });
    });

    group('Styled Edit Mode', () {
      testWidgets('should enter styled edit mode on long press', (WidgetTester tester) async {
        await tester.pumpWidget(
          TestHelpers.createTestApp(
            child: const MarkdownEditorScreen(docId: 'test-doc'),
            mockStore: mockStore,
          ),
        );

        await TestHelpers.pumpAndSettleWithDelay(tester);

        // Switch to styled view
        await TestHelpers.tapAndSettle(tester, find.text('Styled'));

        // Long press on the markdown area to enter edit mode
        await tester.longPress(find.byType(Markdown));
        await tester.pumpAndSettle();

        // Should show "Done" button indicating edit mode
        expect(find.text('Done'), findsOneWidget);
        expect(find.byIcon(Icons.check), findsOneWidget);
      });

      testWidgets('should exit styled edit mode when Done button pressed', (WidgetTester tester) async {
        await tester.pumpWidget(
          TestHelpers.createTestApp(
            child: const MarkdownEditorScreen(docId: 'test-doc'),
            mockStore: mockStore,
          ),
        );

        await TestHelpers.pumpAndSettleWithDelay(tester);

        // Switch to styled view and enter edit mode
        await TestHelpers.tapAndSettle(tester, find.text('Styled'));
        await tester.longPress(find.byType(Markdown));
        await tester.pumpAndSettle();

        // Should show Done button
        expect(find.text('Done'), findsOneWidget);

        // Tap Done button to exit edit mode
        await TestHelpers.tapAndSettle(tester, find.text('Done'));

        // Done button should disappear
        expect(find.text('Done'), findsNothing);
      });
    });
  });
}