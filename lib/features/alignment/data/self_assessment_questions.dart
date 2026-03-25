import '../domain/models/habit_assessment.dart';

/// Questions for the habit discovery self-assessment.
class SelfAssessmentQuestions {
  const SelfAssessmentQuestions._();

  static const List<SelfAssessmentQuestion> allQuestions = [
    // ── Spiritual ────────────────────────────────────────────────────────
    SelfAssessmentQuestion(
      id: 'q_sp_1',
      question: 'I often go several days without praying or talking to God.',
      category: HabitCategory.spiritual,
      relatedHabitIds: ['bad_sp_1'],
    ),
    SelfAssessmentQuestion(
      id: 'q_sp_2',
      question: 'I rarely read or study the Bible on my own.',
      category: HabitCategory.spiritual,
      relatedHabitIds: ['bad_sp_2'],
    ),
    SelfAssessmentQuestion(
      id: 'q_sp_3',
      question: 'I feel like my spiritual life has been on autopilot.',
      category: HabitCategory.spiritual,
      relatedHabitIds: ['bad_sp_3'],
    ),
    SelfAssessmentQuestion(
      id: 'q_sp_4',
      question: 'I am holding a grudge against someone right now.',
      category: HabitCategory.spiritual,
      relatedHabitIds: ['bad_sp_4'],
    ),
    SelfAssessmentQuestion(
      id: 'q_sp_5',
      question: 'I tend to focus more on what I lack than what God has given me.',
      category: HabitCategory.spiritual,
      relatedHabitIds: ['bad_sp_5'],
    ),
    SelfAssessmentQuestion(
      id: 'q_sp_6',
      question: 'I often feel anxious or worried about the future.',
      category: HabitCategory.spiritual,
      relatedHabitIds: ['bad_sp_6'],
    ),

    // ── Mental ───────────────────────────────────────────────────────────
    SelfAssessmentQuestion(
      id: 'q_mn_1',
      question: 'I frequently criticize myself or feel not good enough.',
      category: HabitCategory.mental,
      relatedHabitIds: ['bad_mn_1'],
    ),
    SelfAssessmentQuestion(
      id: 'q_mn_2',
      question: 'I often compare myself to others on social media or in life.',
      category: HabitCategory.mental,
      relatedHabitIds: ['bad_mn_2'],
    ),
    SelfAssessmentQuestion(
      id: 'q_mn_3',
      question: 'I put off important tasks until the last minute.',
      category: HabitCategory.mental,
      relatedHabitIds: ['bad_mn_3'],
    ),
    SelfAssessmentQuestion(
      id: 'q_mn_4',
      question: 'I spend too much time overthinking decisions or replaying past events.',
      category: HabitCategory.mental,
      relatedHabitIds: ['bad_mn_4'],
    ),

    // ── Physical ─────────────────────────────────────────────────────────
    SelfAssessmentQuestion(
      id: 'q_ph_1',
      question: 'I regularly stay up too late or have an inconsistent sleep schedule.',
      category: HabitCategory.physical,
      relatedHabitIds: ['bad_ph_1'],
    ),
    SelfAssessmentQuestion(
      id: 'q_ph_2',
      question: 'I spend most of my day sitting without much physical activity.',
      category: HabitCategory.physical,
      relatedHabitIds: ['bad_ph_2'],
    ),
    SelfAssessmentQuestion(
      id: 'q_ph_3',
      question: 'I tend to eat for comfort when I am stressed or upset.',
      category: HabitCategory.physical,
      relatedHabitIds: ['bad_ph_3'],
    ),
    SelfAssessmentQuestion(
      id: 'q_ph_4',
      question: 'I often neglect basic health care (checkups, rest, nutrition).',
      category: HabitCategory.physical,
      relatedHabitIds: ['bad_ph_4'],
    ),

    // ── Relational ───────────────────────────────────────────────────────
    SelfAssessmentQuestion(
      id: 'q_rl_1',
      question: 'I sometimes talk about people behind their backs in ways that are unkind.',
      category: HabitCategory.relational,
      relatedHabitIds: ['bad_rl_1'],
    ),
    SelfAssessmentQuestion(
      id: 'q_rl_2',
      question: 'I tend to isolate myself and avoid deep connections with others.',
      category: HabitCategory.relational,
      relatedHabitIds: ['bad_rl_2'],
    ),
    SelfAssessmentQuestion(
      id: 'q_rl_3',
      question: 'I have a hard time saying no and often overcommit to please others.',
      category: HabitCategory.relational,
      relatedHabitIds: ['bad_rl_3'],
    ),
    SelfAssessmentQuestion(
      id: 'q_rl_4',
      question: 'I sometimes lose my temper and say things I regret.',
      category: HabitCategory.relational,
      relatedHabitIds: ['bad_rl_4'],
    ),

    // ── Digital ──────────────────────────────────────────────────────────
    SelfAssessmentQuestion(
      id: 'q_dg_1',
      question: 'I spend more than an hour per day scrolling social media without purpose.',
      category: HabitCategory.digital,
      relatedHabitIds: ['bad_dg_1'],
    ),
    SelfAssessmentQuestion(
      id: 'q_dg_2',
      question: 'The first thing I do each morning is check my phone before praying.',
      category: HabitCategory.digital,
      relatedHabitIds: ['bad_dg_2'],
    ),
    SelfAssessmentQuestion(
      id: 'q_dg_3',
      question: 'I use screens late at night, affecting my sleep quality.',
      category: HabitCategory.digital,
      relatedHabitIds: ['bad_dg_3'],
    ),
    SelfAssessmentQuestion(
      id: 'q_dg_4',
      question: 'I sometimes consume media content that does not align with my values.',
      category: HabitCategory.digital,
      relatedHabitIds: ['bad_dg_4'],
    ),
  ];

  static List<SelfAssessmentQuestion> byCategory(HabitCategory category) =>
      allQuestions.where((q) => q.category == category).toList();
}
