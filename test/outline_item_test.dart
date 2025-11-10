import 'package:flutter_test/flutter_test.dart';
import 'package:markflow/features/markdown/models/outline_item.dart';

void main() {
  group('OutlineItem', () {
    test('should create outline item with required properties', () {
      const item = OutlineItem(
        title: 'Test Header',
        level: 2,
        position: 100,
        id: 'test-header_100',
      );

      expect(item.title, 'Test Header');
      expect(item.level, 2);
      expect(item.position, 100);
      expect(item.id, 'test-header_100');
      expect(item.children, isEmpty);
      expect(item.isActive, isFalse);
    });

    test('should create outline item with children', () {
      const child = OutlineItem(
        title: 'Child Header',
        level: 3,
        position: 150,
        id: 'child-header_150',
      );

      const parent = OutlineItem(
        title: 'Parent Header',
        level: 2,
        position: 100,
        id: 'parent-header_100',
        children: [child],
      );

      expect(parent.children, hasLength(1));
      expect(parent.children[0], equals(child));
    });

    test('should support copyWith method', () {
      const original = OutlineItem(
        title: 'Original',
        level: 1,
        position: 0,
        id: 'original_0',
      );

      final copy = original.copyWith(
        title: 'Updated',
        isActive: true,
      );

      expect(copy.title, 'Updated');
      expect(copy.level, 1); // unchanged
      expect(copy.position, 0); // unchanged
      expect(copy.id, 'original_0'); // unchanged
      expect(copy.isActive, isTrue); // changed
    });

    test('should update active state recursively', () {
      const grandchild = OutlineItem(
        title: 'Grandchild',
        level: 3,
        position: 200,
        id: 'grandchild_200',
      );

      const child = OutlineItem(
        title: 'Child',
        level: 2,
        position: 150,
        id: 'child_150',
        children: [grandchild],
      );

      const parent = OutlineItem(
        title: 'Parent',
        level: 1,
        position: 100,
        id: 'parent_100',
        children: [child],
      );

      // Update to make child active
      final updated = parent.updateActiveState('child_150');

      expect(updated.isActive, isFalse);
      expect(updated.children[0].isActive, isTrue);
      expect(updated.children[0].children[0].isActive, isFalse);
    });

    test('should handle equality correctly', () {
      const item1 = OutlineItem(
        title: 'Test',
        level: 1,
        position: 0,
        id: 'test_0',
      );

      const item2 = OutlineItem(
        title: 'Test',
        level: 1,
        position: 0,
        id: 'test_0',
        isActive: true, // Different active state
      );

      const item3 = OutlineItem(
        title: 'Different',
        level: 1,
        position: 0,
        id: 'test_0',
      );

      expect(item1, equals(item2)); // Same core properties
      expect(item1, isNot(equals(item3))); // Different title
    });

    test('should generate consistent hash codes', () {
      const item1 = OutlineItem(
        title: 'Test',
        level: 1,
        position: 0,
        id: 'test_0',
      );

      const item2 = OutlineItem(
        title: 'Test',
        level: 1,
        position: 0,
        id: 'test_0',
        isActive: true,
      );

      expect(item1.hashCode, equals(item2.hashCode));
    });

    test('should generate meaningful toString', () {
      const item = OutlineItem(
        title: 'Test Header',
        level: 2,
        position: 100,
        id: 'test-header_100',
        children: [
          OutlineItem(title: 'Child', level: 3, position: 150, id: 'child_150'),
        ],
      );

      final string = item.toString();
      expect(string, contains('Test Header'));
      expect(string, contains('level: 2'));
      expect(string, contains('position: 100'));
      expect(string, contains('children: 1'));
    });
  });
}