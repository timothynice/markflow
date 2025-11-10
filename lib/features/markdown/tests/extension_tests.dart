import 'package:flutter_test/flutter_test.dart';
import 'package:markdown/markdown.dart' as md;

import '../services/markdown_extensions.dart';
import '../renderers/task_list_renderer.dart';
import '../renderers/footnote_renderer.dart';
import '../renderers/definition_list_renderer.dart';
import '../renderers/text_extensions_renderer.dart';

void main() {
  group('Markdown Extensions Tests', () {
    test('TaskListSyntax parses task list items correctly', () {
      const markdown = '''
- [ ] Incomplete task
- [x] Complete task
- [X] Also complete task
''';

      final document = md.Document(
        blockSyntaxes: [TaskListSyntax()],
      );

      final parsed = document.parseLines(markdown.split('\n'));

      expect(parsed.length, equals(3));

      // Check first task (incomplete)
      final firstTask = parsed[0] as md.Element;
      expect(firstTask.attributes['class'], contains('task-list-item'));
      expect(firstTask.attributes['class'], contains('unchecked'));
      expect(firstTask.attributes['data-checked'], equals('false'));

      // Check second task (complete)
      final secondTask = parsed[1] as md.Element;
      expect(secondTask.attributes['class'], contains('task-list-item'));
      expect(secondTask.attributes['class'], contains('checked'));
      expect(secondTask.attributes['data-checked'], equals('true'));

      // Check third task (also complete)
      final thirdTask = parsed[2] as md.Element;
      expect(thirdTask.attributes['class'], contains('task-list-item'));
      expect(thirdTask.attributes['class'], contains('checked'));
      expect(thirdTask.attributes['data-checked'], equals('true'));
    });

    test('FootnoteSyntax creates correct references', () {
      const markdown = 'This has a footnote[^1] reference.';

      final document = md.Document(
        inlineSyntaxes: [FootnoteSyntax()],
      );

      final parsed = document.parseInline(markdown);

      expect(parsed.children, isNotNull);
      expect(parsed.children!.length, greaterThan(1));

      // Find the footnote reference
      final footnoteRef = parsed.children!
          .whereType<md.Element>()
          .where((e) => e.attributes['class']?.contains('footnote-ref') == true)
          .first;

      expect(footnoteRef.tag, equals('a'));
      expect(footnoteRef.attributes['data-footnote-ref'], equals('1'));
      expect(footnoteRef.attributes['href'], equals('#footnote-1'));
    });

    test('DefinitionListSyntax parses definition lists', () {
      const markdown = '''
: Definition 1
: Definition 2
''';

      final document = md.Document(
        blockSyntaxes: [DefinitionListSyntax()],
      );

      final parsed = document.parseLines(markdown.split('\n'));

      expect(parsed.length, equals(1));

      final definitionList = parsed[0] as md.Element;
      expect(definitionList.tag, equals('dl'));
      expect(definitionList.children!.length, equals(2));

      final firstDef = definitionList.children![0] as md.Element;
      expect(firstDef.tag, equals('dd'));
      expect(firstDef.textContent.trim(), equals('Definition 1'));
    });

    test('HighlightSyntax creates mark elements', () {
      const markdown = 'This is ==highlighted text==.';

      final document = md.Document(
        inlineSyntaxes: [HighlightSyntax()],
      );

      final parsed = document.parseInline(markdown);

      final highlightElement = parsed.children!
          .whereType<md.Element>()
          .where((e) => e.tag == 'mark')
          .first;

      expect(highlightElement.textContent, equals('highlighted text'));
      expect(highlightElement.attributes['class'], equals('highlight'));
    });

    test('SubscriptSyntax creates sub elements', () {
      const markdown = 'H~2~O is water.';

      final document = md.Document(
        inlineSyntaxes: [SubscriptSyntax()],
      );

      final parsed = document.parseInline(markdown);

      final subElement = parsed.children!
          .whereType<md.Element>()
          .where((e) => e.tag == 'sub')
          .first;

      expect(subElement.textContent, equals('2'));
      expect(subElement.attributes['class'], equals('subscript'));
    });

    test('SuperscriptSyntax creates sup elements', () {
      const markdown = 'E = mc^2^ is famous.';

      final document = md.Document(
        inlineSyntaxes: [SuperscriptSyntax()],
      );

      final parsed = document.parseInline(markdown);

      final supElement = parsed.children!
          .whereType<md.Element>()
          .where((e) => e.tag == 'sup')
          .first;

      expect(supElement.textContent, equals('2'));
      expect(supElement.attributes['class'], equals('superscript'));
    });

    test('FootnoteDefinitionSyntax parses footnote definitions', () {
      const markdown = '[^1]: This is a footnote definition.';

      final document = md.Document(
        blockSyntaxes: [FootnoteDefinitionSyntax()],
      );

      final parsed = document.parseLines([markdown]);

      expect(parsed.length, equals(1));

      final footnoteDef = parsed[0] as md.Element;
      expect(footnoteDef.tag, equals('div'));
      expect(footnoteDef.attributes['class'], equals('footnote-definition'));
      expect(footnoteDef.attributes['id'], equals('footnote-1'));
      expect(footnoteDef.attributes['data-footnote-id'], equals('1'));
    });
  });

  group('Extension Settings Tests', () {
    test('MarkdownExtensionSettings default values', () {
      const settings = MarkdownExtensionSettings();

      expect(settings.enableFootnotes, isTrue);
      expect(settings.enableTaskLists, isTrue);
      expect(settings.enableDefinitionLists, isTrue);
      expect(settings.enableTextExtensions, isTrue);
      expect(settings.enableStrikethrough, isTrue);
      expect(settings.enableInteractiveElements, isTrue);
    });

    test('MarkdownExtensionSettings copyWith', () {
      const settings = MarkdownExtensionSettings();
      final updated = settings.copyWith(
        enableFootnotes: false,
        enableTaskLists: false,
      );

      expect(updated.enableFootnotes, isFalse);
      expect(updated.enableTaskLists, isFalse);
      expect(updated.enableDefinitionLists, isTrue); // unchanged
      expect(updated.enableTextExtensions, isTrue); // unchanged
      expect(updated.enableStrikethrough, isTrue); // unchanged
      expect(updated.enableInteractiveElements, isTrue); // unchanged
    });

    test('MarkdownExtensionSettings toJson and fromJson', () {
      const settings = MarkdownExtensionSettings(
        enableFootnotes: false,
        enableTaskLists: true,
        enableDefinitionLists: false,
        enableTextExtensions: true,
        enableStrikethrough: false,
        enableInteractiveElements: true,
      );

      final json = settings.toJson();
      final restored = MarkdownExtensionSettings.fromJson(json);

      expect(restored.enableFootnotes, equals(settings.enableFootnotes));
      expect(restored.enableTaskLists, equals(settings.enableTaskLists));
      expect(restored.enableDefinitionLists, equals(settings.enableDefinitionLists));
      expect(restored.enableTextExtensions, equals(settings.enableTextExtensions));
      expect(restored.enableStrikethrough, equals(settings.enableStrikethrough));
      expect(restored.enableInteractiveElements, equals(settings.enableInteractiveElements));
    });
  });

  group('FootnoteData Tests', () {
    test('FootnoteData creation', () {
      const footnote = FootnoteData(
        id: 'test',
        number: 1,
        content: 'Test footnote content',
      );

      expect(footnote.id, equals('test'));
      expect(footnote.number, equals(1));
      expect(footnote.content, equals('Test footnote content'));
    });
  });

  group('Integration Tests', () {
    test('Full markdown document with all extensions', () {
      const markdown = '''
# Test Document

## Task List
- [ ] Task 1
- [x] Task 2

## Footnotes
Text with footnote[^1].

## Definition List
Term
: Definition

## Text Extensions
~~strikethrough~~ ==highlight== H~2~O E=mc^2^

[^1]: Footnote content.
''';

      final document = md.Document(
        blockSyntaxes: MarkdownExtensions.getBlockSyntaxes(),
        inlineSyntaxes: MarkdownExtensions.getInlineSyntaxes(),
      );

      final parsed = document.parseLines(markdown.split('\n'));

      // Should parse without errors
      expect(parsed, isNotEmpty);

      // Check for task list items
      final taskItems = parsed
          .whereType<md.Element>()
          .where((e) => e.attributes['class']?.contains('task-list-item') == true);
      expect(taskItems.length, equals(2));

      // Check for footnote definitions
      final footnoteDefs = parsed
          .whereType<md.Element>()
          .where((e) => e.attributes['class']?.contains('footnote-definition') == true);
      expect(footnoteDefs.length, equals(1));

      // Check for definition lists
      final definitionLists = parsed
          .whereType<md.Element>()
          .where((e) => e.tag == 'dl');
      expect(definitionLists.length, equals(1));
    });
  });
}