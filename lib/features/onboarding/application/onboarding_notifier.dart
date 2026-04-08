import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/di/app_providers.dart';
import '../../../core/storage/app_settings.dart';
import '../../assessment/domain/models/archetype.dart';
import '../../commitments/domain/models/commitment_category.dart';
import '../../mission/domain/models/mission_focus.dart';
import '../../today/domain/models/daily_anchors.dart';
import 'onboarding_state.dart';

final onboardingProvider =
    StateNotifierProvider<OnboardingNotifier, OnboardingState>((ref) {
  final settings = ref.read(settingsProvider);
  return OnboardingNotifier(settings);
});

class OnboardingNotifier extends StateNotifier<OnboardingState> {
  OnboardingNotifier(AppSettings settings)
      : super(
          OnboardingState(
            step: OnboardingStep.theProblem,
            lifestyle: 'Student',
            morningTime: '07:30',
            eveningTime: '21:00',
            morningReminderEnabled: true,
            eveningReminderEnabled: true,
            primaryVirtue: settings.primaryVirtue,
            socialPresenceOptIn: false,
            contactsImported: false,
            primaryMissionFocus: settings.primaryMissionFocus,
          ),
        );

  void next() {
    final nextStep = switch (state.step) {
      OnboardingStep.theProblem => OnboardingStep.theSolution,
      OnboardingStep.theSolution => OnboardingStep.yourIdentity,
      OnboardingStep.yourIdentity => OnboardingStep.yourPath,
      OnboardingStep.yourPath => OnboardingStep.yourAccount,
      OnboardingStep.yourAccount => OnboardingStep.yourAccount,
    };

    state = state.copyWith(step: nextStep);
  }

  void back() {
    final previousStep = switch (state.step) {
      OnboardingStep.theProblem => OnboardingStep.theProblem,
      OnboardingStep.theSolution => OnboardingStep.theProblem,
      OnboardingStep.yourIdentity => OnboardingStep.theSolution,
      OnboardingStep.yourPath => OnboardingStep.yourIdentity,
      OnboardingStep.yourAccount => OnboardingStep.yourPath,
    };

    state = state.copyWith(step: previousStep);
  }

  // ---------------------------------------------------------------------------
  // Mini-assessment (3 questions + optional tiebreaker)
  // ---------------------------------------------------------------------------

  /// The mini-assessment questions with positive AND negative archetype
  /// affinities plus per-question weight multipliers.
  ///
  /// Negative scoring helps discriminate between archetypes that share
  /// similar positive signals (e.g., Welcomer/Bridgebuilder/Healer cluster).
  static const List<MiniAssessmentQuestion> miniAssessmentQuestions = [
    // Q1: Instinctive response — broad archetype signal (weight 1.0)
    MiniAssessmentQuestion(
      question: 'When life gets overwhelming, what do you instinctively reach for?',
      weight: 1.0,
      options: [
        'Something creative — music, art, writing, or building',
        'Information — I need to understand what\'s happening',
        'People — I reach out to someone I trust',
        'Action — I start doing something to fix it',
      ],
      affinityMap: {
        0: ArchetypeScoreSet(positive: ['Artisan', 'Sower'], negative: ['Architect', 'Pillar']),
        1: ArchetypeScoreSet(positive: ['Watchman', 'Sentinel'], negative: ['Welcomer', 'Sower']),
        2: ArchetypeScoreSet(positive: ['Welcomer', 'Bridgebuilder', 'Healer'], negative: ['Sentinel', 'Architect']),
        3: ArchetypeScoreSet(positive: ['Reformer', 'Architect', 'Harvester'], negative: ['Bridgebuilder', 'Welcomer']),
      },
    ),
    // Q2: Vice-signal question — splits clustered archetypes (weight 1.2)
    MiniAssessmentQuestion(
      question: 'What secretly drains your energy the most?',
      weight: 1.2,
      options: [
        'Feeling unseen or unappreciated for what I give',
        'Shallow relationships that never go deep',
        'Injustice that nobody seems to care about',
        'Disorder when things could be so much better',
      ],
      affinityMap: {
        0: ArchetypeScoreSet(positive: ['Pillar', 'Artisan', 'Cultivator'], negative: ['Harvester', 'Reformer']),
        1: ArchetypeScoreSet(positive: ['Sentinel', 'Healer', 'Bridgebuilder'], negative: ['Sower', 'Harvester']),
        2: ArchetypeScoreSet(positive: ['Reformer', 'Watchman', 'Sower'], negative: ['Welcomer', 'Pillar']),
        3: ArchetypeScoreSet(positive: ['Architect', 'Cultivator', 'Harvester'], negative: ['Bridgebuilder', 'Artisan']),
      },
    ),
    // Q3: Static fallback (only used if dynamic Q3 can't be generated)
    MiniAssessmentQuestion(
      question: 'If you could have one spiritual superpower, what would it be?',
      weight: 1.5,
      options: [
        'The ability to see what God sees in people',
        'Unshakeable peace no matter what happens',
        'The courage to speak truth even when it\'s costly',
        'The patience to build something that outlasts you',
      ],
      affinityMap: {
        0: ArchetypeScoreSet(positive: ['Healer', 'Cultivator', 'Bridgebuilder'], negative: ['Harvester', 'Architect']),
        1: ArchetypeScoreSet(positive: ['Sentinel', 'Pillar', 'Welcomer'], negative: ['Reformer', 'Sower']),
        2: ArchetypeScoreSet(positive: ['Watchman', 'Reformer', 'Sower'], negative: ['Pillar', 'Welcomer']),
        3: ArchetypeScoreSet(positive: ['Architect', 'Harvester', 'Artisan'], negative: ['Healer', 'Bridgebuilder']),
      },
    ),
  ];

  /// Archetype-specific distinguishing statements for dynamic Q3.
  static const archetypeDistinguishers = <String, String>{
    'Watchman': 'I would protect others from unseen dangers',
    'Sentinel': 'I would stand firm when everyone else compromises',
    'Reformer': 'I would challenge systems that keep people oppressed',
    'Architect': 'I would design something that changes how people live',
    'Sower': 'I would start movements that outlive me',
    'Harvester': 'I would bring people together for a shared purpose',
    'Artisan': 'I would create beauty that points people to God',
    'Healer': 'I would restore what is broken in someone\'s life',
    'Welcomer': 'I would make every stranger feel like family',
    'Cultivator': 'I would invest years developing one person\'s potential',
    'Bridgebuilder': 'I would connect divided communities',
    'Pillar': 'I would be the steady presence everyone relies on',
  };

  /// Generates a dynamic Q3 that distinguishes between the top candidates
  /// from Q1+Q2 answers. Uses weighted scoring with negatives.
  MiniAssessmentQuestion getDynamicQuestion3() {
    final answers = state.miniAssessmentAnswers;
    if (answers.length < 2) return miniAssessmentQuestions[2]; // fallback

    // Compute intermediate scores from Q1+Q2 using weighted scoring
    final scores = _computeIntermediateScores(answers.take(2).toList());
    if (scores.isEmpty) return miniAssessmentQuestions[2]; // fallback

    // Get top 4 candidates
    final sorted = scores.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final topCandidates = sorted.take(4).map((e) => e.key).toList();

    // Ensure we have at least 4 options
    if (topCandidates.length < 4) {
      for (final archetype in archetypeDistinguishers.keys) {
        if (!topCandidates.contains(archetype)) {
          topCandidates.add(archetype);
          if (topCandidates.length >= 4) break;
        }
      }
    }

    final options = topCandidates
        .where((a) => archetypeDistinguishers.containsKey(a))
        .take(4)
        .map((a) => archetypeDistinguishers[a]!)
        .toList();

    // Dynamic Q3 gets highest weight (2.0) — it's a direct distinguisher
    final affinityMap = <int, ArchetypeScoreSet>{};
    for (int i = 0; i < options.length; i++) {
      final archetype = topCandidates[i];
      affinityMap[i] = ArchetypeScoreSet(positive: [archetype], negative: const []);
    }

    return MiniAssessmentQuestion(
      question: 'Which of these best describes the impact you want to have?',
      weight: 2.0,
      options: options,
      affinityMap: affinityMap,
    );
  }

  /// Generates a tiebreaker question when the top 2 archetypes are too close.
  /// Returns null if no tiebreaker is needed.
  MiniAssessmentQuestion? getTiebreakerQuestion() {
    final answers = state.miniAssessmentAnswers;
    if (answers.length < 3) return null;

    final scores = _computeFullScores(answers);
    final sorted = scores.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    if (sorted.length < 2) return null;

    final topScore = sorted[0].value;
    final secondScore = sorted[1].value;
    final confidence = topScore > 0 ? (topScore - secondScore) / topScore : 0.0;

    // Only show tiebreaker when confidence is low
    if (confidence >= 0.3) return null;

    final top2 = sorted.take(2).map((e) => e.key).toList();
    final options = top2
        .where((a) => archetypeDistinguishers.containsKey(a))
        .map((a) => archetypeDistinguishers[a]!)
        .toList();

    if (options.length < 2) return null;

    final affinityMap = <int, ArchetypeScoreSet>{};
    for (int i = 0; i < options.length; i++) {
      affinityMap[i] = ArchetypeScoreSet(positive: [top2[i]], negative: const []);
    }

    return MiniAssessmentQuestion(
      question: 'One last thought — which resonates more deeply?',
      weight: 2.5,
      options: options,
      affinityMap: affinityMap,
    );
  }

  /// Computes intermediate scores from a subset of answers (used for dynamic Q3).
  Map<String, double> _computeIntermediateScores(List<int> answers) {
    final scores = <String, double>{};
    for (var i = 0; i < answers.length && i < miniAssessmentQuestions.length; i++) {
      if (answers[i] < 0) continue;
      final question = miniAssessmentQuestions[i];
      final scoreSet = question.affinityMap[answers[i]];
      if (scoreSet == null) continue;
      for (final archetype in scoreSet.positive) {
        scores[archetype] = (scores[archetype] ?? 0) + question.weight;
      }
      for (final archetype in scoreSet.negative) {
        scores[archetype] = (scores[archetype] ?? 0) - (question.weight * 0.5);
      }
    }
    return scores;
  }

  /// Computes full scores across all answered questions (including dynamic Q3).
  Map<String, double> _computeFullScores(List<int> answers) {
    final scores = <String, double>{};
    for (var i = 0; i < answers.length; i++) {
      if (answers[i] < 0) continue;
      final MiniAssessmentQuestion question;
      if (i == 2) {
        question = getDynamicQuestion3();
      } else if (i == 3) {
        final tiebreaker = getTiebreakerQuestion();
        if (tiebreaker == null) continue;
        question = tiebreaker;
      } else if (i < miniAssessmentQuestions.length) {
        question = miniAssessmentQuestions[i];
      } else {
        continue;
      }
      final scoreSet = question.affinityMap[answers[i]];
      if (scoreSet == null) continue;
      for (final archetype in scoreSet.positive) {
        scores[archetype] = (scores[archetype] ?? 0) + question.weight;
      }
      for (final archetype in scoreSet.negative) {
        scores[archetype] = (scores[archetype] ?? 0) - (question.weight * 0.5);
      }
    }
    return scores;
  }

  /// Records an answer for a mini-assessment question and, if all 3 are
  /// answered (or 4 with tiebreaker), computes the primary archetype.
  void answerMiniAssessment(int questionIndex, int answerIndex) {
    final answers = List<int>.from(state.miniAssessmentAnswers);

    // Grow list if needed
    while (answers.length <= questionIndex) {
      answers.add(-1);
    }
    answers[questionIndex] = answerIndex;

    state = state.copyWith(miniAssessmentAnswers: answers);

    // Compute archetype once we have at least 3 answers
    final answeredCount = answers.where((a) => a >= 0).length;
    if (answeredCount >= 3) {
      _computeArchetype(answers);
    }
  }

  void _computeArchetype(List<int> answers) {
    final scores = _computeFullScores(answers);

    // Sort to find best and second-best
    final sorted = scores.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    if (sorted.isEmpty) return;

    final bestArchetype = sorted[0].key;
    final bestScore = sorted[0].value;
    final secondScore = sorted.length > 1 ? sorted[1].value : 0.0;

    // Compute confidence: how much the top archetype leads
    final confidence = bestScore > 0
        ? ((bestScore - secondScore) / bestScore).clamp(0.0, 1.0)
        : 0.0;

    // Set the recommended commitment category
    final recommendedCategory =
        CommitmentCategory.recommendedForArchetype(bestArchetype);

    state = state.copyWith(
      primaryArchetypeId: bestArchetype,
      assessmentConfidence: confidence,
      commitmentCategory: recommendedCategory.name,
      primaryMissionFocus: _recommendedMissionFocus(recommendedCategory).name,
    );
  }

  /// Whether a tiebreaker question is needed (low confidence after 3 questions).
  bool get needsTiebreaker {
    return state.miniAssessmentAnswers.length >= 3 &&
        !state.tiebreakerShown &&
        state.assessmentConfidence < 0.3 &&
        getTiebreakerQuestion() != null;
  }

  /// Marks the tiebreaker as shown so it won't trigger again.
  void markTiebreakerShown() {
    state = state.copyWith(tiebreakerShown: true);
  }

  MissionFocusType _recommendedMissionFocus(CommitmentCategory category) {
    return switch (category) {
      CommitmentCategory.charity => MissionFocusType.service,
      CommitmentCategory.discipline => MissionFocusType.faithSharing,
      CommitmentCategory.growth => MissionFocusType.encouragement,
    };
  }

  /// Returns the full Archetype object for the current primary archetype, or null.
  Archetype? get primaryArchetype {
    final id = state.primaryArchetypeId;
    if (id == null) return null;
    return Archetype.allArchetypes.cast<Archetype?>().firstWhere(
          (a) => a?.name == id,
          orElse: () => null,
        );
  }

  // ---------------------------------------------------------------------------
  // Account fields
  // ---------------------------------------------------------------------------

  void setEmail(String email) {
    state = state.copyWith(email: email);
  }

  void setFullName(String name) {
    state = state.copyWith(fullName: name);
  }

  void setPhone(String phone) {
    state = state.copyWith(phone: phone);
  }

  void setPersonalDistractions(List<String> distractions) {
    state = state.copyWith(personalDistractions: distractions);
  }

  // ---------------------------------------------------------------------------
  // Commitment category
  // ---------------------------------------------------------------------------

  void setCommitmentCategory(String category) {
    state = state.copyWith(
      commitmentCategory: category,
      primaryMissionFocus: _recommendedMissionFocus(
        CommitmentCategory.fromString(category),
      ).name,
    );
  }

  void setPrimaryMissionFocus(String focus) {
    state = state.copyWith(primaryMissionFocus: focus);
  }

  // ---------------------------------------------------------------------------
  // Lifestyle & schedule (retained from original)
  // ---------------------------------------------------------------------------

  void setLifestyle(String lifestyle) {
    String suggestedMorning = '07:30';
    String suggestedEvening = '21:00';

    if (lifestyle == 'Student') {
      suggestedMorning = '05:30';
      suggestedEvening = '22:00';
    } else if (lifestyle == 'Physical Work') {
      suggestedMorning = '06:30';
      suggestedEvening = '21:30';
    } else if (lifestyle == 'Work from Home') {
      suggestedMorning = '07:00';
      suggestedEvening = '20:30';
    } else if (lifestyle == 'Not Employed') {
      suggestedMorning = '08:00';
      suggestedEvening = '20:00';
    }

    state = state.copyWith(
      lifestyle: lifestyle,
      morningTime: suggestedMorning,
      eveningTime: suggestedEvening,
    );
  }

  void setMorningTime(String time) {
    state = state.copyWith(morningTime: time);
  }

  void setEveningTime(String time) {
    state = state.copyWith(eveningTime: time);
  }

  void toggleMorningReminder(bool enabled) {
    state = state.copyWith(morningReminderEnabled: enabled);
  }

  void toggleEveningReminder(bool enabled) {
    state = state.copyWith(eveningReminderEnabled: enabled);
  }

  void setPrimaryVirtue(VirtueType value) {
    state = state.copyWith(primaryVirtue: value);
  }

  void setSocialPresenceOptIn(bool optedIn) {
    state = state.copyWith(socialPresenceOptIn: optedIn);
  }

  void setContactsImported(bool imported) {
    state = state.copyWith(contactsImported: imported);
  }
}

/// A single mini-assessment question with weighted positive/negative scoring.
class MiniAssessmentQuestion {
  const MiniAssessmentQuestion({
    required this.question,
    required this.options,
    required this.affinityMap,
    this.weight = 1.0,
  });

  final String question;
  final List<String> options;

  /// Per-question weight multiplier. Higher weight means this question's
  /// signal counts more toward the final archetype determination.
  final double weight;

  /// Maps answer index -> archetype score set (positive and negative affinities).
  final Map<int, ArchetypeScoreSet> affinityMap;
}

/// Positive and negative archetype affinities for a single answer option.
class ArchetypeScoreSet {
  const ArchetypeScoreSet({
    required this.positive,
    this.negative = const [],
  });

  /// Archetypes that gain points when this answer is selected.
  final List<String> positive;

  /// Archetypes that lose points (at 50% of question weight) when selected.
  final List<String> negative;
}
