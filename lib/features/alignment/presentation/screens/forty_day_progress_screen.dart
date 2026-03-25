import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../../core/di/app_providers.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_theme_tokens.dart';
import '../../domain/models/forty_day_goal.dart';
import '../widgets/calendar_heatmap.dart';
import '../widgets/milestone_marker.dart';

class FortyDayProgressScreen extends ConsumerStatefulWidget {
  const FortyDayProgressScreen({super.key});

  @override
  ConsumerState<FortyDayProgressScreen> createState() =>
      _FortyDayProgressScreenState();
}

class _FortyDayProgressScreenState
    extends ConsumerState<FortyDayProgressScreen> {
  final _reflectionController = TextEditingController();
  int _rating = 3;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(fortyDayProvider.notifier).loadGoal();
    });
  }

  @override
  void dispose() {
    _reflectionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).tokens;
    final state = ref.watch(fortyDayProvider);
    final goal = state.activeGoal;

    return Scaffold(
      backgroundColor: tokens.palette.background,
      appBar: AppBar(
        title: Text(goal?.title ?? '40-Day Progress'),
        backgroundColor: tokens.palette.background,
      ),
      body: state.isLoading
          ? const Center(child: CircularProgressIndicator())
          : goal == null
              ? const Center(child: Text('No active goal'))
              : _buildContent(context, tokens, goal),
    );
  }

  Widget _buildContent(
    BuildContext context,
    AppThemeTokens tokens,
    FortyDayGoal goal,
  ) {
    final todayTask = goal.todayTask;
    final isCompleted = goal.status == GoalStatus.completed;
    final todayDone = goal.isDayCompleted(goal.currentDay);

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Progress ring + stats
          Center(
            child: Column(
              children: [
                SizedBox(
                  width: 120,
                  height: 120,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      SizedBox(
                        width: 120,
                        height: 120,
                        child: CircularProgressIndicator(
                          value: goal.progress,
                          strokeWidth: 10,
                          backgroundColor: tokens.palette.surface,
                          valueColor: AlwaysStoppedAnimation(
                            isCompleted
                                ? tokens.palette.success
                                : tokens.palette.primary,
                          ),
                          strokeCap: StrokeCap.round,
                        ),
                      ),
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '${(goal.progress * 100).round()}%',
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: tokens.palette.textPrimary,
                            ),
                          ),
                          Text(
                            'Day ${goal.currentDay}/40',
                            style: TextStyle(
                              fontSize: 12,
                              color: tokens.palette.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                // Stats row
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _MiniStat(
                      icon: LucideIcons.flame,
                      value: '${goal.streakDays}',
                      label: 'Streak',
                      color: const Color(0xFFFF6B35),
                    ),
                    const SizedBox(width: 24),
                    _MiniStat(
                      icon: LucideIcons.checkCircle,
                      value: '${goal.totalCompletedDays}',
                      label: 'Completed',
                      color: tokens.palette.success,
                    ),
                    const SizedBox(width: 24),
                    _MiniStat(
                      icon: LucideIcons.calendar,
                      value: '${40 - goal.currentDay}',
                      label: 'Remaining',
                      color: tokens.palette.primary,
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Calendar heatmap
          Text(
            'YOUR JOURNEY',
            style: Theme.of(context).textTheme.sectionHeader.copyWith(
                  color: tokens.palette.textTertiary,
                ),
          ),
          const SizedBox(height: 12),
          CalendarHeatmap(
            completions: goal.completions,
            startDate: goal.startDate,
            currentDay: goal.currentDay,
          ),
          const SizedBox(height: 24),

          // Today's task
          if (todayTask != null && !isCompleted) ...[
            Text(
              'TODAY\'S TASK',
              style: Theme.of(context).textTheme.sectionHeader.copyWith(
                    color: tokens.palette.primary,
                  ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: tokens.palette.paper,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: todayDone
                      ? tokens.palette.success
                      : tokens.palette.primary,
                  width: todayDone ? 1 : 1.5,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: tokens.palette.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'Day ${todayTask.dayNumber}',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: tokens.palette.primary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Row(
                        children: [
                          Icon(LucideIcons.clock, size: 12, color: tokens.palette.textTertiary),
                          const SizedBox(width: 4),
                          Text(
                            '${todayTask.durationMinutes} min',
                            style: TextStyle(
                              fontSize: 11,
                              color: tokens.palette.textTertiary,
                            ),
                          ),
                        ],
                      ),
                      if (todayDone) ...[
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: tokens.palette.success.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.check, size: 12, color: tokens.palette.success),
                              const SizedBox(width: 4),
                              Text(
                                'Done',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: tokens.palette.success,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    todayTask.title,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                      color: tokens.palette.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    todayTask.description,
                    style: TextStyle(
                      fontSize: 13,
                      color: tokens.palette.textSecondary,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: tokens.palette.surface,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(LucideIcons.bookOpen, size: 14, color: tokens.palette.primary),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            todayTask.relatedVerse,
                            style: TextStyle(
                              fontSize: 12,
                              fontStyle: FontStyle.italic,
                              color: tokens.palette.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Reflection + check-in (if not yet completed)
                  if (!todayDone) ...[
                    const SizedBox(height: 16),
                    Text(
                      todayTask.reflectionPrompt,
                      style: TextStyle(
                        fontSize: 13,
                        fontStyle: FontStyle.italic,
                        color: tokens.palette.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: _reflectionController,
                      maxLines: 3,
                      decoration: InputDecoration(
                        hintText: 'Your reflection...',
                        hintStyle: TextStyle(
                          color: tokens.palette.textTertiary,
                          fontSize: 13,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Rating
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'How was today?',
                          style: TextStyle(
                            fontSize: 12,
                            color: tokens.palette.textSecondary,
                          ),
                        ),
                        const SizedBox(width: 12),
                        ...List.generate(5, (i) {
                          final star = i + 1;
                          return GestureDetector(
                            onTap: () => setState(() => _rating = star),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 2),
                              child: Icon(
                                star <= _rating
                                    ? Icons.star_rounded
                                    : Icons.star_outline_rounded,
                                color: star <= _rating
                                    ? const Color(0xFFF4C430)
                                    : tokens.palette.textTertiary,
                                size: 28,
                              ),
                            ),
                          );
                        }),
                      ],
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: () {
                          ref.read(fortyDayProvider.notifier).completeDay(
                                dayNumber: goal.currentDay,
                                reflectionNote: _reflectionController.text.isEmpty
                                    ? null
                                    : _reflectionController.text,
                                rating: _rating,
                              );
                          _reflectionController.clear();
                          setState(() => _rating = 3);
                        },
                        child: const Text('Complete Today'),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],

          // Completion celebration
          if (isCompleted) ...[
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    tokens.palette.primary.withValues(alpha: 0.1),
                    tokens.palette.success.withValues(alpha: 0.1),
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: tokens.palette.success),
              ),
              child: Column(
                children: [
                  const Text('🎉', style: TextStyle(fontSize: 48)),
                  const SizedBox(height: 12),
                  Text(
                    'Journey Complete!',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: tokens.palette.success,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'You completed ${goal.totalCompletedDays} out of 40 days. Your faithfulness and perseverance have produced lasting spiritual growth.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: tokens.palette.textSecondary,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],

          // Milestone markers
          Text(
            'MILESTONES',
            style: Theme.of(context).textTheme.sectionHeader.copyWith(
                  color: tokens.palette.textTertiary,
                ),
          ),
          const SizedBox(height: 12),
          ...[
            (7, 'First Week Complete'),
            (14, 'Two Weeks Strong'),
            (21, 'Habit Formed'),
            (30, 'Almost There'),
            (40, 'Journey Complete'),
          ].map((m) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: MilestoneMarker(
                dayNumber: m.$1,
                title: m.$2,
                isCompleted: goal.completions.containsKey(m.$1),
                isCurrent: goal.currentDay == m.$1,
              ),
            );
          }),

          const SizedBox(height: 100),
        ],
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  const _MiniStat({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String value;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).tokens;

    return Column(
      children: [
        Icon(icon, color: color, size: 18),
        const SizedBox(height: 4),
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
    );
  }
}
