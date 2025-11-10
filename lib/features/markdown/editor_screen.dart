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
import 'widgets/markdown_code_builder.dart';
import 'widgets/extended_markdown_viewer.dart';
import 'widgets/table_editor.dart';
import 'widgets/table_creation_dialog.dart';
import 'widgets/outline_navigator.dart';
import 'services/table_service.dart';
import 'services/outline_service.dart';
import 'services/search_service.dart';
import 'models/outline_item.dart';
import 'models/search_result.dart';
import 'widgets/search_replace_overlay.dart';
import 'widgets/auto_complete_overlay.dart';
import 'services/auto_complete_service.dart';
import 'models/completion_suggestion.dart';
import 'providers/completion_provider.dart';
import 'providers/header_completion_provider.dart';
import 'providers/list_completion_provider.dart';
import 'providers/link_completion_provider.dart';
import 'providers/code_completion_provider.dart';
import 'providers/table_completion_provider.dart';
import 'providers/misc_completion_provider.dart';
import '../../theme_controller.dart';
import 'services/writing_stats_service.dart';
import 'services/writing_session_service.dart';
import 'widgets/statistics_panel.dart';
import 'widgets/focus_mode_overlay.dart';
import 'widgets/writing_goals_dialog.dart';
import 'models/writing_session.dart';
import 'services/key_binding_service.dart';
import 'widgets/mode_indicator.dart';
import 'widgets/key_binding_help.dart';

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
  final _editorFocusNode = FocusNode();
  final _editorKey = GlobalKey();
  MdDocument? _doc;
  Timer? _debounce;
  Timer? _outlineDebounce;
  final _store = MdLocalStore();
  TabController? _tabController;
  // Enables full-document editing overlay inside the Styled tab
  bool _styledEditMode = false;

  // Table editing state
  bool _tableEditMode = false;
  TableData? _currentTable;
  TableBounds? _currentTableBounds;

  // Outline state
  List<OutlineItem> _outline = [];
  bool _outlineVisible = true;
  int _currentScrollPosition = 0;

  // Search state
  final _searchService = SearchService();
  bool _showSearchOverlay = false;
  String _highlightedText = '';
  List<TextSpan> _highlightedSpans = [];

  // Auto-completion state
  final _autoCompleteService = AutoCompleteService();
  bool _showAutoComplete = false;
  OverlayEntry? _autoCompleteOverlay;

  // Writing statistics and session state
  final _sessionService = WritingSessionService();
  TextStatistics _currentStats = TextStatistics.empty();
  WritingSession? _currentSession;
  List<WritingGoal> _activeGoals = [];
  bool _showStatisticsPanel = false;
  bool _statisticsPanelExpanded = false;
  Timer? _statsUpdateTimer;
  bool _showFocusMode = false;
  FocusModeSettings _focusModeSettings = const FocusModeSettings();

  // Markdown extensions state
  MarkdownExtensionSettings _extensionSettings = const MarkdownExtensionSettings();

  // Key binding state
  late final KeyBindingService _keyBindingService;
  bool _showKeyBindingHelp = false;

  @override
  void initState() {
    super.initState();
    _keyBindingService = KeyBindingService.instance;
    _initializeKeyBindings();
    _initializeAutoComplete();
    _initializeWritingSession();
    _load();
    _controller.addListener(_onChanged);
    _scrollController.addListener(_onScroll);
    // Listen to tab changes to eagerly flush saves when switching views
    // The TabController is provided by DefaultTabController in build();
    // access it in addPostFrameCallback to ensure it's available.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _tabController = DefaultTabController.of(context);
      _tabController?.addListener(_onTabChanged);
    });

    // Listen to search results for highlighting
    _searchService.addListener(_onSearchResultChanged);

    // Listen to auto-completion changes
    _autoCompleteService.addListener(_onAutoCompleteChanged);
  }

  /// Initialize key binding service
  void _initializeKeyBindings() async {
    await _keyBindingService.initialize();

    // Listen for key binding changes
    _keyBindingService.addListener(() {
      if (mounted) {
        setState(() {});
      }
    });
  }

  /// Initialize auto-completion providers
  void _initializeAutoComplete() {
    final providers = <CompletionProvider>[
      HeaderCompletionProvider(),
      ListCompletionProvider(),
      LinkCompletionProvider(),
      CodeCompletionProvider(),
      TableCompletionProvider(),
      MiscCompletionProvider(),
    ];
    _autoCompleteService.initialize(providers);
  }

  /// Initialize writing session service
  void _initializeWritingSession() {
    // Restore any existing session
    _sessionService.restoreSession();

    // Listen to session changes
    _sessionService.sessionStream.listen((session) {
      if (mounted) {
        setState(() {
          _currentSession = session;
        });
      }
    });

    // Listen to goal changes
    _sessionService.goalsStream.listen((goals) {
      if (mounted) {
        setState(() {
          _activeGoals = goals;
        });
      }
    });

    // Start periodic stats updates
    _statsUpdateTimer = Timer.periodic(const Duration(seconds: 2), (_) {
      _updateStatistics();
    });

    // Load initial goals
    _loadActiveGoals();
  }

  Future<void> _load() async {
    final doc = await _store.findById(widget.docId) ?? await _store.load();
    setState(() {
      _doc = doc;
      _controller.text = doc.content;
      _updateOutline();
    });

    // Start writing session for this document
    await _sessionService.startSession(doc.id, doc.content);
    _updateStatistics();
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

    // Debounced outline update
    _outlineDebounce?.cancel();
    _outlineDebounce = Timer(const Duration(milliseconds: 500), () {
      _updateOutline();
    });

    // Trigger auto-completion
    _requestAutoCompletion();

    // Update writing session
    _updateWritingSession();
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
    _searchService.removeListener(_onSearchResultChanged);
    _autoCompleteService.removeListener(_onAutoCompleteChanged);
    _debounce?.cancel();
    _outlineDebounce?.cancel();
    _statsUpdateTimer?.cancel();
    _hideAutoComplete();
    // Ensure latest edits are persisted when leaving the screen
    // Fire-and-forget; no await during dispose
    unawaited(_flushSave());
    // End writing session
    unawaited(_sessionService.endSession());
    _controller.dispose();
    _scrollController.dispose();
    _editorFocusNode.dispose();
    _searchService.dispose();
    _autoCompleteService.dispose();
    _sessionService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isMobile = size.width < 720; // compact layout (affects sizing only)
    final showOutline = !isMobile && !_tableEditMode && !_showStatisticsPanel;
    final showStatsPanel = !isMobile && _showStatisticsPanel && !_tableEditMode;

    // Show focus mode overlay if enabled
    if (_showFocusMode) {
      return FocusModeOverlay(
        controller: _controller,
        focusNode: _editorFocusNode,
        onExit: _exitFocusMode,
        settings: _focusModeSettings,
      );
    }

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        resizeToAvoidBottomInset: true,
        body: Column(
          children: [
            if (widget.showTopNav) _buildNavBarWithOutlineToggle(),
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
              onTableInsert: _insertVisualTable,
              onImage: _insertImage,
              onTaskList: _insertTaskList,
              onFootnote: _insertFootnote,
              onDefinitionList: _insertDefinitionList,
              onHighlight: () => _wrapSelection('==', '=='),
              onStrikethrough: () => _wrapSelection('~~', '~~'),
            ),
            // Content with outline
            Expanded(
              child: Row(
                children: [
                  // Outline sidebar (desktop only)
                  if (showOutline)
                    OutlineNavigator(
                      outline: OutlineService.updateActiveItem(_outline, _currentScrollPosition),
                      onItemTap: _jumpToSection,
                      isVisible: _outlineVisible,
                      onToggleVisibility: _toggleOutline,
                      isCompact: false,
                      currentPosition: _currentScrollPosition,
                    ),
                  // Main content
                  Expanded(
                    child: _tableEditMode ? _buildTableEditor() : TabBarView(
                      // Disable side-to-side swipe to prevent gesture conflicts with vertical scrolling
                      physics: const NeverScrollableScrollPhysics(),
                      children: [
                        _buildEditor(),
                        _buildStyled(),
                      ],
                    ),
                  ),
                  // Statistics panel (desktop only)
                  if (showStatsPanel)
                    StatisticsPanel(
                      statistics: _currentStats,
                      currentSession: _currentSession,
                      activeGoals: _activeGoals,
                      isExpanded: _statisticsPanelExpanded,
                      onToggle: _toggleStatisticsPanelExpanded,
                      onGoalTap: _showGoalsDialog,
                      isMobile: false,
                    ),
                ],
              ),
            ),
          ],
        ),
        // Fixed bottom toggle bar across all platforms
        bottomNavigationBar: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Mode indicator as status bar
            if (_keyBindingService.isEnabled)
              StatusBarModeIndicator(keyBindingService: _keyBindingService),
            const _BottomViewToggleBar(),
          ],
        ),
      ),
      // Search overlay
      if (_showSearchOverlay) ..._buildSearchOverlay(context, isMobile),
      // Key binding help overlay
      if (_showKeyBindingHelp)
        KeyBindingHelpOverlay(
          keyBindingService: _keyBindingService,
          onClose: () => setState(() => _showKeyBindingHelp = false),
        ),
      // Floating mode indicator for focus mode
      if (_showFocusMode && _keyBindingService.isEnabled)
        FloatingModeIndicator(
          keyBindingService: _keyBindingService,
          alignment: Alignment.topRight,
        ),
    );
  }

  // Outline-related methods
  void _updateOutline() {
    final newOutline = OutlineService.parseOutline(_controller.text);
    setState(() {
      _outline = newOutline;
    });
  }

  void _onScroll() {
    // Update current scroll position for active section highlighting
    if (_scrollController.hasClients) {
      setState(() {
        _currentScrollPosition = _getTextPositionFromScroll();
      });
    }
  }

  int _getTextPositionFromScroll() {
    if (!_scrollController.hasClients) return 0;

    // Calculate approximate text position based on scroll offset
    // This is a simplified approach - a more accurate implementation would
    // calculate based on line heights and text metrics
    final scrollRatio = _scrollController.offset / _scrollController.position.maxScrollExtent;
    return (scrollRatio * _controller.text.length).round();
  }

  void _jumpToSection(OutlineItem item) {
    // Find the text position and scroll to it
    final text = _controller.text;
    final targetPosition = item.position;

    // Calculate approximate scroll position
    // This is simplified - could be enhanced with more precise calculations
    final lines = text.substring(0, targetPosition).split('\n');
    final lineHeight = 25.6; // Approximate line height for the editor font
    final scrollOffset = lines.length * lineHeight;

    _scrollController.animateTo(
      scrollOffset.clamp(0, _scrollController.position.maxScrollExtent),
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _toggleOutline() {
    setState(() {
      _outlineVisible = !_outlineVisible;
    });
  }

  Widget _buildNavBarWithOutlineToggle() {
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
          const SizedBox(width: 16),
          // Search button
          ShadButton.ghost(
            onPressed: _showSearch,
            icon: const Icon(Icons.search, size: 18),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            child: const Text(
              'Search',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          const SizedBox(width: 8),
          // Outline toggle button
          ShadButton.ghost(
            onPressed: _toggleOutline,
            icon: Icon(
              _outlineVisible ? Icons.menu_open : Icons.menu,
              size: 18,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            child: Text(
              'Outline',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: _outlineVisible
                  ? Theme.of(context).colorScheme.primary
                  : null,
              ),
            ),
          ),
          const SizedBox(width: 8),
          // Statistics toggle button
          ShadButton.ghost(
            onPressed: _toggleStatisticsPanel,
            icon: Icon(
              Icons.analytics_outlined,
              size: 18,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            child: Text(
              'Stats',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: _showStatisticsPanel
                  ? Theme.of(context).colorScheme.primary
                  : null,
              ),
            ),
          ),
          const SizedBox(width: 8),
          // Focus mode button
          ShadButton.ghost(
            onPressed: _enterFocusMode,
            icon: const Icon(
              Icons.center_focus_strong,
              size: 18,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            child: const Text(
              'Focus',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          const SizedBox(width: 8),
          // Key binding help button
          if (_keyBindingService.isEnabled)
            ShadButton.ghost(
              onPressed: () => setState(() => _showKeyBindingHelp = true),
              icon: const Icon(
                Icons.keyboard,
                size: 18,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              child: const Text(
                'Keys',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          const Spacer(),
          // Overflow (kebab) menu
          PopupMenuButton<String>(
            tooltip: 'More',
            icon: const Icon(Icons.more_vert),
            onSelected: (value) async {
              switch (value) {
                case 'copy':
                  _copyToAi();
                  break;
                case 'export':
                  await _exportMenu();
                  break;
                case 'link':
                  _insertLink();
                  break;
                case 'table':
                  _insertTable();
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

  // Content builders remain as separate widgets for TabBarView

  Widget _buildTableEditor() {
    if (_currentTable == null) return Container();

    final theme = Theme.of(context);
    final isMobile = MediaQuery.of(context).size.width < 600;

    return Column(
      children: [
        // Table editor header
        Container(
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHigh,
            border: Border(
              bottom: BorderSide(color: theme.dividerColor),
            ),
          ),
          child: Row(
            children: [
              Icon(LucideIcons.table, size: 20, color: theme.colorScheme.primary),
              SizedBox(width: 8),
              Text(
                'Table Editor',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              Spacer(),
              TextButton.icon(
                onPressed: _exitTableEditMode,
                icon: Icon(Icons.check, size: 18),
                label: Text('Done'),
              ),
            ],
          ),
        ),
        // Table editor content
        Expanded(
          child: Padding(
            padding: EdgeInsets.all(16),
            child: isMobile
              ? MobileTableEditor(
                  table: _currentTable!,
                  onTableChanged: (table) {
                    _currentTable = table;
                    _updateTableInText(table);
                  },
                )
              : TableEditor(
                  table: _currentTable!,
                  onTableChanged: (table) {
                    _currentTable = table;
                    _updateTableInText(table);
                  },
                  maxWidth: MediaQuery.of(context).size.width - 32,
                  maxHeight: MediaQuery.of(context).size.height - 200,
                ),
          ),
        ),
      ],
    );
  }

  Widget _buildEditor() {
    final viewInsets = MediaQuery.of(context).viewInsets;
    // Keep caret above the bottom toggle and keyboard without visually adding extra padding
    final caretSafeBottom = viewInsets.bottom + 72; // 56 bottom bar + 16 comfort
    return KeyboardListener(
      focusNode: _editorFocusNode,
      onKeyEvent: _handleKeyEvent,
      child: Shortcuts(
      shortcuts: <LogicalKeySet, Intent>{
        LogicalKeySet(LogicalKeyboardKey.meta, LogicalKeyboardKey.keyB): const _BoldIntent(),
        LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyB): const _BoldIntent(),
        LogicalKeySet(LogicalKeyboardKey.meta, LogicalKeyboardKey.keyI): const _ItalicIntent(),
        LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyI): const _ItalicIntent(),
        LogicalKeySet(LogicalKeyboardKey.meta, LogicalKeyboardKey.keyK): const _LinkIntent(),
        LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyK): const _LinkIntent(),
        LogicalKeySet(LogicalKeyboardKey.meta, LogicalKeyboardKey.keyT): const _TableEditIntent(),
        LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyT): const _TableEditIntent(),
        LogicalKeySet(LogicalKeyboardKey.meta, LogicalKeyboardKey.backslash): const _ToggleOutlineIntent(),
        LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.backslash): const _ToggleOutlineIntent(),
        LogicalKeySet(LogicalKeyboardKey.meta, LogicalKeyboardKey.digit1): const _JumpToHeadingIntent(1),
        LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.digit1): const _JumpToHeadingIntent(1),
        LogicalKeySet(LogicalKeyboardKey.meta, LogicalKeyboardKey.digit2): const _JumpToHeadingIntent(2),
        LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.digit2): const _JumpToHeadingIntent(2),
        LogicalKeySet(LogicalKeyboardKey.meta, LogicalKeyboardKey.digit3): const _JumpToHeadingIntent(3),
        LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.digit3): const _JumpToHeadingIntent(3),
        LogicalKeySet(LogicalKeyboardKey.meta, LogicalKeyboardKey.keyF): const _SearchIntent(),
        LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyF): const _SearchIntent(),
        LogicalKeySet(LogicalKeyboardKey.f3): const _FindNextIntent(),
        LogicalKeySet(LogicalKeyboardKey.shift, LogicalKeyboardKey.f3): const _FindPreviousIntent(),
        LogicalKeySet(LogicalKeyboardKey.escape): const _EscapeIntent(),
        LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.space): const _TriggerAutoCompleteIntent(),
        LogicalKeySet(LogicalKeyboardKey.meta, LogicalKeyboardKey.space): const _TriggerAutoCompleteIntent(),
        LogicalKeySet(LogicalKeyboardKey.arrowDown): const _AutoCompleteNextIntent(),
        LogicalKeySet(LogicalKeyboardKey.arrowUp): const _AutoCompletePreviousIntent(),
        LogicalKeySet(LogicalKeyboardKey.tab): const _AutoCompleteAcceptIntent(),
        LogicalKeySet(LogicalKeyboardKey.enter): const _AutoCompleteAcceptIntent(),
        LogicalKeySet(LogicalKeyboardKey.meta, LogicalKeyboardKey.enter): const _FocusModeIntent(),
        LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.enter): const _FocusModeIntent(),
        LogicalKeySet(LogicalKeyboardKey.meta, LogicalKeyboardKey.period): const _ToggleStatsIntent(),
        LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.period): const _ToggleStatsIntent(),
      },
      child: Actions(
        actions: <Type, Action<Intent>>{
          _BoldIntent: CallbackAction<_BoldIntent>(onInvoke: (i) => _wrapSelection('**', '**')),
          _ItalicIntent: CallbackAction<_ItalicIntent>(onInvoke: (i) => _wrapSelection('*', '*')),
          _LinkIntent: CallbackAction<_LinkIntent>(onInvoke: (i) => _insertLink()),
          _TableEditIntent: CallbackAction<_TableEditIntent>(onInvoke: (i) => _enterTableEditMode()),
          _ToggleOutlineIntent: CallbackAction<_ToggleOutlineIntent>(onInvoke: (i) => _toggleOutline()),
          _JumpToHeadingIntent: CallbackAction<_JumpToHeadingIntent>(onInvoke: (i) => _jumpToNextHeading(i.level)),
          _SearchIntent: CallbackAction<_SearchIntent>(onInvoke: (i) => _showSearch()),
          _FindNextIntent: CallbackAction<_FindNextIntent>(onInvoke: (i) => _searchService.navigateToNext()),
          _FindPreviousIntent: CallbackAction<_FindPreviousIntent>(onInvoke: (i) => _searchService.navigateToPrevious()),
          _EscapeIntent: CallbackAction<_EscapeIntent>(onInvoke: (i) => _handleEscape()),
          _TriggerAutoCompleteIntent: CallbackAction<_TriggerAutoCompleteIntent>(onInvoke: (i) => _triggerAutoComplete()),
          _AutoCompleteNextIntent: CallbackAction<_AutoCompleteNextIntent>(onInvoke: (i) => _autoCompleteNext()),
          _AutoCompletePreviousIntent: CallbackAction<_AutoCompletePreviousIntent>(onInvoke: (i) => _autoCompletePrevious()),
          _AutoCompleteAcceptIntent: CallbackAction<_AutoCompleteAcceptIntent>(onInvoke: (i) => _acceptAutoComplete()),
          _FocusModeIntent: CallbackAction<_FocusModeIntent>(onInvoke: (i) => _enterFocusMode()),
          _ToggleStatsIntent: CallbackAction<_ToggleStatsIntent>(onInvoke: (i) => _toggleStatisticsPanel()),
        },
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
          child: TextField(
            key: _editorKey,
            controller: _controller,
            focusNode: _editorFocusNode,
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
            onChanged: _onTextChanged,
            // Ensure the caret scrolls above the keyboard and bottom bar
            scrollPadding: EdgeInsets.only(bottom: caretSafeBottom),
            style: GoogleFonts.jetBrainsMono().copyWith(
              fontSize: 16,
              height: 1.6,
              fontWeight: FontWeight.w400,
              fontFamilyFallback: const ['GeistMono', 'monospace'],
            ),
            decoration: const InputDecoration(
              border: InputBorder.none,
              // Collapsed decoration prevents any extra vertical layout that can center content
              isCollapsed: true,
              filled: false,
            ),
          ),
        ),
      ), // Close Actions
      ), // Close Shortcuts
      ), // Close KeyboardListener
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
              child: ExtendedMarkdownViewer(
                data: value.text,
                padding: EdgeInsets.fromLTRB(16, 16, 16, bottomSafe),
                selectable: true,
                softLineBreak: true,
                showCopyButton: true,
                showLanguageLabel: true,
                showLineNumbers: false,
                codeBlockFontSize: 13,
                codeBlockFontFamily: 'GeistMono',
                styleSheet: MarkdownStyleSheet.fromTheme(theme).copyWith(
                  textScaleFactor: 1.0,
                  p: const TextStyle(fontSize: 16, height: 1.6),
                  codeblockPadding: const EdgeInsets.all(0), // We handle padding in EnhancedCodeBlock
                  code: const TextStyle(fontFamily: 'GeistMono', fontSize: 13),
                ),
                onTapLink: (text, href, title) {
                  if (href != null) {
                    Clipboard.setData(ClipboardData(text: href));
                    _toast('Link copied to clipboard');
                  }
                },
                enableFootnotes: _extensionSettings.enableFootnotes,
                enableTaskLists: _extensionSettings.enableTaskLists,
                enableDefinitionLists: _extensionSettings.enableDefinitionLists,
                enableTextExtensions: _extensionSettings.enableTextExtensions,
                enableStrikethrough: _extensionSettings.enableStrikethrough,
                enableInteractiveElements: _extensionSettings.enableInteractiveElements,
                onTaskToggle: _handleTaskToggle,
              ),
            ),

            // Full-document editing overlay for Styled mode
            if (_styledEditMode)
              Positioned.fill(
                child: Stack(
                  children: [
                    // Editor area (no tint / borders)
                    Positioned.fill(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
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
                            border: InputBorder.none,
                            isCollapsed: true,
                            filled: false,
                          ),
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

  void _insertVisualTable(TableData table) {
    final markdown = TableService.tableToMarkdown(table);
    _insertRaw(markdown);
  }

  void _enterTableEditMode() {
    final cursor = _controller.selection.baseOffset;
    final bounds = TableService.findTableAt(_controller.text, cursor);

    if (bounds != null) {
      final table = TableService.parseMarkdownTable(bounds.tableText);
      if (table != null) {
        setState(() {
          _tableEditMode = true;
          _currentTable = table;
          _currentTableBounds = bounds;
        });
      }
    }
  }

  void _exitTableEditMode() {
    setState(() {
      _tableEditMode = false;
      _currentTable = null;
      _currentTableBounds = null;
    });
  }

  void _updateTableInText(TableData table) {
    if (_currentTableBounds == null) return;

    final newText = TableService.replaceTableInText(
      _controller.text,
      _currentTableBounds!,
      table,
    );

    _controller.value = _controller.value.copyWith(
      text: newText,
      selection: TextSelection.collapsed(offset: _controller.selection.baseOffset),
    );

    // Update bounds for the new table
    final newBounds = TableService.findTableAt(newText, _currentTableBounds!.startPosition);
    if (newBounds != null) {
      _currentTableBounds = newBounds;
    }
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

  void _jumpToNextHeading(int level) {
    final flatOutline = OutlineService.flattenOutline(_outline);
    final headingsAtLevel = flatOutline.where((item) => item.level == level).toList();

    if (headingsAtLevel.isEmpty) return;

    // Find next heading after current position
    final currentPos = _controller.selection.baseOffset;
    final nextHeading = headingsAtLevel.firstWhere(
      (heading) => heading.position > currentPos,
      orElse: () => headingsAtLevel.first, // Wrap to first if at end
    );

    _jumpToSection(nextHeading);
  }

  // Search-related methods
  void _onSearchResultChanged() {
    if (mounted) {
      setState(() {
        _updateTextHighlighting();
      });
      _scrollToActiveMatch();
    }
  }

  void _updateTextHighlighting() {
    if (!_searchService.hasActiveSearch) {
      _highlightedSpans = [];
      _highlightedText = '';
      return;
    }

    final result = _searchService.currentResult;
    final text = _controller.text;

    if (text != _highlightedText || result.matches.isEmpty) {
      _highlightedSpans = _createHighlightedSpans(text, result);
      _highlightedText = text;
    }
  }

  List<TextSpan> _createHighlightedSpans(String text, SearchResult result) {
    if (result.matches.isEmpty) {
      return [TextSpan(text: text)];
    }

    final spans = <TextSpan>[];
    int lastEnd = 0;

    final matches = result.matchesWithActiveState;
    for (final match in matches) {
      // Add text before match
      if (match.start > lastEnd) {
        spans.add(TextSpan(text: text.substring(lastEnd, match.start)));
      }

      // Add highlighted match
      spans.add(TextSpan(
        text: match.text,
        style: TextStyle(
          backgroundColor: match.isActive
              ? Theme.of(context).colorScheme.primary.withOpacity(0.4)
              : Theme.of(context).colorScheme.primary.withOpacity(0.2),
          color: match.isActive
              ? Theme.of(context).colorScheme.onPrimary
              : null,
        ),
      ));

      lastEnd = match.end;
    }

    // Add remaining text
    if (lastEnd < text.length) {
      spans.add(TextSpan(text: text.substring(lastEnd)));
    }

    return spans;
  }

  void _scrollToActiveMatch() {
    final activeMatch = _searchService.currentResult.activeMatch;
    if (activeMatch == null || !_scrollController.hasClients) return;

    // Calculate approximate scroll position based on match position
    final text = _controller.text;
    final beforeMatch = text.substring(0, activeMatch.start);
    final lines = beforeMatch.split('\n');
    final lineHeight = 25.6; // Approximate line height
    final scrollOffset = lines.length * lineHeight;

    // Ensure the match is visible with some padding
    final viewportHeight = _scrollController.position.viewportDimension;
    final targetOffset = scrollOffset - (viewportHeight / 2);

    _scrollController.animateTo(
      targetOffset.clamp(0, _scrollController.position.maxScrollExtent),
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _showSearch([String? initialQuery]) {
    setState(() {
      _showSearchOverlay = true;
    });
  }

  void _hideSearch() {
    setState(() {
      _showSearchOverlay = false;
    });
    _searchService.clearSearch();
  }

  /// Handle key events for Vim/Emacs key bindings
  void _handleKeyEvent(KeyEvent event) {
    // Handle F1 for help overlay
    if (event is KeyDownEvent && event.logicalKey == LogicalKeyboardKey.f1) {
      _showKeyBindingHelp = !_showKeyBindingHelp;
      setState(() {});
      return;
    }

    // Let the key binding service handle the event if enabled
    if (_keyBindingService.isEnabled && _keyBindingService.handleKeyEvent(event, _controller)) {
      return; // Event was handled by key binding service
    }

    // For Vim insert mode or when key bindings are disabled, use standard escape handling
    if (event is KeyDownEvent && event.logicalKey == LogicalKeyboardKey.escape) {
      if (_keyBindingService.isVimInsertMode) {
        // Let Vim handler manage the mode switch
        _keyBindingService.handleKeyEvent(event, _controller);
      } else {
        _handleEscape();
      }
    }
  }

  void _handleEscape() {
    if (_showKeyBindingHelp) {
      setState(() => _showKeyBindingHelp = false);
    } else if (_showFocusMode) {
      _exitFocusMode();
    } else if (_showAutoComplete) {
      _hideAutoComplete();
    } else if (_showSearchOverlay) {
      _hideSearch();
    } else if (_styledEditMode) {
      setState(() => _styledEditMode = false);
    } else if (_tableEditMode) {
      _exitTableEditMode();
    } else if (_keyBindingService.isEnabled) {
      _keyBindingService.exitToNormalMode();
    }
  }

  void _onSearch(String query, SearchOptions options) {
    _searchService.searchImmediate(_controller.text, query, options: options);
  }

  void _onReplaceCurrent(String replacement) {
    final newText = _searchService.replaceCurrent(_controller.text, replacement);
    _controller.text = newText;
    _controller.selection = TextSelection.collapsed(
      offset: _controller.selection.baseOffset + replacement.length,
    );
  }

  void _onReplaceAll(String replacement) {
    final newText = _searchService.replaceAll(_controller.text, replacement);
    _controller.text = newText;
  }

  void _onJumpToMatch(int matchIndex) {
    _searchService.navigateToMatch(matchIndex);
  }

  List<Widget> _buildSearchOverlay(BuildContext context, bool isMobile) {
    if (isMobile) {
      return [
        Positioned.fill(
          child: MobileSearchOverlay(
            onSearch: _onSearch,
            onReplaceCurrent: _onReplaceCurrent,
            onReplaceAll: _onReplaceAll,
            onNext: _searchService.navigateToNext,
            onPrevious: _searchService.navigateToPrevious,
            onClose: _hideSearch,
            onJumpToMatch: _onJumpToMatch,
            searchResult: _searchService.currentResult,
            searchHistory: _searchService.searchHistory,
            showReplace: true,
            initialQuery: '',
          ),
        ),
      ];
    } else {
      return [
        SearchReplaceOverlay(
          onSearch: _onSearch,
          onReplaceCurrent: _onReplaceCurrent,
          onReplaceAll: _onReplaceAll,
          onNext: _searchService.navigateToNext,
          onPrevious: _searchService.navigateToPrevious,
          onClose: _hideSearch,
          onJumpToMatch: _onJumpToMatch,
          searchResult: _searchService.currentResult,
          searchHistory: _searchService.searchHistory,
          showReplace: true,
          initialQuery: '',
        ),
      ];
    }
  }

  // Auto-completion methods
  void _onTextChanged(String text) {
    // Check for trigger characters
    final selection = _controller.selection;
    if (selection.isValid && selection.isCollapsed) {
      final cursorPos = selection.baseOffset;
      if (cursorPos > 0) {
        final lastChar = text.substring(cursorPos - 1, cursorPos);
        if (_autoCompleteService.shouldTriggerCompletion(lastChar)) {
          _autoCompleteService.requestCompletionsImmediate(
            text,
            cursorPos,
            triggerCharacter: lastChar,
          );
          return;
        }
      }
    }
  }

  void _requestAutoCompletion() {
    final selection = _controller.selection;
    if (selection.isValid && selection.isCollapsed) {
      _autoCompleteService.requestCompletions(
        _controller.text,
        selection.baseOffset,
      );
    }
  }

  void _onAutoCompleteChanged() {
    if (!mounted) return;

    final result = _autoCompleteService.currentResult;
    if (result.isActive && result.hasSuggestions) {
      _showAutoComplete();
    } else {
      _hideAutoComplete();
    }
  }

  void _showAutoComplete() {
    if (_showAutoComplete) return;

    setState(() {
      _showAutoComplete = true;
    });

    _hideAutoComplete(); // Remove any existing overlay first

    final overlay = Overlay.of(context);
    final position = AutoCompletePositioning.calculatePosition(
      context: context,
      textFieldKey: _editorKey,
      controller: _controller,
      cursorOffset: _controller.selection.baseOffset.toDouble(),
    );

    _autoCompleteOverlay = OverlayEntry(
      builder: (context) => AutoCompleteOverlay(
        completionResult: _autoCompleteService.currentResult,
        position: position,
        onSuggestionSelected: _applySuggestion,
        onSuggestionHovered: _autoCompleteService.selectSuggestion,
        onHide: _hideAutoComplete,
      ),
    );

    overlay.insert(_autoCompleteOverlay!);
  }

  void _hideAutoComplete() {
    if (!_showAutoComplete) return;

    setState(() {
      _showAutoComplete = false;
    });

    _autoCompleteOverlay?.remove();
    _autoCompleteOverlay = null;
  }

  void _applySuggestion(CompletionSuggestion suggestion) {
    final application = _autoCompleteService.applySuggestion(suggestion);
    if (application != null) {
      final text = _controller.text;
      final newText = text.replaceRange(
        application.replaceStart,
        application.replaceStart + application.replaceLength,
        application.insertText,
      );

      _controller.value = _controller.value.copyWith(
        text: newText,
        selection: TextSelection(
          baseOffset: application.newCursorPosition,
          extentOffset: application.newCursorPosition + (application.selectionLength ?? 0),
        ),
      );
    }

    _hideAutoComplete();
  }

  void _triggerAutoComplete() {
    _autoCompleteService.requestCompletionsImmediate(
      _controller.text,
      _controller.selection.baseOffset,
    );
  }

  void _autoCompleteNext() {
    if (_showAutoComplete) {
      _autoCompleteService.selectNext();
      return;
    }
    // Pass through to normal behavior if auto-complete is not active
    return;
  }

  void _autoCompletePrevious() {
    if (_showAutoComplete) {
      _autoCompleteService.selectPrevious();
      return;
    }
    // Pass through to normal behavior if auto-complete is not active
    return;
  }

  void _acceptAutoComplete() {
    if (_showAutoComplete) {
      final suggestion = _autoCompleteService.currentResult.selectedSuggestion;
      if (suggestion != null) {
        _applySuggestion(suggestion);
      }
      return;
    }
    // Pass through to normal behavior if auto-complete is not active
    return;
  }

  // Writing statistics and session methods
  void _updateStatistics() {
    final newStats = WritingStatsService.calculateStats(_controller.text);
    if (mounted) {
      setState(() {
        _currentStats = newStats;
      });
    }
  }

  void _updateWritingSession() {
    final text = _controller.text;
    _sessionService.updateSession(text, additionalCharacters: 1);
  }

  void _loadActiveGoals() async {
    final goals = await _sessionService.getGoals(activeOnly: true);
    if (mounted) {
      setState(() {
        _activeGoals = goals;
      });
    }
  }

  // Focus mode methods
  void _enterFocusMode() {
    setState(() {
      _showFocusMode = true;
    });
  }

  void _exitFocusMode() {
    setState(() {
      _showFocusMode = false;
    });
  }

  // Statistics panel methods
  void _toggleStatisticsPanel() {
    setState(() {
      if (_showStatisticsPanel) {
        _showStatisticsPanel = false;
      } else {
        _showStatisticsPanel = true;
        _outlineVisible = false; // Hide outline when showing stats
      }
    });
  }

  void _toggleStatisticsPanelExpanded() {
    setState(() {
      _statisticsPanelExpanded = !_statisticsPanelExpanded;
    });
  }

  // Goals dialog method
  void _showGoalsDialog() {
    showDialog(
      context: context,
      builder: (context) => WritingGoalsDialog(
        sessionService: _sessionService,
        activeGoals: _activeGoals,
      ),
    );
  }

  // Extension methods
  void _insertTaskList() {
    const taskList = '- [ ] Task 1\n- [ ] Task 2\n- [x] Completed task\n';
    _insertRaw(taskList);
  }

  void _insertFootnote() {
    const footnoteRef = '[^1]';
    const footnoteDef = '\n\n[^1]: Your footnote text here.';
    final sel = _controller.selection;
    final text = _controller.text;
    final newText = sel.textBefore(text) + footnoteRef + sel.textAfter(text) + footnoteDef;
    _controller.value = _controller.value.copyWith(
      text: newText,
      selection: TextSelection.collapsed(offset: sel.baseOffset + footnoteRef.length),
    );
  }

  void _insertDefinitionList() {
    const definitionList = 'Term 1\n: Definition for term 1\n\nTerm 2\n: Definition for term 2\n';
    _insertRaw(definitionList);
  }

  void _handleTaskToggle(String taskId, bool checked) {
    // Find and update the task in the text
    // This is a simplified implementation - in a real app, you'd want to
    // maintain a mapping of task IDs to positions in the text
    final text = _controller.text;
    final lines = text.split('\n');

    for (int i = 0; i < lines.length; i++) {
      final line = lines[i];
      if (line.contains(RegExp(r'^[ ]{0,3}[-*+] \[[xX ]\] '))) {
        if (line.hashCode.toString() == taskId) {
          // Toggle the checkbox
          if (checked) {
            lines[i] = line.replaceFirst(RegExp(r'\[ \]'), '[x]');
          } else {
            lines[i] = line.replaceFirst(RegExp(r'\[[xX]\]'), '[ ]');
          }
          break;
        }
      }
    }

    final newText = lines.join('\n');
    _controller.value = _controller.value.copyWith(
      text: newText,
      selection: _controller.selection,
    );
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

class _TableEditIntent extends Intent {
  const _TableEditIntent();
}

class _ToggleOutlineIntent extends Intent {
  const _ToggleOutlineIntent();
}

class _JumpToHeadingIntent extends Intent {
  final int level;
  const _JumpToHeadingIntent(this.level);
}

class _SearchIntent extends Intent {
  const _SearchIntent();
}

class _FindNextIntent extends Intent {
  const _FindNextIntent();
}

class _FindPreviousIntent extends Intent {
  const _FindPreviousIntent();
}

class _EscapeIntent extends Intent {
  const _EscapeIntent();
}

class _TriggerAutoCompleteIntent extends Intent {
  const _TriggerAutoCompleteIntent();
}

class _AutoCompleteNextIntent extends Intent {
  const _AutoCompleteNextIntent();
}

class _AutoCompletePreviousIntent extends Intent {
  const _AutoCompletePreviousIntent();
}

class _AutoCompleteAcceptIntent extends Intent {
  const _AutoCompleteAcceptIntent();
}

class _FocusModeIntent extends Intent {
  const _FocusModeIntent();
}

class _ToggleStatsIntent extends Intent {
  const _ToggleStatsIntent();
}

// no extra imports required for download
