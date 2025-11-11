import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme_controller.dart';
import '../theme.dart';
import '../features/markdown/widgets/extended_markdown_viewer.dart';
import '../features/markdown/services/key_binding_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  MarkdownExtensionSettings _extensionSettings = const MarkdownExtensionSettings();
  late final KeyBindingService _keyBindingService;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _keyBindingService = KeyBindingService.instance;
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final settingsJson = prefs.getString('markdown_extensions');
      if (settingsJson != null) {
        // Parse JSON settings if available
        _extensionSettings = const MarkdownExtensionSettings();
      }
    } catch (e, st) {
      debugPrint('Failed to load markdown extension settings: $e');
      debugPrintStack(stackTrace: st);
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _saveSettings(MarkdownExtensionSettings settings) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      // Save settings JSON (simplified for now)
      await prefs.setString('markdown_extensions', 'settings');
    } catch (e, st) {
      debugPrint('Failed to save markdown extension settings: $e');
      debugPrintStack(stackTrace: st);
    }
  }

  void _updateExtensionSettings(MarkdownExtensionSettings settings) {
    setState(() {
      _extensionSettings = settings;
    });
    _saveSettings(settings);
  }

  @override
  Widget build(BuildContext context) {
    final controller = ThemeController.instance;
    final isLight = Theme.of(context).brightness == Brightness.light;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: isLight ? LightModeColors.appBar : DarkModeColors.appBar,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/'),
          tooltip: 'Back',
        ),
        title: const Text('Settings'),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 8),
                const Text(
                  'Appearance',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                ValueListenableBuilder<ThemeMode>(
                  valueListenable: controller.mode,
                  builder: (context, mode, _) {
                    // If system mode, determine actual brightness from context
                    final effectiveBrightness = mode == ThemeMode.system
                        ? MediaQuery.platformBrightnessOf(context)
                        : (mode == ThemeMode.dark ? Brightness.dark : Brightness.light);
                    final isDark = effectiveBrightness == Brightness.dark;
                    return SwitchListTile.adaptive(
                      value: isDark,
                      onChanged: (v) => v ? controller.setDark() : controller.setLight(),
                      // Show only the dynamic text (Dark/Light) and remove the static label
                      title: Text(isDark ? 'Dark' : 'Light'),
                      contentPadding: EdgeInsets.zero,
                    );
                  },
                ),
                const SizedBox(height: 24),
                const Text(
                  'Markdown Extensions',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                if (_isLoading)
                  const Center(child: CircularProgressIndicator())
                else
                  _buildExtensionSettings(),
                const SizedBox(height: 24),
                const Text(
                  'Key Bindings',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                _buildKeyBindingSettings(),
                const SizedBox(height: 24),
                Text(
                  'More settings coming soon',
                  style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildExtensionSettings() {
    return Column(
      children: [
        SwitchListTile(
          value: _extensionSettings.enableFootnotes,
          onChanged: (value) => _updateExtensionSettings(
            _extensionSettings.copyWith(enableFootnotes: value),
          ),
          title: const Text('Footnotes'),
          subtitle: const Text('Enable footnote syntax ([^1])'),
          contentPadding: EdgeInsets.zero,
        ),
        SwitchListTile(
          value: _extensionSettings.enableTaskLists,
          onChanged: (value) => _updateExtensionSettings(
            _extensionSettings.copyWith(enableTaskLists: value),
          ),
          title: const Text('Task Lists'),
          subtitle: const Text('Enable interactive checkboxes (- [ ])'),
          contentPadding: EdgeInsets.zero,
        ),
        SwitchListTile(
          value: _extensionSettings.enableDefinitionLists,
          onChanged: (value) => _updateExtensionSettings(
            _extensionSettings.copyWith(enableDefinitionLists: value),
          ),
          title: const Text('Definition Lists'),
          subtitle: const Text('Enable definition list syntax (Term: Definition)'),
          contentPadding: EdgeInsets.zero,
        ),
        SwitchListTile(
          value: _extensionSettings.enableTextExtensions,
          onChanged: (value) => _updateExtensionSettings(
            _extensionSettings.copyWith(enableTextExtensions: value),
          ),
          title: const Text('Text Extensions'),
          subtitle: const Text('Enable highlight (==text==), sub/superscript'),
          contentPadding: EdgeInsets.zero,
        ),
        SwitchListTile(
          value: _extensionSettings.enableStrikethrough,
          onChanged: (value) => _updateExtensionSettings(
            _extensionSettings.copyWith(enableStrikethrough: value),
          ),
          title: const Text('Strikethrough'),
          subtitle: const Text('Enable strikethrough text (~~text~~)'),
          contentPadding: EdgeInsets.zero,
        ),
        SwitchListTile(
          value: _extensionSettings.enableInteractiveElements,
          onChanged: (value) => _updateExtensionSettings(
            _extensionSettings.copyWith(enableInteractiveElements: value),
          ),
          title: const Text('Interactive Elements'),
          subtitle: const Text('Enable clickable checkboxes and footnotes'),
          contentPadding: EdgeInsets.zero,
        ),
      ],
    );
  }

  Widget _buildKeyBindingSettings() {
    return AnimatedBuilder(
      animation: _keyBindingService,
      builder: (context, _) {
        final settings = _keyBindingService.settings;

        return Column(
          children: [
            // Key binding mode selection
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Editor Mode',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Choose your preferred key binding style for the editor',
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                      ),
                    ),
                    const SizedBox(height: 12),
                    ...KeyBindingMode.values.map((mode) {
                      return RadioListTile<KeyBindingMode>(
                        value: mode,
                        groupValue: settings.mode,
                        onChanged: (value) {
                          if (value != null) {
                            _updateKeyBindingSettings(settings.copyWith(mode: value));
                          }
                        },
                        title: Text(_getModeName(mode)),
                        subtitle: Text(_getModeDescription(mode)),
                        contentPadding: EdgeInsets.zero,
                      );
                    }),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Additional settings for when key bindings are enabled
            if (settings.mode != KeyBindingMode.none) ...[
              SwitchListTile(
                value: settings.showModeIndicator,
                onChanged: (value) => _updateKeyBindingSettings(
                  settings.copyWith(showModeIndicator: value),
                ),
                title: const Text('Show Mode Indicator'),
                subtitle: const Text('Display current mode in the status bar'),
                contentPadding: EdgeInsets.zero,
              ),
              SwitchListTile(
                value: settings.showCommandFeedback,
                onChanged: (value) => _updateKeyBindingSettings(
                  settings.copyWith(showCommandFeedback: value),
                ),
                title: const Text('Show Command Feedback'),
                subtitle: const Text('Display command execution feedback'),
                contentPadding: EdgeInsets.zero,
              ),
              SwitchListTile(
                value: settings.enableAdvancedFeatures,
                onChanged: (value) => _updateKeyBindingSettings(
                  settings.copyWith(enableAdvancedFeatures: value),
                ),
                title: const Text('Advanced Features'),
                subtitle: const Text('Enable advanced key binding features'),
                contentPadding: EdgeInsets.zero,
              ),
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.help_outline,
                            size: 16,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'Getting Started',
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        settings.mode == KeyBindingMode.vim
                            ? 'Press F1 in the editor for help. Use Esc for Normal mode, i/a/o for Insert mode.'
                            : settings.mode == KeyBindingMode.emacs
                                ? 'Press F1 in the editor for help. C- = Ctrl, M- = Alt. Use C-g to cancel commands.'
                                : 'Select a key binding mode above to get started.',
                        style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        );
      },
    );
  }

  String _getModeName(KeyBindingMode mode) {
    switch (mode) {
      case KeyBindingMode.none:
        return 'Standard';
      case KeyBindingMode.vim:
        return 'Vim';
      case KeyBindingMode.emacs:
        return 'Emacs';
    }
  }

  String _getModeDescription(KeyBindingMode mode) {
    switch (mode) {
      case KeyBindingMode.none:
        return 'Standard Flutter text editing with keyboard shortcuts';
      case KeyBindingMode.vim:
        return 'Modal editing with Vim key bindings (h/j/k/l, i/a/o, d/c/y)';
      case KeyBindingMode.emacs:
        return 'Emacs-style key bindings (C-f/b, C-n/p, C-a/e, M-f/b)';
    }
  }

  void _updateKeyBindingSettings(KeyBindingSettings newSettings) {
    _keyBindingService.updateSettings(newSettings);
  }
}
