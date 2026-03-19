import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:confetti/confetti.dart';
import '../../../today/domain/models/daily_anchors.dart';
import 'breathing_meditation_widget.dart';

class PrayerGuideDialog extends ConsumerStatefulWidget {
  const PrayerGuideDialog({
    super.key,
    required this.virtue,
    required this.onMarkDone,
    this.showQuickStart = true,
  });

  final Virtue virtue;
  final VoidCallback onMarkDone;
  final bool showQuickStart;

  static void show(BuildContext context, Virtue virtue, VoidCallback onMarkDone, {bool showQuickStart = true}) {
    showDialog(
      context: context,
      builder: (context) => PrayerGuideDialog(
        virtue: virtue,
        onMarkDone: onMarkDone,
        showQuickStart: showQuickStart,
      ),
    );
  }

  @override
  ConsumerState<PrayerGuideDialog> createState() => _PrayerGuideDialogState();
}

class _PrayerGuideDialogState extends ConsumerState<PrayerGuideDialog> {
  bool _showBreathing = false;
  late ConfettiController _confettiController;

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(duration: const Duration(seconds: 2));
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  void _showConfettiAndComplete() {
    // Trigger confetti animation first
    _confettiController.play();
    
    // Close dialog after a short delay to let confetti show
    Future.delayed(const Duration(milliseconds: 800), () {
      if (mounted) {
        Navigator.of(context).pop();
      }
    });
    
    // Mark the prayer as done
    widget.onMarkDone();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final virtueColor = _getVirtueColor(widget.virtue.type, theme);

    // Show breathing meditation first if requested
    if (_showBreathing) {
      return Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          padding: const EdgeInsets.all(24),
          child: BreathingMeditationWidget(
            onComplete: () {
              setState(() {
                _showBreathing = false;
              });
            },
          ),
        ),
      );
    }

    return Stack(
      alignment: Alignment.topCenter,
      children: [
        Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  virtueColor.withValues(alpha: 0.1),
                  theme.colorScheme.surface.withValues(alpha: 0.8),
                ],
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Quick Start Options (only show if enabled)
                if (widget.showQuickStart) ...[
                  _buildQuickStartOptions(context, virtueColor),
                  const SizedBox(height: 24),
                ],
                
                // Header with virtue icon and title
                Row(
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: virtueColor.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: virtueColor.withValues(alpha: 0.3),
                          width: 2,
                        ),
                      ),
                      child: Icon(
                        _getVirtueIcon(widget.virtue.type),
                        color: virtueColor,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Prayer Guide',
                            style: theme.textTheme.titleLarge?.copyWith(
                              color: virtueColor,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            widget.virtue.type.title,
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: Icon(
                        Icons.close_rounded,
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 24),
                
                // Scripture reference
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: virtueColor.withValues(alpha: 0.2),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.menu_book_rounded,
                        color: virtueColor,
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          widget.virtue.scriptureReference,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontStyle: FontStyle.italic,
                            color: virtueColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 20),
                
                // Focus prompt
                Text(
                  'Today\'s Focus',
                  style: theme.textTheme.labelMedium?.copyWith(
                    fontSize: 14,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  widget.virtue.focusPrompt,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    height: 1.4,
                  ),
                ),
                
                const SizedBox(height: 20),
                
                // Prayer guide steps
                Text(
                  'Quick Prayer Guide',
                  style: theme.textTheme.labelMedium?.copyWith(
                    fontSize: 14,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                ),
                const SizedBox(height: 12),
                
                ..._buildPrayerSteps(context, widget.virtue.type),
                
                const SizedBox(height: 24),
                
                // Action buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => _showSkipConfirmation(context),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(
                            color: theme.colorScheme.outline.withValues(alpha: 0.5),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: Text(
                          'Skip',
                          style: theme.textTheme.labelLarge?.copyWith(
                            color: theme.colorScheme.onSurface,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton(
                        onPressed: () {
                          _showConfettiAndComplete();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: virtueColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: Text(
                          'Mark as Done',
                          style: theme.textTheme.labelLarge?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
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
              virtueColor,
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

  List<Widget> _buildPrayerSteps(BuildContext context, VirtueType virtueType) {
    final theme = Theme.of(context);
    final steps = _getPrayerSteps(virtueType);
    
    return steps.asMap().entries.map((entry) {
      final index = entry.key;
      final step = entry.value;
      
      return Padding(
        padding: EdgeInsets.only(bottom: index < steps.length - 1 ? 12 : 0),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface.withValues(alpha: 0.6),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: theme.colorScheme.outline.withValues(alpha: 0.1),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: _getVirtueColor(virtueType, theme).withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    '${index + 1}',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: _getVirtueColor(virtueType, theme),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  step,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontSize: 14,
                    height: 1.3,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }).toList();
  }

  List<String> _getPrayerSteps(VirtueType virtueType) {
    switch (virtueType) {
      case VirtueType.humility:
        return [
          'Begin by acknowledging God\'s sovereignty over your life',
          'Ask for the wisdom to see and serve Christ in others',
          'Pray for the strength to surrender your will to God',
          'Close by thanking God for His grace and guidance',
        ];
      case VirtueType.love:
        return [
          'Start by thanking God for His unconditional love',
          'Ask God to fill your heart with compassion for others',
          'Pray for opportunities to serve and bless someone today',
          'Close by asking for strength to love as Christ loves',
        ];
      case VirtueType.faith:
        return [
          'Begin by declaring your trust in God\'s promises',
          'Ask for courage to step out in faith despite uncertainty',
          'Pray for increased faith in God\'s provision and timing',
          'Close by committing to obey God\'s guidance today',
        ];
      case VirtueType.knowledge:
        return [
          'Start by asking God for wisdom and discernment',
          'Pray for clarity in understanding His Word and will',
          'Ask for the wisdom to humbly learn from others and experiences',
          'Close by committing to seek understanding before acting',
        ];
    }
  }

  IconData _getVirtueIcon(VirtueType virtueType) {
    switch (virtueType) {
      case VirtueType.humility:
        return Icons.self_improvement_rounded;
      case VirtueType.love:
        return Icons.favorite_rounded;
      case VirtueType.faith:
        return Icons.lightbulb_rounded;
      case VirtueType.knowledge:
        return Icons.school_rounded;
    }
  }

  Color _getVirtueColor(VirtueType virtue, ThemeData theme) {
    switch (virtue) {
      case VirtueType.humility:
        return const Color(0xFF8B5E3C); // Brown
      case VirtueType.love:
        return const Color(0xFFC85F4B); // Red
      case VirtueType.faith:
        return const Color(0xFF638B6C); // Green
      case VirtueType.knowledge:
        return const Color(0xFF4A6FA5); // Blue
    }
  }

  void _showSkipConfirmation(BuildContext context) {
    final theme = Theme.of(context);
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              Icons.info_outline_rounded,
              color: theme.colorScheme.primary,
              size: 24,
            ),
            const SizedBox(width: 12),
            Text(
              'Quick Prayer',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'This takes less than 2 minutes and there\'s more to gain in doing it than in skipping it.',
              style: theme.textTheme.bodyMedium?.copyWith(
                height: 1.4,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'You can simply close your eyes for a brief moment and pray God increases your humility and ability to see and serve him in others.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(); // Close skip warning first
              _showConfettiAndComplete(); // Then show confetti and close main dialog
            },
            child: Text(
              'Done',
              style: TextStyle(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(); // Close confirmation
              Navigator.of(context).pop(); // Close prayer guide
            },
            child: Text(
              'Skip anyway',
              style: TextStyle(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStartOptions(BuildContext context, Color virtueColor) {
    final theme = Theme.of(context);
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: virtueColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: virtueColor.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Choose Your Prayer Style',
            style: theme.textTheme.titleMedium?.copyWith(
              color: virtueColor,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          
          // Quick Start Option
          InkWell(
            onTap: () {
              setState(() {
                _showBreathing = true;
              });
            },
            borderRadius: BorderRadius.circular(8),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface.withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.timer_rounded,
                    color: virtueColor,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Quick Start (2 min)',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          'Breathing + brief prayer',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.arrow_forward_ios_rounded,
                    color: virtueColor,
                    size: 16,
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 8),
          
          // Full Guide Option
          InkWell(
            onTap: () {
              // Continue with full guide (no action needed)
            },
            borderRadius: BorderRadius.circular(8),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: virtueColor.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.menu_book_rounded,
                    color: virtueColor,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Full Guide (5 min)',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          'Complete prayer with steps',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.check_circle_rounded,
                    color: virtueColor,
                    size: 16,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
