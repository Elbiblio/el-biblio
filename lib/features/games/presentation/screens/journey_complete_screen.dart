import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:confetti/confetti.dart';
import '../../application/journey_game_notifier.dart';

class JourneyCompleteScreen extends ConsumerStatefulWidget {
  const JourneyCompleteScreen({super.key});

  @override
  ConsumerState<JourneyCompleteScreen> createState() =>
      _JourneyCompleteScreenState();
}

class _JourneyCompleteScreenState extends ConsumerState<JourneyCompleteScreen>
    with SingleTickerProviderStateMixin {
  late ConfettiController _confettiController;
  late AnimationController _animCtrl;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(
      duration: const Duration(seconds: 5),
    );
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _scaleAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.elasticOut);

    Future.delayed(const Duration(milliseconds: 300), () {
      _confettiController.play();
      _animCtrl.forward();
    });
  }

  @override
  void dispose() {
    _confettiController.dispose();
    _animCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(journeyGameProvider);
    final notifier = ref.read(journeyGameProvider.notifier);
    final progress = state.progress;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: Stack(
        children: [
          // Background gradient
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: isDark
                    ? [const Color(0xFF1A1033), const Color(0xFF0F172A)]
                    : [const Color(0xFFFEFCE8), const Color(0xFFFFFBEB)],
              ),
            ),
          ),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Column(
                children: [
                  const SizedBox(height: 40),
                  // Trophy
                  ScaleTransition(
                    scale: _scaleAnim,
                    child: Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: const LinearGradient(
                          colors: [Color(0xFFDAA520), Color(0xFFFFD700)],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(
                              0xFFDAA520,
                            ).withValues(alpha: 0.4),
                            blurRadius: 30,
                            spreadRadius: 5,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.emoji_events,
                        size: 60,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  Text(
                    'Journey Complete!',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w900,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'You have walked through the entire life of Jesus.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      height: 1.5,
                      color: isDark ? Colors.white60 : Colors.black45,
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Stats card
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1e293b) : Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.08),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Text(
                          'YOUR JOURNEY RECAP',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 2,
                            color: isDark ? Colors.white38 : Colors.black38,
                          ),
                        ),
                        const SizedBox(height: 20),
                        _recapRow(
                          context,
                          icon: Icons.check_circle,
                          color: Colors.green,
                          label: 'Events Completed',
                          value: '${progress.completedEvents.length} / 30',
                        ),
                        const SizedBox(height: 14),
                        _recapRow(
                          context,
                          icon: Icons.star,
                          color: Colors.amber,
                          label: 'Perfect Events',
                          value: '${progress.perfectAnswers}',
                        ),
                        const SizedBox(height: 14),
                        _recapRow(
                          context,
                          icon: Icons.emoji_events,
                          color: Colors.orange,
                          label: 'Total Score',
                          value: '${progress.totalScore}',
                        ),
                        const SizedBox(height: 14),
                        _recapRow(
                          context,
                          icon: Icons.bolt,
                          color: Colors.blue,
                          label: 'XP Earned',
                          value: '${progress.totalXpEarned}',
                        ),
                        if (progress.startedAt != progress.completedAt) ...[
                          const SizedBox(height: 14),
                          _recapRow(
                            context,
                            icon: Icons.calendar_today,
                            color: Colors.purple,
                            label: 'Days to Complete',
                            value: _daysToComplete(progress),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Buttons
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: () {
                        notifier.backToMap();
                        Navigator.of(context).pop();
                      },
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFFDAA520),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: const Text(
                        'View Journey Map',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: () async {
                      await notifier.resetJourney();
                      if (!context.mounted) return;
                      Navigator.of(context).pop();
                    },
                    child: Text(
                      'Replay Journey',
                      style: TextStyle(
                        color: isDark ? Colors.white54 : Colors.black45,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),

          // Confetti
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confettiController,
              blastDirectionality: BlastDirectionality.explosive,
              shouldLoop: false,
              numberOfParticles: 40,
              gravity: 0.2,
              emissionFrequency: 0.05,
              colors: const [
                Colors.amber,
                Colors.orange,
                Colors.yellow,
                Colors.green,
                Colors.blue,
                Colors.purple,
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _recapRow(
    BuildContext context, {
    required IconData icon,
    required Color color,
    required String label,
    required String value,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Row(
      children: [
        Icon(icon, color: color, size: 22),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: isDark ? Colors.white60 : Colors.black54,
            ),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),
      ],
    );
  }

  String _daysToComplete(progress) {
    if (progress.completedAt == null) return '-';
    final diff = progress.completedAt!.difference(progress.startedAt).inDays;
    return diff <= 0 ? '1' : '$diff';
  }
}
