import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_routes.dart';
import '../../../core/di/app_providers.dart';
import '../domain/models/daily_anchors.dart';
import '../application/mood_notifier.dart';
import 'widgets/current_action_card.dart';
import 'widgets/daily_check_in_dialog.dart';
import 'widgets/daily_verse_card.dart';
import 'widgets/minimal_mood_button.dart';
import 'widgets/success_card.dart';

class TodayScreen extends ConsumerStatefulWidget {
  const TodayScreen({super.key});

  @override
  ConsumerState<TodayScreen> createState() => _TodayScreenState();
}

class _TodayScreenState extends ConsumerState<TodayScreen> {
  // Local state for the session flow
  bool _isActionCompleted = false;
  bool _isReflected = false;
  bool _isJournalCompleted = false;

  void _completeAction() {
    setState(() {
      _isActionCompleted = true;
    });
    // Mark the energy action as completed in the daily anchors
    ref.read(dailyAnchorsProvider.notifier).markAnchorDone(AnchorType.energyAction);
  }

  void _completeReflection() {
    setState(() {
      _isReflected = true;
    });
  }

  void _completeJournal() {
    setState(() {
      _isJournalCompleted = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final moodState = ref.watch(moodProvider);
    final moodNotifier = ref.read(moodProvider.notifier);
    
    final hour = DateTime.now().hour;
    final isEvening = hour >= 17; // 5 PM or later

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: moodState.backgroundColors,
          ),
        ),
        child: SafeArea(
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 8, 0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Left: greeting + subtitle
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              moodNotifier.getCurrentGreeting(),
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              moodNotifier.getCurrentFocus(),
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Right: mood pill + icon buttons
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _HeaderIconButton(
                                icon: Icons.self_improvement_rounded,
                                tooltip: 'Meditation',
                                onPressed: () => context.push(AppRoutes.meditation),
                              ),
                              _HeaderIconButton(
                                icon: Icons.menu_book_rounded,
                                tooltip: 'Bible',
                                onPressed: () => context.push(AppRoutes.bible),
                              ),
                              _HeaderIconButton(
                                icon: Icons.explore_outlined,
                                tooltip: 'Compass',
                                onPressed: () => context.push(AppRoutes.assessment),
                              ),
                              _HeaderIconButton(
                                icon: Icons.edit_note_outlined,
                                tooltip: 'Journal',
                                onPressed: () => context.push(AppRoutes.journal),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          const MinimalMoodButton(),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.all(16),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    const SizedBox(height: 32),
                    
                    // Main Flow Logic
                    if (!_isActionCompleted) ...[
                      // State 1: Next Action
                      CurrentActionCard(
                        onCompleted: _completeAction,
                        onSkip: _completeAction, // Skipping also advances flow
                      ),
                    ] else if (!_isReflected) ...[
                      // State 2: Verse Reflection
                      Container(
                        padding: const EdgeInsets.all(16),
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.thumb_up, color: Theme.of(context).colorScheme.primary),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Great job! Keep it up.',
                                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      DailyVerseCard(
                        onReflect: _completeReflection,
                        onShare: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Sharing coming soon!')),
                          );
                        },
                      ),
                    ] else if (!_isJournalCompleted) ...[
                      // State 3: Journal Recommendation
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surface,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
                          ),
                        ),
                        child: Column(
                          children: [
                            const Icon(Icons.edit_note, size: 48),
                            const SizedBox(height: 16),
                            Text(
                              'Capture your reflection',
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Would you like to journal about today\'s verse?',
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 24),
                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton(
                                    onPressed: _completeJournal, // Skip journaling
                                    child: const Text('Maybe Later'),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: FilledButton(
                                    onPressed: () async {
                                      final navigator = context;
                                      final verse = ref.read(verseProvider).todayVerse;
                                      final journalNotifier = ref.read(journalProvider.notifier);
                                      final noteId = await journalNotifier.createNoteWithContext(
                                        context: 'daily_verse',
                                        verseReference: verse?.reference,
                                        verseText: verse?.text,
                                      );
                                      _completeJournal();
                                      if (noteId != null && mounted) {
                                        navigator.push('${AppRoutes.journal}/$noteId');
                                      } else if (mounted) {
                                        navigator.push(AppRoutes.journal);
                                      }
                                    },
                                    child: const Text('Journal Now'),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ] else ...[
                      // State 4: Sparkling Clean
                      const SuccessCard(),
                    ],
                    
                    const SizedBox(height: 48),
                    
                    // Daily Check-in Button (visible after 5 PM)
                    // Always available regardless of flow state, as it's a separate mechanism
                    if (isEvening)
                      Center(
                        child: FilledButton.icon(
                          onPressed: () => showDialog(
                            context: context,
                            builder: (context) => const DailyCheckInDialog(),
                          ),
                          style: FilledButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                          ),
                          icon: const Icon(Icons.check_circle_outline),
                          label: const Text('Daily Check-in'),
                        ),
                      ),
                      
                    const SizedBox(height: 32),
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

class _HeaderIconButton extends StatelessWidget {
  const _HeaderIconButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.75);
    return IconButton(
      icon: Icon(icon, size: 22, color: color),
      tooltip: tooltip,
      onPressed: onPressed,
      visualDensity: VisualDensity.compact,
      padding: const EdgeInsets.all(6),
      constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
    );
  }
}
