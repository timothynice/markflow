import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

typedef InsertFormatter = void Function(String before, [String after]);
typedef SimpleAction = void Function();

class FormattingToolbar extends StatelessWidget {
  final InsertFormatter onWrapSelection;
  final SimpleAction onHeading1;
  final SimpleAction onHeading2;
  final SimpleAction onHeading3;
  final SimpleAction onLink;
  final SimpleAction onBulletedList;
  final SimpleAction onNumberedList;
  final SimpleAction onTable;
  final SimpleAction onImage;

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
    required this.onImage,
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
            _iconButton(context, LucideIcons.image, 'Image', onImage),
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

  Widget _divider(BuildContext context) => Container(
        width: 1,
        height: 20,
        margin: const EdgeInsets.symmetric(horizontal: 6),
        color: Theme.of(context).dividerColor.withValues(alpha: 0.2),
      );
}
