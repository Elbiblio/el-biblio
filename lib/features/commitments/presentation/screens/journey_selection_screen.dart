import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_routes.dart';
import '../../../../core/di/app_providers.dart';
import '../../../../core/theme/app_theme_tokens.dart';
import '../../domain/models/commitment_journey.dart';
import '../widgets/prayer_intention_dialog.dart';

/// Screen for selecting a commitment journey duration and specific journey.
/// Shows 3-Day Seed, 10-Day Path, and 40-Day Journey options.
class JourneySelectionScreen extends ConsumerStatefulWidget {
  const JourneySelectionScreen({super.key});

  @override
  ConsumerState<JourneySelectionScreen> createState() =>
      _JourneySelectionScreenState();
}

class _JourneySelectionScreenState
    extends ConsumerState<JourneySelectionScreen> {
  CommitmentDuration? _selectedDuration;
  CommitmentJourney? _selectedJourney;

  @override
  void initState() {
    super.initState();
    // Load available journeys
    Future.microtask(() {
      ref.read(commitmentJourneyProvider.notifier).loadAvailableJourneys();
    });
  }

  void _selectDuration(CommitmentDuration duration) {
    setState(() {
      _selectedDuration = duration;
      _selectedJourney = null; // Reset journey when duration changes
    });
  }

  void _selectJourney(CommitmentJourney journey) {
    setState(() {
      _selectedJourney = journey;
    });
  }

  Future<void> _startJourney() async {
    if (_selectedJourney == null) return;

    // Show prayer intention dialog
    final intention = await showPrayerIntentionDialog(
      context: context,
      journeyTitle: _selectedJourney!.title,
      durationDays: _selectedJourney!.duration.days,
      virtueAlignment: _selectedJourney!.virtueAlignment,
    );

    if (intention == null || intention.isEmpty) return;

    // Start the journey
    await ref
        .read(commitmentJourneyProvider.notifier)
        .startJourney(
          journeyId: _selectedJourney!.id,
          prayerIntention: intention,
        );

    if (mounted) {
      // Navigate to the journey screen
      context.push(AppRoutes.commitmentJourney);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.tokens;
    final state = ref.watch(commitmentJourneyProvider);

    // Filter journeys by selected duration
    final filteredJourneys = state.availableJourneys
        .where((j) => j.duration == _selectedDuration)
        .toList();

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: tokens.pageGradient,
          ),
        ),
        child: SafeArea(
          child: CustomScrollView(
            slivers: [
              // App bar
              SliverAppBar(
                floating: true,
                backgroundColor: Colors.transparent,
                surfaceTintColor: Colors.transparent,
                title: Text(
                  'Choose Your Journey',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back_rounded),
                  onPressed: () => context.pop(),
                ),
              ),

              // Content
              SliverPadding(
                padding: const EdgeInsets.all(20),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    // Introduction
                    Text(
                      'How long will you walk this path?',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Choose a virtue and a duration that fits where you are right now.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(
                          alpha: 0.6,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Duration selector
                    _DurationSelector(
                      selectedDuration: _selectedDuration,
                      onSelect: _selectDuration,
                    ),

                    const SizedBox(height: 32),

                    // Journey options (if duration selected)
                    if (_selectedDuration != null) ...[
                      Text(
                        'Where is God inviting you to grow?',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 12),
                      if (filteredJourneys.isEmpty)
                        _EmptyJourneys(duration: _selectedDuration!)
                      else
                        ...filteredJourneys.map(
                          (journey) => Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: _JourneyCard(
                              journey: journey,
                              isSelected: _selectedJourney?.id == journey.id,
                              onTap: () => _selectJourney(journey),
                            ),
                          ),
                        ),
                    ],

                    const SizedBox(height: 24),

                    // Start button
                    if (_selectedJourney != null)
                      FilledButton.icon(
                        onPressed: _startJourney,
                        icon: const Icon(Icons.play_arrow_rounded),
                        label: Text('Begin ${_selectedJourney!.title}'),
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 32,
                            vertical: 16,
                          ),
                        ),
                      ),
                  ]),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Horizontal selector for 3/10/40 day durations
class _DurationSelector extends StatelessWidget {
  const _DurationSelector({
    required this.selectedDuration,
    required this.onSelect,
  });

  final CommitmentDuration? selectedDuration;
  final void Function(CommitmentDuration) onSelect;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      children: CommitmentDuration.values.map((duration) {
        final isSelected = selectedDuration == duration;
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: GestureDetector(
              onTap: () => onSelect(duration),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isSelected
                      ? theme.colorScheme.primary.withValues(alpha: 0.1)
                      : theme.colorScheme.surfaceContainerHighest.withValues(
                          alpha: 0.5,
                        ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isSelected
                        ? theme.colorScheme.primary
                        : Colors.transparent,
                    width: 2,
                  ),
                ),
                child: Column(
                  children: [
                    Text(
                      _durationEmoji(duration),
                      style: const TextStyle(fontSize: 28),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      duration.label.split(
                        ' ',
                      )[0], // "3-Day", "10-Day", "40-Day"
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: isSelected
                            ? theme.colorScheme.primary
                            : theme.colorScheme.onSurface,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _durationSubtitle(duration),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(
                          alpha: 0.6,
                        ),
                        fontSize: 11,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  String _durationEmoji(CommitmentDuration duration) {
    return switch (duration) {
      CommitmentDuration.seed3Day => '🌱',
      CommitmentDuration.path10Day => '🛤️',
      CommitmentDuration.journey40Day => '🏔️',
    };
  }

  String _durationSubtitle(CommitmentDuration duration) {
    return switch (duration) {
      CommitmentDuration.seed3Day => 'Begin with God',
      CommitmentDuration.path10Day => 'Build faithfulness',
      CommitmentDuration.journey40Day => 'Deep transformation',
    };
  }
}

/// Card showing a specific journey option
class _JourneyCard extends StatelessWidget {
  const _JourneyCard({
    required this.journey,
    required this.isSelected,
    required this.onTap,
  });

  final CommitmentJourney journey;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? theme.colorScheme.primaryContainer.withValues(alpha: 0.3)
              : theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? theme.colorScheme.primary
                : theme.colorScheme.outline.withValues(alpha: 0.2),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: _virtueColor(
                  journey.virtueAlignment,
                ).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Icon(
                  _virtueIcon(journey.virtueAlignment),
                  color: _virtueColor(journey.virtueAlignment),
                  size: 24,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    journey.title,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    journey.description,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: [
                      _Tag(
                        label: 'Growing in ${journey.virtueAlignment}',
                        color: _virtueColor(journey.virtueAlignment),
                      ),
                      if (journey.hasMilestones)
                        _Tag(
                          label:
                              '${journey.milestoneCount} deepening${journey.milestoneCount > 1 ? 's' : ''}',
                          color: theme.colorScheme.secondary,
                        ),
                      if (journey.source != CommitmentSource.remote)
                        _OfflineSourceChip(source: journey.source),
                    ],
                  ),
                ],
              ),
            ),
            if (isSelected)
              Icon(Icons.check_circle, color: theme.colorScheme.primary),
          ],
        ),
      ),
    );
  }

  Color _virtueColor(String virtue) {
    return switch (virtue.toLowerCase()) {
      'prayer' => const Color(0xFF7B68EE), // Purple
      'fasting' || 'temperance' => const Color(0xFFFF9800), // Orange
      'generosity' || 'charity' => const Color(0xFF4CAF50), // Green
      'knowledge' || 'scripture' => const Color(0xFF2196F3), // Blue
      'gratitude' => const Color(0xFFFFC107), // Amber
      _ => const Color(0xFF9E9E9E), // Grey
    };
  }

  IconData _virtueIcon(String virtue) {
    return switch (virtue.toLowerCase()) {
      'prayer' => Icons.self_improvement,
      'fasting' || 'temperance' => Icons.restaurant,
      'generosity' || 'charity' => Icons.volunteer_activism,
      'knowledge' || 'scripture' => Icons.menu_book,
      'gratitude' => Icons.favorite,
      _ => Icons.star,
    };
  }
}

/// Discreet chip indicating a journey came from cache or the bundled fallback
/// rather than a live backend fetch.
class _OfflineSourceChip extends StatelessWidget {
  const _OfflineSourceChip({required this.source});

  final CommitmentSource source;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final label = source == CommitmentSource.remoteCache ? 'Cached' : 'Offline';
    final color = theme.colorScheme.onSurface.withValues(alpha: 0.6);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.cloud_off_outlined, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

/// Small tag chip
class _Tag extends StatelessWidget {
  const _Tag({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w500,
          color: color,
        ),
      ),
    );
  }
}

/// Empty state when no journeys available for a duration
class _EmptyJourneys extends StatelessWidget {
  const _EmptyJourneys({required this.duration});

  final CommitmentDuration duration;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(
            Icons.construction_outlined,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
            size: 40,
          ),
          const SizedBox(height: 12),
          Text(
            'More ${duration.label} journeys coming soon',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
