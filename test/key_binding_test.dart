import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/services.dart';
import '../lib/features/markdown/services/key_binding_service.dart';

void main() {
  group('KeyBindingService Tests', () {
    late KeyBindingService service;

    setUp(() {
      service = KeyBindingService.instance;
    });

    test('should initialize with default settings', () {
      expect(service.settings.mode, KeyBindingMode.none);
      expect(service.settings.showModeIndicator, true);
      expect(service.settings.showCommandFeedback, true);
    });

    test('should update settings correctly', () async {
      final newSettings = service.settings.copyWith(
        mode: KeyBindingMode.vim,
        showModeIndicator: false,
      );

      await service.updateSettings(newSettings);

      expect(service.settings.mode, KeyBindingMode.vim);
      expect(service.settings.showModeIndicator, false);
      expect(service.isVimMode, true);
      expect(service.isEmacsMode, false);
    });

    test('should handle vim mode changes', () {
      service.updateSettings(service.settings.copyWith(mode: KeyBindingMode.vim));

      expect(service.vimMode, VimMode.normal);

      service.setVimMode(VimMode.insert);
      expect(service.vimMode, VimMode.insert);
      expect(service.isVimInsertMode, true);
      expect(service.isVimNormalMode, false);
    });

    test('should show feedback correctly', () {
      service.showFeedback('Test message', CommandFeedbackType.info);

      expect(service.currentFeedback, isNotNull);
      expect(service.currentFeedback!.message, 'Test message');
      expect(service.currentFeedback!.type, CommandFeedbackType.info);
    });

    test('should get available commands based on mode', () {
      // Default mode (none) should return empty commands
      expect(service.getAvailableCommands(), isEmpty);

      // Vim mode should return vim commands
      service.updateSettings(service.settings.copyWith(mode: KeyBindingMode.vim));
      final vimCommands = service.getAvailableCommands();
      expect(vimCommands, isNotEmpty);
      expect(vimCommands.any((cmd) => cmd.name.contains('Move left')), true);

      // Emacs mode should return emacs commands
      service.updateSettings(service.settings.copyWith(mode: KeyBindingMode.emacs));
      final emacsCommands = service.getAvailableCommands();
      expect(emacsCommands, isNotEmpty);
      expect(emacsCommands.any((cmd) => cmd.name.contains('Forward char')), true);
    });

    test('should generate appropriate help text', () {
      // Default mode
      expect(service.getHelpText(), contains('disabled'));

      // Vim mode
      service.updateSettings(service.settings.copyWith(mode: KeyBindingMode.vim));
      expect(service.getHelpText(), contains('Vim'));
      expect(service.getHelpText(), contains('h/j/k/l'));

      // Emacs mode
      service.updateSettings(service.settings.copyWith(mode: KeyBindingMode.emacs));
      expect(service.getHelpText(), contains('Emacs'));
      expect(service.getHelpText(), contains('C-'));
    });
  });

  group('KeyBindingSettings Tests', () {
    test('should create settings with correct defaults', () {
      const settings = KeyBindingSettings();

      expect(settings.mode, KeyBindingMode.none);
      expect(settings.showModeIndicator, true);
      expect(settings.showCommandFeedback, true);
      expect(settings.enableAdvancedFeatures, true);
      expect(settings.feedbackDuration, const Duration(milliseconds: 2000));
    });

    test('should copyWith correctly', () {
      const originalSettings = KeyBindingSettings();
      final newSettings = originalSettings.copyWith(
        mode: KeyBindingMode.vim,
        showModeIndicator: false,
      );

      expect(newSettings.mode, KeyBindingMode.vim);
      expect(newSettings.showModeIndicator, false);
      expect(newSettings.showCommandFeedback, true); // Should remain unchanged
    });

    test('should serialize to and from JSON', () {
      const originalSettings = KeyBindingSettings(
        mode: KeyBindingMode.emacs,
        showModeIndicator: false,
        showCommandFeedback: true,
        enableAdvancedFeatures: false,
        feedbackDuration: Duration(milliseconds: 3000),
      );

      final json = originalSettings.toJson();
      final restoredSettings = KeyBindingSettings.fromJson(json);

      expect(restoredSettings.mode, originalSettings.mode);
      expect(restoredSettings.showModeIndicator, originalSettings.showModeIndicator);
      expect(restoredSettings.showCommandFeedback, originalSettings.showCommandFeedback);
      expect(restoredSettings.enableAdvancedFeatures, originalSettings.enableAdvancedFeatures);
      expect(restoredSettings.feedbackDuration, originalSettings.feedbackDuration);
    });
  });

  group('Command Tests', () {
    test('should create KeyBindingCommand correctly', () {
      const command = KeyBindingCommand(
        name: 'Test Command',
        description: 'A test command',
        category: 'Test',
        keys: ['t', 'test'],
      );

      expect(command.name, 'Test Command');
      expect(command.description, 'A test command');
      expect(command.category, 'Test');
      expect(command.keys, ['t', 'test']);
    });

    test('should create CommandFeedback correctly', () {
      final timestamp = DateTime.now();
      final feedback = CommandFeedback(
        message: 'Test feedback',
        type: CommandFeedbackType.success,
        timestamp: timestamp,
      );

      expect(feedback.message, 'Test feedback');
      expect(feedback.type, CommandFeedbackType.success);
      expect(feedback.timestamp, timestamp);
    });
  });
}