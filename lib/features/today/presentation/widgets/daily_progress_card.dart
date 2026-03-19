import 'package:flutter/material.dart';

import '../../../../../core/theme/app_text_styles.dart';
import '../../domain/models/daily_anchors.dart';

class DailyProgressCard extends StatelessWidget {
  const DailyProgressCard({
    super.key,
    required this.anchors,
    required this.onTap,
  });

  final DailyAnchors anchors;
  final VoidCallback onTap;

  int _calculateCompletedAnchors() {
    int count = 0;
    if (anchors.coreVirtue.isCompleted) count++;
    if (anchors.habit.isCompleted) count++;
    if (anchors.energyAction.isCompleted) count++;
    return count;
  }

  @override
  Widget build(BuildContext context) {
    final completedCount = _calculateCompletedAnchors();

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.6),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'DAILY PROGRESS',
                    style: Theme.of(context).textTheme.sectionHeader.copyWith(
                          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
                          letterSpacing: 1.5,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$completedCount of 3 completed',
                    style: Theme.of(context).textTheme.cardTitle,
                  ),
                ],
              ),
              SizedBox(
                width: 48,
                height: 48,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    CircularProgressIndicator(
                      value: completedCount / 3,
                      backgroundColor: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
                      valueColor: AlwaysStoppedAnimation<Color>(Theme.of(context).colorScheme.primary),
                      strokeWidth: 4,
                      strokeCap: StrokeCap.round,
                    ),
                    Center(
                      child: Text(
                        '${((completedCount / 3) * 100).toInt()}%',
                        style: Theme.of(context).textTheme.chipText,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
