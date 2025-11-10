/// Represents a single search match result in the text
class SearchMatch {
  /// The start position of the match in the text
  final int start;

  /// The end position of the match in the text
  final int end;

  /// The matched text content
  final String text;

  /// Whether this is the currently active/selected match
  final bool isActive;

  /// Line number where this match occurs (1-based)
  final int lineNumber;

  /// Column position in the line where this match starts (0-based)
  final int columnPosition;

  const SearchMatch({
    required this.start,
    required this.end,
    required this.text,
    this.isActive = false,
    required this.lineNumber,
    required this.columnPosition,
  });

  /// Length of the matched text
  int get length => end - start;

  /// Create a copy of this match with updated properties
  SearchMatch copyWith({
    int? start,
    int? end,
    String? text,
    bool? isActive,
    int? lineNumber,
    int? columnPosition,
  }) {
    return SearchMatch(
      start: start ?? this.start,
      end: end ?? this.end,
      text: text ?? this.text,
      isActive: isActive ?? this.isActive,
      lineNumber: lineNumber ?? this.lineNumber,
      columnPosition: columnPosition ?? this.columnPosition,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SearchMatch &&
          runtimeType == other.runtimeType &&
          start == other.start &&
          end == other.end &&
          text == other.text;

  @override
  int get hashCode => start.hashCode ^ end.hashCode ^ text.hashCode;

  @override
  String toString() {
    return 'SearchMatch(start: $start, end: $end, text: "$text", line: $lineNumber, col: $columnPosition)';
  }
}

/// Contains all search results for a search query
class SearchResult {
  /// The search query that generated these results
  final String query;

  /// List of all matches found
  final List<SearchMatch> matches;

  /// The currently active/selected match index (0-based)
  final int activeMatchIndex;

  /// Whether the search was case sensitive
  final bool caseSensitive;

  /// Whether the search matched whole words only
  final bool wholeWord;

  /// Whether the search used regex
  final bool useRegex;

  /// Error message if the search failed (e.g., invalid regex)
  final String? error;

  const SearchResult({
    required this.query,
    required this.matches,
    this.activeMatchIndex = 0,
    this.caseSensitive = false,
    this.wholeWord = false,
    this.useRegex = false,
    this.error,
  });

  /// Create an empty search result
  const SearchResult.empty()
      : query = '',
        matches = const [],
        activeMatchIndex = 0,
        caseSensitive = false,
        wholeWord = false,
        useRegex = false,
        error = null;

  /// Create a search result with an error
  const SearchResult.error(String error, {String query = ''})
      : query = query,
        matches = const [],
        activeMatchIndex = 0,
        caseSensitive = false,
        wholeWord = false,
        useRegex = false,
        error = error;

  /// Total number of matches found
  int get matchCount => matches.length;

  /// Whether there are any matches
  bool get hasMatches => matches.isNotEmpty;

  /// Whether there's an error
  bool get hasError => error != null;

  /// Get the currently active match, if any
  SearchMatch? get activeMatch {
    if (matches.isEmpty || activeMatchIndex < 0 || activeMatchIndex >= matches.length) {
      return null;
    }
    return matches[activeMatchIndex];
  }

  /// Get matches with updated active state
  List<SearchMatch> get matchesWithActiveState {
    return matches.asMap().entries.map((entry) {
      return entry.value.copyWith(isActive: entry.key == activeMatchIndex);
    }).toList();
  }

  /// Create a copy of this result with updated properties
  SearchResult copyWith({
    String? query,
    List<SearchMatch>? matches,
    int? activeMatchIndex,
    bool? caseSensitive,
    bool? wholeWord,
    bool? useRegex,
    String? error,
  }) {
    return SearchResult(
      query: query ?? this.query,
      matches: matches ?? this.matches,
      activeMatchIndex: activeMatchIndex ?? this.activeMatchIndex,
      caseSensitive: caseSensitive ?? this.caseSensitive,
      wholeWord: wholeWord ?? this.wholeWord,
      useRegex: useRegex ?? this.useRegex,
      error: error ?? this.error,
    );
  }

  /// Create a copy with a different active match index
  SearchResult withActiveMatch(int newActiveIndex) {
    if (matches.isEmpty) return this;
    final clampedIndex = newActiveIndex.clamp(0, matches.length - 1);
    return copyWith(activeMatchIndex: clampedIndex);
  }

  /// Get the next match index (wraps around)
  int get nextMatchIndex {
    if (matches.isEmpty) return 0;
    return (activeMatchIndex + 1) % matches.length;
  }

  /// Get the previous match index (wraps around)
  int get previousMatchIndex {
    if (matches.isEmpty) return 0;
    return activeMatchIndex == 0 ? matches.length - 1 : activeMatchIndex - 1;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SearchResult &&
          runtimeType == other.runtimeType &&
          query == other.query &&
          matches == other.matches &&
          activeMatchIndex == other.activeMatchIndex &&
          caseSensitive == other.caseSensitive &&
          wholeWord == other.wholeWord &&
          useRegex == other.useRegex &&
          error == other.error;

  @override
  int get hashCode => Object.hash(
        query,
        matches,
        activeMatchIndex,
        caseSensitive,
        wholeWord,
        useRegex,
        error,
      );

  @override
  String toString() {
    return 'SearchResult(query: "$query", matches: ${matches.length}, active: $activeMatchIndex, error: $error)';
  }
}

/// Options for configuring search behavior
class SearchOptions {
  /// Whether the search should be case sensitive
  final bool caseSensitive;

  /// Whether to match whole words only
  final bool wholeWord;

  /// Whether to use regex pattern matching
  final bool useRegex;

  const SearchOptions({
    this.caseSensitive = false,
    this.wholeWord = false,
    this.useRegex = false,
  });

  /// Create a copy of these options with updated properties
  SearchOptions copyWith({
    bool? caseSensitive,
    bool? wholeWord,
    bool? useRegex,
  }) {
    return SearchOptions(
      caseSensitive: caseSensitive ?? this.caseSensitive,
      wholeWord: wholeWord ?? this.wholeWord,
      useRegex: useRegex ?? this.useRegex,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SearchOptions &&
          runtimeType == other.runtimeType &&
          caseSensitive == other.caseSensitive &&
          wholeWord == other.wholeWord &&
          useRegex == other.useRegex;

  @override
  int get hashCode => Object.hash(caseSensitive, wholeWord, useRegex);

  @override
  String toString() {
    return 'SearchOptions(caseSensitive: $caseSensitive, wholeWord: $wholeWord, useRegex: $useRegex)';
  }
}