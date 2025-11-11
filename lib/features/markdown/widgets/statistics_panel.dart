import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../services/writing_stats_service.dart';
import '../models/writing_session.dart';

/// Collapsible panel displaying writing statistics and metrics
class StatisticsPanel extends StatelessWidget {
  final TextStatistics statistics;
  final WritingSession? currentSession;
  final List<WritingGoal> activeGoals;
  final bool isExpanded;
  final VoidCallback? onToggle;
  final VoidCallback? onGoalTap;
  final bool isMobile;

  const StatisticsPanel({
    super.key,
    required this.statistics,
    this.currentSession,
    this.activeGoals = const [],
    this.isExpanded = false,
    this.onToggle,
    this.onGoalTap,
    this.isMobile = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (isMobile) {
      return _buildMobilePanel(context, theme);
    }

    return Container(
      width: isExpanded ? 320 : 280,
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          left: BorderSide(
            color: theme.dividerColor.withValues(alpha: 0.1),
            width: 1,
          ),
        ),
      ),
      child: Column(
        children: [
          _buildHeader(theme),
          if (isExpanded) ...[
            Expanded(child: _buildExpandedContent(theme)),
          ] else ...[
            _buildCompactContent(theme),
          ],
        ],
      ),
    );
  }

  Widget _buildMobilePanel(BuildContext context, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
        border: Border.all(
          color: theme.dividerColor.withValues(alpha: 0.1),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),
          _buildMobileStats(theme),
          if (activeGoals.isNotEmpty) ...[
            const SizedBox(height: 16),
            _buildGoalsSection(theme, compact: true),
          ],
          if (currentSession != null) ...[
            const SizedBox(height: 16),
            _buildSessionStats(theme, compact: true),
          ],
        ],
      ),
    );
  }

  Widget _buildHeader(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: theme.dividerColor.withValues(alpha: 0.1),
          ),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.analytics_outlined,
            size: 18,
            color: theme.colorScheme.onSurface,
          ),
          const SizedBox(width: 8),
          Text(
            'Statistics',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const Spacer(),
          ShadIconButton.ghost(
            onPressed: onToggle,
            icon: Icon(
              isExpanded ? Icons.chevron_left : Icons.chevron_right,
              size: 18,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompactContent(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildQuickStats(theme),
          if (activeGoals.isNotEmpty) ...[
            const SizedBox(height: 16),
            _buildGoalsSection(theme, compact: true),
          ],
        ],
      ),
    );
  }

  Widget _buildExpandedContent(ThemeData theme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildDetailedStats(theme),
          const SizedBox(height: 24),
          _buildMarkdownStats(theme),
          const SizedBox(height: 24),
          _buildComplexityMetrics(theme),
          if (currentSession != null) ...[
            const SizedBox(height: 24),
            _buildSessionStats(theme),
          ],
          if (activeGoals.isNotEmpty) ...[
            const SizedBox(height: 24),
            _buildGoalsSection(theme),
          ],
        ],
      ),
    );
  }

  Widget _buildQuickStats(ThemeData theme) {
    return Column(
      children: [
        _buildStatRow('Words', statistics.wordCount.toString(), theme),
        const SizedBox(height: 8),
        _buildStatRow('Characters', statistics.characterCount.toString(), theme),
        const SizedBox(height: 8),
        _buildStatRow('Reading time', statistics.readingTimeFormatted, theme),
        const SizedBox(height: 8),
        _buildStatRow('Paragraphs', statistics.paragraphCount.toString(), theme),
      ],
    );
  }

  Widget _buildMobileStats(ThemeData theme) {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            'Words',
            statistics.wordCount.toString(),
            Icons.text_fields,
            theme,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            'Reading',
            statistics.readingTimeFormatted,
            Icons.schedule,
            theme,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            'Paragraphs',
            statistics.paragraphCount.toString(),
            Icons.view_headline,
            theme,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            size: 20,
            color: theme.colorScheme.primary,
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailedStats(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Document Stats',
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
            color: theme.colorScheme.primary,
          ),
        ),
        const SizedBox(height: 12),
        _buildStatRow('Words', statistics.wordCount.toString(), theme),
        _buildStatRow('Characters', statistics.characterCount.toString(), theme),
        _buildStatRow('Characters (no spaces)', statistics.characterCountNoSpaces.toString(), theme),
        _buildStatRow('Sentences', statistics.sentenceCount.toString(), theme),
        _buildStatRow('Paragraphs', statistics.paragraphCount.toString(), theme),
        _buildStatRow('Lines', '${statistics.nonEmptyLines}/${statistics.totalLines}', theme),
        _buildStatRow('Reading time', statistics.readingTimeFormatted, theme),
      ],
    );
  }

  Widget _buildMarkdownStats(ThemeData theme) {
    final md = statistics.markdownStats;
    if (md.headingCount == 0 && md.linkCount == 0 && md.codeBlockCount == 0) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Markdown Elements',
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
            color: theme.colorScheme.primary,
          ),
        ),
        const SizedBox(height: 12),
        if (md.headingCount > 0) _buildStatRow('Headings', md.headingCount.toString(), theme),
        if (md.linkCount > 0) _buildStatRow('Links', md.linkCount.toString(), theme),
        if (md.imageCount > 0) _buildStatRow('Images', md.imageCount.toString(), theme),
        if (md.codeBlockCount > 0) _buildStatRow('Code blocks', md.codeBlockCount.toString(), theme),
        if (md.inlineCodeCount > 0) _buildStatRow('Inline code', md.inlineCodeCount.toString(), theme),
        if (md.listItemCount > 0) _buildStatRow('List items', md.listItemCount.toString(), theme),
        if (md.numberedListItemCount > 0) _buildStatRow('Numbered lists', md.numberedListItemCount.toString(), theme),
        if (md.boldCount > 0) _buildStatRow('Bold text', md.boldCount.toString(), theme),
        if (md.italicCount > 0) _buildStatRow('Italic text', md.italicCount.toString(), theme),
      ],
    );
  }

  Widget _buildComplexityMetrics(ThemeData theme) {
    final complexity = statistics.complexityMetrics;
    if (complexity.readingEaseScore == 0) return const SizedBox.shrink();

    final readingDifficulty = WritingStatsService.getReadingDifficulty(complexity.readingEaseScore);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Text Complexity',
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
            color: theme.colorScheme.primary,
          ),
        ),
        const SizedBox(height: 12),
        _buildStatRow('Avg words per sentence', complexity.averageWordsPerSentence.toStringAsFixed(1), theme),
        _buildStatRow('Reading ease', '${complexity.readingEaseScore.toInt()}/100', theme),
        _buildStatRow('Reading difficulty', readingDifficulty, theme),
        _buildStatRow('Grade level', complexity.gradeLevel.toStringAsFixed(1), theme),
      ],
    );
  }

  Widget _buildSessionStats(ThemeData theme, {bool compact = false}) {
    if (currentSession == null) return const SizedBox.shrink();

    final session = currentSession!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Current Session',
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
            color: theme.colorScheme.primary,
          ),
        ),
        const SizedBox(height: 12),
        if (compact) ...[
          Row(
            children: [
              Expanded(child: _buildStatRow('Words added', session.wordsAdded.toString(), theme)),
              const SizedBox(width: 16),
              Expanded(child: _buildStatRow('WPM', session.wordsPerMinute.toStringAsFixed(0), theme)),
            ],
          ),
        ] else ...[
          _buildStatRow('Words added', session.wordsAdded.toString(), theme),
          _buildStatRow('Words per minute', session.wordsPerMinute.toStringAsFixed(1), theme),
          _buildStatRow('Characters per minute', session.charactersPerMinute.toStringAsFixed(0), theme),
          _buildStatRow('Active time', _formatDuration(session.activeDuration), theme),
          _buildStatRow('Total time', _formatDuration(session.totalDuration), theme),
          _buildStatRow('Efficiency', '${(session.efficiency * 100).toStringAsFixed(0)}%', theme),
        ],
      ],
    );
  }

  Widget _buildGoalsSection(ThemeData theme, {bool compact = false}) {
    if (activeGoals.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Goals',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.primary,
              ),
            ),
            const Spacer(),
            if (onGoalTap != null)
              ShadButton.ghost(
                onPressed: onGoalTap,
                child: const Text('Manage'),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              ),
          ],
        ),
        const SizedBox(height: 12),
        ...activeGoals.take(compact ? 2 : 5).map((goal) => _buildGoalItem(goal, theme)),
        if (activeGoals.length > (compact ? 2 : 5)) ...[
          const SizedBox(height: 8),
          Text(
            '+${activeGoals.length - (compact ? 2 : 5)} more',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildGoalItem(WritingGoal goal, ThemeData theme) {
    final progress = goal.calculateProgress(_getCurrentValueForGoal(goal));

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  goal.title,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              Text(
                '${(_getCurrentValueForGoal(goal))}/${goal.targetValue}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          LinearProgressIndicator(
            value: progress,
            backgroundColor: theme.colorScheme.surfaceContainerHighest,
            valueColor: AlwaysStoppedAnimation<Color>(
              progress >= 1.0 ? Colors.green : theme.colorScheme.primary,
            ),
          ),
          if (goal.deadline != null) ...[
            const SizedBox(height: 4),
            Text(
              goal.isDueToday
                  ? 'Due today'
                  : goal.isOverdue
                      ? 'Overdue'
                      : 'Due ${_formatDate(goal.deadline!)}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: goal.isOverdue
                    ? Colors.red
                    : goal.isDueToday
                        ? Colors.orange
                        : theme.colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatRow(String label, String value, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
              ),
            ),
          ),
          Text(
            value,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  int _getCurrentValueForGoal(WritingGoal goal) {
    switch (goal.type) {
      case WritingGoalType.words:
        return statistics.wordCount;
      case WritingGoalType.characters:
        return statistics.characterCount;
      case WritingGoalType.pages:
        return (statistics.wordCount / 250).ceil(); // Assuming 250 words per page
      case WritingGoalType.time:
        return currentSession?.totalDuration.inMinutes ?? 0;
      case WritingGoalType.documents:
        return 1; // This would need to be tracked separately
    }
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;
    final seconds = duration.inSeconds % 60;

    if (hours > 0) {
      return '${hours}h ${minutes}m';
    } else if (minutes > 0) {
      return '${minutes}m ${seconds}s';
    } else {
      return '${seconds}s';
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final dateOnly = DateTime(date.year, date.month, date.day);

    final diff = dateOnly.difference(today).inDays;

    if (diff == 0) return 'today';
    if (diff == 1) return 'tomorrow';
    if (diff > 1 && diff <= 7) return 'in $diff days';

    return '${date.month}/${date.day}';
  }
}