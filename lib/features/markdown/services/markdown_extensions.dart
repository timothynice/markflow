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
      TaskListBlockSyntax(),
      DefinitionListBlockSyntax(),
      FootnoteDefinitionBlockSyntax(),
    ];
  }

  /// Get all supported inline syntaxes
  static List<md.InlineSyntax> getInlineSyntaxes() {
    return [
      md.InlineHtmlSyntax(),
      md.StrikethroughSyntax(),
      md.AutolinkSyntax(),
      md.AutolinkExtensionSyntax(),
      FootnoteInlineSyntax(),
      HighlightInlineSyntax(),
      SubscriptInlineSyntax(),
      SuperscriptInlineSyntax(),
    ];
  }

  // Note: No extension processors are used for markdown >= 7.
}

/// Syntax for task list items (- [ ] and - [x])
class TaskListBlockSyntax extends md.BlockSyntax {
  @override
  RegExp get pattern => RegExp(r'^[ ]{0,3}[-*+] \[[ xX]\] ');

  @override
  md.Node parse(md.BlockParser parser) {
    final currentLine = (parser.current is md.Line)
        ? (parser.current as md.Line).content
        : (parser.current as String);
    final match = pattern.firstMatch(currentLine);
    if (match == null) return md.Text('');

    final isChecked = currentLine.contains(RegExp(r'\[[xX]\]'));
    final content = currentLine.substring(match.end).trim();

    parser.advance();

    final listItem = md.Element('li', [md.Text(content)]);
    listItem.attributes['class'] = isChecked ? 'task-list-item checked' : 'task-list-item unchecked';
    listItem.attributes['data-checked'] = isChecked.toString();

    return listItem;
  }
}

/// Syntax for definition lists
class DefinitionListBlockSyntax extends md.BlockSyntax {
  @override
  RegExp get pattern => RegExp(r'^[ ]{0,3}:[ \t]');

  @override
  md.Node parse(md.BlockParser parser) {
    final definitions = <md.Element>[];

    while (!parser.isDone && pattern.hasMatch((parser.current is md.Line) ? (parser.current as md.Line).content : (parser.current as String))) {
      final lineText = (parser.current is md.Line) ? (parser.current as md.Line).content : (parser.current as String);
      final content = lineText.substring(lineText.indexOf(':') + 1).trim();

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
class FootnoteDefinitionBlockSyntax extends md.BlockSyntax {
  @override
  RegExp get pattern => RegExp(r'^[ ]{0,3}\[\^([^\]]+)\]:[ \t]*(.*)$');

  @override
  md.Node parse(md.BlockParser parser) {
    final lineText = (parser.current is md.Line) ? (parser.current as md.Line).content : (parser.current as String);
    final match = pattern.firstMatch(lineText);
    if (match == null) return md.Text('');

    final id = match.group(1)!;
    final content = match.group(2)!.trim();

    parser.advance();

    // Parse additional lines that are part of the footnote
    final lines = <String>[content];
    while (!parser.isDone) {
      final curr = (parser.current is md.Line) ? (parser.current as md.Line).content : (parser.current as String);
      if (curr.startsWith('    ') || curr.trim().isEmpty) {
        if (curr.trim().isNotEmpty) {
          lines.add(curr.substring(4));
        }
        parser.advance();
      } else {
        break;
      }
    }

    final footnote = md.Element('div', [md.Text(lines.join('\n'))]);
    footnote.attributes['class'] = 'footnote-definition';
    footnote.attributes['id'] = 'footnote-$id';
    footnote.attributes['data-footnote-id'] = id;

    return footnote;
  }
}

/// Inline syntax for footnote references
class FootnoteInlineSyntax extends md.InlineSyntax {
  FootnoteInlineSyntax() : super(r'\[\^([^\]]+)\]');

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
class HighlightInlineSyntax extends md.InlineSyntax {
  HighlightInlineSyntax() : super(r'==([^=]+)==');

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
class SubscriptInlineSyntax extends md.InlineSyntax {
  SubscriptInlineSyntax() : super(r'~([^~]+)~');

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
class SuperscriptInlineSyntax extends md.InlineSyntax {
  SuperscriptInlineSyntax() : super(r'\^([^^]+)\^');

  @override
  bool onMatch(md.InlineParser parser, Match match) {
    final content = match.group(1)!;

    final element = md.Element.text('sup', content);
    element.attributes['class'] = 'superscript';

    parser.addNode(element);
    return true;
  }
}

// Extension processors and visitors are intentionally omitted for compatibility with markdown >= 7