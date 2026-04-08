import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:confetti/confetti.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../core/constants/app_routes.dart';
import '../../../../core/di/app_providers.dart';
import '../../../../core/theme/app_theme_tokens.dart';
import '../../application/commitment_journey_notifier.dart';
import '../../domain/models/commitment_journey.dart';
import '../widgets/landmarked_timeline.dart';

/// New journey screen showing the landmarked timeline and journey progress.
/// Replaces the old 40-level grid with a spiritual journey visualization.
class CommitmentJourneyScreenNew extends ConsumerStatefulWidget {
  const CommitmentJourneyScreenNew({super.key});

  @override
  ConsumerState<CommitmentJourneyScreenNew> createState() =>
      _CommitmentJourneyScreenNewState();
}

class _CommitmentJourneyScreenNewState
    extends ConsumerState<CommitmentJourneyScreenNew> {
  late final ConfettiController _confettiController;

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(duration: const Duration(seconds: 3));
    // Load active journey on init
    Future.microtask(() {
      ref.read(commitmentJourneyProvider.notifier).loadActiveJourney();
    });
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  Future<void> _checkIn() async {
    await ref.read(commitmentJourneyProvider.notifier).checkInToday();
    
    // Check if milestone was reached and show notification
    final state = ref.read(commitmentJourneyProvider);
    if (state.justReachedMilestone != null && mounted) {
      _showMilestoneDialog(state.justReachedMilestone!);
    }
  }

  void _showMilestoneDialog(int milestoneDay) {
    final theme = Theme.of(context);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        icon: Icon(
          Icons.diamond_outlined,
          color: theme.colorScheme.secondary,
          size: 40,
        ),
        title: const Text('Your journey deepens'),
        content: Text(
          'From Day $milestoneDay, your commitment grows stronger. '
          'Stay focused on your calling.',
        ),
        actions: [
          FilledButton(
            onPressed: () {
              Navigator.of(context).pop();
              ref.read(commitmentJourneyProvider.notifier).acknowledgeMilestone();
            },
            child: const Text('Continue'),
          ),
        ],
      ),
    );
  }

  void _showAbandonDialog(String journeyId) {
    final theme = Theme.of(context);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Leave this journey?'),
        content: const Text(
          'You can always start again, but your progress on this journey will be lost.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'Stay',
              style: TextStyle(color: theme.colorScheme.primary),
            ),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(context).pop();
              ref.read(commitmentJourneyProvider.notifier).abandonJourney();
              context.pop();
            },
            style: FilledButton.styleFrom(
              backgroundColor: theme.colorScheme.error,
            ),
            child: const Text('Leave'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.tokens;
    final state = ref.watch(commitmentJourneyProvider);

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
          bottom: false,
          child: Stack(
            children: [
              state.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : state.justCompleted
                      ? _buildCompletionCelebration(context, state)
                      : state.activeJourney == null
                          ? _buildEmptyState(context)
                          : _buildJourneyView(context, state),
              // Confetti overlay
              Align(
                alignment: Alignment.topCenter,
                child: ConfettiWidget(
                  confettiController: _confettiController,
                  blastDirectionality: BlastDirectionality.explosive,
                  particleDrag: 0.05,
                  emissionFrequency: 0.05,
                  numberOfParticles: 60,
                  gravity: 0.1,
                  colors: [
                    theme.colorScheme.primary,
                    Colors.amber,
                    Colors.orange,
                    Colors.pink,
                    Colors.green,
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCompletionCelebration(BuildContext context, CommitmentJourneyState state) {
    final theme = Theme.of(context);
    final active = state.activeJourney;

    // Fire confetti on first build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_confettiController.state != ConfettiControllerState.playing) {
        _confettiController.play();
      }
    });

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Spacer(flex: 2),

            Icon(
              Icons.emoji_events_rounded,
              size: 72,
              color: Colors.amber.shade600,
            ),

            const SizedBox(height: 24),

            Text(
              'Journey Complete!',
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.w800,
                color: theme.colorScheme.onSurface,
              ),
            ),

            const SizedBox(height: 12),

            if (active != null) ...[
              Text(
                '${active.completedDays.length} days of faithfulness',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),

              if (active.prayerIntention.isNotEmpty) ...[
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      Text(
                        'Your prayer intention:',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '"${active.prayerIntention}"',
                        style: theme.textTheme.bodyLarge?.copyWith(
                          fontStyle: FontStyle.italic,
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ],
            ],

            const Spacer(flex: 2),

            // Share button
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  final days = active?.completedDays.length ?? 0;
                  Share.share(
                    'I just completed a $days-day spiritual journey on El-Biblio! '
                    'Grow your faith at elbiblio.com',
                  );
                },
                icon: const Icon(Icons.share_rounded),
                label: const Text('Share this milestone'),
              ),
            ),

            const SizedBox(height: 12),

            // Continue button
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () {
                  ref.read(commitmentJourneyProvider.notifier).acknowledgeCompletion();
                  context.go(AppRoutes.today);
                },
                child: const Text('Continue'),
              ),
            ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.nature_outlined,
              size: 64,
              color: theme.colorScheme.primary.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 24),
            Text(
              'No active journey',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Begin a new commitment to see your journey here.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(height: 32),
            FilledButton.icon(
              onPressed: () => context.push(AppRoutes.journeySelection),
              icon: const Icon(Icons.add_rounded),
              label: const Text('Start a Journey'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildJourneyView(BuildContext context, CommitmentJourneyState state) {
    final theme = Theme.of(context);
    final activeJourney = state.activeJourney!;

    // Get journey details from repository
    return FutureBuilder<CommitmentJourney>(
      future: ref
          .read(commitmentJourneyProvider.notifier)
          .getCurrentJourneyDetails(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final journey = snapshot.data!;

        return CustomScrollView(
          slivers: [
            // App bar
            SliverAppBar(
              pinned: true,
              backgroundColor: Colors.transparent,
              surfaceTintColor: Colors.transparent,
              title: Text(
                'Your ${journey.duration.label}',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              leading: IconButton(
                icon: const Icon(Icons.arrow_back_rounded),
                onPressed: () => context.pop(),
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.more_vert),
                  onPressed: () => _showAbandonDialog(journey.id),
                ),
              ],
            ),

            // Journey header with intention and virtue
            SliverToBoxAdapter(
              child: _JourneyHeader(
                journey: journey,
                activeJourney: activeJourney,
              ),
            ),

            // Today's check-in card
            SliverToBoxAdapter(
              child: _TodayCheckInCard(
                journey: journey,
                activeJourney: activeJourney,
                onCheckIn: _checkIn,
                checkInStatus: state.justReachedMilestone,
              ),
            ),

            // Progress stats
            SliverToBoxAdapter(
              child: _ProgressStats(
                journey: journey,
                activeJourney: activeJourney,
              ),
            ),

            // Landmarked timeline
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Your Journey Path',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Where you are and where you\'re going',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                      ),
                    ),
                    const SizedBox(height: 20),
                    LandmarkedTimeline(
                      journey: journey,
                      activeJourney: activeJourney,
                      onMilestoneTap: (milestone) {
                        // Show milestone details if reached
                        if (activeJourney.currentDay >= milestone.day) {
                          _showMilestoneDetail(milestone);
                        }
                      },
                    ),
                  ],
                ),
              ),
            ),

            // Tips section
            SliverToBoxAdapter(
              child: _TipsSection(tips: journey.tips),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 40)),
          ],
        );
      },
    );
  }

  void _showMilestoneDetail(CommitmentMilestone milestone) {
    final theme = Theme.of(context);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Day ${milestone.day} Deepening'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(milestone.description),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.secondaryContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'New requirement: ${milestone.newRequirement}',
                style: TextStyle(
                  color: theme.colorScheme.onSecondaryContainer,
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}

/// Header showing journey intention and virtue alignment
class _JourneyHeader extends StatelessWidget {
  const _JourneyHeader({
    required this.journey,
    required this.activeJourney,
  });

  final CommitmentJourney journey;
  final ActiveJourney activeJourney;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: theme.colorScheme.primary.withValues(alpha: 0.2),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Intention
            Row(
              children: [
                Icon(
                  Icons.favorite_outline,
                  size: 16,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'INTENTION',
                  style: theme.textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.2,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '"${activeJourney.prayerIntention}"',
              style: theme.textTheme.bodyLarge?.copyWith(
                fontStyle: FontStyle.italic,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 12),
            // Virtue and day
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'Growing in ${journey.virtueAlignment}',
                    style: theme.textTheme.labelSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ),
                const Spacer(),
                Text(
                  'Day ${activeJourney.currentDay} of ${journey.duration.days}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Today's check-in card
class _TodayCheckInCard extends StatelessWidget {
  const _TodayCheckInCard({
    required this.journey,
    required this.activeJourney,
    required this.onCheckIn,
    required this.checkInStatus,
  });

  final CommitmentJourney journey;
  final ActiveJourney activeJourney;
  final VoidCallback onCheckIn;
  final int? checkInStatus;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final today = DateTime.now();
    final hour = today.hour;

    // Check if already checked in today
    final alreadyCheckedIn =
        activeJourney.completedDays.contains(activeJourney.currentDay);

    // Determine check-in availability based on time and partner
    String statusText;
    bool canCheckIn;
    IconData statusIcon;

    if (alreadyCheckedIn) {
      statusText = '✓ Checked in for today';
      canCheckIn = false;
      statusIcon = Icons.check_circle;
    } else if (hour < 18) {
      statusText = 'Check-in opens at 6pm';
      canCheckIn = false;
      statusIcon = Icons.schedule;
    } else if (hour >= 18 && hour < 20) {
      statusText = 'Partner check-in window (6pm-8pm)';
      canCheckIn = true; // Allow, but will note partner first
      statusIcon = Icons.people_outline;
    } else {
      statusText = 'Check in your progress';
      canCheckIn = true;
      statusIcon = Icons.edit_note;
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: alreadyCheckedIn
              ? theme.colorScheme.secondaryContainer.withValues(alpha: 0.3)
              : theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: alreadyCheckedIn
                ? theme.colorScheme.secondary.withValues(alpha: 0.3)
                : theme.colorScheme.outline.withValues(alpha: 0.2),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  statusIcon,
                  size: 20,
                  color: alreadyCheckedIn
                      ? theme.colorScheme.secondary
                      : theme.colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    statusText,
                    style: theme.textTheme.labelSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: alreadyCheckedIn
                          ? theme.colorScheme.secondary
                          : theme.colorScheme.primary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Today\'s commitment:',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              journey.requirementForDay(activeJourney.currentDay),
              style: theme.textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            if (canCheckIn && !alreadyCheckedIn) ...[
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: onCheckIn,
                      icon: const Icon(Icons.check),
                      label: const Text('I kept my commitment'),
                    ),
                  ),
                ],
              ),
              if (hour >= 18 && hour < 20)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    'Your partner will be asked first. You can check in after 8pm if they don\'t respond.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                      fontSize: 11,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Progress statistics
class _ProgressStats extends StatelessWidget {
  const _ProgressStats({
    required this.journey,
    required this.activeJourney,
  });

  final CommitmentJourney journey;
  final ActiveJourney activeJourney;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final progress = activeJourney.progressPercent;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
      child: Row(
        children: [
          _StatCard(
            label: 'Completed',
            value: '${activeJourney.completedDays.length}',
            unit: 'days',
            color: theme.colorScheme.primary,
          ),
          const SizedBox(width: 12),
          _StatCard(
            label: 'Current streak',
            value: '${activeJourney.streakDays}',
            unit: 'days',
            color: theme.colorScheme.secondary,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest
                    .withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${(progress * 100).toInt()}%',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: progress,
                      minHeight: 6,
                      backgroundColor: theme.colorScheme.surface,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Small stat card
class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.value,
    required this.unit,
    required this.color,
  });

  final String label;
  final String value;
  final String unit;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
          Text(
            unit,
            style: theme.textTheme.bodySmall?.copyWith(
              color: color.withValues(alpha: 0.8),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
            ),
          ),
        ],
      ),
    );
  }
}

/// Tips section
class _TipsSection extends StatelessWidget {
  const _TipsSection({required this.tips});

  final List<String> tips;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (tips.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Tips for your journey',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          ...tips.map((tip) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.lightbulb_outline,
                      size: 16,
                      color: theme.colorScheme.secondary,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        tip,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
                        ),
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }
}
