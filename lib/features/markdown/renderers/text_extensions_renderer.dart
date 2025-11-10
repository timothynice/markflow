import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:markdown/markdown.dart' as md;

/// Custom renderer for text extensions (highlight, subscript, superscript)
class TextExtensionsRenderer extends MarkdownElementBuilder {
  @override
  Widget? visitElementAfter(md.Element element, TextStyle? preferredStyle) {
    switch (element.tag) {
      case 'mark':
        return _buildHighlight(element, preferredStyle);
      case 'sub':
        return _buildSubscript(element, preferredStyle);
      case 'sup':
        return _buildSuperscript(element, preferredStyle);
      default:
        return null;
    }
  }

  Widget _buildHighlight(md.Element element, TextStyle? preferredStyle) {
    final content = element.textContent;

    return Builder(
      builder: (context) {
        final theme = Theme.of(context);
        final isDark = theme.brightness == Brightness.dark;

        return Container(
          decoration: BoxDecoration(
            color: isDark ? Colors.yellow.withOpacity(0.3) : Colors.yellow.withOpacity(0.4),
            borderRadius: BorderRadius.circular(2),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 2),
          child: Text(
            content,
            style: preferredStyle?.copyWith(
              backgroundColor: Colors.transparent,
              color: isDark ? Colors.black87 : Colors.black,
              fontWeight: FontWeight.w500,
            ),
          ),
        );
      },
    );
  }

  Widget _buildSubscript(md.Element element, TextStyle? preferredStyle) {
    final content = element.textContent;

    return Text(
      content,
      style: preferredStyle?.copyWith(
        fontSize: (preferredStyle.fontSize ?? 14) * 0.75,
        height: 1.0,
      ),
      textScaleFactor: 0.75,
    );
  }

  Widget _buildSuperscript(md.Element element, TextStyle? preferredStyle) {
    final content = element.textContent;

    return Transform.translate(
      offset: const Offset(0, -4),
      child: Text(
        content,
        style: preferredStyle?.copyWith(
          fontSize: (preferredStyle.fontSize ?? 14) * 0.75,
          height: 1.0,
        ),
      ),
    );
  }
}

/// Enhanced strikethrough renderer with better styling
class StrikethroughRenderer extends MarkdownElementBuilder {
  @override
  Widget? visitElementAfter(md.Element element, TextStyle? preferredStyle) {
    if (element.tag == 'del' || element.tag == 's') {
      return _buildStrikethrough(element, preferredStyle);
    }
    return null;
  }

  Widget _buildStrikethrough(md.Element element, TextStyle? preferredStyle) {
    final content = element.textContent;

    return Builder(
      builder: (context) {
        final theme = Theme.of(context);

        return Text(
          content,
          style: preferredStyle?.copyWith(
            decoration: TextDecoration.lineThrough,
            decorationColor: theme.colorScheme.onSurface.withOpacity(0.6),
            decorationThickness: 2,
            color: theme.colorScheme.onSurface.withOpacity(0.7),
          ),
        );
      },
    );
  }
}