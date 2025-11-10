import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:markflow/features/markdown/services/auto_complete_service.dart';
import 'package:markflow/features/markdown/models/completion_suggestion.dart';
import 'package:markflow/features/markdown/providers/completion_provider.dart';

/// Mock completion provider for testing
class MockCompletionProvider extends Mock implements CompletionProvider {
  @override
  String get name => 'Mock Provider';

  @override
  int get priority => 5;

  @override
  bool shouldActivate(CompletionContext context) => true;

  @override
  Future<List<CompletionSuggestion>> getSuggestions(CompletionContext context) async {
    return [
      const CompletionSuggestion(
        insertText: 'mock suggestion',
        displayText: 'Mock Suggestion',
        type: CompletionType.customShortcut,
        priority: 5,
      ),
    ];
  }
}

void main() {
  group('AutoCompleteService', () {
    late AutoCompleteService service;
    late MockCompletionProvider mockProvider;

    setUpAll(() {
      // Initialize shared preferences with mock data
      SharedPreferences.setMockInitialValues({});
    });

    setUp(() {
      service = AutoCompleteService();
      mockProvider = MockCompletionProvider();
      service.initialize([mockProvider]);
    });

    tearDown(() {
      service.dispose();
    });

    group('Initialization', () {
      test('initializes with default settings', () {
        expect(service.isEnabled, isTrue);
        expect(service.autoTriggerEnabled, isTrue);
        expect(service.suggestionDelay, equals(300));
        expect(service.maxSuggestions, equals(10));
        expect(service.triggerCharacters, contains('#'));
        expect(service.triggerCharacters, contains('*'));
        expect(service.triggerCharacters, contains('-'));
      });

      test('initializes with providers', () {
        final testProvider = MockCompletionProvider();
        final testService = AutoCompleteService();
        testService.initialize([testProvider]);

        // Provider should be added
        expect(testService, isNotNull);
        testService.dispose();
      });
    });

    group('Settings Management', () {
      test('updates settings correctly', () async {
        await service.updateSettings(
          enabled: false,
          autoTrigger: false,
          delay: 500,
          maxSuggestions: 5,
          triggerCharacters: {'#'},
        );

        expect(service.isEnabled, isFalse);
        expect(service.autoTriggerEnabled, isFalse);
        expect(service.suggestionDelay, equals(500));
        expect(service.maxSuggestions, equals(5));
        expect(service.triggerCharacters, equals({'#'}));
      });

      test('notifies listeners on settings change', () async {
        var notified = false;
        service.addListener(() {
          notified = true;
        });

        await service.updateSettings(enabled: false);
        expect(notified, isTrue);
      });
    });

    group('Completion Context', () {
      test('creates context from text and position', () {
        const text = 'Hello\n# Heading\nMore text';
        const position = 15; // Position at 'g' in 'Heading'

        final context = CompletionContext.fromTextAndPosition(text, position);

        expect(context.text, equals(text));
        expect(context.cursorPosition, equals(position));
        expect(context.textBeforeCursor, equals('Hello\n# Headin'));
        expect(context.textAfterCursor, equals('g\nMore text'));
        expect(context.lineNumber, equals(1));
        expect(context.currentLine, equals('# Heading'));
        expect(context.isStartOfLine, isFalse);
      });

      test('detects start of line correctly', () {
        const text = 'Line 1\n\n# ';
        const position = 10; // Position after '# '

        final context = CompletionContext.fromTextAndPosition(text, position);

        expect(context.isStartOfLine, isFalse);
        expect(context.currentLine, equals('# '));
      });

      test('detects code blocks', () {
        const text = 'Text\n```\ncode\n';
        const position = 12; // Inside code block

        final context = CompletionContext.fromTextAndPosition(text, position);

        expect(context.isInCodeBlock, isTrue);
      });
    });

    group('Trigger Characters', () {
      test('identifies trigger characters correctly', () {
        expect(service.shouldTriggerCompletion('#'), isTrue);
        expect(service.shouldTriggerCompletion('*'), isTrue);
        expect(service.shouldTriggerCompletion('a'), isFalse);
      });

      test('respects enabled setting for triggers', () async {
        await service.updateSettings(enabled: false);
        expect(service.shouldTriggerCompletion('#'), isFalse);
      });

      test('respects auto-trigger setting', () async {
        await service.updateSettings(autoTrigger: false);
        expect(service.shouldTriggerCompletion('#'), isFalse);
      });
    });

    group('Completion Requests', () {
      test('requests completions and updates result', () async {
        var resultUpdated = false;
        service.addListener(() {
          resultUpdated = true;
        });

        service.requestCompletionsImmediate('# Test', 6);

        // Wait for debounced completion
        await Future.delayed(const Duration(milliseconds: 100));

        expect(resultUpdated, isTrue);
        expect(service.currentResult.isActive, isTrue);
        expect(service.currentResult.suggestions.isNotEmpty, isTrue);
      });

      test('filters suggestions based on context', () async {
        service.requestCompletionsImmediate('mock', 4);
        await Future.delayed(const Duration(milliseconds: 100));

        final result = service.currentResult;
        expect(result.suggestions.isNotEmpty, isTrue);
        // Should contain our mock suggestion
        expect(result.suggestions.any((s) => s.displayText == 'Mock Suggestion'), isTrue);
      });

      test('limits suggestions to maxSuggestions', () async {
        await service.updateSettings(maxSuggestions: 1);

        // Create multiple mock suggestions
        when(mockProvider.getSuggestions(any)).thenAnswer((_) async => [
          const CompletionSuggestion(
            insertText: 'suggestion1',
            displayText: 'Suggestion 1',
            type: CompletionType.customShortcut,
          ),
          const CompletionSuggestion(
            insertText: 'suggestion2',
            displayText: 'Suggestion 2',
            type: CompletionType.customShortcut,
          ),
        ]);

        service.requestCompletionsImmediate('test', 4);
        await Future.delayed(const Duration(milliseconds: 100));

        expect(service.currentResult.suggestions.length, equals(1));
      });

      test('disabled service returns no suggestions', () async {
        await service.updateSettings(enabled: false);

        service.requestCompletionsImmediate('# Test', 6);
        await Future.delayed(const Duration(milliseconds: 100));

        expect(service.currentResult.isActive, isFalse);
        expect(service.currentResult.suggestions.isEmpty, isTrue);
      });
    });

    group('Suggestion Navigation', () {
      setUp(() async {
        // Set up some test suggestions
        when(mockProvider.getSuggestions(any)).thenAnswer((_) async => [
          const CompletionSuggestion(
            insertText: 'first',
            displayText: 'First',
            type: CompletionType.customShortcut,
          ),
          const CompletionSuggestion(
            insertText: 'second',
            displayText: 'Second',
            type: CompletionType.customShortcut,
          ),
          const CompletionSuggestion(
            insertText: 'third',
            displayText: 'Third',
            type: CompletionType.customShortcut,
          ),
        ]);

        service.requestCompletionsImmediate('test', 4);
        await Future.delayed(const Duration(milliseconds: 100));
      });

      test('selects next suggestion', () {
        expect(service.currentResult.selectedIndex, equals(0));

        service.selectNext();
        expect(service.currentResult.selectedIndex, equals(1));

        service.selectNext();
        expect(service.currentResult.selectedIndex, equals(2));

        // Should wrap around
        service.selectNext();
        expect(service.currentResult.selectedIndex, equals(0));
      });

      test('selects previous suggestion', () {
        expect(service.currentResult.selectedIndex, equals(0));

        // Should wrap to last
        service.selectPrevious();
        expect(service.currentResult.selectedIndex, equals(2));

        service.selectPrevious();
        expect(service.currentResult.selectedIndex, equals(1));
      });

      test('selects suggestion by index', () {
        service.selectSuggestion(2);
        expect(service.currentResult.selectedIndex, equals(2));

        // Invalid index should be ignored
        service.selectSuggestion(10);
        expect(service.currentResult.selectedIndex, equals(2));
      });
    });

    group('Suggestion Application', () {
      test('applies suggestion correctly', () async {
        const suggestion = CompletionSuggestion(
          insertText: '# Heading',
          displayText: '# Heading',
          type: CompletionType.header,
        );

        // Set up context
        service.requestCompletionsImmediate('# ', 2);
        await Future.delayed(const Duration(milliseconds: 100));

        final application = service.applySuggestion(suggestion);

        expect(application, isNotNull);
        expect(application!.insertText, equals('# Heading'));
        expect(application.replaceStart, equals(0));
        expect(application.replaceLength, equals(2));
      });

      test('applies selected suggestion', () async {
        when(mockProvider.getSuggestions(any)).thenAnswer((_) async => [
          const CompletionSuggestion(
            insertText: '# Heading',
            displayText: '# Heading',
            type: CompletionType.header,
          ),
        ]);

        service.requestCompletionsImmediate('# ', 2);
        await Future.delayed(const Duration(milliseconds: 100));

        final application = service.applySelectedSuggestion();

        expect(application, isNotNull);
        expect(application!.insertText, equals('# Heading'));
      });

      test('records usage statistics', () async {
        const suggestion = CompletionSuggestion(
          insertText: '# Heading',
          displayText: '# Heading',
          type: CompletionType.header,
        );

        service.requestCompletionsImmediate('# ', 2);
        await Future.delayed(const Duration(milliseconds: 100));

        service.applySuggestion(suggestion);

        expect(service.usageStats['# Heading'], equals(1));
      });

      test('clears completions after application', () async {
        const suggestion = CompletionSuggestion(
          insertText: '# Heading',
          displayText: '# Heading',
          type: CompletionType.header,
        );

        service.requestCompletionsImmediate('# ', 2);
        await Future.delayed(const Duration(milliseconds: 100));

        expect(service.currentResult.isActive, isTrue);

        service.applySuggestion(suggestion);

        expect(service.currentResult.isActive, isFalse);
      });
    });

    group('Custom Shortcuts', () {
      test('adds custom shortcut', () async {
        const shortcut = CompletionSuggestion(
          shortcutKey: 'test',
          insertText: 'Test shortcut',
          displayText: 'Test Shortcut',
          type: CompletionType.customShortcut,
        );

        await service.addCustomShortcut(shortcut);

        expect(service.customShortcuts, contains(shortcut));
      });

      test('removes custom shortcut', () async {
        const shortcut = CompletionSuggestion(
          shortcutKey: 'test',
          insertText: 'Test shortcut',
          displayText: 'Test Shortcut',
          type: CompletionType.customShortcut,
        );

        await service.addCustomShortcut(shortcut);
        expect(service.customShortcuts, contains(shortcut));

        await service.removeCustomShortcut(shortcut);
        expect(service.customShortcuts, isNot(contains(shortcut)));
      });

      test('includes custom shortcuts in suggestions', () async {
        const shortcut = CompletionSuggestion(
          shortcutKey: 'test',
          insertText: 'Test shortcut',
          displayText: 'Test Shortcut',
          type: CompletionType.customShortcut,
        );

        await service.addCustomShortcut(shortcut);

        service.requestCompletionsImmediate('tes', 3);
        await Future.delayed(const Duration(milliseconds: 100));

        final result = service.currentResult;
        expect(result.suggestions.any((s) => s.shortcutKey == 'test'), isTrue);
      });
    });

    group('Usage Statistics', () {
      test('tracks usage statistics', () async {
        const suggestion = CompletionSuggestion(
          insertText: 'test',
          displayText: 'Test',
          type: CompletionType.customShortcut,
        );

        // Apply the same suggestion multiple times
        service.requestCompletionsImmediate('', 0);
        await Future.delayed(const Duration(milliseconds: 100));

        service.applySuggestion(suggestion);
        service.applySuggestion(suggestion);
        service.applySuggestion(suggestion);

        expect(service.usageStats['Test'], equals(3));
      });

      test('resets usage statistics', () async {
        const suggestion = CompletionSuggestion(
          insertText: 'test',
          displayText: 'Test',
          type: CompletionType.customShortcut,
        );

        service.requestCompletionsImmediate('', 0);
        await Future.delayed(const Duration(milliseconds: 100));

        service.applySuggestion(suggestion);
        expect(service.usageStats['Test'], equals(1));

        await service.resetUsageStats();
        expect(service.usageStats.isEmpty, isTrue);
      });
    });

    group('Completion Result', () {
      test('empty result has no suggestions', () {
        const result = CompletionResult.empty;

        expect(result.isActive, isFalse);
        expect(result.hasSuggestions, isFalse);
        expect(result.selectedSuggestion, isNull);
        expect(result.suggestions.isEmpty, isTrue);
      });

      test('gets selected suggestion correctly', () {
        const suggestions = [
          CompletionSuggestion(
            insertText: 'first',
            displayText: 'First',
            type: CompletionType.customShortcut,
          ),
          CompletionSuggestion(
            insertText: 'second',
            displayText: 'Second',
            type: CompletionType.customShortcut,
          ),
        ];

        const result = CompletionResult(
          suggestions: suggestions,
          isActive: true,
          filterText: '',
          selectedIndex: 1,
        );

        expect(result.selectedSuggestion, equals(suggestions[1]));
      });

      test('handles invalid selected index', () {
        const suggestions = [
          CompletionSuggestion(
            insertText: 'first',
            displayText: 'First',
            type: CompletionType.customShortcut,
          ),
        ];

        const result = CompletionResult(
          suggestions: suggestions,
          isActive: true,
          filterText: '',
          selectedIndex: 10, // Invalid index
        );

        expect(result.selectedSuggestion, isNull);
      });
    });
  });

  group('CompletionSuggestion', () {
    test('creates suggestion with required fields', () {
      const suggestion = CompletionSuggestion(
        insertText: 'test',
        displayText: 'Test',
        type: CompletionType.customShortcut,
      );

      expect(suggestion.insertText, equals('test'));
      expect(suggestion.displayText, equals('Test'));
      expect(suggestion.type, equals(CompletionType.customShortcut));
      expect(suggestion.priority, equals(0)); // default
      expect(suggestion.usageCount, equals(0)); // default
    });

    test('copies with updated properties', () {
      const original = CompletionSuggestion(
        insertText: 'test',
        displayText: 'Test',
        type: CompletionType.customShortcut,
        priority: 5,
        usageCount: 2,
      );

      final updated = original.copyWith(
        priority: 10,
        usageCount: 5,
      );

      expect(updated.insertText, equals('test'));
      expect(updated.displayText, equals('Test'));
      expect(updated.priority, equals(10));
      expect(updated.usageCount, equals(5));
    });

    test('increments usage count', () {
      const original = CompletionSuggestion(
        insertText: 'test',
        displayText: 'Test',
        type: CompletionType.customShortcut,
        usageCount: 2,
      );

      final incremented = original.incrementUsage();

      expect(incremented.usageCount, equals(3));
    });

    test('serializes to/from JSON', () {
      const original = CompletionSuggestion(
        insertText: 'test',
        displayText: 'Test',
        description: 'Test description',
        type: CompletionType.header,
        trigger: '#',
        priority: 5,
        isSnippet: true,
        cursorOffset: 2,
        selectionLength: 4,
        usageCount: 3,
        shortcutKey: 'test',
      );

      final json = original.toJson();
      final restored = CompletionSuggestion.fromJson(json);

      expect(restored.insertText, equals(original.insertText));
      expect(restored.displayText, equals(original.displayText));
      expect(restored.description, equals(original.description));
      expect(restored.type, equals(original.type));
      expect(restored.trigger, equals(original.trigger));
      expect(restored.priority, equals(original.priority));
      expect(restored.isSnippet, equals(original.isSnippet));
      expect(restored.cursorOffset, equals(original.cursorOffset));
      expect(restored.selectionLength, equals(original.selectionLength));
      expect(restored.usageCount, equals(original.usageCount));
      expect(restored.shortcutKey, equals(original.shortcutKey));
    });

    test('equality and hashCode work correctly', () {
      const suggestion1 = CompletionSuggestion(
        insertText: 'test',
        displayText: 'Test',
        type: CompletionType.customShortcut,
      );

      const suggestion2 = CompletionSuggestion(
        insertText: 'test',
        displayText: 'Test',
        type: CompletionType.customShortcut,
      );

      const suggestion3 = CompletionSuggestion(
        insertText: 'different',
        displayText: 'Different',
        type: CompletionType.customShortcut,
      );

      expect(suggestion1, equals(suggestion2));
      expect(suggestion1.hashCode, equals(suggestion2.hashCode));
      expect(suggestion1, isNot(equals(suggestion3)));
    });
  });
}