import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/application/settings_notifier.dart';
import '../../../core/di/app_providers.dart';
import '../../../core/storage/app_settings.dart';
import '../../assessment/domain/models/archetype.dart';
import '../../commitments/domain/models/commitment_category.dart';
import '../../companion/domain/models/christian_life_baseline.dart';
import '../../mission/domain/models/mission_focus.dart';
import '../../today/domain/models/daily_anchors.dart';
import '../domain/compass_discovery_catalog.dart';
import 'onboarding_state.dart';

final onboardingProvider =
    StateNotifierProvider<OnboardingNotifier, OnboardingState>((ref) {
      final settings = ref.read(settingsProvider);
      final settingsNotifier = ref.read(settingsProvider.notifier);
      return OnboardingNotifier(settings, settingsNotifier);
    });

class OnboardingNotifier extends StateNotifier<OnboardingState> {
  OnboardingNotifier(AppSettings settings, [this._settingsNotifier])
    : super(_initialState(settings));

  /// Optional so pure-unit tests can instantiate the notifier without a
  /// real `SettingsNotifier`. Null-case: persistence no-ops silently.
  final SettingsNotifier? _settingsNotifier;

  static OnboardingState _initialState(AppSettings settings) {
    // Rehydrate if user is mid-onboarding and a draft exists. Completed
    // users never rehydrate because the draft is wiped on signup success.
    if (!settings.onboardingCompleted && settings.onboardingDraft != null) {
      try {
        final decoded =
            jsonDecode(settings.onboardingDraft!) as Map<String, dynamic>;
        return OnboardingState.fromJson(decoded);
      } catch (e) {
        debugPrint('OnboardingNotifier: draft rehydrate failed: $e');
      }
    }
    return OnboardingState(
      step: OnboardingStep.connect,
      lifestyle: 'Student',
      morningTime: '07:30',
      eveningTime: '21:00',
      morningReminderEnabled: true,
      eveningReminderEnabled: true,
      primaryVirtue: settings.primaryVirtue,
      socialPresenceOptIn: false,
      contactsImported: false,
      primaryMissionFocus: settings.primaryMissionFocus,
    );
  }

  @override
  set state(OnboardingState value) {
    super.state = value;
    // Fire-and-forget. Fails are debug-logged but not awaited; onboarding
    // UI stays responsive and the next mutation re-persists the whole state.
    _persistDraft();
  }

  Future<void> _persistDraft() async {
    final notifier = _settingsNotifier;
    if (notifier == null) return;
    try {
      await notifier.setOnboardingDraft(jsonEncode(state.toJson()));
    } catch (e) {
      debugPrint('OnboardingNotifier: draft persist failed: $e');
    }
  }

  void next() {
    final nextStep = switch (state.step) {
      OnboardingStep.connect => OnboardingStep.commit,
      OnboardingStep.commit => OnboardingStep.speak,
      OnboardingStep.speak => OnboardingStep.yourAccount,
      OnboardingStep.yourAccount => OnboardingStep.yourAccount,
    };

    state = state.copyWith(step: nextStep);
  }

  void back() {
    final previousStep = switch (state.step) {
      OnboardingStep.connect => OnboardingStep.connect,
      OnboardingStep.commit => OnboardingStep.connect,
      OnboardingStep.speak => OnboardingStep.commit,
      OnboardingStep.yourAccount => OnboardingStep.speak,
    };

    state = state.copyWith(step: previousStep);
  }

  void openAccount() {
    state = state.copyWith(step: OnboardingStep.yourAccount);
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
  // Full spiritual compass
  // ---------------------------------------------------------------------------

  void setExactAge(int? age) {
    if (age == null || age < 13 || age > 120) {
      state = state.copyWith(clearExactAge: true);
      return;
    }
    state = state.copyWith(exactAge: age);
  }

  void setCompassSeasonArchetype(String archetypeName) {
    state = state.copyWith(compassSeasonArchetype: archetypeName);
    _syncCompassDiscoveryResult();
  }

  void setCompassPressureArchetype(String archetypeName) {
    state = state.copyWith(compassPressureArchetype: archetypeName);
    _syncCompassDiscoveryResult();
  }

  void setCompassPostponedArchetype(String archetypeName) {
    state = state.copyWith(compassPostponedArchetype: archetypeName);
    _syncCompassDiscoveryResult();
  }

  void setCompassPeopleNeedArchetype(String archetypeName) {
    state = state.copyWith(compassPeopleNeedArchetype: archetypeName);
    _syncCompassDiscoveryResult();
  }

  void setCompassDistortionFearArchetype(String archetypeName) {
    state = state.copyWith(compassDistortionFearArchetype: archetypeName);
    _syncCompassDiscoveryResult();
  }

  void _syncCompassDiscoveryResult() {
    final scores = {
      for (final archetype in CompassDiscoveryCatalog.archetypeOrder)
        archetype: 0,
    };

    void addScore(String? archetype, int score) {
      if (archetype == null || !scores.containsKey(archetype)) return;
      scores[archetype] = scores[archetype]! + score;
    }

    addScore(state.compassSeasonArchetype, 4);
    addScore(state.compassPressureArchetype, 3);
    addScore(state.compassPostponedArchetype, 3);
    addScore(state.compassPeopleNeedArchetype, 2);
    addScore(state.compassDistortionFearArchetype, 5);

    final ranked = List<String>.from(CompassDiscoveryCatalog.archetypeOrder)
      ..sort((a, b) {
        final byScore = scores[b]!.compareTo(scores[a]!);
        if (byScore != 0) return byScore;
        return CompassDiscoveryCatalog.archetypeOrder
            .indexOf(a)
            .compareTo(CompassDiscoveryCatalog.archetypeOrder.indexOf(b));
      });
    final top = ranked.where((name) => scores[name]! > 0).take(3).toList();
    if (top.isEmpty) return;

    final primary = top.first;
    final primaryScore = scores[primary] ?? 0;
    final supportScore = (40 + (primaryScore * 4)).clamp(40, 96).toInt();
    final recommendedCategory = CommitmentCategory.recommendedForArchetype(
      primary,
    );
    final data = {
      for (final archetype in top)
        archetype: OnboardingCompassData(
          instances: scores[archetype] ?? 0,
          fears: archetype == state.compassDistortionFearArchetype
              ? 'primary'
              : 'secondary',
          maturity: supportScore,
        ),
    };

    state = state.copyWith(
      selectedArchetypeIds: top,
      compassAssessmentData: data,
      primaryArchetypeId: primary,
      commitmentCategory: recommendedCategory.name,
      primaryMissionFocus: _recommendedMissionFocus(recommendedCategory).name,
      spiritualAgeScore: supportScore,
      spiritualAgeStage: spiritualAgeStageForScore(supportScore),
    );
  }

  void toggleCompassArchetype(String archetypeName) {
    final selected = List<String>.from(state.selectedArchetypeIds);
    if (selected.contains(archetypeName)) {
      selected.remove(archetypeName);
      final data = Map<String, OnboardingCompassData>.from(
        state.compassAssessmentData,
      )..remove(archetypeName);
      state = state.copyWith(
        selectedArchetypeIds: selected,
        compassAssessmentData: data,
      );
    } else {
      final data = Map<String, OnboardingCompassData>.from(
        state.compassAssessmentData,
      );
      if (selected.length >= 3) {
        final removed = selected.removeAt(0);
        data.remove(removed);
      }
      selected.add(archetypeName);
      state = state.copyWith(
        selectedArchetypeIds: selected,
        compassAssessmentData: data,
      );
    }
    _syncCompassResult();
  }

  void saveCompassArchetypeAssessment(
    String archetypeName,
    int instances,
    String fears,
  ) {
    final nextData = Map<String, OnboardingCompassData>.from(
      state.compassAssessmentData,
    );
    nextData[archetypeName] = OnboardingCompassData(
      instances: instances,
      fears: fears,
      maturity: _calculateCompassMaturity(instances, fears),
    );
    state = state.copyWith(compassAssessmentData: nextData);
    _syncCompassResult();
  }

  int _calculateCompassMaturity(int instances, String fears) {
    final instanceScore = switch (instances) {
      <= 0 => 10.0,
      <= 3 => 24.0,
      <= 10 => 38.0,
      <= 23 => 52.0,
      <= 40 => 64.0,
      <= 60 => 74.0,
      <= 90 => 84.0,
      _ => 90.0,
    };
    final struggleBonus = switch (fears) {
      'overcome' => 10.0,
      'many' => 7.0,
      'some' => 4.0,
      _ => 0.0,
    };
    return (instanceScore + struggleBonus).clamp(0.0, 100.0).round();
  }

  static String spiritualAgeStageForScore(int score) {
    if (score < 25) return 'Infant';
    if (score < 45) return 'Child';
    if (score < 65) return 'Young';
    if (score < 82) return 'Maturing';
    return 'Mature';
  }

  void _syncCompassResult() {
    if (state.selectedArchetypeIds.isEmpty) {
      state = state.copyWith(
        primaryArchetypeId: null,
        commitmentCategory: null,
        primaryMissionFocus: null,
        spiritualAgeScore: 0,
        spiritualAgeStage: 'Infant',
      );
      return;
    }

    final ranked = List<String>.from(state.selectedArchetypeIds)
      ..sort((a, b) {
        final scoreA = state.compassAssessmentData[a]?.maturity ?? 0;
        final scoreB = state.compassAssessmentData[b]?.maturity ?? 0;
        return scoreB.compareTo(scoreA);
      });
    final primary = ranked.first;
    final data = state.compassAssessmentData;
    final completed = ranked
        .map((name) => data[name]?.maturity)
        .whereType<int>()
        .toList();
    final score = completed.isEmpty
        ? 0
        : (completed.reduce((a, b) => a + b) / completed.length).round();
    final recommendedCategory = CommitmentCategory.recommendedForArchetype(
      primary,
    );

    state = state.copyWith(
      selectedArchetypeIds: ranked,
      primaryArchetypeId: primary,
      commitmentCategory: recommendedCategory.name,
      primaryMissionFocus: _recommendedMissionFocus(recommendedCategory).name,
      spiritualAgeScore: score,
      spiritualAgeStage: spiritualAgeStageForScore(score),
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
    final normalized = CommitmentCategory.normalizeStorageValue(category);
    state = state.copyWith(
      commitmentCategory: normalized,
      primaryMissionFocus: _recommendedMissionFocus(
        CommitmentCategory.fromString(normalized),
      ).name,
    );
  }

  void setPrimaryMissionFocus(String focus) {
    state = state.copyWith(primaryMissionFocus: focus);
  }

  // ---------------------------------------------------------------------------
  // Lifestyle & schedule
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

  // ---------------------------------------------------------------------------
  // Christian-Life Baseline setters
  // ---------------------------------------------------------------------------

  void setBibleReadingCadence(BibleReadingCadence value) {
    state = state.copyWith(bibleReadingCadence: value);
  }

  void setLastChurchAttendance(ChurchAttendance value) {
    state = state.copyWith(lastChurchAttendance: value);
  }

  void setPrayerRhythm(PrayerRhythm value) {
    state = state.copyWith(prayerRhythm: value);
  }

  void setSovereigntyScore(int value) {
    state = state.copyWith(sovereigntyScore: value.clamp(1, 5));
  }

  void setCharityScore(int value) {
    state = state.copyWith(charityScore: value.clamp(1, 5));
  }

  void setTrustScore(int value) {
    state = state.copyWith(trustScore: value.clamp(1, 5));
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

  // ---------------------------------------------------------------------------
  // Pillar-based onboarding setters
  // ---------------------------------------------------------------------------

  void setPrayerStyle(String? style) {
    state = state.copyWith(prayerStyle: style);
  }

  void setTradition(String? tradition) {
    state = state.copyWith(tradition: tradition);
  }

  void setSelectedCompanionId(String? id) {
    state = state.copyWith(selectedCompanionId: id);
  }

  void setAccountabilityLevel(String level) {
    state = state.copyWith(accountabilityLevel: level);
  }

  void setCommitmentChoice(String? choice) {
    state = state.copyWith(commitmentChoice: choice);
  }
}
