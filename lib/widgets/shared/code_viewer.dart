import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import '../../features/markdown/services/syntax_highlight_service.dart';

/// Reusable code viewer widget with syntax highlighting and copy functionality
class CodeViewer extends StatefulWidget {
  final String code;
  final String language;
  final VoidCallback? onCopy;

  const CodeViewer({
    super.key,
    required this.code,
    this.language = 'dart',
    this.onCopy,
  });

  @override
  State<CodeViewer> createState() => _CodeViewerState();
}

class _CodeViewerState extends State<CodeViewer> {
  TextSpan? _highlightedCode;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _highlightCode();
  }

  @override
  void didUpdateWidget(CodeViewer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.code != widget.code || oldWidget.language != widget.language) {
      _highlightCode();
    }
  }

  Future<void> _highlightCode() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Use current theme brightness for syntax highlighting theme
      final isDarkMode = Theme.of(context).brightness == Brightness.dark;
      final highlightService = SyntaxHighlightService.instance;

      final highlightedSpan = await highlightService.highlight(
        widget.code,
        widget.language,
        isDarkMode: isDarkMode,
      );

      setState(() {
        _highlightedCode = highlightedSpan;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Failed to highlight code: $e');
      setState(() {
        _isLoading = false;
        _highlightedCode = TextSpan(
          text: widget.code,
          style: const TextStyle(
            fontSize: 14,
            fontFamily: 'GeistMono',
          ),
        );
      });
    }
  }

  /// Copies the code to the clipboard and shows a confirmation
  Future<void> _copyToClipboard() async {
    try {
      await Clipboard.setData(ClipboardData(text: widget.code));
      if (context.mounted) {
        final sonner = ShadSonner.of(context);
        sonner.show(
          ShadToast(
            title: const Text('Code copied to clipboard!'),
            description: const Text(
              'The code snippet has been copied to your clipboard.',
            ),
          ),
        );
      }
      widget.onCopy?.call();
    } catch (e) {
      if (context.mounted) {
        final sonner = ShadSonner.of(context);
        sonner.show(
          ShadToast.destructive(
            title: const Text('Failed to copy'),
            description: const Text(
              'Could not copy code to clipboard. Please try again.',
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        border: Border.all(
          color: isDarkMode ? Colors.grey[800]! : Colors.grey.shade200,
        ),
        borderRadius: BorderRadius.circular(8),
        color: isDarkMode ? Colors.grey[900] : Colors.grey.shade50,
      ),
      child: Stack(
        children: [
          // Code content
          Padding(
            padding: const EdgeInsets.all(16),
            child: ScrollConfiguration(
              behavior: ScrollConfiguration.of(context).copyWith(
                scrollbars: false,
              ),
              child: _isLoading
                  ? const Center(
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    )
                  : SingleChildScrollView(
                      child: SelectableText.rich(
                        _highlightedCode ?? TextSpan(
                          text: widget.code,
                          style: const TextStyle(
                            fontSize: 14,
                            fontFamily: 'GeistMono',
                          ),
                        ),
                        style: const TextStyle(
                          fontSize: 14,
                          fontFamily: 'GeistMono',
                        ),
                      ),
                    ),
            ),
          ),
          // Copy button
          Positioned(
            top: 12,
            right: 12,
            child: ShadButton.outline(
              onPressed: _copyToClipboard,
              size: ShadButtonSize.sm,
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.copy, size: 16),
                  SizedBox(width: 4),
                  Text('Copy'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
