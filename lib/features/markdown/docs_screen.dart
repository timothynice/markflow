import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'local_store.dart';
import 'models.dart';
import '../../widgets/responsive_nav.dart';
import 'editor_screen.dart';
import '../../theme.dart';

class DocumentsScreen extends StatefulWidget {
  const DocumentsScreen({super.key});

  @override
  State<DocumentsScreen> createState() => _DocumentsScreenState();
}

class _DocumentsScreenState extends State<DocumentsScreen> {
  final _store = MdLocalStore();
  List<MdDocument> _docs = [];
  bool _loading = true;
  final TextEditingController _searchCtrl = TextEditingController();
  String _query = '';
  bool _sidebarExpanded = true;
  String? _selectedDocId;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final docs = await _store.list();
    if (!mounted) return;
    setState(() {
      _docs = docs;
      _loading = false;
      // Auto-select first doc on desktop
      if (_selectedDocId == null && docs.isNotEmpty) {
        _selectedDocId = docs.first.id;
      }
    });
  }

  Future<void> _newDoc() async {
    setState(() => _loading = true);
    final doc = await _store.createNew();
    if (!mounted) return;
    setState(() {
      _loading = false;
      _selectedDocId = doc.id;
    });
    // On mobile, navigate to editor
    final width = MediaQuery.of(context).size.width;
    if (width < Breakpoints.lg) {
      context.go('/markdown/${doc.id}');
    }
  }

  void _selectDoc(String id) {
    final width = MediaQuery.of(context).size.width;
    if (width < Breakpoints.lg) {
      // Mobile: navigate to full-screen editor
      context.go('/markdown/$id');
    } else {
      // Desktop: update split view and refresh list to show updated timestamps
      setState(() => _selectedDocId = id);
      _load(); // Refresh doc list to show latest changes
    }
  }

  void _refreshDocList() {
    _load();
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isDesktop = width >= Breakpoints.lg;

    if (isDesktop) {
      return _buildDesktopSplitView(context);
    } else {
      return _buildMobileView(context);
    }
  }

  Widget _buildDesktopSplitView(BuildContext context) {
    final dividerColor = Theme.of(context).dividerColor.withValues(alpha: 0.12);
    final sidebarWidth = _sidebarExpanded ? 320.0 : 48.0;

    return Scaffold(
      body: Column(
        children: [
          const ResponsiveNav(showMenuButton: false),
          Expanded(
            child: Row(
              children: [
                // Left sidebar (collapsible file list)
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: sidebarWidth,
                  decoration: BoxDecoration(
                    border: Border(right: BorderSide(color: dividerColor)),
                  ),
                  child: _buildSidebar(context),
                ),
                // Right editor area
                Expanded(
                  child: _selectedDocId == null
                      ? _buildEmptyState(context)
                      : MarkdownEditorScreen(
                          docId: _selectedDocId!,
                          showTopNav: false,
                          key: ValueKey(_selectedDocId),
                        ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebar(BuildContext context) {
    if (!_sidebarExpanded) {
      return Column(
        children: [
          const SizedBox(height: 12),
          IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () => setState(() => _sidebarExpanded = true),
            tooltip: 'Expand sidebar',
          ),
          const SizedBox(height: 12),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _newDoc,
            tooltip: 'New document',
          ),
        ],
      );
    }

    final dividerColor = Theme.of(context).dividerColor.withValues(alpha: 0.12);
    final subtle = Theme.of(context).textTheme.bodySmall?.color?.withValues(alpha: 0.65);
    final filtered = () {
      if (_query.trim().isEmpty) return _docs;
      final q = _query.toLowerCase();
      return _docs.where((d) => (d.title.toLowerCase().contains(q) || d.content.toLowerCase().contains(q))).toList();
    }();

    return Column(
      children: [
        // Sidebar header
        Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              const Text('Documents', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.close, size: 18),
                onPressed: () => setState(() => _sidebarExpanded = false),
                tooltip: 'Collapse sidebar',
              ),
            ],
          ),
        ),
        Divider(height: 1, color: dividerColor),
        // Search and new button
        Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 36,
                  child: TextField(
                    controller: _searchCtrl,
                    onChanged: (v) => setState(() => _query = v),
                    textInputAction: TextInputAction.search,
                    decoration: InputDecoration(
                      hintText: 'Search',
                      prefixIcon: const Icon(Icons.search, size: 16),
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                height: 36,
                width: 36,
                child: IconButton(
                  onPressed: _newDoc,
                  tooltip: 'New document',
                  icon: const Icon(Icons.add, size: 18),
                  style: IconButton.styleFrom(
                    minimumSize: const Size(36, 36),
                    maximumSize: const Size(36, 36),
                  ),
                ),
              ),
            ],
          ),
        ),
        // Document list
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : filtered.isEmpty
                  ? Center(
                      child: Text(
                        _query.isEmpty ? 'No documents yet' : 'No matches',
                        style: TextStyle(color: subtle, fontSize: 13),
                      ),
                    )
                  : ListView.builder(
                      itemCount: filtered.length,
                      itemBuilder: (context, index) {
                        final doc = filtered[index];
                        final isSelected = doc.id == _selectedDocId;
                        return Material(
                          color: isSelected
                              ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.08)
                              : Colors.transparent,
                          child: InkWell(
                            onTap: () => _selectDoc(doc.id),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                              decoration: BoxDecoration(
                                border: Border(left: BorderSide(
                                  color: isSelected ? Theme.of(context).colorScheme.primary : Colors.transparent,
                                  width: 3,
                                )),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    doc.title.isEmpty ? 'Untitled' : doc.title,
                                    style: TextStyle(
                                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                                      fontSize: 13,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    _relativeTime(doc.updatedAt),
                                    style: TextStyle(color: subtle, fontSize: 11),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
        ),
      ],
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.description_outlined,
            size: 64,
            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3),
          ),
          const SizedBox(height: 16),
          Text(
            'No document selected',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Select a document from the sidebar or create a new one',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileView(BuildContext context) {
    final dividerColor = Theme.of(context).dividerColor.withValues(alpha: 0.12);
    final subtle = Theme.of(context).textTheme.bodySmall?.color?.withValues(alpha: 0.65);

    final filtered = () {
      if (_query.trim().isEmpty) return _docs;
      final q = _query.toLowerCase();
      return _docs.where((d) => (d.title.toLowerCase().contains(q) || d.content.toLowerCase().contains(q))).toList();
    }();

    return Scaffold(
      bottomNavigationBar: Builder(
        builder: (context) {
          final bottomInset = MediaQuery.viewPaddingOf(context).bottom;
          const contentPadding = EdgeInsets.symmetric(horizontal: 16, vertical: 12);
          final height = 1 + contentPadding.vertical + 40 + bottomInset;

          return PreferredSize(
            preferredSize: Size.fromHeight(height),
            child: Material(
              color: Theme.of(context).scaffoldBackgroundColor,
              clipBehavior: Clip.hardEdge,
              child: Padding(
                padding: EdgeInsets.only(bottom: bottomInset),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(height: 1, width: double.infinity, color: dividerColor),
                    Padding(
                      padding: contentPadding,
                      child: const _BottomSearchAndNewRow(),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
      body: Column(
        children: [
          const ResponsiveNav(showMenuButton: false),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 960),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (filtered.isEmpty) ...[
                              const SizedBox(height: 24),
                              Center(
                                child: Text(
                                  _query.isEmpty ? 'No documents yet' : 'No matches',
                                  style: TextStyle(color: subtle),
                                ),
                              ),
                            ],
                            if (filtered.isNotEmpty)
                              Expanded(
                                child: ListView.separated(
                                  itemCount: filtered.length,
                                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                                  itemBuilder: (context, index) {
                                    final doc = filtered[index];
                                    return Card(
                                      elevation: 0,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        side: BorderSide(color: dividerColor),
                                      ),
                                      child: ListTile(
                                        title: Text(
                                          doc.title.isEmpty ? 'Untitled' : doc.title,
                                          style: const TextStyle(fontWeight: FontWeight.w600),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        subtitle: Text(
                                          'Last edited ${_relativeTime(doc.updatedAt)} • ${doc.versions.length} versions',
                                          style: TextStyle(color: subtle),
                                        ),
                                        onTap: () => _selectDoc(doc.id),
                                      ),
                                    );
                                  },
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

// Extracted to keep layout stable and avoid nested Centers that could affect sizing
class _BottomSearchAndNewRow extends StatelessWidget {
  const _BottomSearchAndNewRow();

  @override
  Widget build(BuildContext context) {
    final state = context.findAncestorStateOfType<_DocumentsScreenState>();
    if (state == null) return const SizedBox.shrink();
    return Row(
      children: [
        Expanded(
          child: SizedBox(
            height: 40,
            child: TextField(
              controller: state._searchCtrl,
              onChanged: (v) => state.setState(() => state._query = v),
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                hintText: 'Search documents',
                prefixIcon: const Icon(Icons.search, size: 20),
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        SizedBox(
          height: 40,
          width: 40,
          child: IconButton.filled(
            onPressed: state._newDoc,
            tooltip: 'New document',
            icon: const Icon(Icons.note_add_outlined),
            style: IconButton.styleFrom(
              minimumSize: const Size(40, 40),
              maximumSize: const Size(40, 40),
              shape: const CircleBorder(),
            ),
          ),
        ),
      ],
    );
  }
}

String _relativeTime(DateTime time) {
  final now = DateTime.now();
  final diff = now.difference(time);
  if (diff.inSeconds < 45) return 'just now';
  if (diff.inMinutes < 2) return 'a minute ago';
  if (diff.inMinutes < 45) return '${diff.inMinutes} minutes ago';
  if (diff.inHours < 2) return 'an hour ago';
  if (diff.inHours < 24) return '${diff.inHours} hours ago';
  if (diff.inDays < 2) return 'yesterday';
  if (diff.inDays < 7) return '${diff.inDays} days ago';
  final weeks = (diff.inDays / 7).floor();
  if (weeks < 5) return '$weeks weeks ago';
  final months = (diff.inDays / 30).floor();
  if (months < 12) return '$months months ago';
  final years = (diff.inDays / 365).floor();
  return '$years years ago';
}
