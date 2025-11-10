import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:markdown/markdown.dart' as md;

/// Custom renderer for footnotes
class FootnoteRenderer extends MarkdownElementBuilder {
  final Function(String footnoteId, BuildContext context)? onFootnoteTap;
  final bool enableInteraction;

  const FootnoteRenderer({
    this.onFootnoteTap,
    this.enableInteraction = true,
  });

  @override
  Widget? visitElementAfter(md.Element element, TextStyle? preferredStyle) {
    // Handle footnote references
    if (element.tag == 'a' &&
        element.attributes['class']?.contains('footnote-ref') == true) {
      return _buildFootnoteReference(element, preferredStyle);
    }

    // Handle footnote definitions
    if (element.tag == 'div' &&
        element.attributes['class']?.contains('footnote-definition') == true) {
      return _buildFootnoteDefinition(element, preferredStyle);
    }

    return null;
  }

  Widget _buildFootnoteReference(md.Element element, TextStyle? preferredStyle) {
    final footnoteId = element.attributes['data-footnote-ref'] ?? '';
    final content = element.textContent;

    return Builder(
      builder: (context) {
        final theme = Theme.of(context);

        return GestureDetector(
          onTap: enableInteraction
              ? () {
                  if (onFootnoteTap != null) {
                    onFootnoteTap!(footnoteId, context);
                  } else {
                    _showFootnotePopup(context, footnoteId, content);
                  }
                }
              : null,
          child: Container(
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(3),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
            child: Text(
              content,
              style: TextStyle(
                color: theme.colorScheme.primary,
                fontSize: (preferredStyle?.fontSize ?? 14) * 0.85,
                fontWeight: FontWeight.w500,
                height: 1.2,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildFootnoteDefinition(md.Element element, TextStyle? preferredStyle) {
    final footnoteId = element.attributes['data-footnote-id'] ?? '';
    final footnoteNumber = element.attributes['data-footnote-number'] ?? '';
    final content = element.textContent.trim();

    return Builder(
      builder: (context) {
        final theme = Theme.of(context);

        return Container(
          margin: const EdgeInsets.symmetric(vertical: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceVariant.withOpacity(0.5),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: theme.colorScheme.outline.withOpacity(0.2),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Footnote number
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    footnoteNumber,
                    style: TextStyle(
                      color: theme.colorScheme.onPrimary,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Footnote content
              Expanded(
                child: Text(
                  content,
                  style: preferredStyle?.copyWith(
                    fontSize: (preferredStyle.fontSize ?? 14) * 0.9,
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showFootnotePopup(BuildContext context, String footnoteId, String content) {
    showDialog(
      context: context,
      builder: (context) => FootnoteDialog(
        footnoteId: footnoteId,
        content: content,
      ),
    );
  }
}

/// Dialog for displaying footnote content
class FootnoteDialog extends StatelessWidget {
  final String footnoteId;
  final String content;

  const FootnoteDialog({
    super.key,
    required this.footnoteId,
    required this.content,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AlertDialog(
      title: Row(
        children: [
          Icon(
            Icons.info_outline,
            size: 20,
            color: theme.colorScheme.primary,
          ),
          const SizedBox(width: 8),
          Text(
            'Footnote $content',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
      content: Text(
        'Footnote content would be displayed here.',
        style: theme.textTheme.bodyMedium,
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
      ],
    );
  }
}

/// Widget for displaying footnotes at the bottom of content
class FootnotesSection extends StatelessWidget {
  final List<FootnoteData> footnotes;
  final TextStyle? style;

  const FootnotesSection({
    super.key,
    required this.footnotes,
    this.style,
  });

  @override
  Widget build(BuildContext context) {
    if (footnotes.isEmpty) return const SizedBox.shrink();

    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 24),
        Divider(color: theme.colorScheme.outline.withOpacity(0.3)),
        const SizedBox(height: 16),
        Text(
          'Footnotes',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        ...footnotes.map((footnote) => _buildFootnoteItem(context, footnote)),
      ],
    );
  }

  Widget _buildFootnoteItem(BuildContext context, FootnoteData footnote) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withOpacity(0.1),
              shape: BoxShape.circle,
              border: Border.all(
                color: theme.colorScheme.primary,
                width: 1,
              ),
            ),
            child: Center(
              child: Text(
                footnote.number.toString(),
                style: TextStyle(
                  color: theme.colorScheme.primary,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              footnote.content,
              style: style?.copyWith(
                fontSize: (style?.fontSize ?? 14) * 0.9,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Data class for footnote information
class FootnoteData {
  final String id;
  final int number;
  final String content;

  const FootnoteData({
    required this.id,
    required this.number,
    required this.content,
  });
}