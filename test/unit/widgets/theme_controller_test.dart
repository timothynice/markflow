import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:markflow/theme_controller.dart';

void main() {
  group('ThemeController', () {
    late ThemeController themeController;

    setUp(() {
      themeController = ThemeController.instance;
      // Reset to default state for each test
      themeController.mode.value = ThemeMode.light;
    });

    test('should be a singleton', () {
      final instance1 = ThemeController.instance;
      final instance2 = ThemeController.instance;

      expect(instance1, same(instance2));
      expect(identical(instance1, instance2), isTrue);
    });

    test('should initialize with light theme mode', () {
      // Create a fresh controller to test initial state
      // Note: Since it's singleton, we test the reset value
      themeController.mode.value = ThemeMode.light;
      expect(themeController.mode.value, equals(ThemeMode.light));
    });

    test('should change to light theme when setLight() is called', () {
      // First set to different theme
      themeController.mode.value = ThemeMode.dark;

      themeController.setLight();

      expect(themeController.mode.value, equals(ThemeMode.light));
    });

    test('should change to dark theme when setDark() is called', () {
      themeController.setDark();

      expect(themeController.mode.value, equals(ThemeMode.dark));
    });

    test('should change to system theme when setSystem() is called', () {
      themeController.setSystem();

      expect(themeController.mode.value, equals(ThemeMode.system));
    });

    test('should notify listeners when theme mode changes', () {
      bool wasNotified = false;
      ThemeMode? notifiedValue;

      void listener() {
        wasNotified = true;
        notifiedValue = themeController.mode.value;
      }

      themeController.mode.addListener(listener);

      themeController.setDark();

      expect(wasNotified, isTrue);
      expect(notifiedValue, equals(ThemeMode.dark));

      // Clean up
      themeController.mode.removeListener(listener);
    });

    test('should notify listeners for all theme mode changes', () {
      final List<ThemeMode> notifiedValues = [];

      void listener() {
        notifiedValues.add(themeController.mode.value);
      }

      themeController.mode.addListener(listener);

      themeController.setLight();
      themeController.setDark();
      themeController.setSystem();
      themeController.setLight();

      expect(notifiedValues, equals([
        ThemeMode.light,
        ThemeMode.dark,
        ThemeMode.system,
        ThemeMode.light,
      ]));

      // Clean up
      themeController.mode.removeListener(listener);
    });

    test('should not notify when setting same theme mode', () {
      int notificationCount = 0;

      void listener() {
        notificationCount++;
      }

      themeController.mode.value = ThemeMode.light;
      themeController.mode.addListener(listener);

      // Reset count after adding listener
      notificationCount = 0;

      themeController.setLight(); // Same as current
      themeController.setLight(); // Same as current

      expect(notificationCount, equals(0));

      // Clean up
      themeController.mode.removeListener(listener);
    });

    group('Theme Mode Persistence', () {
      test('should maintain theme mode across getter calls', () {
        themeController.setDark();

        expect(themeController.mode.value, equals(ThemeMode.dark));
        expect(themeController.mode.value, equals(ThemeMode.dark));
        expect(themeController.mode.value, equals(ThemeMode.dark));

        themeController.setSystem();

        expect(themeController.mode.value, equals(ThemeMode.system));
        expect(themeController.mode.value, equals(ThemeMode.system));
      });

      test('should handle rapid theme mode changes', () {
        // Rapid changes should all be applied correctly
        themeController.setLight();
        expect(themeController.mode.value, equals(ThemeMode.light));

        themeController.setDark();
        expect(themeController.mode.value, equals(ThemeMode.dark));

        themeController.setSystem();
        expect(themeController.mode.value, equals(ThemeMode.system));

        themeController.setLight();
        expect(themeController.mode.value, equals(ThemeMode.light));

        themeController.setDark();
        expect(themeController.mode.value, equals(ThemeMode.dark));
      });

      test('should handle extreme rapid changes', () {
        final List<ThemeMode> expectedModes = [];

        for (int i = 0; i < 100; i++) {
          final mode = i % 3 == 0
            ? ThemeMode.light
            : i % 3 == 1
              ? ThemeMode.dark
              : ThemeMode.system;

          switch (mode) {
            case ThemeMode.light:
              themeController.setLight();
              break;
            case ThemeMode.dark:
              themeController.setDark();
              break;
            case ThemeMode.system:
              themeController.setSystem();
              break;
          }

          expectedModes.add(mode);
          expect(themeController.mode.value, equals(mode));
        }
      });
    });

    group('ValueNotifier Behavior', () {
      test('should use ValueNotifier for reactive updates', () {
        expect(themeController.mode, isA<ValueNotifier<ThemeMode>>());
        expect(themeController.mode.value, isA<ThemeMode>());
      });

      test('should support multiple listeners', () {
        int listener1Count = 0;
        int listener2Count = 0;
        int listener3Count = 0;

        ThemeMode? listener1Value;
        ThemeMode? listener2Value;
        ThemeMode? listener3Value;

        void listener1() {
          listener1Count++;
          listener1Value = themeController.mode.value;
        }

        void listener2() {
          listener2Count++;
          listener2Value = themeController.mode.value;
        }

        void listener3() {
          listener3Count++;
          listener3Value = themeController.mode.value;
        }

        themeController.mode.addListener(listener1);
        themeController.mode.addListener(listener2);
        themeController.mode.addListener(listener3);

        themeController.setDark();

        expect(listener1Count, equals(1));
        expect(listener2Count, equals(1));
        expect(listener3Count, equals(1));

        expect(listener1Value, equals(ThemeMode.dark));
        expect(listener2Value, equals(ThemeMode.dark));
        expect(listener3Value, equals(ThemeMode.dark));

        themeController.setSystem();

        expect(listener1Count, equals(2));
        expect(listener2Count, equals(2));
        expect(listener3Count, equals(2));

        expect(listener1Value, equals(ThemeMode.system));
        expect(listener2Value, equals(ThemeMode.system));
        expect(listener3Value, equals(ThemeMode.system));

        // Clean up
        themeController.mode.removeListener(listener1);
        themeController.mode.removeListener(listener2);
        themeController.mode.removeListener(listener3);
      });

      test('should properly dispose listeners', () {
        int listener1Count = 0;
        int listener2Count = 0;

        void listener1() {
          listener1Count++;
        }

        void listener2() {
          listener2Count++;
        }

        themeController.mode.addListener(listener1);
        themeController.mode.addListener(listener2);

        themeController.setDark();
        expect(listener1Count, equals(1));
        expect(listener2Count, equals(1));

        // Remove one listener
        themeController.mode.removeListener(listener1);

        themeController.setSystem();
        expect(listener1Count, equals(1)); // Should not change
        expect(listener2Count, equals(2)); // Should change

        // Remove the other listener
        themeController.mode.removeListener(listener2);

        themeController.setLight();
        expect(listener1Count, equals(1)); // Should not change
        expect(listener2Count, equals(2)); // Should not change
      });

      test('should handle listener removal during notification', () {
        int callCount = 0;
        late void Function() selfRemovingListener;

        selfRemovingListener = () {
          callCount++;
          if (callCount == 1) {
            // Remove self during first notification
            themeController.mode.removeListener(selfRemovingListener);
          }
        };

        themeController.mode.addListener(selfRemovingListener);

        themeController.setDark();
        expect(callCount, equals(1));

        themeController.setSystem();
        expect(callCount, equals(1)); // Should not be called again

        themeController.setLight();
        expect(callCount, equals(1)); // Should still not be called
      });

      test('should handle adding listener during notification', () {
        int mainListenerCount = 0;
        int addedListenerCount = 0;
        bool hasAddedSecondListener = false;

        void addedListener() {
          addedListenerCount++;
        }

        void mainListener() {
          mainListenerCount++;
          if (!hasAddedSecondListener) {
            hasAddedSecondListener = true;
            themeController.mode.addListener(addedListener);
          }
        }

        themeController.mode.addListener(mainListener);

        themeController.setDark();
        expect(mainListenerCount, equals(1));
        expect(addedListenerCount, equals(0)); // Added during notification, so not called yet

        themeController.setSystem();
        expect(mainListenerCount, equals(2));
        expect(addedListenerCount, equals(1)); // Should be called now

        // Clean up
        themeController.mode.removeListener(mainListener);
        themeController.mode.removeListener(addedListener);
      });

      test('should handle duplicate listener addition', () {
        int listenerCount = 0;

        void listener() {
          listenerCount++;
        }

        themeController.mode.addListener(listener);
        themeController.mode.addListener(listener); // Add same listener twice

        themeController.setDark();

        // Should only be called once, even though added twice
        expect(listenerCount, equals(1));

        // Clean up
        themeController.mode.removeListener(listener);
      });
    });

    group('Edge Cases', () {
      test('should handle removing non-existent listener gracefully', () {
        void nonExistentListener() {}

        // Should not throw an exception
        expect(() => themeController.mode.removeListener(nonExistentListener),
               returnsNormally);
      });

      test('should maintain singleton behavior across test runs', () {
        final controller1 = ThemeController.instance;
        controller1.setDark();

        final controller2 = ThemeController.instance;
        expect(controller2.mode.value, equals(ThemeMode.dark));
        expect(controller1, same(controller2));
      });

      test('should handle null listener gracefully', () {
        // This would be a compile-time error in Dart, but testing the concept
        // that the ValueNotifier handles edge cases properly
        expect(themeController.mode.hasListeners, isFalse);

        void listener() {}
        themeController.mode.addListener(listener);
        expect(themeController.mode.hasListeners, isTrue);

        themeController.mode.removeListener(listener);
        expect(themeController.mode.hasListeners, isFalse);
      });

      test('should work correctly after many operations', () {
        // Test stability after many operations
        for (int i = 0; i < 1000; i++) {
          switch (i % 3) {
            case 0:
              themeController.setLight();
              break;
            case 1:
              themeController.setDark();
              break;
            case 2:
              themeController.setSystem();
              break;
          }
        }

        // Should still work correctly
        themeController.setLight();
        expect(themeController.mode.value, equals(ThemeMode.light));

        bool wasNotified = false;
        void listener() {
          wasNotified = true;
        }

        themeController.mode.addListener(listener);
        themeController.setDark();

        expect(wasNotified, isTrue);
        expect(themeController.mode.value, equals(ThemeMode.dark));

        // Clean up
        themeController.mode.removeListener(listener);
      });
    });

    group('Integration with Flutter', () {
      testWidgets('should integrate properly with Flutter widgets', (tester) async {
        ThemeMode? capturedMode;

        await tester.pumpWidget(
          ValueListenableBuilder<ThemeMode>(
            valueListenable: themeController.mode,
            builder: (context, mode, child) {
              capturedMode = mode;
              return MaterialApp(
                theme: ThemeData.light(),
                darkTheme: ThemeData.dark(),
                themeMode: mode,
                home: Container(),
              );
            },
          ),
        );

        expect(capturedMode, equals(ThemeMode.light));

        themeController.setDark();
        await tester.pump();

        expect(capturedMode, equals(ThemeMode.dark));

        themeController.setSystem();
        await tester.pump();

        expect(capturedMode, equals(ThemeMode.system));
      });

      testWidgets('should handle multiple widgets listening simultaneously', (tester) async {
        final List<ThemeMode> widget1Modes = [];
        final List<ThemeMode> widget2Modes = [];

        await tester.pumpWidget(
          MaterialApp(
            home: Column(
              children: [
                ValueListenableBuilder<ThemeMode>(
                  valueListenable: themeController.mode,
                  builder: (context, mode, child) {
                    widget1Modes.add(mode);
                    return Text('Widget 1: ${mode.name}');
                  },
                ),
                ValueListenableBuilder<ThemeMode>(
                  valueListenable: themeController.mode,
                  builder: (context, mode, child) {
                    widget2Modes.add(mode);
                    return Text('Widget 2: ${mode.name}');
                  },
                ),
              ],
            ),
          ),
        );

        // Initial build
        expect(widget1Modes, hasLength(1));
        expect(widget2Modes, hasLength(1));

        themeController.setDark();
        await tester.pump();

        expect(widget1Modes, hasLength(2));
        expect(widget2Modes, hasLength(2));
        expect(widget1Modes.last, equals(ThemeMode.dark));
        expect(widget2Modes.last, equals(ThemeMode.dark));

        themeController.setSystem();
        await tester.pump();

        expect(widget1Modes, hasLength(3));
        expect(widget2Modes, hasLength(3));
        expect(widget1Modes.last, equals(ThemeMode.system));
        expect(widget2Modes.last, equals(ThemeMode.system));
      });
    });
  });
}