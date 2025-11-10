import 'package:markdown/markdown.dart' as md;

/// Service for managing markdown extensions
class MarkdownExtensions {
  /// Get all supported extensions
  static List<md.BlockSyntax> getBlockSyntaxes() {
    return [
      md.FencedCodeBlockSyntax(),
      md.HeaderWithIdSyntax(),
      md.SetextHeaderWithIdSyntax(),
      md.TableSyntax(),
      TaskListSyntax(),
      DefinitionListSyntax(),
      FootnoteDefinitionSyntax(),
    ];
  }

  /// Get all supported inline syntaxes
  static List<md.InlineSyntax> getInlineSyntaxes() {
    return [
      md.InlineHtmlSyntax(),
      md.StrikethroughSyntax(),
      md.AutolinkSyntax(),
      md.AutolinkExtensionSyntax(),
      FootnoteSyntax(),
      HighlightSyntax(),
      SubscriptSyntax(),
      SuperscriptSyntax(),
    ];
  }

  /// Get all extension processors
  static List<md.ExtensionProcessor> getExtensionProcessors() {
    return [
      FootnoteExtensionProcessor(),
      TaskListExtensionProcessor(),
    ];
  }
}

/// Syntax for task list items (- [ ] and - [x])
class TaskListSyntax extends md.BlockSyntax {
  @override
  RegExp get pattern => RegExp(r'^[ ]{0,3}[-*+] \[[ xX]\] ');

  @override
  md.Node parse(md.BlockParser parser) {
    final match = pattern.firstMatch(parser.current);
    if (match == null) return md.Text('');

    final line = parser.current;
    final isChecked = line.contains(RegExp(r'\[[xX]\]'));
    final content = line.substring(match.end).trim();

    parser.advance();

    final listItem = md.Element('li', [md.Text(content)]);
    listItem.attributes['class'] = isChecked ? 'task-list-item checked' : 'task-list-item unchecked';
    listItem.attributes['data-checked'] = isChecked.toString();

    return listItem;
  }
}

/// Syntax for definition lists
class DefinitionListSyntax extends md.BlockSyntax {
  @override
  RegExp get pattern => RegExp(r'^[ ]{0,3}:[ \t]');

  @override
  md.Node parse(md.BlockParser parser) {
    final definitions = <md.Element>[];

    while (!parser.isDone && pattern.hasMatch(parser.current)) {
      final line = parser.current;
      final content = line.substring(line.indexOf(':') + 1).trim();

      final dd = md.Element('dd', [md.Text(content)]);
      definitions.add(dd);
      parser.advance();
    }

    if (definitions.isNotEmpty) {
      return md.Element('dl', definitions);
    }

    return md.Text('');
  }
}

/// Syntax for footnote definitions
class FootnoteDefinitionSyntax extends md.BlockSyntax {
  @override
  RegExp get pattern => RegExp(r'^[ ]{0,3}\[\^([^\]]+)\]:[ \t]*(.*)$');

  @override
  md.Node parse(md.BlockParser parser) {
    final match = pattern.firstMatch(parser.current);
    if (match == null) return md.Text('');

    final id = match.group(1)!;
    final content = match.group(2)!.trim();

    parser.advance();

    // Parse additional lines that are part of the footnote
    final lines = <String>[content];
    while (!parser.isDone &&
           (parser.current.startsWith('    ') || parser.current.trim().isEmpty)) {
      if (parser.current.trim().isNotEmpty) {
        lines.add(parser.current.substring(4)); // Remove indentation
      }
      parser.advance();
    }

    final footnote = md.Element('div', [md.Text(lines.join('\n'))]);
    footnote.attributes['class'] = 'footnote-definition';
    footnote.attributes['id'] = 'footnote-$id';
    footnote.attributes['data-footnote-id'] = id;

    return footnote;
  }
}

/// Inline syntax for footnote references
class FootnoteSyntax extends md.InlineSyntax {
  FootnoteSyntax() : super(r'\[\^([^\]]+)\]');

  @override
  bool onMatch(md.InlineParser parser, Match match) {
    final id = match.group(1)!;

    final element = md.Element.text('a', '[${id}]');
    element.attributes['href'] = '#footnote-$id';
    element.attributes['class'] = 'footnote-ref';
    element.attributes['data-footnote-ref'] = id;

    parser.addNode(element);
    return true;
  }
}

/// Inline syntax for highlight/mark text (==text==)
class HighlightSyntax extends md.InlineSyntax {
  HighlightSyntax() : super(r'==([^=]+)==');

  @override
  bool onMatch(md.InlineParser parser, Match match) {
    final content = match.group(1)!;

    final element = md.Element.text('mark', content);
    element.attributes['class'] = 'highlight';

    parser.addNode(element);
    return true;
  }
}

/// Inline syntax for subscript (~text~)
class SubscriptSyntax extends md.InlineSyntax {
  SubscriptSyntax() : super(r'~([^~]+)~');

  @override
  bool onMatch(md.InlineParser parser, Match match) {
    final content = match.group(1)!;

    final element = md.Element.text('sub', content);
    element.attributes['class'] = 'subscript';

    parser.addNode(element);
    return true;
  }
}

/// Inline syntax for superscript (^text^)
class SuperscriptSyntax extends md.InlineSyntax {
  SuperscriptSyntax() : super(r'\^([^^]+)\^');

  @override
  bool onMatch(md.InlineParser parser, Match match) {
    final content = match.group(1)!;

    final element = md.Element.text('sup', content);
    element.attributes['class'] = 'superscript';

    parser.addNode(element);
    return true;
  }
}

/// Extension processor for footnotes
class FootnoteExtensionProcessor extends md.ExtensionProcessor {
  @override
  void process(md.Document document) {
    final footnoteRefs = <md.Element>[];
    final footnoteDefinitions = <md.Element>[];

    // Collect footnote references and definitions
    document.accept(FootnoteCollector(footnoteRefs, footnoteDefinitions));

    // Number footnotes and create back-references
    final footnoteMap = <String, int>{};
    var footnoteIndex = 1;

    for (final ref in footnoteRefs) {
      final id = ref.attributes['data-footnote-ref'];
      if (id != null && !footnoteMap.containsKey(id)) {
        footnoteMap[id] = footnoteIndex++;
      }
    }

    // Update footnote references with numbers
    for (final ref in footnoteRefs) {
      final id = ref.attributes['data-footnote-ref'];
      if (id != null && footnoteMap.containsKey(id)) {
        final number = footnoteMap[id]!;
        ref.textContent = '[$number]';
        ref.attributes['title'] = 'Footnote $number';
      }
    }

    // Update footnote definitions with numbers and back-links
    for (final def in footnoteDefinitions) {
      final id = def.attributes['data-footnote-id'];
      if (id != null && footnoteMap.containsKey(id)) {
        final number = footnoteMap[id]!;
        def.attributes['data-footnote-number'] = number.toString();

        // Add back-link
        final backLink = md.Element.text('a', '↩');
        backLink.attributes['href'] = '#footnote-ref-$id';
        backLink.attributes['class'] = 'footnote-backref';
        backLink.attributes['title'] = 'Back to reference';

        def.children!.add(md.Text(' '));
        def.children!.add(backLink);
      }
    }
  }
}

/// Extension processor for task lists
class TaskListExtensionProcessor extends md.ExtensionProcessor {
  @override
  void process(md.Document document) {
    // Find all task list items and wrap them in appropriate containers
    document.accept(TaskListProcessor());
  }
}

/// Visitor to collect footnotes
class FootnoteCollector implements md.NodeVisitor {
  final List<md.Element> footnoteRefs;
  final List<md.Element> footnoteDefinitions;

  FootnoteCollector(this.footnoteRefs, this.footnoteDefinitions);

  @override
  bool visitElementBefore(md.Element element) {
    if (element.attributes['class'] == 'footnote-ref') {
      footnoteRefs.add(element);
    } else if (element.attributes['class'] == 'footnote-definition') {
      footnoteDefinitions.add(element);
    }
    return true;
  }

  @override
  void visitElementAfter(md.Element element) {}

  @override
  void visitText(md.Text text) {}
}

/// Visitor to process task lists
class TaskListProcessor implements md.NodeVisitor {
  @override
  bool visitElementBefore(md.Element element) {
    if (element.tag == 'li' &&
        element.attributes['class']?.contains('task-list-item') == true) {

      // Mark parent list as task list
      final parent = element.parent;
      if (parent is md.Element && (parent.tag == 'ul' || parent.tag == 'ol')) {
        parent.attributes['class'] = 'task-list';
      }
    }
    return true;
  }

  @override
  void visitElementAfter(md.Element element) {}

  @override
  void visitText(md.Text text) {}
}