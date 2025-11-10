import 'package:flutter/material.dart';
import '../models/completion_suggestion.dart';
import 'completion_provider.dart';

/// Provider for markdown header completions
class HeaderCompletionProvider extends CompletionProvider with TriggerBasedProvider, LineStartProvider {
  @override
  String get name => 'Header Completion';

  @override
  Set<String> get triggerCharacters => {'#'};

  @override
  int get priority => 10;

  @override
  Future<List<CompletionSuggestion>> getSuggestions(CompletionContext context) async {
    final suggestions = <CompletionSuggestion>[];

    // Only suggest headers at line start or after whitespace
    if (!_isValidHeaderPosition(context)) {
      return suggestions;
    }

    // Count existing '#' characters to determine current level
    final beforeCursor = context.textBeforeCursor;
    final currentLineStart = beforeCursor.lastIndexOf('\n') + 1;
    final currentLinePrefix = beforeCursor.substring(currentLineStart);
    final hashCount = currentLinePrefix.split('').where((c) => c == '#').length;

    // Suggest header levels 1-6
    for (int level = 1; level <= 6; level++) {
      final hashes = '#' * level;
      final displayText = '$hashes Heading $level';
      final description = 'Insert level $level heading';

      suggestions.add(CompletionSuggestion(
        insertText: '$hashes ',
        displayText: displayText,
        description: description,
        type: CompletionType.header,
        icon: Icons.title,
        trigger: '#',
        priority: 10 - level, // Higher level headers have higher priority
        cursorOffset: 0,
      ));
    }

    // Add specific common headers
    final commonHeaders = [
      ('# Title', 'Main document title'),
      ('## Overview', 'Section overview'),
      ('## Installation', 'Installation instructions'),
      ('## Usage', 'Usage examples'),
      ('## API Reference', 'API documentation'),
      ('## Examples', 'Code examples'),
      ('## License', 'License information'),
      ('## Contributing', 'Contributing guidelines'),
      ('### Prerequisites', 'Required dependencies'),
      ('### Configuration', 'Configuration options'),
    ];

    for (final (headerText, description) in commonHeaders) {
      final level = headerText.split(' ')[0].length; // Count # characters
      suggestions.add(CompletionSuggestion(
        insertText: headerText,
        displayText: headerText,
        description: description,
        type: CompletionType.header,
        icon: Icons.title,
        trigger: '#',
        priority: 5,
        cursorOffset: 0,
      ));
    }

    return suggestions;
  }

  @override
  bool shouldActivate(CompletionContext context) {
    return super.shouldActivate(context) && _isValidHeaderPosition(context);
  }

  bool _isValidHeaderPosition(CompletionContext context) {
    // Headers should be at line start or after whitespace
    final beforeCursor = context.textBeforeCursor;
    if (beforeCursor.isEmpty) return true;

    final lastNewline = beforeCursor.lastIndexOf('\n');
    final currentLineStart = lastNewline + 1;
    final linePrefix = beforeCursor.substring(currentLineStart, context.cursorPosition);

    // Allow if only whitespace and # characters before cursor
    return RegExp(r'^[\s#]*$').hasMatch(linePrefix);
  }
}