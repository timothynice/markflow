import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/key_binding_service.dart';

class VimKeyHandler {
  final KeyBindingService _service;

  // State management
  String _commandBuffer = '';
  int _count = 0;
  String? _registerName;
  Map<String, String> _registers = {};
  TextSelection? _visualSelection;
  int _lastSearchDirection = 1; // 1 for forward, -1 for backward
  String _lastSearchPattern = '';

  VimKeyHandler(this._service);

  bool handleKeyEvent(KeyEvent event, TextEditingController controller) {
    if (event is! KeyDownEvent) return false;

    final key = event.logicalKey;
    final isShift = event.logicalKey == LogicalKeyboardKey.shift;
    final isCtrl = HardwareKeyboard.instance.isControlPressed;
    final isAlt = HardwareKeyboard.instance.isAltPressed;

    if (isShift) return false; // Skip isolated shift presses

    final keyLabel = _getKeyLabel(key, isShift, isCtrl, isAlt);

    switch (_service.vimMode) {
      case VimMode.normal:
        return _handleNormalMode(keyLabel, controller);
      case VimMode.insert:
        return _handleInsertMode(keyLabel, controller);
      case VimMode.visual:
      case VimMode.visualLine:
      case VimMode.visualBlock:
        return _handleVisualMode(keyLabel, controller);
    }
  }

  String _getKeyLabel(LogicalKeyboardKey key, bool isShift, bool isCtrl, bool isAlt) {
    String prefix = '';
    if (isCtrl) prefix += 'C-';
    if (isAlt) prefix += 'M-';

    if (key == LogicalKeyboardKey.escape) return 'Escape';
    if (key == LogicalKeyboardKey.enter) return 'Enter';
    if (key == LogicalKeyboardKey.tab) return 'Tab';
    if (key == LogicalKeyboardKey.backspace) return 'Backspace';
    if (key == LogicalKeyboardKey.space) return 'Space';
    if (key == LogicalKeyboardKey.arrowUp) return 'Up';
    if (key == LogicalKeyboardKey.arrowDown) return 'Down';
    if (key == LogicalKeyboardKey.arrowLeft) return 'Left';
    if (key == LogicalKeyboardKey.arrowRight) return 'Right';

    // Handle character keys
    final keyName = key.keyLabel;
    if (keyName.length == 1) {
      return prefix + (isShift ? keyName.toUpperCase() : keyName.toLowerCase());
    }

    return prefix + keyName;
  }

  bool _handleNormalMode(String key, TextEditingController controller) {
    // Handle escape to clear command buffer
    if (key == 'Escape') {
      _clearCommand();
      return true;
    }

    // Handle register selection ("a, "b, etc.)
    if (key == '"' && _commandBuffer.isEmpty) {
      _commandBuffer = key;
      _service.showFeedback('"', CommandFeedbackType.info);
      return true;
    }

    if (_commandBuffer == '"' && key.length == 1) {
      _registerName = key;
      _commandBuffer = '';
      _service.showFeedback('"$key', CommandFeedbackType.info);
      return true;
    }

    // Handle count prefix (1-9)
    if (_commandBuffer.isEmpty && key.length == 1 && '123456789'.contains(key)) {
      _count = int.parse(key);
      _commandBuffer = key;
      _service.showFeedback(key, CommandFeedbackType.info);
      return true;
    }

    if (_commandBuffer.isNotEmpty && key.length == 1 && '0123456789'.contains(key)) {
      _count = _count * 10 + int.parse(key);
      _commandBuffer += key;
      _service.showFeedback(_commandBuffer, CommandFeedbackType.info);
      return true;
    }

    final count = _count > 0 ? _count : 1;

    // Navigation commands
    switch (key) {
      case 'h':
      case 'Left':
        _moveCursor(controller, -count, 0);
        break;
      case 'j':
      case 'Down':
        _moveCursor(controller, 0, count);
        break;
      case 'k':
      case 'Up':
        _moveCursor(controller, 0, -count);
        break;
      case 'l':
      case 'Right':
        _moveCursor(controller, count, 0);
        break;
      case 'w':
        _moveToNextWord(controller, count);
        break;
      case 'e':
        _moveToEndOfWord(controller, count);
        break;
      case 'b':
        _moveToPreviousWord(controller, count);
        break;
      case '0':
        if (_commandBuffer.isEmpty) {
          _moveToLineStart(controller);
        }
        break;
      case '$':
        _moveToLineEnd(controller);
        break;
      case 'g':
        return _handleGCommand(key, controller, count);
      case 'G':
        if (_count > 0) {
          _goToLine(controller, _count);
        } else {
          _goToEndOfDocument(controller);
        }
        break;
      case 'f':
      case 'F':
      case 't':
      case 'T':
        _commandBuffer = key;
        _service.showFeedback(key, CommandFeedbackType.info);
        return true;

      // Mode switches
      case 'i':
        _service.setVimMode(VimMode.insert);
        break;
      case 'I':
        _moveToLineStart(controller);
        _service.setVimMode(VimMode.insert);
        break;
      case 'a':
        _moveCursor(controller, 1, 0);
        _service.setVimMode(VimMode.insert);
        break;
      case 'A':
        _moveToLineEnd(controller);
        _service.setVimMode(VimMode.insert);
        break;
      case 'o':
        _insertNewLineBelow(controller);
        _service.setVimMode(VimMode.insert);
        break;
      case 'O':
        _insertNewLineAbove(controller);
        _service.setVimMode(VimMode.insert);
        break;
      case 's':
        _deleteCharacters(controller, count);
        _service.setVimMode(VimMode.insert);
        break;
      case 'S':
        _deleteLine(controller);
        _service.setVimMode(VimMode.insert);
        break;

      // Delete operations
      case 'x':
        _deleteCharacters(controller, count);
        break;
      case 'X':
        _deleteCharactersBefore(controller, count);
        break;
      case 'd':
        return _handleDeleteCommand(key, controller, count);
      case 'D':
        _deleteToLineEnd(controller);
        break;

      // Change operations
      case 'c':
        return _handleChangeCommand(key, controller, count);
      case 'C':
        _deleteToLineEnd(controller);
        _service.setVimMode(VimMode.insert);
        break;
      case 'r':
        _commandBuffer = key;
        _service.showFeedback('r', CommandFeedbackType.info);
        return true;
      case 'R':
        _service.setVimMode(VimMode.insert); // Replace mode (simplified as insert)
        break;

      // Yank operations
      case 'y':
        return _handleYankCommand(key, controller, count);
      case 'Y':
        _yankLine(controller);
        break;

      // Put operations
      case 'p':
        _putAfter(controller, count);
        break;
      case 'P':
        _putBefore(controller, count);
        break;

      // Undo/Redo
      case 'u':
        // Note: Flutter's TextEditingController doesn't have built-in undo
        _service.showFeedback('Undo not available', CommandFeedbackType.warning);
        break;
      case 'C-r':
        _service.showFeedback('Redo not available', CommandFeedbackType.warning);
        break;

      // Visual mode
      case 'v':
        _service.setVimMode(VimMode.visual);
        _visualSelection = controller.selection;
        break;
      case 'V':
        _service.setVimMode(VimMode.visualLine);
        _visualSelection = _selectCurrentLine(controller);
        break;
      case 'C-v':
        _service.setVimMode(VimMode.visualBlock);
        _visualSelection = controller.selection;
        break;

      // Search
      case '/':
        _startSearch(controller, true);
        return true;
      case '?':
        _startSearch(controller, false);
        return true;
      case 'n':
        _searchNext(controller);
        break;
      case 'N':
        _searchPrevious(controller);
        break;

      default:
        // Handle multi-character commands
        if (_commandBuffer.isNotEmpty) {
          return _handleMultiCharacterCommand(_commandBuffer + key, controller, count);
        }
        return false;
    }

    _clearCommand();
    return true;
  }

  bool _handleInsertMode(String key, TextEditingController controller) {
    switch (key) {
      case 'Escape':
        _service.setVimMode(VimMode.normal);
        // Move cursor back one position (standard Vim behavior)
        if (controller.selection.baseOffset > 0) {
          _moveCursor(controller, -1, 0);
        }
        return true;
      case 'C-w':
        _deleteWordBefore(controller);
        return true;
      case 'C-u':
        _deleteToLineStart(controller);
        return true;
      default:
        return false; // Let normal text input handling take over
    }
  }

  bool _handleVisualMode(String key, TextEditingController controller) {
    switch (key) {
      case 'Escape':
        _service.setVimMode(VimMode.normal);
        _visualSelection = null;
        return true;

      // Navigation in visual mode
      case 'h':
      case 'Left':
        _extendSelection(controller, -1, 0);
        break;
      case 'j':
      case 'Down':
        _extendSelection(controller, 0, 1);
        break;
      case 'k':
      case 'Up':
        _extendSelection(controller, 0, -1);
        break;
      case 'l':
      case 'Right':
        _extendSelection(controller, 1, 0);
        break;
      case 'w':
        _extendSelectionToNextWord(controller);
        break;
      case 'e':
        _extendSelectionToEndOfWord(controller);
        break;
      case 'b':
        _extendSelectionToPreviousWord(controller);
        break;
      case '0':
        _extendSelectionToLineStart(controller);
        break;
      case '$':
        _extendSelectionToLineEnd(controller);
        break;

      // Operations on selected text
      case 'd':
      case 'x':
        _deleteSelection(controller);
        _service.setVimMode(VimMode.normal);
        break;
      case 'c':
        _deleteSelection(controller);
        _service.setVimMode(VimMode.insert);
        break;
      case 'y':
        _yankSelection(controller);
        _service.setVimMode(VimMode.normal);
        break;

      default:
        return false;
    }

    return true;
  }

  bool _handleGCommand(String key, TextEditingController controller, int count) {
    if (_commandBuffer == 'g') {
      if (key == 'g') {
        _goToLine(controller, count > 0 ? count : 1);
        _clearCommand();
        return true;
      }
    } else {
      _commandBuffer = 'g';
      _service.showFeedback('g', CommandFeedbackType.info);
      return true;
    }
    return false;
  }

  bool _handleDeleteCommand(String key, TextEditingController controller, int count) {
    if (_commandBuffer == 'd') {
      if (key == 'd') {
        _deleteLine(controller, count);
        _clearCommand();
        return true;
      } else if (key == 'w') {
        _deleteWords(controller, count);
        _clearCommand();
        return true;
      } else if (key == 'e') {
        _deleteToEndOfWord(controller, count);
        _clearCommand();
        return true;
      } else if (key == 'b') {
        _deleteWordsBefore(controller, count);
        _clearCommand();
        return true;
      } else if (key == '$') {
        _deleteToLineEnd(controller);
        _clearCommand();
        return true;
      } else if (key == '0') {
        _deleteToLineStart(controller);
        _clearCommand();
        return true;
      }
    } else {
      _commandBuffer = 'd';
      _service.showFeedback('d', CommandFeedbackType.info);
      return true;
    }
    return false;
  }

  bool _handleChangeCommand(String key, TextEditingController controller, int count) {
    if (_commandBuffer == 'c') {
      if (key == 'c') {
        _deleteLine(controller, count);
        _service.setVimMode(VimMode.insert);
        _clearCommand();
        return true;
      } else if (key == 'w') {
        _deleteWords(controller, count);
        _service.setVimMode(VimMode.insert);
        _clearCommand();
        return true;
      } else if (key == 'e') {
        _deleteToEndOfWord(controller, count);
        _service.setVimMode(VimMode.insert);
        _clearCommand();
        return true;
      } else if (key == 'b') {
        _deleteWordsBefore(controller, count);
        _service.setVimMode(VimMode.insert);
        _clearCommand();
        return true;
      } else if (key == '$') {
        _deleteToLineEnd(controller);
        _service.setVimMode(VimMode.insert);
        _clearCommand();
        return true;
      } else if (key == '0') {
        _deleteToLineStart(controller);
        _service.setVimMode(VimMode.insert);
        _clearCommand();
        return true;
      }
    } else {
      _commandBuffer = 'c';
      _service.showFeedback('c', CommandFeedbackType.info);
      return true;
    }
    return false;
  }

  bool _handleYankCommand(String key, TextEditingController controller, int count) {
    if (_commandBuffer == 'y') {
      if (key == 'y') {
        _yankLine(controller, count);
        _clearCommand();
        return true;
      } else if (key == 'w') {
        _yankWords(controller, count);
        _clearCommand();
        return true;
      } else if (key == 'e') {
        _yankToEndOfWord(controller, count);
        _clearCommand();
        return true;
      } else if (key == 'b') {
        _yankWordsBefore(controller, count);
        _clearCommand();
        return true;
      } else if (key == '$') {
        _yankToLineEnd(controller);
        _clearCommand();
        return true;
      } else if (key == '0') {
        _yankToLineStart(controller);
        _clearCommand();
        return true;
      }
    } else {
      _commandBuffer = 'y';
      _service.showFeedback('y', CommandFeedbackType.info);
      return true;
    }
    return false;
  }

  bool _handleMultiCharacterCommand(String command, TextEditingController controller, int count) {
    // Handle f/F/t/T commands
    if (command.startsWith('f') && command.length == 2) {
      _findCharacter(controller, command[1], true, false, count);
      _clearCommand();
      return true;
    }
    if (command.startsWith('F') && command.length == 2) {
      _findCharacter(controller, command[1], false, false, count);
      _clearCommand();
      return true;
    }
    if (command.startsWith('t') && command.length == 2) {
      _findCharacter(controller, command[1], true, true, count);
      _clearCommand();
      return true;
    }
    if (command.startsWith('T') && command.length == 2) {
      _findCharacter(controller, command[1], false, true, count);
      _clearCommand();
      return true;
    }

    // Handle replace command
    if (command.startsWith('r') && command.length == 2) {
      _replaceCharacter(controller, command[1], count);
      _clearCommand();
      return true;
    }

    return false;
  }

  // Movement operations
  void _moveCursor(TextEditingController controller, int charOffset, int lineOffset) {
    final text = controller.text;
    final currentOffset = controller.selection.baseOffset;

    if (lineOffset != 0) {
      final lines = text.split('\n');
      final currentPos = _getLineAndColumn(text, currentOffset);
      final targetLine = (currentPos.line + lineOffset).clamp(0, lines.length - 1);
      final targetColumn = currentPos.column.clamp(0, lines[targetLine].length);

      int newOffset = 0;
      for (int i = 0; i < targetLine; i++) {
        newOffset += lines[i].length + 1; // +1 for newline
      }
      newOffset += targetColumn;

      controller.selection = TextSelection.collapsed(offset: newOffset.clamp(0, text.length));
    } else {
      final newOffset = (currentOffset + charOffset).clamp(0, text.length);
      controller.selection = TextSelection.collapsed(offset: newOffset);
    }
  }

  void _moveToNextWord(TextEditingController controller, int count) {
    final text = controller.text;
    int offset = controller.selection.baseOffset;

    for (int i = 0; i < count; i++) {
      offset = _findNextWordStart(text, offset);
    }

    controller.selection = TextSelection.collapsed(offset: offset.clamp(0, text.length));
  }

  void _moveToEndOfWord(TextEditingController controller, int count) {
    final text = controller.text;
    int offset = controller.selection.baseOffset;

    for (int i = 0; i < count; i++) {
      offset = _findWordEnd(text, offset);
    }

    controller.selection = TextSelection.collapsed(offset: offset.clamp(0, text.length));
  }

  void _moveToPreviousWord(TextEditingController controller, int count) {
    final text = controller.text;
    int offset = controller.selection.baseOffset;

    for (int i = 0; i < count; i++) {
      offset = _findPreviousWordStart(text, offset);
    }

    controller.selection = TextSelection.collapsed(offset: offset.clamp(0, text.length));
  }

  void _moveToLineStart(TextEditingController controller) {
    final text = controller.text;
    final currentOffset = controller.selection.baseOffset;
    final lineStart = text.lastIndexOf('\n', currentOffset - 1) + 1;
    controller.selection = TextSelection.collapsed(offset: lineStart);
  }

  void _moveToLineEnd(TextEditingController controller) {
    final text = controller.text;
    final currentOffset = controller.selection.baseOffset;
    final lineEnd = text.indexOf('\n', currentOffset);
    final targetOffset = lineEnd == -1 ? text.length : lineEnd;
    controller.selection = TextSelection.collapsed(offset: targetOffset);
  }

  void _goToLine(TextEditingController controller, int lineNumber) {
    final text = controller.text;
    final lines = text.split('\n');
    final targetLine = (lineNumber - 1).clamp(0, lines.length - 1);

    int offset = 0;
    for (int i = 0; i < targetLine; i++) {
      offset += lines[i].length + 1;
    }

    controller.selection = TextSelection.collapsed(offset: offset);
  }

  void _goToEndOfDocument(TextEditingController controller) {
    controller.selection = TextSelection.collapsed(offset: controller.text.length);
  }

  // Helper methods for word navigation
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

  int _findWordEnd(String text, int start) {
    if (start >= text.length) return text.length;

    int pos = start;

    // If we're at the beginning of a word, move to its end
    if (pos < text.length && _isWordChar(text[pos])) {
      while (pos < text.length && _isWordChar(text[pos])) {
        pos++;
      }
      return pos - 1;
    }

    // Otherwise, find the next word and move to its end
    pos = _findNextWordStart(text, pos);
    while (pos < text.length && _isWordChar(text[pos])) {
      pos++;
    }

    return pos > 0 ? pos - 1 : 0;
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

  // Delete operations
  void _deleteCharacters(TextEditingController controller, int count) {
    final text = controller.text;
    final offset = controller.selection.baseOffset;
    final endOffset = (offset + count).clamp(0, text.length);

    final newText = text.replaceRange(offset, endOffset, '');
    controller.value = controller.value.copyWith(
      text: newText,
      selection: TextSelection.collapsed(offset: offset),
    );

    // Store in register
    final deleted = text.substring(offset, endOffset);
    _setRegister(_registerName ?? '0', deleted);
  }

  void _deleteCharactersBefore(TextEditingController controller, int count) {
    final text = controller.text;
    final offset = controller.selection.baseOffset;
    final startOffset = (offset - count).clamp(0, text.length);

    final newText = text.replaceRange(startOffset, offset, '');
    controller.value = controller.value.copyWith(
      text: newText,
      selection: TextSelection.collapsed(offset: startOffset),
    );

    // Store in register
    final deleted = text.substring(startOffset, offset);
    _setRegister(_registerName ?? '0', deleted);
  }

  void _deleteLine(TextEditingController controller, [int count = 1]) {
    final text = controller.text;
    final lines = text.split('\n');
    final currentPos = _getLineAndColumn(text, controller.selection.baseOffset);

    final startLine = currentPos.line;
    final endLine = (startLine + count - 1).clamp(0, lines.length - 1);

    final deletedLines = lines.sublist(startLine, endLine + 1);
    lines.removeRange(startLine, endLine + 1);

    final newText = lines.join('\n');
    final newOffset = startLine < lines.length
        ? _getOffsetFromLinePosition(newText, startLine, 0)
        : newText.length;

    controller.value = controller.value.copyWith(
      text: newText,
      selection: TextSelection.collapsed(offset: newOffset),
    );

    // Store in register
    _setRegister(_registerName ?? '0', deletedLines.join('\n') + '\n');
  }

  void _deleteToLineEnd(TextEditingController controller) {
    final text = controller.text;
    final offset = controller.selection.baseOffset;
    final lineEnd = text.indexOf('\n', offset);
    final endOffset = lineEnd == -1 ? text.length : lineEnd;

    final deleted = text.substring(offset, endOffset);
    final newText = text.replaceRange(offset, endOffset, '');

    controller.value = controller.value.copyWith(
      text: newText,
      selection: TextSelection.collapsed(offset: offset),
    );

    _setRegister(_registerName ?? '0', deleted);
  }

  void _deleteToLineStart(TextEditingController controller) {
    final text = controller.text;
    final offset = controller.selection.baseOffset;
    final lineStart = text.lastIndexOf('\n', offset - 1) + 1;

    final deleted = text.substring(lineStart, offset);
    final newText = text.replaceRange(lineStart, offset, '');

    controller.value = controller.value.copyWith(
      text: newText,
      selection: TextSelection.collapsed(offset: lineStart),
    );

    _setRegister(_registerName ?? '0', deleted);
  }

  void _deleteWords(TextEditingController controller, int count) {
    final text = controller.text;
    int startOffset = controller.selection.baseOffset;
    int endOffset = startOffset;

    for (int i = 0; i < count; i++) {
      endOffset = _findNextWordStart(text, endOffset);
    }

    final deleted = text.substring(startOffset, endOffset);
    final newText = text.replaceRange(startOffset, endOffset, '');

    controller.value = controller.value.copyWith(
      text: newText,
      selection: TextSelection.collapsed(offset: startOffset),
    );

    _setRegister(_registerName ?? '0', deleted);
  }

  void _deleteToEndOfWord(TextEditingController controller, int count) {
    final text = controller.text;
    int startOffset = controller.selection.baseOffset;
    int endOffset = startOffset;

    for (int i = 0; i < count; i++) {
      endOffset = _findWordEnd(text, endOffset) + 1;
    }

    final deleted = text.substring(startOffset, endOffset);
    final newText = text.replaceRange(startOffset, endOffset, '');

    controller.value = controller.value.copyWith(
      text: newText,
      selection: TextSelection.collapsed(offset: startOffset),
    );

    _setRegister(_registerName ?? '0', deleted);
  }

  void _deleteWordsBefore(TextEditingController controller, int count) {
    final text = controller.text;
    int endOffset = controller.selection.baseOffset;
    int startOffset = endOffset;

    for (int i = 0; i < count; i++) {
      startOffset = _findPreviousWordStart(text, startOffset);
    }

    final deleted = text.substring(startOffset, endOffset);
    final newText = text.replaceRange(startOffset, endOffset, '');

    controller.value = controller.value.copyWith(
      text: newText,
      selection: TextSelection.collapsed(offset: startOffset),
    );

    _setRegister(_registerName ?? '0', deleted);
  }

  void _deleteWordBefore(TextEditingController controller) {
    final text = controller.text;
    final endOffset = controller.selection.baseOffset;
    final startOffset = _findPreviousWordStart(text, endOffset);

    final deleted = text.substring(startOffset, endOffset);
    final newText = text.replaceRange(startOffset, endOffset, '');

    controller.value = controller.value.copyWith(
      text: newText,
      selection: TextSelection.collapsed(offset: startOffset),
    );

    _setRegister(_registerName ?? '0', deleted);
  }

  // Insert operations
  void _insertNewLineBelow(TextEditingController controller) {
    final text = controller.text;
    final offset = controller.selection.baseOffset;
    final lineEnd = text.indexOf('\n', offset);
    final insertPos = lineEnd == -1 ? text.length : lineEnd;

    final newText = text.replaceRange(insertPos, insertPos, '\n');
    controller.value = controller.value.copyWith(
      text: newText,
      selection: TextSelection.collapsed(offset: insertPos + 1),
    );
  }

  void _insertNewLineAbove(TextEditingController controller) {
    final text = controller.text;
    final offset = controller.selection.baseOffset;
    final lineStart = text.lastIndexOf('\n', offset - 1) + 1;

    final newText = text.replaceRange(lineStart, lineStart, '\n');
    controller.value = controller.value.copyWith(
      text: newText,
      selection: TextSelection.collapsed(offset: lineStart),
    );
  }

  // Yank operations
  void _yankLine(TextEditingController controller, [int count = 1]) {
    final text = controller.text;
    final lines = text.split('\n');
    final currentPos = _getLineAndColumn(text, controller.selection.baseOffset);

    final startLine = currentPos.line;
    final endLine = (startLine + count - 1).clamp(0, lines.length - 1);

    final yankedLines = lines.sublist(startLine, endLine + 1);
    _setRegister(_registerName ?? '0', yankedLines.join('\n') + '\n');

    _service.showFeedback('${yankedLines.length} line(s) yanked', CommandFeedbackType.success);
  }

  void _yankWords(TextEditingController controller, int count) {
    final text = controller.text;
    int startOffset = controller.selection.baseOffset;
    int endOffset = startOffset;

    for (int i = 0; i < count; i++) {
      endOffset = _findNextWordStart(text, endOffset);
    }

    final yanked = text.substring(startOffset, endOffset);
    _setRegister(_registerName ?? '0', yanked);

    _service.showFeedback('Yanked: ${yanked.substring(0, yanked.length.clamp(0, 20))}...', CommandFeedbackType.success);
  }

  void _yankToEndOfWord(TextEditingController controller, int count) {
    final text = controller.text;
    int startOffset = controller.selection.baseOffset;
    int endOffset = startOffset;

    for (int i = 0; i < count; i++) {
      endOffset = _findWordEnd(text, endOffset) + 1;
    }

    final yanked = text.substring(startOffset, endOffset);
    _setRegister(_registerName ?? '0', yanked);

    _service.showFeedback('Yanked: ${yanked.substring(0, yanked.length.clamp(0, 20))}...', CommandFeedbackType.success);
  }

  void _yankWordsBefore(TextEditingController controller, int count) {
    final text = controller.text;
    int endOffset = controller.selection.baseOffset;
    int startOffset = endOffset;

    for (int i = 0; i < count; i++) {
      startOffset = _findPreviousWordStart(text, startOffset);
    }

    final yanked = text.substring(startOffset, endOffset);
    _setRegister(_registerName ?? '0', yanked);

    _service.showFeedback('Yanked: ${yanked.substring(0, yanked.length.clamp(0, 20))}...', CommandFeedbackType.success);
  }

  void _yankToLineEnd(TextEditingController controller) {
    final text = controller.text;
    final offset = controller.selection.baseOffset;
    final lineEnd = text.indexOf('\n', offset);
    final endOffset = lineEnd == -1 ? text.length : lineEnd;

    final yanked = text.substring(offset, endOffset);
    _setRegister(_registerName ?? '0', yanked);

    _service.showFeedback('Yanked to line end', CommandFeedbackType.success);
  }

  void _yankToLineStart(TextEditingController controller) {
    final text = controller.text;
    final offset = controller.selection.baseOffset;
    final lineStart = text.lastIndexOf('\n', offset - 1) + 1;

    final yanked = text.substring(lineStart, offset);
    _setRegister(_registerName ?? '0', yanked);

    _service.showFeedback('Yanked to line start', CommandFeedbackType.success);
  }

  void _yankSelection(TextEditingController controller) {
    final selection = controller.selection;
    if (selection.isValid && !selection.isCollapsed) {
      final yanked = selection.textInside(controller.text);
      _setRegister(_registerName ?? '0', yanked);
      _service.showFeedback('Yanked selection', CommandFeedbackType.success);
    }
  }

  // Put operations
  void _putAfter(TextEditingController controller, int count) {
    final content = _getRegister(_registerName ?? '0');
    if (content.isEmpty) return;

    final text = controller.text;
    final offset = controller.selection.baseOffset;

    String putText = '';
    for (int i = 0; i < count; i++) {
      putText += content;
    }

    final insertPos = content.endsWith('\n') ?
        (text.indexOf('\n', offset) + 1).clamp(0, text.length) :
        offset + 1;

    final newText = text.replaceRange(insertPos, insertPos, putText);
    controller.value = controller.value.copyWith(
      text: newText,
      selection: TextSelection.collapsed(offset: insertPos + putText.length),
    );
  }

  void _putBefore(TextEditingController controller, int count) {
    final content = _getRegister(_registerName ?? '0');
    if (content.isEmpty) return;

    final text = controller.text;
    final offset = controller.selection.baseOffset;

    String putText = '';
    for (int i = 0; i < count; i++) {
      putText += content;
    }

    final insertPos = content.endsWith('\n') ?
        text.lastIndexOf('\n', offset - 1) + 1 :
        offset;

    final newText = text.replaceRange(insertPos, insertPos, putText);
    controller.value = controller.value.copyWith(
      text: newText,
      selection: TextSelection.collapsed(offset: insertPos + putText.length),
    );
  }

  // Visual mode operations
  TextSelection _selectCurrentLine(TextEditingController controller) {
    final text = controller.text;
    final offset = controller.selection.baseOffset;
    final lineStart = text.lastIndexOf('\n', offset - 1) + 1;
    final lineEnd = text.indexOf('\n', offset);
    final endPos = lineEnd == -1 ? text.length : lineEnd + 1;

    return TextSelection(baseOffset: lineStart, extentOffset: endPos);
  }

  void _extendSelection(TextEditingController controller, int charOffset, int lineOffset) {
    final text = controller.text;
    final selection = controller.selection;
    final baseOffset = _visualSelection?.baseOffset ?? selection.baseOffset;

    int newExtent = selection.extentOffset;

    if (lineOffset != 0) {
      final currentPos = _getLineAndColumn(text, newExtent);
      final lines = text.split('\n');
      final targetLine = (currentPos.line + lineOffset).clamp(0, lines.length - 1);
      final targetColumn = currentPos.column.clamp(0, lines[targetLine].length);

      newExtent = _getOffsetFromLinePosition(text, targetLine, targetColumn);
    } else {
      newExtent = (newExtent + charOffset).clamp(0, text.length);
    }

    controller.selection = TextSelection(
      baseOffset: baseOffset,
      extentOffset: newExtent,
    );
  }

  void _extendSelectionToNextWord(TextEditingController controller) {
    final text = controller.text;
    final selection = controller.selection;
    final baseOffset = _visualSelection?.baseOffset ?? selection.baseOffset;
    final newExtent = _findNextWordStart(text, selection.extentOffset);

    controller.selection = TextSelection(
      baseOffset: baseOffset,
      extentOffset: newExtent,
    );
  }

  void _extendSelectionToEndOfWord(TextEditingController controller) {
    final text = controller.text;
    final selection = controller.selection;
    final baseOffset = _visualSelection?.baseOffset ?? selection.baseOffset;
    final newExtent = _findWordEnd(text, selection.extentOffset) + 1;

    controller.selection = TextSelection(
      baseOffset: baseOffset,
      extentOffset: newExtent,
    );
  }

  void _extendSelectionToPreviousWord(TextEditingController controller) {
    final text = controller.text;
    final selection = controller.selection;
    final baseOffset = _visualSelection?.baseOffset ?? selection.baseOffset;
    final newExtent = _findPreviousWordStart(text, selection.extentOffset);

    controller.selection = TextSelection(
      baseOffset: baseOffset,
      extentOffset: newExtent,
    );
  }

  void _extendSelectionToLineStart(TextEditingController controller) {
    final text = controller.text;
    final selection = controller.selection;
    final baseOffset = _visualSelection?.baseOffset ?? selection.baseOffset;
    final newExtent = text.lastIndexOf('\n', selection.extentOffset - 1) + 1;

    controller.selection = TextSelection(
      baseOffset: baseOffset,
      extentOffset: newExtent,
    );
  }

  void _extendSelectionToLineEnd(TextEditingController controller) {
    final text = controller.text;
    final selection = controller.selection;
    final baseOffset = _visualSelection?.baseOffset ?? selection.baseOffset;
    final lineEnd = text.indexOf('\n', selection.extentOffset);
    final newExtent = lineEnd == -1 ? text.length : lineEnd;

    controller.selection = TextSelection(
      baseOffset: baseOffset,
      extentOffset: newExtent,
    );
  }

  void _deleteSelection(TextEditingController controller) {
    final selection = controller.selection;
    if (!selection.isValid || selection.isCollapsed) return;

    final text = controller.text;
    final deleted = selection.textInside(text);
    final newText = text.replaceRange(selection.start, selection.end, '');

    controller.value = controller.value.copyWith(
      text: newText,
      selection: TextSelection.collapsed(offset: selection.start),
    );

    _setRegister(_registerName ?? '0', deleted);
  }

  // Character finding operations
  void _findCharacter(TextEditingController controller, String char, bool forward, bool before, int count) {
    final text = controller.text;
    final startOffset = controller.selection.baseOffset;
    int searchStart = forward ? startOffset + 1 : startOffset - 1;

    for (int i = 0; i < count; i++) {
      final foundIndex = forward
          ? text.indexOf(char, searchStart)
          : text.lastIndexOf(char, searchStart);

      if (foundIndex == -1) {
        _service.showFeedback('Character not found', CommandFeedbackType.warning);
        return;
      }

      searchStart = forward ? foundIndex + 1 : foundIndex - 1;
    }

    int targetOffset = forward
        ? text.indexOf(char, startOffset + 1)
        : text.lastIndexOf(char, startOffset - 1);

    if (before) {
      targetOffset = forward ? targetOffset - 1 : targetOffset + 1;
    }

    controller.selection = TextSelection.collapsed(offset: targetOffset.clamp(0, text.length));
  }

  // Replace operations
  void _replaceCharacter(TextEditingController controller, String newChar, int count) {
    final text = controller.text;
    final offset = controller.selection.baseOffset;

    if (offset + count > text.length) {
      _service.showFeedback('Not enough characters to replace', CommandFeedbackType.warning);
      return;
    }

    final replacement = newChar * count;
    final newText = text.replaceRange(offset, offset + count, replacement);

    controller.value = controller.value.copyWith(
      text: newText,
      selection: TextSelection.collapsed(offset: offset + count - 1),
    );
  }

  // Search operations
  void _startSearch(TextEditingController controller, bool forward) {
    _lastSearchDirection = forward ? 1 : -1;
    // Note: In a real implementation, you'd show a search input dialog here
    _service.showFeedback(forward ? 'Search forward...' : 'Search backward...', CommandFeedbackType.info);
  }

  void _searchNext(TextEditingController controller) {
    if (_lastSearchPattern.isEmpty) {
      _service.showFeedback('No previous search', CommandFeedbackType.warning);
      return;
    }
    // Note: Implement actual search functionality
    _service.showFeedback('Search next (not implemented)', CommandFeedbackType.info);
  }

  void _searchPrevious(TextEditingController controller) {
    if (_lastSearchPattern.isEmpty) {
      _service.showFeedback('No previous search', CommandFeedbackType.warning);
      return;
    }
    // Note: Implement actual search functionality
    _service.showFeedback('Search previous (not implemented)', CommandFeedbackType.info);
  }

  // Register operations
  void _setRegister(String name, String content) {
    _registers[name] = content;
  }

  String _getRegister(String name) {
    return _registers[name] ?? '';
  }

  // Helper methods
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
    _count = 0;
    _registerName = null;
    _service.clearFeedback();
  }

  List<KeyBindingCommand> getAvailableCommands() {
    return [
      // Navigation
      const KeyBindingCommand(name: 'Move left', description: 'Move cursor left', category: 'Navigation', keys: ['h', '←']),
      const KeyBindingCommand(name: 'Move down', description: 'Move cursor down', category: 'Navigation', keys: ['j', '↓']),
      const KeyBindingCommand(name: 'Move up', description: 'Move cursor up', category: 'Navigation', keys: ['k', '↑']),
      const KeyBindingCommand(name: 'Move right', description: 'Move cursor right', category: 'Navigation', keys: ['l', '→']),
      const KeyBindingCommand(name: 'Next word', description: 'Move to next word', category: 'Navigation', keys: ['w']),
      const KeyBindingCommand(name: 'End of word', description: 'Move to end of word', category: 'Navigation', keys: ['e']),
      const KeyBindingCommand(name: 'Previous word', description: 'Move to previous word', category: 'Navigation', keys: ['b']),
      const KeyBindingCommand(name: 'Line start', description: 'Move to line start', category: 'Navigation', keys: ['0']),
      const KeyBindingCommand(name: 'Line end', description: 'Move to line end', category: 'Navigation', keys: ['\$']),
      const KeyBindingCommand(name: 'First line', description: 'Go to first line', category: 'Navigation', keys: ['gg']),
      const KeyBindingCommand(name: 'Last line', description: 'Go to last line', category: 'Navigation', keys: ['G']),

      // Insert mode
      const KeyBindingCommand(name: 'Insert', description: 'Enter insert mode', category: 'Insert', keys: ['i']),
      const KeyBindingCommand(name: 'Insert at line start', description: 'Insert at beginning of line', category: 'Insert', keys: ['I']),
      const KeyBindingCommand(name: 'Append', description: 'Append after cursor', category: 'Insert', keys: ['a']),
      const KeyBindingCommand(name: 'Append at line end', description: 'Append at end of line', category: 'Insert', keys: ['A']),
      const KeyBindingCommand(name: 'Open line below', description: 'Open new line below', category: 'Insert', keys: ['o']),
      const KeyBindingCommand(name: 'Open line above', description: 'Open new line above', category: 'Insert', keys: ['O']),

      // Delete
      const KeyBindingCommand(name: 'Delete character', description: 'Delete character under cursor', category: 'Delete', keys: ['x']),
      const KeyBindingCommand(name: 'Delete line', description: 'Delete current line', category: 'Delete', keys: ['dd']),
      const KeyBindingCommand(name: 'Delete word', description: 'Delete word', category: 'Delete', keys: ['dw']),
      const KeyBindingCommand(name: 'Delete to line end', description: 'Delete to end of line', category: 'Delete', keys: ['D']),

      // Change
      const KeyBindingCommand(name: 'Change line', description: 'Change entire line', category: 'Change', keys: ['cc']),
      const KeyBindingCommand(name: 'Change word', description: 'Change word', category: 'Change', keys: ['cw']),
      const KeyBindingCommand(name: 'Change to line end', description: 'Change to end of line', category: 'Change', keys: ['C']),

      // Copy/Paste
      const KeyBindingCommand(name: 'Yank line', description: 'Copy current line', category: 'Copy', keys: ['yy']),
      const KeyBindingCommand(name: 'Yank word', description: 'Copy word', category: 'Copy', keys: ['yw']),
      const KeyBindingCommand(name: 'Put after', description: 'Paste after cursor', category: 'Paste', keys: ['p']),
      const KeyBindingCommand(name: 'Put before', description: 'Paste before cursor', category: 'Paste', keys: ['P']),

      // Visual mode
      const KeyBindingCommand(name: 'Visual mode', description: 'Enter visual mode', category: 'Visual', keys: ['v']),
      const KeyBindingCommand(name: 'Visual line mode', description: 'Enter visual line mode', category: 'Visual', keys: ['V']),
      const KeyBindingCommand(name: 'Visual block mode', description: 'Enter visual block mode', category: 'Visual', keys: ['Ctrl+v']),
    ];
  }

  String getHelpText() {
    switch (_service.vimMode) {
      case VimMode.normal:
        return '''Vim Normal Mode
Navigation: h/j/k/l, w/e/b, 0/\$, gg/G
Insert: i/I/a/A/o/O
Delete: x/dd/dw/D
Change: cc/cw/C
Copy: yy/yw, Paste: p/P
Visual: v/V/Ctrl+v
Search: //?
Numbers: [count]command''';

      case VimMode.insert:
        return '''Vim Insert Mode
Type normally to insert text
Esc: Return to normal mode
Ctrl+w: Delete word backwards
Ctrl+u: Delete to line start''';

      case VimMode.visual:
      case VimMode.visualLine:
      case VimMode.visualBlock:
        return '''Vim Visual Mode
Navigate to extend selection
d/x: Delete selection
c: Change selection
y: Copy selection
Esc: Return to normal mode''';
    }
  }

  void dispose() {
    _registers.clear();
    _commandBuffer = '';
    _count = 0;
    _registerName = null;
    _visualSelection = null;
  }
}

class LinePosition {
  final int line;
  final int column;

  const LinePosition(this.line, this.column);
}