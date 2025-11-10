import 'package:flutter/material.dart';

/// Types of markdown completion suggestions
enum CompletionType {
  header,
  list,
  link,
  image,
  codeBlock,
  table,
  emphasis,
  blockquote,
  horizontalRule,
  customShortcut,
}

/// Represents a single auto-completion suggestion
class CompletionSuggestion {
  /// The text to insert
  final String insertText;

  /// The display text shown in the suggestion list
  final String displayText;

  /// Optional description for the suggestion
  final String? description;

  /// The type of completion
  final CompletionType type;

  /// Icon to show in the suggestion list
  final IconData? icon;

  /// The trigger character that initiated this suggestion
  final String? trigger;

  /// Priority for ranking (higher = more important)
  final int priority;

  /// Whether this is a snippet with cursor positions
  final bool isSnippet;

  /// Cursor position after insertion (relative to insertion point)
  final int? cursorOffset;

  /// Length of text to select after insertion
  final int? selectionLength;

  /// Usage frequency for learning system
  final int usageCount;

  /// Custom shortcut key (e.g., "h1", "table")
  final String? shortcutKey;

  const CompletionSuggestion({
    required this.insertText,
    required this.displayText,
    required this.type,
    this.description,
    this.icon,
    this.trigger,
    this.priority = 0,
    this.isSnippet = false,
    this.cursorOffset,
    this.selectionLength,
    this.usageCount = 0,
    this.shortcutKey,
  });

  /// Creates a copy with updated properties
  CompletionSuggestion copyWith({
    String? insertText,
    String? displayText,
    String? description,
    CompletionType? type,
    IconData? icon,
    String? trigger,
    int? priority,
    bool? isSnippet,
    int? cursorOffset,
    int? selectionLength,
    int? usageCount,
    String? shortcutKey,
  }) {
    return CompletionSuggestion(
      insertText: insertText ?? this.insertText,
      displayText: displayText ?? this.displayText,
      description: description ?? this.description,
      type: type ?? this.type,
      icon: icon ?? this.icon,
      trigger: trigger ?? this.trigger,
      priority: priority ?? this.priority,
      isSnippet: isSnippet ?? this.isSnippet,
      cursorOffset: cursorOffset ?? this.cursorOffset,
      selectionLength: selectionLength ?? this.selectionLength,
      usageCount: usageCount ?? this.usageCount,
      shortcutKey: shortcutKey ?? this.shortcutKey,
    );
  }

  /// Increment usage count for learning system
  CompletionSuggestion incrementUsage() {
    return copyWith(usageCount: usageCount + 1);
  }

  /// Converts to JSON for persistence
  Map<String, dynamic> toJson() {
    return {
      'insertText': insertText,
      'displayText': displayText,
      'description': description,
      'type': type.name,
      'trigger': trigger,
      'priority': priority,
      'isSnippet': isSnippet,
      'cursorOffset': cursorOffset,
      'selectionLength': selectionLength,
      'usageCount': usageCount,
      'shortcutKey': shortcutKey,
    };
  }

  /// Creates from JSON
  factory CompletionSuggestion.fromJson(Map<String, dynamic> json) {
    return CompletionSuggestion(
      insertText: json['insertText'] as String,
      displayText: json['displayText'] as String,
      description: json['description'] as String?,
      type: CompletionType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => CompletionType.customShortcut,
      ),
      trigger: json['trigger'] as String?,
      priority: json['priority'] as int? ?? 0,
      isSnippet: json['isSnippet'] as bool? ?? false,
      cursorOffset: json['cursorOffset'] as int?,
      selectionLength: json['selectionLength'] as int?,
      usageCount: json['usageCount'] as int? ?? 0,
      shortcutKey: json['shortcutKey'] as String?,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CompletionSuggestion &&
        other.insertText == insertText &&
        other.displayText == displayText &&
        other.type == type;
  }

  @override
  int get hashCode => Object.hash(insertText, displayText, type);

  @override
  String toString() {
    return 'CompletionSuggestion(displayText: $displayText, type: $type, priority: $priority)';
  }
}

/// Context information for generating suggestions
class CompletionContext {
  /// The current text being edited
  final String text;

  /// Current cursor position
  final int cursorPosition;

  /// Text before the cursor
  final String textBeforeCursor;

  /// Text after the cursor
  final String textAfterCursor;

  /// Current line content
  final String currentLine;

  /// Current line number (0-based)
  final int lineNumber;

  /// Position within the current line
  final int columnPosition;

  /// Whether we're at the start of a line
  final bool isStartOfLine;

  /// Whether we're inside a code block
  final bool isInCodeBlock;

  /// The trigger character that initiated completion
  final String? triggerCharacter;

  const CompletionContext({
    required this.text,
    required this.cursorPosition,
    required this.textBeforeCursor,
    required this.textAfterCursor,
    required this.currentLine,
    required this.lineNumber,
    required this.columnPosition,
    required this.isStartOfLine,
    required this.isInCodeBlock,
    this.triggerCharacter,
  });

  /// Creates context from text and cursor position
  factory CompletionContext.fromTextAndPosition(String text, int position, {String? triggerCharacter}) {
    final textBeforeCursor = text.substring(0, position);
    final textAfterCursor = text.substring(position);

    final lines = text.split('\n');
    final beforeLines = textBeforeCursor.split('\n');
    final lineNumber = beforeLines.length - 1;
    final currentLine = lines.length > lineNumber ? lines[lineNumber] : '';
    final columnPosition = beforeLines.last.length;
    final isStartOfLine = currentLine.trim().isEmpty || columnPosition == 0;

    // Simple check for code block - could be enhanced
    final codeBlockPattern = RegExp(r'```[\s\S]*?```');
    final isInCodeBlock = codeBlockPattern.allMatches(textBeforeCursor).length % 2 == 1;

    return CompletionContext(
      text: text,
      cursorPosition: position,
      textBeforeCursor: textBeforeCursor,
      textAfterCursor: textAfterCursor,
      currentLine: currentLine,
      lineNumber: lineNumber,
      columnPosition: columnPosition,
      isStartOfLine: isStartOfLine,
      isInCodeBlock: isInCodeBlock,
      triggerCharacter: triggerCharacter,
    );
  }
}

/// Result of a completion request
class CompletionResult {
  /// List of suggestions
  final List<CompletionSuggestion> suggestions;

  /// Whether the completion was triggered
  final bool isActive;

  /// Current filter text
  final String filterText;

  /// Selected suggestion index
  final int selectedIndex;

  const CompletionResult({
    required this.suggestions,
    required this.isActive,
    required this.filterText,
    this.selectedIndex = 0,
  });

  /// Empty result
  static const CompletionResult empty = CompletionResult(
    suggestions: [],
    isActive: false,
    filterText: '',
  );

  /// Creates a copy with updated properties
  CompletionResult copyWith({
    List<CompletionSuggestion>? suggestions,
    bool? isActive,
    String? filterText,
    int? selectedIndex,
  }) {
    return CompletionResult(
      suggestions: suggestions ?? this.suggestions,
      isActive: isActive ?? this.isActive,
      filterText: filterText ?? this.filterText,
      selectedIndex: selectedIndex ?? this.selectedIndex,
    );
  }

  /// Gets the currently selected suggestion
  CompletionSuggestion? get selectedSuggestion {
    if (suggestions.isEmpty || selectedIndex < 0 || selectedIndex >= suggestions.length) {
      return null;
    }
    return suggestions[selectedIndex];
  }

  /// Whether there are any suggestions
  bool get hasSuggestions => suggestions.isNotEmpty;
}