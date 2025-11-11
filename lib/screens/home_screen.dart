import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../widgets/responsive_nav.dart';
import 'package:markflow/widgets/shared/mobile_nav_drawer.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import '../features/markdown/local_store.dart';
import '../features/markdown/models.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _store = MdLocalStore();
  MdDocument? _doc;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final doc = await _store.load();
    if (!mounted) return;
    setState(() {
      _doc = doc;
      _loading = false;
    });
  }

  Future<void> _newDocument() async {
    setState(() => _loading = true);
    final doc = await _store.createNew();
    if (!mounted) return;
    setState(() => _loading = false);
    context.go('/markdown/${doc.id}');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      drawer: const MobileNavDrawer(),
      body: Column(
        children: [
          const ResponsiveNav(),
          Expanded(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 960),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
                  child: _loading
                      ? const Center(child: CircularProgressIndicator())
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Markdown Editor',
                              style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w700),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Distraction-free writing with live preview and local autosave.',
                              style: theme.textTheme.bodyLarge?.copyWith(color: theme.textTheme.bodyLarge?.color?.withValues(alpha: 0.8)),
                            ),
                            const SizedBox(height: 24),
                            _LastDocCard(
                                doc: _doc,
                                onContinue: () {
                                  final id = _doc?.id;
                                  if (id != null) context.go('/markdown/$id');
                                },
                                onNew: _newDocument),
                            const SizedBox(height: 24),
                            const _QuickTips(),
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

class _LastDocCard extends StatelessWidget {
  final MdDocument? doc;
  final VoidCallback onContinue;
  final VoidCallback onNew;

  const _LastDocCard({required this.doc, required this.onContinue, required this.onNew});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final updated = doc?.updatedAt;
    final updatedLabel = updated != null ? _relativeTime(updated) : '—';
    final versions = doc?.versions.length ?? 0;

    return Card(
      elevation: 0,
      color: theme.colorScheme.surface,
      shape: RoundedRectangleBorder(
        side: BorderSide(color: theme.dividerColor.withValues(alpha: 0.12)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            const Icon(Icons.description, size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(doc?.title ?? 'Untitled', style: const TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 4),
                  Text('Last edited $updatedLabel • $versions versions',
                      style: theme.textTheme.bodySmall?.copyWith(color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.7))),
                ],
              ),
            ),
            ShadButton(onPressed: onContinue, child: const Text('Continue writing')),
            const SizedBox(width: 8),
            ShadButton.outline(onPressed: onNew, child: const Text('New document')),
          ],
        ),
      ),
    );
  }
}

class _QuickTips extends StatelessWidget {
  const _QuickTips({super.key});
  @override
  Widget build(BuildContext context) {
    const tips = [
      '⌘/Ctrl + B, I for bold/italic',
      'On mobile, use bottom bar to toggle Preview',
      'Copy to AI to share content',
    ];
    final theme = Theme.of(context);
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: tips
          .map((t) => Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: theme.dividerColor.withValues(alpha: 0.12)),
                ),
                child: Text(t, style: theme.textTheme.bodySmall),
              ))
          .toList(),
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
