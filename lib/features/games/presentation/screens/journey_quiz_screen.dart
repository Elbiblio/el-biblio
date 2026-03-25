import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../application/journey_game_notifier.dart';
import '../widgets/quiz_option_card.dart';
import 'journey_complete_screen.dart';

class JourneyQuizScreen extends ConsumerWidget {
  const JourneyQuizScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(journeyGameProvider);
    final notifier = ref.read(journeyGameProvider.notifier);
    final event = state.currentEvent;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (event == null) {
      return const Scaffold(body: Center(child: Text('No event')));
    }

    // Listen for completion
    ref.listen<JourneyPhase>(
      journeyGameProvider.select((s) => s.phase),
      (prev, next) {
        if (next == JourneyPhase.eventComplete) {
          // Pop quiz + event screens, back to map
          Navigator.of(context).popUntil((route) => route.isFirst);
        } else if (next == JourneyPhase.journeyComplete) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const JourneyCompleteScreen()),
          );
        }
      },
    );

    final question = event.questions[state.currentQuestionIndex];
    final showResult = state.phase == JourneyPhase.quizResult;
    final questionNumber = state.currentQuestionIndex + 1;
    final totalQuestions = event.questions.length;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              event.themeColor.withValues(alpha: isDark ? 0.15 : 0.08),
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
                        notifier.backToMap();
                        Navigator.of(context)
                            .popUntil((route) => route.isFirst);
                      },
                    ),
                    Expanded(
                      child: Column(
                        children: [
                          Text(
                            event.title,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color:
                                  isDark ? Colors.white70 : Colors.black54,
                            ),
                          ),
                          const SizedBox(height: 4),
                          // Progress dots
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children:
                                List.generate(totalQuestions, (i) {
                              Color dotColor;
                              if (i < state.currentQuestionIndex) {
                                dotColor = event.themeColor;
                              } else if (i == state.currentQuestionIndex) {
                                dotColor =
                                    event.themeColor.withValues(alpha: 0.5);
                              } else {
                                dotColor = isDark
                                    ? Colors.grey.shade700
                                    : Colors.grey.shade300;
                              }
                              return Container(
                                margin: const EdgeInsets.symmetric(
                                    horizontal: 4),
                                width: i == state.currentQuestionIndex
                                    ? 24
                                    : 10,
                                height: 10,
                                decoration: BoxDecoration(
                                  color: dotColor,
                                  borderRadius: BorderRadius.circular(5),
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
                        color: event.themeColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.star,
                              size: 14, color: event.themeColor),
                          const SizedBox(width: 4),
                          Text(
                            '${state.sessionCorrect}/$totalQuestions',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: event.themeColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Question
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Question label
                      Text(
                        'QUESTION $questionNumber',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 2,
                          color: event.themeColor,
                        ),
                      ),
                      const SizedBox(height: 8),
                      // Difficulty indicator
                      Row(
                        children: List.generate(3, (i) {
                          return Container(
                            margin: const EdgeInsets.only(right: 4),
                            width: 20,
                            height: 4,
                            decoration: BoxDecoration(
                              color: i < question.difficulty
                                  ? event.themeColor
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
                      ...List.generate(question.options.length, (i) {
                        return QuizOptionCard(
                          text: question.options[i],
                          index: i,
                          correctIndex: question.correctIndex,
                          isSelected: state.selectedAnswerIndex == i,
                          isCorrect:
                              state.selectedAnswerIndex == i
                                  ? state.isCorrect
                                  : null,
                          showResult: showResult,
                          onTap: () {
                            HapticFeedback.mediumImpact();
                            notifier.submitAnswer(i);
                          },
                        );
                      }),

                      // Explanation (shown after answer)
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
                              color: state.isCorrect == true
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
                                    state.isCorrect == true
                                        ? Icons.lightbulb
                                        : Icons.info_outline,
                                    color: state.isCorrect == true
                                        ? Colors.green
                                        : Colors.orange,
                                    size: 18,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    state.isCorrect == true
                                        ? 'Correct!'
                                        : 'Good to know',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                      color: state.isCorrect == true
                                          ? Colors.green
                                          : Colors.orange,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                question.explanation,
                                style: TextStyle(
                                  fontSize: 14,
                                  height: 1.5,
                                  color: isDark
                                      ? Colors.white70
                                      : Colors.black54,
                                ),
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
                              backgroundColor: event.themeColor,
                              padding: const EdgeInsets.symmetric(
                                  vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            child: Text(
                              state.currentQuestionIndex <
                                      event.questions.length - 1
                                  ? 'Next Question'
                                  : 'Complete Event',
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
