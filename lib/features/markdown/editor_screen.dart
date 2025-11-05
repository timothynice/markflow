import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'download_stub.dart'
    if (dart.library.html) 'download_web.dart' as dl;
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';

import 'local_store.dart';
import 'models.dart';
import 'widgets/formatting_toolbar.dart';

class MarkdownEditorScreen extends StatefulWidget {
  final String docId;
  final bool showTopNav;
  const MarkdownEditorScreen({super.key, required this.docId, this.showTopNav = true});

  @override
  State<MarkdownEditorScreen> createState() => _MarkdownEditorScreenState();
}

class _MarkdownEditorScreenState extends State<MarkdownEditorScreen> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  MdDocument? _doc;
  Timer? _debounce;
  final _store = MdLocalStore();
  TabController? _tabController;
  // Enables full-document editing overlay inside the Styled tab
  bool _styledEditMode = false;

  @override
  void initState() {
    super.initState();
    _load();
    _controller.addListener(_onChanged);
    // Listen to tab changes to eagerly flush saves when switching views
    // The TabController is provided by DefaultTabController in build();
    // access it in addPostFrameCallback to ensure it's available.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _tabController = DefaultTabController.of(context);
      _tabController?.addListener(_onTabChanged);
    });
  }

  Future<void> _load() async {
    final doc = await _store.findById(widget.docId) ?? await _store.load();
    setState(() {
      _doc = doc;
      _controller.text = doc.content;
    });
  }

  void _onChanged() {
    // Optimistically update the in-memory doc for instant UI sync
    if (_doc != null) {
      _doc!
        ..content = _controller.text
        ..title = _deriveTitleFromContent(_controller.text)
        ..updatedAt = DateTime.now();
    }

    // Debounced autosave (snappier)
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () async {
      await _flushSave();
    });
  }

  String _deriveTitleFromContent(String content) {
    final lines = content.split('\n');
    for (final raw in lines) {
      var line = raw.trim();
      if (line.isEmpty) continue;
      // Remove common markdown heading and list markers
      line = line.replaceFirst(RegExp(r'^#{1,6}\s*'), '');
      line = line.replaceFirst(RegExp(r'^(>\s*)'), '');
      line = line.replaceFirst(RegExp(r'^(?:[-*+]\s+|\d+\.\s+)'), '');
      if (line.isNotEmpty) return line;
    }
    return 'Untitled';
  }

  @override
  void dispose() {
    _tabController?.removeListener(_onTabChanged);
    _debounce?.cancel();
    // Ensure latest edits are persisted when leaving the screen
    // Fire-and-forget; no await during dispose
    unawaited(_flushSave());
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isMobile = size.width < 720; // compact layout (affects sizing only)
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        resizeToAvoidBottomInset: true,
        body: Column(
          children: [
            if (widget.showTopNav) const ResponsiveNavBar(),
            // Toolbar
            FormattingToolbar(
              onWrapSelection: _wrapSelection,
              onHeading1: () => _applyHeadingLevel(1),
              onHeading2: () => _applyHeadingLevel(2),
              onHeading3: () => _applyHeadingLevel(3),
              onLink: _insertLink,
              onBulletedList: _insertBulletedList,
              onNumberedList: _insertNumberedList,
              onTable: _insertTable,
              onImage: _insertImage,
            ),
            // Content
            Expanded(
              child: TabBarView(
                // Disable side-to-side swipe to prevent gesture conflicts with vertical scrolling
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _buildEditor(),
                  _buildStyled(),
                ],
              ),
            ),
          ],
        ),
        // Fixed bottom toggle bar across all platforms
        bottomNavigationBar: const _BottomViewToggleBar(),
      ),
    );
  }

  // Content builders remain as separate widgets for TabBarView

  Widget _buildEditor() {
    final viewInsets = MediaQuery.of(context).viewInsets;
    // Keep caret above the bottom toggle and keyboard without visually adding extra padding
    final caretSafeBottom = viewInsets.bottom + 72; // 56 bottom bar + 16 comfort
    return Shortcuts(
      shortcuts: <LogicalKeySet, Intent>{
        LogicalKeySet(LogicalKeyboardKey.meta, LogicalKeyboardKey.keyB): const _BoldIntent(),
        LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyB): const _BoldIntent(),
        LogicalKeySet(LogicalKeyboardKey.meta, LogicalKeyboardKey.keyI): const _ItalicIntent(),
        LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyI): const _ItalicIntent(),
        LogicalKeySet(LogicalKeyboardKey.meta, LogicalKeyboardKey.keyK): const _LinkIntent(),
        LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyK): const _LinkIntent(),
      },
      child: Actions(
        actions: <Type, Action<Intent>>{
          _BoldIntent: CallbackAction<_BoldIntent>(onInvoke: (i) => _wrapSelection('**', '**')),
          _ItalicIntent: CallbackAction<_ItalicIntent>(onInvoke: (i) => _wrapSelection('*', '*')),
          _LinkIntent: CallbackAction<_LinkIntent>(onInvoke: (i) => _insertLink()),
        },
        child: TextField(
          controller: _controller,
          scrollController: _scrollController,
          maxLines: null,
          // Make the editor take all available height; scroll when content exceeds
          expands: true,
          // Ensure content anchors to the top when expanded
          textAlignVertical: TextAlignVertical.top,
          textAlign: TextAlign.start,
          keyboardType: TextInputType.multiline,
          textInputAction: TextInputAction.newline,
          autocorrect: false,
          enableSuggestions: false,
          // Ensure the caret scrolls above the keyboard and bottom bar
          scrollPadding: EdgeInsets.only(bottom: caretSafeBottom),
          style: GoogleFonts.jetBrainsMono().copyWith(
            fontSize: 16,
            height: 1.6,
            fontWeight: FontWeight.w400,
            fontFamilyFallback: const ['GeistMono', 'monospace'],
          ),
          decoration: InputDecoration(
            // Keep visual margins consistent without forcing extra bottom padding
            contentPadding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
            border: InputBorder.none,
            // Remove any theme-level fill or borders so the editor blends into the canvas
            filled: false,
          ),
        ),
      ),
    );
  }

  Widget _buildStyled() {
    // Rebuild styled view instantly as the editor text changes
    return ValueListenableBuilder<TextEditingValue>(
      valueListenable: _controller,
      builder: (context, value, _) {
        final viewInsets = MediaQuery.of(context).viewInsets;
        // Ensure the preview list never gets covered by bottom bar or keyboard
        final bottomSafe = 16.0 + viewInsets.bottom;
        final caretSafeBottom = viewInsets.bottom + 72; // 56 bottom bar + 16
        final theme = Theme.of(context);
        return Stack(
          children: [
            // Styled rendering layer
            GestureDetector(
              behavior: HitTestBehavior.deferToChild,
              onLongPress: () {
                setState(() => _styledEditMode = true);
              },
              child: Markdown(
                data: value.text,
                padding: EdgeInsets.fromLTRB(16, 16, 16, bottomSafe),
                selectable: true,
                softLineBreak: true,
                styleSheet: MarkdownStyleSheet.fromTheme(theme).copyWith(
                  textScaleFactor: 1.0,
                  p: const TextStyle(fontSize: 16, height: 1.6),
                  codeblockPadding: const EdgeInsets.all(12),
                  code: const TextStyle(fontFamily: 'GeistMono-Regular', fontSize: 13),
                ),
                onTapLink: (text, href, title) {
                  if (href != null) {
                    Clipboard.setData(ClipboardData(text: href));
                    _toast('Link copied to clipboard');
                  }
                },
              ),
            ),

            // Full-document editing overlay for Styled mode
            if (_styledEditMode)
              Positioned.fill(
                child: Stack(
                  children: [
                    // Editor area (no tint / borders)
                    Positioned.fill(
                      child: TextField(
                        controller: _controller,
                        maxLines: null,
                        expands: true,
                        textAlignVertical: TextAlignVertical.top,
                        textAlign: TextAlign.start,
                        keyboardType: TextInputType.multiline,
                        textInputAction: TextInputAction.newline,
                        // Keep caret visible above keyboard and bottom bar
                        scrollPadding: EdgeInsets.only(bottom: caretSafeBottom),
                        style: const TextStyle(fontSize: 16, height: 1.6),
                        decoration: const InputDecoration(
                          contentPadding: EdgeInsets.fromLTRB(16, 16, 16, 16),
                          border: InputBorder.none,
                          filled: false,
                        ),
                      ),
                    ),
                    // Top-right dismiss control
                    Positioned(
                      right: 8,
                      top: 8 + MediaQuery.of(context).padding.top,
                      child: TextButton.icon(
                        onPressed: () {
                          setState(() => _styledEditMode = false);
                          // Flush immediately when leaving edit overlay
                          unawaited(_flushSave());
                        },
                        icon: Icon(Icons.check, size: 18, color: theme.colorScheme.primary),
                        label: Text(
                          'Done',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        );
      },
    );
  }

  // Formatting helpers
  void _wrapSelection(String before, [String after = '']) {
    final sel = _controller.selection;
    if (!sel.isValid) return;
    final text = _controller.text;
    final selected = sel.textInside(text);
    final newText = sel.textBefore(text) + before + selected + (after.isEmpty ? before : after) + sel.textAfter(text);
    final newPos = sel.baseOffset + before.length + selected.length + (after.isEmpty ? before.length : after.length);
    _controller.value = _controller.value.copyWith(
      text: newText,
      selection: TextSelection.collapsed(offset: newPos),
      composing: TextRange.empty,
    );
  }

  void _toggleHeading() {
    final sel = _controller.selection;
    if (!sel.isValid) return;
    final text = _controller.text;
    final lines = text.split('\n');
    final lineStart = text.lastIndexOf('\n', min(sel.baseOffset, sel.extentOffset));
    final lineIndex = '\n'.allMatches(text.substring(0, lineStart + 1)).length;
    if (lineIndex < 0 || lineIndex >= lines.length) return;
    final line = lines[lineIndex];
    final trimmed = line.trimLeft();
    final prefix = line.substring(0, line.length - trimmed.length);
    String replaced;
    if (trimmed.startsWith('# ')) {
      replaced = prefix + trimmed.substring(2);
    } else {
      replaced = prefix + '# ' + trimmed;
    }
    lines[lineIndex] = replaced;
    _controller.text = lines.join('\n');
  }

  void _applyHeadingLevel(int level) {
    final sel = _controller.selection;
    if (!sel.isValid) return;
    final text = _controller.text;
    final lines = text.split('\n');
    final caret = min(sel.baseOffset, sel.extentOffset);
    final lineStart = text.lastIndexOf('\n', caret);
    final before = text.substring(0, max(0, lineStart + 1));
    final lineIndex = '\n'.allMatches(before).length;
    if (lineIndex < 0 || lineIndex >= lines.length) return;
    final line = lines[lineIndex];
    final trimmed = line.trimLeft();
    final prefix = line.substring(0, line.length - trimmed.length);

    // Remove existing heading hashes
    final withoutHashes = trimmed.replaceFirst(RegExp(r'^#{1,6}\s+'), '');
    String newContent;
    if (trimmed.startsWith('#' * level + ' ')) {
      // toggle off if already at desired level
      newContent = withoutHashes;
    } else {
      newContent = ('#' * level) + ' ' + withoutHashes;
    }
    lines[lineIndex] = prefix + newContent;
    _controller.text = lines.join('\n');
  }

  void _insertLink() async {
    final url = await _prompt('Insert URL');
    if (url == null || url.isEmpty) return;
    final sel = _controller.selection;
    final text = _controller.text;
    final selected = sel.isValid ? sel.textInside(text) : 'link';
    final md = '[$selected]($url)';
    final newText = sel.textBefore(text) + md + sel.textAfter(text);
    _controller.value = _controller.value.copyWith(
      text: newText,
      selection: TextSelection.collapsed(offset: sel.baseOffset + md.length),
    );
  }

  void _insertBulletedList() {
    _insertList(prefix: '- ');
  }

  void _insertNumberedList() {
    _insertList(prefix: '1. ');
  }

  void _insertList({required String prefix}) {
    final sel = _controller.selection;
    final text = _controller.text;
    final selected = sel.isValid ? sel.textInside(text) : '';
    final lines = selected.isEmpty ? [''] : selected.split('\n');
    final md = lines.map((l) => '$prefix$l').join('\n');
    final newText = sel.textBefore(text) + md + sel.textAfter(text);
    _controller.value = _controller.value.copyWith(
      text: newText,
      selection: TextSelection.collapsed(offset: sel.baseOffset + md.length),
    );
  }

  void _insertTable() {
    const table = '| Column A | Column B |\n| --- | --- |\n|  |  |\n|  |  |\n';
    _insertRaw(table);
  }

  void _insertImage() async {
    final url = await _prompt('Image URL');
    if (url == null || url.isEmpty) return;
    _insertRaw('![]($url)');
  }

  void _insertRaw(String insert) {
    final sel = _controller.selection;
    final text = _controller.text;
    final newText = sel.textBefore(text) + insert + sel.textAfter(text);
    _controller.value = _controller.value.copyWith(
      text: newText,
      selection: TextSelection.collapsed(offset: sel.baseOffset + insert.length),
    );
  }

  Future<String?> _prompt(String title) async {
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(title),
          content: TextField(
            controller: controller,
            autofocus: true,
            decoration: const InputDecoration(hintText: 'https://...'),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            FilledButton(onPressed: () => Navigator.pop(context, controller.text.trim()), child: const Text('OK')),
          ],
        );
      },
    );
  }

  Future<void> _exportMenu() async {
    final choice = await showMenu<String>(
      context: context,
      position: const RelativeRect.fromLTRB(1000, 80, 16, 0),
      items: const [
        PopupMenuItem(value: 'md', child: Text('Download .md')),
        PopupMenuItem(value: 'txt', child: Text('Download .txt')),
        PopupMenuDivider(),
        PopupMenuItem(value: 'json', child: Text('Download .json (with versions)')),
      ],
    );
    if (choice == null) return;
    switch (choice) {
      case 'md':
        _download(_controller.text, filename: '${_doc?.title ?? 'document'}.md');
        break;
      case 'txt':
        _download(_controller.text, filename: '${_doc?.title ?? 'document'}.txt');
        break;
      case 'json':
        if (_doc != null) {
          _download(jsonEncode(_doc!.toJson()), filename: '${_doc!.title}.json');
        }
        break;
    }
  }

  void _download(String content, {required String filename}) async {
    final ok = await dl.saveTextFile(filename, content);
    if (ok) {
      _toast('Downloading $filename');
    } else {
      _toast('Export available on web in this build');
    }
  }

  void _copyToAi() {
    final sel = _controller.selection;
    String text;
    if (sel.isValid && !sel.isCollapsed) {
      text = sel.textInside(_controller.text);
    } else {
      text = _controller.text;
    }
    Clipboard.setData(ClipboardData(text: text));
    _toast('Copied selection to clipboard');
  }

  void _toast(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  // Flush any pending changes to storage immediately
  Future<void> _flushSave() async {
    if (_doc == null) return;
    final content = _controller.text;
    final title = _deriveTitleFromContent(content);
    _doc!
      ..content = content
      ..title = title
      ..updatedAt = DateTime.now();
    await _store.save(_doc!);
  }

  void _onTabChanged() {
    if (_tabController == null) return;
    // When switching to Styled view, flush save so the list metadata stays current
    if (_tabController!.index == 1) {
      unawaited(_flushSave());
    }
  }
}

// Bottom toggle bar that fills the width and has large touch targets
class _BottomViewToggleBar extends StatelessWidget {
  const _BottomViewToggleBar();

  @override
  Widget build(BuildContext context) {
    final controller = DefaultTabController.of(context);
    if (controller == null) return const SizedBox.shrink();
    final theme = Theme.of(context);

    return SafeArea(
      top: false,
      child: AnimatedBuilder(
        animation: controller,
        builder: (context, _) {
          final index = controller.index;
          return Container(
            height: 56,
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              border: Border(
                top: BorderSide(
                  color: theme.dividerColor.withValues(alpha: 0.1),
                  width: 1,
                ),
              ),
            ),
            child: Row(
              children: [
                _BottomItem(
                  label: 'Markdown',
                  icon: Icons.code,
                  selected: index == 0,
                  onTap: () => controller.index = 0,
                ),
                _BottomItem(
                  label: 'Styled',
                  icon: Icons.remove_red_eye,
                  selected: index == 1,
                  onTap: () => controller.index = 1,
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _BottomItem extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _BottomItem({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = selected ? theme.colorScheme.primary : theme.colorScheme.onSurface.withValues(alpha: 0.7);
    final bg = selected ? theme.colorScheme.primary.withValues(alpha: 0.06) : Colors.transparent;
    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: Container(
          height: double.infinity,
          color: bg,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 20, color: color),
              const SizedBox(width: 8),
              Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ),
    );
  }
}

// Minimal top bar matching app style without importing full ResponsiveNav
class ResponsiveNavBar extends StatelessWidget {
  const ResponsiveNavBar({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 56,
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).dividerColor.withValues(alpha: 0.1),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          const SizedBox(width: 8),
          InkWell(
            onTap: () {
              // Navigate to Documents list
              context.go('/docs');
            },
            borderRadius: BorderRadius.circular(6),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              child: Row(
                children: const [
                  Icon(Icons.arrow_back, size: 18),
                  SizedBox(width: 6),
                  Text('Documents', style: TextStyle(fontWeight: FontWeight.w600)),
                ],
              ),
            ),
          ),
          const Spacer(),
          // Overflow (kebab) menu
          PopupMenuButton<String>(
            tooltip: 'More',
            icon: const Icon(Icons.more_vert),
            onSelected: (value) async {
              final state = context.findAncestorStateOfType<_MarkdownEditorScreenState>();
              switch (value) {
                case 'copy':
                  state?._copyToAi();
                  break;
                case 'export':
                  await state?._exportMenu();
                  break;
                case 'link':
                  state?._insertLink();
                  break;
                case 'table':
                  state?._insertTable();
                  break;
              }
            },
            itemBuilder: (context) {
              return [
                const PopupMenuItem(value: 'copy', child: Text('Copy')),
                const PopupMenuItem(value: 'export', child: Text('Export')),
                const PopupMenuDivider(),
                const PopupMenuItem(value: 'link', child: Text('Insert link…')),
                const PopupMenuItem(value: 'table', child: Text('Insert table')),
              ];
            },
          ),
          const SizedBox(width: 12),
        ],
      ),
    );
  }
}

// Intents for keyboard shortcuts
class _BoldIntent extends Intent {
  const _BoldIntent();
}

class _ItalicIntent extends Intent {
  const _ItalicIntent();
}

class _LinkIntent extends Intent {
  const _LinkIntent();
}

// no extra imports required for download
