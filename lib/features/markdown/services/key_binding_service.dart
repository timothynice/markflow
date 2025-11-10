import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../handlers/vim_key_handler.dart';
import '../handlers/emacs_key_handler.dart';

enum KeyBindingMode {
  none,
  vim,
  emacs,
}

enum VimMode {
  normal,
  insert,
  visual,
  visualLine,
  visualBlock,
}

class KeyBindingSettings {
  final KeyBindingMode mode;
  final bool showModeIndicator;
  final bool showCommandFeedback;
  final bool enableAdvancedFeatures;
  final Duration feedbackDuration;

  const KeyBindingSettings({
    this.mode = KeyBindingMode.none,
    this.showModeIndicator = true,
    this.showCommandFeedback = true,
    this.enableAdvancedFeatures = true,
    this.feedbackDuration = const Duration(milliseconds: 2000),
  });

  KeyBindingSettings copyWith({
    KeyBindingMode? mode,
    bool? showModeIndicator,
    bool? showCommandFeedback,
    bool? enableAdvancedFeatures,
    Duration? feedbackDuration,
  }) {
    return KeyBindingSettings(
      mode: mode ?? this.mode,
      showModeIndicator: showModeIndicator ?? this.showModeIndicator,
      showCommandFeedback: showCommandFeedback ?? this.showCommandFeedback,
      enableAdvancedFeatures: enableAdvancedFeatures ?? this.enableAdvancedFeatures,
      feedbackDuration: feedbackDuration ?? this.feedbackDuration,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'mode': mode.index,
      'showModeIndicator': showModeIndicator,
      'showCommandFeedback': showCommandFeedback,
      'enableAdvancedFeatures': enableAdvancedFeatures,
      'feedbackDurationMs': feedbackDuration.inMilliseconds,
    };
  }

  factory KeyBindingSettings.fromJson(Map<String, dynamic> json) {
    return KeyBindingSettings(
      mode: KeyBindingMode.values[json['mode'] ?? 0],
      showModeIndicator: json['showModeIndicator'] ?? true,
      showCommandFeedback: json['showCommandFeedback'] ?? true,
      enableAdvancedFeatures: json['enableAdvancedFeatures'] ?? true,
      feedbackDuration: Duration(milliseconds: json['feedbackDurationMs'] ?? 2000),
    );
  }
}

class KeyBindingCommand {
  final String name;
  final String description;
  final String category;
  final List<String> keys;

  const KeyBindingCommand({
    required this.name,
    required this.description,
    required this.category,
    required this.keys,
  });
}

class CommandFeedback {
  final String message;
  final CommandFeedbackType type;
  final DateTime timestamp;

  const CommandFeedback({
    required this.message,
    required this.type,
    required this.timestamp,
  });
}

enum CommandFeedbackType {
  info,
  success,
  error,
  warning,
}

class KeyBindingService extends ChangeNotifier {
  static KeyBindingService? _instance;
  static KeyBindingService get instance => _instance ??= KeyBindingService._();

  KeyBindingService._();

  KeyBindingSettings _settings = const KeyBindingSettings();
  VimMode _vimMode = VimMode.normal;
  CommandFeedback? _currentFeedback;

  late final VimKeyHandler _vimHandler;
  late final EmacsKeyHandler _emacsHandler;

  bool _initialized = false;

  // Getters
  KeyBindingSettings get settings => _settings;
  VimMode get vimMode => _vimMode;
  CommandFeedback? get currentFeedback => _currentFeedback;
  bool get isVimMode => _settings.mode == KeyBindingMode.vim;
  bool get isEmacsMode => _settings.mode == KeyBindingMode.emacs;
  bool get isEnabled => _settings.mode != KeyBindingMode.none;
  bool get isVimInsertMode => isVimMode && _vimMode == VimMode.insert;
  bool get isVimNormalMode => isVimMode && _vimMode == VimMode.normal;
  bool get isVimVisualMode => isVimMode && (_vimMode == VimMode.visual || _vimMode == VimMode.visualLine || _vimMode == VimMode.visualBlock);

  Future<void> initialize() async {
    if (_initialized) return;

    _vimHandler = VimKeyHandler(this);
    _emacsHandler = EmacsKeyHandler(this);

    await _loadSettings();
    _initialized = true;
    notifyListeners();
  }

  Future<void> _loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final settingsJson = prefs.getString('key_binding_settings');

      if (settingsJson != null) {
        // For now, use default settings - proper JSON serialization can be added later
        // final Map<String, dynamic> json = jsonDecode(settingsJson);
        // _settings = KeyBindingSettings.fromJson(json);
        _settings = const KeyBindingSettings();
      }
    } catch (e) {
      // Use default settings on error
      debugPrint('Failed to load key binding settings: $e');
    }
  }

  Future<void> updateSettings(KeyBindingSettings newSettings) async {
    _settings = newSettings;

    // Reset vim mode when changing binding modes
    if (_settings.mode != KeyBindingMode.vim) {
      _vimMode = VimMode.normal;
    }

    await _saveSettings();
    notifyListeners();
  }

  Future<void> _saveSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      // For now, save a simple indicator - proper JSON serialization can be added later
      await prefs.setString('key_binding_settings', _settings.mode.index.toString());
    } catch (e) {
      debugPrint('Failed to save key binding settings: $e');
    }
  }

  void setVimMode(VimMode mode) {
    if (!isVimMode) return;

    _vimMode = mode;
    notifyListeners();

    if (_settings.showCommandFeedback) {
      final modeText = mode.toString().split('.').last.toUpperCase();
      showFeedback('-- $modeText --', CommandFeedbackType.info);
    }
  }

  void showFeedback(String message, CommandFeedbackType type) {
    if (!_settings.showCommandFeedback) return;

    _currentFeedback = CommandFeedback(
      message: message,
      type: type,
      timestamp: DateTime.now(),
    );
    notifyListeners();

    // Auto-hide feedback after duration
    Future.delayed(_settings.feedbackDuration, () {
      if (_currentFeedback?.timestamp == _currentFeedback?.timestamp) {
        _currentFeedback = null;
        notifyListeners();
      }
    });
  }

  void clearFeedback() {
    _currentFeedback = null;
    notifyListeners();
  }

  /// Handle raw key events and route to appropriate handler
  bool handleKeyEvent(KeyEvent event, TextEditingController controller) {
    if (!isEnabled || !_initialized) return false;

    try {
      switch (_settings.mode) {
        case KeyBindingMode.vim:
          return _vimHandler.handleKeyEvent(event, controller);
        case KeyBindingMode.emacs:
          return _emacsHandler.handleKeyEvent(event, controller);
        case KeyBindingMode.none:
          return false;
      }
    } catch (e) {
      debugPrint('Error handling key event: $e');
      showFeedback('Error executing command', CommandFeedbackType.error);
      return false;
    }
  }

  /// Get available commands for current mode
  List<KeyBindingCommand> getAvailableCommands() {
    if (!isEnabled) return [];

    switch (_settings.mode) {
      case KeyBindingMode.vim:
        return _vimHandler.getAvailableCommands();
      case KeyBindingMode.emacs:
        return _emacsHandler.getAvailableCommands();
      case KeyBindingMode.none:
        return [];
    }
  }

  /// Get mode-specific help text
  String getHelpText() {
    if (!isEnabled) return 'Key bindings are disabled';

    switch (_settings.mode) {
      case KeyBindingMode.vim:
        return _vimHandler.getHelpText();
      case KeyBindingMode.emacs:
        return _emacsHandler.getHelpText();
      case KeyBindingMode.none:
        return 'Key bindings are disabled';
    }
  }

  /// Force exit to normal mode (useful for Escape handling)
  void exitToNormalMode() {
    if (isVimMode) {
      setVimMode(VimMode.normal);
    }
  }

  /// Check if we should intercept this key event
  bool shouldInterceptKey(KeyEvent event) {
    if (!isEnabled) return false;

    // Always intercept in Vim normal/visual modes
    if (isVimMode && !isVimInsertMode) {
      return true;
    }

    // In Emacs mode, intercept control combinations
    if (isEmacsMode && (event.logicalKey.keyLabel.startsWith('Control') ||
                       event.logicalKey.keyLabel.startsWith('Alt'))) {
      return true;
    }

    return false;
  }

  @override
  void dispose() {
    _vimHandler.dispose();
    _emacsHandler.dispose();
    super.dispose();
  }
}