import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/key_binding_service.dart';

class KeyBindingHelpOverlay extends StatefulWidget {
  final KeyBindingService keyBindingService;
  final VoidCallback onClose;

  const KeyBindingHelpOverlay({
    super.key,
    required this.keyBindingService,
    required this.onClose,
  });

  @override
  State<KeyBindingHelpOverlay> createState() => _KeyBindingHelpOverlayState();
}

class _KeyBindingHelpOverlayState extends State<KeyBindingHelpOverlay> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;

  String _searchQuery = '';
  String _selectedCategory = 'All';
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.elasticOut,
    ));

    _opacityAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));

    _animationController.forward();

    // Auto-focus search
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _searchFocusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return KeyboardListener(
      focusNode: FocusNode(),
      onKeyEvent: _handleKeyEvent,
      child: Material(
        color: Colors.black.withOpacity(0.5),
        child: GestureDetector(
          onTap: _close,
          child: Center(
            child: GestureDetector(
              onTap: () {}, // Prevent closing when tapping on the content
              child: AnimatedBuilder(
                animation: _animationController,
                builder: (context, child) {
                  return Transform.scale(
                    scale: _scaleAnimation.value,
                    child: Opacity(
                      opacity: _opacityAnimation.value,
                      child: _buildHelpContent(context),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHelpContent(BuildContext context) {
    final theme = Theme.of(context);
    final size = MediaQuery.of(context).size;
    final isMobile = size.width < 600;

    return Container(
      width: isMobile ? size.width * 0.9 : 800,
      height: isMobile ? size.height * 0.8 : 600,
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildHeader(context),
          _buildSearchAndFilter(context),
          Expanded(child: _buildCommandList(context)),
          _buildFooter(context),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceVariant.withOpacity(0.5),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        border: Border(
          bottom: BorderSide(
            color: theme.dividerColor.withOpacity(0.2),
          ),
        ),
      ),
      child: Row(
        children: [
          Icon(
            widget.keyBindingService.isVimMode ? Icons.keyboard_command_key : Icons.keyboard,
            color: theme.colorScheme.primary,
            size: 28,
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${widget.keyBindingService.settings.mode.name.toUpperCase()} Key Bindings',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary,
                ),
              ),
              Text(
                widget.keyBindingService.getHelpText().split('\n').first,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          const Spacer(),
          IconButton(
            onPressed: _close,
            icon: const Icon(Icons.close),
            tooltip: 'Close (Esc)',
          ),
        ],
      ),
    );
  }

  Widget _buildSearchAndFilter(BuildContext context) {
    final theme = Theme.of(context);
    final commands = widget.keyBindingService.getAvailableCommands();
    final categories = ['All'] + commands.map((c) => c.category).toSet().toList()..sort();

    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _searchController,
              focusNode: _searchFocusNode,
              onChanged: (value) {
                setState(() {
                  _searchQuery = value.toLowerCase();
                });
              },
              decoration: InputDecoration(
                hintText: 'Search commands...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {
                            _searchQuery = '';
                          });
                        },
                      )
                    : null,
              ),
            ),
          ),
          const SizedBox(width: 12),
          DropdownButton<String>(
            value: _selectedCategory,
            onChanged: (value) {
              setState(() {
                _selectedCategory = value ?? 'All';
              });
            },
            items: categories.map((category) {
              return DropdownMenuItem(
                value: category,
                child: Text(category),
              );
            }).toList(),
            decoration: InputDecoration(
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCommandList(BuildContext context) {
    final theme = Theme.of(context);
    final commands = _getFilteredCommands();

    if (commands.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off,
              size: 64,
              color: theme.colorScheme.onSurface.withOpacity(0.3),
            ),
            const SizedBox(height: 16),
            Text(
              'No commands found',
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Try adjusting your search or filter',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.5),
              ),
            ),
          ],
        ),
      );
    }

    // Group commands by category
    final groupedCommands = <String, List<KeyBindingCommand>>{};
    for (final command in commands) {
      groupedCommands.putIfAbsent(command.category, () => []).add(command);
    }

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      children: [
        ...groupedCommands.entries.map((entry) => _buildCategorySection(context, entry.key, entry.value)),
      ],
    );
  }

  Widget _buildCategorySection(BuildContext context, String category, List<KeyBindingCommand> commands) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(0, 16, 0, 8),
          child: Text(
            category,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.primary,
            ),
          ),
        ),
        ...commands.map((command) => _buildCommandItem(context, command)),
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _buildCommandItem(BuildContext context, KeyBindingCommand command) {
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceVariant.withOpacity(0.3),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: theme.dividerColor.withOpacity(0.2),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  command.name,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  command.description,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            flex: 1,
            child: Wrap(
              alignment: WrapAlignment.end,
              spacing: 4,
              runSpacing: 4,
              children: command.keys.map((key) => _buildKeyChip(context, key)).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKeyChip(BuildContext context, String key) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: theme.colorScheme.secondaryContainer,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: theme.colorScheme.outline.withOpacity(0.3),
        ),
      ),
      child: Text(
        key,
        style: TextStyle(
          fontFamily: 'monospace',
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: theme.colorScheme.onSecondaryContainer,
        ),
      ),
    );
  }

  Widget _buildFooter(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceVariant.withOpacity(0.3),
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
        border: Border(
          top: BorderSide(
            color: theme.dividerColor.withOpacity(0.2),
          ),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.info_outline,
            size: 16,
            color: theme.colorScheme.onSurface.withOpacity(0.6),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              widget.keyBindingService.isVimMode
                  ? 'Vim mode: Press Esc to enter Normal mode, i/a/o for Insert mode'
                  : 'Emacs mode: C- = Ctrl, M- = Alt. Use C-g to cancel commands',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildKeyChip(context, 'Esc'),
              const SizedBox(width: 4),
              Text(
                'Close',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.6),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  List<KeyBindingCommand> _getFilteredCommands() {
    final commands = widget.keyBindingService.getAvailableCommands();

    return commands.where((command) {
      final matchesSearch = _searchQuery.isEmpty ||
          command.name.toLowerCase().contains(_searchQuery) ||
          command.description.toLowerCase().contains(_searchQuery) ||
          command.keys.any((key) => key.toLowerCase().contains(_searchQuery));

      final matchesCategory = _selectedCategory == 'All' || command.category == _selectedCategory;

      return matchesSearch && matchesCategory;
    }).toList();
  }

  void _handleKeyEvent(KeyEvent event) {
    if (event is KeyDownEvent) {
      if (event.logicalKey == LogicalKeyboardKey.escape) {
        _close();
      }
    }
  }

  void _close() {
    _animationController.reverse().then((_) {
      widget.onClose();
    });
  }
}

class KeyBindingHelpButton extends StatelessWidget {
  final KeyBindingService keyBindingService;

  const KeyBindingHelpButton({
    super.key,
    required this.keyBindingService,
  });

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: keyBindingService,
      builder: (context, _, __) {
        if (!keyBindingService.isEnabled) {
          return const SizedBox.shrink();
        }

        return IconButton(
          onPressed: () => _showHelp(context),
          icon: const Icon(Icons.help_outline),
          tooltip: 'Key Binding Help (F1)',
        );
      },
    );
  }

  void _showHelp(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => KeyBindingHelpOverlay(
        keyBindingService: keyBindingService,
        onClose: () => Navigator.of(context).pop(),
      ),
    );
  }
}

class QuickReferenceCard extends StatelessWidget {
  final KeyBindingService keyBindingService;

  const QuickReferenceCard({
    super.key,
    required this.keyBindingService,
  });

  @override
  Widget build(BuildContext context) {
    if (!keyBindingService.isEnabled) {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);
    final quickCommands = _getQuickCommands();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Icon(
                  keyBindingService.isVimMode ? Icons.keyboard_command_key : Icons.keyboard,
                  size: 16,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Quick Reference',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  ),
                ),
                const Spacer(),
                InkWell(
                  onTap: () => _showFullHelp(context),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.open_in_full,
                        size: 12,
                        color: theme.colorScheme.onSurface.withOpacity(0.6),
                      ),
                      const SizedBox(width: 2),
                      Text(
                        'F1',
                        style: TextStyle(
                          fontSize: 10,
                          color: theme.colorScheme.onSurface.withOpacity(0.6),
                          fontFamily: 'monospace',
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ...quickCommands.take(5).map((command) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      command.name,
                      style: theme.textTheme.bodySmall,
                    ),
                  ),
                  Text(
                    command.keys.first,
                    style: TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 10,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ],
              ),
            )),
          ],
        ),
      ),
    );
  }

  List<KeyBindingCommand> _getQuickCommands() {
    final allCommands = keyBindingService.getAvailableCommands();

    if (keyBindingService.isVimMode) {
      // Most common Vim commands
      final priorityCommands = ['Insert', 'Move left', 'Move down', 'Move up', 'Move right'];
      return priorityCommands
          .map((name) => allCommands.firstWhere((cmd) => cmd.name == name, orElse: () => allCommands.first))
          .toList();
    } else {
      // Most common Emacs commands
      final priorityCommands = ['Forward char', 'Backward char', 'Next line', 'Previous line', 'Beginning of line'];
      return priorityCommands
          .map((name) => allCommands.firstWhere((cmd) => cmd.name == name, orElse: () => allCommands.first))
          .toList();
    }
  }

  void _showFullHelp(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => KeyBindingHelpOverlay(
        keyBindingService: keyBindingService,
        onClose: () => Navigator.of(context).pop(),
      ),
    );
  }
}