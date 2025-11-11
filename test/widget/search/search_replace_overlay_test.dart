import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:markflow/features/markdown/widgets/search_replace_overlay.dart';
import 'package:markflow/features/markdown/models/search_result.dart';

void main() {
  group('SearchReplaceOverlay', () {
    late SearchResult mockSearchResult;
    late List<String> mockSearchHistory;
    late List<String> onSearchCalls;
    late List<String> onReplaceCurrentCalls;
    late List<String> onReplaceAllCalls;
    late int onNextCalls;
    late int onPreviousCalls;
    late int onCloseCalls;
    late List<int> onJumpToMatchCalls;

    setUp(() {
      mockSearchResult = const SearchResult(
        query: 'test',
        matches: [
          SearchMatch(
            start: 0,
            end: 4,
            text: 'test',
            lineNumber: 1,
            columnPosition: 0,
          ),
          SearchMatch(
            start: 10,
            end: 14,
            text: 'test',
            lineNumber: 1,
            columnPosition: 10,
          ),
        ],
        activeMatchIndex: 0,
      );

      mockSearchHistory = ['previous search', 'another search'];
      onSearchCalls = [];
      onReplaceCurrentCalls = [];
      onReplaceAllCalls = [];
      onNextCalls = 0;
      onPreviousCalls = 0;
      onCloseCalls = 0;
      onJumpToMatchCalls = [];
    });

    Widget createTestWidget({
      SearchResult? searchResult,
      List<String>? searchHistory,
      bool showReplace = true,
      String initialQuery = '',
    }) {
      return MaterialApp(
        home: Scaffold(
          body: SearchReplaceOverlay(
            onSearch: (query, options) {
              onSearchCalls.add(query);
            },
            onReplaceCurrent: (replacement) {
              onReplaceCurrentCalls.add(replacement);
            },
            onReplaceAll: (replacement) {
              onReplaceAllCalls.add(replacement);
            },
            onNext: () => onNextCalls++,
            onPrevious: () => onPreviousCalls++,
            onClose: () => onCloseCalls++,
            onJumpToMatch: (index) => onJumpToMatchCalls.add(index),
            searchResult: searchResult ?? mockSearchResult,
            searchHistory: searchHistory ?? mockSearchHistory,
            showReplace: showReplace,
            initialQuery: initialQuery,
          ),
        ),
      );
    }

    group('Basic Rendering', () {
      testWidgets('should render search overlay', (tester) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        expect(find.byType(SearchReplaceOverlay), findsOneWidget);
        expect(find.text('Search...'), findsOneWidget);
      });

      testWidgets('should show match counter when matches exist', (tester) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        expect(find.text('1 / 2'), findsOneWidget);
      });

      testWidgets('should show 0/0 when no matches', (tester) async {
        const emptyResult = SearchResult.empty();
        await tester.pumpWidget(createTestWidget(searchResult: emptyResult));
        await tester.pumpAndSettle();

        expect(find.text('0 / 0'), findsOneWidget);
      });

      testWidgets('should show error message when search fails', (tester) async {
        const errorResult = SearchResult.error('Invalid regex');
        await tester.pumpWidget(createTestWidget(searchResult: errorResult));
        await tester.pumpAndSettle();

        expect(find.text('Invalid regex'), findsOneWidget);
      });

      testWidgets('should have initial query when provided', (tester) async {
        await tester.pumpWidget(createTestWidget(initialQuery: 'hello'));
        await tester.pumpAndSettle();

        final searchField = find.widgetWithText(TextField, 'hello');
        expect(searchField, findsOneWidget);
      });
    });

    group('Search Functionality', () {
      testWidgets('should trigger search when typing', (tester) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        final searchField = find.byType(TextField).first;
        await tester.enterText(searchField, 'hello');
        await tester.pump(const Duration(milliseconds: 350)); // Wait for debounce

        expect(onSearchCalls, contains('hello'));
      });

      testWidgets('should clear search field', (tester) async {
        await tester.pumpWidget(createTestWidget(initialQuery: 'test'));
        await tester.pumpAndSettle();

        final clearButton = find.byIcon(Icons.clear);
        await tester.tap(clearButton);
        await tester.pumpAndSettle();

        final textField = tester.widget<TextField>(find.byType(TextField).first);
        expect(textField.controller?.text, isEmpty);
      });

      testWidgets('should show search history', (tester) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        final historyButton = find.byIcon(Icons.history);
        await tester.tap(historyButton);
        await tester.pumpAndSettle();

        expect(find.text('previous search'), findsOneWidget);
        expect(find.text('another search'), findsOneWidget);
      });

      testWidgets('should select from search history', (tester) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        // Open history
        final historyButton = find.byIcon(Icons.history);
        await tester.tap(historyButton);
        await tester.pumpAndSettle();

        // Tap on history item
        final historyItem = find.text('previous search');
        await tester.tap(historyItem);
        await tester.pumpAndSettle();

        expect(onSearchCalls, contains('previous search'));
      });
    });

    group('Navigation Controls', () {
      testWidgets('should navigate to next match', (tester) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        final nextButton = find.byIcon(Icons.keyboard_arrow_down);
        await tester.tap(nextButton);

        expect(onNextCalls, equals(1));
      });

      testWidgets('should navigate to previous match', (tester) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        final prevButton = find.byIcon(Icons.keyboard_arrow_up);
        await tester.tap(prevButton);

        expect(onPreviousCalls, equals(1));
      });

      testWidgets('should disable navigation when no matches', (tester) async {
        const emptyResult = SearchResult.empty();
        await tester.pumpWidget(createTestWidget(searchResult: emptyResult));
        await tester.pumpAndSettle();

        final nextButton = find.byIcon(Icons.keyboard_arrow_down);
        final prevButton = find.byIcon(Icons.keyboard_arrow_up);

        // Buttons should be disabled
        final nextWidget = tester.widget<IconButton>(nextButton);
        final prevWidget = tester.widget<IconButton>(prevButton);

        expect(nextWidget.onPressed, isNull);
        expect(prevWidget.onPressed, isNull);
      });
    });

    group('Search Options', () {
      testWidgets('should toggle case sensitivity', (tester) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        final caseButton = find.byIcon(Icons.search);
        await tester.tap(caseButton);
        await tester.pumpAndSettle();

        // Should trigger a new search with case sensitivity enabled
        expect(onSearchCalls, isNotEmpty);
      });

      testWidgets('should toggle whole word search', (tester) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        final wholeWordButton = find.byIcon(Icons.crop_free);
        await tester.tap(wholeWordButton);
        await tester.pumpAndSettle();

        expect(onSearchCalls, isNotEmpty);
      });

      testWidgets('should toggle regex search', (tester) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        final regexButton = find.text('.*');
        await tester.tap(regexButton);
        await tester.pumpAndSettle();

        expect(onSearchCalls, isNotEmpty);
      });
    });

    group('Replace Functionality', () {
      testWidgets('should expand replace section', (tester) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        final expandButton = find.byIcon(Icons.unfold_more);
        await tester.tap(expandButton);
        await tester.pumpAndSettle();

        expect(find.text('Replace with...'), findsOneWidget);
        expect(find.text('Replace'), findsOneWidget);
        expect(find.text('All'), findsOneWidget);
      });

      testWidgets('should perform replace current', (tester) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        // Expand replace section
        final expandButton = find.byIcon(Icons.unfold_more);
        await tester.tap(expandButton);
        await tester.pumpAndSettle();

        // Enter replacement text
        final replaceField = find.widgetWithText(TextField, 'Replace with...');
        await tester.enterText(replaceField, 'replacement');
        await tester.pumpAndSettle();

        // Tap replace button
        final replaceButton = find.text('Replace');
        await tester.tap(replaceButton);

        expect(onReplaceCurrentCalls, contains('replacement'));
      });

      testWidgets('should perform replace all', (tester) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        // Expand replace section
        final expandButton = find.byIcon(Icons.unfold_more);
        await tester.tap(expandButton);
        await tester.pumpAndSettle();

        // Enter replacement text
        final replaceField = find.widgetWithText(TextField, 'Replace with...');
        await tester.enterText(replaceField, 'replacement');
        await tester.pumpAndSettle();

        // Tap replace all button
        final replaceAllButton = find.text('All');
        await tester.tap(replaceAllButton);

        expect(onReplaceAllCalls, contains('replacement'));
      });

      testWidgets('should disable replace buttons when no matches', (tester) async {
        const emptyResult = SearchResult.empty();
        await tester.pumpWidget(createTestWidget(searchResult: emptyResult));
        await tester.pumpAndSettle();

        // Expand replace section
        final expandButton = find.byIcon(Icons.unfold_more);
        await tester.tap(expandButton);
        await tester.pumpAndSettle();

        // Replace buttons should be disabled
        final replaceButton = find.widgetWithText(ElevatedButton, 'Replace');
        final replaceAllButton = find.widgetWithText(ElevatedButton, 'All');

        expect(replaceButton, findsNothing); // Buttons don't exist when disabled
        expect(replaceAllButton, findsNothing);
      });

      testWidgets('should hide replace section when showReplace is false', (tester) async {
        await tester.pumpWidget(createTestWidget(showReplace: false));
        await tester.pumpAndSettle();

        expect(find.byIcon(Icons.unfold_more), findsNothing);
      });
    });

    group('Close Functionality', () {
      testWidgets('should close overlay', (tester) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        final closeButton = find.byIcon(Icons.close);
        await tester.tap(closeButton);

        expect(onCloseCalls, equals(1));
      });
    });

    group('Keyboard Shortcuts', () {
      testWidgets('should handle Enter key in search field', (tester) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        final searchField = find.byType(TextField).first;
        await tester.enterText(searchField, 'hello');
        await tester.testTextInput.receiveAction(TextInputAction.search);
        await tester.pumpAndSettle();

        expect(onSearchCalls, contains('hello'));
      });

      testWidgets('should handle Enter key in replace field', (tester) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        // Expand replace section
        final expandButton = find.byIcon(Icons.unfold_more);
        await tester.tap(expandButton);
        await tester.pumpAndSettle();

        final replaceField = find.widgetWithText(TextField, 'Replace with...');
        await tester.enterText(replaceField, 'replacement');
        await tester.testTextInput.receiveAction(TextInputAction.done);
        await tester.pumpAndSettle();

        expect(onReplaceAllCalls, contains('replacement'));
      });
    });

    group('Animation', () {
      testWidgets('should animate in', (tester) async {
        await tester.pumpWidget(createTestWidget());

        // Animation should start
        await tester.pump();

        // Complete animation
        await tester.pumpAndSettle();

        expect(find.byType(SearchReplaceOverlay), findsOneWidget);
      });
    });
  });

  group('MobileSearchOverlay', () {
    late SearchResult mockSearchResult;
    late List<String> mockSearchHistory;

    setUp(() {
      mockSearchResult = const SearchResult(
        query: 'test',
        matches: [
          SearchMatch(
            start: 0,
            end: 4,
            text: 'test',
            lineNumber: 1,
            columnPosition: 0,
          ),
        ],
        activeMatchIndex: 0,
      );
      mockSearchHistory = ['previous search'];
    });

    Widget createMobileTestWidget({
      SearchResult? searchResult,
      List<String>? searchHistory,
    }) {
      return MaterialApp(
        home: Scaffold(
          body: MobileSearchOverlay(
            onSearch: (query, options) {},
            onReplaceCurrent: (replacement) {},
            onReplaceAll: (replacement) {},
            onNext: () {},
            onPrevious: () {},
            onClose: () {},
            onJumpToMatch: (index) {},
            searchResult: searchResult ?? mockSearchResult,
            searchHistory: searchHistory ?? mockSearchHistory,
          ),
        ),
      );
    }

    testWidgets('should render mobile search overlay', (tester) async {
      await tester.pumpWidget(createMobileTestWidget());
      await tester.pumpAndSettle();

      expect(find.byType(MobileSearchOverlay), findsOneWidget);
      expect(find.text('Search...'), findsOneWidget);
    });

    testWidgets('should show handle bar', (tester) async {
      await tester.pumpWidget(createMobileTestWidget());
      await tester.pumpAndSettle();

      // Handle bar should be present (container with specific dimensions)
      final handleBar = find.byWidgetPredicate(
        (widget) => widget is Container &&
                    widget.decoration != null,
      );
      expect(handleBar, findsWidgets);
    });

    testWidgets('should toggle replace mode', (tester) async {
      await tester.pumpWidget(createMobileTestWidget());
      await tester.pumpAndSettle();

      final toggleButton = find.text('Replace');
      await tester.tap(toggleButton);
      await tester.pumpAndSettle();

      expect(find.text('Replace with...'), findsOneWidget);
      expect(find.text('Search'), findsOneWidget); // Button text should change
    });

    testWidgets('should show match counter', (tester) async {
      await tester.pumpWidget(createMobileTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('1 / 1'), findsOneWidget);
    });

    testWidgets('should animate slide up', (tester) async {
      await tester.pumpWidget(createMobileTestWidget());

      // Animation should start
      await tester.pump();

      // Complete animation
      await tester.pumpAndSettle();

      expect(find.byType(MobileSearchOverlay), findsOneWidget);
    });
  });
}