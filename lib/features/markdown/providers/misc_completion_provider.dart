import 'package:flutter/material.dart';
import '../models/completion_suggestion.dart';
import 'completion_provider.dart';

/// Provider for miscellaneous markdown completions (blockquotes, horizontal rules, etc.)
class MiscCompletionProvider extends CompletionProvider with TriggerBasedProvider, LineStartProvider {
  @override
  String get name => 'Miscellaneous Completion';

  @override
  Set<String> get triggerCharacters => {'>', '-', '*', '_'};

  @override
  int get priority => 6;

  @override
  Future<List<CompletionSuggestion>> getSuggestions(CompletionContext context) async {
    final suggestions = <CompletionSuggestion>[];

    final trigger = context.triggerCharacter;

    switch (trigger) {
      case '>':
        suggestions.addAll(_getBlockquoteSuggestions(context));
        break;
      case '-':
      case '*':
      case '_':
        suggestions.addAll(_getHorizontalRuleSuggestions(context));
        suggestions.addAll(_getEmphasisSuggestions(context));
        break;
    }

    return suggestions;
  }

  List<CompletionSuggestion> _getBlockquoteSuggestions(CompletionContext context) {
    final suggestions = <CompletionSuggestion>[];

    // Basic blockquote
    suggestions.add(CompletionSuggestion(
      insertText: '> Quote text',
      displayText: '> Quote text',
      description: 'Basic blockquote',
      type: CompletionType.blockquote,
      icon: Icons.format_quote,
      trigger: '>',
      priority: 10,
      cursorOffset: -10,
      selectionLength: 10,
    ));

    // Multi-line blockquote
    suggestions.add(CompletionSuggestion(
      insertText: '> Line 1\n> Line 2\n> Line 3',
      displayText: '> Multi-line quote',
      description: 'Multi-line blockquote',
      type: CompletionType.blockquote,
      icon: Icons.format_quote,
      trigger: '>',
      priority: 9,
      isSnippet: true,
    ));

    // Nested blockquote
    suggestions.add(CompletionSuggestion(
      insertText: '> Outer quote\n> > Nested quote\n> Back to outer',
      displayText: '> > Nested quote',
      description: 'Nested blockquote',
      type: CompletionType.blockquote,
      icon: Icons.format_quote,
      trigger: '>',
      priority: 8,
      isSnippet: true,
    ));

    // Blockquote with attribution
    suggestions.add(CompletionSuggestion(
      insertText: '> Quote text\n> \n> — Author Name',
      displayText: '> Quote with attribution',
      description: 'Blockquote with author attribution',
      type: CompletionType.blockquote,
      icon: Icons.person_pin,
      trigger: '>',
      priority: 8,
      isSnippet: true,
    ));

    // Callout-style blockquotes
    final callouts = [
      ('> **Note:** Important information', 'Note callout'),
      ('> **Warning:** Be careful here', 'Warning callout'),
      ('> **Tip:** Helpful suggestion', 'Tip callout'),
      ('> **Info:** Additional details', 'Info callout'),
      ('> **Important:** Critical information', 'Important callout'),
    ];

    for (final (callout, description) in callouts) {
      suggestions.add(CompletionSuggestion(
        insertText: callout,
        displayText: callout.substring(0, callout.indexOf(':') + 1),
        description: description,
        type: CompletionType.blockquote,
        icon: Icons.info,
        trigger: '>',
        priority: 7,
        cursorOffset: -1,
      ));
    }

    // GitHub-style alerts (if supported)
    final alerts = [
      ('> [!NOTE]\n> Useful information that users should know', '[!NOTE] alert'),
      ('> [!TIP]\n> Helpful advice for doing things better', '[!TIP] alert'),
      ('> [!IMPORTANT]\n> Key information users need to know', '[!IMPORTANT] alert'),
      ('> [!WARNING]\n> Critical content demanding attention', '[!WARNING] alert'),
      ('> [!CAUTION]\n> Negative potential consequences', '[!CAUTION] alert'),
    ];

    for (final (alert, description) in alerts) {
      suggestions.add(CompletionSuggestion(
        insertText: alert,
        displayText: alert.split('\n').first,
        description: description,
        type: CompletionType.blockquote,
        icon: Icons.report,
        trigger: '>',
        priority: 6,
        isSnippet: true,
      ));
    }

    return suggestions;
  }

  List<CompletionSuggestion> _getHorizontalRuleSuggestions(CompletionContext context) {
    final suggestions = <CompletionSuggestion>[];

    // Only suggest horizontal rules at line start
    if (!_isStartOfLineOrAfterBlankLine(context)) {
      return suggestions;
    }

    final trigger = context.triggerCharacter!;

    // Basic horizontal rules
    final rules = [
      ('---', 'Horizontal rule (dashes)'),
      ('***', 'Horizontal rule (asterisks)'),
      ('___', 'Horizontal rule (underscores)'),
      ('- - -', 'Spaced horizontal rule (dashes)'),
      ('* * *', 'Spaced horizontal rule (asterisks)'),
      ('_ _ _', 'Spaced horizontal rule (underscores)'),
    ];

    for (final (rule, description) in rules) {
      if (rule.startsWith(trigger)) {
        suggestions.add(CompletionSuggestion(
          insertText: rule,
          displayText: rule,
          description: description,
          type: CompletionType.horizontalRule,
          icon: Icons.horizontal_rule,
          trigger: trigger,
          priority: trigger == '-' ? 10 : 9,
        ));
      }
    }

    return suggestions;
  }

  List<CompletionSuggestion> _getEmphasisSuggestions(CompletionContext context) {
    final suggestions = <CompletionSuggestion>[];

    final trigger = context.triggerCharacter!;

    // Only suggest emphasis for * and _
    if (trigger != '*' && trigger != '_') {
      return suggestions;
    }

    // Don't suggest emphasis at start of line (conflicts with lists and horizontal rules)
    if (context.isStartOfLine) {
      return suggestions;
    }

    // Basic emphasis
    suggestions.addAll([
      CompletionSuggestion(
        insertText: '${trigger}italic$trigger',
        displayText: '${trigger}italic$trigger',
        description: 'Italic text',
        type: CompletionType.emphasis,
        icon: Icons.format_italic,
        trigger: trigger,
        priority: 8,
        cursorOffset: -trigger.length,
        selectionLength: 6,
      ),
      CompletionSuggestion(
        insertText: '$trigger${trigger}bold$trigger$trigger',
        displayText: '$trigger${trigger}bold$trigger$trigger',
        description: 'Bold text',
        type: CompletionType.emphasis,
        icon: Icons.format_bold,
        trigger: trigger,
        priority: 9,
        cursorOffset: -trigger.length * 2,
        selectionLength: 4,
      ),
      CompletionSuggestion(
        insertText: '$trigger$trigger${trigger}bold italic$trigger$trigger$trigger',
        displayText: '$trigger$trigger${trigger}bold italic$trigger$trigger$trigger',
        description: 'Bold italic text',
        type: CompletionType.emphasis,
        icon: Icons.format_bold,
        trigger: trigger,
        priority: 7,
        cursorOffset: -trigger.length * 3,
        selectionLength: 11,
      ),
    ]);

    return suggestions;
  }

  @override
  bool shouldActivate(CompletionContext context) {
    final trigger = context.triggerCharacter;

    // Special handling for different triggers
    switch (trigger) {
      case '>':
        // Blockquotes work at line start or after whitespace
        return _isValidBlockquotePosition(context);
      case '-':
      case '*':
      case '_':
        // These can be horizontal rules (at line start) or emphasis (inline)
        return super.shouldActivate(context) || !context.isStartOfLine;
      default:
        return super.shouldActivate(context);
    }
  }

  bool _isValidBlockquotePosition(CompletionContext context) {
    final beforeCursor = context.textBeforeCursor;
    if (beforeCursor.isEmpty) return true;

    final lastNewline = beforeCursor.lastIndexOf('\n');
    final currentLineStart = lastNewline + 1;
    final linePrefix = beforeCursor.substring(currentLineStart, context.cursorPosition);

    // Allow if only whitespace and > characters before cursor
    return RegExp(r'^[\s>]*$').hasMatch(linePrefix);
  }

  bool _isStartOfLineOrAfterBlankLine(CompletionContext context) {
    if (context.isStartOfLine) return true;

    final lines = context.textBeforeCursor.split('\n');
    if (lines.length < 2) return context.isStartOfLine;

    // Check if previous line is empty
    final previousLine = lines[lines.length - 2].trim();
    return previousLine.isEmpty && context.currentLine.trim().isEmpty;
  }
}