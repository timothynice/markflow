import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import '../models/search_result.dart';
import '../services/search_service.dart';

/// Floating search and replace overlay with modern design
class SearchReplaceOverlay extends StatefulWidget {
  /// Callback when search query changes
  final Function(String query, SearchOptions options) onSearch;

  /// Callback when replace current is requested
  final Function(String replacement) onReplaceCurrent;

  /// Callback when replace all is requested
  final Function(String replacement) onReplaceAll;

  /// Callback when navigation to next match is requested
  final VoidCallback onNext;

  /// Callback when navigation to previous match is requested
  final VoidCallback onPrevious;

  /// Callback when the overlay should be closed
  final VoidCallback onClose;

  /// Callback when a specific match is selected (for jump-to functionality)
  final Function(int matchIndex) onJumpToMatch;

  /// Current search result
  final SearchResult searchResult;

  /// Search history
  final List<String> searchHistory;

  /// Whether to show replace functionality
  final bool showReplace;

  /// Initial search query
  final String initialQuery;

  const SearchReplaceOverlay({
    super.key,
    required this.onSearch,
    required this.onReplaceCurrent,
    required this.onReplaceAll,
    required this.onNext,
    required this.onPrevious,
    required this.onClose,
    required this.onJumpToMatch,
    required this.searchResult,
    required this.searchHistory,
    this.showReplace = true,
    this.initialQuery = '',
  });

  @override
  State<SearchReplaceOverlay> createState() => _SearchReplaceOverlayState();
}

class _SearchReplaceOverlayState extends State<SearchReplaceOverlay>
    with TickerProviderStateMixin {
  late final TextEditingController _searchController;
  late final TextEditingController _replaceController;
  late final FocusNode _searchFocusNode;
  late final FocusNode _replaceFocusNode;
  late final AnimationController _animationController;
  late final Animation<double> _slideAnimation;
  late final Animation<double> _fadeAnimation;

  SearchOptions _searchOptions = const SearchOptions();
  bool _replaceExpanded = false;
  bool _showHistory = false;
  Timer? _searchDebounce;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController(text: widget.initialQuery);
    _replaceController = TextEditingController();
    _searchFocusNode = FocusNode();
    _replaceFocusNode = FocusNode();

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    _slideAnimation = Tween<double>(
      begin: -1.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));

    _animationController.forward();

    // Focus search field initially
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _searchFocusNode.requestFocus();
      if (widget.initialQuery.isNotEmpty) {
        _performSearch();
      }
    });

    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.dispose();
    _replaceController.dispose();
    _searchFocusNode.dispose();
    _replaceFocusNode.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 300), () {
      _performSearch();
    });
  }

  void _performSearch() {
    widget.onSearch(_searchController.text, _searchOptions);
  }

  void _toggleCaseSensitive() {
    setState(() {
      _searchOptions = _searchOptions.copyWith(
        caseSensitive: !_searchOptions.caseSensitive,
      );
    });
    _performSearch();
  }

  void _toggleWholeWord() {
    setState(() {
      _searchOptions = _searchOptions.copyWith(
        wholeWord: !_searchOptions.wholeWord,
      );
    });
    _performSearch();
  }

  void _toggleRegex() {
    setState(() {
      _searchOptions = _searchOptions.copyWith(
        useRegex: !_searchOptions.useRegex,
      );
    });
    _performSearch();
  }

  void _close() {
    _animationController.reverse().then((_) {
      widget.onClose();
    });
  }

  Widget _buildSearchField() {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Search input with history dropdown
              Stack(
                children: [
                  ShadInput(
                    controller: _searchController,
                    focusNode: _searchFocusNode,
                    placeholder: 'Search...',
                    prefix: const Padding(
                      padding: EdgeInsets.all(8.0),
                      child: Icon(Icons.search, size: 16),
                    ),
                    suffix: _searchController.text.isNotEmpty
                        ? ShadButton.ghost(
                            onPressed: () {
                              _searchController.clear();
                              _performSearch();
                            },
                            size: ShadButtonSize.icon,
                            icon: const Icon(Icons.clear, size: 16),
                          )
                        : null,
                    keyboardType: TextInputType.text,
                    textInputAction: TextInputAction.search,
                    onSubmitted: (_) => _performSearch(),
                  ),
                  // History dropdown button
                  if (widget.searchHistory.isNotEmpty)
                    Positioned(
                      right: _searchController.text.isNotEmpty ? 40 : 8,
                      top: 8,
                      child: ShadButton.ghost(
                        onPressed: () => setState(() => _showHistory = !_showHistory),
                        size: ShadButtonSize.icon,
                        icon: Icon(
                          _showHistory ? Icons.keyboard_arrow_up : Icons.history,
                          size: 16,
                        ),
                      ),
                    ),
                ],
              ),
              // History dropdown
              if (_showHistory && widget.searchHistory.isNotEmpty) ...[
                const SizedBox(height: 4),
                Container(
                  constraints: const BoxConstraints(maxHeight: 120),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    border: Border.all(
                      color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
                    ),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: SingleChildScrollView(
                    child: Column(
                      children: widget.searchHistory.map((query) {
                        return InkWell(
                          onTap: () {
                            _searchController.text = query;
                            setState(() => _showHistory = false);
                            _performSearch();
                          },
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            child: Row(
                              children: [
                                const Icon(Icons.history, size: 14),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    query,
                                    style: Theme.of(context).textTheme.bodySmall,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ],
              // Error message
              if (widget.searchResult.hasError) ...[
                const SizedBox(height: 4),
                Text(
                  widget.searchResult.error!,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.error,
                    fontSize: 12,
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(width: 8),
        // Navigation buttons
        _buildNavigationControls(),
      ],
    );
  }

  Widget _buildNavigationControls() {
    final hasMatches = widget.searchResult.hasMatches;
    final matchCount = widget.searchResult.matchCount;
    final activeIndex = widget.searchResult.activeMatchIndex;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Match counter
        if (hasMatches)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              '${activeIndex + 1} / $matchCount',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          )
        else if (_searchController.text.isNotEmpty && !widget.searchResult.hasError)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.outline.withOpacity(0.1),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              '0 / 0',
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
          ),
        const SizedBox(width: 8),
        // Previous button
        ShadButton.ghost(
          onPressed: hasMatches ? widget.onPrevious : null,
          size: ShadButtonSize.icon,
          icon: const Icon(Icons.keyboard_arrow_up, size: 16),
        ),
        // Next button
        ShadButton.ghost(
          onPressed: hasMatches ? widget.onNext : null,
          size: ShadButtonSize.icon,
          icon: const Icon(Icons.keyboard_arrow_down, size: 16),
        ),
        const SizedBox(width: 4),
        // Toggle replace
        if (widget.showReplace)
          ShadButton.ghost(
            onPressed: () => setState(() => _replaceExpanded = !_replaceExpanded),
            size: ShadButtonSize.icon,
            icon: Icon(
              _replaceExpanded ? Icons.unfold_less : Icons.unfold_more,
              size: 16,
            ),
          ),
        // Close button
        ShadButton.ghost(
          onPressed: _close,
          size: ShadButtonSize.icon,
          icon: const Icon(Icons.close, size: 16),
        ),
      ],
    );
  }

  Widget _buildReplaceField() {
    return AnimatedSize(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeInOut,
      child: _replaceExpanded
          ? Column(
              children: [
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: ShadInput(
                        controller: _replaceController,
                        focusNode: _replaceFocusNode,
                        placeholder: 'Replace with...',
                        prefix: const Padding(
                          padding: EdgeInsets.all(8.0),
                          child: Icon(Icons.find_replace, size: 16),
                        ),
                        textInputAction: TextInputAction.done,
                        onSubmitted: (_) => _replaceAll(),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Replace current button
                    ShadButton.outline(
                      onPressed: widget.searchResult.hasMatches
                          ? () => widget.onReplaceCurrent(_replaceController.text)
                          : null,
                      size: ShadButtonSize.sm,
                      child: const Text('Replace'),
                    ),
                    const SizedBox(width: 4),
                    // Replace all button
                    ShadButton(
                      onPressed: widget.searchResult.hasMatches
                          ? _replaceAll
                          : null,
                      size: ShadButtonSize.sm,
                      child: const Text('All'),
                    ),
                  ],
                ),
              ],
            )
          : const SizedBox.shrink(),
    );
  }

  void _replaceAll() {
    if (!widget.searchResult.hasMatches) return;
    widget.onReplaceAll(_replaceController.text);
  }

  Widget _buildSearchOptions() {
    return Wrap(
      spacing: 8,
      children: [
        // Case sensitive
        ShadButton.ghost(
          onPressed: _toggleCaseSensitive,
          size: ShadButtonSize.sm,
          decoration: ShadButtonDecoration(
            backgroundColor: _searchOptions.caseSensitive
                ? Theme.of(context).colorScheme.primary.withOpacity(0.1)
                : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.match_case,
                size: 14,
                color: _searchOptions.caseSensitive
                    ? Theme.of(context).colorScheme.primary
                    : null,
              ),
              const SizedBox(width: 4),
              Text(
                'Aa',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: _searchOptions.caseSensitive
                      ? Theme.of(context).colorScheme.primary
                      : null,
                ),
              ),
            ],
          ),
        ),
        // Whole word
        ShadButton.ghost(
          onPressed: _toggleWholeWord,
          size: ShadButtonSize.sm,
          decoration: ShadButtonDecoration(
            backgroundColor: _searchOptions.wholeWord
                ? Theme.of(context).colorScheme.primary.withOpacity(0.1)
                : null,
          ),
          child: Icon(
            Icons.crop_free,
            size: 14,
            color: _searchOptions.wholeWord
                ? Theme.of(context).colorScheme.primary
                : null,
          ),
        ),
        // Regex
        ShadButton.ghost(
          onPressed: _toggleRegex,
          size: ShadButtonSize.sm,
          decoration: ShadButtonDecoration(
            backgroundColor: _searchOptions.useRegex
                ? Theme.of(context).colorScheme.primary.withOpacity(0.1)
                : null,
          ),
          child: Text(
            '.*',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              fontFamily: 'monospace',
              color: _searchOptions.useRegex
                  ? Theme.of(context).colorScheme.primary
                  : null,
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 16,
      right: 16,
      child: AnimatedBuilder(
        animation: _animationController,
        builder: (context, child) {
          return Transform.translate(
            offset: Offset(0, _slideAnimation.value * 100),
            child: Opacity(
              opacity: _fadeAnimation.value,
              child: child,
            ),
          );
        },
        child: Material(
          elevation: 8,
          shadowColor: Colors.black26,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            width: 400,
            constraints: const BoxConstraints(maxWidth: 400),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildSearchField(),
                _buildReplaceField(),
                const SizedBox(height: 12),
                _buildSearchOptions(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Mobile-optimized search overlay that appears at the bottom
class MobileSearchOverlay extends StatefulWidget {
  /// Same callbacks as SearchReplaceOverlay
  final Function(String query, SearchOptions options) onSearch;
  final Function(String replacement) onReplaceCurrent;
  final Function(String replacement) onReplaceAll;
  final VoidCallback onNext;
  final VoidCallback onPrevious;
  final VoidCallback onClose;
  final Function(int matchIndex) onJumpToMatch;
  final SearchResult searchResult;
  final List<String> searchHistory;
  final bool showReplace;
  final String initialQuery;

  const MobileSearchOverlay({
    super.key,
    required this.onSearch,
    required this.onReplaceCurrent,
    required this.onReplaceAll,
    required this.onNext,
    required this.onPrevious,
    required this.onClose,
    required this.onJumpToMatch,
    required this.searchResult,
    required this.searchHistory,
    this.showReplace = true,
    this.initialQuery = '',
  });

  @override
  State<MobileSearchOverlay> createState() => _MobileSearchOverlayState();
}

class _MobileSearchOverlayState extends State<MobileSearchOverlay>
    with TickerProviderStateMixin {
  late final TextEditingController _searchController;
  late final TextEditingController _replaceController;
  late final FocusNode _searchFocusNode;
  late final AnimationController _animationController;
  late final Animation<Offset> _slideAnimation;

  SearchOptions _searchOptions = const SearchOptions();
  bool _replaceMode = false;
  Timer? _searchDebounce;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController(text: widget.initialQuery);
    _replaceController = TextEditingController();
    _searchFocusNode = FocusNode();

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 250),
      vsync: this,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));

    _animationController.forward();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _searchFocusNode.requestFocus();
      if (widget.initialQuery.isNotEmpty) {
        _performSearch();
      }
    });

    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.dispose();
    _replaceController.dispose();
    _searchFocusNode.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 300), () {
      _performSearch();
    });
  }

  void _performSearch() {
    widget.onSearch(_searchController.text, _searchOptions);
  }

  void _close() {
    _animationController.reverse().then((_) {
      widget.onClose();
    });
  }

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: _slideAnimation,
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Handle bar
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 16),
                // Search/Replace toggle
                if (widget.showReplace) ...[
                  ShadButton.outline(
                    onPressed: () => setState(() => _replaceMode = !_replaceMode),
                    child: Text(_replaceMode ? 'Search' : 'Replace'),
                  ),
                  const SizedBox(height: 16),
                ],
                // Search field
                Row(
                  children: [
                    Expanded(
                      child: ShadInput(
                        controller: _searchController,
                        focusNode: _searchFocusNode,
                        placeholder: 'Search...',
                        prefix: const Padding(
                          padding: EdgeInsets.all(8.0),
                          child: Icon(Icons.search, size: 20),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ShadButton.ghost(
                      onPressed: _close,
                      size: ShadButtonSize.icon,
                      icon: const Icon(Icons.close, size: 20),
                    ),
                  ],
                ),
                // Replace field
                if (_replaceMode) ...[
                  const SizedBox(height: 12),
                  ShadInput(
                    controller: _replaceController,
                    placeholder: 'Replace with...',
                    prefix: const Padding(
                      padding: EdgeInsets.all(8.0),
                      child: Icon(Icons.find_replace, size: 20),
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                // Controls
                Row(
                  children: [
                    // Match counter
                    if (widget.searchResult.hasMatches)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '${widget.searchResult.activeMatchIndex + 1} / ${widget.searchResult.matchCount}',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                      )
                    else
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.outline.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '0 / 0',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                          ),
                        ),
                      ),
                    const Spacer(),
                    // Navigation
                    ShadButton.outline(
                      onPressed: widget.searchResult.hasMatches ? widget.onPrevious : null,
                      size: ShadButtonSize.icon,
                      child: const Icon(Icons.keyboard_arrow_up),
                    ),
                    const SizedBox(width: 8),
                    ShadButton.outline(
                      onPressed: widget.searchResult.hasMatches ? widget.onNext : null,
                      size: ShadButtonSize.icon,
                      child: const Icon(Icons.keyboard_arrow_down),
                    ),
                    if (_replaceMode) ...[
                      const SizedBox(width: 8),
                      ShadButton(
                        onPressed: widget.searchResult.hasMatches
                            ? () => widget.onReplaceAll(_replaceController.text)
                            : null,
                        size: ShadButtonSize.sm,
                        child: const Text('Replace All'),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}