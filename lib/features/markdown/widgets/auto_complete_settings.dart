import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import '../services/auto_complete_service.dart';
import '../models/completion_suggestion.dart';

/// Widget for managing auto-completion settings
class AutoCompleteSettings extends StatefulWidget {
  final AutoCompleteService autoCompleteService;
  final VoidCallback? onSettingsChanged;

  const AutoCompleteSettings({
    super.key,
    required this.autoCompleteService,
    this.onSettingsChanged,
  });

  @override
  State<AutoCompleteSettings> createState() => _AutoCompleteSettingsState();
}

class _AutoCompleteSettingsState extends State<AutoCompleteSettings> {
  late bool _isEnabled;
  late bool _autoTriggerEnabled;
  late int _suggestionDelay;
  late int _maxSuggestions;
  late Set<String> _triggerCharacters;
  late List<CompletionSuggestion> _customShortcuts;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  void _loadSettings() {
    final service = widget.autoCompleteService;
    setState(() {
      _isEnabled = service.isEnabled;
      _autoTriggerEnabled = service.autoTriggerEnabled;
      _suggestionDelay = service.suggestionDelay;
      _maxSuggestions = service.maxSuggestions;
      _triggerCharacters = Set.from(service.triggerCharacters);
      _customShortcuts = List.from(service.customShortcuts);
    });
  }

  Future<void> _saveSettings() async {
    await widget.autoCompleteService.updateSettings(
      enabled: _isEnabled,
      autoTrigger: _autoTriggerEnabled,
      delay: _suggestionDelay,
      maxSuggestions: _maxSuggestions,
      triggerCharacters: _triggerCharacters,
    );
    widget.onSettingsChanged?.call();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Auto-Completion Settings'),
        backgroundColor: theme.colorScheme.surface,
        elevation: 0,
        actions: [
          TextButton(
            onPressed: _saveSettings,
            child: const Text('Save'),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildGeneralSettings(),
          const SizedBox(height: 24),
          _buildTriggerSettings(),
          const SizedBox(height: 24),
          _buildPerformanceSettings(),
          const SizedBox(height: 24),
          _buildCustomShortcuts(),
          const SizedBox(height: 24),
          _buildUsageStatistics(),
        ],
      ),
    );
  }

  Widget _buildGeneralSettings() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'General Settings',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              title: const Text('Enable Auto-Completion'),
              subtitle: const Text('Turn auto-completion on or off'),
              value: _isEnabled,
              onChanged: (value) {
                setState(() {
                  _isEnabled = value;
                });
              },
            ),
            SwitchListTile(
              title: const Text('Auto-Trigger'),
              subtitle: const Text('Automatically show suggestions on trigger characters'),
              value: _autoTriggerEnabled,
              onChanged: _isEnabled
                  ? (value) {
                      setState(() {
                        _autoTriggerEnabled = value;
                      });
                    }
                  : null,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTriggerSettings() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Trigger Characters',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Characters that trigger auto-completion suggestions',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: ['#', '*', '-', '[', '!', '`', '>', '|', '+', '_'].map((char) {
                final isSelected = _triggerCharacters.contains(char);
                return FilterChip(
                  label: Text(char),
                  selected: isSelected,
                  onSelected: _isEnabled
                      ? (selected) {
                          setState(() {
                            if (selected) {
                              _triggerCharacters.add(char);
                            } else {
                              _triggerCharacters.remove(char);
                            }
                          });
                        }
                      : null,
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPerformanceSettings() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Performance Settings',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              title: const Text('Suggestion Delay'),
              subtitle: Text('${_suggestionDelay}ms - Delay before showing suggestions'),
              trailing: SizedBox(
                width: 200,
                child: Slider(
                  value: _suggestionDelay.toDouble(),
                  min: 100,
                  max: 1000,
                  divisions: 18,
                  label: '${_suggestionDelay}ms',
                  onChanged: _isEnabled
                      ? (value) {
                          setState(() {
                            _suggestionDelay = value.round();
                          });
                        }
                      : null,
                ),
              ),
            ),
            ListTile(
              title: const Text('Max Suggestions'),
              subtitle: Text('$_maxSuggestions - Maximum number of suggestions to show'),
              trailing: SizedBox(
                width: 200,
                child: Slider(
                  value: _maxSuggestions.toDouble(),
                  min: 5,
                  max: 20,
                  divisions: 15,
                  label: _maxSuggestions.toString(),
                  onChanged: _isEnabled
                      ? (value) {
                          setState(() {
                            _maxSuggestions = value.round();
                          });
                        }
                      : null,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCustomShortcuts() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Custom Shortcuts',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: _isEnabled ? _showAddShortcutDialog : null,
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text('Add'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Create custom shortcuts for frequently used markdown patterns',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
            const SizedBox(height: 16),
            if (_customShortcuts.isEmpty)
              Container(
                padding: const EdgeInsets.symmetric(vertical: 32),
                alignment: Alignment.center,
                child: Column(
                  children: [
                    Icon(
                      Icons.shortcut,
                      size: 48,
                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'No custom shortcuts yet',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ),
              )
            else
              ...(_customShortcuts.map((shortcut) => _buildShortcutItem(shortcut))),
          ],
        ),
      ),
    );
  }

  Widget _buildShortcutItem(CompletionSuggestion shortcut) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        title: Text(shortcut.shortcutKey ?? 'Unknown'),
        subtitle: Text(
          shortcut.displayText,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit, size: 18),
              onPressed: () => _showEditShortcutDialog(shortcut),
              tooltip: 'Edit shortcut',
            ),
            IconButton(
              icon: const Icon(Icons.delete, size: 18),
              onPressed: () => _deleteShortcut(shortcut),
              tooltip: 'Delete shortcut',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUsageStatistics() {
    final stats = widget.autoCompleteService.usageStats;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Usage Statistics',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextButton(
                  onPressed: _resetUsageStats,
                  child: const Text('Reset'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Most frequently used completions',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
            const SizedBox(height: 16),
            if (stats.isEmpty)
              Container(
                padding: const EdgeInsets.symmetric(vertical: 32),
                alignment: Alignment.center,
                child: Text(
                  'No usage statistics yet',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
              )
            else
              ...(stats.entries.take(10).map((entry) => ListTile(
                title: Text(entry.key),
                trailing: Chip(
                  label: Text('${entry.value}'),
                  backgroundColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                ),
              ))),
          ],
        ),
      ),
    );
  }

  void _showAddShortcutDialog() {
    _showShortcutDialog(null);
  }

  void _showEditShortcutDialog(CompletionSuggestion shortcut) {
    _showShortcutDialog(shortcut);
  }

  void _showShortcutDialog(CompletionSuggestion? existing) {
    final keyController = TextEditingController(text: existing?.shortcutKey ?? '');
    final displayController = TextEditingController(text: existing?.displayText ?? '');
    final insertController = TextEditingController(text: existing?.insertText ?? '');
    final descriptionController = TextEditingController(text: existing?.description ?? '');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(existing == null ? 'Add Shortcut' : 'Edit Shortcut'),
        content: SizedBox(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: keyController,
                decoration: const InputDecoration(
                  labelText: 'Shortcut Key',
                  hintText: 'e.g., "h1", "table", "link"',
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: displayController,
                decoration: const InputDecoration(
                  labelText: 'Display Text',
                  hintText: 'Text shown in suggestions',
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: insertController,
                decoration: const InputDecoration(
                  labelText: 'Insert Text',
                  hintText: 'Text to insert when selected',
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description (optional)',
                  hintText: 'Brief description',
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final shortcut = CompletionSuggestion(
                shortcutKey: keyController.text.trim(),
                displayText: displayController.text.trim(),
                insertText: insertController.text.trim(),
                description: descriptionController.text.trim().isEmpty
                    ? null
                    : descriptionController.text.trim(),
                type: CompletionType.customShortcut,
                icon: Icons.shortcut,
                priority: 5,
              );

              if (existing != null) {
                _updateShortcut(existing, shortcut);
              } else {
                _addShortcut(shortcut);
              }

              Navigator.of(context).pop();
            },
            child: Text(existing == null ? 'Add' : 'Update'),
          ),
        ],
      ),
    );
  }

  void _addShortcut(CompletionSuggestion shortcut) {
    if (shortcut.shortcutKey?.isNotEmpty == true &&
        shortcut.displayText.isNotEmpty &&
        shortcut.insertText.isNotEmpty) {
      setState(() {
        _customShortcuts.add(shortcut);
      });
      widget.autoCompleteService.addCustomShortcut(shortcut);
    }
  }

  void _updateShortcut(CompletionSuggestion existing, CompletionSuggestion updated) {
    setState(() {
      final index = _customShortcuts.indexOf(existing);
      if (index != -1) {
        _customShortcuts[index] = updated;
      }
    });
    widget.autoCompleteService.removeCustomShortcut(existing);
    widget.autoCompleteService.addCustomShortcut(updated);
  }

  void _deleteShortcut(CompletionSuggestion shortcut) {
    setState(() {
      _customShortcuts.remove(shortcut);
    });
    widget.autoCompleteService.removeCustomShortcut(shortcut);
  }

  void _resetUsageStats() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset Usage Statistics'),
        content: const Text('Are you sure you want to reset all usage statistics? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              widget.autoCompleteService.resetUsageStats();
              Navigator.of(context).pop();
              setState(() {}); // Refresh the UI
            },
            style: ElevatedButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Reset'),
          ),
        ],
      ),
    );
  }
}