import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../application/time_diagnose_notifier.dart';
import '../../domain/models/time_diagnose_models.dart';

class TimeDiagnoseAnalysisScreen extends ConsumerWidget {
  const TimeDiagnoseAnalysisScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(timeDiagnoseProvider);

    // Basic logic to find dominant and lacking pillars
    var sortedAllocations = state.allocations.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    
    final dominantPillar = sortedAllocations.first.key;
    const lackingPillar = TimePillar.spirit; // Could be dynamic, defaulting to Spirit for demo
    
    final dominantPercent = (state.allocations[dominantPillar]! / (24 * 60) * 100).toStringAsFixed(0);

    return Scaffold(
      backgroundColor: const Color(0xFFFDFCF7), // parchment
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 32, 24, 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'ELBIBLIO SPIRITUAL OS',
                        style: TextStyle(
                          fontSize: 10,
                          letterSpacing: 3,
                          fontWeight: FontWeight.w500,
                          color: Colors.black38,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'The Prescription',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w300,
                          color: Color(0xFF333D29), // earth-charcoal
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.history_edu, color: Colors.black38),
                    onPressed: () {},
                  ),
                ],
              ),
            ),
            
            // Description
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 24.0),
              child: Text(
                'Analysis complete. Here is your tailored path to balance.',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w300,
                  color: Colors.black54,
                  height: 1.5,
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Diagnosis Card
                    Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Container(
                          margin: const EdgeInsets.only(top: 12),
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: const Color(0xFF333D29).withValues(alpha:0.05),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: const Color(0xFF333D29).withValues(alpha:0.1),
                            ),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Padding(
                                padding: EdgeInsets.only(top: 4.0),
                                child: Icon(
                                  Icons.balance,
                                  color: Color(0xFFC89F81),
                                  size: 28,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Imbalance Detected',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w500,
                                        color: Color(0xFF333D29),
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    RichText(
                                      text: TextSpan(
                                        style: const TextStyle(
                                          fontSize: 14,
                                          height: 1.5,
                                          color: Colors.black87,
                                          fontFamily: 'Noto Serif',
                                        ),
                                        children: [
                                          const TextSpan(text: 'Your '),
                                          TextSpan(
                                            text: dominantPillar.label,
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              color: dominantPillar.color,
                                            ),
                                          ),
                                          TextSpan(text: ' slice is dominant ($dominantPercent%), leaving sparse room for '),
                                          TextSpan(
                                            text: lackingPillar.label,
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              color: lackingPillar.color,
                                            ),
                                          ),
                                          const TextSpan(text: '. This imbalance often leads to burnout and disconnection from purpose.'),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        Positioned(
                          top: 0,
                          left: 24,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            color: const Color(0xFFFDFCF7),
                            child: const Text(
                              'DIAGNOSIS',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 2,
                                color: Color(0xFF333D29),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 32),
                    
                    const Padding(
                      padding: EdgeInsets.only(left: 4.0),
                      child: Text(
                        'SUGGESTED REGIMENS',
                        style: TextStyle(
                          fontSize: 10,
                          letterSpacing: 2,
                          color: Colors.black38,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Scripture Plan
                    const _PlanCard(
                      pillar: TimePillar.learning,
                      icon: Icons.menu_book,
                      duration: '15m Daily',
                      title: 'The Humility Path',
                      description: 'A 4-week journey through Proverbs and Psalms to reground your professional ambition.',
                      primaryColor: Color(0xFF8D7B68),
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Contemplation Plan
                    const _PlanCard(
                      pillar: TimePillar.spirit,
                      icon: Icons.self_improvement,
                      duration: '10m Daily',
                      title: 'Silence & Solitude',
                      description: 'Morning breath prayers designed to center your spirit before the workday begins.',
                      primaryColor: Color(0xFFA4AC86),
                    ),
                    
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
            
            // Bottom Action
            Container(
              padding: const EdgeInsets.symmetric(vertical: 24),
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(color: Colors.black.withValues(alpha:0.06)),
                ),
              ),
              child: Center(
                child: TextButton(
                  onPressed: () {
                    // Navigate to root/today screen
                    context.go('/');
                  },
                  child: const Text(
                    'SKIP FOR NOW',
                    style: TextStyle(
                      fontSize: 12,
                      letterSpacing: 2,
                      color: Colors.black38,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PlanCard extends StatelessWidget {
  final TimePillar pillar;
  final IconData icon;
  final String duration;
  final String title;
  final String description;
  final Color primaryColor;

  const _PlanCard({
    required this.pillar,
    required this.icon,
    required this.duration,
    required this.title,
    required this.description,
    required this.primaryColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha:0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.black.withValues(alpha:0.08)),
      ),
      clipBehavior: Clip.hardEdge,
      child: Column(
        children: [
          // Top accent line
          Container(
            height: 4,
            width: double.infinity,
            color: primaryColor,
          ),
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(icon, color: primaryColor, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          pillar.label.toUpperCase(),
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 2,
                            color: primaryColor,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: primaryColor.withValues(alpha:0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        duration,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                          color: primaryColor,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 20,
                    color: Color(0xFF333D29),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.black54,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {},
                        style: OutlinedButton.styleFrom(
                          foregroundColor: primaryColor,
                          side: BorderSide(color: primaryColor.withValues(alpha:0.3)),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text(
                          'PREVIEW',
                          style: TextStyle(
                            fontSize: 12,
                            letterSpacing: 1,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {},
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          elevation: 2,
                        ),
                        child: const Text(
                          'START PLAN',
                          style: TextStyle(
                            fontSize: 12,
                            letterSpacing: 1,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
