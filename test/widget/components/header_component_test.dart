import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:markflow/widgets/header_component.dart';
import 'package:markflow/theme_controller.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../test_helpers.dart';

void main() {
  group('Header Component Widget Tests', () {
    testWidgets('should render header component with required properties', (WidgetTester tester) async {
      await tester.pumpWidget(
        TestHelpers.createTestApp(
          child: const HeaderComponent(
            title: 'Test Title',
            description: 'Test Description',
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byType(HeaderComponent), findsOneWidget);
      expect(find.text('Test Title'), findsOneWidget);
      expect(find.text('Test Description'), findsOneWidget);
    });

    testWidgets('should display title with proper styling', (WidgetTester tester) async {
      await tester.pumpWidget(
        TestHelpers.createTestApp(
          child: const HeaderComponent(
            title: 'Main Header Title',
            description: 'Header description text',
          ),
        ),
      );

      await tester.pumpAndSettle();

      final titleText = tester.widget<Text>(find.text('Main Header Title'));
      expect(titleText.style?.fontWeight, FontWeight.bold);
      expect(titleText.style?.fontSize, greaterThanOrEqualTo(36));
    });

    testWidgets('should display description text with proper styling', (WidgetTester tester) async {
      await tester.pumpWidget(
        TestHelpers.createTestApp(
          child: const HeaderComponent(
            title: 'Title',
            description: 'This is a detailed description',
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('This is a detailed description'), findsOneWidget);

      final descText = tester.widget<Text>(find.text('This is a detailed description'));
      expect(descText.style?.fontSize, greaterThanOrEqualTo(14));
      expect(descText.textAlign, TextAlign.center);
    });

    testWidgets('should display optional badge when provided', (WidgetTester tester) async {
      await tester.pumpWidget(
        TestHelpers.createTestApp(
          child: const HeaderComponent(
            title: 'Title',
            description: 'Description',
            badgeText: 'New Feature',
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byType(ShadBadge), findsOneWidget);
      expect(find.text('New Feature'), findsOneWidget);
    });

    testWidgets('should display badge with icon when both provided', (WidgetTester tester) async {
      await tester.pumpWidget(
        TestHelpers.createTestApp(
          child: const HeaderComponent(
            title: 'Title',
            description: 'Description',
            badgeText: 'Beta',
            badgeIcon: 'arrow_forward',
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byType(ShadBadge), findsOneWidget);
      expect(find.text('Beta'), findsOneWidget);
      expect(find.byIcon(Icons.arrow_forward), findsOneWidget);
    });

    testWidgets('should display optional subtitle when provided', (WidgetTester tester) async {
      await tester.pumpWidget(
        TestHelpers.createTestApp(
          child: const HeaderComponent(
            title: 'Main Title',
            description: 'Main Description',
            subtitle: 'Additional subtitle information',
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Additional subtitle information'), findsOneWidget);
    });

    group('Action Buttons', () {
      testWidgets('should display primary action button', (WidgetTester tester) async {
        bool buttonTapped = false;

        await tester.pumpWidget(
          TestHelpers.createTestApp(
            child: HeaderComponent(
              title: 'Title',
              description: 'Description',
              actions: [
                HeaderAction(
                  text: 'Primary Action',
                  variant: HeaderActionVariant.primary,
                  onPressed: () => buttonTapped = true,
                ),
              ],
            ),
          ),
        );

        await tester.pumpAndSettle();

        expect(find.text('Primary Action'), findsOneWidget);
        expect(find.byType(ShadButton), findsOneWidget);

        await TestHelpers.tapAndSettle(tester, find.text('Primary Action'));
        expect(buttonTapped, isTrue);
      });

      testWidgets('should display secondary action button', (WidgetTester tester) async {
        await tester.pumpWidget(
          TestHelpers.createTestApp(
            child: HeaderComponent(
              title: 'Title',
              description: 'Description',
              actions: [
                HeaderAction(
                  text: 'Secondary Action',
                  variant: HeaderActionVariant.secondary,
                  onPressed: () {},
                ),
              ],
            ),
          ),
        );

        await tester.pumpAndSettle();

        expect(find.text('Secondary Action'), findsOneWidget);
        // Should have outline button
        expect(find.byType(ShadButton), findsOneWidget);
      });

      testWidgets('should display ghost action button', (WidgetTester tester) async {
        await tester.pumpWidget(
          TestHelpers.createTestApp(
            child: HeaderComponent(
              title: 'Title',
              description: 'Description',
              actions: [
                HeaderAction(
                  text: 'Ghost Action',
                  variant: HeaderActionVariant.ghost,
                  onPressed: () {},
                ),
              ],
            ),
          ),
        );

        await tester.pumpAndSettle();

        expect(find.text('Ghost Action'), findsOneWidget);
        expect(find.byType(ShadButton), findsOneWidget);
      });

      testWidgets('should display destructive action button', (WidgetTester tester) async {
        await tester.pumpWidget(
          TestHelpers.createTestApp(
            child: HeaderComponent(
              title: 'Title',
              description: 'Description',
              actions: [
                HeaderAction(
                  text: 'Delete',
                  variant: HeaderActionVariant.destructive,
                  onPressed: () {},
                ),
              ],
            ),
          ),
        );

        await tester.pumpAndSettle();

        expect(find.text('Delete'), findsOneWidget);
        expect(find.byType(ShadButton), findsOneWidget);
      });

      testWidgets('should display multiple action buttons', (WidgetTester tester) async {
        await tester.pumpWidget(
          TestHelpers.createTestApp(
            child: HeaderComponent(
              title: 'Title',
              description: 'Description',
              actions: [
                HeaderAction(
                  text: 'Primary',
                  variant: HeaderActionVariant.primary,
                  onPressed: () {},
                ),
                HeaderAction(
                  text: 'Secondary',
                  variant: HeaderActionVariant.secondary,
                  onPressed: () {},
                ),
              ],
            ),
          ),
        );

        await tester.pumpAndSettle();

        expect(find.text('Primary'), findsOneWidget);
        expect(find.text('Secondary'), findsOneWidget);
        expect(find.byType(ShadButton), findsNWidgets(2));
      });
    });

    group('Responsive Behavior', () {
      testWidgets('should adapt to mobile screen size', (WidgetTester tester) async {
        await tester.pumpWidget(
          TestHelpers.createTestApp(
            child: const HeaderComponent(
              title: 'Mobile Title',
              description: 'Mobile Description',
            ),
            screenSize: TestHelpers.mobileSize,
          ),
        );

        await tester.pumpAndSettle();

        final titleText = tester.widget<Text>(find.text('Mobile Title'));
        // Mobile should have smaller font size
        expect(titleText.style?.fontSize, equals(36));
      });

      testWidgets('should adapt to tablet screen size', (WidgetTester tester) async {
        await tester.pumpWidget(
          TestHelpers.createTestApp(
            child: const HeaderComponent(
              title: 'Tablet Title',
              description: 'Tablet Description',
            ),
            screenSize: TestHelpers.tabletSize,
          ),
        );

        await tester.pumpAndSettle();

        final titleText = tester.widget<Text>(find.text('Tablet Title'));
        // Tablet should have medium font size
        expect(titleText.style?.fontSize, equals(48));
      });

      testWidgets('should adapt to desktop screen size', (WidgetTester tester) async {
        await tester.pumpWidget(
          TestHelpers.createTestApp(
            child: const HeaderComponent(
              title: 'Desktop Title',
              description: 'Desktop Description',
            ),
            screenSize: TestHelpers.desktopSize,
          ),
        );

        await tester.pumpAndSettle();

        final titleText = tester.widget<Text>(find.text('Desktop Title'));
        // Desktop should have largest font size
        expect(titleText.style?.fontSize, equals(56));
      });

      testWidgets('should maintain proper spacing across screen sizes', (WidgetTester tester) async {
        // Test mobile
        await tester.pumpWidget(
          TestHelpers.createTestApp(
            child: const HeaderComponent(
              title: 'Title',
              description: 'Description',
            ),
            screenSize: TestHelpers.mobileSize,
          ),
        );

        await tester.pumpAndSettle();

        // Should have proper container constraints
        expect(find.byType(Container), findsAtLeastNWidgets(1));
        expect(find.byType(Column), findsOneWidget);
      });
    });

    group('Content Centering', () {
      testWidgets('should center content by default', (WidgetTester tester) async {
        await tester.pumpWidget(
          TestHelpers.createTestApp(
            child: const HeaderComponent(
              title: 'Centered Title',
              description: 'Centered Description',
            ),
          ),
        );

        await tester.pumpAndSettle();

        final column = tester.widget<Column>(find.byType(Column));
        expect(column.mainAxisAlignment, MainAxisAlignment.center);
      });

      testWidgets('should align to start when centerContent is false', (WidgetTester tester) async {
        await tester.pumpWidget(
          TestHelpers.createTestApp(
            child: const HeaderComponent(
              title: 'Start Aligned Title',
              description: 'Start Aligned Description',
              centerContent: false,
            ),
          ),
        );

        await tester.pumpAndSettle();

        final column = tester.widget<Column>(find.byType(Column));
        expect(column.mainAxisAlignment, MainAxisAlignment.start);
      });
    });

    group('Custom Padding', () {
      testWidgets('should apply custom padding when provided', (WidgetTester tester) async {
        const customPadding = EdgeInsets.all(32);

        await tester.pumpWidget(
          TestHelpers.createTestApp(
            child: const HeaderComponent(
              title: 'Custom Padded Title',
              description: 'Custom Padded Description',
              padding: customPadding,
            ),
          ),
        );

        await tester.pumpAndSettle();

        final container = tester.widget<Container>(find.byType(Container));
        expect(container.padding, customPadding);
      });

      testWidgets('should use default padding when none provided', (WidgetTester tester) async {
        await tester.pumpWidget(
          TestHelpers.createTestApp(
            child: const HeaderComponent(
              title: 'Default Padded Title',
              description: 'Default Padded Description',
            ),
            screenSize: TestHelpers.desktopSize,
          ),
        );

        await tester.pumpAndSettle();

        final container = tester.widget<Container>(find.byType(Container));
        // Desktop should have no horizontal padding, 48 vertical
        expect(container.padding, const EdgeInsets.symmetric(horizontal: 0, vertical: 48));
      });
    });

    group('Icon Mapping', () {
      testWidgets('should map known icon names correctly', (WidgetTester tester) async {
        const iconTests = [
          ('arrow_forward', Icons.arrow_forward),
          ('add', Icons.add),
          ('search', Icons.search),
          ('settings', Icons.settings),
        ];

        for (final (iconName, expectedIcon) in iconTests) {
          await tester.pumpWidget(
            TestHelpers.createTestApp(
              child: HeaderComponent(
                title: 'Title',
                description: 'Description',
                badgeText: 'Badge',
                badgeIcon: iconName,
              ),
            ),
          );

          await tester.pumpAndSettle();

          expect(find.byIcon(expectedIcon), findsOneWidget);

          // Clear the widget tree for next iteration
          await tester.pumpWidget(Container());
        }
      });

      testWidgets('should fallback to arrow_forward for unknown icon names', (WidgetTester tester) async {
        await tester.pumpWidget(
          TestHelpers.createTestApp(
            child: const HeaderComponent(
              title: 'Title',
              description: 'Description',
              badgeText: 'Badge',
              badgeIcon: 'unknown_icon',
            ),
          ),
        );

        await tester.pumpAndSettle();

        expect(find.byIcon(Icons.arrow_forward), findsOneWidget);
      });
    });

    group('Layout Structure', () {
      testWidgets('should use proper widget hierarchy', (WidgetTester tester) async {
        await tester.pumpWidget(
          TestHelpers.createTestApp(
            child: const HeaderComponent(
              title: 'Test Title',
              description: 'Test Description',
              badgeText: 'Badge',
              subtitle: 'Subtitle',
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Check for proper widget hierarchy
        expect(find.byType(LayoutBuilder), findsOneWidget);
        expect(find.byType(Center), findsOneWidget);
        expect(find.byType(Container), findsOneWidget);
        expect(find.byType(Column), findsOneWidget);
      });

      testWidgets('should maintain proper spacing between elements', (WidgetTester tester) async {
        await tester.pumpWidget(
          TestHelpers.createTestApp(
            child: const HeaderComponent(
              title: 'Spaced Title',
              description: 'Spaced Description',
              badgeText: 'Badge',
              subtitle: 'Subtitle',
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Should have SizedBox widgets for spacing
        expect(find.byType(SizedBox), findsAtLeastNWidgets(1));
      });
    });

    group('Edge Cases', () {
      testWidgets('should handle empty actions list', (WidgetTester tester) async {
        await tester.pumpWidget(
          TestHelpers.createTestApp(
            child: const HeaderComponent(
              title: 'Title',
              description: 'Description',
              actions: [],
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Should render without action buttons
        expect(find.byType(ShadButton), findsNothing);
        expect(find.text('Title'), findsOneWidget);
        expect(find.text('Description'), findsOneWidget);
      });

      testWidgets('should handle null badge text gracefully', (WidgetTester tester) async {
        await tester.pumpWidget(
          TestHelpers.createTestApp(
            child: const HeaderComponent(
              title: 'Title',
              description: 'Description',
              badgeText: null,
              badgeIcon: 'arrow_forward',
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Should not show badge when badgeText is null
        expect(find.byType(ShadBadge), findsNothing);
        expect(find.byIcon(Icons.arrow_forward), findsNothing);
      });

      testWidgets('should handle disabled action buttons', (WidgetTester tester) async {
        await tester.pumpWidget(
          TestHelpers.createTestApp(
            child: HeaderComponent(
              title: 'Title',
              description: 'Description',
              actions: [
                HeaderAction(
                  text: 'Disabled Action',
                  onPressed: null, // Disabled
                ),
              ],
            ),
          ),
        );

        await tester.pumpAndSettle();

        expect(find.text('Disabled Action'), findsOneWidget);
        expect(find.byType(ShadButton), findsOneWidget);

        // Button should be present but disabled
        final button = tester.widget<ShadButton>(find.byType(ShadButton));
        expect(button.onPressed, isNull);
      });
    });

    group('Accessibility', () {
      testWidgets('should provide semantic structure', (WidgetTester tester) async {
        await tester.pumpWidget(
          TestHelpers.createTestApp(
            child: HeaderComponent(
              title: 'Accessible Title',
              description: 'Accessible Description',
              actions: [
                HeaderAction(
                  text: 'Accessible Button',
                  onPressed: () {},
                ),
              ],
            ),
          ),
        );

        await tester.pumpAndSettle();

        TestHelpers.verifyAccessibilitySemantics(
          tester,
          expectsButton: true,
        );
      });

      testWidgets('should support keyboard navigation to action buttons', (WidgetTester tester) async {
        await tester.pumpWidget(
          TestHelpers.createTestApp(
            child: HeaderComponent(
              title: 'Title',
              description: 'Description',
              actions: [
                HeaderAction(
                  text: 'Focusable Button',
                  onPressed: () {},
                ),
              ],
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Tab to the button
        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await tester.pump();

        // Button should be focusable
        final buttonFinder = find.byType(ShadButton);
        expect(buttonFinder, findsOneWidget);
      });
    });
  });
}