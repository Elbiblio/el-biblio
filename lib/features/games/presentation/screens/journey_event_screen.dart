import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../application/journey_game_notifier.dart';
import '../widgets/event_narrative_card.dart';
import 'journey_quiz_screen.dart';

class JourneyEventScreen extends ConsumerWidget {
  const JourneyEventScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(journeyGameProvider);
    final notifier = ref.read(journeyGameProvider.notifier);
    final event = state.currentEvent;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (event == null) {
      return const Scaffold(body: Center(child: Text('No event selected')));
    }

    // Listen for phase transition to quiz
    ref.listen<JourneyPhase>(
      journeyGameProvider.select((s) => s.phase),
      (prev, next) {
        if (next == JourneyPhase.quiz) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const JourneyQuizScreen()),
          );
        }
      },
    );

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              event.themeColor.withValues(alpha: isDark ? 0.2 : 0.1),
              isDark ? const Color(0xFF0F172A) : Colors.white,
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // App bar
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_ios_new, size: 20),
                      onPressed: () {
                        notifier.backToMap();
                        Navigator.of(context).pop();
                      },
                    ),
                    Expanded(
                      child: Text(
                        'Event ${event.order + 1} of 30',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white54 : Colors.black45,
                        ),
                      ),
                    ),
                    const SizedBox(width: 48), // balance
                  ],
                ),
              ),

              // Content
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 24, vertical: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Event icon & title
                      Center(
                        child: Container(
                          width: 72,
                          height: 72,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color:
                                event.themeColor.withValues(alpha: 0.15),
                            border: Border.all(
                                color: event.themeColor, width: 2),
                          ),
                          child: Icon(
                            _resolveIcon(event.iconName),
                            color: event.themeColor,
                            size: 32,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Center(
                        child: Text(
                          event.title,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.w900,
                            color: isDark ? Colors.white : Colors.black87,
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Center(
                        child: Text(
                          event.subtitle,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 14,
                            color: isDark ? Colors.white54 : Colors.black45,
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Center(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(
                            color:
                                event.themeColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            event.bibleReference,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: event.themeColor,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Narrative
                      EventNarrativeCard(
                        narrative: event.narrative,
                        themeColor: event.themeColor,
                      ),
                      const SizedBox(height: 24),

                      // Key verse
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: isDark
                              ? const Color(0xFF1e293b)
                              : Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color:
                                event.themeColor.withValues(alpha: 0.3),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color:
                                  Colors.black.withValues(alpha: 0.04),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            Icon(LucideIcons.quote,
                                color: event.themeColor, size: 20),
                            const SizedBox(height: 8),
                            Text(
                              event.keyVerse,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                fontStyle: FontStyle.italic,
                                height: 1.5,
                                color: isDark
                                    ? Colors.white
                                    : Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '- ${event.keyVerseReference}',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: event.themeColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 32),

                      // Begin quiz button
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          onPressed: () => notifier.startQuiz(),
                          icon: const Icon(Icons.quiz_outlined),
                          label: const Text(
                            'Begin Questions',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          style: FilledButton.styleFrom(
                            backgroundColor: event.themeColor,
                            padding: const EdgeInsets.symmetric(
                                vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

IconData _resolveIcon(String name) {
  final map = <String, IconData>{
    'scroll_text': LucideIcons.scrollText,
    'sparkles': LucideIcons.sparkles,
    'baby': LucideIcons.baby,
    'star': LucideIcons.star,
    'route': LucideIcons.navigation,
    'book_open': LucideIcons.bookOpen,
    'droplets': LucideIcons.droplets,
    'shield': LucideIcons.shield,
    'users': LucideIcons.users,
    'wine': LucideIcons.wine,
    'mountain': LucideIcons.mountain,
    'heart_handshake': LucideIcons.heartHandshake,
    'cloud_lightning': LucideIcons.cloudLightning,
    'wheat': LucideIcons.wheat,
    'waves': LucideIcons.waves,
    'sun': LucideIcons.sun,
    'hand_helping': LucideIcons.helpingHand,
    'sunrise': LucideIcons.sunrise,
    'heart': LucideIcons.heart,
    'tree_pine': LucideIcons.treePine,
    'palm_tree': LucideIcons.palmtree,
    'flame': LucideIcons.flame,
    'utensils': LucideIcons.utensils,
    'moon': LucideIcons.moon,
    'scale': LucideIcons.scale,
    'cross': LucideIcons.cross,
    'landmark': LucideIcons.landmark,
    'sun_rise': LucideIcons.sunrise,
    'users_round': LucideIcons.users,
    'cloud': LucideIcons.cloud,
  };
  return map[name] ?? LucideIcons.circle;
}
