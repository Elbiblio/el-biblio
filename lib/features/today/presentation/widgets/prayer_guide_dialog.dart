import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:confetti/confetti.dart';
import '../../../today/domain/models/daily_anchors.dart';
import '../../../commitments/domain/models/commitment_journey.dart';
import 'breathing_meditation_widget.dart';

/// Full-screen 3-step morning prayer guide.
///
/// Step 1: Breathe & Center (breathing animation + greeting)
/// Step 2: Pray (scripture + focus + prayer bullets)
/// Step 3: Commit (focus prompt + "I commit" button)
///
/// When an active commitment journey exists, the prayer guide reflects
/// that journey's content instead of generic virtue-based prayers.
class PrayerGuideDialog extends ConsumerStatefulWidget {
  const PrayerGuideDialog({
    super.key,
    required this.virtue,
    required this.onMarkDone,
    this.showQuickStart = true,
    this.activeJourney,
    this.commitmentJourney,
  });

  final Virtue virtue;
  final VoidCallback onMarkDone;
  final bool showQuickStart;
  final ActiveJourney? activeJourney;
  final CommitmentJourney? commitmentJourney;

  static void show(
    BuildContext context,
    Virtue virtue,
    VoidCallback onMarkDone, {
    bool showQuickStart = true,
    ActiveJourney? activeJourney,
    CommitmentJourney? commitmentJourney,
  }) {
    Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        pageBuilder: (context, animation, secondaryAnimation) =>
            PrayerGuideDialog(
              virtue: virtue,
              onMarkDone: onMarkDone,
              showQuickStart: showQuickStart,
              activeJourney: activeJourney,
              commitmentJourney: commitmentJourney,
            ),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    );
  }

  @override
  ConsumerState<PrayerGuideDialog> createState() => _PrayerGuideDialogState();
}

class _PrayerGuideDialogState extends ConsumerState<PrayerGuideDialog> {
  late final PageController _pageController;
  late final ConfettiController _confettiController;
  int _currentPage = 0;
  static const _totalPages = 3;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _confettiController = ConfettiController(
      duration: const Duration(seconds: 2),
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    _confettiController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentPage < _totalPages - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    }
  }

  void _complete() {
    _confettiController.play();
    widget.onMarkDone();
    Future.delayed(const Duration(milliseconds: 1200), () {
      if (mounted) Navigator.of(context).pop();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final virtueColor = _getVirtueColor(widget.virtue.type);
    final greeting = _timeGreeting();

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: Stack(
        children: [
          // Background gradient
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  virtueColor.withValues(alpha: 0.08),
                  theme.colorScheme.surface,
                ],
              ),
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                // Top bar
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: Icon(
                          Icons.close_rounded,
                          color: theme.colorScheme.onSurface.withValues(
                            alpha: 0.5,
                          ),
                        ),
                      ),
                      // 3 dots
                      Row(
                        children: List.generate(_totalPages, (index) {
                          final isActive = index == _currentPage;
                          return AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            margin: const EdgeInsets.symmetric(horizontal: 3),
                            width: isActive ? 24 : 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: isActive
                                  ? virtueColor
                                  : virtueColor.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(4),
                            ),
                          );
                        }),
                      ),
                      TextButton(
                        onPressed: _complete,
                        child: Text(
                          'Done',
                          style: TextStyle(
                            color: theme.colorScheme.onSurface.withValues(
                              alpha: 0.5,
                            ),
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // 3 pages
                Expanded(
                  child: PageView(
                    controller: _pageController,
                    onPageChanged: (index) =>
                        setState(() => _currentPage = index),
                    physics: const ClampingScrollPhysics(),
                    children: [
                      _buildStep1Breathe(theme, virtueColor, greeting),
                      _buildStep2Pray(theme, virtueColor),
                      _buildStep3Commit(theme, virtueColor),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Confetti
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: ConfettiWidget(
              confettiController: _confettiController,
              blastDirectionality: BlastDirectionality.explosive,
              particleDrag: 0.05,
              emissionFrequency: 0.05,
              numberOfParticles: 50,
              gravity: 0.1,
              colors: [virtueColor, Colors.amber, Colors.orange, Colors.pink],
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Step 1: Breathe & Center
  // ---------------------------------------------------------------------------

  Widget _buildStep1Breathe(
    ThemeData theme,
    Color virtueColor,
    String greeting,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Spacer(flex: 2),

          Text(
            greeting,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
            ),
          ),

          const SizedBox(height: 8),

          Text(
            'Take a deep breath.\nLet everything else go.',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 40),

          BreathingMeditationWidget(
            onComplete: () {
              Future.delayed(const Duration(milliseconds: 400), _nextPage);
            },
          ),

          const Spacer(flex: 2),

          TextButton(
            onPressed: _nextPage,
            child: Text(
              'Skip',
              style: TextStyle(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
              ),
            ),
          ),

          const SizedBox(height: 24),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Step 2: Pray (scripture + focus + prayer bullets)
  // ---------------------------------------------------------------------------

  Widget _buildStep2Pray(ThemeData theme, Color virtueColor) {
    final steps = _getContextualPrayerSteps();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        children: [
          const Spacer(flex: 1),

          // Virtue icon
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: virtueColor.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(
              _getVirtueIcon(widget.virtue.type),
              color: virtueColor,
              size: 28,
            ),
          ),

          const SizedBox(height: 16),

          // Scripture or journey title
          Text(
            widget.commitmentJourney != null
                ? widget.commitmentJourney!.title
                : widget.virtue.scriptureReference,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontStyle: FontStyle.italic,
              color: virtueColor,
              fontWeight: FontWeight.w600,
            ),
          ),

          const SizedBox(height: 8),

          Text(
            widget.commitmentJourney != null
                ? widget.commitmentJourney!.description
                : widget.virtue.focusPrompt,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w600,
              height: 1.3,
              color: theme.colorScheme.onSurface,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 24),

          // Prayer bullets
          ...steps.map(
            (step) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    margin: const EdgeInsets.only(top: 6),
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: virtueColor.withValues(alpha: 0.6),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      step,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        height: 1.4,
                        color: theme.colorScheme.onSurface.withValues(
                          alpha: 0.75,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 8),

          Text(
            'Pray silently or aloud.',
            style: theme.textTheme.bodySmall?.copyWith(
              fontStyle: FontStyle.italic,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
            ),
          ),

          const Spacer(flex: 2),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _nextPage,
              style: ElevatedButton.styleFrom(
                backgroundColor: virtueColor.withValues(alpha: 0.15),
                foregroundColor: virtueColor,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: Text(
                'I have prayed',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: virtueColor,
                ),
              ),
            ),
          ),

          const SizedBox(height: 24),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Step 3: Commit
  // ---------------------------------------------------------------------------

  Widget _buildStep3Commit(ThemeData theme, Color virtueColor) {
    final journey = widget.commitmentJourney;
    final focusText = journey?.baseRequirement != null
        ? journey!.baseRequirement!
        : widget.virtue.focusPrompt;
    final titleText = journey != null ? 'Your Commitment' : 'Your Focus Today';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Spacer(flex: 2),

          Icon(Icons.favorite_rounded, color: virtueColor, size: 48),

          const SizedBox(height: 24),

          Text(
            titleText,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurface,
            ),
          ),

          const SizedBox(height: 16),

          Text(
            focusText,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w500,
              height: 1.4,
              color: virtueColor,
            ),
            textAlign: TextAlign.center,
          ),

          if (widget.activeJourney != null && journey != null) ...[
            const SizedBox(height: 12),
            Text(
              'Day ${widget.activeJourney!.currentDay} of ${journey.duration.days}',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
              ),
            ),
          ],

          const Spacer(flex: 3),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _complete,
              style: ElevatedButton.styleFrom(
                backgroundColor: virtueColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 18),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: Text(
                'I commit to this',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ),

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  String _timeGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  /// Returns prayer steps that match the user's active commitment journey
  /// when one exists, falling back to generic virtue-based prayers.
  List<String> _getContextualPrayerSteps() {
    final journey = widget.commitmentJourney;
    if (journey != null) {
      return [
        if (journey.baseRequirement != null) journey.baseRequirement!,
        ...journey.tips,
      ];
    }
    return _getPrayerSteps(widget.virtue.type);
  }

  List<String> _getPrayerSteps(VirtueType virtueType) {
    switch (virtueType) {
      case VirtueType.humility:
        return [
          'Acknowledge God\'s sovereignty over your life',
          'Ask for wisdom to see Christ in others',
          'Thank God for His grace today',
        ];
      case VirtueType.love:
        return [
          'Thank God for His unconditional love',
          'Ask to be filled with compassion for others',
          'Pray for one person to bless today',
        ];
      case VirtueType.faith:
        return [
          'Declare your trust in God\'s promises',
          'Ask for courage despite uncertainty',
          'Commit to follow God\'s lead today',
        ];
      case VirtueType.knowledge:
        return [
          'Ask God for wisdom and discernment',
          'Pray for understanding of His will',
          'Commit to listen before reacting',
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

  Color _getVirtueColor(VirtueType virtue) {
    switch (virtue) {
      case VirtueType.humility:
        return const Color(0xFF8B5E3C);
      case VirtueType.love:
        return const Color(0xFFC85F4B);
      case VirtueType.faith:
        return const Color(0xFF638B6C);
      case VirtueType.knowledge:
        return const Color(0xFF4A6FA5);
    }
  }
}
