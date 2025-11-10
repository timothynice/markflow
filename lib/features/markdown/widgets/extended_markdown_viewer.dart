import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:markdown/markdown.dart' as md;

import '../services/markdown_extensions.dart';
import '../renderers/task_list_renderer.dart';
import '../renderers/footnote_renderer.dart';
import '../renderers/definition_list_renderer.dart';
import '../renderers/text_extensions_renderer.dart';
import 'markdown_code_builder.dart';

/// Extended markdown viewer with support for footnotes, task lists, definition lists, and text extensions
class ExtendedMarkdownViewer extends StatefulWidget {
  final String data;
  final EdgeInsetsGeometry? padding;
  final bool selectable;
  final bool softLineBreak;
  final MarkdownStyleSheet? styleSheet;
  final void Function(String, String?, String)? onTapLink;
  final ScrollController? controller;
  final ScrollPhysics? physics;
  final bool showLineNumbers;
  final bool showCopyButton;
  final bool showLanguageLabel;
  final double? codeBlockFontSize;
  final String? codeBlockFontFamily;

  // Extension settings
  final bool enableFootnotes;
  final bool enableTaskLists;
  final bool enableDefinitionLists;
  final bool enableTextExtensions;
  final bool enableStrikethrough;
  final bool enableInteractiveElements;

  // Task list callbacks
  final Function(String taskId, bool checked)? onTaskToggle;

  const ExtendedMarkdownViewer({
    super.key,
    required this.data,
    this.padding,
    this.selectable = true,
    this.softLineBreak = false,
    this.styleSheet,
    this.onTapLink,
    this.controller,
    this.physics,
    this.showLineNumbers = false,
    this.showCopyButton = true,
    this.showLanguageLabel = true,
    this.codeBlockFontSize,
    this.codeBlockFontFamily,
    this.enableFootnotes = true,
    this.enableTaskLists = true,
    this.enableDefinitionLists = true,
    this.enableTextExtensions = true,
    this.enableStrikethrough = true,
    this.enableInteractiveElements = true,
    this.onTaskToggle,
  });

  @override
  State<ExtendedMarkdownViewer> createState() => _ExtendedMarkdownViewerState();
}

class _ExtendedMarkdownViewerState extends State<ExtendedMarkdownViewer> {
  late List<FootnoteData> _footnotes;
  late List<bool> _taskStates;

  @override
  void initState() {
    super.initState();
    _extractFootnotesAndTasks();
  }

  @override
  void didUpdateWidget(ExtendedMarkdownViewer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.data != widget.data) {
      _extractFootnotesAndTasks();
    }
  }

  void _extractFootnotesAndTasks() {
    _footnotes = _extractFootnotes(widget.data);
    _taskStates = _extractTaskStates(widget.data);
  }

  List<FootnoteData> _extractFootnotes(String markdown) {
    final footnotes = <FootnoteData>[];
    final pattern = RegExp(r'\[\^([^\]]+)\]:[ \t]*(.*)$', multiLine: true);
    final matches = pattern.allMatches(markdown);

    int index = 1;
    for (final match in matches) {
      final id = match.group(1)!;
      final content = match.group(2)!.trim();
      footnotes.add(FootnoteData(
        id: id,
        number: index++,
        content: content,
      ));
    }

    return footnotes;
  }

  List<bool> _extractTaskStates(String markdown) {
    final taskStates = <bool>[];
    final pattern = RegExp(r'^[ ]{0,3}[-*+] \[([xX ])\] ', multiLine: true);
    final matches = pattern.allMatches(markdown);

    for (final match in matches) {
      final checkmark = match.group(1)!;
      taskStates.add(checkmark.toLowerCase() == 'x');
    }

    return taskStates;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Task progress indicator
        if (widget.enableTaskLists &&
            widget.enableInteractiveElements &&
            _taskStates.isNotEmpty)
          Padding(
            padding: widget.padding ?? EdgeInsets.zero,
            child: TaskListProgress(
              taskStates: _taskStates,
              style: widget.styleSheet?.p,
            ),
          ),

        // Main markdown content
        Expanded(
          child: Markdown(
            data: widget.data,
            padding: widget.padding,
            controller: widget.controller,
            physics: widget.physics,
            selectable: widget.selectable,
            softLineBreak: widget.softLineBreak,
            styleSheet: widget.styleSheet,
            onTapLink: widget.onTapLink,
            extensionSet: _buildExtensionSet(),
            builders: _buildCustomBuilders(),
          ),
        ),

        // Footnotes section
        if (widget.enableFootnotes && _footnotes.isNotEmpty)
          Padding(
            padding: widget.padding ?? EdgeInsets.zero,
            child: FootnotesSection(
              footnotes: _footnotes,
              style: widget.styleSheet?.p,
            ),
          ),
      ],
    );
  }

  md.ExtensionSet _buildExtensionSet() {
    final blockSyntaxes = <md.BlockSyntax>[];
    final inlineSyntaxes = <md.InlineSyntax>[];

    // Always include basic syntaxes
    blockSyntaxes.addAll([
      md.FencedCodeBlockSyntax(),
      md.HeaderWithIdSyntax(),
      md.SetextHeaderWithIdSyntax(),
      md.TableSyntax(),
    ]);

    inlineSyntaxes.addAll([
      md.InlineHtmlSyntax(),
      md.AutolinkSyntax(),
      md.AutolinkExtensionSyntax(),
    ]);

    // Add extension syntaxes based on settings
    if (widget.enableTaskLists) {
      blockSyntaxes.add(TaskListSyntax());
    }

    if (widget.enableDefinitionLists) {
      blockSyntaxes.add(DefinitionListSyntax());
    }

    if (widget.enableFootnotes) {
      blockSyntaxes.add(FootnoteDefinitionSyntax());
      inlineSyntaxes.add(FootnoteSyntax());
    }

    if (widget.enableStrikethrough) {
      inlineSyntaxes.add(md.StrikethroughSyntax());
    }

    if (widget.enableTextExtensions) {
      inlineSyntaxes.addAll([
        HighlightSyntax(),
        SubscriptSyntax(),
        SuperscriptSyntax(),
      ]);
    }

    return md.ExtensionSet(
      blockSyntaxes,
      inlineSyntaxes,
    );
  }

  Map<String, MarkdownElementBuilder> _buildCustomBuilders() {
    final builders = <String, MarkdownElementBuilder>{};

    // Always include code builder
    final codeBuilder = MarkdownCodeBuilder(
      showLineNumbers: widget.showLineNumbers,
      showCopyButton: widget.showCopyButton,
      showLanguageLabel: widget.showLanguageLabel,
      fontSize: widget.codeBlockFontSize,
      fontFamily: widget.codeBlockFontFamily,
    );

    builders['pre'] = codeBuilder;
    builders['code'] = codeBuilder;

    // Add extension builders based on settings
    if (widget.enableTaskLists) {
      builders['ul'] = TaskListRenderer(
        onTaskToggle: widget.enableInteractiveElements ? widget.onTaskToggle : null,
        enableInteraction: widget.enableInteractiveElements,
      );
      builders['li'] = TaskListRenderer(
        onTaskToggle: widget.enableInteractiveElements ? widget.onTaskToggle : null,
        enableInteraction: widget.enableInteractiveElements,
      );
    }

    if (widget.enableFootnotes) {
      final footnoteBuilder = FootnoteRenderer(
        enableInteraction: widget.enableInteractiveElements,
      );
      builders['a'] = footnoteBuilder;
      builders['div'] = footnoteBuilder;
    }

    if (widget.enableDefinitionLists) {
      final definitionBuilder = DefinitionListRenderer();
      builders['dl'] = definitionBuilder;
      builders['dt'] = definitionBuilder;
      builders['dd'] = definitionBuilder;
    }

    if (widget.enableTextExtensions) {
      final textExtensionsBuilder = TextExtensionsRenderer();
      builders['mark'] = textExtensionsBuilder;
      builders['sub'] = textExtensionsBuilder;
      builders['sup'] = textExtensionsBuilder;
    }

    if (widget.enableStrikethrough) {
      final strikethroughBuilder = StrikethroughRenderer();
      builders['del'] = strikethroughBuilder;
      builders['s'] = strikethroughBuilder;
    }

    return builders;
  }
}

/// Settings for markdown extensions
class MarkdownExtensionSettings {
  final bool enableFootnotes;
  final bool enableTaskLists;
  final bool enableDefinitionLists;
  final bool enableTextExtensions;
  final bool enableStrikethrough;
  final bool enableInteractiveElements;

  const MarkdownExtensionSettings({
    this.enableFootnotes = true,
    this.enableTaskLists = true,
    this.enableDefinitionLists = true,
    this.enableTextExtensions = true,
    this.enableStrikethrough = true,
    this.enableInteractiveElements = true,
  });

  MarkdownExtensionSettings copyWith({
    bool? enableFootnotes,
    bool? enableTaskLists,
    bool? enableDefinitionLists,
    bool? enableTextExtensions,
    bool? enableStrikethrough,
    bool? enableInteractiveElements,
  }) {
    return MarkdownExtensionSettings(
      enableFootnotes: enableFootnotes ?? this.enableFootnotes,
      enableTaskLists: enableTaskLists ?? this.enableTaskLists,
      enableDefinitionLists: enableDefinitionLists ?? this.enableDefinitionLists,
      enableTextExtensions: enableTextExtensions ?? this.enableTextExtensions,
      enableStrikethrough: enableStrikethrough ?? this.enableStrikethrough,
      enableInteractiveElements: enableInteractiveElements ?? this.enableInteractiveElements,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'enableFootnotes': enableFootnotes,
      'enableTaskLists': enableTaskLists,
      'enableDefinitionLists': enableDefinitionLists,
      'enableTextExtensions': enableTextExtensions,
      'enableStrikethrough': enableStrikethrough,
      'enableInteractiveElements': enableInteractiveElements,
    };
  }

  factory MarkdownExtensionSettings.fromJson(Map<String, dynamic> json) {
    return MarkdownExtensionSettings(
      enableFootnotes: json['enableFootnotes'] ?? true,
      enableTaskLists: json['enableTaskLists'] ?? true,
      enableDefinitionLists: json['enableDefinitionLists'] ?? true,
      enableTextExtensions: json['enableTextExtensions'] ?? true,
      enableStrikethrough: json['enableStrikethrough'] ?? true,
      enableInteractiveElements: json['enableInteractiveElements'] ?? true,
    );
  }
}