import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/search_result.dart';

/// Service for handling text search and replace operations
class SearchService extends ChangeNotifier {
  static const String _historyKey = 'search_history';
  static const int _maxHistoryItems = 20;

  SearchResult _currentResult = const SearchResult.empty();
  List<String> _searchHistory = [];
  Timer? _debounceTimer;

  /// Current search result
  SearchResult get currentResult => _currentResult;

  /// Search history (most recent first)
  List<String> get searchHistory => List.unmodifiable(_searchHistory);

  /// Whether a search is currently active
  bool get hasActiveSearch => _currentResult.hasMatches;

  SearchService() {
    _loadSearchHistory();
  }

  /// Perform a text search with the given query and options
  Future<SearchResult> search(
    String text,
    String query, {
    SearchOptions options = const SearchOptions(),
    Duration debounce = const Duration(milliseconds: 300),
  }) async {
    // Cancel any pending search
    _debounceTimer?.cancel();

    // If query is empty, return empty result
    if (query.isEmpty) {
      _currentResult = const SearchResult.empty();
      notifyListeners();
      return _currentResult;
    }

    // Debounce the search for better performance
    final completer = Completer<SearchResult>();
    _debounceTimer = Timer(debounce, () {
      _performSearch(text, query, options).then((result) {
        _currentResult = result;
        if (result.hasMatches && query.trim().isNotEmpty) {
          _addToHistory(query);
        }
        notifyListeners();
        completer.complete(result);
      }).catchError((error) {
        final errorResult = SearchResult.error(error.toString(), query: query);
        _currentResult = errorResult;
        notifyListeners();
        completer.complete(errorResult);
      });
    });

    return completer.future;
  }

  /// Perform immediate search without debouncing (for navigation)
  SearchResult searchImmediate(
    String text,
    String query, {
    SearchOptions options = const SearchOptions(),
  }) {
    if (query.isEmpty) {
      _currentResult = const SearchResult.empty();
      notifyListeners();
      return _currentResult;
    }

    try {
      _currentResult = _performSearchSync(text, query, options);
      if (_currentResult.hasMatches && query.trim().isNotEmpty) {
        _addToHistory(query);
      }
      notifyListeners();
      return _currentResult;
    } catch (error) {
      _currentResult = SearchResult.error(error.toString(), query: query);
      notifyListeners();
      return _currentResult;
    }
  }

  /// Navigate to the next match
  SearchResult navigateToNext() {
    if (!_currentResult.hasMatches) return _currentResult;
    _currentResult = _currentResult.withActiveMatch(_currentResult.nextMatchIndex);
    notifyListeners();
    return _currentResult;
  }

  /// Navigate to the previous match
  SearchResult navigateToPrevious() {
    if (!_currentResult.hasMatches) return _currentResult;
    _currentResult = _currentResult.withActiveMatch(_currentResult.previousMatchIndex);
    notifyListeners();
    return _currentResult;
  }

  /// Navigate to a specific match by index
  SearchResult navigateToMatch(int index) {
    if (!_currentResult.hasMatches || index < 0 || index >= _currentResult.matchCount) {
      return _currentResult;
    }
    _currentResult = _currentResult.withActiveMatch(index);
    notifyListeners();
    return _currentResult;
  }

  /// Replace the current match with the given replacement text
  /// Returns the new text with the replacement applied
  String replaceCurrent(String text, String replacement) {
    final activeMatch = _currentResult.activeMatch;
    if (activeMatch == null) return text;

    final before = text.substring(0, activeMatch.start);
    final after = text.substring(activeMatch.end);
    final newText = before + replacement + after;

    // Update the search result to reflect the text change
    _updateSearchAfterReplace(activeMatch, replacement);

    return newText;
  }

  /// Replace all matches with the given replacement text
  /// Returns the new text with all replacements applied
  String replaceAll(String text, String replacement) {
    if (!_currentResult.hasMatches) return text;

    // Sort matches by start position in descending order to avoid offset issues
    final sortedMatches = List<SearchMatch>.from(_currentResult.matches)
      ..sort((a, b) => b.start.compareTo(a.start));

    String newText = text;
    int replacementCount = 0;

    for (final match in sortedMatches) {
      final before = newText.substring(0, match.start);
      final after = newText.substring(match.end);
      newText = before + replacement + after;
      replacementCount++;
    }

    // Clear the search result since all matches have been replaced
    _currentResult = const SearchResult.empty();
    notifyListeners();

    return newText;
  }

  /// Clear the current search
  void clearSearch() {
    _debounceTimer?.cancel();
    _currentResult = const SearchResult.empty();
    notifyListeners();
  }

  /// Add a query to search history
  void _addToHistory(String query) {
    query = query.trim();
    if (query.isEmpty) return;

    // Remove if already exists
    _searchHistory.remove(query);

    // Add to beginning
    _searchHistory.insert(0, query);

    // Limit history size
    if (_searchHistory.length > _maxHistoryItems) {
      _searchHistory = _searchHistory.take(_maxHistoryItems).toList();
    }

    _saveSearchHistory();
  }

  /// Load search history from shared preferences
  Future<void> _loadSearchHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final history = prefs.getStringList(_historyKey) ?? [];
      _searchHistory = history;
    } catch (e) {
      debugPrint('Failed to load search history: $e');
    }
  }

  /// Save search history to shared preferences
  Future<void> _saveSearchHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(_historyKey, _searchHistory);
    } catch (e) {
      debugPrint('Failed to save search history: $e');
    }
  }

  /// Clear search history
  Future<void> clearHistory() async {
    _searchHistory.clear();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_historyKey);
    } catch (e) {
      debugPrint('Failed to clear search history: $e');
    }
    notifyListeners();
  }

  /// Perform the actual search operation
  Future<SearchResult> _performSearch(
    String text,
    String query,
    SearchOptions options,
  ) async {
    return _performSearchSync(text, query, options);
  }

  /// Synchronous search implementation
  SearchResult _performSearchSync(
    String text,
    String query,
    SearchOptions options,
  ) {
    try {
      RegExp pattern;

      if (options.useRegex) {
        // Use the query as a regex pattern
        pattern = RegExp(
          query,
          caseSensitive: options.caseSensitive,
          multiLine: true,
        );
      } else {
        // Escape special regex characters for literal search
        String escapedQuery = RegExp.escape(query);

        if (options.wholeWord) {
          // Add word boundary markers
          escapedQuery = r'\b' + escapedQuery + r'\b';
        }

        pattern = RegExp(
          escapedQuery,
          caseSensitive: options.caseSensitive,
          multiLine: true,
        );
      }

      final matches = <SearchMatch>[];
      final allMatches = pattern.allMatches(text);

      // Calculate line numbers and column positions
      final lines = text.split('\n');
      var lineStart = 0;
      var lineNumber = 1;

      for (final match in allMatches) {
        // Find which line this match is on
        while (lineStart + lines[lineNumber - 1].length < match.start && lineNumber <= lines.length) {
          lineStart += lines[lineNumber - 1].length + 1; // +1 for newline
          lineNumber++;
        }

        final columnPosition = match.start - lineStart;

        matches.add(SearchMatch(
          start: match.start,
          end: match.end,
          text: match.group(0) ?? '',
          lineNumber: lineNumber,
          columnPosition: columnPosition,
        ));
      }

      return SearchResult(
        query: query,
        matches: matches,
        activeMatchIndex: matches.isNotEmpty ? 0 : 0,
        caseSensitive: options.caseSensitive,
        wholeWord: options.wholeWord,
        useRegex: options.useRegex,
      );
    } catch (e) {
      return SearchResult.error(e.toString(), query: query);
    }
  }

  /// Update search result after a replacement to maintain consistency
  void _updateSearchAfterReplace(SearchMatch replacedMatch, String replacement) {
    if (!_currentResult.hasMatches) return;

    final lengthDifference = replacement.length - replacedMatch.length;
    final updatedMatches = <SearchMatch>[];

    for (int i = 0; i < _currentResult.matches.length; i++) {
      final match = _currentResult.matches[i];

      if (i == _currentResult.activeMatchIndex) {
        // Skip the replaced match
        continue;
      } else if (match.start > replacedMatch.start) {
        // Adjust positions for matches after the replacement
        updatedMatches.add(match.copyWith(
          start: match.start + lengthDifference,
          end: match.end + lengthDifference,
        ));
      } else {
        // Keep matches before the replacement unchanged
        updatedMatches.add(match);
      }
    }

    // Adjust active match index
    int newActiveIndex = _currentResult.activeMatchIndex;
    if (newActiveIndex >= updatedMatches.length) {
      newActiveIndex = updatedMatches.isEmpty ? 0 : updatedMatches.length - 1;
    }

    _currentResult = _currentResult.copyWith(
      matches: updatedMatches,
      activeMatchIndex: newActiveIndex,
    );

    notifyListeners();
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    super.dispose();
  }
}