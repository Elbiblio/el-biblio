import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../../core/di/app_providers.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_theme_tokens.dart';
import '../../data/habit_catalog.dart';
import '../../data/self_assessment_questions.dart';
import '../../domain/models/habit_assessment.dart';

class HabitAssessmentScreen extends ConsumerStatefulWidget {
  const HabitAssessmentScreen({super.key});

  @override
  ConsumerState<HabitAssessmentScreen> createState() =>
      _HabitAssessmentScreenState();
}

class _HabitAssessmentScreenState extends ConsumerState<HabitAssessmentScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  final Map<String, int> _answers = {}; // questionId -> score (1-5)
  bool _showResults = false;
  List<HabitItem> _identifiedHabits = [];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onAnswer(String questionId, int score) {
    setState(() {
      _answers[questionId] = score;
    });
  }

  void _next() {
    final questions = SelfAssessmentQuestions.allQuestions;
    if (_currentPage < questions.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _calculateResults();
    }
  }

  void _calculateResults() {
    final identified = <HabitItem>[];
    for (final question in SelfAssessmentQuestions.allQuestions) {
      final score = _answers[question.id] ?? 0;
      if (score >= 3) {
        // Score 3+ means this is a habit to address
        for (final habitId in question.relatedHabitIds) {
          final habit = HabitCatalog.findById(habitId);
          if (habit != null && !identified.any((h) => h.id == habit.id)) {
            identified.add(habit);
          }
        }
      }
    }
    setState(() {
      _identifiedHabits = identified;
      _showResults = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).tokens;

    return Scaffold(
      backgroundColor: tokens.palette.background,
      appBar: AppBar(
        title: Text(_showResults ? 'Your Habits' : 'Habit Discovery'),
        backgroundColor: tokens.palette.background,
      ),
      body: _showResults
          ? _buildResults(context, tokens)
          : _buildQuestionnaire(context, tokens),
    );
  }

  Widget _buildQuestionnaire(BuildContext context, AppThemeTokens tokens) {
    final questions = SelfAssessmentQuestions.allQuestions;
    final progress = questions.isNotEmpty
        ? (_currentPage + 1) / questions.length
        : 0.0;

    return Column(
      children: [
        // Progress bar
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Question ${_currentPage + 1} of ${questions.length}',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: tokens.palette.textSecondary,
                    ),
                  ),
                  Text(
                    '${(progress * 100).round()}%',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: tokens.palette.primary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 6,
                  backgroundColor: tokens.palette.surface,
                  valueColor: AlwaysStoppedAnimation(tokens.palette.primary),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Question cards
        Expanded(
          child: PageView.builder(
            controller: _pageController,
            physics: const NeverScrollableScrollPhysics(),
            onPageChanged: (page) => setState(() => _currentPage = page),
            itemCount: questions.length,
            itemBuilder: (context, index) {
              final question = questions[index];
              final answer = _answers[question.id];

              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Category chip
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: question.category.color.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            question.category.icon,
                            size: 14,
                            color: question.category.color,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            question.category.label,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: question.category.color,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Question text
                    Text(
                      question.question,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: tokens.palette.textPrimary,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Answer scale
                    Text(
                      'How true is this for you?',
                      style: TextStyle(
                        fontSize: 13,
                        color: tokens.palette.textTertiary,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(5, (i) {
                        final score = i + 1;
                        final isSelected = answer == score;
                        final labels = [
                          'Never',
                          'Rarely',
                          'Sometimes',
                          'Often',
                          'Always',
                        ];

                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: GestureDetector(
                            onTap: () => _onAnswer(question.id, score),
                            child: Column(
                              children: [
                                Container(
                                  width: 48,
                                  height: 48,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: isSelected
                                        ? tokens.palette.primary
                                        : tokens.palette.surface,
                                    border: Border.all(
                                      color: isSelected
                                          ? tokens.palette.primary
                                          : tokens.palette.border,
                                    ),
                                  ),
                                  child: Center(
                                    child: Text(
                                      '$score',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: isSelected
                                            ? Colors.white
                                            : tokens.palette.textSecondary,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  labels[i],
                                  style: TextStyle(
                                    fontSize: 9,
                                    color: isSelected
                                        ? tokens.palette.primary
                                        : tokens.palette.textTertiary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }),
                    ),
                  ],
                ),
              );
            },
          ),
        ),

        // Next button
        Padding(
          padding: const EdgeInsets.all(20),
          child: SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _answers.containsKey(
                SelfAssessmentQuestions.allQuestions[_currentPage].id,
              )
                  ? _next
                  : null,
              child: Text(
                _currentPage < SelfAssessmentQuestions.allQuestions.length - 1
                    ? 'Next'
                    : 'See Results',
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildResults(BuildContext context, AppThemeTokens tokens) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Summary
          Center(
            child: Column(
              children: [
                Icon(
                  LucideIcons.target,
                  size: 48,
                  color: tokens.palette.primary,
                ),
                const SizedBox(height: 12),
                Text(
                  'We Found ${_identifiedHabits.length} Habits',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: tokens.palette.textPrimary,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Based on your responses, here are the habits to work on.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: tokens.palette.textSecondary,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          if (_identifiedHabits.isEmpty) ...[
            Center(
              child: Text(
                'Great news! No significant bad habits were identified.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: tokens.palette.success,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ] else ...[
            // Habit cards
            ..._identifiedHabits.map((habit) {
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: tokens.palette.paper,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: tokens.palette.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: habit.category.color.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            habit.category.icon,
                            color: habit.category.color,
                            size: 18,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                habit.name,
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: tokens.palette.textPrimary,
                                ),
                              ),
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 1,
                                    ),
                                    decoration: BoxDecoration(
                                      color: habit.category.color
                                          .withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      habit.category.label,
                                      style: TextStyle(
                                        fontSize: 9,
                                        fontWeight: FontWeight.w600,
                                        color: habit.category.color,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Severity: ${habit.severity}/5',
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: tokens.palette.textTertiary,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      habit.description,
                      style: TextStyle(
                        fontSize: 13,
                        color: tokens.palette.textSecondary,
                        height: 1.4,
                      ),
                    ),
                    if (habit.counterHabit != null) ...[
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: tokens.palette.success.withValues(alpha: 0.06),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: tokens.palette.success.withValues(alpha: 0.2),
                          ),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              LucideIcons.lightbulb,
                              size: 14,
                              color: tokens.palette.success,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                habit.counterHabit!,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: tokens.palette.success,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              );
            }),
          ],

          const SizedBox(height: 24),

          // Action buttons
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () {
                ref.read(habitProvider.notifier).addHabits(_identifiedHabits);
                context.go('/alignment/habit-tracker');
              },
              child: const Text('Start Habit Conquest'),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () => context.pop(),
              child: const Text('Back to Hub'),
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }
}
