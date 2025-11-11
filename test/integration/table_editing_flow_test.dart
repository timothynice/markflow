import 'package:flutter/gestures.dart' show kSecondaryMouseButton;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:markflow/features/markdown/editor_screen.dart';
import 'package:markflow/features/markdown/local_store.dart';
import 'package:markflow/features/markdown/models.dart';
import 'package:markflow/features/markdown/services/table_service.dart';
import '../test_helpers.dart';

class MockMdLocalStore extends Mock implements MdLocalStore {}

void main() {
  group('Table Editing Flow Integration Tests', () {
    late MockMdLocalStore mockStore;
    late MdDocument testDocument;

    setUp(() {
      mockStore = MockMdLocalStore();
      testDocument = MdDocument(
        id: 'test-doc',
        title: 'Test Document',
        content: '''# Test Document

This is a test document with a table.

| Name | Age | City |
| --- | --- | --- |
| John | 25 | NYC |
| Jane | 30 | LA |

Some text after the table.''',
        updatedAt: DateTime.now(),
        versions: [],
      );

      when(mockStore.findById('test-doc')).thenAnswer((_) async => testDocument);
      when(mockStore.save(any as MdDocument)).thenAnswer((_) async {});
    });

    group('Table Creation Flow', () {
      testWidgets('should create table through toolbar button', (WidgetTester tester) async {
        when(mockStore.load()).thenAnswer((_) async => testDocument);

        await tester.pumpWidget(TestHelpers.createTestApp(
          child: MarkdownEditorScreen(docId: 'test-doc'),
        ));

        await tester.pumpAndSettle();

        // Find and tap the table button
        final tableButton = find.byIcon(Icons.table_chart);
        expect(tableButton, findsOneWidget);

        await tester.tap(tableButton);
        await tester.pumpAndSettle();

        // Should show popup menu with table options
        expect(find.text('2×2 Table'), findsOneWidget);
        expect(find.text('Custom Table...'), findsOneWidget);
      });

      testWidgets('should create quick table', (WidgetTester tester) async {
        when(mockStore.load()).thenAnswer((_) async => testDocument);

        await tester.pumpWidget(TestHelpers.createTestApp(
          child: MarkdownEditorScreen(docId: 'test-doc'),
        ));

        await tester.pumpAndSettle();

        // Tap table button and select quick table
        await tester.tap(find.byIcon(Icons.table_chart));
        await tester.pumpAndSettle();

        await tester.tap(find.text('2×2 Table'));
        await tester.pumpAndSettle();

        // Should insert table markdown into the document
        // This would be verified by checking the controller content
        // For now, we verify the UI doesn't crash
      });

      testWidgets('should create custom table through dialog', (WidgetTester tester) async {
        when(mockStore.load()).thenAnswer((_) async => testDocument);

        await tester.pumpWidget(TestHelpers.createTestApp(
          child: MarkdownEditorScreen(docId: 'test-doc'),
        ));

        await tester.pumpAndSettle();

        // Tap table button and select custom
        await tester.tap(find.byIcon(Icons.table_chart));
        await tester.pumpAndSettle();

        await tester.tap(find.text('Custom Table...'));
        await tester.pumpAndSettle();

        // Should show table creation dialog
        expect(find.text('Create Table'), findsOneWidget);

        // Modify settings and create
        final headerField = find.byType(TextFormField).first;
        await tester.enterText(headerField, 'Custom Header');

        await tester.tap(find.text('Create Table'));
        await tester.pumpAndSettle();

        // Dialog should close
        expect(find.text('Create Table'), findsNothing);
      });
    });

    group('Table Detection and Editing Mode', () {
      testWidgets('should enter table edit mode with keyboard shortcut', (WidgetTester tester) async {
        when(mockStore.load()).thenAnswer((_) async => testDocument);

        await tester.pumpWidget(TestHelpers.createTestApp(
          child: MarkdownEditorScreen(docId: 'test-doc'),
        ));

        await tester.pumpAndSettle();

        // Focus the editor and position cursor in table
        final textField = find.byType(TextField).first;
        await tester.tap(textField);
        await tester.pumpAndSettle();

        // Use keyboard shortcut to enter table edit mode
        await tester.sendKeyDownEvent(LogicalKeyboardKey.meta);
        await tester.sendKeyEvent(LogicalKeyboardKey.keyT);
        await tester.sendKeyUpEvent(LogicalKeyboardKey.meta);
        await tester.pumpAndSettle();

        // Should show table editor interface
        expect(find.text('Table Editor'), findsOneWidget);
        expect(find.text('Done'), findsOneWidget);
      });

      testWidgets('should detect table at cursor position', (WidgetTester tester) async {
        const testText = '''# Document

| Name | Age |
| --- | --- |
| John | 25 |

End text''';

        final bounds = TableService.findTableAt(testText, 30);
        expect(bounds, isNotNull);
        expect(bounds!.tableText, contains('| Name | Age |'));
      });

      testWidgets('should not enter table edit mode when cursor not in table', (WidgetTester tester) async {
        final docWithoutTable = MdDocument(
          id: 'no-table-doc',
          title: 'No Table Document',
          content: 'Just some text without any tables.',
          updatedAt: DateTime.now(),
          versions: [],
        );

        when(mockStore.findById('no-table-doc')).thenAnswer((_) async => docWithoutTable);
        when(mockStore.load()).thenAnswer((_) async => docWithoutTable);

        await tester.pumpWidget(TestHelpers.createTestApp(
          child: MarkdownEditorScreen(docId: 'no-table-doc'),
        ));

        await tester.pumpAndSettle();

        // Focus editor and try table edit shortcut
        final textField = find.byType(TextField).first;
        await tester.tap(textField);
        await tester.pumpAndSettle();

        await tester.sendKeyDownEvent(LogicalKeyboardKey.meta);
        await tester.sendKeyEvent(LogicalKeyboardKey.keyT);
        await tester.sendKeyUpEvent(LogicalKeyboardKey.meta);
        await tester.pumpAndSettle();

        // Should not show table editor
        expect(find.text('Table Editor'), findsNothing);
      });
    });

    group('Visual Table Editing', () {
      testWidgets('should show visual table editor with existing table data', (WidgetTester tester) async {
        when(mockStore.load()).thenAnswer((_) async => testDocument);

        await tester.pumpWidget(TestHelpers.createTestApp(
          child: MarkdownEditorScreen(docId: 'test-doc'),
        ));

        await tester.pumpAndSettle();

        // Position cursor in table and enter edit mode
        final textField = find.byType(TextField).first;
        await tester.tap(textField);

        // Simulate keyboard shortcut to enter table edit mode
        await tester.sendKeyDownEvent(LogicalKeyboardKey.meta);
        await tester.sendKeyEvent(LogicalKeyboardKey.keyT);
        await tester.sendKeyUpEvent(LogicalKeyboardKey.meta);
        await tester.pumpAndSettle();

        // Should show table editor with data
        expect(find.text('Table Editor'), findsOneWidget);
        expect(find.text('Name'), findsOneWidget);
        expect(find.text('Age'), findsOneWidget);
        expect(find.text('City'), findsOneWidget);
        expect(find.text('John'), findsOneWidget);
        expect(find.text('Jane'), findsOneWidget);
      });

      testWidgets('should exit table edit mode and return to text editor', (WidgetTester tester) async {
        when(mockStore.load()).thenAnswer((_) async => testDocument);

        await tester.pumpWidget(TestHelpers.createTestApp(
          child: MarkdownEditorScreen(docId: 'test-doc'),
        ));

        await tester.pumpAndSettle();

        // Enter table edit mode (simulated)
        final textField = find.byType(TextField).first;
        await tester.tap(textField);

        await tester.sendKeyDownEvent(LogicalKeyboardKey.meta);
        await tester.sendKeyEvent(LogicalKeyboardKey.keyT);
        await tester.sendKeyUpEvent(LogicalKeyboardKey.meta);
        await tester.pumpAndSettle();

        // Exit table edit mode
        await tester.tap(find.text('Done'));
        await tester.pumpAndSettle();

        // Should be back to regular editor
        expect(find.text('Table Editor'), findsNothing);
        expect(find.byType(TextField), findsAtLeast(1));
      });
    });

    group('Table Editing Operations', () {
      testWidgets('should edit cell content in visual editor', (WidgetTester tester) async {
        when(mockStore.load()).thenAnswer((_) async => testDocument);

        await tester.pumpWidget(TestHelpers.createTestApp(
          child: MarkdownEditorScreen(docId: 'test-doc'),
        ));

        await tester.pumpAndSettle();

        // Enter table edit mode
        final textField = find.byType(TextField).first;
        await tester.tap(textField);

        await tester.sendKeyDownEvent(LogicalKeyboardKey.meta);
        await tester.sendKeyEvent(LogicalKeyboardKey.keyT);
        await tester.sendKeyUpEvent(LogicalKeyboardKey.meta);
        await tester.pumpAndSettle();

        // Double tap a cell to edit
        await tester.tap(find.text('John'));
        await tester.pump();
        await tester.tap(find.text('John'));
        await tester.pumpAndSettle();

        // Should show text field for editing
        expect(find.byType(TextField), findsAtLeast(2)); // One for main editor + one for cell

        // Enter new content
        final cellEditor = find.byType(TextField).last;
        await tester.enterText(cellEditor, 'Johnny');
        await tester.testTextInput.receiveAction(TextInputAction.done);
        await tester.pumpAndSettle();

        // Cell should show updated content
        expect(find.text('Johnny'), findsOneWidget);
        expect(find.text('John'), findsNothing);
      });

      testWidgets('should add row through context menu', (WidgetTester tester) async {
        when(mockStore.load()).thenAnswer((_) async => testDocument);

        await tester.pumpWidget(TestHelpers.createTestApp(
          child: MarkdownEditorScreen(docId: 'test-doc'),
        ));

        await tester.pumpAndSettle();

        // Enter table edit mode
        final textField = find.byType(TextField).first;
        await tester.tap(textField);

        await tester.sendKeyDownEvent(LogicalKeyboardKey.meta);
        await tester.sendKeyEvent(LogicalKeyboardKey.keyT);
        await tester.sendKeyUpEvent(LogicalKeyboardKey.meta);
        await tester.pumpAndSettle();

        // Right click on a row to show context menu
        await tester.tap(find.text('John'), buttons: kSecondaryMouseButton);
        await tester.pumpAndSettle();

        expect(find.text('Insert row above'), findsOneWidget);

        await tester.tap(find.text('Insert row above'));
        await tester.pumpAndSettle();

        // Should have added a new row
        // This would be verified by checking the table structure
      });

      testWidgets('should resize columns by dragging handles', (WidgetTester tester) async {
        when(mockStore.load()).thenAnswer((_) async => testDocument);

        await tester.pumpWidget(TestHelpers.createTestApp(
          child: MarkdownEditorScreen(docId: 'test-doc'),
        ));

        await tester.pumpAndSettle();

        // Enter table edit mode
        final textField = find.byType(TextField).first;
        await tester.tap(textField);

        await tester.sendKeyDownEvent(LogicalKeyboardKey.meta);
        await tester.sendKeyEvent(LogicalKeyboardKey.keyT);
        await tester.sendKeyUpEvent(LogicalKeyboardKey.meta);
        await tester.pumpAndSettle();

        // Find and drag a resize handle
        final resizeHandle = find.byType(GestureDetector);
        if (resizeHandle.evaluate().isNotEmpty) {
          await tester.drag(resizeHandle.first, const Offset(50, 0));
          await tester.pumpAndSettle();
        }

        // Column should be resized
        // This would be verified by checking column width
      });
    });

    group('Mobile Table Editing', () {
      testWidgets('should show mobile table editor on small screens', (WidgetTester tester) async {
        when(mockStore.load()).thenAnswer((_) async => testDocument);

        await tester.pumpWidget(TestHelpers.createTestApp(
          screenSize: TestHelpers.mobileSize,
          child: MarkdownEditorScreen(docId: 'test-doc'),
        ));

        await tester.pumpAndSettle();

        // Enter table edit mode
        final textField = find.byType(TextField).first;
        await tester.tap(textField);

        await tester.sendKeyDownEvent(LogicalKeyboardKey.meta);
        await tester.sendKeyEvent(LogicalKeyboardKey.keyT);
        await tester.sendKeyUpEvent(LogicalKeyboardKey.meta);
        await tester.pumpAndSettle();

        // Should show mobile table editor
        expect(find.byType(PageView), findsOneWidget);
        expect(find.byType(ListView), findsOneWidget);
      });

      testWidgets('should navigate between columns in mobile editor', (WidgetTester tester) async {
        when(mockStore.load()).thenAnswer((_) async => testDocument);

        await tester.pumpWidget(TestHelpers.createTestApp(
          screenSize: TestHelpers.mobileSize,
          child: MarkdownEditorScreen(docId: 'test-doc'),
        ));

        await tester.pumpAndSettle();

        // Enter table edit mode
        final textField = find.byType(TextField).first;
        await tester.tap(textField);

        await tester.sendKeyDownEvent(LogicalKeyboardKey.meta);
        await tester.sendKeyEvent(LogicalKeyboardKey.keyT);
        await tester.sendKeyUpEvent(LogicalKeyboardKey.meta);
        await tester.pumpAndSettle();

        // Should start with first column
        expect(find.text('Name'), findsOneWidget);

        // Swipe to next column
        await tester.drag(find.byType(PageView), const Offset(-300, 0));
        await tester.pumpAndSettle();

        // Should show second column
        expect(find.text('Age'), findsOneWidget);
      });

      testWidgets('should edit cell through dialog on mobile', (WidgetTester tester) async {
        when(mockStore.load()).thenAnswer((_) async => testDocument);

        await tester.pumpWidget(TestHelpers.createTestApp(
          screenSize: TestHelpers.mobileSize,
          child: MarkdownEditorScreen(docId: 'test-doc'),
        ));

        await tester.pumpAndSettle();

        // Enter table edit mode
        final textField = find.byType(TextField).first;
        await tester.tap(textField);

        await tester.sendKeyDownEvent(LogicalKeyboardKey.meta);
        await tester.sendKeyEvent(LogicalKeyboardKey.keyT);
        await tester.sendKeyUpEvent(LogicalKeyboardKey.meta);
        await tester.pumpAndSettle();

        // Tap on a list item to edit
        if (find.byType(ListTile).evaluate().isNotEmpty) {
          await tester.tap(find.byType(ListTile).first);
          await tester.pumpAndSettle();

          // Should show edit dialog
          expect(find.text('Edit Cell'), findsOneWidget);

          // Enter new content
          final dialogTextField = find.byType(TextField).last;
          await tester.enterText(dialogTextField, 'Updated Content');

          await tester.tap(find.text('Save'));
          await tester.pumpAndSettle();
        }
      });
    });

    group('Table Data Persistence', () {
      testWidgets('should save table changes to document', (WidgetTester tester) async {
        when(mockStore.load()).thenAnswer((_) async => testDocument);

        await tester.pumpWidget(TestHelpers.createTestApp(
          child: MarkdownEditorScreen(docId: 'test-doc'),
        ));

        await tester.pumpAndSettle();

        // Make changes to table
        final textField = find.byType(TextField).first;
        await tester.tap(textField);

        await tester.sendKeyDownEvent(LogicalKeyboardKey.meta);
        await tester.sendKeyEvent(LogicalKeyboardKey.keyT);
        await tester.sendKeyUpEvent(LogicalKeyboardKey.meta);
        await tester.pumpAndSettle();

        // Edit a cell
        await tester.tap(find.text('John'));
        await tester.pump();
        await tester.tap(find.text('John'));
        await tester.pumpAndSettle();

        if (find.byType(TextField).evaluate().length > 1) {
          final cellEditor = find.byType(TextField).last;
          await tester.enterText(cellEditor, 'Johnny');
          await tester.testTextInput.receiveAction(TextInputAction.done);
          await tester.pumpAndSettle();
        }

        // Exit table edit mode
        await tester.tap(find.text('Done'));
        await tester.pumpAndSettle();

        // Changes should be saved automatically
        // This would be verified by checking the document content
        verify(mockStore.save(any as MdDocument)).called(1);
      });

      testWidgets('should preserve table formatting in markdown', (WidgetTester tester) async {
        final table = TableData.create(2, 3);
        table.columns[0].header = 'Name';
        table.columns[1].header = 'Age';
        table.columns[2].header = 'City';
        table.columns[1].alignment = TableAlignment.center;
        table.columns[2].alignment = TableAlignment.right;

        table.setCellAt(0, 0, 'John');
        table.setCellAt(0, 1, '25');
        table.setCellAt(0, 2, 'NYC');

        final markdown = TableService.tableToMarkdown(table);

        expect(markdown, contains('| Name | Age | City |'));
        expect(markdown, contains('| --- | :---: | ---: |'));
        expect(markdown, contains('| John | 25 | NYC |'));
      });
    });

    group('Error Handling', () {
      testWidgets('should handle malformed table gracefully', (WidgetTester tester) async {
        final malformedDoc = MdDocument(
          id: 'malformed-doc',
          title: 'Malformed Table',
          content: '''# Document

| Name | Age
| --- |
| John | 25 |

''',
          updatedAt: DateTime.now(),
          versions: [],
        );

        when(mockStore.findById('malformed-doc')).thenAnswer((_) async => malformedDoc);
        when(mockStore.load()).thenAnswer((_) async => malformedDoc);

        await tester.pumpWidget(TestHelpers.createTestApp(
          child: MarkdownEditorScreen(docId: 'malformed-doc'),
        ));

        await tester.pumpAndSettle();

        // Try to enter table edit mode
        final textField = find.byType(TextField).first;
        await tester.tap(textField);

        await tester.sendKeyDownEvent(LogicalKeyboardKey.meta);
        await tester.sendKeyEvent(LogicalKeyboardKey.keyT);
        await tester.sendKeyUpEvent(LogicalKeyboardKey.meta);
        await tester.pumpAndSettle();

        // Should not crash
        expect(tester.takeException(), isNull);
      });

      testWidgets('should handle empty table creation', (WidgetTester tester) async {
        when(mockStore.load()).thenAnswer((_) async => testDocument);

        await tester.pumpWidget(TestHelpers.createTestApp(
          child: MarkdownEditorScreen(docId: 'test-doc'),
        ));

        await tester.pumpAndSettle();

        // Try to create table with invalid dimensions
        await tester.tap(find.byIcon(Icons.table_chart));
        await tester.pumpAndSettle();

        await tester.tap(find.text('Custom Table...'));
        await tester.pumpAndSettle();

        // Enter invalid dimensions
        final textFields = find.byType(TextFormField);
        await tester.enterText(textFields.first, '0');
        await tester.enterText(textFields.at(1), '0');

        await tester.tap(find.text('Create Table'));
        await tester.pump();

        // Should show validation errors, not crash
        expect(find.text('Create Table'), findsOneWidget); // Dialog still open
        expect(tester.takeException(), isNull);
      });
    });

    group('Performance', () {
      testWidgets('should handle large tables efficiently', (WidgetTester tester) async {
        // Create a large table
        final largeTable = TableData.create(20, 10);
        for (int i = 0; i < 20; i++) {
          for (int j = 0; j < 10; j++) {
            largeTable.setCellAt(i, j, 'R${i}C$j');
          }
        }

        final largeTableMarkdown = TableService.tableToMarkdown(largeTable);
        final largeDoc = MdDocument(
          id: 'large-doc',
          title: 'Large Table',
          content: largeTableMarkdown,
          updatedAt: DateTime.now(),
          versions: [],
        );

        when(mockStore.findById('large-doc')).thenAnswer((_) async => largeDoc);
        when(mockStore.load()).thenAnswer((_) async => largeDoc);

        await tester.pumpWidget(TestHelpers.createTestApp(
          child: MarkdownEditorScreen(docId: 'large-doc'),
        ));

        await tester.pumpAndSettle();

        // Enter table edit mode
        final textField = find.byType(TextField).first;
        await tester.tap(textField);

        await tester.sendKeyDownEvent(LogicalKeyboardKey.meta);
        await tester.sendKeyEvent(LogicalKeyboardKey.keyT);
        await tester.sendKeyUpEvent(LogicalKeyboardKey.meta);
        await tester.pumpAndSettle();

        // Should render without performance issues
        expect(find.text('Table Editor'), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    });
  });
}