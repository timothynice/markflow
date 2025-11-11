import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:markdown/markdown.dart' as md;

/// Custom renderer for task list items with interactive checkboxes
class TaskListRenderer extends MarkdownElementBuilder {
  final Function(String taskId, bool checked)? onTaskToggle;
  final bool enableInteraction;

  TaskListRenderer({
    this.onTaskToggle,
    this.enableInteraction = true,
  });

  @override
  Widget? visitElementAfter(md.Element element, TextStyle? preferredStyle) {
    // Handle task list containers
    if (element.tag == 'ul' &&
        element.attributes['class']?.contains('task-list') == true) {
      return _buildTaskList(element, preferredStyle);
    }

    // Handle individual task list items
    if (element.tag == 'li' &&
        element.attributes['class']?.contains('task-list-item') == true) {
      return _buildTaskListItem(element, preferredStyle);
    }

    return null;
  }

  Widget _buildTaskList(md.Element element, TextStyle? preferredStyle) {
    final children = <Widget>[];

    for (final child in element.children ?? <md.Node>[]) {
      if (child is md.Element && child.tag == 'li') {
        final widget = visitElementAfter(child, preferredStyle);
        if (widget != null) {
          children.add(widget);
        }
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: children,
    );
  }

  Widget _buildTaskListItem(md.Element element, TextStyle? preferredStyle) {
    final isChecked = element.attributes['data-checked'] == 'true';
    final content = element.textContent.trim();
    final taskId = element.hashCode.toString(); // Generate unique ID

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Checkbox
          SizedBox(
            width: 24,
            height: 24,
            child: enableInteraction
                ? Checkbox(
                    value: isChecked,
                    onChanged: (value) {
                      if (onTaskToggle != null && value != null) {
                        onTaskToggle!(taskId, value);
                      }
                    },
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    visualDensity: VisualDensity.compact,
                  )
                : IgnorePointer(
                    child: Checkbox(
                      value: isChecked,
                      onChanged: null,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      visualDensity: VisualDensity.compact,
                    ),
                  ),
          ),
          const SizedBox(width: 8),
          // Content
          Expanded(
            child: Text(
              content,
              style: preferredStyle?.copyWith(
                decoration: isChecked ? TextDecoration.lineThrough : null,
                color: isChecked
                    ? preferredStyle.color?.withValues(alpha: 0.6)
                    : preferredStyle.color,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Progress indicator for task lists
class TaskListProgress extends StatelessWidget {
  final List<bool> taskStates;
  final TextStyle? style;

  const TaskListProgress({
    super.key,
    required this.taskStates,
    this.style,
  });

  @override
  Widget build(BuildContext context) {
    if (taskStates.isEmpty) return const SizedBox.shrink();

    final completed = taskStates.where((state) => state).length;
    final total = taskStates.length;
    final percentage = (completed / total * 100).round();

    final theme = Theme.of(context);
    final textStyle = style ?? theme.textTheme.bodySmall;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: LinearProgressIndicator(
                  value: completed / total,
                  backgroundColor: theme.colorScheme.surfaceVariant,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    completed == total
                        ? Colors.green
                        : theme.colorScheme.primary,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '$completed/$total ($percentage%)',
                style: textStyle?.copyWith(
                  fontWeight: FontWeight.w500,
                  color: completed == total
                      ? Colors.green
                      : theme.colorScheme.onSurface,
                ),
              ),
            ],
          ),
          if (completed == total)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Row(
                children: [
                  Icon(
                    Icons.check_circle,
                    size: 16,
                    color: Colors.green,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'All tasks completed!',
                    style: textStyle?.copyWith(
                      color: Colors.green,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}