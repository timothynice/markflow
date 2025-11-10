import 'package:flutter/material.dart';
import '../services/key_binding_service.dart';

class ModeIndicator extends StatelessWidget {
  final KeyBindingService keyBindingService;
  final bool isCompact;

  const ModeIndicator({
    super.key,
    required this.keyBindingService,
    this.isCompact = false,
  });

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: keyBindingService,
      builder: (context, _, __) {
        if (!keyBindingService.settings.showModeIndicator || !keyBindingService.isEnabled) {
          return const SizedBox.shrink();
        }

        return Container(
          padding: EdgeInsets.symmetric(
            horizontal: isCompact ? 8 : 12,
            vertical: isCompact ? 4 : 8,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildModeChip(context),
              if (keyBindingService.currentFeedback != null) ...[
                const SizedBox(width: 12),
                _buildFeedbackChip(context),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildModeChip(BuildContext context) {
    final theme = Theme.of(context);
    final settings = keyBindingService.settings;

    if (settings.mode == KeyBindingMode.none) {
      return const SizedBox.shrink();
    }

    String modeText;
    Color modeColor;
    IconData modeIcon;

    switch (settings.mode) {
      case KeyBindingMode.vim:
        modeText = _getVimModeText();
        modeColor = _getVimModeColor(theme);
        modeIcon = _getVimModeIcon();
        break;
      case KeyBindingMode.emacs:
        modeText = 'EMACS';
        modeColor = theme.colorScheme.secondary;
        modeIcon = Icons.keyboard;
        break;
      case KeyBindingMode.none:
        return const SizedBox.shrink();
    }

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isCompact ? 6 : 8,
        vertical: isCompact ? 2 : 4,
      ),
      decoration: BoxDecoration(
        color: modeColor.withOpacity(0.1),
        border: Border.all(color: modeColor.withOpacity(0.3)),
        borderRadius: BorderRadius.circular(isCompact ? 4 : 6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            modeIcon,
            size: isCompact ? 14 : 16,
            color: modeColor,
          ),
          const SizedBox(width: 4),
          Text(
            modeText,
            style: TextStyle(
              color: modeColor,
              fontSize: isCompact ? 11 : 12,
              fontWeight: FontWeight.w600,
              fontFamily: 'monospace',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeedbackChip(BuildContext context) {
    final feedback = keyBindingService.currentFeedback;
    if (feedback == null) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final feedbackColor = _getFeedbackColor(theme, feedback.type);

    return AnimatedOpacity(
      opacity: 1.0,
      duration: const Duration(milliseconds: 150),
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: isCompact ? 6 : 8,
          vertical: isCompact ? 2 : 4,
        ),
        decoration: BoxDecoration(
          color: feedbackColor.withOpacity(0.1),
          border: Border.all(color: feedbackColor.withOpacity(0.3)),
          borderRadius: BorderRadius.circular(isCompact ? 4 : 6),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              _getFeedbackIcon(feedback.type),
              size: isCompact ? 12 : 14,
              color: feedbackColor,
            ),
            const SizedBox(width: 4),
            Text(
              feedback.message,
              style: TextStyle(
                color: feedbackColor,
                fontSize: isCompact ? 10 : 11,
                fontWeight: FontWeight.w500,
                fontFamily: 'monospace',
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getVimModeText() {
    switch (keyBindingService.vimMode) {
      case VimMode.normal:
        return 'NORMAL';
      case VimMode.insert:
        return 'INSERT';
      case VimMode.visual:
        return 'VISUAL';
      case VimMode.visualLine:
        return 'V-LINE';
      case VimMode.visualBlock:
        return 'V-BLOCK';
    }
  }

  Color _getVimModeColor(ThemeData theme) {
    switch (keyBindingService.vimMode) {
      case VimMode.normal:
        return theme.colorScheme.primary;
      case VimMode.insert:
        return Colors.green;
      case VimMode.visual:
        return Colors.orange;
      case VimMode.visualLine:
        return Colors.orange.shade700;
      case VimMode.visualBlock:
        return Colors.orange.shade900;
    }
  }

  IconData _getVimModeIcon() {
    switch (keyBindingService.vimMode) {
      case VimMode.normal:
        return Icons.keyboard_command_key;
      case VimMode.insert:
        return Icons.edit;
      case VimMode.visual:
        return Icons.select_all;
      case VimMode.visualLine:
        return Icons.horizontal_rule;
      case VimMode.visualBlock:
        return Icons.crop_free;
    }
  }

  Color _getFeedbackColor(ThemeData theme, CommandFeedbackType type) {
    switch (type) {
      case CommandFeedbackType.info:
        return theme.colorScheme.primary;
      case CommandFeedbackType.success:
        return Colors.green;
      case CommandFeedbackType.error:
        return theme.colorScheme.error;
      case CommandFeedbackType.warning:
        return Colors.orange;
    }
  }

  IconData _getFeedbackIcon(CommandFeedbackType type) {
    switch (type) {
      case CommandFeedbackType.info:
        return Icons.info_outline;
      case CommandFeedbackType.success:
        return Icons.check_circle_outline;
      case CommandFeedbackType.error:
        return Icons.error_outline;
      case CommandFeedbackType.warning:
        return Icons.warning_amber;
    }
  }
}

class FloatingModeIndicator extends StatelessWidget {
  final KeyBindingService keyBindingService;
  final Alignment alignment;

  const FloatingModeIndicator({
    super.key,
    required this.keyBindingService,
    this.alignment = Alignment.bottomLeft,
  });

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: keyBindingService,
      builder: (context, _, __) {
        if (!keyBindingService.settings.showModeIndicator || !keyBindingService.isEnabled) {
          return const SizedBox.shrink();
        }

        return Positioned(
          bottom: alignment == Alignment.bottomLeft || alignment == Alignment.bottomRight ? 16 : null,
          top: alignment == Alignment.topLeft || alignment == Alignment.topRight ? 16 : null,
          left: alignment == Alignment.bottomLeft || alignment == Alignment.topLeft ? 16 : null,
          right: alignment == Alignment.bottomRight || alignment == Alignment.topRight ? 16 : null,
          child: Material(
            elevation: 4,
            borderRadius: BorderRadius.circular(8),
            child: Container(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Theme.of(context).dividerColor.withOpacity(0.2),
                ),
              ),
              child: ModeIndicator(
                keyBindingService: keyBindingService,
                isCompact: false,
              ),
            ),
          ),
        );
      },
    );
  }
}

class StatusBarModeIndicator extends StatelessWidget {
  final KeyBindingService keyBindingService;

  const StatusBarModeIndicator({
    super.key,
    required this.keyBindingService,
  });

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: keyBindingService,
      builder: (context, _, __) {
        if (!keyBindingService.settings.showModeIndicator || !keyBindingService.isEnabled) {
          return const SizedBox.shrink();
        }

        final theme = Theme.of(context);

        return Container(
          height: 28,
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceVariant.withOpacity(0.5),
            border: Border(
              top: BorderSide(
                color: theme.dividerColor.withOpacity(0.2),
              ),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                ModeIndicator(
                  keyBindingService: keyBindingService,
                  isCompact: true,
                ),
                const Spacer(),
                if (keyBindingService.isVimMode)
                  _buildVimStatusInfo(context),
                if (keyBindingService.isEmacsMode)
                  _buildEmacsStatusInfo(context),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildVimStatusInfo(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'VIM',
          style: TextStyle(
            color: theme.colorScheme.onSurfaceVariant,
            fontSize: 10,
            fontWeight: FontWeight.w500,
            fontFamily: 'monospace',
          ),
        ),
        const SizedBox(width: 8),
        Icon(
          Icons.help_outline,
          size: 12,
          color: theme.colorScheme.onSurfaceVariant.withOpacity(0.7),
        ),
        const SizedBox(width: 2),
        Text(
          'F1',
          style: TextStyle(
            color: theme.colorScheme.onSurfaceVariant.withOpacity(0.7),
            fontSize: 9,
            fontFamily: 'monospace',
          ),
        ),
      ],
    );
  }

  Widget _buildEmacsStatusInfo(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'EMACS',
          style: TextStyle(
            color: theme.colorScheme.onSurfaceVariant,
            fontSize: 10,
            fontWeight: FontWeight.w500,
            fontFamily: 'monospace',
          ),
        ),
        const SizedBox(width: 8),
        Icon(
          Icons.help_outline,
          size: 12,
          color: theme.colorScheme.onSurfaceVariant.withOpacity(0.7),
        ),
        const SizedBox(width: 2),
        Text(
          'F1',
          style: TextStyle(
            color: theme.colorScheme.onSurfaceVariant.withOpacity(0.7),
            fontSize: 9,
            fontFamily: 'monospace',
          ),
        ),
      ],
    );
  }
}