import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../../core/di/app_providers.dart';
import '../../../../core/services/sound_service.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/widgets/ambient_scope.dart';
import '../../../../core/theme/app_theme_tokens.dart';
import '../../application/habit_notifier.dart';
import '../../domain/models/habit_assessment.dart';
import '../widgets/habit_streak_card.dart';

class HabitTrackerScreen extends ConsumerStatefulWidget {
  const HabitTrackerScreen({super.key});

  @override
  ConsumerState<HabitTrackerScreen> createState() => _HabitTrackerScreenState();
}

class _HabitTrackerScreenState extends ConsumerState<HabitTrackerScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(habitProvider.notifier).loadHabits();
    });
  }

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).tokens;
    final state = ref.watch(habitProvider);

    return AmbientScope(
      asset: SoundService.ambientAssessmentAsset,
      volume: 0.06,
      child: Scaffold(
      backgroundColor: tokens.palette.background,
      appBar: AppBar(
        title: const Text('Habit Tracker'),
        backgroundColor: tokens.palette.background,
        actions: [
          IconButton(
            icon: Icon(LucideIcons.plus, color: tokens.palette.primary),
            onPressed: () => context.push('/alignment/habit-assessment'),
          ),
        ],
      ),
      body: state.isLoading
          ? const Center(child: CircularProgressIndicator())
          : state.activeHabits.isEmpty
              ? _buildEmptyState(context, tokens)
              : _buildContent(context, tokens, state),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, AppThemeTokens tokens) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              LucideIcons.target,
              size: 64,
              color: tokens.palette.textTertiary,
            ),
            const SizedBox(height: 16),
            Text(
              'No Active Habits',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Take the habit assessment to discover areas for growth.',
              textAlign: TextAlign.center,
              style: TextStyle(color: tokens.palette.textSecondary),
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: () => context.push('/alignment/habit-assessment'),
              child: const Text('Start Assessment'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    AppThemeTokens tokens,
    HabitState state,
  ) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Stats row
          Row(
            children: [
              _StatCard(
                label: 'Active',
                value: '${state.activeHabits.length}',
                icon: LucideIcons.activity,
                color: tokens.palette.primary,
              ),
              const SizedBox(width: 8),
              _StatCard(
                label: 'Best Streak',
                value: '${state.longestStreak}d',
                icon: LucideIcons.flame,
                color: const Color(0xFFFF6B35),
              ),
              const SizedBox(width: 8),
              _StatCard(
                label: 'Today',
                value: '${(state.consistencyPercent * 100).round()}%',
                icon: LucideIcons.checkCircle,
                color: tokens.palette.success,
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Category filter tabs
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _FilterChip(
                  label: 'All',
                  isSelected: state.selectedCategory == null,
                  onTap: () => ref.read(habitProvider.notifier).setCategory(null),
                ),
                ...HabitCategory.values.map((cat) => Padding(
                      padding: const EdgeInsets.only(left: 8),
                      child: _FilterChip(
                        label: cat.label,
                        icon: cat.icon,
                        color: cat.color,
                        isSelected: state.selectedCategory == cat,
                        onTap: () =>
                            ref.read(habitProvider.notifier).setCategory(cat),
                      ),
                    )),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Bad habits section
          if (state.filteredHabits.where((h) => h.isBadHabit).isNotEmpty) ...[
            Text(
              'HABITS TO CONQUER',
              style: Theme.of(context).textTheme.sectionHeader.copyWith(
                    color: tokens.palette.error,
                  ),
            ),
            const SizedBox(height: 8),
            ...state.filteredHabits.where((h) => h.isBadHabit).map((habit) {
              return HabitStreakCard(
                habit: habit,
                onCheckIn: () {
                  ref.read(soundServiceProvider).playChimeGentle();
                  ref.read(habitProvider.notifier).checkInHabit(habit.id);
                },
              );
            }),
            const SizedBox(height: 16),
          ],

          // Good habits section
          if (state.filteredHabits.where((h) => !h.isBadHabit).isNotEmpty) ...[
            Text(
              'BUILDING GOOD HABITS',
              style: Theme.of(context).textTheme.sectionHeader.copyWith(
                    color: tokens.palette.success,
                  ),
            ),
            const SizedBox(height: 8),
            ...state.filteredHabits.where((h) => !h.isBadHabit).map((habit) {
              return HabitStreakCard(
                habit: habit,
                onCheckIn: () {
                  ref.read(soundServiceProvider).playChimeGentle();
                  ref.read(habitProvider.notifier).checkInHabit(habit.id);
                },
              );
            }),
          ],

          const SizedBox(height: 100),
        ],
      ),
    );
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
    final tokens = Theme.of(context).tokens;

    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.15)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 6),
            Text(
              value,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: tokens.palette.textPrimary,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                color: tokens.palette.textTertiary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    this.icon,
    this.color,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final IconData? icon;
  final Color? color;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).tokens;
    final chipColor = color ?? tokens.palette.primary;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? chipColor.withValues(alpha: 0.15)
              : tokens.palette.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? chipColor : tokens.palette.border,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 14, color: isSelected ? chipColor : tokens.palette.textTertiary),
              const SizedBox(width: 4),
            ],
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isSelected ? chipColor : tokens.palette.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
