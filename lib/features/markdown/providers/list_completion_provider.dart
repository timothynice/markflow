import 'package:flutter/material.dart';
import '../models/completion_suggestion.dart';
import 'completion_provider.dart';

/// Provider for markdown list completions
class ListCompletionProvider extends CompletionProvider with TriggerBasedProvider, LineStartProvider {
  @override
  String get name => 'List Completion';

  @override
  Set<String> get triggerCharacters => {'-', '*', '+'};

  @override
  int get priority => 8;

  @override
  Future<List<CompletionSuggestion>> getSuggestions(CompletionContext context) async {
    final suggestions = <CompletionSuggestion>[];

    if (!_isValidListPosition(context)) {
      return suggestions;
    }

    // Basic list items
    final listMarkers = [
      ('-', 'Bullet list item'),
      ('*', 'Bullet list item (asterisk)'),
      ('+', 'Bullet list item (plus)'),
      ('1.', 'Numbered list item'),
    ];

    for (final (marker, description) in listMarkers) {
      suggestions.add(CompletionSuggestion(
        insertText: '$marker ',
        displayText: '$marker List item',
        description: description,
        type: CompletionType.list,
        icon: Icons.format_list_bulleted,
        trigger: context.triggerCharacter,
        priority: 8,
        cursorOffset: 0,
      ));
    }

    // Task list items
    suggestions.addAll([
      CompletionSuggestion(
        insertText: '- [ ] ',
        displayText: '- [ ] Task list item',
        description: 'Unchecked task item',
        type: CompletionType.list,
        icon: Icons.check_box_outline_blank,
        trigger: context.triggerCharacter,
        priority: 7,
        cursorOffset: 0,
      ),
      CompletionSuggestion(
        insertText: '- [x] ',
        displayText: '- [x] Completed task',
        description: 'Checked task item',
        type: CompletionType.list,
        icon: Icons.check_box,
        trigger: context.triggerCharacter,
        priority: 6,
        cursorOffset: 0,
      ),
    ]);

    // Nested list items
    final currentIndent = _getCurrentIndentLevel(context);
    final nextIndent = '  ' * (currentIndent + 1);

    suggestions.addAll([
      CompletionSuggestion(
        insertText: '$nextIndent- ',
        displayText: '  - Nested list item',
        description: 'Indented bullet list item',
        type: CompletionType.list,
        icon: Icons.format_indent_increase,
        trigger: context.triggerCharacter,
        priority: 5,
        cursorOffset: 0,
      ),
      CompletionSuggestion(
        insertText: '$nextIndent1. ',
        displayText: '  1. Nested numbered item',
        description: 'Indented numbered list item',
        type: CompletionType.list,
        icon: Icons.format_list_numbered,
        trigger: context.triggerCharacter,
        priority: 5,
        cursorOffset: 0,
      ),
    ]);

    // Common list templates
    final templates = [
      ('- **Bold item**: Description', 'Bold list item with description'),
      ('- *Italic item*: Details', 'Italic list item with details'),
      ('- `Code item`: Implementation', 'Code list item'),
      ('1. First step', 'Numbered step'),
      ('2. Second step', 'Next numbered step'),
      ('- Item 1\n- Item 2\n- Item 3', 'Quick list template'),
    ];

    for (final (template, description) in templates) {
      suggestions.add(CompletionSuggestion(
        insertText: template,
        displayText: template.split('\n').first,
        description: description,
        type: CompletionType.list,
        icon: Icons.list,
        trigger: context.triggerCharacter,
        priority: 4,
        isSnippet: template.contains('\n'),
      ));
    }

    return suggestions;
  }

  @override
  bool shouldActivate(CompletionContext context) {
    return super.shouldActivate(context) && _isValidListPosition(context);
  }

  bool _isValidListPosition(CompletionContext context) {
    // Lists should be at line start or after whitespace
    final beforeCursor = context.textBeforeCursor;
    if (beforeCursor.isEmpty) return true;

    final lastNewline = beforeCursor.lastIndexOf('\n');
    final currentLineStart = lastNewline + 1;
    final linePrefix = beforeCursor.substring(currentLineStart, context.cursorPosition);

    // Allow if only whitespace and list markers before cursor
    return RegExp(r'^[\s\-*+]*$').hasMatch(linePrefix);
  }

  int _getCurrentIndentLevel(CompletionContext context) {
    final lines = context.textBeforeCursor.split('\n');
    if (lines.isEmpty) return 0;

    // Look backwards for the nearest list item to determine indent
    for (int i = lines.length - 1; i >= 0; i--) {
      final line = lines[i];
      final match = RegExp(r'^(\s*)[-*+]').firstMatch(line);
      if (match != null) {
        return match.group(1)!.length ~/ 2; // Assuming 2 spaces per indent
      }
    }

    return 0;
  }
}