import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../services/table_service.dart' as ts;

/// Callback for when table data changes
typedef TableChangeCallback = void Function(ts.TableData table);

/// Callback for table operation execution
typedef TableOperationCallback = void Function(ts.TableOperation operation);

/// Interactive table editor with resize handles and context menus
class TableEditor extends StatefulWidget {
  final ts.TableData table;
  final TableChangeCallback? onTableChanged;
  final TableOperationCallback? onOperation;
  final bool isReadOnly;
  final double maxWidth;
  final double maxHeight;

  const TableEditor({
    super.key,
    required this.table,
    this.onTableChanged,
    this.onOperation,
    this.isReadOnly = false,
    this.maxWidth = double.infinity,
    this.maxHeight = double.infinity,
  });

  @override
  State<TableEditor> createState() => _TableEditorState();
}

class _TableEditorState extends State<TableEditor> {
  late ts.TableData _table;
  late ts.TableHistoryManager _historyManager;

  // Editing state
  int? _editingRow;
  int? _editingColumn;
  final TextEditingController _editController = TextEditingController();
  final FocusNode _editFocus = FocusNode();

  // Selection state
  int? _selectedRow;
  int? _selectedColumn;

  // Resize state
  int? _resizingColumn;
  double _resizeStartX = 0;
  double _resizeStartWidth = 0;

  // Scrolling
  final ScrollController _horizontalScrollController = ScrollController();
  final ScrollController _verticalScrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _table = widget.table.copy();
    _historyManager = ts.TableHistoryManager();
    _editFocus.addListener(_onEditFocusChanged);
  }

  @override
  void didUpdateWidget(TableEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.table != widget.table) {
      _table = widget.table.copy();
      _historyManager.clear();
    }
  }

  @override
  void dispose() {
    _editController.dispose();
    _editFocus.dispose();
    _horizontalScrollController.dispose();
    _verticalScrollController.dispose();
    super.dispose();
  }

  void _onEditFocusChanged() {
    if (!_editFocus.hasFocus) {
      _commitEdit();
    }
  }

  void _executeOperation(ts.TableOperation operation) {
    if (widget.onOperation != null) {
      widget.onOperation!(operation);
    } else {
      _historyManager.executeOperation(operation, _table);
    }
    _notifyTableChanged();
  }

  void _notifyTableChanged() {
    if (widget.onTableChanged != null) {
      widget.onTableChanged!(_table);
    }
    setState(() {});
  }

  void _startEditing(int row, int column) {
    if (widget.isReadOnly) return;

    _commitEdit(); // Commit any existing edit

    setState(() {
      _editingRow = row;
      _editingColumn = column;
      _selectedRow = row;
      _selectedColumn = column;
    });

    final cell = _table.getCellAt(row, column);
    _editController.text = cell?.content ?? '';
    _editController.selection = TextSelection(
      baseOffset: 0,
      extentOffset: _editController.text.length,
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _editFocus.requestFocus();
    });
  }

  void _commitEdit() {
    if (_editingRow == null || _editingColumn == null) return;

    final newContent = _editController.text;
    final cell = _table.getCellAt(_editingRow!, _editingColumn!);
    final oldContent = cell?.content ?? '';

    if (newContent != oldContent) {
      final operation = ts.SetCellContentOperation(
        _editingRow!,
        _editingColumn!,
        newContent,
        oldContent,
      );
      _executeOperation(operation);
    }

    setState(() {
      _editingRow = null;
      _editingColumn = null;
    });
  }

  void _selectCell(int row, int column) {
    setState(() {
      _selectedRow = row;
      _selectedColumn = column;
    });
  }

  void _startResize(int column, double startX) {
    setState(() {
      _resizingColumn = column;
      _resizeStartX = startX;
      _resizeStartWidth = _table.columns[column].width;
    });
  }

  void _updateResize(double currentX) {
    if (_resizingColumn == null) return;

    final delta = currentX - _resizeStartX;
    final newWidth = _resizeStartWidth + delta;

    setState(() {
      _table.resizeColumn(_resizingColumn!, newWidth);
    });
  }

  void _endResize() {
    if (_resizingColumn != null) {
      _notifyTableChanged();
      setState(() {
        _resizingColumn = null;
      });
    }
  }

  void _showContextMenu(BuildContext context, int? row, int? column, Offset position) {
    if (widget.isReadOnly) return;

    final items = <PopupMenuEntry<String>>[];

    if (row != null) {
      items.addAll([
        PopupMenuItem(value: 'insert_row_above', child: Text('Insert row above')),
        PopupMenuItem(value: 'insert_row_below', child: Text('Insert row below')),
        if (_table.rowCount > 1)
          PopupMenuItem(value: 'delete_row', child: Text('Delete row')),
        PopupMenuDivider(),
      ]);
    }

    if (column != null) {
      items.addAll([
        PopupMenuItem(value: 'insert_column_left', child: Text('Insert column left')),
        PopupMenuItem(value: 'insert_column_right', child: Text('Insert column right')),
        if (_table.columnCount > 1)
          PopupMenuItem(value: 'delete_column', child: Text('Delete column')),
        PopupMenuDivider(),
      ]);
    }

    items.addAll([
      PopupMenuItem(value: 'clear_table', child: Text('Clear table')),
    ]);

    showMenu<String>(
      context: context,
      position: RelativeRect.fromLTRB(
        position.dx,
        position.dy,
        position.dx + 1,
        position.dy + 1,
      ),
      items: items,
    ).then((value) => _handleContextMenuAction(value, row, column));
  }

  void _handleContextMenuAction(String? action, int? row, int? column) {
    if (action == null) return;

    switch (action) {
      case 'insert_row_above':
        if (row != null) {
          _executeOperation(ts.InsertRowOperation(row));
        }
        break;
      case 'insert_row_below':
        if (row != null) {
          _executeOperation(ts.InsertRowOperation(row + 1));
        }
        break;
      case 'delete_row':
        if (row != null) {
          final deletedRow = List<ts.TableCell>.from(_table.rows[row]);
          _executeOperation(ts.DeleteRowOperation(row, deletedRow));
        }
        break;
      case 'insert_column_left':
        if (column != null) {
          _executeOperation(ts.InsertColumnOperation(column));
        }
        break;
      case 'insert_column_right':
        if (column != null) {
          _executeOperation(ts.InsertColumnOperation(column + 1));
        }
        break;
      case 'delete_column':
        if (column != null) {
          final deletedColumn = _table.columns[column];
          final deletedCells = _table.rows.map((row) => row[column]).toList();
          _executeOperation(ts.DeleteColumnOperation(column, deletedColumn, deletedCells));
        }
        break;
      case 'clear_table':
        for (int i = 0; i < _table.rowCount; i++) {
          for (int j = 0; j < _table.columnCount; j++) {
            final cell = _table.getCellAt(i, j);
            if (cell != null && cell.content.isNotEmpty) {
              _executeOperation(ts.SetCellContentOperation(i, j, '', cell.content));
            }
          }
        }
        break;
    }
  }

  void _handleKeyPress(KeyEvent event) {
    if (event is! KeyDownEvent) return;

    if (event.logicalKey == LogicalKeyboardKey.tab) {
      final pressed = HardwareKeyboard.instance.logicalKeysPressed;
      final isShift = pressed.contains(LogicalKeyboardKey.shiftLeft) || pressed.contains(LogicalKeyboardKey.shiftRight);
      _navigateWithTab(isShift);
      return;
    }

    if (_selectedRow == null || _selectedColumn == null) return;

    switch (event.logicalKey) {
      case LogicalKeyboardKey.arrowUp:
        _navigateVertical(-1);
        break;
      case LogicalKeyboardKey.arrowDown:
        _navigateVertical(1);
        break;
      case LogicalKeyboardKey.arrowLeft:
        _navigateHorizontal(-1);
        break;
      case LogicalKeyboardKey.arrowRight:
        _navigateHorizontal(1);
        break;
      case LogicalKeyboardKey.enter:
        _startEditing(_selectedRow!, _selectedColumn!);
        break;
      case LogicalKeyboardKey.escape:
        if (_editingRow != null) {
          setState(() {
            _editingRow = null;
            _editingColumn = null;
          });
        }
        break;
    }
  }

  void _navigateWithTab(bool reverse) {
    if (_selectedRow == null || _selectedColumn == null) return;

    _commitEdit();

    int newRow = _selectedRow!;
    int newColumn = _selectedColumn!;

    if (reverse) {
      newColumn--;
      if (newColumn < 0) {
        newColumn = _table.columnCount - 1;
        newRow--;
        if (newRow < 0) {
          newRow = _table.rowCount - 1;
        }
      }
    } else {
      newColumn++;
      if (newColumn >= _table.columnCount) {
        newColumn = 0;
        newRow++;
        if (newRow >= _table.rowCount) {
          newRow = 0;
        }
      }
    }

    _selectCell(newRow, newColumn);
  }

  void _navigateVertical(int direction) {
    if (_selectedRow == null) return;
    _commitEdit();

    final newRow = (_selectedRow! + direction).clamp(0, _table.rowCount - 1);
    _selectCell(newRow, _selectedColumn ?? 0);
  }

  void _navigateHorizontal(int direction) {
    if (_selectedColumn == null) return;
    _commitEdit();

    final newColumn = (_selectedColumn! + direction).clamp(0, _table.columnCount - 1);
    _selectCell(_selectedRow ?? 0, newColumn);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Focus(
      onKeyEvent: (node, event) {
        _handleKeyPress(event);
        return KeyEventResult.handled;
      },
      child: Container(
        constraints: BoxConstraints(
          maxWidth: widget.maxWidth,
          maxHeight: widget.maxHeight,
        ),
        decoration: BoxDecoration(
          border: Border.all(color: theme.dividerColor),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Scrollbar(
          controller: _horizontalScrollController,
          child: Scrollbar(
            controller: _verticalScrollController,
            child: SingleChildScrollView(
              controller: _horizontalScrollController,
              scrollDirection: Axis.horizontal,
              child: SingleChildScrollView(
                controller: _verticalScrollController,
                child: _buildTable(theme),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTable(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildHeaderRow(theme),
        ..._table.rows.asMap().entries.map((entry) =>
          _buildDataRow(theme, entry.key, entry.value)
        ),
      ],
    );
  }

  Widget _buildHeaderRow(ThemeData theme) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Row number cell
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest,
            border: Border.all(color: theme.dividerColor),
          ),
          child: Center(
            child: Text(
              '#',
              style: theme.textTheme.labelSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        // Header cells
        ..._table.columns.asMap().entries.map((entry) =>
          _buildHeaderCell(theme, entry.key, entry.value)
        ),
      ],
    );
  }

  Widget _buildHeaderCell(ThemeData theme, int columnIndex, ts.TableColumn column) {
    final isSelected = _selectedColumn == columnIndex;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: () => _selectCell(-1, columnIndex),
          onSecondaryTapUp: (details) => _showContextMenu(
            context,
            null,
            columnIndex,
            details.globalPosition,
          ),
          child: Container(
            width: column.width,
            height: 40,
            decoration: BoxDecoration(
              color: isSelected
                ? theme.colorScheme.primaryContainer.withValues(alpha: 0.5)
                : theme.colorScheme.surfaceContainerHighest,
              border: Border.all(
                color: isSelected
                  ? theme.colorScheme.primary
                  : theme.dividerColor,
                width: isSelected ? 2 : 1,
              ),
            ),
            child: Center(
              child: Text(
                column.header,
                style: theme.textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
        ),
        _buildResizeHandle(theme, columnIndex),
      ],
    );
  }

  Widget _buildDataRow(ThemeData theme, int rowIndex, List<ts.TableCell> rowCells) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Row number cell
        GestureDetector(
          onTap: () => _selectCell(rowIndex, -1),
          onSecondaryTapUp: (details) => _showContextMenu(
            context,
            rowIndex,
            null,
            details.globalPosition,
          ),
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: _selectedRow == rowIndex
                ? theme.colorScheme.primaryContainer.withValues(alpha: 0.5)
                : theme.colorScheme.surfaceContainerHighest,
              border: Border.all(
                color: _selectedRow == rowIndex
                  ? theme.colorScheme.primary
                  : theme.dividerColor,
                width: _selectedRow == rowIndex ? 2 : 1,
              ),
            ),
            child: Center(
              child: Text(
                '${rowIndex + 1}',
                style: theme.textTheme.labelSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ),
        // Data cells
        ...rowCells.asMap().entries.map((entry) =>
          _buildDataCell(theme, rowIndex, entry.key, entry.value)
        ),
      ],
    );
  }

  Widget _buildDataCell(ThemeData theme, int rowIndex, int columnIndex, ts.TableCell cell) {
    final isSelected = _selectedRow == rowIndex && _selectedColumn == columnIndex;
    final isEditing = _editingRow == rowIndex && _editingColumn == columnIndex;
    final column = _table.columns[columnIndex];

    Widget content;

    if (isEditing) {
      content = TextField(
        controller: _editController,
        focusNode: _editFocus,
        decoration: InputDecoration(
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          isDense: true,
        ),
        style: theme.textTheme.bodySmall,
        textAlign: _getTextAlign(column.alignment),
        onSubmitted: (_) {
          _commitEdit();
          _navigateVertical(1);
        },
      );
    } else {
      content = GestureDetector(
        onTap: () => _selectCell(rowIndex, columnIndex),
        onDoubleTap: () => _startEditing(rowIndex, columnIndex),
        onSecondaryTapUp: (details) => _showContextMenu(
          context,
          rowIndex,
          columnIndex,
          details.globalPosition,
        ),
        child: Container(
          width: column.width,
          height: 40,
          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: isSelected
              ? theme.colorScheme.primaryContainer.withValues(alpha: 0.3)
              : theme.colorScheme.surface,
            border: Border.all(
              color: isSelected
                ? theme.colorScheme.primary
                : theme.dividerColor,
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Align(
            alignment: _getAlignment(column.alignment),
            child: Text(
              cell.content,
              style: theme.textTheme.bodySmall,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        content,
        if (columnIndex < _table.columnCount - 1)
          _buildResizeHandle(theme, columnIndex),
      ],
    );
  }

  Widget _buildResizeHandle(ThemeData theme, int columnIndex) {
    return GestureDetector(
      onPanStart: (details) => _startResize(columnIndex, details.globalPosition.dx),
      onPanUpdate: (details) => _updateResize(details.globalPosition.dx),
      onPanEnd: (_) => _endResize(),
      child: MouseRegion(
        cursor: SystemMouseCursors.resizeColumn,
        child: Container(
          width: 8,
          height: 40,
          decoration: BoxDecoration(
            color: _resizingColumn == columnIndex
              ? theme.colorScheme.primary.withValues(alpha: 0.3)
              : Colors.transparent,
          ),
          child: Center(
            child: Container(
              width: 2,
              height: 20,
              color: theme.dividerColor,
            ),
          ),
        ),
      ),
    );
  }

  TextAlign _getTextAlign(ts.TableAlignment alignment) {
    switch (alignment) {
      case ts.TableAlignment.center:
        return TextAlign.center;
      case ts.TableAlignment.right:
        return TextAlign.right;
      case ts.TableAlignment.left:
      default:
        return TextAlign.left;
    }
  }

  Alignment _getAlignment(ts.TableAlignment alignment) {
    switch (alignment) {
      case ts.TableAlignment.center:
        return Alignment.center;
      case ts.TableAlignment.right:
        return Alignment.centerRight;
      case ts.TableAlignment.left:
      default:
        return Alignment.centerLeft;
    }
  }
}

/// Simplified table editor for mobile devices
class MobileTableEditor extends StatefulWidget {
  final ts.TableData table;
  final TableChangeCallback? onTableChanged;
  final bool isReadOnly;

  const MobileTableEditor({
    super.key,
    required this.table,
    this.onTableChanged,
    this.isReadOnly = false,
  });

  @override
  State<MobileTableEditor> createState() => _MobileTableEditorState();
}

class _MobileTableEditorState extends State<MobileTableEditor> {
  late ts.TableData _table;
  final PageController _pageController = PageController();
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _table = widget.table.copy();
  }

  @override
  void didUpdateWidget(MobileTableEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.table != widget.table) {
      _table = widget.table.copy();
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _notifyTableChanged() {
    if (widget.onTableChanged != null) {
      widget.onTableChanged!(_table);
    }
    setState(() {});
  }

  void _editCell(int row, int column) async {
    if (widget.isReadOnly) return;

    final cell = _table.getCellAt(row, column);
    final initialText = cell?.content ?? '';

    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Edit Cell'),
        content: TextField(
          autofocus: true,
          controller: TextEditingController(text: initialText),
          decoration: InputDecoration(
            hintText: 'Enter cell content...',
          ),
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(
              (context.findAncestorWidgetOfExactType<AlertDialog>()
                as AlertDialog).content?.runtimeType == TextField
                ? (((context.findAncestorWidgetOfExactType<AlertDialog>()
                  as AlertDialog).content as TextField).controller?.text ?? '')
                : initialText),
            child: Text('Save'),
          ),
        ],
      ),
    );

    if (result != null && result != initialText) {
      _table.setCellAt(row, column, result);
      _notifyTableChanged();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      children: [
        // Column navigation
        if (_table.columnCount > 1)
          Container(
            height: 50,
            child: PageView.builder(
              controller: _pageController,
              onPageChanged: (index) => setState(() => _currentPage = index),
              itemCount: _table.columnCount,
              itemBuilder: (context, index) => Center(
                child: Text(
                  _table.columns[index].header,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),

        // Page indicator
        if (_table.columnCount > 1)
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              _table.columnCount,
              (index) => Container(
                width: 8,
                height: 8,
                margin: EdgeInsets.symmetric(horizontal: 2),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: index == _currentPage
                    ? theme.colorScheme.primary
                    : theme.colorScheme.outline,
                ),
              ),
            ),
          ),

        SizedBox(height: 16),

        // Table content
        Expanded(
          child: ListView.builder(
            itemCount: _table.rowCount,
            itemBuilder: (context, rowIndex) => Card(
              margin: EdgeInsets.symmetric(vertical: 4, horizontal: 16),
              child: ListTile(
                title: Text('Row ${rowIndex + 1}'),
                subtitle: Text(
                  _table.getCellAt(rowIndex, _currentPage)?.content ?? '',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                onTap: () => _editCell(rowIndex, _currentPage),
                trailing: widget.isReadOnly ? null : Icon(Icons.edit),
              ),
            ),
          ),
        ),
      ],
    );
  }
}