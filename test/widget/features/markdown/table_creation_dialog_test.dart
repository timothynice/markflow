import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:markflow/features/markdown/services/table_service.dart';
import 'package:markflow/features/markdown/widgets/table_creation_dialog.dart';
import '../../../test_helpers.dart';

void main() {
  group('TableCreationDialog Widget Tests', () {
    group('Basic Rendering', () {
      testWidgets('should render dialog with all sections', (WidgetTester tester) async {
        await tester.pumpWidget(TestHelpers.createTestApp(
          child: Material(
            child: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () => TableCreationDialog.show(context),
                child: Text('Show Dialog'),
              ),
            ),
          ),
        ));

        await tester.tap(find.text('Show Dialog'));
        await tester.pumpAndSettle();

        expect(find.text('Create Table'), findsOneWidget);
        expect(find.text('Dimensions'), findsOneWidget);
        expect(find.text('Headers'), findsOneWidget);
        expect(find.text('Default Alignment'), findsOneWidget);
        expect(find.text('Preview'), findsOneWidget);
      });

      testWidgets('should render with default values', (WidgetTester tester) async {
        await tester.pumpWidget(TestHelpers.createTestApp(
          child: Material(
            child: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () => TableCreationDialog.show(context),
                child: Text('Show Dialog'),
              ),
            ),
          ),
        ));

        await tester.tap(find.text('Show Dialog'));
        await tester.pumpAndSettle();

        // Check default row/column values
        expect(find.text('3'), findsAtLeast(2)); // Default 3 rows and 3 columns
        expect(find.byType(Switch), findsOneWidget); // Header toggle
      });

      testWidgets('should render with custom initial values', (WidgetTester tester) async {
        await tester.pumpWidget(TestHelpers.createTestApp(
          child: Material(
            child: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () => TableCreationDialog.show(
                  context,
                  initialRows: 5,
                  initialColumns: 4,
                ),
                child: Text('Show Dialog'),
              ),
            ),
          ),
        ));

        await tester.tap(find.text('Show Dialog'));
        await tester.pumpAndSettle();

        expect(find.text('5'), findsOneWidget); // Custom rows
        expect(find.text('4'), findsOneWidget); // Custom columns
      });
    });

    group('Dimension Controls', () {
      testWidgets('should update rows when input changes', (WidgetTester tester) async {
        await tester.pumpWidget(TestHelpers.createTestApp(
          child: Material(
            child: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () => TableCreationDialog.show(context),
                child: Text('Show Dialog'),
              ),
            ),
          ),
        ));

        await tester.tap(find.text('Show Dialog'));
        await tester.pumpAndSettle();

        // Find the rows input field and change it
        final rowsField = find.ancestor(
          of: find.text('Rows'),
          matching: find.byType(Column),
        ).first;

        final textField = find.descendant(
          of: rowsField,
          matching: find.byType(TextFormField),
        );

        await tester.enterText(textField, '5');
        await tester.pump();

        // Preview should show indication of more rows
        expect(find.text('... and 2 more rows'), findsOneWidget);
      });

      testWidgets('should update columns when input changes', (WidgetTester tester) async {
        await tester.pumpWidget(TestHelpers.createTestApp(
          child: Material(
            child: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () => TableCreationDialog.show(context),
                child: Text('Show Dialog'),
              ),
            ),
          ),
        ));

        await tester.tap(find.text('Show Dialog'));
        await tester.pumpAndSettle();

        // Find the columns input field and change it
        final columnsField = find.ancestor(
          of: find.text('Columns'),
          matching: find.byType(Column),
        ).first;

        final textField = find.descendant(
          of: columnsField,
          matching: find.byType(TextFormField),
        );

        await tester.enterText(textField, '2');
        await tester.pump();

        // Should now show only 2 header inputs
        expect(find.text('Header 1'), findsOneWidget);
        expect(find.text('Header 2'), findsOneWidget);
        expect(find.text('Header 3'), findsNothing);
      });

      testWidgets('should validate dimension inputs', (WidgetTester tester) async {
        await tester.pumpWidget(TestHelpers.createTestApp(
          child: Material(
            child: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () => TableCreationDialog.show(context),
                child: Text('Show Dialog'),
              ),
            ),
          ),
        ));

        await tester.tap(find.text('Show Dialog'));
        await tester.pumpAndSettle();

        // Enter invalid values
        final textFields = find.byType(TextFormField);
        await tester.enterText(textFields.first, '0');
        await tester.enterText(textFields.at(1), '25');

        // Try to create table
        await tester.tap(find.text('Create Table'));
        await tester.pump();

        // Should show validation errors
        expect(find.text('1-20'), findsOneWidget);
        expect(find.text('1-10'), findsOneWidget);
      });
    });

    group('Header Controls', () {
      testWidgets('should toggle header inclusion', (WidgetTester tester) async {
        await tester.pumpWidget(TestHelpers.createTestApp(
          child: Material(
            child: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () => TableCreationDialog.show(context),
                child: Text('Show Dialog'),
              ),
            ),
          ),
        ));

        await tester.tap(find.text('Show Dialog'));
        await tester.pumpAndSettle();

        // Initially headers should be enabled
        expect(find.text('Header 1'), findsOneWidget);

        // Toggle headers off
        await tester.tap(find.byType(Switch));
        await tester.pump();

        // Header inputs should be hidden
        expect(find.text('Header 1'), findsNothing);
      });

      testWidgets('should update header names', (WidgetTester tester) async {
        await tester.pumpWidget(TestHelpers.createTestApp(
          child: Material(
            child: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () => TableCreationDialog.show(context),
                child: Text('Show Dialog'),
              ),
            ),
          ),
        ));

        await tester.tap(find.text('Show Dialog'));
        await tester.pumpAndSettle();

        // Find header input and change it
        final headerField = find.ancestor(
          of: find.text('Header 1'),
          matching: find.byType(TextFormField),
        );

        await tester.enterText(headerField, 'Custom Header');
        await tester.pump();

        // Preview should show the custom header
        expect(find.text('Custom Header'), findsOneWidget);
      });

      testWidgets('should validate required header names', (WidgetTester tester) async {
        await tester.pumpWidget(TestHelpers.createTestApp(
          child: Material(
            child: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () => TableCreationDialog.show(context),
                child: Text('Show Dialog'),
              ),
            ),
          ),
        ));

        await tester.tap(find.text('Show Dialog'));
        await tester.pumpAndSettle();

        // Clear header name
        final headerField = find.ancestor(
          of: find.text('Header 1'),
          matching: find.byType(TextFormField),
        );

        await tester.enterText(headerField, '');

        // Try to create table
        await tester.tap(find.text('Create Table'));
        await tester.pump();

        expect(find.text('Header name required'), findsAtLeast(1));
      });

      testWidgets('should navigate between header fields with tab', (WidgetTester tester) async {
        await tester.pumpWidget(TestHelpers.createTestApp(
          child: Material(
            child: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () => TableCreationDialog.show(context),
                child: Text('Show Dialog'),
              ),
            ),
          ),
        ));

        await tester.tap(find.text('Show Dialog'));
        await tester.pumpAndSettle();

        // Focus first header field
        final headerField = find.ancestor(
          of: find.text('Header 1'),
          matching: find.byType(TextFormField),
        );

        await tester.tap(headerField);
        await tester.pump();

        // Press enter to move to next field
        await tester.testTextInput.receiveAction(TextInputAction.next);
        await tester.pump();
      });
    });

    group('Alignment Controls', () {
      testWidgets('should render alignment options', (WidgetTester tester) async {
        await tester.pumpWidget(TestHelpers.createTestApp(
          child: Material(
            child: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () => TableCreationDialog.show(context),
                child: Text('Show Dialog'),
              ),
            ),
          ),
        ));

        await tester.tap(find.text('Show Dialog'));
        await tester.pumpAndSettle();

        expect(find.text('Left'), findsOneWidget);
        expect(find.text('Center'), findsOneWidget);
        expect(find.text('Right'), findsOneWidget);
      });

      testWidgets('should select alignment option', (WidgetTester tester) async {
        await tester.pumpWidget(TestHelpers.createTestApp(
          child: Material(
            child: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () => TableCreationDialog.show(context),
                child: Text('Show Dialog'),
              ),
            ),
          ),
        ));

        await tester.tap(find.text('Show Dialog'));
        await tester.pumpAndSettle();

        // Select center alignment
        await tester.tap(find.text('Center'));
        await tester.pump();

        // Left should be selected by default initially
        expect(find.byType(FilterChip), findsNWidgets(3));
      });
    });

    group('Preview', () {
      testWidgets('should show table preview', (WidgetTester tester) async {
        await tester.pumpWidget(TestHelpers.createTestApp(
          child: Material(
            child: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () => TableCreationDialog.show(context),
                child: Text('Show Dialog'),
              ),
            ),
          ),
        ));

        await tester.tap(find.text('Show Dialog'));
        await tester.pumpAndSettle();

        // Should show preview with default headers
        expect(find.text('Column A'), findsOneWidget);
        expect(find.text('Column B'), findsOneWidget);
        expect(find.text('Column C'), findsOneWidget);
      });

      testWidgets('should update preview when dimensions change', (WidgetTester tester) async {
        await tester.pumpWidget(TestHelpers.createTestApp(
          child: Material(
            child: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () => TableCreationDialog.show(context),
                child: Text('Show Dialog'),
              ),
            ),
          ),
        ));

        await tester.tap(find.text('Show Dialog'));
        await tester.pumpAndSettle();

        // Change rows to 5
        final rowsField = find.ancestor(
          of: find.text('Rows'),
          matching: find.byType(Column),
        ).first;

        final textField = find.descendant(
          of: rowsField,
          matching: find.byType(TextFormField),
        );

        await tester.enterText(textField, '5');
        await tester.pump();

        // Preview should indicate more rows
        expect(find.text('... and 2 more rows'), findsOneWidget);
      });

      testWidgets('should hide preview headers when headers disabled', (WidgetTester tester) async {
        await tester.pumpWidget(TestHelpers.createTestApp(
          child: Material(
            child: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () => TableCreationDialog.show(context),
                child: Text('Show Dialog'),
              ),
            ),
          ),
        ));

        await tester.tap(find.text('Show Dialog'));
        await tester.pumpAndSettle();

        // Toggle headers off
        await tester.tap(find.byType(Switch));
        await tester.pump();

        // Preview should not show header row with different background
        // This is more of a visual test - we can check that structure changes
        expect(find.text('Column A'), findsNothing);
      });
    });

    group('Dialog Actions', () {
      testWidgets('should cancel dialog', (WidgetTester tester) async {
        await tester.pumpWidget(TestHelpers.createTestApp(
          child: Material(
            child: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () => TableCreationDialog.show(context),
                child: Text('Show Dialog'),
              ),
            ),
          ),
        ));

        await tester.tap(find.text('Show Dialog'));
        await tester.pumpAndSettle();

        expect(find.text('Create Table'), findsOneWidget);

        await tester.tap(find.text('Cancel'));
        await tester.pumpAndSettle();

        expect(find.text('Create Table'), findsNothing);
      });

      testWidgets('should create table with correct data', (WidgetTester tester) async {
        TableData? createdTable;

        await tester.pumpWidget(TestHelpers.createTestApp(
          child: Material(
            child: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () async {
                  createdTable = await TableCreationDialog.show(context);
                },
                child: Text('Show Dialog'),
              ),
            ),
          ),
        ));

        await tester.tap(find.text('Show Dialog'));
        await tester.pumpAndSettle();

        // Modify some settings
        final headerField = find.ancestor(
          of: find.text('Header 1'),
          matching: find.byType(TextFormField),
        );
        await tester.enterText(headerField, 'Name');

        await tester.tap(find.text('Create Table'));
        await tester.pumpAndSettle();

        expect(createdTable, isNotNull);
        expect(createdTable!.rowCount, equals(3));
        expect(createdTable!.columnCount, equals(3));
        expect(createdTable!.columns[0].header, equals('Name'));
      });

      testWidgets('should not create table with invalid data', (WidgetTester tester) async {
        await tester.pumpWidget(TestHelpers.createTestApp(
          child: Material(
            child: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () => TableCreationDialog.show(context),
                child: Text('Show Dialog'),
              ),
            ),
          ),
        ));

        await tester.tap(find.text('Show Dialog'));
        await tester.pumpAndSettle();

        // Enter invalid data
        final textFields = find.byType(TextFormField);
        await tester.enterText(textFields.first, '0');

        await tester.tap(find.text('Create Table'));
        await tester.pump();

        // Dialog should still be open due to validation error
        expect(find.text('Create Table'), findsOneWidget);
      });
    });

    group('Responsive Behavior', () {
      testWidgets('should adapt to mobile screen size', (WidgetTester tester) async {
        await tester.pumpWidget(TestHelpers.createTestApp(
          screenSize: TestHelpers.mobileSize,
          child: Material(
            child: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () => TableCreationDialog.show(context),
                child: Text('Show Dialog'),
              ),
            ),
          ),
        ));

        await tester.tap(find.text('Show Dialog'));
        await tester.pumpAndSettle();

        // Dialog should be wider on mobile
        expect(find.text('Create Table'), findsOneWidget);
        expect(find.byType(SingleChildScrollView), findsAtLeast(1));
      });

      testWidgets('should scroll on small screens', (WidgetTester tester) async {
        await tester.pumpWidget(TestHelpers.createTestApp(
          screenSize: const Size(300, 400), // Very small screen
          child: Material(
            child: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () => TableCreationDialog.show(context),
                child: Text('Show Dialog'),
              ),
            ),
          ),
        ));

        await tester.tap(find.text('Show Dialog'));
        await tester.pumpAndSettle();

        expect(find.byType(SingleChildScrollView), findsAtLeast(1));
      });
    });

    group('Accessibility', () {
      testWidgets('should provide semantic labels', (WidgetTester tester) async {
        await tester.pumpWidget(TestHelpers.createTestApp(
          child: Material(
            child: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () => TableCreationDialog.show(context),
                child: Text('Show Dialog'),
              ),
            ),
          ),
        ));

        await tester.tap(find.text('Show Dialog'));
        await tester.pumpAndSettle();

        TestHelpers.verifyAccessibilitySemantics(
          tester,
          expectsButton: true,
          expectsTextField: true,
        );
      });

      testWidgets('should support keyboard navigation', (WidgetTester tester) async {
        await tester.pumpWidget(TestHelpers.createTestApp(
          child: Material(
            child: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () => TableCreationDialog.show(context),
                child: Text('Show Dialog'),
              ),
            ),
          ),
        ));

        await tester.tap(find.text('Show Dialog'));
        await tester.pumpAndSettle();

        // Should be able to navigate with tab
        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await tester.pump();
      });
    });
  });

  group('QuickTableButtons Widget Tests', () {
    group('Basic Rendering', () {
      testWidgets('should render quick table buttons', (WidgetTester tester) async {
        TableData? createdTable;

        await tester.pumpWidget(TestHelpers.createTestApp(
          child: QuickTableButtons(
            onTableCreated: (table) => createdTable = table,
          ),
        ));

        expect(find.text('2×2'), findsOneWidget);
        expect(find.text('3×3'), findsOneWidget);
        expect(find.text('4×3'), findsOneWidget);
        expect(find.text('5×4'), findsOneWidget);
        expect(find.text('Custom'), findsOneWidget);
      });

      testWidgets('should create table when quick button pressed', (WidgetTester tester) async {
        TableData? createdTable;

        await tester.pumpWidget(TestHelpers.createTestApp(
          child: QuickTableButtons(
            onTableCreated: (table) => createdTable = table,
          ),
        ));

        await tester.tap(find.text('2×2'));
        await tester.pumpAndSettle();

        expect(createdTable, isNotNull);
        expect(createdTable!.rowCount, equals(2));
        expect(createdTable!.columnCount, equals(2));
      });

      testWidgets('should open custom dialog when custom button pressed', (WidgetTester tester) async {
        await tester.pumpWidget(TestHelpers.createTestApp(
          child: QuickTableButtons(
            onTableCreated: (table) {},
          ),
        ));

        await tester.tap(find.text('Custom'));
        await tester.pumpAndSettle();

        expect(find.text('Create Table'), findsOneWidget);
      });

      testWidgets('should create table from custom dialog', (WidgetTester tester) async {
        TableData? createdTable;

        await tester.pumpWidget(TestHelpers.createTestApp(
          child: QuickTableButtons(
            onTableCreated: (table) => createdTable = table,
          ),
        ));

        await tester.tap(find.text('Custom'));
        await tester.pumpAndSettle();

        await tester.tap(find.text('Create Table'));
        await tester.pumpAndSettle();

        expect(createdTable, isNotNull);
      });
    });

    group('Button Variations', () {
      testWidgets('should create different sized tables', (WidgetTester tester) async {
        final Map<String, TableData> createdTables = {};

        await tester.pumpWidget(TestHelpers.createTestApp(
          child: QuickTableButtons(
            onTableCreated: (table) {
              createdTables['${table.rowCount}×${table.columnCount}'] = table;
            },
          ),
        ));

        // Test each quick button
        await tester.tap(find.text('2×2'));
        await tester.pump();

        await tester.tap(find.text('3×3'));
        await tester.pump();

        await tester.tap(find.text('4×3'));
        await tester.pump();

        await tester.tap(find.text('5×4'));
        await tester.pump();

        expect(createdTables['2×2'], isNotNull);
        expect(createdTables['3×3'], isNotNull);
        expect(createdTables['3×4'], isNotNull);
        expect(createdTables['4×5'], isNotNull);

        expect(createdTables['2×2']!.rowCount, equals(2));
        expect(createdTables['2×2']!.columnCount, equals(2));
        expect(createdTables['4×5']!.rowCount, equals(4));
        expect(createdTables['4×5']!.columnCount, equals(5));
      });
    });

    group('Layout', () {
      testWidgets('should wrap buttons on small screens', (WidgetTester tester) async {
        await tester.pumpWidget(TestHelpers.createTestApp(
          screenSize: TestHelpers.mobileSize,
          child: QuickTableButtons(
            onTableCreated: (table) {},
          ),
        ));

        expect(find.byType(Wrap), findsOneWidget);
        expect(find.byType(OutlinedButton), findsNWidgets(5));
      });
    });
  });
}