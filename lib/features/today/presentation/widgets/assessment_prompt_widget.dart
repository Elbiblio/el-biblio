import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/app_providers.dart';
import '../../../../core/constants/app_routes.dart';

class AssessmentPromptWidget extends ConsumerWidget {
  const AssessmentPromptWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFFF4B925).withValues(alpha: 0.15),
            const Color(0xFFF4B925).withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFFF4B925).withValues(alpha: 0.3),
          width: 2,
        ),
        boxShadow: [
          if (!isDark)
            BoxShadow(
              color: const Color(0xFFF4B925).withValues(alpha: 0.2),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with icon and title
          Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: const Color(0xFFF4B925),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFF4B925).withValues(alpha: 0.4),
                      blurRadius: 15,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.explore_rounded,
                  color: Color(0xFF221D10),
                  size: 32,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Discover Your Spiritual Archetype',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : const Color(0xFF221D10),
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Take our Discovery Compass assessment',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: isDark ? Colors.white70 : const Color(0xFF221D10).withValues(alpha: 0.8),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 20),
          
          // Description
          Text(
            'Understanding your unique spiritual makeup helps us personalize your journey. The Discovery Compass reveals your core identity and strengths.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: isDark ? Colors.white70 : const Color(0xFF221D10).withValues(alpha: 0.7),
              height: 1.5,
              fontSize: 15,
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Action buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => _dismissPrompt(context, ref),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(
                      color: const Color(0xFFF4B925).withValues(alpha: 0.5),
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: Text(
                    'Skip',
                    style: TextStyle(
                      color: isDark ? Colors.white70 : const Color(0xFF221D10).withValues(alpha: 0.7),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: ElevatedButton(
                  onPressed: () => _startAssessment(context, ref),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFF4B925),
                    foregroundColor: const Color(0xFF221D10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    elevation: 4,
                    shadowColor: const Color(0xFFF4B925).withValues(alpha: 0.4),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Start Assessment',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(width: 8),
                      Icon(Icons.arrow_forward_rounded, size: 18),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _dismissPrompt(BuildContext context, WidgetRef ref) async {
    // Mark the prompt as seen so it doesn't show again
    await ref.read(settingsStorageProvider).markAssessmentPromptSeen();
  }

  void _startAssessment(BuildContext context, WidgetRef ref) async {
    // Mark the prompt as seen and navigate to assessment
    await ref.read(settingsStorageProvider).markAssessmentPromptSeen();
    if (context.mounted) {
      context.push(AppRoutes.assessment);
    }
  }
}
