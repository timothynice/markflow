import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../models/writing_session.dart';
import '../services/writing_session_service.dart';

/// Dialog for managing writing goals
class WritingGoalsDialog extends StatefulWidget {
  final WritingSessionService sessionService;
  final List<WritingGoal> activeGoals;

  const WritingGoalsDialog({
    super.key,
    required this.sessionService,
    required this.activeGoals,
  });

  @override
  State<WritingGoalsDialog> createState() => _WritingGoalsDialogState();
}

class _WritingGoalsDialogState extends State<WritingGoalsDialog>
    with TickerProviderStateMixin {
  late TabController _tabController;
  final _titleController = TextEditingController();
  final _targetController = TextEditingController();
  WritingGoalType _selectedType = WritingGoalType.words;
  DateTime? _selectedDeadline;
  bool _isCreating = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _titleController.dispose();
    _targetController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: 600,
        height: 500,
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                const Icon(Icons.flag_outlined),
                const SizedBox(width: 8),
                Text(
                  'Writing Goals',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                ShadIconButton.ghost(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close, size: 18),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Tab bar
            TabBar(
              controller: _tabController,
              tabs: const [
                Tab(text: 'Active Goals'),
                Tab(text: 'Create New'),
              ],
            ),
            const SizedBox(height: 16),

            // Tab content
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildActiveGoalsTab(),
                  _buildCreateGoalTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActiveGoalsTab() {
    return Column(
      children: [
        if (widget.activeGoals.isEmpty) ...[
          Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.flag_outlined,
                    size: 48,
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No active goals',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Create your first writing goal to track progress',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
                    ),
                  ),
                  const SizedBox(height: 16),
                  ShadButton(
                    onPressed: () => _tabController.animateTo(1),
                    child: const Text('Create Goal'),
                  ),
                ],
              ),
            ),
          ),
        ] else ...[
          Expanded(
            child: ListView.builder(
              itemCount: widget.activeGoals.length,
              itemBuilder: (context, index) {
                final goal = widget.activeGoals[index];
                return _buildGoalCard(goal);
              },
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildGoalCard(WritingGoal goal) {
    final progress = goal.calculateProgress(_getCurrentValueForGoal(goal));
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    goal.title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                PopupMenuButton<String>(
                  onSelected: (value) async {
                    switch (value) {
                      case 'complete':
                        await widget.sessionService.completeGoal(goal.id);
                        if (mounted) Navigator.of(context).pop();
                        break;
                      case 'delete':
                        await widget.sessionService.deleteGoal(goal.id);
                        if (mounted) Navigator.of(context).pop();
                        break;
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'complete',
                      child: Row(
                        children: [
                          Icon(Icons.check, size: 16),
                          SizedBox(width: 8),
                          Text('Mark Complete'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete, size: 16),
                          SizedBox(width: 8),
                          Text('Delete'),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  _getIconForGoalType(goal.type),
                  size: 16,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 6),
                Text(
                  _getGoalTypeLabel(goal.type),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  '${_getCurrentValueForGoal(goal)}/${goal.targetValue}',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '(${(progress * 100).toInt()}%)',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            LinearProgressIndicator(
              value: progress,
              backgroundColor: theme.colorScheme.surfaceContainerHighest,
              valueColor: AlwaysStoppedAnimation<Color>(
                progress >= 1.0 ? Colors.green : theme.colorScheme.primary,
              ),
            ),
            if (goal.deadline != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(
                    Icons.schedule,
                    size: 14,
                    color: goal.isOverdue
                        ? Colors.red
                        : goal.isDueToday
                            ? Colors.orange
                            : theme.colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                  const SizedBox(width: 4),
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
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildCreateGoalTab() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Goal title
        Text(
          'Goal Title',
          style: Theme.of(context).textTheme.labelLarge,
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _titleController,
          decoration: const InputDecoration(
            hintText: 'e.g., Write 1000 words daily',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 16),

        // Goal type
        Text(
          'Goal Type',
          style: Theme.of(context).textTheme.labelLarge,
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<WritingGoalType>(
          value: _selectedType,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
          ),
          items: WritingGoalType.values.map((type) {
            return DropdownMenuItem(
              value: type,
              child: Row(
                children: [
                  Icon(_getIconForGoalType(type), size: 16),
                  const SizedBox(width: 8),
                  Text(_getGoalTypeLabel(type)),
                ],
              ),
            );
          }).toList(),
          onChanged: (value) {
            if (value != null) {
              setState(() {
                _selectedType = value;
              });
            }
          },
        ),
        const SizedBox(height: 16),

        // Target value
        Text(
          'Target ${_getGoalTypeUnit(_selectedType)}',
          style: Theme.of(context).textTheme.labelLarge,
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _targetController,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            hintText: _getGoalTypeHint(_selectedType),
            border: const OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 16),

        // Deadline (optional)
        Row(
          children: [
            Text(
              'Deadline (optional)',
              style: Theme.of(context).textTheme.labelLarge,
            ),
            const Spacer(),
            if (_selectedDeadline != null) ...[
              ShadButton.ghost(
                onPressed: () {
                  setState(() {
                    _selectedDeadline = null;
                  });
                },
                child: const Text('Clear'),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              ),
            ],
          ],
        ),
        const SizedBox(height: 8),
        ShadButton.outline(
          onPressed: _pickDeadline,
          child: Text(
            _selectedDeadline != null
                ? _formatDate(_selectedDeadline!)
                : 'Set deadline',
          ),
        ),
        const Spacer(),

        // Create button
        SizedBox(
          width: double.infinity,
          child: ShadButton(
            onPressed: _isCreating ? null : _createGoal,
            child: _isCreating
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Create Goal'),
          ),
        ),
      ],
    );
  }

  IconData _getIconForGoalType(WritingGoalType type) {
    switch (type) {
      case WritingGoalType.words:
        return Icons.text_fields;
      case WritingGoalType.characters:
        return Icons.keyboard;
      case WritingGoalType.pages:
        return Icons.description;
      case WritingGoalType.time:
        return Icons.schedule;
      case WritingGoalType.documents:
        return Icons.folder;
    }
  }

  String _getGoalTypeLabel(WritingGoalType type) {
    switch (type) {
      case WritingGoalType.words:
        return 'Words';
      case WritingGoalType.characters:
        return 'Characters';
      case WritingGoalType.pages:
        return 'Pages';
      case WritingGoalType.time:
        return 'Time';
      case WritingGoalType.documents:
        return 'Documents';
    }
  }

  String _getGoalTypeUnit(WritingGoalType type) {
    switch (type) {
      case WritingGoalType.words:
        return 'Words';
      case WritingGoalType.characters:
        return 'Characters';
      case WritingGoalType.pages:
        return 'Pages';
      case WritingGoalType.time:
        return 'Minutes';
      case WritingGoalType.documents:
        return 'Documents';
    }
  }

  String _getGoalTypeHint(WritingGoalType type) {
    switch (type) {
      case WritingGoalType.words:
        return '500';
      case WritingGoalType.characters:
        return '2000';
      case WritingGoalType.pages:
        return '2';
      case WritingGoalType.time:
        return '30';
      case WritingGoalType.documents:
        return '1';
    }
  }

  int _getCurrentValueForGoal(WritingGoal goal) {
    // This would need access to current statistics
    // For now, return 0 as a placeholder
    return 0;
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final dateOnly = DateTime(date.year, date.month, date.day);

    final diff = dateOnly.difference(today).inDays;

    if (diff == 0) return 'Today';
    if (diff == 1) return 'Tomorrow';
    if (diff > 1 && diff <= 7) return 'In $diff days';

    return '${date.month}/${date.day}/${date.year}';
  }

  Future<void> _pickDeadline() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDeadline ?? DateTime.now().add(const Duration(days: 7)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (date != null) {
      setState(() {
        _selectedDeadline = date;
      });
    }
  }

  Future<void> _createGoal() async {
    if (_titleController.text.trim().isEmpty || _targetController.text.trim().isEmpty) {
      return;
    }

    final target = int.tryParse(_targetController.text.trim());
    if (target == null || target <= 0) {
      return;
    }

    setState(() {
      _isCreating = true;
    });

    try {
      await widget.sessionService.createGoal(
        title: _titleController.text.trim(),
        type: _selectedType,
        targetValue: target,
        deadline: _selectedDeadline,
      );

      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      // Handle error
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to create goal: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isCreating = false;
        });
      }
    }
  }
}