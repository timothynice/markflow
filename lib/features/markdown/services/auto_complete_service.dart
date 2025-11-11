import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/completion_suggestion.dart';
import '../providers/completion_provider.dart';

/// Service that manages auto-completion functionality
class AutoCompleteService extends ChangeNotifier {
  static const String _prefsKey = 'auto_complete_preferences';
  static const String _usageStatsKey = 'auto_complete_usage_stats';
  static const String _customShortcutsKey = 'auto_complete_custom_shortcuts';

  final List<CompletionProvider> _providers = [];
  CompletionResult _currentResult = CompletionResult.empty;
  CompletionContext? _currentContext;
  Timer? _debounceTimer;
  SharedPreferences? _prefs;

  // User preferences
  bool _isEnabled = true;
  bool _autoTriggerEnabled = true;
  int _suggestionDelay = 300; // milliseconds
  int _maxSuggestions = 10;
  Set<String> _triggerCharacters = {'#', '*', '-', '[', '!', '`', '>', '|'};
  Map<String, int> _usageStats = {};
  List<CompletionSuggestion> _customShortcuts = [];

  // Getters
  CompletionResult get currentResult => _currentResult;
  CompletionContext? get currentContext => _currentContext;
  bool get isEnabled => _isEnabled;
  bool get autoTriggerEnabled => _autoTriggerEnabled;
  int get suggestionDelay => _suggestionDelay;
  int get maxSuggestions => _maxSuggestions;
  Set<String> get triggerCharacters => Set.unmodifiable(_triggerCharacters);
  Map<String, int> get usageStats => Map.unmodifiable(_usageStats);
  List<CompletionSuggestion> get customShortcuts => List.unmodifiable(_customShortcuts);

  AutoCompleteService() {
    _initializePreferences();
  }

  /// Initialize the service with providers
  void initialize(List<CompletionProvider> providers) {
    _providers.clear();
    _providers.addAll(providers);
    notifyListeners();
  }

  /// Add a completion provider
  void addProvider(CompletionProvider provider) {
    _providers.add(provider);
    notifyListeners();
  }

  /// Remove a completion provider
  void removeProvider(CompletionProvider provider) {
    _providers.remove(provider);
    notifyListeners();
  }

  /// Initialize preferences from storage
  Future<void> _initializePreferences() async {
    try {
      _prefs = await SharedPreferences.getInstance();
      await _loadPreferences();
      await _loadUsageStats();
      await _loadCustomShortcuts();
    } catch (e) {
      debugPrint('Failed to initialize auto-complete preferences: $e');
    }
  }

  /// Load preferences from storage
  Future<void> _loadPreferences() async {
    if (_prefs == null) return;

    final prefsJson = _prefs!.getString(_prefsKey);
    if (prefsJson != null) {
      try {
        final Map<String, dynamic> prefs = jsonDecode(prefsJson) as Map<String, dynamic>;
        _isEnabled = (prefs['enabled'] as bool?) ?? true;
        _autoTriggerEnabled = (prefs['autoTrigger'] as bool?) ?? true;
        _suggestionDelay = (prefs['delay'] as int?) ?? 300;
        _maxSuggestions = (prefs['maxSuggestions'] as int?) ?? 10;

        final triggers = prefs['triggerCharacters'] as List<dynamic>?;
        if (triggers != null) {
          _triggerCharacters = triggers.cast<String>().toSet();
        }
      } catch (e) {
        debugPrint('Failed to load auto-complete preferences: $e');
      }
    }
  }

  /// Load usage statistics from storage
  Future<void> _loadUsageStats() async {
    if (_prefs == null) return;

    final statsJson = _prefs!.getString(_usageStatsKey);
    if (statsJson != null) {
      try {
        final Map<String, dynamic> stats = jsonDecode(statsJson) as Map<String, dynamic>;
        // Safely coerce numeric types
        _usageStats = stats.map((key, value) => MapEntry(
              key,
              (value is num) ? value.toInt() : int.tryParse(value.toString()) ?? 0,
            ));
      } catch (e) {
        debugPrint('Failed to load usage statistics: $e');
      }
    }
  }

  /// Load custom shortcuts from storage
  Future<void> _loadCustomShortcuts() async {
    if (_prefs == null) return;

    final shortcutsJson = _prefs!.getString(_customShortcutsKey);
    if (shortcutsJson != null) {
      try {
        final List<dynamic> shortcuts = jsonDecode(shortcutsJson) as List<dynamic>;
        _customShortcuts = shortcuts
            .map((json) => CompletionSuggestion.fromJson(
                  Map<String, dynamic>.from(json as Map),
                ))
            .toList();
      } catch (e) {
        debugPrint('Failed to load custom shortcuts: $e');
      }
    }
  }

  /// Save preferences to storage
  Future<void> _savePreferences() async {
    if (_prefs == null) return;

    try {
      final prefs = {
        'enabled': _isEnabled,
        'autoTrigger': _autoTriggerEnabled,
        'delay': _suggestionDelay,
        'maxSuggestions': _maxSuggestions,
        'triggerCharacters': _triggerCharacters.toList(),
      };
      await _prefs!.setString(_prefsKey, jsonEncode(prefs));
    } catch (e) {
      debugPrint('Failed to save auto-complete preferences: $e');
    }
  }

  /// Save usage statistics to storage
  Future<void> _saveUsageStats() async {
    if (_prefs == null) return;

    try {
      await _prefs!.setString(_usageStatsKey, jsonEncode(_usageStats));
    } catch (e) {
      debugPrint('Failed to save usage statistics: $e');
    }
  }

  /// Save custom shortcuts to storage
  Future<void> _saveCustomShortcuts() async {
    if (_prefs == null) return;

    try {
      final shortcuts = _customShortcuts.map((s) => s.toJson()).toList();
      await _prefs!.setString(_customShortcutsKey, jsonEncode(shortcuts));
    } catch (e) {
      debugPrint('Failed to save custom shortcuts: $e');
    }
  }

  /// Update service settings
  Future<void> updateSettings({
    bool? enabled,
    bool? autoTrigger,
    int? delay,
    int? maxSuggestions,
    Set<String>? triggerCharacters,
  }) async {
    bool changed = false;

    if (enabled != null && enabled != _isEnabled) {
      _isEnabled = enabled;
      changed = true;
    }

    if (autoTrigger != null && autoTrigger != _autoTriggerEnabled) {
      _autoTriggerEnabled = autoTrigger;
      changed = true;
    }

    if (delay != null && delay != _suggestionDelay) {
      _suggestionDelay = delay;
      changed = true;
    }

    if (maxSuggestions != null && maxSuggestions != _maxSuggestions) {
      _maxSuggestions = maxSuggestions;
      changed = true;
    }

    if (triggerCharacters != null && !setEquals(triggerCharacters, _triggerCharacters)) {
      _triggerCharacters = Set.from(triggerCharacters);
      changed = true;
    }

    if (changed) {
      await _savePreferences();
      notifyListeners();
    }
  }

  /// Request completions for the given context
  void requestCompletions(String text, int position, {String? triggerCharacter}) {
    if (!_isEnabled) {
      _clearCompletions();
      return;
    }

    // Cancel previous debounce timer
    _debounceTimer?.cancel();

    // Create completion context
    final context = CompletionContext.fromTextAndPosition(
      text,
      position,
      triggerCharacter: triggerCharacter,
    );
    _currentContext = context;

    // Debounce the completion request
    _debounceTimer = Timer(Duration(milliseconds: _suggestionDelay), () {
      _performCompletion(context);
    });
  }

  /// Immediately request completions (for trigger characters)
  void requestCompletionsImmediate(String text, int position, {String? triggerCharacter}) {
    if (!_isEnabled) {
      _clearCompletions();
      return;
    }

    _debounceTimer?.cancel();

    final context = CompletionContext.fromTextAndPosition(
      text,
      position,
      triggerCharacter: triggerCharacter,
    );
    _currentContext = context;

    _performCompletion(context);
  }

  /// Perform the completion logic
  Future<void> _performCompletion(CompletionContext context) async {
    final suggestions = <CompletionSuggestion>[];

    // Get suggestions from all providers
    for (final provider in _providers) {
      try {
        final providerSuggestions = await provider.getSuggestions(context);
        suggestions.addAll(providerSuggestions);
      } catch (e) {
        debugPrint('Error getting suggestions from provider: $e');
      }
    }

    // Add custom shortcuts if appropriate
    if (context.triggerCharacter == null || context.triggerCharacter!.isEmpty) {
      final matchingShortcuts = _customShortcuts.where((shortcut) {
        if (shortcut.shortcutKey == null) return false;
        final currentWord = _getCurrentWord(context);
        return shortcut.shortcutKey!.toLowerCase().contains(currentWord.toLowerCase());
      }).toList();
      suggestions.addAll(matchingShortcuts);
    }

    // Filter and rank suggestions
    final filteredSuggestions = _filterAndRankSuggestions(suggestions, context);

    // Update current result
    _currentResult = CompletionResult(
      suggestions: filteredSuggestions,
      isActive: filteredSuggestions.isNotEmpty,
      filterText: _getFilterText(context),
    );

    notifyListeners();
  }

  /// Filter and rank suggestions based on context and usage
  List<CompletionSuggestion> _filterAndRankSuggestions(
    List<CompletionSuggestion> suggestions,
    CompletionContext context,
  ) {
    final filterText = _getFilterText(context).toLowerCase();

    // Filter suggestions
    List<CompletionSuggestion> filtered;
    if (filterText.isEmpty) {
      filtered = List.from(suggestions);
    } else {
      filtered = suggestions.where((suggestion) {
        return suggestion.displayText.toLowerCase().contains(filterText) ||
               suggestion.insertText.toLowerCase().contains(filterText) ||
               (suggestion.shortcutKey?.toLowerCase().contains(filterText) ?? false);
      }).toList();
    }

    // Rank suggestions
    filtered.sort((a, b) {
      // First by priority
      int priorityCompare = b.priority.compareTo(a.priority);
      if (priorityCompare != 0) return priorityCompare;

      // Then by usage count
      final aUsage = _usageStats[a.displayText] ?? 0;
      final bUsage = _usageStats[b.displayText] ?? 0;
      int usageCompare = bUsage.compareTo(aUsage);
      if (usageCompare != 0) return usageCompare;

      // Then by relevance to filter text
      if (filterText.isNotEmpty) {
        final aStarts = a.displayText.toLowerCase().startsWith(filterText);
        final bStarts = b.displayText.toLowerCase().startsWith(filterText);
        if (aStarts && !bStarts) return -1;
        if (!aStarts && bStarts) return 1;
      }

      // Finally alphabetically
      return a.displayText.compareTo(b.displayText);
    });

    // Limit results
    return filtered.take(_maxSuggestions).toList();
  }

  /// Get the current word being typed
  String _getCurrentWord(CompletionContext context) {
    final line = context.currentLine;
    final position = context.columnPosition;

    // Find word boundaries
    int start = position;
    while (start > 0 && !_isWordBoundary(line[start - 1])) {
      start--;
    }

    int end = position;
    while (end < line.length && !_isWordBoundary(line[end])) {
      end++;
    }

    return line.substring(start, end);
  }

  /// Check if character is a word boundary
  bool _isWordBoundary(String char) {
    return char == ' ' || char == '\t' || char == '\n' ||
           char == '(' || char == ')' || char == '[' || char == ']' ||
           char == '{' || char == '}' || char == ',' || char == '.' ||
           char == ';' || char == ':' || char == '!' || char == '?';
  }

  /// Get filter text for current context
  String _getFilterText(CompletionContext context) {
    // If triggered by character, use text after trigger
    if (context.triggerCharacter != null) {
      final triggerIndex = context.textBeforeCursor.lastIndexOf(context.triggerCharacter!);
      if (triggerIndex != -1) {
        return context.textBeforeCursor.substring(triggerIndex + 1);
      }
    }

    // Otherwise use current word
    return _getCurrentWord(context);
  }

  /// Select next suggestion
  void selectNext() {
    if (!_currentResult.hasSuggestions) return;

    final newIndex = (_currentResult.selectedIndex + 1) % _currentResult.suggestions.length;
    _currentResult = _currentResult.copyWith(selectedIndex: newIndex);
    notifyListeners();
  }

  /// Select previous suggestion
  void selectPrevious() {
    if (!_currentResult.hasSuggestions) return;

    final newIndex = (_currentResult.selectedIndex - 1 + _currentResult.suggestions.length) % _currentResult.suggestions.length;
    _currentResult = _currentResult.copyWith(selectedIndex: newIndex);
    notifyListeners();
  }

  /// Select suggestion by index
  void selectSuggestion(int index) {
    if (index < 0 || index >= _currentResult.suggestions.length) return;

    _currentResult = _currentResult.copyWith(selectedIndex: index);
    notifyListeners();
  }

  /// Apply the currently selected suggestion
  CompletionApplication? applySelectedSuggestion() {
    final suggestion = _currentResult.selectedSuggestion;
    if (suggestion == null || _currentContext == null) return null;

    return applySuggestion(suggestion);
  }

  /// Apply a specific suggestion
  CompletionApplication? applySuggestion(CompletionSuggestion suggestion) {
    if (_currentContext == null) return null;

    // Record usage for learning
    _recordUsage(suggestion);

    // Calculate insertion details
    final context = _currentContext!;
    final filterText = _getFilterText(context);

    int replaceStart = context.cursorPosition;
    int replaceLength = 0;

    if (context.triggerCharacter != null) {
      // Replace from trigger character
      final triggerIndex = context.textBeforeCursor.lastIndexOf(context.triggerCharacter!);
      if (triggerIndex != -1) {
        replaceStart = triggerIndex;
        replaceLength = context.cursorPosition - triggerIndex;
      }
    } else if (filterText.isNotEmpty) {
      // Replace current word
      replaceStart = context.cursorPosition - filterText.length;
      replaceLength = filterText.length;
    }

    final newCursorPosition = replaceStart + suggestion.insertText.length + (suggestion.cursorOffset ?? 0);

    final application = CompletionApplication(
      insertText: suggestion.insertText,
      replaceStart: replaceStart,
      replaceLength: replaceLength,
      newCursorPosition: newCursorPosition,
      selectionLength: suggestion.selectionLength,
    );

    // Clear completions after application
    _clearCompletions();

    return application;
  }

  /// Record usage of a suggestion for learning
  void _recordUsage(CompletionSuggestion suggestion) {
    final key = suggestion.displayText;
    _usageStats[key] = (_usageStats[key] ?? 0) + 1;

    // Save usage stats periodically (every 10 uses)
    if (_usageStats[key]! % 10 == 0) {
      unawaited(_saveUsageStats());
    }
  }

  /// Check if character should trigger completion
  bool shouldTriggerCompletion(String character) {
    return _isEnabled && _autoTriggerEnabled && _triggerCharacters.contains(character);
  }

  /// Add custom shortcut
  Future<void> addCustomShortcut(CompletionSuggestion shortcut) async {
    _customShortcuts.add(shortcut);
    await _saveCustomShortcuts();
    notifyListeners();
  }

  /// Remove custom shortcut
  Future<void> removeCustomShortcut(CompletionSuggestion shortcut) async {
    _customShortcuts.removeWhere((s) =>
      s.shortcutKey == shortcut.shortcutKey && s.insertText == shortcut.insertText);
    await _saveCustomShortcuts();
    notifyListeners();
  }

  /// Clear current completions
  void _clearCompletions() {
    _debounceTimer?.cancel();
    _currentResult = CompletionResult.empty;
    _currentContext = null;
    notifyListeners();
  }

  /// Manually clear completions
  void clearCompletions() {
    _clearCompletions();
  }

  /// Reset usage statistics
  Future<void> resetUsageStats() async {
    _usageStats.clear();
    await _saveUsageStats();
    notifyListeners();
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    super.dispose();
  }
}

/// Details for applying a completion
class CompletionApplication {
  final String insertText;
  final int replaceStart;
  final int replaceLength;
  final int newCursorPosition;
  final int? selectionLength;

  const CompletionApplication({
    required this.insertText,
    required this.replaceStart,
    required this.replaceLength,
    required this.newCursorPosition,
    this.selectionLength,
  });
}

// Helper function for async operations without await
void unawaited(Future<void> future) {
  future.catchError((error) {
    debugPrint('Unawaited future error: $error');
  });
}