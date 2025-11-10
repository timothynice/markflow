import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../models/completion_suggestion.dart';
import 'completion_provider.dart';

/// Provider for markdown table completions
class TableCompletionProvider extends CompletionProvider with TriggerBasedProvider, LineStartProvider {
  @override
  String get name => 'Table Completion';

  @override
  Set<String> get triggerCharacters => {'|'};

  @override
  int get priority => 7;

  @override
  Future<List<CompletionSuggestion>> getSuggestions(CompletionContext context) async {
    final suggestions = <CompletionSuggestion>[];

    if (!_isValidTablePosition(context)) {
      return suggestions;
    }

    // Basic table templates
    final basicTables = [
      (
        '| Header 1 | Header 2 |\n| --- | --- |\n| Cell 1 | Cell 2 |\n| Cell 3 | Cell 4 |',
        '2x2 table',
        '2 columns, 2 rows'
      ),
      (
        '| Header 1 | Header 2 | Header 3 |\n| --- | --- | --- |\n| Cell 1 | Cell 2 | Cell 3 |\n| Cell 4 | Cell 5 | Cell 6 |',
        '3x2 table',
        '3 columns, 2 rows'
      ),
      (
        '| Name | Type | Description |\n| --- | --- | --- |\n| item1 | string | First item |\n| item2 | number | Second item |\n| item3 | boolean | Third item |',
        'API table',
        'API documentation table'
      ),
      (
        '| Feature | Status | Notes |\n| --- | --- | --- |\n| ✅ Feature 1 | Complete | Working well |\n| ⚠️ Feature 2 | In Progress | Almost done |\n| ❌ Feature 3 | Pending | Not started |',
        'Status table',
        'Feature status table'
      ),
    ];

    for (final (table, displayName, description) in basicTables) {
      suggestions.add(CompletionSuggestion(
        insertText: table,
        displayText: displayName,
        description: description,
        type: CompletionType.table,
        icon: Icons.table_chart,
        trigger: '|',
        priority: 10,
        isSnippet: true,
      ));
    }

    // Comparison tables
    final comparisonTables = [
      (
        '| Feature | Option A | Option B | Option C |\n| --- | --- | --- | --- |\n| Price | \$10 | \$20 | \$30 |\n| Speed | Fast | Medium | Slow |\n| Quality | Good | Better | Best |',
        'Comparison table',
        'Feature comparison table'
      ),
      (
        '| Before | After |\n| --- | --- |\n| Old way | New way |\n| Problem | Solution |\n| Issue | Fix |',
        'Before/After table',
        'Before and after comparison'
      ),
      (
        '| Pros | Cons |\n| --- | --- |\n| Advantage 1 | Disadvantage 1 |\n| Advantage 2 | Disadvantage 2 |\n| Advantage 3 | Disadvantage 3 |',
        'Pros/Cons table',
        'Pros and cons comparison'
      ),
    ];

    for (final (table, displayName, description) in comparisonTables) {
      suggestions.add(CompletionSuggestion(
        insertText: table,
        displayText: displayName,
        description: description,
        type: CompletionType.table,
        icon: Icons.compare,
        trigger: '|',
        priority: 8,
        isSnippet: true,
      ));
    }

    // Alignment examples
    final alignmentTables = [
      (
        '| Left | Center | Right |\n| :--- | :---: | ---: |\n| Left aligned | Center aligned | Right aligned |\n| Text | Text | Text |',
        'Aligned table',
        'Table with column alignment'
      ),
    ];

    for (final (table, displayName, description) in alignmentTables) {
      suggestions.add(CompletionSuggestion(
        insertText: table,
        displayText: displayName,
        description: description,
        type: CompletionType.table,
        icon: Icons.format_align_center,
        trigger: '|',
        priority: 7,
        isSnippet: true,
      ));
    }

    // Special purpose tables
    final specialTables = [
      (
        '| Time | Event |\n| --- | --- |\n| 9:00 AM | Meeting start |\n| 10:00 AM | Presentation |\n| 11:00 AM | Q&A session |\n| 12:00 PM | Lunch break |',
        'Schedule table',
        'Time schedule table'
      ),
      (
        '| Name | Email | Role |\n| --- | --- | --- |\n| John Doe | john@example.com | Admin |\n| Jane Smith | jane@example.com | User |\n| Bob Johnson | bob@example.com | Moderator |',
        'Contact table',
        'Contact information table'
      ),
      (
        '| Task | Assignee | Due Date | Priority |\n| --- | --- | --- | --- |\n| Task 1 | Alice | 2024-01-15 | High |\n| Task 2 | Bob | 2024-01-20 | Medium |\n| Task 3 | Carol | 2024-01-25 | Low |',
        'Task table',
        'Task management table'
      ),
      (
        '| Version | Date | Changes |\n| --- | --- | --- |\n| v1.0.0 | 2024-01-01 | Initial release |\n| v1.1.0 | 2024-01-15 | Added features |\n| v1.2.0 | 2024-02-01 | Bug fixes |',
        'Changelog table',
        'Version changelog table'
      ),
      (
        '| Metric | Value | Target | Status |\n| --- | --- | --- | --- |\n| Users | 1,000 | 1,500 | 📈 Growing |\n| Revenue | \$50K | \$75K | 📊 On Track |\n| Satisfaction | 4.2/5 | 4.5/5 | ⭐ Good |',
        'Metrics table',
        'KPI metrics table'
      ),
    ];

    for (final (table, displayName, description) in specialTables) {
      suggestions.add(CompletionSuggestion(
        insertText: table,
        displayText: displayName,
        description: description,
        type: CompletionType.table,
        icon: Icons.table_rows,
        trigger: '|',
        priority: 6,
        isSnippet: true,
      ));
    }

    // Table row continuation
    if (_isInExistingTable(context)) {
      suggestions.add(CompletionSuggestion(
        insertText: '| Cell 1 | Cell 2 |',
        displayText: '| Cell | Cell |',
        description: 'Continue table row',
        type: CompletionType.table,
        icon: Icons.add_box,
        trigger: '|',
        priority: 12, // Higher priority when in existing table
        cursorOffset: -10,
        selectionLength: 6,
      ));
    }

    // Simple pipe character completion
    suggestions.add(CompletionSuggestion(
      insertText: '| ',
      displayText: '| ',
      description: 'Table cell separator',
      type: CompletionType.table,
      icon: Icons.vertical_split,
      trigger: '|',
      priority: 5,
      cursorOffset: 0,
    ));

    return suggestions;
  }

  @override
  bool shouldActivate(CompletionContext context) {
    return super.shouldActivate(context) && _isValidTablePosition(context);
  }

  bool _isValidTablePosition(CompletionContext context) {
    // Tables should be at line start or after whitespace, or continuing existing table
    final beforeCursor = context.textBeforeCursor;
    if (beforeCursor.isEmpty) return true;

    // Check if we're in an existing table
    if (_isInExistingTable(context)) return true;

    // Check if we're at a valid position to start a new table
    final lastNewline = beforeCursor.lastIndexOf('\n');
    final currentLineStart = lastNewline + 1;
    final linePrefix = beforeCursor.substring(currentLineStart, context.cursorPosition);

    // Allow if only whitespace and pipe characters before cursor
    return RegExp(r'^[\s|]*$').hasMatch(linePrefix);
  }

  bool _isInExistingTable(CompletionContext context) {
    final lines = context.text.split('\n');
    final currentLineNumber = context.lineNumber;

    // Check if current line or nearby lines contain table patterns
    for (int i = math.max(0, currentLineNumber - 5); i < math.min(lines.length, currentLineNumber + 5); i++) {
      final line = lines[i].trim();
      // Look for table separator lines (| --- | --- |)
      if (RegExp(r'^\|\s*:?-+:?\s*(\|\s*:?-+:?\s*)*\|?\s*$').hasMatch(line)) {
        return true;
      }
      // Look for table content lines with multiple pipes
      if (line.split('|').length >= 3 && line.startsWith('|') && line.endsWith('|')) {
        return true;
      }
    }

    return false;
  }
}