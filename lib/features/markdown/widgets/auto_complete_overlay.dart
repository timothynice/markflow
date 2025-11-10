import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/completion_suggestion.dart';

/// Overlay widget that displays auto-completion suggestions
class AutoCompleteOverlay extends StatefulWidget {
  final CompletionResult completionResult;
  final VoidCallback? onHide;
  final Function(CompletionSuggestion)? onSuggestionSelected;
  final Function(int)? onSuggestionHovered;
  final Offset position;
  final double maxWidth;
  final double maxHeight;
  final bool showDescriptions;
  final bool showIcons;

  const AutoCompleteOverlay({
    super.key,
    required this.completionResult,
    required this.position,
    this.onHide,
    this.onSuggestionSelected,
    this.onSuggestionHovered,
    this.maxWidth = 400,
    this.maxHeight = 300,
    this.showDescriptions = true,
    this.showIcons = true,
  });

  @override
  State<AutoCompleteOverlay> createState() => _AutoCompleteOverlayState();
}

class _AutoCompleteOverlayState extends State<AutoCompleteOverlay>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  ScrollController? _scrollController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));

    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));

    _scrollController = ScrollController();
    _animationController.forward();

    // Auto-scroll to selected item
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToSelectedItem();
    });
  }

  @override
  void didUpdateWidget(AutoCompleteOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Scroll to selected item when selection changes
    if (oldWidget.completionResult.selectedIndex != widget.completionResult.selectedIndex) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToSelectedItem();
      });
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    _scrollController?.dispose();
    super.dispose();
  }

  void _scrollToSelectedItem() {
    if (_scrollController == null || !_scrollController!.hasClients) return;

    final selectedIndex = widget.completionResult.selectedIndex;
    if (selectedIndex < 0 || selectedIndex >= widget.completionResult.suggestions.length) return;

    final itemHeight = widget.showDescriptions ? 72.0 : 48.0;
    final targetOffset = selectedIndex * itemHeight;
    final viewportHeight = _scrollController!.position.viewportDimension;

    // Only scroll if item is not visible
    final currentOffset = _scrollController!.offset;
    if (targetOffset < currentOffset || targetOffset > currentOffset + viewportHeight - itemHeight) {
      _scrollController!.animateTo(
        math.max(0, targetOffset - viewportHeight / 2 + itemHeight / 2),
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.completionResult.isActive || widget.completionResult.suggestions.isEmpty) {
      return const SizedBox.shrink();
    }

    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Opacity(
          opacity: _fadeAnimation.value,
          child: Transform.scale(
            scale: _scaleAnimation.value,
            alignment: Alignment.topLeft,
            child: child,
          ),
        );
      },
      child: _buildOverlayContent(context),
    );
  }

  Widget _buildOverlayContent(BuildContext context) {
    final theme = Theme.of(context);
    final suggestions = widget.completionResult.suggestions;

    return Positioned(
      left: widget.position.dx,
      top: widget.position.dy,
      child: Material(
        elevation: 8,
        borderRadius: BorderRadius.circular(8),
        shadowColor: Colors.black.withOpacity(0.2),
        child: Container(
          constraints: BoxConstraints(
            maxWidth: widget.maxWidth,
            maxHeight: widget.maxHeight,
            minWidth: 200,
          ),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: theme.colorScheme.outline.withOpacity(0.2),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              _buildHeader(context),
              // Suggestions list
              Flexible(
                child: _buildSuggestionsList(context, suggestions),
              ),
              // Footer
              if (suggestions.length > 5) _buildFooter(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final theme = Theme.of(context);
    final filterText = widget.completionResult.filterText;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.5),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(8),
          topRight: Radius.circular(8),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.auto_awesome,
            size: 16,
            color: theme.colorScheme.primary,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              filterText.isEmpty
                ? 'Suggestions'
                : 'Suggestions for "$filterText"',
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurface.withOpacity(0.8),
              ),
            ),
          ),
          Text(
            '${widget.completionResult.suggestions.length}',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.6),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuggestionsList(BuildContext context, List<CompletionSuggestion> suggestions) {
    return ListView.builder(
      controller: _scrollController,
      shrinkWrap: true,
      padding: const EdgeInsets.symmetric(vertical: 4),
      itemCount: suggestions.length,
      itemBuilder: (context, index) {
        final suggestion = suggestions[index];
        final isSelected = index == widget.completionResult.selectedIndex;

        return _buildSuggestionItem(
          context,
          suggestion,
          index,
          isSelected,
        );
      },
    );
  }

  Widget _buildSuggestionItem(
    BuildContext context,
    CompletionSuggestion suggestion,
    int index,
    bool isSelected,
  ) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: () => widget.onSuggestionSelected?.call(suggestion),
      onHover: (hovering) {
        if (hovering) {
          widget.onSuggestionHovered?.call(index);
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
            ? theme.colorScheme.primary.withOpacity(0.1)
            : null,
          border: isSelected
            ? Border(
                left: BorderSide(
                  color: theme.colorScheme.primary,
                  width: 2,
                ),
              )
            : null,
        ),
        child: Row(
          children: [
            // Icon
            if (widget.showIcons && suggestion.icon != null) ...[
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: _getIconBackgroundColor(suggestion.type, theme),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(
                  suggestion.icon,
                  size: 16,
                  color: _getIconColor(suggestion.type, theme),
                ),
              ),
              const SizedBox(width: 12),
            ],

            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Display text
                  Text(
                    suggestion.displayText,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                      color: isSelected
                        ? theme.colorScheme.primary
                        : theme.colorScheme.onSurface,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),

                  // Description
                  if (widget.showDescriptions && suggestion.description != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      suggestion.description!,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withOpacity(0.7),
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),

            // Metadata
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Type badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: _getTypeBadgeColor(suggestion.type, theme),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    _getTypeDisplayName(suggestion.type),
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.onSurface.withOpacity(0.8),
                    ),
                  ),
                ),

                // Shortcut key
                if (suggestion.shortcutKey != null) ...[
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: theme.colorScheme.outline.withOpacity(0.3),
                      ),
                      borderRadius: BorderRadius.circular(3),
                    ),
                    child: Text(
                      suggestion.shortcutKey!,
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontSize: 9,
                        fontFamily: 'monospace',
                        color: theme.colorScheme.onSurface.withOpacity(0.6),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFooter(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.3),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(8),
          bottomRight: Radius.circular(8),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              '↑↓ Navigate • Enter Select • Esc Cancel',
              style: theme.textTheme.bodySmall?.copyWith(
                fontSize: 10,
                color: theme.colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getIconBackgroundColor(CompletionType type, ThemeData theme) {
    switch (type) {
      case CompletionType.header:
        return theme.colorScheme.primary.withOpacity(0.1);
      case CompletionType.list:
        return theme.colorScheme.secondary.withOpacity(0.1);
      case CompletionType.link:
        return theme.colorScheme.tertiary.withOpacity(0.1);
      case CompletionType.image:
        return Colors.purple.withOpacity(0.1);
      case CompletionType.codeBlock:
        return Colors.orange.withOpacity(0.1);
      case CompletionType.table:
        return Colors.green.withOpacity(0.1);
      case CompletionType.emphasis:
        return Colors.blue.withOpacity(0.1);
      case CompletionType.blockquote:
        return Colors.indigo.withOpacity(0.1);
      case CompletionType.horizontalRule:
        return Colors.grey.withOpacity(0.1);
      case CompletionType.customShortcut:
        return theme.colorScheme.surfaceContainerHighest;
    }
  }

  Color _getIconColor(CompletionType type, ThemeData theme) {
    switch (type) {
      case CompletionType.header:
        return theme.colorScheme.primary;
      case CompletionType.list:
        return theme.colorScheme.secondary;
      case CompletionType.link:
        return theme.colorScheme.tertiary;
      case CompletionType.image:
        return Colors.purple;
      case CompletionType.codeBlock:
        return Colors.orange;
      case CompletionType.table:
        return Colors.green;
      case CompletionType.emphasis:
        return Colors.blue;
      case CompletionType.blockquote:
        return Colors.indigo;
      case CompletionType.horizontalRule:
        return Colors.grey;
      case CompletionType.customShortcut:
        return theme.colorScheme.onSurface;
    }
  }

  Color _getTypeBadgeColor(CompletionType type, ThemeData theme) {
    return theme.colorScheme.surfaceContainerHighest.withOpacity(0.5);
  }

  String _getTypeDisplayName(CompletionType type) {
    switch (type) {
      case CompletionType.header:
        return 'H';
      case CompletionType.list:
        return 'L';
      case CompletionType.link:
        return 'LINK';
      case CompletionType.image:
        return 'IMG';
      case CompletionType.codeBlock:
        return 'CODE';
      case CompletionType.table:
        return 'TBL';
      case CompletionType.emphasis:
        return 'EM';
      case CompletionType.blockquote:
        return 'Q';
      case CompletionType.horizontalRule:
        return 'HR';
      case CompletionType.customShortcut:
        return 'CUSTOM';
    }
  }
}

/// Positioning helper for the auto-complete overlay
class AutoCompletePositioning {
  /// Calculate the optimal position for the overlay
  static Offset calculatePosition({
    required BuildContext context,
    required GlobalKey textFieldKey,
    required TextEditingController controller,
    required double cursorOffset,
    double overlayHeight = 300,
    double overlayWidth = 400,
  }) {
    final renderBox = textFieldKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) {
      return const Offset(0, 0);
    }

    final textFieldRect = renderBox.localToGlobal(Offset.zero) & renderBox.size;
    final mediaQuery = MediaQuery.of(context);
    final screenSize = mediaQuery.size;
    final viewInsets = mediaQuery.viewInsets;

    // Estimate cursor position (simplified)
    final text = controller.text;
    final selection = controller.selection;
    final textBeforeCursor = text.substring(0, selection.baseOffset);
    final lines = textBeforeCursor.split('\n');

    // Approximate cursor position
    final lineHeight = 20.0; // Approximate line height
    final charWidth = 8.0; // Approximate character width

    final cursorY = textFieldRect.top + (lines.length - 1) * lineHeight + lineHeight;
    final cursorX = textFieldRect.left + (lines.last.length * charWidth).clamp(0.0, textFieldRect.width);

    // Calculate preferred position (below cursor)
    double overlayX = cursorX;
    double overlayY = cursorY;

    // Adjust if overlay would go off screen horizontally
    if (overlayX + overlayWidth > screenSize.width - 16) {
      overlayX = screenSize.width - overlayWidth - 16;
    }
    if (overlayX < 16) {
      overlayX = 16;
    }

    // Adjust if overlay would go off screen vertically
    final availableSpaceBelow = screenSize.height - viewInsets.bottom - overlayY - 16;
    final availableSpaceAbove = cursorY - textFieldRect.top - 16;

    if (availableSpaceBelow < overlayHeight && availableSpaceAbove > availableSpaceBelow) {
      // Show above cursor
      overlayY = cursorY - overlayHeight - lineHeight;
    }

    // Ensure minimum margins
    overlayY = overlayY.clamp(16.0, screenSize.height - viewInsets.bottom - overlayHeight - 16);

    return Offset(overlayX, overlayY);
  }
}