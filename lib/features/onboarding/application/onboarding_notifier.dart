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
  // Mini-assessment (3 questions)
  // ---------------------------------------------------------------------------

  /// The 3 mini-assessment questions. Each question maps answer indices to
  /// archetype affinities (which archetypes score points for that answer).
  static const List<MiniAssessmentQuestion> miniAssessmentQuestions = [
    MiniAssessmentQuestion(
      question: 'When life gets overwhelming, what do you instinctively reach for?',
      options: [
        'Something creative — music, art, writing, or building',
        'Information — I need to understand what\'s happening',
        'People — I reach out to someone I trust',
        'Action — I start doing something to fix it',
      ],
      affinityMap: {
        0: ['Artisan', 'Sower'],
        1: ['Watchman', 'Sentinel'],
        2: ['Welcomer', 'Bridgebuilder', 'Healer'],
        3: ['Reformer', 'Architect', 'Harvester'],
      },
    ),
    MiniAssessmentQuestion(
      question: 'What frustrates you most about the world right now?',
      options: [
        'People don\'t care enough about each other',
        'Things are chaotic — no one is building anything lasting',
        'Truth is being silenced or ignored',
        'People are stuck and won\'t grow or change',
      ],
      affinityMap: {
        0: ['Healer', 'Welcomer', 'Cultivator'],
        1: ['Architect', 'Pillar', 'Cultivator'],
        2: ['Watchman', 'Reformer', 'Sentinel'],
        3: ['Sower', 'Harvester', 'Artisan'],
      },
    ),
    MiniAssessmentQuestion(
      question: 'If you could have one spiritual superpower, what would it be?',
      options: [
        'The ability to see what God sees in people',
        'Unshakeable peace no matter what happens',
        'The courage to speak truth even when it\'s costly',
        'The patience to build something that outlasts you',
      ],
      affinityMap: {
        0: ['Healer', 'Cultivator', 'Bridgebuilder'],
        1: ['Sentinel', 'Pillar', 'Welcomer'],
        2: ['Watchman', 'Reformer', 'Sower'],
        3: ['Architect', 'Harvester', 'Artisan'],
      },
    ),
  ];

  /// Records an answer for a mini-assessment question and, if all 3 are
  /// answered, computes the primary archetype.
  void answerMiniAssessment(int questionIndex, int answerIndex) {
    final answers = List<int>.from(state.miniAssessmentAnswers);

    // Grow list if needed
    while (answers.length <= questionIndex) {
      answers.add(-1);
    }
    answers[questionIndex] = answerIndex;

    state = state.copyWith(miniAssessmentAnswers: answers);

    // If all 3 answered, compute archetype
    if (answers.length >= 3 && !answers.contains(-1)) {
      _computeArchetype(answers);
    }
  }

  void _computeArchetype(List<int> answers) {
    // Tally affinity scores
    final scores = <String, int>{};
    for (var i = 0; i < answers.length && i < miniAssessmentQuestions.length; i++) {
      final question = miniAssessmentQuestions[i];
      final archetypes = question.affinityMap[answers[i]] ?? [];
      for (final archetype in archetypes) {
        scores[archetype] = (scores[archetype] ?? 0) + 1;
      }
    }

    // Find the highest-scoring archetype
    String? bestArchetype;
    var bestScore = 0;
    for (final entry in scores.entries) {
      if (entry.value > bestScore) {
        bestScore = entry.value;
        bestArchetype = entry.key;
      }
    }

    if (bestArchetype != null) {
      // Also set the recommended commitment category
      final recommendedCategory =
          CommitmentCategory.recommendedForArchetype(bestArchetype);

      state = state.copyWith(
        primaryArchetypeId: bestArchetype,
        commitmentCategory: recommendedCategory.name,
        primaryMissionFocus: _recommendedMissionFocus(recommendedCategory).name,
      );
    }
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

/// A single mini-assessment question with answer-to-archetype mapping.
class MiniAssessmentQuestion {
  const MiniAssessmentQuestion({
    required this.question,
    required this.options,
    required this.affinityMap,
  });

  final String question;
  final List<String> options;

  /// Maps answer index -> list of archetype names that gain affinity.
  final Map<int, List<String>> affinityMap;
}
