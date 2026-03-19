import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:confetti/confetti.dart';

import '../../../../core/di/app_providers.dart';
import '../../domain/models/daily_anchors.dart';
import '../../domain/models/commitment.dart';
import 'habit_growth_visualization.dart';

class EnhancedCommitmentCard extends ConsumerStatefulWidget {
  const EnhancedCommitmentCard({
    super.key,
    required this.anchor,
    required this.onTap,
    required this.timePeriod,
    this.commitment,
  });

  final Habit anchor;
  final VoidCallback onTap;
  final String timePeriod;
  final Commitment? commitment;

  @override
  ConsumerState<EnhancedCommitmentCard> createState() => _EnhancedCommitmentCardState();
}

class _EnhancedCommitmentCardState extends ConsumerState<EnhancedCommitmentCard> {
  late Timer _timer;
  Duration _timeRemaining = Duration.zero;
  late ConfettiController _confettiController;

  @override
  void initState() {
    super.initState();
    _updateTimeRemaining();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _updateTimeRemaining());
    _confettiController = ConfettiController(duration: const Duration(seconds: 2));
  }

  @override
  void dispose() {
    _timer.cancel();
    _confettiController.dispose();
    super.dispose();
  }

  void _updateTimeRemaining() {
    if (!mounted) return;
    
    setState(() {
      _timeRemaining = Duration.zero;
    });
  }

  void _showAbortDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Abort Commitment'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Are you sure you want to abort this commitment?'),
            const SizedBox(height: 16),
            Text(
              '"${widget.anchor.displayDescription}"',
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              // Mark as completed with failure
              ref.read(dailyAnchorsProvider.notifier).completeCommitment(succeeded: false);
            },
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Abort'),
          ),
        ],
      ),
    );
  }

  double get _progressPercent {
    return widget.anchor.adjustedCommitmentProgressPercent;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 360;
    
    return Stack(
      alignment: Alignment.topCenter,
      children: [
        InkWell(
          onTap: widget.onTap,
          borderRadius: BorderRadius.circular(32),
          child: Container(
            width: double.infinity,
            padding: EdgeInsets.all(isSmallScreen ? 20 : 28),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(32),
              border: Border.all(
                color: theme.colorScheme.primary.withValues(alpha: 0.3),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: theme.colorScheme.primary.withValues(alpha: 0.2),
                  blurRadius: 20,
                  spreadRadius: 0,
                ),
              ],
            ),
            child: Column(
              children: [
                // Header with time remaining
                Row(
                  children: [
                    // Growth visualization instead of static icon
                    HabitGrowthVisualization(
                      progress: _progressPercent,
                      isPaused: widget.anchor.isPaused,
                      size: isSmallScreen ? 48 : 56,
                    ),
                    SizedBox(width: isSmallScreen ? 16 : 20),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.timePeriod,
                            style: theme.textTheme.labelSmall?.copyWith(
                              fontSize: isSmallScreen ? 9 : 10,
                              letterSpacing: 2.5,
                              fontWeight: FontWeight.w700,
                              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                            ),
                          ),
                          SizedBox(height: isSmallScreen ? 2 : 4),
                          Text(
                            widget.anchor.adjustedTimeRemaining,
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontSize: isSmallScreen ? 18 : 20,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1.0,
                              color: widget.anchor.isPaused
                                  ? theme.colorScheme.outline
                                  : theme.colorScheme.onSurface,
                            ),
                          ),
                          
                          // Pause/Resume status indicator
                          if (widget.anchor.isPaused) ...[
                            SizedBox(height: isSmallScreen ? 2 : 4),
                            Text(
                              'PAUSED',
                              style: theme.textTheme.bodySmall?.copyWith(
                                fontSize: isSmallScreen ? 8 : 9,
                                fontWeight: FontWeight.w600,
                                color: theme.colorScheme.error,
                                letterSpacing: 1.5,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
                
                SizedBox(height: isSmallScreen ? 16 : 24),
                
                // Current focus card
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(isSmallScreen ? 16 : 24),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface.withValues(alpha: 0.9),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: theme.colorScheme.outline.withValues(alpha: 0.1),
                    ),
                  ),
                  child: Column(
                    children: [
                      Text(
                        '"${widget.anchor.displayDescription}"',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontSize: isSmallScreen ? 16 : 18,
                          fontWeight: FontWeight.w500,
                          letterSpacing: 0.5,
                          height: 1.4,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: isSmallScreen ? 16 : 20),
                      
                      // Progress bar
                      Container(
                        width: double.infinity,
                        height: 4,
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(2),
                        ),
                        child: FractionallySizedBox(
                          alignment: Alignment.centerLeft,
                          widthFactor: _progressPercent,
                          child: Container(
                            decoration: BoxDecoration(
                              color: _timeRemaining.inMinutes > 5 
                                  ? theme.colorScheme.primary
                                  : theme.colorScheme.error,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: isSmallScreen ? 8 : 12),
                      
                      // Progress text
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Progress',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                            ),
                          ),
                          Text(
                            '${(_progressPercent * 100).toInt()}%',
                            style: theme.textTheme.bodySmall?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: _timeRemaining.inMinutes > 5 
                                  ? theme.colorScheme.primary
                                  : theme.colorScheme.error,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                
                SizedBox(height: isSmallScreen ? 16 : 20),
                
                // Action buttons - only Complete and Abort when locked in
                Row(
                  children: [
                    // Abort button
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => _showAbortDialog(),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(
                            color: theme.colorScheme.error.withValues(alpha: 0.5),
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: EdgeInsets.symmetric(vertical: isSmallScreen ? 10 : 12),
                        ),
                        child: Text(
                          'Abort',
                          style: TextStyle(
                            color: theme.colorScheme.error,
                            fontWeight: FontWeight.w600,
                            fontSize: isSmallScreen ? 14 : 16,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: isSmallScreen ? 8 : 12),
                    // Complete button
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => _showCompletionDialog(),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: theme.colorScheme.primary,
                          foregroundColor: theme.colorScheme.onPrimary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: EdgeInsets.symmetric(vertical: isSmallScreen ? 10 : 12),
                        ),
                        child: Text(
                          'Complete',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: isSmallScreen ? 14 : 16,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        // Confetti overlay
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          height: 300,
          child: ConfettiWidget(
            confettiController: _confettiController,
            blastDirectionality: BlastDirectionality.explosive,
            particleDrag: 0.05,
            emissionFrequency: 0.05,
            numberOfParticles: 50,
            gravity: 0.1,
            colors: [
              theme.colorScheme.primary,
              Colors.amber,
              Colors.orange,
              Colors.pink,
              Colors.purple,
              Colors.blue,
            ],
            strokeWidth: 1,
            strokeColor: Colors.white,
          ),
        ),
      ],
    );
  }

  void _showConfettiAndComplete() {
    // Trigger confetti animation
    _confettiController.play();
    
    // Mark as completed with success after a short delay to let confetti show
    Future.delayed(const Duration(milliseconds: 500), () {
      ref.read(dailyAnchorsProvider.notifier).completeCommitment(succeeded: true);
    });
  }

  void _showCompletionDialog() {
    final hasElapsedRequiredTime = widget.anchor.isCommitmentComplete;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Complete Commitment'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!hasElapsedRequiredTime) ...[
              const Text('You must complete the full 4 hours before marking this as done.'),
              const SizedBox(height: 8),
              Text(
                'Time remaining: ${widget.anchor.adjustedTimeRemaining}',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 16),
            ] else ...[
              const Text('Did you complete your commitment?'),
              const SizedBox(height: 16),
              Text(
                '"${widget.anchor.displayDescription}"',
                style: Theme.of(context).textTheme.bodySmall,
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          if (hasElapsedRequiredTime)
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                // Show confetti and mark as completed with success
                _showConfettiAndComplete();
              },
              child: const Text('Yes, I did it!'),
            ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              // Mark as completed with failure
              ref.read(dailyAnchorsProvider.notifier).completeCommitment(succeeded: false);
            },
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            child: Text(hasElapsedRequiredTime ? 'Not yet' : 'End Early'),
          ),
        ],
      ),
    );
  }
}

class CommitmentDetailsDialog extends StatelessWidget {
  const CommitmentDetailsDialog({
    super.key,
    required this.habit,
    required this.commitment,
    required this.timeRemaining,
    required this.progressPercent,
  });

  final Habit habit;
  final Commitment? commitment;
  final Duration timeRemaining;
  final double progressPercent;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        padding: const EdgeInsets.all(24),
        constraints: const BoxConstraints(maxWidth: 400),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.task_alt_rounded,
                    color: theme.colorScheme.onPrimaryContainer,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Commitment Details',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        habit.displayTitle,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 24),
            
            // Progress section
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Time Remaining',
                        style: theme.textTheme.labelMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        _formatDuration(timeRemaining),
                        style: theme.textTheme.labelMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: timeRemaining.inMinutes > 5 
                              ? theme.colorScheme.primary
                              : theme.colorScheme.error,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    height: 6,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(3),
                    ),
                    child: FractionallySizedBox(
                      alignment: Alignment.centerLeft,
                      widthFactor: progressPercent,
                      child: Container(
                        decoration: BoxDecoration(
                          color: timeRemaining.inMinutes > 5 
                              ? theme.colorScheme.primary
                              : theme.colorScheme.error,
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${(progressPercent * 100).toInt()}% Complete',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 20),
            
            // Description
            Text(
              'Focus',
              style: theme.textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              habit.description,
              style: theme.textTheme.bodyMedium,
            ),
            
            const SizedBox(height: 20),
            
            // Tips section
            if (commitment != null && commitment!.tips.isNotEmpty) ...[
              Text(
                'Tips & Guidance',
                style: theme.textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              ...commitment!.tips.asMap().entries.map((entry) {
                final index = entry.key;
                final tip = entry.value;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 20,
                        height: 20,
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary,
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            '${index + 1}',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onPrimary,
                              fontWeight: FontWeight.w600,
                              fontSize: 10,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          tip,
                          style: theme.textTheme.bodySmall,
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],
            
            const SizedBox(height: 24),
            
            // Close button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.primary,
                  foregroundColor: theme.colorScheme.onPrimary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child: const Text(
                  'Got it',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;
    
    if (hours > 0) {
      return '${hours}H ${minutes}M';
    } else {
      return '${minutes}M';
    }
  }
}
