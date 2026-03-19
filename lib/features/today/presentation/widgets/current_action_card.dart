import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/di/app_providers.dart';
import '../../../../core/theme/app_theme_tokens.dart';
import '../../application/actionable_intelligence.dart';
import '../../application/mood_notifier.dart';
import '../../domain/models/mood.dart';

class CurrentActionCard extends ConsumerWidget {
  const CurrentActionCard({
    super.key,
    this.onCompleted,
    this.onSkip,
  });

  final VoidCallback? onCompleted;
  final VoidCallback? onSkip;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final moodState = ref.watch(moodProvider);
    
    // Get actual virtue type from settings
    final virtueType = settings.primaryVirtue;
    // Get actual mood from mood provider
    final moodType = moodState.currentMood?.type;
    
    // Get current time context
    final hour = DateTime.now().hour;
    final timeContext = hour >= 6 && hour < 12 
        ? TimeContext.morning 
        : hour >= 12 && hour < 18 
            ? TimeContext.midday 
            : hour >= 18 && hour < 22 
                ? TimeContext.evening 
                : TimeContext.night;
    
    final currentAction = ActionableIntelligence.getCurrentAction(
      virtueType: virtueType,
      moodType: moodType,
      timeContext: timeContext,
    );

    final theme = Theme.of(context);
    final tokens = theme.tokens;
    final isDark = theme.brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.only(bottom: 24.0),
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? theme.colorScheme.surface : tokens.palette.paper,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isDark 
                ? theme.colorScheme.outline.withValues(alpha: 0.2)
                : tokens.palette.border.withValues(alpha: 0.85),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.14 : 0.05),
              blurRadius: 20,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image Header
            SizedBox(
              height: 176, // h-44
              width: double.infinity,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Container(
                    color: theme.colorScheme.primaryContainer,
                    child: Icon(
                      Icons.image_outlined,
                      size: 48,
                      color: theme.colorScheme.onPrimaryContainer.withValues(alpha: 0.5),
                    ),
                  ),
                  // Gradient overlay
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withValues(alpha: 0.1),
                          Colors.transparent,
                          Colors.black.withValues(alpha: 0.4),
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    top: 16,
                    left: 16,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: isDark
                            ? theme.colorScheme.surface.withValues(alpha: 0.9)
                            : tokens.palette.paper.withValues(alpha: 0.9),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        'NEXT ACTION • ${currentAction.context.toUpperCase()}',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: theme.colorScheme.primary,
                          letterSpacing: -0.5,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            // Content
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    currentAction.title,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    currentAction.description,
                    style: TextStyle(
                      fontSize: 14,
                      color: tokens.palette.textSecondary,
                      height: 1.6,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: onCompleted,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: theme.colorScheme.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 0,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.play_circle_fill, size: 20),
                              const SizedBox(width: 8),
                              Text(
                                'Start ${currentAction.context}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      OutlinedButton(
                        onPressed: onSkip,
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          side: BorderSide(
                            color: theme.colorScheme.outline.withValues(alpha: 0.2),
                          ),
                        ),
                        child: const Icon(Icons.skip_next, size: 20),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
