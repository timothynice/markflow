import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:markdown/markdown.dart' as md;

/// Custom renderer for definition lists
class DefinitionListRenderer extends MarkdownElementBuilder {
  @override
  Widget? visitElementAfter(md.Element element, TextStyle? preferredStyle) {
    // Handle definition lists
    if (element.tag == 'dl') {
      return _buildDefinitionList(element, preferredStyle);
    }

    // Handle definition terms
    if (element.tag == 'dt') {
      return _buildDefinitionTerm(element, preferredStyle);
    }

    // Handle definition descriptions
    if (element.tag == 'dd') {
      return _buildDefinitionDescription(element, preferredStyle);
    }

    return null;
  }

  Widget _buildDefinitionList(md.Element element, TextStyle? preferredStyle) {
    final children = <Widget>[];
    final terms = <md.Element>[];
    final definitions = <md.Element>[];

    // Group terms and definitions
    for (final child in element.children ?? <md.Node>[]) {
      if (child is md.Element) {
        if (child.tag == 'dt') {
          terms.add(child);
        } else if (child.tag == 'dd') {
          definitions.add(child);
        }
      }
    }

    // Create grouped definition items
    for (int i = 0; i < terms.length; i++) {
      final term = terms[i];
      final relatedDefinitions = <md.Element>[];

      // Find definitions that follow this term
      int definitionIndex = 0;
      for (final def in definitions) {
        if (definitionIndex >= i) {
          relatedDefinitions.add(def);
          if (definitionIndex == i ||
              (i + 1 < terms.length && definitionIndex >= i + 1)) {
            break;
          }
        }
        definitionIndex++;
      }

      children.add(_buildDefinitionItem(term, relatedDefinitions, preferredStyle));

      if (i < terms.length - 1) {
        children.add(const SizedBox(height: 12));
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: children,
    );
  }

  Widget _buildDefinitionItem(
    md.Element term,
    List<md.Element> definitions,
    TextStyle? preferredStyle
  ) {
    return Builder(
      builder: (context) {
        final theme = Theme.of(context);

        return Container(
          margin: const EdgeInsets.symmetric(vertical: 4),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceVariant.withOpacity(0.3),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: theme.colorScheme.outline.withOpacity(0.2),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Term
              Row(
                children: [
                  Icon(
                    Icons.label,
                    size: 16,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      term.textContent.trim(),
                      style: preferredStyle?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ),
                ],
              ),
              if (definitions.isNotEmpty) ...[
                const SizedBox(height: 8),
                // Definitions
                ...definitions.map((def) => Padding(
                  padding: const EdgeInsets.only(left: 24, bottom: 4),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Container(
                          width: 4,
                          height: 4,
                          decoration: BoxDecoration(
                            color: theme.colorScheme.onSurfaceVariant,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          def.textContent.trim(),
                          style: preferredStyle?.copyWith(
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                )),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildDefinitionTerm(md.Element element, TextStyle? preferredStyle) {
    // This method is not used as we handle terms in _buildDefinitionList
    return const SizedBox.shrink();
  }

  Widget _buildDefinitionDescription(md.Element element, TextStyle? preferredStyle) {
    // This method is not used as we handle descriptions in _buildDefinitionList
    return const SizedBox.shrink();
  }
}