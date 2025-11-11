import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import '../services/syntax_highlight_service.dart';
import '../../../theme_controller.dart';

/// Enhanced code block widget with syntax highlighting and improved UX
class EnhancedCodeBlock extends StatefulWidget {
  final String code;
  final String? language;
  final bool showLineNumbers;
  final bool showCopyButton;
  final bool showLanguageLabel;
  final EdgeInsets? padding;
  final double? fontSize;
  final String? fontFamily;

  const EnhancedCodeBlock({
    super.key,
    required this.code,
    this.language,
    this.showLineNumbers = false,
    this.showCopyButton = true,
    this.showLanguageLabel = true,
    this.padding,
    this.fontSize,
    this.fontFamily,
  });

  @override
  State<EnhancedCodeBlock> createState() => _EnhancedCodeBlockState();
}

class _EnhancedCodeBlockState extends State<EnhancedCodeBlock> {
  TextSpan? _highlightedCode;
  String? _detectedLanguage;
  bool _isLoading = true;
  bool _showCopied = false;

  @override
  void initState() {
    super.initState();
    _highlightCode();
  }

  @override
  void didUpdateWidget(EnhancedCodeBlock oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.code != widget.code ||
        oldWidget.language != widget.language) {
      _highlightCode();
    }
  }

  Future<void> _highlightCode() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final isDarkMode = ThemeController.instance.isDarkMode;
      final highlightService = SyntaxHighlightService.instance;

      // Highlight the code
      final highlightedSpan = await highlightService.highlight(
        widget.code,
        widget.language,
        isDarkMode: isDarkMode,
      );

      // Detect language for display
      _detectedLanguage = widget.language ??
          highlightService.detectLanguage(widget.code);

      setState(() {
        _highlightedCode = highlightedSpan;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error highlighting code: $e');
      setState(() {
        _isLoading = false;
        _highlightedCode = TextSpan(
          text: widget.code,
          style: _getFallbackTextStyle(),
        );
      });
    }
  }

  TextStyle _getFallbackTextStyle() {
    final isDarkMode = ThemeController.instance.isDarkMode;
    return TextStyle(
      fontFamily: widget.fontFamily ?? 'GeistMono',
      fontSize: widget.fontSize ?? 14,
      color: isDarkMode ? Colors.grey[300] : Colors.grey[800],
      height: 1.4,
    );
  }

  Future<void> _copyToClipboard() async {
    try {
      await Clipboard.setData(ClipboardData(text: widget.code));
      setState(() {
        _showCopied = true;
      });

      // Show copied state for 2 seconds
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) {
          setState(() {
            _showCopied = false;
          });
        }
      });

      // Show toast notification
      if (context.mounted) {
        final sonner = ShadSonner.of(context);
        sonner.show(
          ShadToast(
            title: const Text('Code copied!'),
            description: Text(
              'Code snippet${_detectedLanguage != null ? " ($_detectedLanguage)" : ""} copied to clipboard.',
            ),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        final sonner = ShadSonner.of(context);
        sonner.show(
          ShadToast.destructive(
            title: const Text('Failed to copy'),
            description: const Text('Could not copy code to clipboard.'),
          ),
        );
      }
    }
  }

  Widget _buildLineNumbers() {
    final lines = widget.code.split('\n');
    final isDarkMode = ThemeController.instance.isDarkMode;

    return Container(
      padding: const EdgeInsets.only(right: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: lines.asMap().entries.map((entry) {
          final lineNumber = entry.key + 1;
          return SizedBox(
            height: 19.6, // Match line height of code
            child: Text(
              '$lineNumber',
              style: TextStyle(
                fontFamily: widget.fontFamily ?? 'GeistMono',
                fontSize: (widget.fontSize ?? 14) - 1,
                color: isDarkMode ? Colors.grey[600] : Colors.grey[400],
                height: 1.4,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = ThemeController.instance.isDarkMode;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF1A1A1A) : const Color(0xFFF8F9FA),
        border: Border.all(
          color: isDarkMode ? Colors.grey[800]! : Colors.grey[200]!,
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with language label and copy button
          if (widget.showLanguageLabel || widget.showCopyButton)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: isDarkMode ? Colors.grey[900] : Colors.grey[100],
                border: Border(
                  bottom: BorderSide(
                    color: isDarkMode ? Colors.grey[800]! : Colors.grey[200]!,
                  ),
                ),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(8),
                  topRight: Radius.circular(8),
                ),
              ),
              child: Row(
                children: [
                  if (widget.showLanguageLabel && _detectedLanguage != null)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        _detectedLanguage!,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ),
                  const Spacer(),
                  if (widget.showCopyButton)
                    ShadButton.outline(
                      onPressed: _copyToClipboard,
                      size: ShadButtonSize.sm,
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 200),
                        child: _showCopied
                            ? const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.check, size: 14),
                                  SizedBox(width: 4),
                                  Text('Copied', style: TextStyle(fontSize: 12)),
                                ],
                              )
                            : const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.copy, size: 14),
                                  SizedBox(width: 4),
                                  Text('Copy', style: TextStyle(fontSize: 12)),
                                ],
                              ),
                      ),
                    ),
                ],
              ),
            ),

          // Code content
          Container(
            padding: widget.padding ?? const EdgeInsets.all(16),
            width: double.infinity,
            child: _isLoading
                ? SizedBox(
                    height: 40,
                    child: Center(
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ),
                  )
                : Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Line numbers
                      if (widget.showLineNumbers) _buildLineNumbers(),

                      // Code content
                      Expanded(
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: SelectableText.rich(
                            _highlightedCode ?? TextSpan(
                              text: widget.code,
                              style: _getFallbackTextStyle(),
                            ),
                            style: TextStyle(
                              fontFamily: widget.fontFamily ?? 'GeistMono',
                              fontSize: widget.fontSize ?? 14,
                              height: 1.4,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}