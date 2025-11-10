import 'package:flutter_test/flutter_test.dart';
import 'package:markflow/features/markdown/models/search_result.dart';

void main() {
  group('SearchMatch', () {
    test('should create a search match with correct properties', () {
      const match = SearchMatch(
        start: 10,
        end: 15,
        text: 'hello',
        lineNumber: 2,
        columnPosition: 5,
      );

      expect(match.start, equals(10));
      expect(match.end, equals(15));
      expect(match.text, equals('hello'));
      expect(match.length, equals(5));
      expect(match.isActive, isFalse);
      expect(match.lineNumber, equals(2));
      expect(match.columnPosition, equals(5));
    });

    test('should create an active search match', () {
      const match = SearchMatch(
        start: 10,
        end: 15,
        text: 'hello',
        isActive: true,
        lineNumber: 2,
        columnPosition: 5,
      );

      expect(match.isActive, isTrue);
    });

    test('should create a copy with updated properties', () {
      const original = SearchMatch(
        start: 10,
        end: 15,
        text: 'hello',
        lineNumber: 2,
        columnPosition: 5,
      );

      final copy = original.copyWith(
        isActive: true,
        text: 'world',
      );

      expect(copy.start, equals(10));
      expect(copy.end, equals(15));
      expect(copy.text, equals('world'));
      expect(copy.isActive, isTrue);
      expect(copy.lineNumber, equals(2));
      expect(copy.columnPosition, equals(5));
    });

    test('should compare matches correctly', () {
      const match1 = SearchMatch(
        start: 10,
        end: 15,
        text: 'hello',
        lineNumber: 2,
        columnPosition: 5,
      );

      const match2 = SearchMatch(
        start: 10,
        end: 15,
        text: 'hello',
        lineNumber: 3, // Different line number shouldn't affect equality
        columnPosition: 6,
      );

      const match3 = SearchMatch(
        start: 11,
        end: 15,
        text: 'hello',
        lineNumber: 2,
        columnPosition: 5,
      );

      expect(match1, equals(match2));
      expect(match1, isNot(equals(match3)));
    });
  });

  group('SearchResult', () {
    test('should create an empty search result', () {
      const result = SearchResult.empty();

      expect(result.query, isEmpty);
      expect(result.matches, isEmpty);
      expect(result.matchCount, equals(0));
      expect(result.hasMatches, isFalse);
      expect(result.hasError, isFalse);
      expect(result.activeMatch, isNull);
      expect(result.activeMatchIndex, equals(0));
    });

    test('should create an error search result', () {
      const result = SearchResult.error('Invalid regex', query: 'test');

      expect(result.query, equals('test'));
      expect(result.matches, isEmpty);
      expect(result.hasError, isTrue);
      expect(result.error, equals('Invalid regex'));
    });

    test('should create a search result with matches', () {
      const matches = [
        SearchMatch(
          start: 0,
          end: 5,
          text: 'hello',
          lineNumber: 1,
          columnPosition: 0,
        ),
        SearchMatch(
          start: 10,
          end: 15,
          text: 'hello',
          lineNumber: 1,
          columnPosition: 10,
        ),
      ];

      const result = SearchResult(
        query: 'hello',
        matches: matches,
        caseSensitive: true,
        useRegex: false,
      );

      expect(result.query, equals('hello'));
      expect(result.matchCount, equals(2));
      expect(result.hasMatches, isTrue);
      expect(result.hasError, isFalse);
      expect(result.caseSensitive, isTrue);
      expect(result.useRegex, isFalse);
      expect(result.activeMatch, equals(matches.first));
      expect(result.activeMatchIndex, equals(0));
    });

    test('should get active match correctly', () {
      const matches = [
        SearchMatch(
          start: 0,
          end: 5,
          text: 'hello',
          lineNumber: 1,
          columnPosition: 0,
        ),
        SearchMatch(
          start: 10,
          end: 15,
          text: 'world',
          lineNumber: 1,
          columnPosition: 10,
        ),
      ];

      const result = SearchResult(
        query: 'test',
        matches: matches,
        activeMatchIndex: 1,
      );

      expect(result.activeMatch, equals(matches[1]));
    });

    test('should handle invalid active match index', () {
      const matches = [
        SearchMatch(
          start: 0,
          end: 5,
          text: 'hello',
          lineNumber: 1,
          columnPosition: 0,
        ),
      ];

      const result = SearchResult(
        query: 'test',
        matches: matches,
        activeMatchIndex: 5, // Invalid index
      );

      expect(result.activeMatch, isNull);
    });

    test('should get matches with active state', () {
      const matches = [
        SearchMatch(
          start: 0,
          end: 5,
          text: 'hello',
          lineNumber: 1,
          columnPosition: 0,
        ),
        SearchMatch(
          start: 10,
          end: 15,
          text: 'world',
          lineNumber: 1,
          columnPosition: 10,
        ),
      ];

      const result = SearchResult(
        query: 'test',
        matches: matches,
        activeMatchIndex: 1,
      );

      final matchesWithState = result.matchesWithActiveState;
      expect(matchesWithState[0].isActive, isFalse);
      expect(matchesWithState[1].isActive, isTrue);
    });

    test('should navigate to next match with wrapping', () {
      const matches = [
        SearchMatch(
          start: 0,
          end: 5,
          text: 'hello',
          lineNumber: 1,
          columnPosition: 0,
        ),
        SearchMatch(
          start: 10,
          end: 15,
          text: 'world',
          lineNumber: 1,
          columnPosition: 10,
        ),
      ];

      const result = SearchResult(
        query: 'test',
        matches: matches,
        activeMatchIndex: 0,
      );

      expect(result.nextMatchIndex, equals(1));

      final lastMatch = result.withActiveMatch(1);
      expect(lastMatch.nextMatchIndex, equals(0)); // Wraps around
    });

    test('should navigate to previous match with wrapping', () {
      const matches = [
        SearchMatch(
          start: 0,
          end: 5,
          text: 'hello',
          lineNumber: 1,
          columnPosition: 0,
        ),
        SearchMatch(
          start: 10,
          end: 15,
          text: 'world',
          lineNumber: 1,
          columnPosition: 10,
        ),
      ];

      const result = SearchResult(
        query: 'test',
        matches: matches,
        activeMatchIndex: 1,
      );

      expect(result.previousMatchIndex, equals(0));

      final firstMatch = result.withActiveMatch(0);
      expect(firstMatch.previousMatchIndex, equals(1)); // Wraps around
    });

    test('should create copy with updated properties', () {
      const original = SearchResult(
        query: 'hello',
        matches: [],
        caseSensitive: false,
      );

      final copy = original.copyWith(
        query: 'world',
        caseSensitive: true,
      );

      expect(copy.query, equals('world'));
      expect(copy.caseSensitive, isTrue);
      expect(copy.matches, equals(original.matches));
    });

    test('should create copy with different active match', () {
      const matches = [
        SearchMatch(
          start: 0,
          end: 5,
          text: 'hello',
          lineNumber: 1,
          columnPosition: 0,
        ),
        SearchMatch(
          start: 10,
          end: 15,
          text: 'world',
          lineNumber: 1,
          columnPosition: 10,
        ),
      ];

      const original = SearchResult(
        query: 'test',
        matches: matches,
        activeMatchIndex: 0,
      );

      final copy = original.withActiveMatch(1);
      expect(copy.activeMatchIndex, equals(1));
      expect(copy.activeMatch, equals(matches[1]));
    });

    test('should clamp active match index when creating copy', () {
      const matches = [
        SearchMatch(
          start: 0,
          end: 5,
          text: 'hello',
          lineNumber: 1,
          columnPosition: 0,
        ),
      ];

      const original = SearchResult(
        query: 'test',
        matches: matches,
        activeMatchIndex: 0,
      );

      final copy = original.withActiveMatch(10); // Out of bounds
      expect(copy.activeMatchIndex, equals(0)); // Clamped
    });
  });

  group('SearchOptions', () {
    test('should create default search options', () {
      const options = SearchOptions();

      expect(options.caseSensitive, isFalse);
      expect(options.wholeWord, isFalse);
      expect(options.useRegex, isFalse);
    });

    test('should create search options with custom values', () {
      const options = SearchOptions(
        caseSensitive: true,
        wholeWord: true,
        useRegex: true,
      );

      expect(options.caseSensitive, isTrue);
      expect(options.wholeWord, isTrue);
      expect(options.useRegex, isTrue);
    });

    test('should create copy with updated properties', () {
      const original = SearchOptions(caseSensitive: false);

      final copy = original.copyWith(caseSensitive: true, useRegex: true);

      expect(copy.caseSensitive, isTrue);
      expect(copy.wholeWord, equals(original.wholeWord));
      expect(copy.useRegex, isTrue);
    });

    test('should compare options correctly', () {
      const options1 = SearchOptions(
        caseSensitive: true,
        wholeWord: false,
      );

      const options2 = SearchOptions(
        caseSensitive: true,
        wholeWord: false,
      );

      const options3 = SearchOptions(
        caseSensitive: false,
        wholeWord: false,
      );

      expect(options1, equals(options2));
      expect(options1, isNot(equals(options3)));
    });
  });
}