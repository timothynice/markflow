import 'package:flutter_test/flutter_test.dart';
import 'package:markflow/features/markdown/models/completion_suggestion.dart';
import 'package:markflow/features/markdown/providers/header_completion_provider.dart';
import 'package:markflow/features/markdown/providers/list_completion_provider.dart';
import 'package:markflow/features/markdown/providers/link_completion_provider.dart';
import 'package:markflow/features/markdown/providers/code_completion_provider.dart';
import 'package:markflow/features/markdown/providers/table_completion_provider.dart';
import 'package:markflow/features/markdown/providers/misc_completion_provider.dart';

void main() {
  group('HeaderCompletionProvider', () {
    late HeaderCompletionProvider provider;

    setUp(() {
      provider = HeaderCompletionProvider();
    });

    test('should activate on hash trigger at line start', () {
      final context = CompletionContext.fromTextAndPosition('# ', 2, triggerCharacter: '#');
      expect(provider.shouldActivate(context), isTrue);
    });

    test('should not activate on hash in middle of line', () {
      final context = CompletionContext.fromTextAndPosition('text # ', 6, triggerCharacter: '#');
      expect(provider.shouldActivate(context), isFalse);
    });

    test('provides header suggestions', () async {
      final context = CompletionContext.fromTextAndPosition('# ', 2, triggerCharacter: '#');
      final suggestions = await provider.getSuggestions(context);

      expect(suggestions.isNotEmpty, isTrue);
      expect(suggestions.any((s) => s.insertText.startsWith('# ')), isTrue);
      expect(suggestions.any((s) => s.insertText.startsWith('## ')), isTrue);
      expect(suggestions.any((s) => s.type == CompletionType.header), isTrue);
    });

    test('provides common header templates', () async {
      final context = CompletionContext.fromTextAndPosition('# ', 2, triggerCharacter: '#');
      final suggestions = await provider.getSuggestions(context);

      expect(suggestions.any((s) => s.insertText.contains('Overview')), isTrue);
      expect(suggestions.any((s) => s.insertText.contains('Installation')), isTrue);
      expect(suggestions.any((s) => s.insertText.contains('Usage')), isTrue);
    });

    test('sorts suggestions by priority', () async {
      final context = CompletionContext.fromTextAndPosition('# ', 2, triggerCharacter: '#');
      final suggestions = await provider.getSuggestions(context);

      // Header level 1 should have higher priority than level 6
      final h1 = suggestions.where((s) => s.insertText == '# ').first;
      final h6 = suggestions.where((s) => s.insertText == '###### ').first;
      expect(h1.priority > h6.priority, isTrue);
    });
  });

  group('ListCompletionProvider', () {
    late ListCompletionProvider provider;

    setUp(() {
      provider = ListCompletionProvider();
    });

    test('should activate on list triggers at line start', () {
      final context1 = CompletionContext.fromTextAndPosition('- ', 2, triggerCharacter: '-');
      final context2 = CompletionContext.fromTextAndPosition('* ', 2, triggerCharacter: '*');
      final context3 = CompletionContext.fromTextAndPosition('+ ', 2, triggerCharacter: '+');

      expect(provider.shouldActivate(context1), isTrue);
      expect(provider.shouldActivate(context2), isTrue);
      expect(provider.shouldActivate(context3), isTrue);
    });

    test('provides basic list suggestions', () async {
      final context = CompletionContext.fromTextAndPosition('- ', 2, triggerCharacter: '-');
      final suggestions = await provider.getSuggestions(context);

      expect(suggestions.isNotEmpty, isTrue);
      expect(suggestions.any((s) => s.insertText == '- '), isTrue);
      expect(suggestions.any((s) => s.insertText == '* '), isTrue);
      expect(suggestions.any((s) => s.insertText == '1. '), isTrue);
      expect(suggestions.any((s) => s.type == CompletionType.list), isTrue);
    });

    test('provides task list suggestions', () async {
      final context = CompletionContext.fromTextAndPosition('- ', 2, triggerCharacter: '-');
      final suggestions = await provider.getSuggestions(context);

      expect(suggestions.any((s) => s.insertText == '- [ ] '), isTrue);
      expect(suggestions.any((s) => s.insertText == '- [x] '), isTrue);
    });

    test('provides nested list suggestions', () async {
      final context = CompletionContext.fromTextAndPosition('- ', 2, triggerCharacter: '-');
      final suggestions = await provider.getSuggestions(context);

      expect(suggestions.any((s) => s.insertText.startsWith('  -')), isTrue);
      expect(suggestions.any((s) => s.insertText.startsWith('  1.')), isTrue);
    });

    test('calculates indent level correctly', () async {
      final context = CompletionContext.fromTextAndPosition('- Item 1\n  - ', 13, triggerCharacter: '-');
      final suggestions = await provider.getSuggestions(context);

      // Should provide nested suggestions with correct indentation
      expect(suggestions.any((s) => s.insertText.startsWith('    -')), isTrue);
    });
  });

  group('LinkCompletionProvider', () {
    late LinkCompletionProvider provider;

    setUp(() {
      provider = LinkCompletionProvider();
    });

    test('should activate on bracket trigger', () {
      final context = CompletionContext.fromTextAndPosition('[', 1, triggerCharacter: '[');
      expect(provider.shouldActivate(context), isTrue);
    });

    test('should activate on exclamation trigger', () {
      final context = CompletionContext.fromTextAndPosition('!', 1, triggerCharacter: '!');
      expect(provider.shouldActivate(context), isTrue);
    });

    test('should not activate inside code blocks', () {
      final context = CompletionContext.fromTextAndPosition('```\n[', 5, triggerCharacter: '[');
      expect(provider.shouldActivate(context), isFalse);
    });

    test('provides link suggestions for bracket trigger', () async {
      final context = CompletionContext.fromTextAndPosition('[', 1, triggerCharacter: '[');
      final suggestions = await provider.getSuggestions(context);

      expect(suggestions.isNotEmpty, isTrue);
      expect(suggestions.any((s) => s.type == CompletionType.link), isTrue);
      expect(suggestions.any((s) => s.insertText.contains('[text](url)')), isTrue);
      expect(suggestions.any((s) => s.insertText.contains('[text][ref]')), isTrue);
    });

    test('provides image suggestions for exclamation trigger', () async {
      final context = CompletionContext.fromTextAndPosition('!', 1, triggerCharacter: '!');
      final suggestions = await provider.getSuggestions(context);

      expect(suggestions.isNotEmpty, isTrue);
      expect(suggestions.any((s) => s.type == CompletionType.image), isTrue);
      expect(suggestions.any((s) => s.insertText.contains('![alt text](url)')), isTrue);
    });

    test('provides common link types', () async {
      final context = CompletionContext.fromTextAndPosition('[', 1, triggerCharacter: '[');
      final suggestions = await provider.getSuggestions(context);

      expect(suggestions.any((s) => s.insertText.contains('Homepage')), isTrue);
      expect(suggestions.any((s) => s.insertText.contains('Documentation')), isTrue);
      expect(suggestions.any((s) => s.insertText.contains('GitHub')), isTrue);
    });

    test('provides email and phone links', () async {
      final context = CompletionContext.fromTextAndPosition('[', 1, triggerCharacter: '[');
      final suggestions = await provider.getSuggestions(context);

      expect(suggestions.any((s) => s.insertText.contains('mailto:')), isTrue);
      expect(suggestions.any((s) => s.insertText.contains('tel:')), isTrue);
    });

    test('sets correct cursor positions', () async {
      final context = CompletionContext.fromTextAndPosition('[', 1, triggerCharacter: '[');
      final suggestions = await provider.getSuggestions(context);

      final basicLink = suggestions.firstWhere((s) => s.insertText == '[text](url)');
      expect(basicLink.cursorOffset, equals(-5));
      expect(basicLink.selectionLength, equals(4));
    });
  });

  group('CodeCompletionProvider', () {
    late CodeCompletionProvider provider;

    setUp(() {
      provider = CodeCompletionProvider();
    });

    test('should activate on backtick trigger', () {
      final context = CompletionContext.fromTextAndPosition('`', 1, triggerCharacter: '`');
      expect(provider.shouldActivate(context), isTrue);
    });

    test('provides inline code suggestions for single backtick', () async {
      final context = CompletionContext.fromTextAndPosition('`', 1, triggerCharacter: '`');
      final suggestions = await provider.getSuggestions(context);

      expect(suggestions.isNotEmpty, isTrue);
      expect(suggestions.any((s) => s.insertText == '`code`'), isTrue);
      expect(suggestions.any((s) => s.type == CompletionType.emphasis), isTrue);
    });

    test('provides code block suggestions for triple backticks', () async {
      final context = CompletionContext.fromTextAndPosition('```', 3, triggerCharacter: '`');
      final suggestions = await provider.getSuggestions(context);

      expect(suggestions.isNotEmpty, isTrue);
      expect(suggestions.any((s) => s.type == CompletionType.codeBlock), isTrue);
      expect(suggestions.any((s) => s.insertText.contains('```\ncode\n```')), isTrue);
    });

    test('provides language-specific code blocks', () async {
      final context = CompletionContext.fromTextAndPosition('```', 3, triggerCharacter: '`');
      final suggestions = await provider.getSuggestions(context);

      expect(suggestions.any((s) => s.insertText.contains('```javascript')), isTrue);
      expect(suggestions.any((s) => s.insertText.contains('```python')), isTrue);
      expect(suggestions.any((s) => s.insertText.contains('```dart')), isTrue);
      expect(suggestions.any((s) => s.insertText.contains('```html')), isTrue);
    });

    test('provides code templates', () async {
      final context = CompletionContext.fromTextAndPosition('```', 3, triggerCharacter: '`');
      final suggestions = await provider.getSuggestions(context);

      expect(suggestions.any((s) => s.insertText.contains('function example()')), isTrue);
      expect(suggestions.any((s) => s.insertText.contains('def example():')), isTrue);
    });

    test('provides Mermaid diagram templates', () async {
      final context = CompletionContext.fromTextAndPosition('```', 3, triggerCharacter: '`');
      final suggestions = await provider.getSuggestions(context);

      expect(suggestions.any((s) => s.insertText.contains('```mermaid')), isTrue);
      expect(suggestions.any((s) => s.insertText.contains('graph TD')), isTrue);
      expect(suggestions.any((s) => s.insertText.contains('sequenceDiagram')), isTrue);
    });

    test('provides common inline code patterns', () async {
      final context = CompletionContext.fromTextAndPosition('`', 1, triggerCharacter: '`');
      final suggestions = await provider.getSuggestions(context);

      expect(suggestions.any((s) => s.insertText.contains('function()')), isTrue);
      expect(suggestions.any((s) => s.insertText.contains('variable')), isTrue);
      expect(suggestions.any((s) => s.insertText.contains('className')), isTrue);
    });
  });

  group('TableCompletionProvider', () {
    late TableCompletionProvider provider;

    setUp(() {
      provider = TableCompletionProvider();
    });

    test('should activate on pipe trigger at line start', () {
      final context = CompletionContext.fromTextAndPosition('| ', 2, triggerCharacter: '|');
      expect(provider.shouldActivate(context), isTrue);
    });

    test('provides basic table templates', () async {
      final context = CompletionContext.fromTextAndPosition('| ', 2, triggerCharacter: '|');
      final suggestions = await provider.getSuggestions(context);

      expect(suggestions.isNotEmpty, isTrue);
      expect(suggestions.any((s) => s.type == CompletionType.table), isTrue);
      expect(suggestions.any((s) => s.displayText.contains('2x2')), isTrue);
      expect(suggestions.any((s) => s.displayText.contains('3x2')), isTrue);
    });

    test('provides specialized table templates', () async {
      final context = CompletionContext.fromTextAndPosition('| ', 2, triggerCharacter: '|');
      final suggestions = await provider.getSuggestions(context);

      expect(suggestions.any((s) => s.displayText.contains('API')), isTrue);
      expect(suggestions.any((s) => s.displayText.contains('Status')), isTrue);
      expect(suggestions.any((s) => s.displayName.contains('Comparison')), isTrue);
      expect(suggestions.any((s) => s.displayText.contains('Schedule')), isTrue);
    });

    test('provides alignment table examples', () async {
      final context = CompletionContext.fromTextAndPosition('| ', 2, triggerCharacter: '|');
      final suggestions = await provider.getSuggestions(context);

      expect(suggestions.any((s) => s.insertText.contains(':---:')), isTrue);
      expect(suggestions.any((s) => s.insertText.contains('---:')), isTrue);
    });

    test('detects existing table context', () async {
      const tableText = '''
| Header 1 | Header 2 |
| --- | --- |
| Cell 1 | ''';
      final context = CompletionContext.fromTextAndPosition(tableText, tableText.length, triggerCharacter: '|');

      expect(provider.shouldActivate(context), isTrue);
      final suggestions = await provider.getSuggestions(context);

      // Should provide row continuation with higher priority
      expect(suggestions.any((s) => s.priority >= 12), isTrue);
    });

    test('provides simple pipe separator', () async {
      final context = CompletionContext.fromTextAndPosition('| ', 2, triggerCharacter: '|');
      final suggestions = await provider.getSuggestions(context);

      expect(suggestions.any((s) => s.insertText == '| '), isTrue);
    });
  });

  group('MiscCompletionProvider', () {
    late MiscCompletionProvider provider;

    setUp(() {
      provider = MiscCompletionProvider();
    });

    test('should activate on blockquote trigger', () {
      final context = CompletionContext.fromTextAndPosition('> ', 2, triggerCharacter: '>');
      expect(provider.shouldActivate(context), isTrue);
    });

    test('should activate on horizontal rule triggers', () {
      final context1 = CompletionContext.fromTextAndPosition('-', 1, triggerCharacter: '-');
      final context2 = CompletionContext.fromTextAndPosition('*', 1, triggerCharacter: '*');
      final context3 = CompletionContext.fromTextAndPosition('_', 1, triggerCharacter: '_');

      expect(provider.shouldActivate(context1), isTrue);
      expect(provider.shouldActivate(context2), isTrue);
      expect(provider.shouldActivate(context3), isTrue);
    });

    test('provides blockquote suggestions', () async {
      final context = CompletionContext.fromTextAndPosition('> ', 2, triggerCharacter: '>');
      final suggestions = await provider.getSuggestions(context);

      expect(suggestions.isNotEmpty, isTrue);
      expect(suggestions.any((s) => s.type == CompletionType.blockquote), isTrue);
      expect(suggestions.any((s) => s.insertText == '> Quote text'), isTrue);
    });

    test('provides multi-line blockquote suggestions', () async {
      final context = CompletionContext.fromTextAndPosition('> ', 2, triggerCharacter: '>');
      final suggestions = await provider.getSuggestions(context);

      expect(suggestions.any((s) => s.insertText.contains('> Line 1\n> Line 2')), isTrue);
      expect(suggestions.any((s) => s.isSnippet == true), isTrue);
    });

    test('provides nested blockquote suggestions', () async {
      final context = CompletionContext.fromTextAndPosition('> ', 2, triggerCharacter: '>');
      final suggestions = await provider.getSuggestions(context);

      expect(suggestions.any((s) => s.insertText.contains('> > Nested')), isTrue);
    });

    test('provides callout-style blockquotes', () async {
      final context = CompletionContext.fromTextAndPosition('> ', 2, triggerCharacter: '>');
      final suggestions = await provider.getSuggestions(context);

      expect(suggestions.any((s) => s.insertText.contains('**Note:**')), isTrue);
      expect(suggestions.any((s) => s.insertText.contains('**Warning:**')), isTrue);
      expect(suggestions.any((s) => s.insertText.contains('**Tip:**')), isTrue);
    });

    test('provides GitHub-style alerts', () async {
      final context = CompletionContext.fromTextAndPosition('> ', 2, triggerCharacter: '>');
      final suggestions = await provider.getSuggestions(context);

      expect(suggestions.any((s) => s.insertText.contains('[!NOTE]')), isTrue);
      expect(suggestions.any((s) => s.insertText.contains('[!WARNING]')), isTrue);
      expect(suggestions.any((s) => s.insertText.contains('[!IMPORTANT]')), isTrue);
    });

    test('provides horizontal rule suggestions at line start', () async {
      final context = CompletionContext.fromTextAndPosition('\n-', 2, triggerCharacter: '-');
      final suggestions = await provider.getSuggestions(context);

      expect(suggestions.any((s) => s.type == CompletionType.horizontalRule), isTrue);
      expect(suggestions.any((s) => s.insertText == '---'), isTrue);
      expect(suggestions.any((s) => s.insertText == '***'), isTrue);
      expect(suggestions.any((s) => s.insertText == '___'), isTrue);
    });

    test('provides spaced horizontal rules', () async {
      final context = CompletionContext.fromTextAndPosition('\n-', 2, triggerCharacter: '-');
      final suggestions = await provider.getSuggestions(context);

      expect(suggestions.any((s) => s.insertText == '- - -'), isTrue);
      expect(suggestions.any((s) => s.insertText == '* * *'), isTrue);
      expect(suggestions.any((s) => s.insertText == '_ _ _'), isTrue);
    });

    test('provides emphasis suggestions inline', () async {
      final context = CompletionContext.fromTextAndPosition('text *', 6, triggerCharacter: '*');
      final suggestions = await provider.getSuggestions(context);

      expect(suggestions.any((s) => s.type == CompletionType.emphasis), isTrue);
      expect(suggestions.any((s) => s.insertText.contains('*italic*')), isTrue);
      expect(suggestions.any((s) => s.insertText.contains('**bold**')), isTrue);
      expect(suggestions.any((s) => s.insertText.contains('***bold italic***')), isTrue);
    });

    test('does not provide emphasis suggestions at line start', () async {
      final context = CompletionContext.fromTextAndPosition('*', 1, triggerCharacter: '*');
      final suggestions = await provider.getSuggestions(context);

      // Should provide horizontal rules but not emphasis at line start
      expect(suggestions.any((s) => s.type == CompletionType.horizontalRule), isTrue);
      expect(suggestions.where((s) => s.type == CompletionType.emphasis).isEmpty, isTrue);
    });
  });

  group('CompletionProvider Base Functionality', () {
    test('trigger-based providers respond to correct characters', () {
      final headerProvider = HeaderCompletionProvider();
      final listProvider = ListCompletionProvider();
      final linkProvider = LinkCompletionProvider();

      expect(headerProvider.triggerCharacters, contains('#'));
      expect(listProvider.triggerCharacters, containsAll(['-', '*', '+']));
      expect(linkProvider.triggerCharacters, containsAll(['[', '!']));
    });

    test('providers have correct priorities', () {
      final providers = [
        HeaderCompletionProvider(),
        ListCompletionProvider(),
        LinkCompletionProvider(),
        CodeCompletionProvider(),
        TableCompletionProvider(),
        MiscCompletionProvider(),
      ];

      for (final provider in providers) {
        expect(provider.priority, greaterThanOrEqualTo(0));
      }
    });

    test('providers have names', () {
      final providers = [
        HeaderCompletionProvider(),
        ListCompletionProvider(),
        LinkCompletionProvider(),
        CodeCompletionProvider(),
        TableCompletionProvider(),
        MiscCompletionProvider(),
      ];

      for (final provider in providers) {
        expect(provider.name.isNotEmpty, isTrue);
      }
    });
  });

  group('Provider Integration', () {
    test('multiple providers can be active for same context', () {
      final context = CompletionContext.fromTextAndPosition('*', 1, triggerCharacter: '*');

      final listProvider = ListCompletionProvider();
      final miscProvider = MiscCompletionProvider();

      expect(listProvider.shouldActivate(context), isTrue);
      expect(miscProvider.shouldActivate(context), isTrue);
    });

    test('providers respect context constraints', () {
      final codeContext = CompletionContext.fromTextAndPosition('```\n[', 5, triggerCharacter: '[');
      final linkProvider = LinkCompletionProvider();

      // Link provider should not activate inside code blocks
      expect(linkProvider.shouldActivate(codeContext), isFalse);
    });

    test('providers generate distinct suggestion types', () async {
      final context = CompletionContext.fromTextAndPosition('# ', 2, triggerCharacter: '#');

      final headerProvider = HeaderCompletionProvider();
      final suggestions = await headerProvider.getSuggestions(context);

      expect(suggestions.every((s) => s.type == CompletionType.header), isTrue);
    });
  });
}