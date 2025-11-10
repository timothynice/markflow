import 'dart:math';
import '../models/outline_item.dart';

/// Service for parsing markdown headers and building document outline
class OutlineService {
  /// Parses markdown content and returns a hierarchical list of outline items
  static List<OutlineItem> parseOutline(String content) {
    if (content.isEmpty) return [];

    final lines = content.split('\n');
    final flatItems = <OutlineItem>[];

    int position = 0;

    // First pass: extract all headers
    for (int i = 0; i < lines.length; i++) {
      final line = lines[i];
      final headerMatch = _parseHeaderLine(line);

      if (headerMatch != null) {
        final item = OutlineItem(
          title: headerMatch.title,
          level: headerMatch.level,
          position: position,
          id: _generateId(headerMatch.title, position),
        );
        flatItems.add(item);
      }

      // Update position for next line (including newline character)
      position += line.length + 1;
    }

    // Second pass: build hierarchy
    return _buildHierarchy(flatItems);
  }

  /// Finds the closest header to a given text position
  static OutlineItem? findNearestHeader(List<OutlineItem> outline, int position) {
    OutlineItem? nearest;

    void searchItems(List<OutlineItem> items) {
      for (final item in items) {
        if (item.position <= position) {
          if (nearest == null || item.position > nearest!.position) {
            nearest = item;
          }
        }
        searchItems(item.children);
      }
    }

    searchItems(outline);
    return nearest;
  }

  /// Updates the active state of outline items based on current position
  static List<OutlineItem> updateActiveItem(List<OutlineItem> outline, int position) {
    final activeItem = findNearestHeader(outline, position);
    final activeId = activeItem?.id;

    return outline.map((item) => item.updateActiveState(activeId ?? '')).toList();
  }

  /// Flattens a hierarchical outline into a flat list
  static List<OutlineItem> flattenOutline(List<OutlineItem> outline) {
    final result = <OutlineItem>[];

    void addItems(List<OutlineItem> items) {
      for (final item in items) {
        result.add(item);
        addItems(item.children);
      }
    }

    addItems(outline);
    return result;
  }

  /// Gets all header positions for smooth scrolling calculations
  static List<int> getHeaderPositions(List<OutlineItem> outline) {
    return flattenOutline(outline).map((item) => item.position).toList()..sort();
  }

  // Private helper methods

  static _HeaderMatch? _parseHeaderLine(String line) {
    // ATX headers (# Header)
    final atxMatch = RegExp(r'^(#{1,6})\s+(.+)$').firstMatch(line.trim());
    if (atxMatch != null) {
      return _HeaderMatch(
        level: atxMatch.group(1)!.length,
        title: atxMatch.group(2)!.trim(),
      );
    }

    // Could add Setext headers (underlined with = or -) here if needed
    // For now, focusing on ATX headers which are more common

    return null;
  }

  static List<OutlineItem> _buildHierarchy(List<OutlineItem> flatItems) {
    if (flatItems.isEmpty) return [];

    final result = <OutlineItem>[];
    final stack = <OutlineItem>[];

    for (final item in flatItems) {
      // Find the appropriate parent level
      while (stack.isNotEmpty && stack.last.level >= item.level) {
        stack.removeLast();
      }

      if (stack.isEmpty) {
        // Top-level item
        result.add(item);
        stack.add(item);
      } else {
        // Child item - add to parent's children
        final parent = stack.last;
        final updatedParent = parent.copyWith(
          children: [...parent.children, item],
        );

        // Update the parent in the stack
        stack[stack.length - 1] = updatedParent;
        stack.add(item);

        // Update the parent in the result tree
        _updateItemInTree(result, parent.id, updatedParent);
      }
    }

    return result;
  }

  static void _updateItemInTree(List<OutlineItem> tree, String targetId, OutlineItem updatedItem) {
    for (int i = 0; i < tree.length; i++) {
      if (tree[i].id == targetId) {
        tree[i] = updatedItem;
        return;
      }
      _updateItemInTree(tree[i].children, targetId, updatedItem);
    }
  }

  static String _generateId(String title, int position) {
    // Create a URL-friendly slug from the title
    final slug = title
        .toLowerCase()
        .replaceAll(RegExp(r'[^\w\s-]'), '')  // Remove special characters
        .replaceAll(RegExp(r'\s+'), '-')       // Replace spaces with hyphens
        .replaceAll(RegExp(r'-+'), '-')        // Collapse multiple hyphens
        .replaceAll(RegExp(r'^-|-$'), '');     // Remove leading/trailing hyphens

    // Ensure uniqueness by including position
    return '${slug}_$position';
  }
}

/// Internal class for header parsing results
class _HeaderMatch {
  final int level;
  final String title;

  _HeaderMatch({required this.level, required this.title});
}