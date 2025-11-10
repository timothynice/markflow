import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

/// Focus mode overlay for distraction-free writing
class FocusModeOverlay extends StatefulWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final VoidCallback onExit;
  final String? currentParagraph;
  final FocusModeSettings settings;

  const FocusModeOverlay({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.onExit,
    this.currentParagraph,
    this.settings = const FocusModeSettings(),
  });

  @override
  State<FocusModeOverlay> createState() => _FocusModeOverlayState();
}

class _FocusModeOverlayState extends State<FocusModeOverlay>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _typewriterController;
  late ScrollController _scrollController;
  Timer? _hideControlsTimer;
  bool _showControls = true;
  bool _isTypewriterMode = false;
  String _currentText = '';

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _typewriterController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _scrollController = ScrollController();

    _currentText = widget.controller.text;
    widget.controller.addListener(_onTextChanged);

    _fadeController.forward();
    _startHideControlsTimer();

    // Enable typewriter mode if configured
    if (widget.settings.typewriterMode) {
      _isTypewriterMode = true;
      _typewriterController.forward();
    }

    // Auto-focus the text field
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _hideControlsTimer?.cancel();
    _fadeController.dispose();
    _typewriterController.dispose();
    _scrollController.dispose();
    widget.controller.removeListener(_onTextChanged);
    super.dispose();
  }

  void _onTextChanged() {
    setState(() {
      _currentText = widget.controller.text;
    });

    // In typewriter mode, keep cursor centered
    if (_isTypewriterMode) {
      _centerCursor();
    }

    _showControlsTemporarily();
  }

  void _centerCursor() {
    if (!_scrollController.hasClients) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final viewport = _scrollController.position.viewportDimension;
      final maxScroll = _scrollController.position.maxScrollExtent;

      // Calculate cursor position based on text and selection
      final selection = widget.controller.selection;
      if (selection.isValid) {
        final textBeforeCursor = widget.controller.text.substring(0, selection.baseOffset);
        final lines = textBeforeCursor.split('\n').length;
        final lineHeight = 30.0; // Approximate line height
        final cursorOffset = lines * lineHeight;

        // Center the cursor in the viewport
        final targetOffset = (cursorOffset - viewport / 2).clamp(0.0, maxScroll);

        _scrollController.animateTo(
          targetOffset,
          duration: const Duration(milliseconds: 150),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _showControlsTemporarily() {
    setState(() {
      _showControls = true;
    });
    _startHideControlsTimer();
  }

  void _startHideControlsTimer() {
    _hideControlsTimer?.cancel();
    _hideControlsTimer = Timer(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          _showControls = false;
        });
      }
    });
  }

  void _toggleTypewriter() {
    setState(() {
      _isTypewriterMode = !_isTypewriterMode;
    });

    if (_isTypewriterMode) {
      _typewriterController.forward();
      _centerCursor();
    } else {
      _typewriterController.reverse();
    }
  }

  String _getCurrentParagraph() {
    final selection = widget.controller.selection;
    if (!selection.isValid) return '';

    final text = widget.controller.text;
    final cursorPos = selection.baseOffset;

    // Find paragraph boundaries
    int start = cursorPos;
    int end = cursorPos;

    // Find start of paragraph
    while (start > 0 && text[start - 1] != '\n') {
      start--;
    }

    // Find end of paragraph
    while (end < text.length && text[end] != '\n') {
      end++;
    }

    return text.substring(start, end).trim();
  }

  List<String> _getParagraphs() {
    return widget.controller.text.split('\n\n').where((p) => p.trim().isNotEmpty).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: widget.settings.backgroundColor,
      child: Stack(
        children: [
          // Background with blur effect
          Container(
            decoration: BoxDecoration(
              color: widget.settings.backgroundColor,
              image: widget.settings.backgroundImage != null
                  ? DecorationImage(
                      image: AssetImage(widget.settings.backgroundImage!),
                      fit: BoxFit.cover,
                      opacity: widget.settings.backgroundOpacity,
                    )
                  : null,
            ),
          ),

          // Main content area
          Center(
            child: Container(
              constraints: BoxConstraints(
                maxWidth: widget.settings.contentWidth,
              ),
              child: _buildEditor(),
            ),
          ),

          // Controls overlay
          AnimatedOpacity(
            opacity: _showControls ? 1.0 : 0.0,
            duration: const Duration(milliseconds: 300),
            child: _buildControls(),
          ),

          // Keyboard shortcuts help
          if (widget.settings.showKeyboardShortcuts)
            Positioned(
              bottom: 20,
              right: 20,
              child: AnimatedOpacity(
                opacity: _showControls ? 0.7 : 0.0,
                duration: const Duration(milliseconds: 300),
                child: _buildKeyboardShortcuts(),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildEditor() {
    final theme = Theme.of(context);

    return AnimatedBuilder(
      animation: _fadeController,
      builder: (context, child) {
        return FadeTransition(
          opacity: _fadeController,
          child: Container(
            padding: EdgeInsets.symmetric(
              horizontal: widget.settings.horizontalPadding,
              vertical: widget.settings.verticalPadding,
            ),
            child: Column(
              children: [
                if (widget.settings.showCurrentParagraph && !_isTypewriterMode) ...[
                  _buildCurrentParagraphHighlight(),
                  const SizedBox(height: 20),
                ],
                Expanded(
                  child: _buildTextEditor(theme),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildTextEditor(ThemeData theme) {
    if (_isTypewriterMode) {
      return _buildTypewriterEditor(theme);
    }

    return TextField(
      controller: widget.controller,
      focusNode: widget.focusNode,
      scrollController: _scrollController,
      maxLines: null,
      expands: true,
      textAlignVertical: TextAlignVertical.top,
      style: GoogleFonts.jetBrainsMono().copyWith(
        fontSize: widget.settings.fontSize,
        height: widget.settings.lineHeight,
        color: widget.settings.textColor,
        fontWeight: FontWeight.w400,
      ),
      decoration: InputDecoration(
        border: InputBorder.none,
        hintText: widget.settings.placeholder,
        hintStyle: TextStyle(
          color: widget.settings.textColor.withValues(alpha: 0.5),
        ),
      ),
      cursorColor: widget.settings.cursorColor,
      cursorWidth: 2.0,
      cursorHeight: widget.settings.fontSize * widget.settings.lineHeight,
    );
  }

  Widget _buildTypewriterEditor(ThemeData theme) {
    return AnimatedBuilder(
      animation: _typewriterController,
      builder: (context, child) {
        return Stack(
          children: [
            // Dimmed background paragraphs
            if (widget.settings.dimNonCurrentParagraphs)
              _buildDimmedContent(),

            // Main editor
            TextField(
              controller: widget.controller,
              focusNode: widget.focusNode,
              scrollController: _scrollController,
              maxLines: null,
              expands: true,
              textAlignVertical: TextAlignVertical.center,
              textAlign: TextAlign.center,
              style: GoogleFonts.jetBrainsMono().copyWith(
                fontSize: widget.settings.fontSize,
                height: widget.settings.lineHeight,
                color: widget.settings.textColor,
                fontWeight: FontWeight.w400,
              ),
              decoration: InputDecoration(
                border: InputBorder.none,
                hintText: widget.settings.placeholder,
                hintStyle: TextStyle(
                  color: widget.settings.textColor.withValues(alpha: 0.5),
                ),
                contentPadding: EdgeInsets.symmetric(
                  vertical: MediaQuery.of(context).size.height * 0.4,
                ),
              ),
              cursorColor: widget.settings.cursorColor,
              cursorWidth: 3.0,
              cursorHeight: widget.settings.fontSize * widget.settings.lineHeight,
            ),
          ],
        );
      },
    );
  }

  Widget _buildDimmedContent() {
    final currentParagraph = _getCurrentParagraph();
    final paragraphs = _getParagraphs();

    return Container(
      padding: EdgeInsets.symmetric(
        vertical: MediaQuery.of(context).size.height * 0.4,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: paragraphs.map((paragraph) {
          final isCurrent = paragraph.trim() == currentParagraph.trim();
          return Opacity(
            opacity: isCurrent ? 1.0 : 0.3,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                paragraph,
                textAlign: TextAlign.center,
                style: GoogleFonts.jetBrainsMono().copyWith(
                  fontSize: widget.settings.fontSize,
                  height: widget.settings.lineHeight,
                  color: widget.settings.textColor,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildCurrentParagraphHighlight() {
    final currentParagraph = _getCurrentParagraph();
    if (currentParagraph.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: widget.settings.textColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        currentParagraph,
        style: GoogleFonts.jetBrainsMono().copyWith(
          fontSize: widget.settings.fontSize * 0.9,
          color: widget.settings.textColor.withValues(alpha: 0.8),
          fontStyle: FontStyle.italic,
        ),
      ),
    );
  }

  Widget _buildControls() {
    return Positioned(
      top: 20,
      right: 20,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Typewriter mode toggle
          _buildControlButton(
            icon: _isTypewriterMode ? Icons.keyboard : Icons.keyboard_outlined,
            tooltip: 'Toggle typewriter mode',
            onPressed: _toggleTypewriter,
            isActive: _isTypewriterMode,
          ),
          const SizedBox(width: 8),

          // Settings button
          _buildControlButton(
            icon: Icons.settings_outlined,
            tooltip: 'Focus mode settings',
            onPressed: () {
              // TODO: Show settings dialog
            },
          ),
          const SizedBox(width: 8),

          // Exit button
          _buildControlButton(
            icon: Icons.close,
            tooltip: 'Exit focus mode (Esc)',
            onPressed: widget.onExit,
            isDestructive: true,
          ),
        ],
      ),
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback onPressed,
    bool isActive = false,
    bool isDestructive = false,
  }) {
    return Tooltip(
      message: tooltip,
      child: ShadButton.ghost(
        onPressed: onPressed,
        icon: Icon(
          icon,
          size: 18,
          color: isDestructive
              ? Colors.red
              : isActive
                  ? widget.settings.textColor
                  : widget.settings.textColor.withValues(alpha: 0.7),
        ),
        padding: const EdgeInsets.all(8),
        backgroundColor: isActive
            ? widget.settings.textColor.withValues(alpha: 0.1)
            : Colors.transparent,
      ),
    );
  }

  Widget _buildKeyboardShortcuts() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: widget.settings.backgroundColor.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: widget.settings.textColor.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildShortcutRow('Esc', 'Exit focus mode'),
          _buildShortcutRow('Ctrl/Cmd + T', 'Toggle typewriter'),
          _buildShortcutRow('Ctrl/Cmd + ;', 'Toggle controls'),
        ],
      ),
    );
  }

  Widget _buildShortcutRow(String keys, String description) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            keys,
            style: TextStyle(
              fontSize: 11,
              fontFamily: 'monospace',
              color: widget.settings.textColor.withValues(alpha: 0.8),
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            description,
            style: TextStyle(
              fontSize: 11,
              color: widget.settings.textColor.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }
}

/// Configuration for focus mode
class FocusModeSettings {
  final Color backgroundColor;
  final Color textColor;
  final Color cursorColor;
  final double fontSize;
  final double lineHeight;
  final double contentWidth;
  final double horizontalPadding;
  final double verticalPadding;
  final bool typewriterMode;
  final bool showCurrentParagraph;
  final bool dimNonCurrentParagraphs;
  final bool showKeyboardShortcuts;
  final String placeholder;
  final String? backgroundImage;
  final double backgroundOpacity;

  const FocusModeSettings({
    this.backgroundColor = const Color(0xFF1a1a1a),
    this.textColor = const Color(0xFFe5e5e5),
    this.cursorColor = const Color(0xFF3b82f6),
    this.fontSize = 18.0,
    this.lineHeight = 1.8,
    this.contentWidth = 800.0,
    this.horizontalPadding = 40.0,
    this.verticalPadding = 60.0,
    this.typewriterMode = false,
    this.showCurrentParagraph = true,
    this.dimNonCurrentParagraphs = true,
    this.showKeyboardShortcuts = true,
    this.placeholder = 'Start writing...',
    this.backgroundImage,
    this.backgroundOpacity = 0.1,
  });

  FocusModeSettings copyWith({
    Color? backgroundColor,
    Color? textColor,
    Color? cursorColor,
    double? fontSize,
    double? lineHeight,
    double? contentWidth,
    double? horizontalPadding,
    double? verticalPadding,
    bool? typewriterMode,
    bool? showCurrentParagraph,
    bool? dimNonCurrentParagraphs,
    bool? showKeyboardShortcuts,
    String? placeholder,
    String? backgroundImage,
    double? backgroundOpacity,
  }) {
    return FocusModeSettings(
      backgroundColor: backgroundColor ?? this.backgroundColor,
      textColor: textColor ?? this.textColor,
      cursorColor: cursorColor ?? this.cursorColor,
      fontSize: fontSize ?? this.fontSize,
      lineHeight: lineHeight ?? this.lineHeight,
      contentWidth: contentWidth ?? this.contentWidth,
      horizontalPadding: horizontalPadding ?? this.horizontalPadding,
      verticalPadding: verticalPadding ?? this.verticalPadding,
      typewriterMode: typewriterMode ?? this.typewriterMode,
      showCurrentParagraph: showCurrentParagraph ?? this.showCurrentParagraph,
      dimNonCurrentParagraphs: dimNonCurrentParagraphs ?? this.dimNonCurrentParagraphs,
      showKeyboardShortcuts: showKeyboardShortcuts ?? this.showKeyboardShortcuts,
      placeholder: placeholder ?? this.placeholder,
      backgroundImage: backgroundImage ?? this.backgroundImage,
      backgroundOpacity: backgroundOpacity ?? this.backgroundOpacity,
    );
  }
}