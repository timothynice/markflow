import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/key_binding_service.dart';

class EmacsKeyHandler {
  final KeyBindingService _service;

  // State management
  String _commandBuffer = '';
  bool _markActive = false;
  TextSelection? _markSelection;
  String _killRing = '';
  String _lastSearchPattern = '';
  int _lastSearchDirection = 1; // 1 for forward, -1 for backward

  EmacsKeyHandler(this._service);

  bool handleKeyEvent(KeyEvent event, TextEditingController controller) {
    if (event is! KeyDownEvent) return false;

    final key = event.logicalKey;
    final isCtrl = HardwareKeyboard.instance.isControlPressed;
    final isAlt = HardwareKeyboard.instance.isAltPressed;
    final isShift = HardwareKeyboard.instance.isShiftPressed;

    if (key == LogicalKeyboardKey.shift ||
        key == LogicalKeyboardKey.control ||
        key == LogicalKeyboardKey.alt) {
      return false; // Skip modifier keys alone
    }

    final keyLabel = _getKeyLabel(key, isShift, isCtrl, isAlt);

    return _handleEmacsCommand(keyLabel, controller);
  }

  String _getKeyLabel(LogicalKeyboardKey key, bool isShift, bool isCtrl, bool isAlt) {
    String prefix = '';
    if (isCtrl) prefix += 'C-';
    if (isAlt) prefix += 'M-';
    if (isShift && key.keyLabel.length == 1) return prefix + key.keyLabel.toUpperCase();

    if (key == LogicalKeyboardKey.escape) return 'Escape';
    if (key == LogicalKeyboardKey.enter) return 'Enter';
    if (key == LogicalKeyboardKey.tab) return 'Tab';
    if (key == LogicalKeyboardKey.backspace) return 'Backspace';
    if (key == LogicalKeyboardKey.space) return prefix + 'Space';
    if (key == LogicalKeyboardKey.arrowUp) return prefix + 'Up';
    if (key == LogicalKeyboardKey.arrowDown) return prefix + 'Down';
    if (key == LogicalKeyboardKey.arrowLeft) return prefix + 'Left';
    if (key == LogicalKeyboardKey.arrowRight) return prefix + 'Right';

    // Handle character keys
    final keyName = key.keyLabel;
    if (keyName.length == 1) {
      return prefix + keyName.toLowerCase();
    }

    return prefix + keyName;
  }

  bool _handleEmacsCommand(String key, TextEditingController controller) {
    // Handle escape to cancel command
    if (key == 'Escape') {
      _clearCommand();
      _clearMark();
      return true;
    }

    // Handle Ctrl+x prefix commands
    if (key == 'C-x') {
      _commandBuffer = 'C-x ';
      _service.showFeedback('C-x-', CommandFeedbackType.info);
      return true;
    }

    // Handle multi-character commands
    if (_commandBuffer.isNotEmpty) {
      return _handleMultiCharacterCommand(_commandBuffer + key, controller);
    }

    // Single character commands
    switch (key) {
      // Basic navigation
      case 'C-f':
      case 'Right':
        _moveForward(controller, 1);
        break;
      case 'C-b':
      case 'Left':
        _moveBackward(controller, 1);
        break;
      case 'C-n':
      case 'Down':
        _moveDown(controller, 1);
        break;
      case 'C-p':
      case 'Up':
        _moveUp(controller, 1);
        break;
      case 'C-a':
        _moveToLineStart(controller);
        break;
      case 'C-e':
        _moveToLineEnd(controller);
        break;

      // Word navigation
      case 'M-f':
        _moveForwardWord(controller, 1);
        break;
      case 'M-b':
        _moveBackwardWord(controller, 1);
        break;
      case 'M-<':
        _moveToBufferStart(controller);
        break;
      case 'M->':
        _moveToBufferEnd(controller);
        break;

      // Delete operations
      case 'C-d':
        _deleteForward(controller, 1);
        break;
      case 'Backspace':
      case 'C-h':
        _deleteBackward(controller, 1);
        break;
      case 'M-d':
        _deleteWordForward(controller, 1);
        break;
      case 'C-k':
        _killToLineEnd(controller);
        break;
      case 'C-w':
        _killRegion(controller);
        break;
      case 'M-Backspace':
        _killWordBackward(controller);
        break;

      // Copy/Paste operations
      case 'C-y':
        _yank(controller);
        break;
      case 'M-w':
        _copyRegion(controller);
        break;

      // Mark operations
      case 'C-Space':
        _setMark(controller);
        break;

      // Search operations
      case 'C-s':
        _searchForward(controller);
        break;
      case 'C-r':
        _searchBackward(controller);
        break;

      // Undo
      case 'C-/':
        _undo(controller);
        break;

      // Quit/Cancel
      case 'C-g':
        _clearCommand();
        _clearMark();
        _service.showFeedback('Quit', CommandFeedbackType.info);
        break;

      default:
        return false; // Command not handled
    }

    _clearCommand();
    return true;
  }

  bool _handleMultiCharacterCommand(String command, TextEditingController controller) {
    switch (command) {
      // Ctrl+x commands
      case 'C-x C-s':
        _saveBuffer(controller);
        break;
      case 'C-x C-w':
        _writeFile(controller);
        break;
      case 'C-x C-f':
        _findFile(controller);
        break;
      case 'C-x u':
        _undo(controller);
        break;
      case 'C-x h':
        _selectAll(controller);
        break;

      default:
        _service.showFeedback('Unknown command: $command', CommandFeedbackType.warning);
        _clearCommand();
        return true;
    }

    _clearCommand();
    return true;
  }

  // Navigation operations
  void _moveForward(TextEditingController controller, int count) {
    final offset = controller.selection.baseOffset;
    final newOffset = (offset + count).clamp(0, controller.text.length);
    _updateCursorOrExtendSelection(controller, newOffset);
  }

  void _moveBackward(TextEditingController controller, int count) {
    final offset = controller.selection.baseOffset;
    final newOffset = (offset - count).clamp(0, controller.text.length);
    _updateCursorOrExtendSelection(controller, newOffset);
  }

  void _moveDown(TextEditingController controller, int count) {
    final text = controller.text;
    final offset = controller.selection.baseOffset;
    final currentPos = _getLineAndColumn(text, offset);

    final lines = text.split('\n');
    final targetLine = (currentPos.line + count).clamp(0, lines.length - 1);
    final targetColumn = currentPos.column.clamp(0, lines[targetLine].length);

    final newOffset = _getOffsetFromLinePosition(text, targetLine, targetColumn);
    _updateCursorOrExtendSelection(controller, newOffset);
  }

  void _moveUp(TextEditingController controller, int count) {
    final text = controller.text;
    final offset = controller.selection.baseOffset;
    final currentPos = _getLineAndColumn(text, offset);

    final lines = text.split('\n');
    final targetLine = (currentPos.line - count).clamp(0, lines.length - 1);
    final targetColumn = currentPos.column.clamp(0, lines[targetLine].length);

    final newOffset = _getOffsetFromLinePosition(text, targetLine, targetColumn);
    _updateCursorOrExtendSelection(controller, newOffset);
  }

  void _moveToLineStart(TextEditingController controller) {
    final text = controller.text;
    final offset = controller.selection.baseOffset;
    final lineStart = text.lastIndexOf('\n', offset - 1) + 1;
    _updateCursorOrExtendSelection(controller, lineStart);
  }

  void _moveToLineEnd(TextEditingController controller) {
    final text = controller.text;
    final offset = controller.selection.baseOffset;
    final lineEnd = text.indexOf('\n', offset);
    final targetOffset = lineEnd == -1 ? text.length : lineEnd;
    _updateCursorOrExtendSelection(controller, targetOffset);
  }

  void _moveForwardWord(TextEditingController controller, int count) {
    final text = controller.text;
    int offset = controller.selection.baseOffset;

    for (int i = 0; i < count; i++) {
      offset = _findNextWordStart(text, offset);
    }

    _updateCursorOrExtendSelection(controller, offset);
  }

  void _moveBackwardWord(TextEditingController controller, int count) {
    final text = controller.text;
    int offset = controller.selection.baseOffset;

    for (int i = 0; i < count; i++) {
      offset = _findPreviousWordStart(text, offset);
    }

    _updateCursorOrExtendSelection(controller, offset);
  }

  void _moveToBufferStart(TextEditingController controller) {
    _updateCursorOrExtendSelection(controller, 0);
  }

  void _moveToBufferEnd(TextEditingController controller) {
    _updateCursorOrExtendSelection(controller, controller.text.length);
  }

  // Delete operations
  void _deleteForward(TextEditingController controller, int count) {
    final text = controller.text;
    final offset = controller.selection.baseOffset;
    final endOffset = (offset + count).clamp(0, text.length);

    final newText = text.replaceRange(offset, endOffset, '');
    controller.value = controller.value.copyWith(
      text: newText,
      selection: TextSelection.collapsed(offset: offset),
    );
  }

  void _deleteBackward(TextEditingController controller, int count) {
    final text = controller.text;
    final offset = controller.selection.baseOffset;
    final startOffset = (offset - count).clamp(0, text.length);

    final newText = text.replaceRange(startOffset, offset, '');
    controller.value = controller.value.copyWith(
      text: newText,
      selection: TextSelection.collapsed(offset: startOffset),
    );
  }

  void _deleteWordForward(TextEditingController controller, int count) {
    final text = controller.text;
    int startOffset = controller.selection.baseOffset;
    int endOffset = startOffset;

    for (int i = 0; i < count; i++) {
      endOffset = _findNextWordStart(text, endOffset);
    }

    final deleted = text.substring(startOffset, endOffset);
    _killRing = deleted; // Store in kill ring

    final newText = text.replaceRange(startOffset, endOffset, '');
    controller.value = controller.value.copyWith(
      text: newText,
      selection: TextSelection.collapsed(offset: startOffset),
    );
  }

  void _killToLineEnd(TextEditingController controller) {
    final text = controller.text;
    final offset = controller.selection.baseOffset;
    final lineEnd = text.indexOf('\n', offset);
    final endOffset = lineEnd == -1 ? text.length : lineEnd;

    final killed = text.substring(offset, endOffset);
    _killRing = killed;

    final newText = text.replaceRange(offset, endOffset, '');
    controller.value = controller.value.copyWith(
      text: newText,
      selection: TextSelection.collapsed(offset: offset),
    );

    _service.showFeedback('Killed to line end', CommandFeedbackType.success);
  }

  void _killRegion(TextEditingController controller) {
    if (!_markActive || _markSelection == null) {
      _service.showFeedback('No region selected', CommandFeedbackType.warning);
      return;
    }

    final selection = controller.selection;
    final text = controller.text;
    final start = selection.start;
    final end = selection.end;

    final killed = text.substring(start, end);
    _killRing = killed;

    final newText = text.replaceRange(start, end, '');
    controller.value = controller.value.copyWith(
      text: newText,
      selection: TextSelection.collapsed(offset: start),
    );

    _clearMark();
    _service.showFeedback('Killed region', CommandFeedbackType.success);
  }

  void _killWordBackward(TextEditingController controller) {
    final text = controller.text;
    final endOffset = controller.selection.baseOffset;
    final startOffset = _findPreviousWordStart(text, endOffset);

    final killed = text.substring(startOffset, endOffset);
    _killRing = killed;

    final newText = text.replaceRange(startOffset, endOffset, '');
    controller.value = controller.value.copyWith(
      text: newText,
      selection: TextSelection.collapsed(offset: startOffset),
    );
  }

  // Copy/Paste operations
  void _yank(TextEditingController controller) {
    if (_killRing.isEmpty) {
      _service.showFeedback('Kill ring is empty', CommandFeedbackType.warning);
      return;
    }

    final text = controller.text;
    final offset = controller.selection.baseOffset;
    final newText = text.replaceRange(offset, offset, _killRing);

    controller.value = controller.value.copyWith(
      text: newText,
      selection: TextSelection.collapsed(offset: offset + _killRing.length),
    );

    _service.showFeedback('Yanked', CommandFeedbackType.success);
  }

  void _copyRegion(TextEditingController controller) {
    if (!_markActive || _markSelection == null) {
      _service.showFeedback('No region selected', CommandFeedbackType.warning);
      return;
    }

    final selection = controller.selection;
    final text = controller.text;
    final copied = text.substring(selection.start, selection.end);
    _killRing = copied;

    _clearMark();
    _service.showFeedback('Region copied', CommandFeedbackType.success);
  }

  // Mark operations
  void _setMark(TextEditingController controller) {
    _markActive = true;
    _markSelection = controller.selection;
    _service.showFeedback('Mark set', CommandFeedbackType.success);
  }

  void _clearMark() {
    _markActive = false;
    _markSelection = null;
  }

  // Search operations
  void _searchForward(TextEditingController controller) {
    _lastSearchDirection = 1;
    // Note: In a real implementation, you'd show a search input here
    _service.showFeedback('I-search forward...', CommandFeedbackType.info);
  }

  void _searchBackward(TextEditingController controller) {
    _lastSearchDirection = -1;
    // Note: In a real implementation, you'd show a search input here
    _service.showFeedback('I-search backward...', CommandFeedbackType.info);
  }

  // File operations
  void _saveBuffer(TextEditingController controller) {
    _service.showFeedback('Buffer saved (auto-save active)', CommandFeedbackType.success);
  }

  void _writeFile(TextEditingController controller) {
    _service.showFeedback('Write file (not implemented)', CommandFeedbackType.info);
  }

  void _findFile(TextEditingController controller) {
    _service.showFeedback('Find file (not implemented)', CommandFeedbackType.info);
  }

  // Edit operations
  void _undo(TextEditingController controller) {
    // Note: Flutter's TextEditingController doesn't have built-in undo
    _service.showFeedback('Undo not available', CommandFeedbackType.warning);
  }

  void _selectAll(TextEditingController controller) {
    controller.selection = TextSelection(
      baseOffset: 0,
      extentOffset: controller.text.length,
    );
    _service.showFeedback('Selected all', CommandFeedbackType.success);
  }

  // Helper methods
  void _updateCursorOrExtendSelection(TextEditingController controller, int newOffset) {
    if (_markActive && _markSelection != null) {
      // Extend selection from mark to new position
      controller.selection = TextSelection(
        baseOffset: _markSelection!.baseOffset,
        extentOffset: newOffset,
      );
    } else {
      // Move cursor normally
      controller.selection = TextSelection.collapsed(offset: newOffset);
    }
  }

  int _findNextWordStart(String text, int start) {
    if (start >= text.length) return text.length;

    int pos = start;

    // Skip current word
    while (pos < text.length && _isWordChar(text[pos])) {
      pos++;
    }

    // Skip whitespace
    while (pos < text.length && _isWhitespace(text[pos])) {
      pos++;
    }

    return pos;
  }

  int _findPreviousWordStart(String text, int start) {
    if (start <= 0) return 0;

    int pos = start - 1;

    // Skip whitespace
    while (pos > 0 && _isWhitespace(text[pos])) {
      pos--;
    }

    // Skip word characters to find the start
    while (pos > 0 && _isWordChar(text[pos - 1])) {
      pos--;
    }

    return pos;
  }

  bool _isWordChar(String char) {
    return RegExp(r'[a-zA-Z0-9_]').hasMatch(char);
  }

  bool _isWhitespace(String char) {
    return RegExp(r'\s').hasMatch(char);
  }

  LinePosition _getLineAndColumn(String text, int offset) {
    final beforeCursor = text.substring(0, offset);
    final lines = beforeCursor.split('\n');
    final line = lines.length - 1;
    final column = lines.last.length;
    return LinePosition(line, column);
  }

  int _getOffsetFromLinePosition(String text, int line, int column) {
    final lines = text.split('\n');
    if (line >= lines.length) return text.length;

    int offset = 0;
    for (int i = 0; i < line; i++) {
      offset += lines[i].length + 1; // +1 for newline
    }
    offset += column.clamp(0, lines[line].length);

    return offset.clamp(0, text.length);
  }

  void _clearCommand() {
    _commandBuffer = '';
    _service.clearFeedback();
  }

  List<KeyBindingCommand> getAvailableCommands() {
    return [
      // Navigation
      const KeyBindingCommand(name: 'Forward char', description: 'Move forward one character', category: 'Navigation', keys: ['C-f', '→']),
      const KeyBindingCommand(name: 'Backward char', description: 'Move backward one character', category: 'Navigation', keys: ['C-b', '←']),
      const KeyBindingCommand(name: 'Next line', description: 'Move to next line', category: 'Navigation', keys: ['C-n', '↓']),
      const KeyBindingCommand(name: 'Previous line', description: 'Move to previous line', category: 'Navigation', keys: ['C-p', '↑']),
      const KeyBindingCommand(name: 'Beginning of line', description: 'Move to beginning of line', category: 'Navigation', keys: ['C-a']),
      const KeyBindingCommand(name: 'End of line', description: 'Move to end of line', category: 'Navigation', keys: ['C-e']),
      const KeyBindingCommand(name: 'Forward word', description: 'Move forward one word', category: 'Navigation', keys: ['M-f']),
      const KeyBindingCommand(name: 'Backward word', description: 'Move backward one word', category: 'Navigation', keys: ['M-b']),
      const KeyBindingCommand(name: 'Beginning of buffer', description: 'Move to beginning of document', category: 'Navigation', keys: ['M-<']),
      const KeyBindingCommand(name: 'End of buffer', description: 'Move to end of document', category: 'Navigation', keys: ['M->']),

      // Delete
      const KeyBindingCommand(name: 'Delete char', description: 'Delete character forward', category: 'Delete', keys: ['C-d']),
      const KeyBindingCommand(name: 'Delete backward', description: 'Delete character backward', category: 'Delete', keys: ['Backspace', 'C-h']),
      const KeyBindingCommand(name: 'Kill word', description: 'Kill word forward', category: 'Delete', keys: ['M-d']),
      const KeyBindingCommand(name: 'Kill line', description: 'Kill to end of line', category: 'Delete', keys: ['C-k']),
      const KeyBindingCommand(name: 'Kill region', description: 'Kill selected region', category: 'Delete', keys: ['C-w']),
      const KeyBindingCommand(name: 'Backward kill word', description: 'Kill word backward', category: 'Delete', keys: ['M-Backspace']),

      // Copy/Paste
      const KeyBindingCommand(name: 'Yank', description: 'Paste from kill ring', category: 'Copy/Paste', keys: ['C-y']),
      const KeyBindingCommand(name: 'Kill ring save', description: 'Copy region to kill ring', category: 'Copy/Paste', keys: ['M-w']),

      // Mark/Select
      const KeyBindingCommand(name: 'Set mark', description: 'Set mark at current position', category: 'Select', keys: ['C-Space']),

      // Search
      const KeyBindingCommand(name: 'Incremental search', description: 'Search forward incrementally', category: 'Search', keys: ['C-s']),
      const KeyBindingCommand(name: 'Reverse incremental search', description: 'Search backward incrementally', category: 'Search', keys: ['C-r']),

      // File operations
      const KeyBindingCommand(name: 'Save buffer', description: 'Save current buffer', category: 'File', keys: ['C-x C-s']),
      const KeyBindingCommand(name: 'Write file', description: 'Write buffer to file', category: 'File', keys: ['C-x C-w']),
      const KeyBindingCommand(name: 'Find file', description: 'Open file', category: 'File', keys: ['C-x C-f']),

      // Edit
      const KeyBindingCommand(name: 'Undo', description: 'Undo last operation', category: 'Edit', keys: ['C-/', 'C-x u']),
      const KeyBindingCommand(name: 'Select all', description: 'Select entire buffer', category: 'Edit', keys: ['C-x h']),

      // Other
      const KeyBindingCommand(name: 'Quit', description: 'Cancel current command', category: 'Other', keys: ['C-g']),
    ];
  }

  String getHelpText() {
    return '''Emacs Key Bindings
Navigation: C-f/b, C-n/p, C-a/e, M-f/b, M-</>
Delete: C-d, C-h, M-d, C-k, C-w, M-Backspace
Copy/Paste: C-y, M-w
Mark: C-Space (set mark)
Search: C-s (forward), C-r (backward)
File: C-x C-s (save), C-x C-f (open)
Other: C-g (quit), C-x u (undo)

Note: C- = Ctrl, M- = Alt''';
  }

  void dispose() {
    _commandBuffer = '';
    _markActive = false;
    _markSelection = null;
    _killRing = '';
    _lastSearchPattern = '';
  }
}

class LinePosition {
  final int line;
  final int column;

  const LinePosition(this.line, this.column);
}