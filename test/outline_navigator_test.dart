import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:markflow/features/markdown/widgets/outline_navigator.dart';
import 'package:markflow/features/markdown/models/outline_item.dart';

void main() {
  group('OutlineNavigator Widget Tests', () {
    testWidgets('should display empty state when no outline items', (tester) async {
      var tappedItem;
      var toggledVisibility = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: OutlineNavigator(
              outline: [],
              onItemTap: (item) => tappedItem = item,
              isVisible: true,
              onToggleVisibility: () => toggledVisibility = true,
            ),
          ),
        ),
      );

      expect(find.text('No headers found'), findsOneWidget);
      expect(find.text('Add some headers to your document to see the outline here.'), findsOneWidget);
      expect(find.byIcon(Icons.article_outlined), findsOneWidget);
    });

    testWidgets('should display outline items when provided', (tester) async {
      const outline = [
        OutlineItem(
          title: 'First Header',
          level: 1,
          position: 0,
          id: 'first_0',
        ),
        OutlineItem(
          title: 'Second Header',
          level: 2,
          position: 50,
          id: 'second_50',
          children: [
            OutlineItem(
              title: 'Nested Header',
              level: 3,
              position: 100,
              id: 'nested_100',
            ),
          ],
        ),
      ];

      var tappedItem;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: OutlineNavigator(
              outline: outline,
              onItemTap: (item) => tappedItem = item,
              isVisible: true,
              onToggleVisibility: () {},
            ),
          ),
        ),
      );

      expect(find.text('First Header'), findsOneWidget);
      expect(find.text('Second Header'), findsOneWidget);
      expect(find.text('Nested Header'), findsOneWidget);
    });

    testWidgets('should call onItemTap when item is tapped', (tester) async {
      const outline = [
        OutlineItem(
          title: 'Test Header',
          level: 1,
          position: 0,
          id: 'test_0',
        ),
      ];

      OutlineItem? tappedItem;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: OutlineNavigator(
              outline: outline,
              onItemTap: (item) => tappedItem = item,
              isVisible: true,
              onToggleVisibility: () {},
            ),
          ),
        ),
      );

      await tester.tap(find.text('Test Header'));
      await tester.pump();

      expect(tappedItem, isNotNull);
      expect(tappedItem?.title, 'Test Header');
    });

    testWidgets('should display toggle button and call onToggleVisibility', (tester) async {
      var visibilityToggled = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: OutlineNavigator(
              outline: [],
              onItemTap: (item) {},
              isVisible: true,
              onToggleVisibility: () => visibilityToggled = true,
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.chevron_left), findsOneWidget);

      await tester.tap(find.byIcon(Icons.chevron_left));
      await tester.pump();

      expect(visibilityToggled, isTrue);
    });

    testWidgets('should show different icons for visible/hidden state', (tester) async {
      Widget buildNavigator(bool visible) {
        return MaterialApp(
          home: Scaffold(
            body: OutlineNavigator(
              outline: [],
              onItemTap: (item) {},
              isVisible: visible,
              onToggleVisibility: () {},
            ),
          ),
        );
      }

      // Test visible state
      await tester.pumpWidget(buildNavigator(true));
      expect(find.byIcon(Icons.chevron_left), findsOneWidget);

      // Test hidden state
      await tester.pumpWidget(buildNavigator(false));
      await tester.pump();
      expect(find.byIcon(Icons.chevron_right), findsOneWidget);
    });

    testWidgets('should handle expandable items correctly', (tester) async {
      const outline = [
        OutlineItem(
          title: 'Parent Header',
          level: 1,
          position: 0,
          id: 'parent_0',
          children: [
            OutlineItem(
              title: 'Child Header',
              level: 2,
              position: 50,
              id: 'child_50',
            ),
          ],
        ),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: OutlineNavigator(
              outline: outline,
              onItemTap: (item) {},
              isVisible: true,
              onToggleVisibility: () {},
            ),
          ),
        ),
      );

      // Should show both parent and child initially (expanded by default)
      expect(find.text('Parent Header'), findsOneWidget);
      expect(find.text('Child Header'), findsOneWidget);
      expect(find.byIcon(Icons.expand_more), findsOneWidget);

      // Tap to collapse
      await tester.tap(find.byIcon(Icons.expand_more));
      await tester.pump();

      // Should show collapsed state
      expect(find.text('Parent Header'), findsOneWidget);
      expect(find.text('Child Header'), findsNothing);
      expect(find.byIcon(Icons.chevron_right), findsOneWidget);
    });

    testWidgets('should highlight active items correctly', (tester) async {
      const outline = [
        OutlineItem(
          title: 'Active Header',
          level: 1,
          position: 0,
          id: 'active_0',
          isActive: true,
        ),
        OutlineItem(
          title: 'Inactive Header',
          level: 1,
          position: 50,
          id: 'inactive_50',
          isActive: false,
        ),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: OutlineNavigator(
              outline: outline,
              onItemTap: (item) {},
              isVisible: true,
              onToggleVisibility: () {},
            ),
          ),
        ),
      );

      expect(find.text('Active Header'), findsOneWidget);
      expect(find.text('Inactive Header'), findsOneWidget);

      // The active item should have different styling
      // This is a simplified test - in practice, you'd check for specific styling
      final activeText = tester.widget<Text>(find.text('Active Header'));
      final inactiveText = tester.widget<Text>(find.text('Inactive Header'));

      expect(activeText.style?.fontWeight, FontWeight.w600);
      expect(inactiveText.style?.fontWeight, FontWeight.w500);
    });

    testWidgets('should show Table of Contents header', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: OutlineNavigator(
              outline: [],
              onItemTap: (item) {},
              isVisible: true,
              onToggleVisibility: () {},
            ),
          ),
        ),
      );

      expect(find.text('Table of Contents'), findsOneWidget);
      expect(find.byIcon(Icons.list_alt), findsOneWidget);
    });

    testWidgets('should handle compact mode', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: OutlineNavigator(
              outline: [],
              onItemTap: (item) {},
              isVisible: true,
              onToggleVisibility: () {},
              isCompact: true,
            ),
          ),
        ),
      );

      // In compact mode, the widget should be narrower
      // This test verifies the widget still renders correctly
      expect(find.text('Table of Contents'), findsOneWidget);
    });
  });
}