import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../application/journey_game_notifier.dart';
import '../../data/jesus_journey_catalog.dart';
import '../../domain/models/journey_progress.dart';
import '../widgets/journey_path_node.dart';
import '../widgets/journey_path_connector.dart';
import '../widgets/journey_stats_bar.dart';
import 'journey_event_screen.dart';
import 'journey_complete_screen.dart';

class JourneyMapScreen extends ConsumerStatefulWidget {
  const JourneyMapScreen({super.key});

  @override
  ConsumerState<JourneyMapScreen> createState() => _JourneyMapScreenState();
}

class _JourneyMapScreenState extends ConsumerState<JourneyMapScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(journeyGameProvider);
    final notifier = ref.read(journeyGameProvider.notifier);

    // Navigate based on phase changes
    ref.listen<JourneyPhase>(
      journeyGameProvider.select((s) => s.phase),
      (prev, next) {
        if (next == JourneyPhase.viewingEvent && state.currentEvent != null) {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => const JourneyEventScreen(),
            ),
          );
        } else if (next == JourneyPhase.journeyComplete) {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => const JourneyCompleteScreen(),
            ),
          );
        }
      },
    );

    if (state.phase == JourneyPhase.loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final events = JesusJourneyCatalog.allEvents;
    final progress = state.progress;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Compute background gradient based on progress
    final gradientColors = _backgroundGradient(progress, isDark);

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: gradientColors,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // App bar
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_ios_new, size: 20),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Journey with Jesus',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                    const Spacer(),
                    // Reset button
                    if (progress.completedEvents.isNotEmpty)
                      PopupMenuButton<String>(
                        icon: Icon(
                          Icons.more_vert,
                          color: isDark ? Colors.white54 : Colors.black45,
                        ),
                        onSelected: (val) {
                          if (val == 'reset') {
                            _showResetDialog(context, notifier);
                          }
                        },
                        itemBuilder: (_) => [
                          const PopupMenuItem(
                            value: 'reset',
                            child: Text('Reset Journey'),
                          ),
                        ],
                      ),
                  ],
                ),
              ),

              // Stats bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: JourneyStatsBar(progress: progress),
              ),
              const SizedBox(height: 12),

              // Scrollable journey path
              Expanded(
                child: ListView.builder(
                  controller: _scrollController,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                  itemCount: events.length * 2 - 1, // nodes + connectors
                  itemBuilder: (context, index) {
                    if (index.isOdd) {
                      // Connector
                      final nodeIndex = index ~/ 2;
                      final isCompleted = progress.completedEvents
                          .containsKey(nodeIndex);
                      return JourneyPathConnector(
                        isCompleted: isCompleted,
                        isLeft: nodeIndex.isEven,
                      );
                    }

                    final eventIndex = index ~/ 2;
                    final event = events[eventIndex];
                    final isCompleted = progress.completedEvents
                        .containsKey(eventIndex);
                    final isCurrent =
                        eventIndex == progress.currentEvent && !isCompleted;

                    final nodeState = isCompleted
                        ? NodeState.completed
                        : isCurrent
                            ? NodeState.current
                            : NodeState.locked;

                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: JourneyPathNode(
                        event: event,
                        nodeState: nodeState,
                        result: progress.completedEvents[eventIndex],
                        isLeft: eventIndex.isEven,
                        onTap: () => notifier.openEvent(eventIndex),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Color> _backgroundGradient(JourneyProgress progress, bool isDark) {
    if (isDark) {
      return const [Color(0xFF0F172A), Color(0xFF1E293B)];
    }

    final pct = progress.overallProgress;
    if (pct < 0.2) {
      // Dawn
      return const [Color(0xFFFFF8E7), Color(0xFFFFECD2)];
    } else if (pct < 0.5) {
      // Midday
      return const [Color(0xFFF0F9FF), Color(0xFFE0F2FE)];
    } else if (pct < 0.8) {
      // Sunset
      return const [Color(0xFFFFF7ED), Color(0xFFFED7AA)];
    } else if (pct < 0.95) {
      // Night
      return const [Color(0xFFF1F5F9), Color(0xFFE2E8F0)];
    } else {
      // Sunrise (resurrection)
      return const [Color(0xFFFEFCE8), Color(0xFFFEF9C3)];
    }
  }

  void _showResetDialog(BuildContext context, JourneyGameNotifier notifier) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reset Journey?'),
        content: const Text(
          'This will clear all your progress and start the journey '
          'from the beginning. This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              notifier.resetJourney();
              Navigator.of(ctx).pop();
            },
            child: const Text(
              'Reset',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }
}
