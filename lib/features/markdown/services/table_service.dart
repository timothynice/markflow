import 'dart:math';

/// Represents a single cell in a table
class TableCell {
  String content;
  int columnSpan;
  int rowSpan;

  TableCell({
    this.content = '',
    this.columnSpan = 1,
    this.rowSpan = 1,
  });

  TableCell copyWith({
    String? content,
    int? columnSpan,
    int? rowSpan,
  }) {
    return TableCell(
      content: content ?? this.content,
      columnSpan: columnSpan ?? this.columnSpan,
      rowSpan: rowSpan ?? this.rowSpan,
    );
  }

  @override
  String toString() => content;
}

/// Represents table column alignment
enum TableAlignment {
  left,
  center,
  right,
}

/// Represents a column in a table
class TableColumn {
  String header;
  double width;
  TableAlignment alignment;
  double minWidth;
  double maxWidth;

  TableColumn({
    this.header = '',
    this.width = 100.0,
    this.alignment = TableAlignment.left,
    this.minWidth = 50.0,
    this.maxWidth = 500.0,
  });

  TableColumn copyWith({
    String? header,
    double? width,
    TableAlignment? alignment,
    double? minWidth,
    double? maxWidth,
  }) {
    return TableColumn(
      header: header ?? this.header,
      width: width ?? this.width,
      alignment: alignment ?? this.alignment,
      minWidth: minWidth ?? this.minWidth,
      maxWidth: maxWidth ?? this.maxWidth,
    );
  }
}

/// Represents a complete table structure
class TableData {
  List<TableColumn> columns;
  List<List<TableCell>> rows;

  TableData({
    required this.columns,
    required this.rows,
  });

  int get columnCount => columns.length;
  int get rowCount => rows.length;

  /// Create a new table with specified dimensions
  factory TableData.create(int rows, int columns) {
    final columnList = List.generate(
      columns,
      (index) => TableColumn(header: 'Column ${String.fromCharCode(65 + index)}'),
    );

    final rowList = List.generate(
      rows,
      (rowIndex) => List.generate(
        columns,
        (colIndex) => TableCell(),
      ),
    );

    return TableData(
      columns: columnList,
      rows: rowList,
    );
  }

  /// Get cell at specific position
  TableCell? getCellAt(int row, int column) {
    if (row < 0 || row >= rows.length) return null;
    if (column < 0 || column >= rows[row].length) return null;
    return rows[row][column];
  }

  /// Set cell content at specific position
  void setCellAt(int row, int column, String content) {
    if (row < 0 || row >= rows.length) return;
    if (column < 0 || column >= rows[row].length) return;
    rows[row][column].content = content;
  }

  /// Add a new row at specified index
  void insertRow(int index) {
    if (index < 0 || index > rows.length) return;
    final newRow = List.generate(columnCount, (i) => TableCell());
    rows.insert(index, newRow);
  }

  /// Add a new column at specified index
  void insertColumn(int index) {
    if (index < 0 || index > columnCount) return;

    // Add to columns list
    columns.insert(index, TableColumn(header: 'Column ${String.fromCharCode(65 + index)}'));

    // Add cells to each row
    for (final row in rows) {
      row.insert(index, TableCell());
    }
  }

  /// Remove row at specified index
  void deleteRow(int index) {
    if (index < 0 || index >= rows.length || rows.length <= 1) return;
    rows.removeAt(index);
  }

  /// Remove column at specified index
  void deleteColumn(int index) {
    if (index < 0 || index >= columnCount || columnCount <= 1) return;

    // Remove from columns list
    columns.removeAt(index);

    // Remove cells from each row
    for (final row in rows) {
      if (index < row.length) {
        row.removeAt(index);
      }
    }
  }

  /// Move row from one position to another
  void moveRow(int fromIndex, int toIndex) {
    if (fromIndex < 0 || fromIndex >= rows.length) return;
    if (toIndex < 0 || toIndex >= rows.length) return;
    if (fromIndex == toIndex) return;

    final row = rows.removeAt(fromIndex);
    rows.insert(toIndex, row);
  }

  /// Move column from one position to another
  void moveColumn(int fromIndex, int toIndex) {
    if (fromIndex < 0 || fromIndex >= columnCount) return;
    if (toIndex < 0 || toIndex >= columnCount) return;
    if (fromIndex == toIndex) return;

    // Move column
    final column = columns.removeAt(fromIndex);
    columns.insert(toIndex, column);

    // Move cells in each row
    for (final row in rows) {
      if (fromIndex < row.length) {
        final cell = row.removeAt(fromIndex);
        row.insert(toIndex, cell);
      }
    }
  }

  /// Resize column width
  void resizeColumn(int index, double width) {
    if (index < 0 || index >= columnCount) return;
    columns[index].width = width.clamp(columns[index].minWidth, columns[index].maxWidth);
  }

  /// Create a copy of the table
  TableData copy() {
    final newColumns = columns.map((col) => TableColumn(
      header: col.header,
      width: col.width,
      alignment: col.alignment,
      minWidth: col.minWidth,
      maxWidth: col.maxWidth,
    )).toList();

    final newRows = rows.map((row) =>
      row.map((cell) => TableCell(
        content: cell.content,
        columnSpan: cell.columnSpan,
        rowSpan: cell.rowSpan,
      )).toList()
    ).toList();

    return TableData(
      columns: newColumns,
      rows: newRows,
    );
  }
}

/// Service for handling table operations and markdown conversion
class TableService {
  /// Parse markdown table string into TableData
  static TableData? parseMarkdownTable(String markdown) {
    final lines = markdown.trim().split('\n');
    if (lines.length < 2) return null;

    // Parse header row
    final headerLine = lines[0].trim();
    if (!headerLine.startsWith('|') || !headerLine.endsWith('|')) return null;

    final headers = headerLine
        .substring(1, headerLine.length - 1)
        .split('|')
        .map((h) => h.trim())
        .toList();

    // Parse alignment row
    final alignmentLine = lines[1].trim();
    if (!alignmentLine.startsWith('|') || !alignmentLine.endsWith('|')) return null;

    final alignments = alignmentLine
        .substring(1, alignmentLine.length - 1)
        .split('|')
        .map((a) => _parseAlignment(a.trim()))
        .toList();

    if (headers.length != alignments.length) return null;

    // Create columns
    final columns = List.generate(headers.length, (i) => TableColumn(
      header: headers[i],
      alignment: alignments[i],
    ));

    // Parse data rows
    final rows = <List<TableCell>>[];
    for (int i = 2; i < lines.length; i++) {
      final line = lines[i].trim();
      if (!line.startsWith('|') || !line.endsWith('|')) continue;

      final cells = line
          .substring(1, line.length - 1)
          .split('|')
          .map((c) => TableCell(content: c.trim()))
          .toList();

      // Pad or trim cells to match column count
      while (cells.length < columns.length) {
        cells.add(TableCell());
      }
      if (cells.length > columns.length) {
        cells.removeRange(columns.length, cells.length);
      }

      rows.add(cells);
    }

    // Ensure at least one data row
    if (rows.isEmpty) {
      rows.add(List.generate(columns.length, (i) => TableCell()));
    }

    return TableData(columns: columns, rows: rows);
  }

  /// Convert TableData to markdown string
  static String tableToMarkdown(TableData table) {
    if (table.columns.isEmpty) return '';

    final buffer = StringBuffer();

    // Header row
    buffer.write('|');
    for (final column in table.columns) {
      buffer.write(' ${column.header} |');
    }
    buffer.writeln();

    // Alignment row
    buffer.write('|');
    for (final column in table.columns) {
      final alignment = _alignmentToMarkdown(column.alignment);
      buffer.write(' $alignment |');
    }
    buffer.writeln();

    // Data rows
    for (final row in table.rows) {
      buffer.write('|');
      for (int i = 0; i < table.columnCount; i++) {
        final cell = i < row.length ? row[i] : TableCell();
        buffer.write(' ${cell.content} |');
      }
      buffer.writeln();
    }

    return buffer.toString();
  }

  /// Find table boundaries in markdown text
  static TableBounds? findTableAt(String text, int cursorPosition) {
    final lines = text.split('\n');
    int currentPos = 0;
    int lineIndex = -1;

    // Find which line the cursor is on
    for (int i = 0; i < lines.length; i++) {
      final lineLength = lines[i].length + 1; // +1 for newline
      if (currentPos <= cursorPosition && cursorPosition < currentPos + lineLength) {
        lineIndex = i;
        break;
      }
      currentPos += lineLength;
    }

    if (lineIndex == -1) return null;

    // Check if current line looks like a table
    final currentLine = lines[lineIndex].trim();
    if (!_isTableLine(currentLine)) return null;

    // Find table boundaries
    int startLine = lineIndex;
    int endLine = lineIndex;

    // Find start of table
    while (startLine > 0 && _isTableLine(lines[startLine - 1].trim())) {
      startLine--;
    }

    // Find end of table
    while (endLine < lines.length - 1 && _isTableLine(lines[endLine + 1].trim())) {
      endLine++;
    }

    // Calculate text positions
    int startPos = 0;
    for (int i = 0; i < startLine; i++) {
      startPos += lines[i].length + 1;
    }

    int endPos = startPos;
    for (int i = startLine; i <= endLine; i++) {
      endPos += lines[i].length + 1;
    }
    endPos--; // Remove final newline

    return TableBounds(
      startLine: startLine,
      endLine: endLine,
      startPosition: startPos,
      endPosition: endPos,
      tableText: lines.sublist(startLine, endLine + 1).join('\n'),
    );
  }

  /// Replace table in text at specified bounds
  static String replaceTableInText(String text, TableBounds bounds, TableData newTable) {
    final newTableText = tableToMarkdown(newTable);
    return text.substring(0, bounds.startPosition) +
           newTableText +
           text.substring(bounds.endPosition + 1);
  }

  /// Helper methods
  static TableAlignment _parseAlignment(String align) {
    if (align.startsWith(':') && align.endsWith(':')) {
      return TableAlignment.center;
    } else if (align.endsWith(':')) {
      return TableAlignment.right;
    }
    return TableAlignment.left;
  }

  static String _alignmentToMarkdown(TableAlignment alignment) {
    switch (alignment) {
      case TableAlignment.center:
        return ':---:';
      case TableAlignment.right:
        return '---:';
      case TableAlignment.left:
      default:
        return '---';
    }
  }

  static bool _isTableLine(String line) {
    return line.startsWith('|') && line.endsWith('|') && line.contains('|');
  }
}

/// Represents the boundaries of a table in text
class TableBounds {
  final int startLine;
  final int endLine;
  final int startPosition;
  final int endPosition;
  final String tableText;

  TableBounds({
    required this.startLine,
    required this.endLine,
    required this.startPosition,
    required this.endPosition,
    required this.tableText,
  });
}

/// Represents a table operation for undo/redo
abstract class TableOperation {
  void execute(TableData table);
  void undo(TableData table);
}

class InsertRowOperation implements TableOperation {
  final int index;

  InsertRowOperation(this.index);

  @override
  void execute(TableData table) => table.insertRow(index);

  @override
  void undo(TableData table) => table.deleteRow(index);
}

class DeleteRowOperation implements TableOperation {
  final int index;
  final List<TableCell> deletedRow;

  DeleteRowOperation(this.index, this.deletedRow);

  @override
  void execute(TableData table) => table.deleteRow(index);

  @override
  void undo(TableData table) {
    table.rows.insert(index, deletedRow);
  }
}

class InsertColumnOperation implements TableOperation {
  final int index;

  InsertColumnOperation(this.index);

  @override
  void execute(TableData table) => table.insertColumn(index);

  @override
  void undo(TableData table) => table.deleteColumn(index);
}

class DeleteColumnOperation implements TableOperation {
  final int index;
  final TableColumn deletedColumn;
  final List<TableCell> deletedCells;

  DeleteColumnOperation(this.index, this.deletedColumn, this.deletedCells);

  @override
  void execute(TableData table) => table.deleteColumn(index);

  @override
  void undo(TableData table) {
    table.columns.insert(index, deletedColumn);
    for (int i = 0; i < table.rows.length && i < deletedCells.length; i++) {
      table.rows[i].insert(index, deletedCells[i]);
    }
  }
}

class SetCellContentOperation implements TableOperation {
  final int row;
  final int column;
  final String newContent;
  final String oldContent;

  SetCellContentOperation(this.row, this.column, this.newContent, this.oldContent);

  @override
  void execute(TableData table) => table.setCellAt(row, column, newContent);

  @override
  void undo(TableData table) => table.setCellAt(row, column, oldContent);
}

/// Manages table operation history for undo/redo
class TableHistoryManager {
  final List<TableOperation> _history = [];
  int _currentIndex = -1;

  void executeOperation(TableOperation operation, TableData table) {
    // Remove any operations after current index
    if (_currentIndex < _history.length - 1) {
      _history.removeRange(_currentIndex + 1, _history.length);
    }

    // Execute the operation
    operation.execute(table);

    // Add to history
    _history.add(operation);
    _currentIndex++;

    // Limit history size
    if (_history.length > 50) {
      _history.removeAt(0);
      _currentIndex--;
    }
  }

  bool canUndo() => _currentIndex >= 0;

  bool canRedo() => _currentIndex < _history.length - 1;

  void undo(TableData table) {
    if (!canUndo()) return;
    _history[_currentIndex].undo(table);
    _currentIndex--;
  }

  void redo(TableData table) {
    if (!canRedo()) return;
    _currentIndex++;
    _history[_currentIndex].execute(table);
  }

  void clear() {
    _history.clear();
    _currentIndex = -1;
  }
}