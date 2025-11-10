import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../services/table_service.dart';

/// Dialog for creating new tables with customizable dimensions and properties
class TableCreationDialog extends StatefulWidget {
  final int initialRows;
  final int initialColumns;

  const TableCreationDialog({
    super.key,
    this.initialRows = 3,
    this.initialColumns = 3,
  });

  /// Show the table creation dialog and return the created table data
  static Future<TableData?> show(
    BuildContext context, {
    int initialRows = 3,
    int initialColumns = 3,
  }) {
    return showDialog<TableData>(
      context: context,
      barrierDismissible: false,
      builder: (context) => TableCreationDialog(
        initialRows: initialRows,
        initialColumns: initialColumns,
      ),
    );
  }

  @override
  State<TableCreationDialog> createState() => _TableCreationDialogState();
}

class _TableCreationDialogState extends State<TableCreationDialog> {
  late int _rows;
  late int _columns;
  final List<TextEditingController> _headerControllers = [];
  final List<FocusNode> _headerFocusNodes = [];
  bool _includeHeaders = true;
  TableAlignment _defaultAlignment = TableAlignment.left;

  // Validation
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _rows = widget.initialRows.clamp(1, 20);
    _columns = widget.initialColumns.clamp(1, 10);
    _initializeHeaders();
  }

  @override
  void dispose() {
    for (final controller in _headerControllers) {
      controller.dispose();
    }
    for (final focusNode in _headerFocusNodes) {
      focusNode.dispose();
    }
    super.dispose();
  }

  void _initializeHeaders() {
    // Clear existing controllers and focus nodes
    for (final controller in _headerControllers) {
      controller.dispose();
    }
    for (final focusNode in _headerFocusNodes) {
      focusNode.dispose();
    }
    _headerControllers.clear();
    _headerFocusNodes.clear();

    // Create new controllers and focus nodes
    for (int i = 0; i < _columns; i++) {
      final controller = TextEditingController(
        text: 'Column ${String.fromCharCode(65 + i)}',
      );
      final focusNode = FocusNode();

      _headerControllers.add(controller);
      _headerFocusNodes.add(focusNode);
    }
  }

  void _updateColumns(int newColumns) {
    if (newColumns == _columns) return;

    setState(() {
      _columns = newColumns.clamp(1, 10);
      _initializeHeaders();
    });
  }

  void _createTable() {
    if (!_formKey.currentState!.validate()) return;

    // Create columns with headers and alignment
    final columns = <TableColumn>[];
    for (int i = 0; i < _columns; i++) {
      final header = _includeHeaders
        ? _headerControllers[i].text.trim()
        : 'Column ${String.fromCharCode(65 + i)}';

      columns.add(TableColumn(
        header: header.isEmpty ? 'Column ${String.fromCharCode(65 + i)}' : header,
        alignment: _defaultAlignment,
      ));
    }

    // Create rows
    final rows = <List<TableCell>>[];
    for (int i = 0; i < _rows; i++) {
      final row = <TableCell>[];
      for (int j = 0; j < _columns; j++) {
        row.add(TableCell());
      }
      rows.add(row);
    }

    final table = TableData(columns: columns, rows: rows);
    Navigator.of(context).pop(table);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final size = MediaQuery.of(context).size;
    final isMobile = size.width < 600;

    return AlertDialog(
      title: Row(
        children: [
          Icon(LucideIcons.table, size: 24),
          SizedBox(width: 8),
          Text('Create Table'),
        ],
      ),
      content: Container(
        width: isMobile ? size.width * 0.9 : 500,
        constraints: BoxConstraints(
          maxHeight: size.height * 0.8,
        ),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Dimensions section
                _buildSectionHeader('Dimensions'),
                SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(child: _buildDimensionInput('Rows', _rows, (value) {
                      setState(() => _rows = value.clamp(1, 20));
                    })),
                    SizedBox(width: 16),
                    Expanded(child: _buildDimensionInput('Columns', _columns, _updateColumns)),
                  ],
                ),

                SizedBox(height: 24),

                // Headers section
                _buildSectionHeader('Headers'),
                SizedBox(height: 8),
                SwitchListTile(
                  title: Text('Include header row'),
                  subtitle: Text('Add a header row to the table'),
                  value: _includeHeaders,
                  onChanged: (value) => setState(() => _includeHeaders = value),
                  contentPadding: EdgeInsets.zero,
                ),

                if (_includeHeaders) ...[
                  SizedBox(height: 16),
                  Text(
                    'Header names:',
                    style: theme.textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: 8),
                  _buildHeaderInputs(),
                ],

                SizedBox(height: 24),

                // Alignment section
                _buildSectionHeader('Default Alignment'),
                SizedBox(height: 8),
                _buildAlignmentSelector(),

                SizedBox(height: 24),

                // Preview section
                _buildSectionHeader('Preview'),
                SizedBox(height: 8),
                _buildPreview(),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text('Cancel'),
        ),
        FilledButton(
          onPressed: _createTable,
          child: Text('Create Table'),
        ),
      ],
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleSmall?.copyWith(
        fontWeight: FontWeight.bold,
        color: Theme.of(context).colorScheme.primary,
      ),
    );
  }

  Widget _buildDimensionInput(String label, int value, void Function(int) onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.labelMedium),
        SizedBox(height: 4),
        TextFormField(
          initialValue: value.toString(),
          keyboardType: TextInputType.number,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(2),
          ],
          decoration: InputDecoration(
            border: OutlineInputBorder(),
            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            isDense: true,
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Required';
            }
            final intValue = int.tryParse(value);
            if (intValue == null) {
              return 'Invalid number';
            }
            final min = label == 'Rows' ? 1 : 1;
            final max = label == 'Rows' ? 20 : 10;
            if (intValue < min || intValue > max) {
              return '$min-$max';
            }
            return null;
          },
          onChanged: (value) {
            final intValue = int.tryParse(value);
            if (intValue != null) {
              onChanged(intValue);
            }
          },
        ),
      ],
    );
  }

  Widget _buildHeaderInputs() {
    return Column(
      children: List.generate(_columns, (index) {
        return Padding(
          padding: EdgeInsets.only(bottom: 8),
          child: TextFormField(
            controller: _headerControllers[index],
            focusNode: _headerFocusNodes[index],
            decoration: InputDecoration(
              labelText: 'Header ${index + 1}',
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              isDense: true,
            ),
            textInputAction: index < _columns - 1
              ? TextInputAction.next
              : TextInputAction.done,
            onFieldSubmitted: (_) {
              if (index < _columns - 1) {
                _headerFocusNodes[index + 1].requestFocus();
              }
            },
            validator: (value) {
              if (_includeHeaders && (value == null || value.trim().isEmpty)) {
                return 'Header name required';
              }
              return null;
            },
          ),
        );
      }),
    );
  }

  Widget _buildAlignmentSelector() {
    return Wrap(
      spacing: 8,
      children: [
        _buildAlignmentChip('Left', TableAlignment.left, LucideIcons.alignLeft),
        _buildAlignmentChip('Center', TableAlignment.center, LucideIcons.alignCenter),
        _buildAlignmentChip('Right', TableAlignment.right, LucideIcons.alignRight),
      ],
    );
  }

  Widget _buildAlignmentChip(String label, TableAlignment alignment, IconData icon) {
    final isSelected = _defaultAlignment == alignment;
    final theme = Theme.of(context);

    return FilterChip(
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16),
          SizedBox(width: 4),
          Text(label),
        ],
      ),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) {
          setState(() => _defaultAlignment = alignment);
        }
      },
      selectedColor: theme.colorScheme.primaryContainer,
      checkmarkColor: theme.colorScheme.primary,
    );
  }

  Widget _buildPreview() {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: theme.dividerColor),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          // Header row
          if (_includeHeaders)
            Container(
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(7),
                  topRight: Radius.circular(7),
                ),
              ),
              child: Row(
                children: List.generate(_columns, (index) {
                  final header = _headerControllers.length > index
                    ? _headerControllers[index].text.trim()
                    : '';
                  return Expanded(
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                      decoration: BoxDecoration(
                        border: index < _columns - 1
                          ? Border(right: BorderSide(color: theme.dividerColor))
                          : null,
                      ),
                      child: Text(
                        header.isEmpty ? 'Column ${String.fromCharCode(65 + index)}' : header,
                        style: theme.textTheme.labelMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: _getTextAlign(_defaultAlignment),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  );
                }),
              ),
            ),

          // Data rows preview
          ...List.generate(min(_rows, 3), (rowIndex) {
            return Container(
              decoration: BoxDecoration(
                border: Border(
                  top: rowIndex > 0 || _includeHeaders
                    ? BorderSide(color: theme.dividerColor)
                    : BorderSide.none,
                ),
              ),
              child: Row(
                children: List.generate(_columns, (colIndex) {
                  return Expanded(
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                      decoration: BoxDecoration(
                        border: colIndex < _columns - 1
                          ? Border(right: BorderSide(color: theme.dividerColor))
                          : null,
                      ),
                      child: Text(
                        '', // Empty cell for preview
                        style: theme.textTheme.bodySmall,
                        textAlign: _getTextAlign(_defaultAlignment),
                      ),
                    ),
                  );
                }),
              ),
            );
          }),

          // Show indicator if there are more rows
          if (_rows > 3)
            Container(
              padding: EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                border: Border(top: BorderSide(color: theme.dividerColor)),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(7),
                  bottomRight: Radius.circular(7),
                ),
              ),
              child: Center(
                child: Text(
                  '... and ${_rows - 3} more rows',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  TextAlign _getTextAlign(TableAlignment alignment) {
    switch (alignment) {
      case TableAlignment.center:
        return TextAlign.center;
      case TableAlignment.right:
        return TextAlign.right;
      case TableAlignment.left:
      default:
        return TextAlign.left;
    }
  }
}

/// Quick table creation buttons for common table sizes
class QuickTableButtons extends StatelessWidget {
  final void Function(TableData) onTableCreated;

  const QuickTableButtons({
    super.key,
    required this.onTableCreated,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _buildQuickButton(context, '2×2', 2, 2),
        _buildQuickButton(context, '3×3', 3, 3),
        _buildQuickButton(context, '4×3', 3, 4),
        _buildQuickButton(context, '5×4', 4, 5),
        _buildCustomButton(context),
      ],
    );
  }

  Widget _buildQuickButton(BuildContext context, String label, int rows, int columns) {
    return OutlinedButton(
      onPressed: () {
        final table = TableData.create(rows, columns);
        onTableCreated(table);
      },
      child: Text(label),
    );
  }

  Widget _buildCustomButton(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: () async {
        final table = await TableCreationDialog.show(context);
        if (table != null) {
          onTableCreated(table);
        }
      },
      icon: Icon(Icons.more_horiz, size: 16),
      label: Text('Custom'),
    );
  }
}