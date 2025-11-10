/// Represents a single item in the document outline/table of contents
class OutlineItem {
  /// The header text without markdown formatting
  final String title;

  /// The header level (1-6 for H1-H6)
  final int level;

  /// The position in the text where this header starts
  final int position;

  /// A unique identifier for this outline item
  final String id;

  /// Child outline items (nested headers)
  final List<OutlineItem> children;

  /// Whether this item is currently active/selected
  final bool isActive;

  const OutlineItem({
    required this.title,
    required this.level,
    required this.position,
    required this.id,
    this.children = const [],
    this.isActive = false,
  });

  /// Creates a copy of this outline item with optional parameter overrides
  OutlineItem copyWith({
    String? title,
    int? level,
    int? position,
    String? id,
    List<OutlineItem>? children,
    bool? isActive,
  }) {
    return OutlineItem(
      title: title ?? this.title,
      level: level ?? this.level,
      position: position ?? this.position,
      id: id ?? this.id,
      children: children ?? this.children,
      isActive: isActive ?? this.isActive,
    );
  }

  /// Creates a copy of this outline item with updated active state for nested items
  OutlineItem updateActiveState(String activeId) {
    return copyWith(
      isActive: id == activeId,
      children: children.map((child) => child.updateActiveState(activeId)).toList(),
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is OutlineItem &&
        other.title == title &&
        other.level == level &&
        other.position == position &&
        other.id == id;
  }

  @override
  int get hashCode {
    return title.hashCode ^
        level.hashCode ^
        position.hashCode ^
        id.hashCode;
  }

  @override
  String toString() {
    return 'OutlineItem(title: $title, level: $level, position: $position, id: $id, children: ${children.length})';
  }
}