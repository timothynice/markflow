import 'package:flutter_test/flutter_test.dart';
import 'package:markflow/features/markdown/services/table_service.dart';

void main() {
  group('TableService Tests', () {
    group('Table Parsing', () {
      test('should parse simple table with headers', () {
        const markdown = '''| Name | Age | City |
| --- | --- | --- |
| John | 25 | NYC |
| Jane | 30 | LA |''';

        final table = TableService.parseMarkdownTable(markdown);

        expect(table, isNotNull);
        expect(table!.columnCount, equals(3));
        expect(table.rowCount, equals(2));
        expect(table.columns[0].header, equals('Name'));
        expect(table.columns[1].header, equals('Age'));
        expect(table.columns[2].header, equals('City'));
        expect(table.getCellAt(0, 0)!.content, equals('John'));
        expect(table.getCellAt(1, 2)!.content, equals('LA'));
      });

      test('should parse table with different alignments', () {
        const markdown = '''| Left | Center | Right |
| :--- | :---: | ---: |
| L1 | C1 | R1 |''';

        final table = TableService.parseMarkdownTable(markdown);

        expect(table, isNotNull);
        expect(table!.columns[0].alignment, equals(TableAlignment.left));
        expect(table.columns[1].alignment, equals(TableAlignment.center));
        expect(table.columns[2].alignment, equals(TableAlignment.right));
      });

      test('should handle empty cells', () {
        const markdown = '''| A | B | C |
| --- | --- | --- |
| 1 |  | 3 |
|  | 2 |  |''';

        final table = TableService.parseMarkdownTable(markdown);

        expect(table, isNotNull);
        expect(table!.getCellAt(0, 1)!.content, equals(''));
        expect(table.getCellAt(1, 0)!.content, equals(''));
        expect(table.getCellAt(1, 2)!.content, equals(''));
      });

      test('should return null for invalid table', () {
        const invalidMarkdown = 'Not a table';
        final table = TableService.parseMarkdownTable(invalidMarkdown);
        expect(table, isNull);
      });

      test('should handle table with missing alignment row', () {
        const markdown = '''| Name | Age |
| John | 25 |''';

        final table = TableService.parseMarkdownTable(markdown);
        expect(table, isNull);
      });
    });

    group('Table Generation', () {
      test('should generate markdown from table data', () {
        final table = TableData.create(2, 3);
        table.columns[0].header = 'Name';
        table.columns[1].header = 'Age';
        table.columns[2].header = 'City';
        table.setCellAt(0, 0, 'John');
        table.setCellAt(0, 1, '25');
        table.setCellAt(0, 2, 'NYC');
        table.setCellAt(1, 0, 'Jane');
        table.setCellAt(1, 1, '30');
        table.setCellAt(1, 2, 'LA');

        final markdown = TableService.tableToMarkdown(table);

        expect(markdown, contains('| Name | Age | City |'));
        expect(markdown, contains('| --- | --- | --- |'));
        expect(markdown, contains('| John | 25 | NYC |'));
        expect(markdown, contains('| Jane | 30 | LA |'));
      });

      test('should generate markdown with correct alignment indicators', () {
        final table = TableData.create(1, 3);
        table.columns[0].alignment = TableAlignment.left;
        table.columns[1].alignment = TableAlignment.center;
        table.columns[2].alignment = TableAlignment.right;

        final markdown = TableService.tableToMarkdown(table);

        expect(markdown, contains('| --- | :---: | ---: |'));
      });

      test('should handle empty table', () {
        final table = TableData(columns: [], rows: []);
        final markdown = TableService.tableToMarkdown(table);
        expect(markdown, equals(''));
      });
    });

    group('Table Detection', () {
      test('should find table at cursor position', () {
        const text = '''# Document

| Name | Age |
| --- | --- |
| John | 25 |

Some text after.''';

        final bounds = TableService.findTableAt(text, 20); // Position within table

        expect(bounds, isNotNull);
        expect(bounds!.startLine, equals(2));
        expect(bounds.endLine, equals(4));
        expect(bounds.tableText, contains('| Name | Age |'));
      });

      test('should return null when cursor not in table', () {
        const text = '''# Document

Some text here.

More text.''';

        final bounds = TableService.findTableAt(text, 20);
        expect(bounds, isNull);
      });

      test('should find table boundaries correctly', () {
        const text = '''Before text

| Col1 | Col2 |
| --- | --- |
| A | B |
| C | D |

After text''';

        final bounds = TableService.findTableAt(text, 30);

        expect(bounds, isNotNull);
        expect(bounds!.tableText.split('\n').length, equals(4));
        expect(bounds.tableText, contains('| Col1 | Col2 |'));
        expect(bounds.tableText, contains('| C | D |'));
      });
    });

    group('Table Replacement', () {
      test('should replace table in text correctly', () {
        const originalText = '''# Document

| Old | Table |
| --- | --- |
| A | B |

End text''';

        final bounds = TableService.findTableAt(originalText, 30)!;
        final newTable = TableData.create(1, 2);
        newTable.columns[0].header = 'New';
        newTable.columns[1].header = 'Table';
        newTable.setCellAt(0, 0, 'X');
        newTable.setCellAt(0, 1, 'Y');

        final newText = TableService.replaceTableInText(originalText, bounds, newTable);

        expect(newText, contains('| New | Table |'));
        expect(newText, contains('| X | Y |'));
        expect(newText, contains('# Document'));
        expect(newText, contains('End text'));
        expect(newText, isNot(contains('| Old | Table |')));
      });
    });
  });

  group('TableData Tests', () {
    group('Table Creation', () {
      test('should create table with specified dimensions', () {
        final table = TableData.create(3, 4);

        expect(table.rowCount, equals(3));
        expect(table.columnCount, equals(4));
        expect(table.columns.length, equals(4));
        expect(table.rows.length, equals(3));
        expect(table.rows[0].length, equals(4));
      });

      test('should create columns with default headers', () {
        final table = TableData.create(2, 3);

        expect(table.columns[0].header, equals('Column A'));
        expect(table.columns[1].header, equals('Column B'));
        expect(table.columns[2].header, equals('Column C'));
      });

      test('should initialize empty cells', () {
        final table = TableData.create(2, 2);

        for (int i = 0; i < 2; i++) {
          for (int j = 0; j < 2; j++) {
            expect(table.getCellAt(i, j)!.content, equals(''));
          }
        }
      });
    });

    group('Cell Operations', () {
      late TableData table;

      setUp(() {
        table = TableData.create(3, 3);
      });

      test('should get and set cell content', () {
        table.setCellAt(1, 1, 'Test Content');
        expect(table.getCellAt(1, 1)!.content, equals('Test Content'));
      });

      test('should return null for invalid cell coordinates', () {
        expect(table.getCellAt(-1, 0), isNull);
        expect(table.getCellAt(0, -1), isNull);
        expect(table.getCellAt(10, 0), isNull);
        expect(table.getCellAt(0, 10), isNull);
      });

      test('should handle setting content for invalid coordinates', () {
        // Should not throw exception
        table.setCellAt(-1, 0, 'Invalid');
        table.setCellAt(10, 10, 'Invalid');
      });
    });

    group('Row Operations', () {
      late TableData table;

      setUp(() {
        table = TableData.create(3, 3);
        // Add some test data
        for (int i = 0; i < 3; i++) {
          for (int j = 0; j < 3; j++) {
            table.setCellAt(i, j, 'R${i}C$j');
          }
        }
      });

      test('should insert row at specified index', () {
        table.insertRow(1);

        expect(table.rowCount, equals(4));
        expect(table.getCellAt(0, 0)!.content, equals('R0C0'));
        expect(table.getCellAt(1, 0)!.content, equals(''));
        expect(table.getCellAt(2, 0)!.content, equals('R1C0'));
      });

      test('should delete row at specified index', () {
        table.deleteRow(1);

        expect(table.rowCount, equals(2));
        expect(table.getCellAt(0, 0)!.content, equals('R0C0'));
        expect(table.getCellAt(1, 0)!.content, equals('R2C0'));
      });

      test('should not delete last row', () {
        final singleRowTable = TableData.create(1, 2);
        singleRowTable.deleteRow(0);

        expect(singleRowTable.rowCount, equals(1));
      });

      test('should move row correctly', () {
        table.moveRow(0, 2);

        expect(table.getCellAt(0, 0)!.content, equals('R1C0'));
        expect(table.getCellAt(1, 0)!.content, equals('R2C0'));
        expect(table.getCellAt(2, 0)!.content, equals('R0C0'));
      });
    });

    group('Column Operations', () {
      late TableData table;

      setUp(() {
        table = TableData.create(3, 3);
        table.columns[0].header = 'Col0';
        table.columns[1].header = 'Col1';
        table.columns[2].header = 'Col2';
        for (int i = 0; i < 3; i++) {
          for (int j = 0; j < 3; j++) {
            table.setCellAt(i, j, 'R${i}C$j');
          }
        }
      });

      test('should insert column at specified index', () {
        table.insertColumn(1);

        expect(table.columnCount, equals(4));
        expect(table.columns[0].header, equals('Col0'));
        expect(table.columns[1].header, contains('Column'));
        expect(table.columns[2].header, equals('Col1'));
        expect(table.getCellAt(0, 0)!.content, equals('R0C0'));
        expect(table.getCellAt(0, 1)!.content, equals(''));
        expect(table.getCellAt(0, 2)!.content, equals('R0C1'));
      });

      test('should delete column at specified index', () {
        table.deleteColumn(1);

        expect(table.columnCount, equals(2));
        expect(table.columns[0].header, equals('Col0'));
        expect(table.columns[1].header, equals('Col2'));
        expect(table.getCellAt(0, 1)!.content, equals('R0C2'));
      });

      test('should not delete last column', () {
        final singleColumnTable = TableData.create(2, 1);
        singleColumnTable.deleteColumn(0);

        expect(singleColumnTable.columnCount, equals(1));
      });

      test('should move column correctly', () {
        table.moveColumn(0, 2);

        expect(table.columns[0].header, equals('Col1'));
        expect(table.columns[1].header, equals('Col2'));
        expect(table.columns[2].header, equals('Col0'));
        expect(table.getCellAt(0, 0)!.content, equals('R0C1'));
        expect(table.getCellAt(0, 2)!.content, equals('R0C0'));
      });

      test('should resize column within bounds', () {
        table.resizeColumn(0, 150.0);
        expect(table.columns[0].width, equals(150.0));

        // Test min width constraint
        table.resizeColumn(0, 10.0);
        expect(table.columns[0].width, equals(table.columns[0].minWidth));

        // Test max width constraint
        table.resizeColumn(0, 1000.0);
        expect(table.columns[0].width, equals(table.columns[0].maxWidth));
      });
    });

    group('Table Copy', () {
      test('should create deep copy of table', () {
        final original = TableData.create(2, 2);
        original.setCellAt(0, 0, 'Original');
        original.columns[0].header = 'Original Header';

        final copy = original.copy();

        expect(copy.getCellAt(0, 0)!.content, equals('Original'));
        expect(copy.columns[0].header, equals('Original Header'));

        // Modify copy - original should remain unchanged
        copy.setCellAt(0, 0, 'Modified');
        copy.columns[0].header = 'Modified Header';

        expect(original.getCellAt(0, 0)!.content, equals('Original'));
        expect(original.columns[0].header, equals('Original Header'));
      });
    });
  });

  group('TableCell Tests', () {
    test('should create cell with default values', () {
      final cell = TableCell();

      expect(cell.content, equals(''));
      expect(cell.columnSpan, equals(1));
      expect(cell.rowSpan, equals(1));
    });

    test('should create cell with custom values', () {
      final cell = TableCell(
        content: 'Test',
        columnSpan: 2,
        rowSpan: 3,
      );

      expect(cell.content, equals('Test'));
      expect(cell.columnSpan, equals(2));
      expect(cell.rowSpan, equals(3));
    });

    test('should create copy with modifications', () {
      final original = TableCell(content: 'Original');
      final copy = original.copyWith(content: 'Modified', columnSpan: 2);

      expect(copy.content, equals('Modified'));
      expect(copy.columnSpan, equals(2));
      expect(copy.rowSpan, equals(1)); // Should retain original value
    });

    test('should convert to string correctly', () {
      final cell = TableCell(content: 'Test Content');
      expect(cell.toString(), equals('Test Content'));
    });
  });

  group('TableColumn Tests', () {
    test('should create column with default values', () {
      final column = TableColumn();

      expect(column.header, equals(''));
      expect(column.width, equals(100.0));
      expect(column.alignment, equals(TableAlignment.left));
      expect(column.minWidth, equals(50.0));
      expect(column.maxWidth, equals(500.0));
    });

    test('should create column with custom values', () {
      final column = TableColumn(
        header: 'Test Header',
        width: 200.0,
        alignment: TableAlignment.center,
        minWidth: 100.0,
        maxWidth: 400.0,
      );

      expect(column.header, equals('Test Header'));
      expect(column.width, equals(200.0));
      expect(column.alignment, equals(TableAlignment.center));
      expect(column.minWidth, equals(100.0));
      expect(column.maxWidth, equals(400.0));
    });

    test('should create copy with modifications', () {
      final original = TableColumn(header: 'Original');
      final copy = original.copyWith(
        header: 'Modified',
        alignment: TableAlignment.right,
      );

      expect(copy.header, equals('Modified'));
      expect(copy.alignment, equals(TableAlignment.right));
      expect(copy.width, equals(100.0)); // Should retain original value
    });
  });

  group('TableHistoryManager Tests', () {
    late TableData table;
    late TableHistoryManager historyManager;

    setUp(() {
      table = TableData.create(2, 2);
      historyManager = TableHistoryManager();
    });

    test('should execute operation and add to history', () {
      final operation = SetCellContentOperation(0, 0, 'New', '');

      expect(historyManager.canUndo(), isFalse);

      historyManager.executeOperation(operation, table);

      expect(table.getCellAt(0, 0)!.content, equals('New'));
      expect(historyManager.canUndo(), isTrue);
      expect(historyManager.canRedo(), isFalse);
    });

    test('should undo and redo operations', () {
      final operation = SetCellContentOperation(0, 0, 'New', '');

      historyManager.executeOperation(operation, table);
      expect(table.getCellAt(0, 0)!.content, equals('New'));

      historyManager.undo(table);
      expect(table.getCellAt(0, 0)!.content, equals(''));
      expect(historyManager.canRedo(), isTrue);

      historyManager.redo(table);
      expect(table.getCellAt(0, 0)!.content, equals('New'));
    });

    test('should clear history', () {
      final operation = SetCellContentOperation(0, 0, 'New', '');
      historyManager.executeOperation(operation, table);

      expect(historyManager.canUndo(), isTrue);

      historyManager.clear();

      expect(historyManager.canUndo(), isFalse);
      expect(historyManager.canRedo(), isFalse);
    });

    test('should limit history size', () {
      // Add more operations than the limit (50)
      for (int i = 0; i < 60; i++) {
        final operation = SetCellContentOperation(0, 0, 'Content $i', 'Content ${i-1}');
        historyManager.executeOperation(operation, table);
      }

      // Should still be able to undo (history was trimmed, not cleared)
      expect(historyManager.canUndo(), isTrue);
    });
  });

  group('Table Operations Tests', () {
    late TableData table;

    setUp(() {
      table = TableData.create(3, 3);
      for (int i = 0; i < 3; i++) {
        for (int j = 0; j < 3; j++) {
          table.setCellAt(i, j, 'R${i}C$j');
        }
      }
    });

    group('InsertRowOperation', () {
      test('should execute and undo correctly', () {
        final operation = InsertRowOperation(1);

        operation.execute(table);
        expect(table.rowCount, equals(4));
        expect(table.getCellAt(1, 0)!.content, equals(''));

        operation.undo(table);
        expect(table.rowCount, equals(3));
        expect(table.getCellAt(1, 0)!.content, equals('R1C0'));
      });
    });

    group('DeleteRowOperation', () {
      test('should execute and undo correctly', () {
        final deletedRow = List<TableCell>.from(table.rows[1]);
        final operation = DeleteRowOperation(1, deletedRow);

        operation.execute(table);
        expect(table.rowCount, equals(2));
        expect(table.getCellAt(1, 0)!.content, equals('R2C0'));

        operation.undo(table);
        expect(table.rowCount, equals(3));
        expect(table.getCellAt(1, 0)!.content, equals('R1C0'));
      });
    });

    group('InsertColumnOperation', () {
      test('should execute and undo correctly', () {
        final operation = InsertColumnOperation(1);

        operation.execute(table);
        expect(table.columnCount, equals(4));
        expect(table.getCellAt(0, 1)!.content, equals(''));

        operation.undo(table);
        expect(table.columnCount, equals(3));
        expect(table.getCellAt(0, 1)!.content, equals('R0C1'));
      });
    });

    group('SetCellContentOperation', () {
      test('should execute and undo correctly', () {
        final operation = SetCellContentOperation(1, 1, 'New Content', 'R1C1');

        operation.execute(table);
        expect(table.getCellAt(1, 1)!.content, equals('New Content'));

        operation.undo(table);
        expect(table.getCellAt(1, 1)!.content, equals('R1C1'));
      });
    });
  });
}