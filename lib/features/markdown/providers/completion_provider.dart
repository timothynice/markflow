import '../models/completion_suggestion.dart';

/// Base class for completion providers
abstract class CompletionProvider {
  /// Get suggestions for the given context
  Future<List<CompletionSuggestion>> getSuggestions(CompletionContext context);

  /// Whether this provider should be active for the given context
  bool shouldActivate(CompletionContext context);

  /// Priority of this provider (higher = more important)
  int get priority => 0;

  /// Name of this provider for debugging
  String get name;
}

/// Mixin for providers that work with trigger characters
mixin TriggerBasedProvider on CompletionProvider {
  /// Characters that trigger this provider
  Set<String> get triggerCharacters;

  @override
  bool shouldActivate(CompletionContext context) {
    return context.triggerCharacter != null &&
           triggerCharacters.contains(context.triggerCharacter);
  }
}

/// Mixin for providers that work at line start
mixin LineStartProvider on CompletionProvider {
  @override
  bool shouldActivate(CompletionContext context) {
    return context.isStartOfLine ||
           context.currentLine.trim().isEmpty ||
           RegExp(r'^\s*$').hasMatch(context.currentLine.substring(0, context.columnPosition));
  }
}

/// Mixin for providers that work anywhere
mixin UniversalProvider on CompletionProvider {
  @override
  bool shouldActivate(CompletionContext context) {
    return !context.isInCodeBlock; // Generally avoid inside code blocks
  }
}