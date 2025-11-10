import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import '../models/outline_item.dart';

/// A collapsible sidebar widget that displays document outline/table of contents
class OutlineNavigator extends StatefulWidget {
  /// The outline items to display
  final List<OutlineItem> outline;

  /// Callback when an outline item is tapped
  final Function(OutlineItem) onItemTap;

  /// Whether the outline is currently visible
  final bool isVisible;

  /// Callback when the visibility toggle is tapped
  final VoidCallback onToggleVisibility;

  /// Whether to show in compact mode (for mobile)
  final bool isCompact;

  /// The current scroll position for highlighting active sections
  final int currentPosition;

  const OutlineNavigator({
    super.key,
    required this.outline,
    required this.onItemTap,
    required this.isVisible,
    required this.onToggleVisibility,
    this.isCompact = false,
    this.currentPosition = 0,
  });

  @override
  State<OutlineNavigator> createState() => _OutlineNavigatorState();
}

class _OutlineNavigatorState extends State<OutlineNavigator> with TickerProviderStateMixin {
  late AnimationController _slideController;
  late Animation<double> _slideAnimation;
  final ScrollController _scrollController = ScrollController();
  final Map<String, bool> _expandedStates = {};

  @override
  void initState() {
    super.initState();
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 250),
      vsync: this,
    );
    _slideAnimation = CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeInOut,
    );

    if (widget.isVisible) {
      _slideController.forward();
    }
  }

  @override
  void didUpdateWidget(OutlineNavigator oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isVisible != oldWidget.isVisible) {
      if (widget.isVisible) {
        _slideController.forward();
      } else {
        _slideController.reverse();
      }
    }

    // Auto-scroll to active item when it changes
    if (widget.currentPosition != oldWidget.currentPosition) {
      _scrollToActiveItem();
    }
  }

  @override
  void dispose() {
    _slideController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToActiveItem() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final activeItem = _findActiveItem(widget.outline);
      if (activeItem != null && _scrollController.hasClients) {
        // Simple scroll to top strategy - could be enhanced with more precise positioning
        _scrollController.animateTo(
          0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  OutlineItem? _findActiveItem(List<OutlineItem> items) {
    for (final item in items) {
      if (item.isActive) return item;
      final activeChild = _findActiveItem(item.children);
      if (activeChild != null) return activeChild;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final width = widget.isCompact ? 280.0 : 320.0;

    return AnimatedBuilder(
      animation: _slideAnimation,
      builder: (context, child) {
        return SizedBox(
          width: width * _slideAnimation.value,
          child: _slideAnimation.value > 0
              ? Container(
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    border: Border(
                      right: BorderSide(
                        color: theme.dividerColor.withValues(alpha: 0.2),
                        width: 1,
                      ),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeader(theme),
                      Expanded(child: _buildOutlineContent()),
                    ],
                  ),
                )
              : const SizedBox.shrink(),
        );
      },
    );
  }

  Widget _buildHeader(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: theme.dividerColor.withValues(alpha: 0.1),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.list_alt,
            size: 18,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Table of Contents',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurface,
              ),
            ),
          ),
          ShadButton.ghost(
            onPressed: widget.onToggleVisibility,
            icon: Icon(
              widget.isVisible ? Icons.chevron_left : Icons.chevron_right,
              size: 16,
            ),
            padding: const EdgeInsets.all(4),
            width: 28,
            height: 28,
          ),
        ],
      ),
    );
  }

  Widget _buildOutlineContent() {
    if (widget.outline.isEmpty) {
      return _buildEmptyState();
    }

    return Shortcuts(
      shortcuts: <LogicalKeySet, Intent>{
        LogicalKeySet(LogicalKeyboardKey.arrowUp): const _NavigateUpIntent(),
        LogicalKeySet(LogicalKeyboardKey.arrowDown): const _NavigateDownIntent(),
        LogicalKeySet(LogicalKeyboardKey.enter): const _SelectItemIntent(),
        LogicalKeySet(LogicalKeyboardKey.space): const _SelectItemIntent(),
      },
      child: Actions(
        actions: <Type, Action<Intent>>{
          _NavigateUpIntent: CallbackAction<_NavigateUpIntent>(
            onInvoke: (intent) => _navigateUp(),
          ),
          _NavigateDownIntent: CallbackAction<_NavigateDownIntent>(
            onInvoke: (intent) => _navigateDown(),
          ),
          _SelectItemIntent: CallbackAction<_SelectItemIntent>(
            onInvoke: (intent) => _selectCurrentItem(),
          ),
        },
        child: ListView(
          controller: _scrollController,
          padding: const EdgeInsets.all(8),
          children: widget.outline.map((item) => _buildOutlineItem(item, 0)).toList(),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.article_outlined,
              size: 48,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 16),
            Text(
              'No headers found',
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Add some headers to your document to see the outline here.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOutlineItem(OutlineItem item, int depth) {
    final theme = Theme.of(context);
    final hasChildren = item.children.isNotEmpty;
    final isExpanded = _expandedStates[item.id] ?? true;
    final indentSize = depth * 16.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          margin: EdgeInsets.only(left: indentSize),
          decoration: BoxDecoration(
            color: item.isActive
                ? theme.colorScheme.primary.withValues(alpha: 0.1)
                : null,
            borderRadius: BorderRadius.circular(6),
          ),
          child: InkWell(
            onTap: () => widget.onItemTap(item),
            borderRadius: BorderRadius.circular(6),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              child: Row(
                children: [
                  if (hasChildren)
                    GestureDetector(
                      onTap: () => _toggleExpanded(item.id),
                      child: Icon(
                        isExpanded ? Icons.expand_more : Icons.chevron_right,
                        size: 16,
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                    )
                  else
                    SizedBox(width: hasChildren ? 16 : 0),
                  Expanded(
                    child: Row(
                      children: [
                        // Level indicator
                        Container(
                          width: 3,
                          height: 12,
                          decoration: BoxDecoration(
                            color: _getLevelColor(theme, item.level),
                            borderRadius: BorderRadius.circular(1.5),
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Header text
                        Expanded(
                          child: Text(
                            item.title,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontSize: _getFontSize(item.level),
                              fontWeight: item.isActive
                                  ? FontWeight.w600
                                  : FontWeight.w500,
                              color: item.isActive
                                  ? theme.colorScheme.primary
                                  : theme.colorScheme.onSurface.withValues(alpha: 0.8),
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        // Children
        if (hasChildren && isExpanded)
          ...item.children.map((child) => _buildOutlineItem(child, depth + 1)),
      ],
    );
  }

  Color _getLevelColor(ThemeData theme, int level) {
    final colors = [
      theme.colorScheme.primary,
      theme.colorScheme.secondary,
      theme.colorScheme.tertiary,
      theme.colorScheme.primary.withValues(alpha: 0.7),
      theme.colorScheme.secondary.withValues(alpha: 0.7),
      theme.colorScheme.tertiary.withValues(alpha: 0.7),
    ];
    return colors[(level - 1) % colors.length];
  }

  double _getFontSize(int level) {
    switch (level) {
      case 1:
        return 14;
      case 2:
        return 13.5;
      case 3:
        return 13;
      case 4:
      case 5:
      case 6:
        return 12.5;
      default:
        return 13;
    }
  }

  void _toggleExpanded(String itemId) {
    setState(() {
      _expandedStates[itemId] = !(_expandedStates[itemId] ?? true);
    });
  }

  // Keyboard navigation methods
  void _navigateUp() {
    // Implementation for keyboard navigation up
    // This would require maintaining focus state
  }

  void _navigateDown() {
    // Implementation for keyboard navigation down
    // This would require maintaining focus state
  }

  void _selectCurrentItem() {
    // Implementation for selecting current focused item
    // This would require maintaining focus state
  }
}

// Keyboard navigation intents
class _NavigateUpIntent extends Intent {}
class _NavigateDownIntent extends Intent {}
class _SelectItemIntent extends Intent {}