import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/services/haptic_service.dart';
import '../../../../core/theme/app_animations.dart';
import '../../application/onboarding_notifier.dart';

/// Step 3: Your Identity — 3-question mini-assessment with inline archetype reveal.
///
/// Supports an optional 4th tiebreaker question when the top 2 archetypes
/// are too close after the first 3 questions.
class DiscoverIdentityView extends ConsumerStatefulWidget {
  const DiscoverIdentityView({super.key});

  @override
  ConsumerState<DiscoverIdentityView> createState() =>
      _DiscoverIdentityViewState();
}

class _DiscoverIdentityViewState extends ConsumerState<DiscoverIdentityView>
    with SingleTickerProviderStateMixin {
  int _currentQuestion = 0;
  late final AnimationController _revealController;
  late final Animation<double> _revealScale;
  late final Animation<double> _revealFade;
  bool _revealTriggered = false;
  bool _showingTiebreaker = false;

  @override
  void initState() {
    super.initState();
    _revealController = AnimationController(
      vsync: this,
      duration: AppAnimations.reveal,
    );
    _revealScale = Tween<double>(begin: 0.7, end: 1.0).animate(
      CurvedAnimation(parent: _revealController, curve: AppAnimations.bounceCurve),
    );
    _revealFade = CurvedAnimation(
      parent: _revealController,
      curve: const Interval(0.2, 1.0, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _revealController.dispose();
    super.dispose();
  }

  void _triggerReveal() {
    if (!_revealTriggered) {
      _revealTriggered = true;
      HapticService.milestone();
      _revealController.forward();
    }
  }

  /// Returns a confidence label based on the assessment score spread.
  String _confidenceLabel(double confidence) {
    if (confidence >= 0.5) return 'Strong match!';
    if (confidence >= 0.3) return 'Great match!';
    return 'Good match';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final state = ref.watch(onboardingProvider);
    final notifier = ref.read(onboardingProvider.notifier);
    const questions = OnboardingNotifier.miniAssessmentQuestions;

    // Determine total questions including possible tiebreaker
    final baseQuestionCount = questions.length; // 3

    // Determine which question to show
    final MiniAssessmentQuestion question;
    if (_showingTiebreaker) {
      final tiebreaker = notifier.getTiebreakerQuestion();
      if (tiebreaker != null) {
        question = tiebreaker;
      } else {
        question = questions[_currentQuestion.clamp(0, baseQuestionCount - 1)];
      }
    } else if (_currentQuestion == 2) {
      question = notifier.getDynamicQuestion3();
    } else {
      question = questions[_currentQuestion.clamp(0, baseQuestionCount - 1)];
    }

    final archetype = notifier.primaryArchetype;

    // Check if current question has been answered
    final questionIndex = _showingTiebreaker ? 3 : _currentQuestion;
    final hasAnswer = state.miniAssessmentAnswers.length > questionIndex &&
        state.miniAssessmentAnswers[questionIndex] >= 0;
    final selectedIndex =
        hasAnswer ? state.miniAssessmentAnswers[questionIndex] : -1;

    // Assessment is complete when archetype is determined AND no tiebreaker needed
    final hasThreeAnswers = state.miniAssessmentAnswers.length >= 3 &&
        state.miniAssessmentAnswers.take(3).every((a) => a >= 0);
    final needsTiebreaker = hasThreeAnswers && notifier.needsTiebreaker;
    final assessmentComplete = hasThreeAnswers &&
        archetype != null &&
        !needsTiebreaker &&
        !_showingTiebreaker;

    // Check if tiebreaker just completed
    final tiebreakerComplete = _showingTiebreaker &&
        state.miniAssessmentAnswers.length >= 4 &&
        state.miniAssessmentAnswers[3] >= 0 &&
        archetype != null;

    // Trigger reveal when fully done
    if (assessmentComplete || tiebreakerComplete) {
      _triggerReveal();
    }

    // Auto-show tiebreaker after Q3 completes
    if (needsTiebreaker && !_showingTiebreaker && !state.tiebreakerShown) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() {
            _showingTiebreaker = true;
          });
          notifier.markTiebreakerShown();
        }
      });
    }

    final totalQuestions = _showingTiebreaker ? baseQuestionCount + 1 : baseQuestionCount;
    final displayQuestionNum = _showingTiebreaker ? baseQuestionCount + 1 : _currentQuestion + 1;

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),
          // Question progress
          Row(
            children: [
              for (var i = 0; i < totalQuestions; i++) ...[
                if (i > 0) const SizedBox(width: 8),
                Expanded(
                  child: AnimatedContainer(
                    duration: AppAnimations.fast,
                    height: 4,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(2),
                      color: i < displayQuestionNum
                          ? theme.colorScheme.primary
                          : theme.colorScheme.onSurface
                              .withValues(alpha: 0.1),
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 8),
          Text(
            _showingTiebreaker
                ? 'One last thought...'
                : 'Question $displayQuestionNum of $totalQuestions',
            style: textTheme.labelMedium?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            question.question,
            style: textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w600,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 24),
          // Answer options
          ...List.generate(question.options.length, (index) {
            final isSelected = selectedIndex == index;
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () {
                    HapticService.selection();
                    notifier.answerMiniAssessment(questionIndex, index);
                    // Auto-advance after a short delay
                    if (!_showingTiebreaker && _currentQuestion < baseQuestionCount - 1) {
                      Future.delayed(const Duration(milliseconds: 400), () {
                        if (mounted) {
                          setState(() {
                            _currentQuestion++;
                          });
                        }
                      });
                    }
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? theme.colorScheme.primary
                              .withValues(alpha: 0.1)
                          : theme.colorScheme.onSurface
                              .withValues(alpha: 0.03),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected
                            ? theme.colorScheme.primary
                                .withValues(alpha: 0.4)
                            : theme.colorScheme.onSurface
                                .withValues(alpha: 0.1),
                        width: isSelected ? 1.5 : 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isSelected
                                ? theme.colorScheme.primary
                                : Colors.transparent,
                            border: Border.all(
                              color: isSelected
                                  ? theme.colorScheme.primary
                                  : theme.colorScheme.onSurface
                                      .withValues(alpha: 0.3),
                              width: 1.5,
                            ),
                          ),
                          child: isSelected
                              ? const Icon(Icons.check,
                                  size: 16, color: Colors.white)
                              : Center(
                                  child: Text(
                                    String.fromCharCode(65 + index),
                                    style: textTheme.labelMedium?.copyWith(
                                      color: theme.colorScheme.onSurface
                                          .withValues(alpha: 0.5),
                                    ),
                                  ),
                                ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Text(
                            question.options[index],
                            style: textTheme.bodyMedium?.copyWith(
                              fontWeight: isSelected
                                  ? FontWeight.w600
                                  : FontWeight.w400,
                              color: isSelected
                                  ? theme.colorScheme.primary
                                  : theme.colorScheme.onSurface
                                      .withValues(alpha: 0.8),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }),
          // Back button for questions 2+ (not during tiebreaker)
          if (_currentQuestion > 0 && !assessmentComplete && !tiebreakerComplete && !_showingTiebreaker) ...[
            const SizedBox(height: 8),
            Center(
              child: TextButton.icon(
                onPressed: () {
                  setState(() {
                    _currentQuestion--;
                  });
                },
                icon: const Icon(Icons.arrow_back, size: 16),
                label: const Text('Previous question'),
              ),
            ),
          ],
          // Inline archetype reveal
          if (assessmentComplete || tiebreakerComplete) ...[
            const SizedBox(height: 32),
            AnimatedBuilder(
              animation: _revealController,
              builder: (context, child) {
                return Opacity(
                  opacity: _revealFade.value,
                  child: child,
                );
              },
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      theme.colorScheme.primary.withValues(alpha: 0.08),
                      theme.colorScheme.primary.withValues(alpha: 0.02),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color:
                        theme.colorScheme.primary.withValues(alpha: 0.2),
                  ),
                ),
                child: Column(
                  children: [
                    // Animated archetype badge
                    ScaleTransition(
                      scale: _revealScale,
                      child: Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              theme.colorScheme.primary
                                  .withValues(alpha: 0.15),
                              theme.colorScheme.primary
                                  .withValues(alpha: 0.05),
                            ],
                          ),
                          border: Border.all(
                            color: theme.colorScheme.primary
                                .withValues(alpha: 0.3),
                            width: 2,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            archetype.name[0],
                            style: textTheme.displaySmall?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: theme.colorScheme.primary,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'You are a',
                      style: textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurface
                            .withValues(alpha: 0.5),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      archetype.name,
                      style: textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary
                            .withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        'The ${archetype.identity}',
                        style: textTheme.labelLarge?.copyWith(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Confidence indicator
                    Text(
                      _confidenceLabel(state.assessmentConfidence),
                      style: textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.primary.withValues(alpha: 0.7),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Strengths
                    _buildSection(
                      context,
                      icon: Icons.star_outline,
                      title: 'Your Strengths',
                      content: archetype.strengths,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(height: 14),
                    // Inversion strategy / spiritual path
                    if (archetype.inversionStrategy.isNotEmpty)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary
                              .withValues(alpha: 0.06),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: theme.colorScheme.primary
                                .withValues(alpha: 0.12),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.lightbulb_outline,
                                  size: 18,
                                  color: theme.colorScheme.primary,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Your Spiritual Path',
                                  style: textTheme.labelLarge?.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: theme.colorScheme.primary,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Text(
                              archetype.inversionStrategy,
                              style: textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurface
                                    .withValues(alpha: 0.7),
                                height: 1.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    const SizedBox(height: 10),
                    Text(
                      'Take the full assessment later for deeper insights.',
                      textAlign: TextAlign.center,
                      style: textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface
                            .withValues(alpha: 0.4),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildSection(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String content,
    required Color color,
  }) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: color),
              const SizedBox(width: 8),
              Text(
                title,
                style: theme.textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            content.replaceAll(';', '\n\u2022').replaceAll(', ', '\n\u2022 '),
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
