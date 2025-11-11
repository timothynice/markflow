import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:markdown/markdown.dart' as md;
import 'enhanced_code_block.dart';

/// Custom markdown code builder that uses enhanced syntax highlighting
class MarkdownCodeBuilder extends MarkdownElementBuilder {
  final bool showLineNumbers;
  final bool showCopyButton;
  final bool showLanguageLabel;
  final double? fontSize;
  final String? fontFamily;

  MarkdownCodeBuilder({
    this.showLineNumbers = false,
    this.showCopyButton = true,
    this.showLanguageLabel = true,
    this.fontSize,
    this.fontFamily,
  });

  @override
  Widget? visitElementAfter(md.Element element, TextStyle? preferredStyle) {
    // Handle code blocks (```language)
    if (element.tag == 'pre') {
      final codeElement = element.children?.firstWhere(
        (child) => child is md.Element && child.tag == 'code',
        orElse: () => element,
      ) as md.Element?;

      if (codeElement != null) {
        // Extract language from class attribute (e.g., "language-dart")
        String? language;
        final classAttr = codeElement.attributes['class'];
        if (classAttr != null && classAttr.startsWith('language-')) {
          language = classAttr.substring('language-'.length);
        }

        // Get code content
        final code = codeElement.textContent;

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: EnhancedCodeBlock(
            code: code,
            language: language,
            showLineNumbers: showLineNumbers,
            showCopyButton: showCopyButton,
            showLanguageLabel: showLanguageLabel,
            fontSize: fontSize,
            fontFamily: fontFamily,
          ),
        );
      }
    }

    return null;
  }
}

/// Enhanced markdown widget that includes syntax highlighting
class EnhancedMarkdown extends StatelessWidget {
  final String data;
  final EdgeInsets? padding;
  final bool selectable;
  final bool softLineBreak;
  final MarkdownStyleSheet? styleSheet;
  final void Function(String, String?, String)? onTapLink;
  final bool showLineNumbers;
  final bool showCopyButton;
  final bool showLanguageLabel;
  final double? codeBlockFontSize;
  final String? codeBlockFontFamily;
  final ScrollController? controller;
  final ScrollPhysics? physics;

  const EnhancedMarkdown({
    super.key,
    required this.data,
    this.padding,
    this.selectable = true,
    this.softLineBreak = false,
    this.styleSheet,
    this.onTapLink,
    this.showLineNumbers = false,
    this.showCopyButton = true,
    this.showLanguageLabel = true,
    this.codeBlockFontSize,
    this.codeBlockFontFamily,
    this.controller,
    this.physics,
  });

  @override
  Widget build(BuildContext context) {
    return Markdown(
      data: data,
      padding: padding ?? EdgeInsets.zero,
      controller: controller,
      physics: physics,
      selectable: selectable,
      softLineBreak: softLineBreak,
      styleSheet: styleSheet,
      onTapLink: onTapLink,
      builders: {
        'pre': MarkdownCodeBuilder(
          showLineNumbers: showLineNumbers,
          showCopyButton: showCopyButton,
          showLanguageLabel: showLanguageLabel,
          fontSize: codeBlockFontSize,
          fontFamily: codeBlockFontFamily,
        ),
        'code': MarkdownCodeBuilder(
          showLineNumbers: false, // Never show line numbers for inline code
          showCopyButton: false, // Never show copy button for inline code
          showLanguageLabel: false, // Never show language label for inline code
          fontSize: codeBlockFontSize,
          fontFamily: codeBlockFontFamily,
        ),
      },
    );
  }
}