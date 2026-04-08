import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/di/app_providers.dart';
import '../../application/mission_notifier.dart';

enum TimeFilter { week, month, allTime }

class ImpactHistoryScreen extends ConsumerStatefulWidget {
  const ImpactHistoryScreen({super.key});

  @override
  ConsumerState<ImpactHistoryScreen> createState() => _ImpactHistoryScreenState();
}

class _ImpactHistoryScreenState extends ConsumerState<ImpactHistoryScreen> {
  ImpactType? _typeFilter;
  TimeFilter _timeFilter = TimeFilter.allTime;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final timelineEvents = ref.read(missionProvider.notifier).impactTimeline;
    final filteredEvents = _filterEvents(timelineEvents);
    final stats = _calculateStats(timelineEvents);

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
                  Row(
                    children: [
                      Expanded(
                        child: _StatCard(
                          label: 'Actions',
                          value: '${stats.actionCount}',
                          icon: ImpactType.action.icon,
                          color: ImpactType.action.color,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _StatCard(
                          label: 'Giving',
                          value: '${stats.generosityCount}',
                          icon: ImpactType.generosity.icon,
                          color: ImpactType.generosity.color,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _StatCard(
                          label: 'Faith',
                          value: '${stats.evangelismCount}',
                          icon: ImpactType.evangelism.icon,
                          color: ImpactType.evangelism.color,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _StatCard(
                          label: 'People',
                          value: '${stats.relationshipCount}',
                          icon: ImpactType.relationship.icon,
                          color: ImpactType.relationship.color,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Filter by type',
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
                        isSelected: _typeFilter == null,
                        onTap: () => setState(() => _typeFilter = null),
                      ),
                      ...ImpactType.values.map(
                        (type) => _FilterChip(
                          label: type.label,
                          isSelected: _typeFilter == type,
                          onTap: () => setState(() => _typeFilter = type),
                          icon: type.icon,
                          color: type.color,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
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
          if (filteredEvents.isEmpty)
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
                      'No impact recorded yet',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Complete mission actions, record generosity,\nlog evangelism, or help specific people',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
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
                    final event = filteredEvents[index];
                    final showDateHeader = index == 0 ||
                        _getDateGroup(event.date) !=
                            _getDateGroup(filteredEvents[index - 1].date);

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (showDateHeader) ...[
                          _DateHeader(date: event.date),
                          const SizedBox(height: 8),
                        ],
                        _ImpactEventCard(
                          event: event,
                          isDark: isDark,
                        ),
                        const SizedBox(height: 12),
                      ],
                    );
                  },
                  childCount: filteredEvents.length,
                ),
              ),
            ),
        ],
      ),
    );
  }

  List<ImpactTimelineEvent> _filterEvents(List<ImpactTimelineEvent> events) {
    var filtered = events;

    if (_typeFilter != null) {
      filtered = filtered.where((e) => e.type == _typeFilter).toList();
    }

    final now = DateTime.now();
    switch (_timeFilter) {
      case TimeFilter.week:
        final weekAgo = now.subtract(const Duration(days: 7));
        filtered = filtered.where((e) => e.date.isAfter(weekAgo)).toList();
        break;
      case TimeFilter.month:
        final monthAgo = now.subtract(const Duration(days: 30));
        filtered = filtered.where((e) => e.date.isAfter(monthAgo)).toList();
        break;
      case TimeFilter.allTime:
        break;
    }

    return filtered;
  }

  _ImpactStats _calculateStats(List<ImpactTimelineEvent> events) {
    final now = DateTime.now();
    final weekAgo = now.subtract(const Duration(days: 7));

    return _ImpactStats(
      actionCount: events.where((e) => e.type == ImpactType.action).length,
      generosityCount: events.where((e) => e.type == ImpactType.generosity).length,
      evangelismCount: events.where((e) => e.type == ImpactType.evangelism).length,
      relationshipCount: events.where((e) => e.type == ImpactType.relationship).length,
      thisWeek: events.where((e) => e.date.isAfter(weekAgo)).length,
    );
  }

  String _getDateGroup(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final eventDate = DateTime(date.year, date.month, date.day);

    final difference = today.difference(eventDate).inDays;

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
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: color.withValues(alpha: isDark ? 0.15 : 0.1),
        border: Border.all(
          color: color.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 4),
          Text(
            value,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              fontSize: 11,
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
    this.icon,
    this.color,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final IconData? icon;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return FilterChip(
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(
              icon,
              size: 16,
              color: isSelected ? (color ?? theme.colorScheme.primary) : theme.colorScheme.onSurface.withValues(alpha: 0.6),
            ),
            const SizedBox(width: 6),
          ],
          Text(label),
        ],
      ),
      selected: isSelected,
      onSelected: (_) => onTap(),
      selectedColor: (color ?? theme.colorScheme.primary).withValues(alpha: 0.15),
      labelStyle: TextStyle(
        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
        color: isSelected
            ? (color ?? theme.colorScheme.primary)
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

class _ImpactEventCard extends StatelessWidget {
  const _ImpactEventCard({
    required this.event,
    required this.isDark,
  });

  final ImpactTimelineEvent event;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = event.type.color;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: theme.colorScheme.surface,
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: isDark ? 0.2 : 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              event.type.icon,
              color: color,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: isDark ? 0.2 : 0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        event.type.label,
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: color,
                        ),
                      ),
                    ),
                    if (event.personName != null) ...[
                      const SizedBox(width: 8),
                      Icon(
                        Icons.person_outline,
                        size: 14,
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        event.personName!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  event.title,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  event.description,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                ),
                if (event.decisionMade != null) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getDecisionColor(event.decisionMade!).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(
                        color: _getDecisionColor(event.decisionMade!).withValues(alpha: 0.3),
                      ),
                    ),
                    child: Text(
                      'Decision: ${_capitalizeFirst(event.decisionMade!)}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: _getDecisionColor(event.decisionMade!),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getDecisionColor(String decision) {
    switch (decision.toLowerCase()) {
      case 'accepted':
        return Colors.green;
      case 'considering':
        return Colors.orange;
      case 'not-ready':
        return Colors.blue;
      case 'declined':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _capitalizeFirst(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1);
  }
}

class _ImpactStats {
  final int actionCount;
  final int generosityCount;
  final int evangelismCount;
  final int relationshipCount;
  final int thisWeek;

  _ImpactStats({
    required this.actionCount,
    required this.generosityCount,
    required this.evangelismCount,
    required this.relationshipCount,
    required this.thisWeek,
  });
}
