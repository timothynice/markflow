import 'dart:async';
import 'package:flutter/material.dart';
import 'enhanced_code_block.dart';

/// A debounced version of EnhancedCodeBlock that delays highlighting
/// updates to improve performance during rapid text changes
class DebouncedCodeBlock extends StatefulWidget {
  final String code;
  final String? language;
  final bool showLineNumbers;
  final bool showCopyButton;
  final bool showLanguageLabel;
  final EdgeInsets? padding;
  final double? fontSize;
  final String? fontFamily;
  final Duration debounceDelay;

  const DebouncedCodeBlock({
    super.key,
    required this.code,
    this.language,
    this.showLineNumbers = false,
    this.showCopyButton = true,
    this.showLanguageLabel = true,
    this.padding,
    this.fontSize,
    this.fontFamily,
    this.debounceDelay = const Duration(milliseconds: 300),
  });

  @override
  State<DebouncedCodeBlock> createState() => _DebouncedCodeBlockState();
}

class _DebouncedCodeBlockState extends State<DebouncedCodeBlock> {
  String _lastCode = '';
  String _displayCode = '';
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    _displayCode = widget.code;
    _lastCode = widget.code;
  }

  @override
  void didUpdateWidget(DebouncedCodeBlock oldWidget) {
    super.didUpdateWidget(oldWidget);

    // If code changed, debounce the update
    if (oldWidget.code != widget.code) {
      _debounceTimer?.cancel();
      _debounceTimer = Timer(widget.debounceDelay, () {
        if (mounted) {
          setState(() {
            _displayCode = widget.code;
            _lastCode = widget.code;
          });
        }
      });
    }

    // If other properties changed, update immediately
    if (oldWidget.language != widget.language ||
        oldWidget.showLineNumbers != widget.showLineNumbers ||
        oldWidget.showCopyButton != widget.showCopyButton ||
        oldWidget.showLanguageLabel != widget.showLanguageLabel) {
      setState(() {
        _displayCode = widget.code;
        _lastCode = widget.code;
      });
    }
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return EnhancedCodeBlock(
      code: _displayCode,
      language: widget.language,
      showLineNumbers: widget.showLineNumbers,
      showCopyButton: widget.showCopyButton,
      showLanguageLabel: widget.showLanguageLabel,
      padding: widget.padding,
      fontSize: widget.fontSize,
      fontFamily: widget.fontFamily,
    );
  }
}