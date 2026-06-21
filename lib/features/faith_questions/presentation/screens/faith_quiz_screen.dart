import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../../core/di/app_providers.dart';
import '../../application/faith_questions_notifier.dart';
import '../../application/faith_questions_state.dart';
import '../../data/faith_quiz_level_catalog.dart';
import '../../../games/presentation/widgets/quiz_option_card.dart';

class FaithQuizScreen extends ConsumerWidget {
  const FaithQuizScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(faithQuestionsProvider);

    // Listen for quiz completion to navigate to results
    ref.listen<FaithQuestionsMode>(
      faithQuestionsProvider.select((s) => s.mode),
      (prev, next) {
        if (next == FaithQuestionsMode.quizResult) {
          context.push('/faith-questions/quiz-results');
        }
      },
    );

    if (state.mode == FaithQuestionsMode.activeQuiz) {
      return _ActiveQuizView(state: state, ref: ref);
    }

    return _LevelSelectionView(state: state, ref: ref);
  }
}

// ── Level Selection ─────────────────────────────────────────────────────

class _LevelSelectionView extends StatelessWidget {
  final FaithQuestionsState state;
  final WidgetRef ref;

  const _LevelSelectionView({required this.state, required this.ref});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    const levels = FaithQuizLevelCatalog.allLevels;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new, size: 20),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Faith Quiz',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                'Complete each level with 7/10 correct to unlock the next',
                style: TextStyle(
                  fontSize: 13,
                  color: isDark ? Colors.white54 : Colors.black45,
                ),
              ),
            ),
            const SizedBox(height: 16),

            Expanded(
              child: ListView.builder(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                itemCount: levels.length,
                itemBuilder: (context, index) {
                  final level = levels[index];
                  final isCompleted =
                      state.progress.completedLevels.contains(level.level);
                  final isUnlocked =
                      state.progress.isLevelUnlocked(level.level);

                  // Tier color
                  Color tierColor;
                  String tierLabel;
                  if (level.level <= 3) {
                    tierColor = const Color(0xFF22C55E);
                    tierLabel = 'Foundational';
                  } else if (level.level <= 6) {
                    tierColor = const Color(0xFF3B82F6);
                    tierLabel = 'Intermediate';
                  } else if (level.level <= 8) {
                    tierColor = const Color(0xFFA855F7);
                    tierLabel = 'Advanced';
                  } else {
                    tierColor = const Color(0xFFD97706);
                    tierLabel = 'Scholar';
                  }

                  return _LevelCard(
                    level: level.level,
                    title: level.title,
                    description: level.description,
                    tierLabel: tierLabel,
                    tierColor: tierColor,
                    xpReward: level.xpReward,
                    isCompleted: isCompleted,
                    isUnlocked: isUnlocked,
                    isDark: isDark,
                    onTap: isUnlocked
                        ? () => ref
                            .read(faithQuestionsProvider.notifier)
                            .startQuizLevel(level.level)
                        : null,
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LevelCard extends StatelessWidget {
  final int level;
  final String title;
  final String description;
  final String tierLabel;
  final Color tierColor;
  final int xpReward;
  final bool isCompleted;
  final bool isUnlocked;
  final bool isDark;
  final VoidCallback? onTap;

  const _LevelCard({
    required this.level,
    required this.title,
    required this.description,
    required this.tierLabel,
    required this.tierColor,
    required this.xpReward,
    required this.isCompleted,
    required this.isUnlocked,
    required this.isDark,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final opacity = isUnlocked ? 1.0 : 0.45;

    return Opacity(
      opacity: opacity,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                tierColor.withValues(alpha: isDark ? 0.2 : 0.08),
                tierColor.withValues(alpha: isDark ? 0.08 : 0.02),
              ],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isCompleted
                  ? Colors.green.withValues(alpha: 0.5)
                  : tierColor.withValues(alpha: 0.2),
            ),
          ),
          child: Row(
            children: [
              // Level number circle
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isCompleted
                      ? Colors.green.withValues(alpha: 0.2)
                      : tierColor.withValues(alpha: 0.15),
                ),
                alignment: Alignment.center,
                child: isCompleted
                    ? const Icon(Icons.check, color: Colors.green, size: 22)
                    : isUnlocked
                        ? Text(
                            '$level',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                              color: tierColor,
                            ),
                          )
                        : Icon(LucideIcons.lock,
                            size: 18, color: Colors.grey.shade500),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          title,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: isDark ? Colors.white : Colors.black87,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: tierColor.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            tierLabel,
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                              color: tierColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      description,
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? Colors.white54 : Colors.black45,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                children: [
                  Icon(Icons.bolt, size: 16, color: Colors.amber.shade600),
                  Text(
                    '$xpReward',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white60 : Colors.black45,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Active Quiz ─────────────────────────────────────────────────────────

class _ActiveQuizView extends StatelessWidget {
  final FaithQuestionsState state;
  final WidgetRef ref;

  const _ActiveQuizView({required this.state, required this.ref});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final notifier = ref.read(faithQuestionsProvider.notifier);
    const themeColor = Color(0xFFD97706);

    if (state.quizQuestions.isEmpty) {
      return Scaffold(
        body: Center(
          child: Text(
            'No questions loaded',
            style: TextStyle(color: isDark ? Colors.white54 : Colors.black45),
          ),
        ),
      );
    }

    final question = state.quizQuestions[state.currentQuestionIndex];
    final showResult = state.showingResult;
    final questionNumber = state.currentQuestionIndex + 1;
    final totalQuestions = state.quizQuestions.length;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              themeColor.withValues(alpha: isDark ? 0.15 : 0.08),
              isDark ? const Color(0xFF0F172A) : Colors.white,
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.close, size: 22),
                      onPressed: () {
                        notifier.backToHub();
                      },
                    ),
                    Expanded(
                      child: Column(
                        children: [
                          Text(
                            'Level ${state.activeQuizLevel}',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: isDark ? Colors.white70 : Colors.black54,
                            ),
                          ),
                          const SizedBox(height: 4),
                          // Progress dots
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: List.generate(totalQuestions, (i) {
                              Color dotColor;
                              if (i < state.currentQuestionIndex) {
                                dotColor = themeColor;
                              } else if (i == state.currentQuestionIndex) {
                                dotColor =
                                    themeColor.withValues(alpha: 0.5);
                              } else {
                                dotColor = isDark
                                    ? Colors.grey.shade700
                                    : Colors.grey.shade300;
                              }
                              return Container(
                                margin:
                                    const EdgeInsets.symmetric(horizontal: 3),
                                width: i == state.currentQuestionIndex
                                    ? 20
                                    : 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  color: dotColor,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              );
                            }),
                          ),
                        ],
                      ),
                    ),
                    // Score
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: themeColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.star, size: 14, color: themeColor),
                          const SizedBox(width: 4),
                          Text(
                            '${state.sessionCorrect}/$totalQuestions',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                            ).copyWith(color: themeColor),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Question content
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'QUESTION $questionNumber',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 2,
                        ).copyWith(color: themeColor),
                      ),
                      const SizedBox(height: 8),
                      // Difficulty indicator
                      Row(
                        children: List.generate(5, (i) {
                          return Container(
                            margin: const EdgeInsets.only(right: 4),
                            width: 16,
                            height: 4,
                            decoration: BoxDecoration(
                              color: i < question.difficulty
                                  ? themeColor
                                  : (isDark
                                      ? Colors.grey.shade700
                                      : Colors.grey.shade300),
                              borderRadius: BorderRadius.circular(2),
                            ),
                          );
                        }),
                      ),
                      const SizedBox(height: 16),

                      // Question text
                      Text(
                        question.question,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          height: 1.4,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Options
                      ...List.generate(question.quizOptions.length, (i) {
                        return QuizOptionCard(
                          text: question.quizOptions[i],
                          index: i,
                          correctIndex: question.correctOptionIndex,
                          isSelected: state.selectedAnswerIndex == i,
                          isCorrect: state.selectedAnswerIndex == i
                              ? state.lastAnswerCorrect
                              : null,
                          showResult: showResult,
                          onTap: () {
                            HapticFeedback.mediumImpact();
                            notifier.submitAnswer(i);
                            // Sound plays after state updates
                            WidgetsBinding.instance.addPostFrameCallback((_) {
                              final s = ref.read(faithQuestionsProvider);
                              if (s.lastAnswerCorrect == true) {
                                ref.read(soundServiceProvider).playCorrect();
                              } else if (s.lastAnswerCorrect == false) {
                                ref.read(soundServiceProvider).playWrong();
                              }
                            });
                          },
                        );
                      }),

                      // Feedback after answer
                      if (showResult) ...[
                        const SizedBox(height: 20),
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 400),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: isDark
                                ? const Color(0xFF1e293b)
                                : const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: state.lastAnswerCorrect == true
                                  ? Colors.green.withValues(alpha: 0.3)
                                  : Colors.orange.withValues(alpha: 0.3),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    state.lastAnswerCorrect == true
                                        ? Icons.lightbulb
                                        : Icons.info_outline,
                                    color: state.lastAnswerCorrect == true
                                        ? Colors.green
                                        : Colors.orange,
                                    size: 18,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    state.lastAnswerCorrect == true
                                        ? 'Correct!'
                                        : 'Good to know',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                      color: state.lastAnswerCorrect == true
                                          ? Colors.green
                                          : Colors.orange,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                question.shortAnswer,
                                style: TextStyle(
                                  fontSize: 14,
                                  height: 1.5,
                                  color: isDark
                                      ? Colors.white70
                                      : Colors.black54,
                                ),
                              ),
                              const SizedBox(height: 8),
                              // Scripture refs
                              Wrap(
                                spacing: 6,
                                runSpacing: 4,
                                children: question.scriptureRefs.map((r) {
                                  return Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: themeColor
                                          .withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      r,
                                      style: const TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w600,
                                      ).copyWith(color: themeColor),
                                    ),
                                  );
                                }).toList(),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Continue button
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton(
                            onPressed: () => notifier.nextQuestion(),
                            style: FilledButton.styleFrom(
                              backgroundColor: themeColor,
                              padding:
                                  const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            child: Text(
                              state.currentQuestionIndex <
                                      state.quizQuestions.length - 1
                                  ? 'Next Question'
                                  : 'See Results',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(height: 32),
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
