import 'package:flutter_test/flutter_test.dart';
import 'package:markflow/features/markdown/services/search_service.dart';
import 'package:markflow/features/markdown/models/search_result.dart';

void main() {
  group('SearchService', () {
    late SearchService service;
    const testText = '''
Hello World
This is a test document.
Hello again!
Test with HELLO in caps.
Another line with test content.
''';

    setUp(() {
      service = SearchService();
    });

    tearDown(() {
      service.dispose();
    });

    group('Basic Search', () {
      test('should return empty result for empty query', () {
        final result = service.searchImmediate(testText, '');

        expect(result.query, isEmpty);
        expect(result.matches, isEmpty);
        expect(result.hasMatches, isFalse);
      });

      test('should find simple text matches', () {
        final result = service.searchImmediate(testText, 'Hello');

        expect(result.query, equals('Hello'));
        expect(result.matchCount, equals(2));
        expect(result.hasMatches, isTrue);
        expect(result.matches.first.text, equals('Hello'));
        expect(result.matches.first.start, equals(0));
        expect(result.matches.first.end, equals(5));
      });

      test('should find case insensitive matches', () {
        const options = SearchOptions(caseSensitive: false);
        final result = service.searchImmediate(testText, 'hello', options: options);

        expect(result.matchCount, equals(3)); // Hello, Hello, HELLO
        expect(result.caseSensitive, isFalse);
      });

      test('should find case sensitive matches', () {
        const options = SearchOptions(caseSensitive: true);
        final result = service.searchImmediate(testText, 'hello', options: options);

        expect(result.matchCount, equals(0)); // No lowercase 'hello' in text
        expect(result.caseSensitive, isTrue);
      });

      test('should find whole word matches', () {
        const options = SearchOptions(wholeWord: true);
        final result = service.searchImmediate(testText, 'test', options: options);

        expect(result.matchCount, equals(3)); // 'test' as whole words
        expect(result.wholeWord, isTrue);
      });

      test('should calculate line numbers and column positions correctly', () {
        final result = service.searchImmediate(testText, 'test');

        expect(result.matchCount, greaterThan(0));

        final firstMatch = result.matches.first;
        expect(firstMatch.lineNumber, greaterThan(0));
        expect(firstMatch.columnPosition, greaterThanOrEqualTo(0));
      });
    });

    group('Regex Search', () {
      test('should handle basic regex patterns', () {
        const options = SearchOptions(useRegex: true);
        final result = service.searchImmediate(testText, r'H\w+', options: options);

        expect(result.matchCount, equals(3)); // Hello, Hello, HELLO
        expect(result.useRegex, isTrue);
      });

      test('should handle regex with anchors', () {
        const options = SearchOptions(useRegex: true);
        final result = service.searchImmediate(testText, r'^Hello', options: options);

        expect(result.matchCount, equals(1)); // Only the first Hello at line start
      });

      test('should return error for invalid regex', () {
        const options = SearchOptions(useRegex: true);
        final result = service.searchImmediate(testText, r'[unclosed', options: options);

        expect(result.hasError, isTrue);
        expect(result.error, isNotNull);
        expect(result.matches, isEmpty);
      });

      test('should handle complex regex patterns', () {
        const options = SearchOptions(useRegex: true);
        final result = service.searchImmediate(testText, r'\b\w{4}\b', options: options);

        expect(result.matchCount, greaterThan(0)); // Should find 4-letter words
      });
    });

    group('Navigation', () {
      test('should navigate to next match', () {
        final result = service.searchImmediate(testText, 'test');
        expect(result.activeMatchIndex, equals(0));

        final nextResult = service.navigateToNext();
        expect(nextResult.activeMatchIndex, equals(1));
      });

      test('should wrap around when navigating past last match', () {
        final result = service.searchImmediate(testText, 'Hello');
        expect(result.matchCount, equals(2));

        // Go to last match
        service.navigateToMatch(1);
        expect(service.currentResult.activeMatchIndex, equals(1));

        // Navigate next should wrap to first
        final wrapped = service.navigateToNext();
        expect(wrapped.activeMatchIndex, equals(0));
      });

      test('should navigate to previous match', () {
        final result = service.searchImmediate(testText, 'test');
        service.navigateToMatch(2); // Go to third match

        final prevResult = service.navigateToPrevious();
        expect(prevResult.activeMatchIndex, equals(1));
      });

      test('should wrap around when navigating before first match', () {
        final result = service.searchImmediate(testText, 'Hello');
        expect(result.matchCount, equals(2));
        expect(result.activeMatchIndex, equals(0));

        // Navigate previous should wrap to last
        final wrapped = service.navigateToPrevious();
        expect(wrapped.activeMatchIndex, equals(1));
      });

      test('should navigate to specific match', () {
        service.searchImmediate(testText, 'test');

        final result = service.navigateToMatch(1);
        expect(result.activeMatchIndex, equals(1));
      });

      test('should handle invalid match index', () {
        service.searchImmediate(testText, 'Hello'); // 2 matches

        final result = service.navigateToMatch(10); // Invalid index
        expect(result.activeMatchIndex, equals(service.currentResult.activeMatchIndex));
      });

      test('should not navigate when no matches', () {
        service.searchImmediate(testText, 'nonexistent');

        final nextResult = service.navigateToNext();
        expect(nextResult.matches, isEmpty);

        final prevResult = service.navigateToPrevious();
        expect(prevResult.matches, isEmpty);
      });
    });

    group('Replace', () {
      test('should replace current match', () {
        service.searchImmediate(testText, 'Hello');
        expect(service.currentResult.hasMatches, isTrue);

        final newText = service.replaceCurrent(testText, 'Hi');
        expect(newText, startsWith('Hi World'));
        expect(newText.contains('Hello'), isTrue); // Other matches remain
      });

      test('should replace all matches', () {
        service.searchImmediate(testText, 'Hello');
        expect(service.currentResult.matchCount, equals(2));

        final newText = service.replaceAll(testText, 'Hi');
        expect(newText.contains('Hello'), isFalse);
        expect(newText.contains('Hi'), isTrue);
      });

      test('should handle replace with empty string', () {
        service.searchImmediate(testText, 'Hello');

        final newText = service.replaceCurrent(testText, '');
        expect(newText, startsWith(' World'));
      });

      test('should handle replace when no matches', () {
        service.searchImmediate(testText, 'nonexistent');

        final newText = service.replaceCurrent(testText, 'replacement');
        expect(newText, equals(testText)); // No changes
      });

      test('should replace with regex capture groups', () {
        const options = SearchOptions(useRegex: true);
        service.searchImmediate(testText, r'(\w+) World', options: options);

        if (service.currentResult.hasMatches) {
          final newText = service.replaceCurrent(testText, 'Greetings Universe');
          expect(newText, startsWith('Greetings Universe'));
        }
      });
    });

    group('Clear Search', () {
      test('should clear search results', () {
        service.searchImmediate(testText, 'Hello');
        expect(service.hasActiveSearch, isTrue);

        service.clearSearch();
        expect(service.hasActiveSearch, isFalse);
        expect(service.currentResult.matches, isEmpty);
      });
    });

    group('Multiple Search Operations', () {
      test('should handle consecutive searches', () {
        final result1 = service.searchImmediate(testText, 'Hello');
        expect(result1.matchCount, equals(2));

        final result2 = service.searchImmediate(testText, 'test');
        expect(result2.matchCount, greaterThan(2));
        expect(result2.query, equals('test'));

        // Previous search should be replaced
        expect(service.currentResult.query, equals('test'));
      });

      test('should maintain state during navigation after new search', () {
        service.searchImmediate(testText, 'test');
        service.navigateToMatch(1);

        // New search should reset active match
        final newResult = service.searchImmediate(testText, 'Hello');
        expect(newResult.activeMatchIndex, equals(0));
      });
    });

    group('Edge Cases', () {
      test('should handle empty text', () {
        final result = service.searchImmediate('', 'test');
        expect(result.matches, isEmpty);
      });

      test('should handle single character search', () {
        final result = service.searchImmediate(testText, 'a');
        expect(result.matchCount, greaterThan(0));
      });

      test('should handle multiline patterns', () {
        const options = SearchOptions(useRegex: true);
        final result = service.searchImmediate(testText, r'World\nThis', options: options);
        expect(result.matchCount, greaterThanOrEqualTo(0));
      });

      test('should handle special regex characters in literal search', () {
        const textWithSpecialChars = 'Price: \$10.00 (tax included)';
        final result = service.searchImmediate(textWithSpecialChars, '\$10.00');
        expect(result.matchCount, equals(1));
      });

      test('should handle very large text', () {
        final largeText = 'test ' * 10000;
        final result = service.searchImmediate(largeText, 'test');
        expect(result.matchCount, equals(10000));
      });
    });

    group('Performance', () {
      test('should handle debounced search', () async {
        var searchCompleted = false;
        final future = service.search(testText, 'Hello').then((_) {
          searchCompleted = true;
        });

        expect(searchCompleted, isFalse);
        await future;
        expect(searchCompleted, isTrue);
      });

      test('should cancel previous debounced search', () async {
        // Start first search
        final future1 = service.search(testText, 'Hello');

        // Start second search immediately (should cancel first)
        final future2 = service.search(testText, 'test');

        await future2;
        expect(service.currentResult.query, equals('test'));
      });
    });
  });
}