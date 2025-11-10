import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../services/table_service.dart';
import 'table_creation_dialog.dart';

typedef InsertFormatter = void Function(String before, [String after]);
typedef SimpleAction = void Function();
typedef TableInsertCallback = void Function(TableData table);

class FormattingToolbar extends StatelessWidget {
  final InsertFormatter onWrapSelection;
  final SimpleAction onHeading1;
  final SimpleAction onHeading2;
  final SimpleAction onHeading3;
  final SimpleAction onLink;
  final SimpleAction onBulletedList;
  final SimpleAction onNumberedList;
  final SimpleAction onTable;
  final TableInsertCallback? onTableInsert;
  final SimpleAction onImage;

  // Extension actions
  final SimpleAction? onTaskList;
  final SimpleAction? onFootnote;
  final SimpleAction? onDefinitionList;
  final SimpleAction? onHighlight;
  final SimpleAction? onStrikethrough;

  const FormattingToolbar({
    super.key,
    required this.onWrapSelection,
    required this.onHeading1,
    required this.onHeading2,
    required this.onHeading3,
    required this.onLink,
    required this.onBulletedList,
    required this.onNumberedList,
    required this.onTable,
    this.onTableInsert,
    required this.onImage,
    this.onTaskList,
    this.onFootnote,
    this.onDefinitionList,
    this.onHighlight,
    this.onStrikethrough,
  });

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isCompact = width < 720;
    return Container(
      height: 44,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).dividerColor.withValues(alpha: 0.1),
            width: 1,
          ),
        ),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            const SizedBox(width: 8),
            _iconButton(context, LucideIcons.bold, 'Bold', () => onWrapSelection('**', '**')),
            _iconButton(context, LucideIcons.italic, 'Italic', () => onWrapSelection('*', '*')),
            _iconButton(context, LucideIcons.heading1, 'H1', onHeading1),
            _iconButton(context, LucideIcons.heading2, 'H2', onHeading2),
            _iconButton(context, LucideIcons.heading3, 'H3', onHeading3),
            _divider(context),
            _iconButton(context, LucideIcons.list, 'Bulleted list', onBulletedList),
            _iconButton(context, LucideIcons.listOrdered, 'Numbered list', onNumberedList),
            if (onTaskList != null)
              _iconButton(context, LucideIcons.checkSquare, 'Task list', onTaskList!),
            _tableButton(context),
            _divider(context),
            _iconButton(context, LucideIcons.image, 'Image', onImage),
            if (onFootnote != null)
              _iconButton(context, LucideIcons.footprints, 'Footnote', onFootnote!),
            if (onDefinitionList != null)
              _iconButton(context, LucideIcons.bookOpen, 'Definition list', onDefinitionList!),
            _extensionsButton(context),
            const SizedBox(width: 8),
          ],
        ),
      ),
    );
  }

  Widget _iconButton(
      BuildContext context, IconData icon, String tooltip, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Tooltip(
        message: tooltip,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(6),
          child: Container(
            padding: const EdgeInsets.all(8),
            child: Icon(icon, size: 18, color: Theme.of(context).iconTheme.color),
          ),
        ),
      ),
    );
  }

  Widget _tableButton(BuildContext context) {
    return PopupMenuButton<String>(
      tooltip: 'Insert Table',
      child: Container(
        padding: const EdgeInsets.all(8),
        child: Icon(LucideIcons.table, size: 18, color: Theme.of(context).iconTheme.color),
      ),
      onSelected: (value) async {
        switch (value) {
          case 'quick_2x2':
            _insertQuickTable(2, 2);
            break;
          case 'quick_3x3':
            _insertQuickTable(3, 3);
            break;
          case 'quick_4x3':
            _insertQuickTable(3, 4);
            break;
          case 'quick_5x4':
            _insertQuickTable(4, 5);
            break;
          case 'custom':
            final table = await TableCreationDialog.show(context);
            if (table != null) {
              if (onTableInsert != null) {
                onTableInsert!(table);
              } else {
                _insertTableMarkdown(table);
              }
            }
            break;
          case 'simple':
            onTable();
            break;
        }
      },
      itemBuilder: (context) => [
        PopupMenuItem(
          value: 'quick_2x2',
          child: Row(
            children: [
              Icon(LucideIcons.table, size: 16),
              SizedBox(width: 8),
              Text('2×2 Table'),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'quick_3x3',
          child: Row(
            children: [
              Icon(LucideIcons.table, size: 16),
              SizedBox(width: 8),
              Text('3×3 Table'),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'quick_4x3',
          child: Row(
            children: [
              Icon(LucideIcons.table, size: 16),
              SizedBox(width: 8),
              Text('4×3 Table'),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'quick_5x4',
          child: Row(
            children: [
              Icon(LucideIcons.table, size: 16),
              SizedBox(width: 8),
              Text('5×4 Table'),
            ],
          ),
        ),
        PopupMenuDivider(),
        PopupMenuItem(
          value: 'custom',
          child: Row(
            children: [
              Icon(LucideIcons.settings, size: 16),
              SizedBox(width: 8),
              Text('Custom Table...'),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'simple',
          child: Row(
            children: [
              Icon(LucideIcons.edit, size: 16),
              SizedBox(width: 8),
              Text('Simple Markdown'),
            ],
          ),
        ),
      ],
    );
  }

  void _insertQuickTable(int rows, int columns) {
    final table = TableData.create(rows, columns);
    if (onTableInsert != null) {
      onTableInsert!(table);
    } else {
      _insertTableMarkdown(table);
    }
  }

  void _insertTableMarkdown(TableData table) {
    final markdown = TableService.tableToMarkdown(table);
    onWrapSelection(markdown, '');
  }

  Widget _extensionsButton(BuildContext context) {
    return PopupMenuButton<String>(
      tooltip: 'Text Extensions',
      child: Container(
        padding: const EdgeInsets.all(8),
        child: Icon(LucideIcons.type, size: 18, color: Theme.of(context).iconTheme.color),
      ),
      onSelected: (value) {
        switch (value) {
          case 'strikethrough':
            onWrapSelection('~~', '~~');
            break;
          case 'highlight':
            if (onHighlight != null) {
              onHighlight!();
            } else {
              onWrapSelection('==', '==');
            }
            break;
          case 'subscript':
            onWrapSelection('~', '~');
            break;
          case 'superscript':
            onWrapSelection('^', '^');
            break;
        }
      },
      itemBuilder: (context) => [
        if (onStrikethrough != null)
          PopupMenuItem(
            value: 'strikethrough',
            child: Row(
              children: [
                Icon(LucideIcons.strikethrough, size: 16),
                SizedBox(width: 8),
                Text('Strikethrough'),
              ],
            ),
          ),
        PopupMenuItem(
          value: 'highlight',
          child: Row(
            children: [
              Icon(LucideIcons.highlighter, size: 16),
              SizedBox(width: 8),
              Text('Highlight'),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'subscript',
          child: Row(
            children: [
              Icon(LucideIcons.subscript, size: 16),
              SizedBox(width: 8),
              Text('Subscript'),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'superscript',
          child: Row(
            children: [
              Icon(LucideIcons.superscript, size: 16),
              SizedBox(width: 8),
              Text('Superscript'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _divider(BuildContext context) => Container(
        width: 1,
        height: 20,
        margin: const EdgeInsets.symmetric(horizontal: 6),
        color: Theme.of(context).dividerColor.withValues(alpha: 0.2),
      );
}
