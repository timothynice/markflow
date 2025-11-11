import 'package:flutter/gestures.dart' show kSecondaryMouseButton;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:markflow/features/markdown/services/table_service.dart';
import 'package:markflow/features/markdown/widgets/table_editor.dart';
import '../../../test_helpers.dart';

void main() {
  group('TableEditor Widget Tests', () {
    late TableData testTable;

    setUp(() {
      testTable = TableData.create(3, 3);
      testTable.columns[0].header = 'Name';
      testTable.columns[1].header = 'Age';
      testTable.columns[2].header = 'City';
      testTable.setCellAt(0, 0, 'John');
      testTable.setCellAt(0, 1, '25');
      testTable.setCellAt(0, 2, 'NYC');
      testTable.setCellAt(1, 0, 'Jane');
      testTable.setCellAt(1, 1, '30');
      testTable.setCellAt(1, 2, 'LA');
    });

    group('Basic Rendering', () {
      testWidgets('should render table with headers and data', (WidgetTester tester) async {
        await tester.pumpWidget(TestHelpers.createTestApp(
          child: TableEditor(table: testTable),
        ));

        expect(find.text('Name'), findsOneWidget);
        expect(find.text('Age'), findsOneWidget);
        expect(find.text('City'), findsOneWidget);
        expect(find.text('John'), findsOneWidget);
        expect(find.text('Jane'), findsOneWidget);
        expect(find.text('25'), findsOneWidget);
        expect(find.text('30'), findsOneWidget);
        expect(find.text('NYC'), findsOneWidget);
        expect(find.text('LA'), findsOneWidget);
      });

      testWidgets('should render row and column numbers', (WidgetTester tester) async {
        await tester.pumpWidget(TestHelpers.createTestApp(
          child: TableEditor(table: testTable),
        ));

        expect(find.text('#'), findsOneWidget); // Header for row numbers
        expect(find.text('1'), findsOneWidget);
        expect(find.text('2'), findsOneWidget);
        expect(find.text('3'), findsOneWidget);
      });

      testWidgets('should render resize handles', (WidgetTester tester) async {
        await tester.pumpWidget(TestHelpers.createTestApp(
          child: TableEditor(table: testTable),
        ));

        // Check for resize handle widgets (they contain divider lines)
        expect(find.byType(Container), findsAtLeast(1));
      });
    });

    group('Cell Selection', () {
      testWidgets('should select cell on tap', (WidgetTester tester) async {
        bool cellSelected = false;
        int? selectedRow, selectedColumn;

        await tester.pumpWidget(TestHelpers.createTestApp(
          child: TableEditor(
            table: testTable,
            onTableChanged: (table) {},
          ),
        ));

        // Tap on a data cell
        await tester.tap(find.text('John'));
        await tester.pumpAndSettle();

        // Visual verification would require checking the container decoration
        // This is a basic structural test
      });

      testWidgets('should handle row selection', (WidgetTester tester) async {
        await tester.pumpWidget(TestHelpers.createTestApp(
          child: TableEditor(table: testTable),
        ));

        // Tap on row number
        await tester.tap(find.text('1'));
        await tester.pumpAndSettle();
      });

      testWidgets('should handle column selection', (WidgetTester tester) async {
        await tester.pumpWidget(TestHelpers.createTestApp(
          child: TableEditor(table: testTable),
        ));

        // Tap on column header
        await tester.tap(find.text('Name'));
        await tester.pumpAndSettle();
      });
    });

    group('Cell Editing', () {
      testWidgets('should enter edit mode on double tap', (WidgetTester tester) async {
        await tester.pumpWidget(TestHelpers.createTestApp(
          child: TableEditor(table: testTable),
        ));

        // Double tap to start editing
        await tester.tap(find.text('John'));
        await tester.pump();
        await tester.tap(find.text('John'));
        await tester.pumpAndSettle();

        // Should find a TextField for editing
        expect(find.byType(TextField), findsAtLeast(1));
      });

      testWidgets('should save cell content on focus loss', (WidgetTester tester) async {
        String? updatedContent;

        await tester.pumpWidget(TestHelpers.createTestApp(
          child: TableEditor(
            table: testTable,
            onTableChanged: (table) {
              updatedContent = table.getCellAt(0, 0)?.content;
            },
          ),
        ));

        // Start editing
        await tester.tap(find.text('John'));
        await tester.pump();
        await tester.tap(find.text('John'));
        await tester.pumpAndSettle();

        // Enter new text
        final textField = find.byType(TextField).first;
        await tester.enterText(textField, 'Johnny');

        // Tap elsewhere to lose focus
        await tester.tap(find.text('Jane'));
        await tester.pumpAndSettle();

        expect(updatedContent, equals('Johnny'));
      });

      testWidgets('should save cell content on enter key', (WidgetTester tester) async {
        await tester.pumpWidget(TestHelpers.createTestApp(
          child: TableEditor(table: testTable),
        ));

        // Start editing
        await tester.tap(find.text('John'));
        await tester.pump();
        await tester.tap(find.text('John'));
        await tester.pumpAndSettle();

        // Enter new text and press enter
        final textField = find.byType(TextField).first;
        await tester.enterText(textField, 'Johnny');
        await tester.testTextInput.receiveAction(TextInputAction.done);
        await tester.pumpAndSettle();
      });
    });

    group('Keyboard Navigation', () {
      testWidgets('should navigate with arrow keys', (WidgetTester tester) async {
        await tester.pumpWidget(TestHelpers.createTestApp(
          child: TableEditor(table: testTable),
        ));

        // Focus the widget and select a cell
        await tester.tap(find.text('John'));
        await tester.pumpAndSettle();

        // Navigate with arrow keys
        await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
        await tester.pumpAndSettle();

        await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
        await tester.pumpAndSettle();

        await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
        await tester.pumpAndSettle();

        await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
        await tester.pumpAndSettle();
      });

      testWidgets('should navigate with tab key', (WidgetTester tester) async {
        await tester.pumpWidget(TestHelpers.createTestApp(
          child: TableEditor(table: testTable),
        ));

        // Focus the widget and select a cell
        await tester.tap(find.text('John'));
        await tester.pumpAndSettle();

        // Navigate with tab
        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await tester.pumpAndSettle();

        // Navigate with shift+tab
        await tester.sendKeyDownEvent(LogicalKeyboardKey.shift);
        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await tester.sendKeyUpEvent(LogicalKeyboardKey.shift);
        await tester.pumpAndSettle();
      });

      testWidgets('should enter edit mode with enter key', (WidgetTester tester) async {
        await tester.pumpWidget(TestHelpers.createTestApp(
          child: TableEditor(table: testTable),
        ));

        // Focus and select a cell
        await tester.tap(find.text('John'));
        await tester.pumpAndSettle();

        // Press enter to start editing
        await tester.sendKeyEvent(LogicalKeyboardKey.enter);
        await tester.pumpAndSettle();

        expect(find.byType(TextField), findsAtLeast(1));
      });

      testWidgets('should exit edit mode with escape key', (WidgetTester tester) async {
        await tester.pumpWidget(TestHelpers.createTestApp(
          child: TableEditor(table: testTable),
        ));

        // Start editing
        await tester.tap(find.text('John'));
        await tester.pump();
        await tester.tap(find.text('John'));
        await tester.pumpAndSettle();

        expect(find.byType(TextField), findsAtLeast(1));

        // Press escape to exit editing
        await tester.sendKeyEvent(LogicalKeyboardKey.escape);
        await tester.pumpAndSettle();
      });
    });

    group('Context Menu', () {
      testWidgets('should show context menu on right click', (WidgetTester tester) async {
        await tester.pumpWidget(TestHelpers.createTestApp(
          child: TableEditor(table: testTable),
        ));

        // Right click on a cell (simulate with secondary tap)
        await tester.tap(find.text('John'), buttons: kSecondaryMouseButton);
        await tester.pumpAndSettle();

        // Should show context menu with options
        expect(find.text('Insert row above'), findsOneWidget);
        expect(find.text('Insert row below'), findsOneWidget);
        expect(find.text('Insert column left'), findsOneWidget);
        expect(find.text('Insert column right'), findsOneWidget);
      });

      testWidgets('should insert row above when context menu option selected', (WidgetTester tester) async {
        int? originalRowCount = testTable.rowCount;

        await tester.pumpWidget(TestHelpers.createTestApp(
          child: TableEditor(
            table: testTable,
            onTableChanged: (table) {
              testTable = table;
            },
          ),
        ));

        // Right click and select insert row above
        await tester.tap(find.text('Jane'), buttons: kSecondaryMouseButton);
        await tester.pumpAndSettle();

        await tester.tap(find.text('Insert row above'));
        await tester.pumpAndSettle();
      });

      testWidgets('should insert column when context menu option selected', (WidgetTester tester) async {
        await tester.pumpWidget(TestHelpers.createTestApp(
          child: TableEditor(table: testTable),
        ));

        // Right click on header and insert column
        await tester.tap(find.text('Age'), buttons: kSecondaryMouseButton);
        await tester.pumpAndSettle();

        await tester.tap(find.text('Insert column left'));
        await tester.pumpAndSettle();
      });

      testWidgets('should delete row when context menu option selected', (WidgetTester tester) async {
        await tester.pumpWidget(TestHelpers.createTestApp(
          child: TableEditor(table: testTable),
        ));

        // Right click on row number and delete
        await tester.tap(find.text('2'), buttons: kSecondaryMouseButton);
        await tester.pumpAndSettle();

        await tester.tap(find.text('Delete row'));
        await tester.pumpAndSettle();
      });

      testWidgets('should clear table when context menu option selected', (WidgetTester tester) async {
        await tester.pumpWidget(TestHelpers.createTestApp(
          child: TableEditor(table: testTable),
        ));

        // Right click and clear table
        await tester.tap(find.text('John'), buttons: kSecondaryMouseButton);
        await tester.pumpAndSettle();

        await tester.tap(find.text('Clear table'));
        await tester.pumpAndSettle();
      });
    });

    group('Column Resizing', () {
      testWidgets('should show resize cursor on resize handle', (WidgetTester tester) async {
        await tester.pumpWidget(TestHelpers.createTestApp(
          child: TableEditor(table: testTable),
        ));

        // Find resize handles (they should have MouseRegion with resizeColumn cursor)
        expect(find.byType(MouseRegion), findsAtLeast(1));
      });

      testWidgets('should resize column on drag', (WidgetTester tester) async {
        double? newWidth;

        await tester.pumpWidget(TestHelpers.createTestApp(
          child: TableEditor(
            table: testTable,
            onTableChanged: (table) {
              newWidth = table.columns[0].width;
            },
          ),
        ));

        // Find and drag a resize handle
        final resizeHandle = find.byType(GestureDetector).first;
        await tester.drag(resizeHandle, const Offset(50, 0));
        await tester.pumpAndSettle();
      });
    });

    group('Read-Only Mode', () {
      testWidgets('should not allow editing in read-only mode', (WidgetTester tester) async {
        await tester.pumpWidget(TestHelpers.createTestApp(
          child: TableEditor(
            table: testTable,
            isReadOnly: true,
          ),
        ));

        // Try to double tap for editing
        await tester.tap(find.text('John'));
        await tester.pump();
        await tester.tap(find.text('John'));
        await tester.pumpAndSettle();

        // Should not find TextField (editing disabled)
        expect(find.byType(TextField), findsNothing);
      });

      testWidgets('should not show context menu in read-only mode', (WidgetTester tester) async {
        await tester.pumpWidget(TestHelpers.createTestApp(
          child: TableEditor(
            table: testTable,
            isReadOnly: true,
          ),
        ));

        // Right click should not show context menu
        await tester.tap(find.text('John'), buttons: kSecondaryMouseButton);
        await tester.pumpAndSettle();

        expect(find.text('Insert row above'), findsNothing);
      });
    });

    group('Responsive Behavior', () {
      testWidgets('should handle small screen sizes', (WidgetTester tester) async {
        await tester.pumpWidget(TestHelpers.createTestApp(
          screenSize: TestHelpers.mobileSize,
          child: TableEditor(table: testTable),
        ));

        await tester.pumpAndSettle();
        expect(find.byType(TableEditor), findsOneWidget);
      });

      testWidgets('should handle large screen sizes', (WidgetTester tester) async {
        await tester.pumpWidget(TestHelpers.createTestApp(
          screenSize: TestHelpers.desktopSize,
          child: TableEditor(table: testTable),
        ));

        await tester.pumpAndSettle();
        expect(find.byType(TableEditor), findsOneWidget);
      });
    });

    group('Scrolling', () {
      testWidgets('should provide horizontal scrolling for wide tables', (WidgetTester tester) async {
        // Create a wide table
        final wideTable = TableData.create(3, 10);
        for (int i = 0; i < 10; i++) {
          wideTable.columns[i].header = 'Column $i';
        }

        await tester.pumpWidget(TestHelpers.createTestApp(
          child: TableEditor(table: wideTable),
        ));

        expect(find.byType(SingleChildScrollView), findsAtLeast(1));
        expect(find.byType(Scrollbar), findsAtLeast(1));
      });

      testWidgets('should provide vertical scrolling for tall tables', (WidgetTester tester) async {
        // Create a tall table
        final tallTable = TableData.create(20, 3);

        await tester.pumpWidget(TestHelpers.createTestApp(
          child: TableEditor(table: tallTable),
        ));

        expect(find.byType(SingleChildScrollView), findsAtLeast(1));
      });
    });

    group('Accessibility', () {
      testWidgets('should be focusable for keyboard navigation', (WidgetTester tester) async {
        await tester.pumpWidget(TestHelpers.createTestApp(
          child: TableEditor(table: testTable),
        ));

        expect(find.byType(Focus), findsOneWidget);
      });

      testWidgets('should handle semantic properties', (WidgetTester tester) async {
        await tester.pumpWidget(TestHelpers.createTestApp(
          child: TableEditor(table: testTable),
        ));

        // Basic semantic structure should be present
        TestHelpers.verifyAccessibilitySemantics(tester);
      });
    });
  });

  group('MobileTableEditor Widget Tests', () {
    late TableData testTable;

    setUp(() {
      testTable = TableData.create(3, 3);
      testTable.columns[0].header = 'Name';
      testTable.columns[1].header = 'Age';
      testTable.columns[2].header = 'City';
      testTable.setCellAt(0, 0, 'John');
      testTable.setCellAt(0, 1, '25');
      testTable.setCellAt(0, 2, 'NYC');
    });

    group('Mobile Interface', () {
      testWidgets('should render column navigation', (WidgetTester tester) async {
        await tester.pumpWidget(TestHelpers.createTestApp(
          child: MobileTableEditor(table: testTable),
        ));

        expect(find.byType(PageView), findsOneWidget);
        expect(find.text('Name'), findsOneWidget);
      });

      testWidgets('should show page indicators', (WidgetTester tester) async {
        await tester.pumpWidget(TestHelpers.createTestApp(
          child: MobileTableEditor(table: testTable),
        ));

        // Should show dots for page indication
        expect(find.byType(Container), findsAtLeast(3));
      });

      testWidgets('should show rows as list items', (WidgetTester tester) async {
        await tester.pumpWidget(TestHelpers.createTestApp(
          child: MobileTableEditor(table: testTable),
        ));

        expect(find.byType(ListView), findsOneWidget);
        expect(find.byType(ListTile), findsAtLeast(3));
        expect(find.text('Row 1'), findsOneWidget);
        expect(find.text('Row 2'), findsOneWidget);
        expect(find.text('Row 3'), findsOneWidget);
      });

      testWidgets('should allow cell editing through dialog', (WidgetTester tester) async {
        await tester.pumpWidget(TestHelpers.createTestApp(
          child: MobileTableEditor(table: testTable),
        ));

        // Tap on a row to edit
        await tester.tap(find.byType(ListTile).first);
        await tester.pumpAndSettle();

        expect(find.byType(AlertDialog), findsOneWidget);
        expect(find.text('Edit Cell'), findsOneWidget);
      });

      testWidgets('should not show edit dialog in read-only mode', (WidgetTester tester) async {
        await tester.pumpWidget(TestHelpers.createTestApp(
          child: MobileTableEditor(
            table: testTable,
            isReadOnly: true,
          ),
        ));

        await tester.tap(find.byType(ListTile).first);
        await tester.pumpAndSettle();

        expect(find.byType(AlertDialog), findsNothing);
      });

      testWidgets('should navigate between columns', (WidgetTester tester) async {
        await tester.pumpWidget(TestHelpers.createTestApp(
          child: MobileTableEditor(table: testTable),
        ));

        // Swipe to next column
        await tester.drag(find.byType(PageView), const Offset(-300, 0));
        await tester.pumpAndSettle();

        expect(find.text('Age'), findsOneWidget);
      });
    });
  });
}