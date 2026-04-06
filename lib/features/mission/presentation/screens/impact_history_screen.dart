import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/di/app_providers.dart';
import '../../domain/models/mission_action.dart';
import '../../domain/models/mission_focus.dart';
import '../widgets/mission_hub_sections.dart';

enum TimeFilter { week, month, allTime }

class ImpactHistoryScreen extends ConsumerStatefulWidget {
  const ImpactHistoryScreen({super.key});

  @override
  ConsumerState<ImpactHistoryScreen> createState() => _ImpactHistoryScreenState();
}

class _ImpactHistoryScreenState extends ConsumerState<ImpactHistoryScreen> {
  MissionFocusType? _focusFilter;
  TimeFilter _timeFilter = TimeFilter.allTime;

  @override
  Widget build(BuildContext context) {
    final mission = ref.watch(missionProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final filteredActions = _filterActions(mission.completedActions);
    final stats = _calculateStats(filteredActions);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Impact History'),
      ),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Statistics cards
                  Row(
                    children: [
                      Expanded(
                        child: _StatCard(
                          label: 'Total',
                          value: '${stats.total}',
                          icon: Icons.task_alt_rounded,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _StatCard(
                          label: 'This Week',
                          value: '${stats.thisWeek}',
                          icon: Icons.calendar_view_week_rounded,
                          color: Colors.blue,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _StatCard(
                          label: 'Follow-ups',
                          value: '${stats.followUps}',
                          icon: Icons.check_circle_rounded,
                          color: Colors.green,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Focus filter
                  Text(
                    'Filter by focus',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _FilterChip(
                        label: 'All',
                        isSelected: _focusFilter == null,
                        onTap: () => setState(() => _focusFilter = null),
                      ),
                      ...MissionFocusType.values.map(
                        (focus) => _FilterChip(
                          label: focus.label,
                          isSelected: _focusFilter == focus,
                          onTap: () => setState(() => _focusFilter = focus),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Time filter
                  Text(
                    'Time period',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  SegmentedButton<TimeFilter>(
                    segments: const [
                      ButtonSegment(
                        value: TimeFilter.week,
                        label: Text('Week'),
                      ),
                      ButtonSegment(
                        value: TimeFilter.month,
                        label: Text('Month'),
                      ),
                      ButtonSegment(
                        value: TimeFilter.allTime,
                        label: Text('All time'),
                      ),
                    ],
                    selected: {_timeFilter},
                    onSelectionChanged: (Set<TimeFilter> selected) {
                      setState(() => _timeFilter = selected.first);
                    },
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),

          // Timeline
          if (filteredActions.isEmpty)
            SliverFillRemaining(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.history_rounded,
                      size: 64,
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No completed actions yet',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final action = filteredActions[index];
                    final showDateHeader = index == 0 ||
                        _getDateGroup(action.completedAt!) !=
                            _getDateGroup(filteredActions[index - 1].completedAt!);

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (showDateHeader) ...[
                          _DateHeader(date: action.completedAt!),
                          const SizedBox(height: 8),
                        ],
                        MissionActionCard(
                          action: action,
                          isDark: isDark,
                          onToggle: () {
                            // Allow toggling back to incomplete if needed
                            ref.read(missionProvider.notifier).toggleCompleted(action);
                          },
                        ),
                        const SizedBox(height: 12),
                      ],
                    );
                  },
                  childCount: filteredActions.length,
                ),
              ),
            ),
        ],
      ),
    );
  }

  List<MissionAction> _filterActions(List<MissionAction> actions) {
    var filtered = actions;

    // Filter by focus
    if (_focusFilter != null) {
      filtered = filtered.where((a) => a.focus == _focusFilter).toList();
    }

    // Filter by time
    final now = DateTime.now();
    switch (_timeFilter) {
      case TimeFilter.week:
        final weekAgo = now.subtract(const Duration(days: 7));
        filtered = filtered
            .where((a) => a.completedAt != null && a.completedAt!.isAfter(weekAgo))
            .toList();
        break;
      case TimeFilter.month:
        final monthAgo = now.subtract(const Duration(days: 30));
        filtered = filtered
            .where((a) => a.completedAt != null && a.completedAt!.isAfter(monthAgo))
            .toList();
        break;
      case TimeFilter.allTime:
        break;
    }

    // Sort by completion date (newest first)
    filtered.sort((a, b) => (b.completedAt ?? a.createdAt).compareTo(a.completedAt ?? a.createdAt));

    return filtered;
  }

  _ImpactStats _calculateStats(List<MissionAction> actions) {
    final now = DateTime.now();
    final weekAgo = now.subtract(const Duration(days: 7));

    return _ImpactStats(
      total: actions.length,
      thisWeek: actions.where((a) => a.completedAt != null && a.completedAt!.isAfter(weekAgo)).length,
      followUps: actions.where((a) => a.followUpCompletedAt != null).length,
    );
  }

  String _getDateGroup(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final actionDate = DateTime(date.year, date.month, date.day);

    final difference = today.difference(actionDate).inDays;

    if (difference == 0) return 'Today';
    if (difference == 1) return 'Yesterday';
    if (difference < 7) return 'This week';
    if (difference < 30) return 'This month';
    return DateFormat('MMMM yyyy').format(date);
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: color.withValues(alpha: isDark ? 0.15 : 0.1),
        border: Border.all(
          color: color.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
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
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => onTap(),
      selectedColor: theme.colorScheme.primary.withValues(alpha: 0.15),
      labelStyle: TextStyle(
        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
        color: isSelected
            ? theme.colorScheme.primary
            : theme.colorScheme.onSurface.withValues(alpha: 0.75),
      ),
    );
  }
}

class _DateHeader extends StatelessWidget {
  const _DateHeader({required this.date});

  final DateTime date;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        DateFormat('MMM d, yyyy').format(date),
        style: theme.textTheme.titleSmall?.copyWith(
          fontWeight: FontWeight.w700,
          color: theme.colorScheme.primary,
        ),
      ),
    );
  }
}

class _ImpactStats {
  final int total;
  final int thisWeek;
  final int followUps;

  _ImpactStats({
    required this.total,
    required this.thisWeek,
    required this.followUps,
  });
}
