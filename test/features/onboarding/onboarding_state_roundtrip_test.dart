import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';

import 'package:elbiblio/features/companion/domain/models/christian_life_baseline.dart';
import 'package:elbiblio/features/onboarding/application/onboarding_state.dart';
import 'package:elbiblio/features/today/domain/models/daily_anchors.dart';

void main() {
  group('OnboardingState JSON round-trip', () {
    test('empty state round-trips cleanly', () {
      const state = OnboardingState(
        step: OnboardingStep.theProblem,
        lifestyle: 'Student',
        morningTime: '07:30',
        eveningTime: '21:00',
        morningReminderEnabled: true,
        eveningReminderEnabled: true,
        primaryVirtue: VirtueType.humility,
        socialPresenceOptIn: false,
        contactsImported: false,
      );

      final encoded = jsonEncode(state.toJson());
      final decoded = OnboardingState.fromJson(
        jsonDecode(encoded) as Map<String, dynamic>,
      );

      expect(decoded.step, state.step);
      expect(decoded.lifestyle, state.lifestyle);
      expect(decoded.morningTime, state.morningTime);
      expect(decoded.eveningTime, state.eveningTime);
      expect(decoded.primaryVirtue, state.primaryVirtue);
      expect(decoded.bibleReadingCadence, isNull);
      expect(decoded.lastChurchAttendance, isNull);
      expect(decoded.prayerRhythm, isNull);
    });

    test('fully populated state survives round-trip', () {
      const state = OnboardingState(
        step: OnboardingStep.yourIdentity,
        lifestyle: 'Work from Home',
        morningTime: '06:00',
        eveningTime: '20:45',
        morningReminderEnabled: true,
        eveningReminderEnabled: false,
        primaryVirtue: VirtueType.faith,
        socialPresenceOptIn: true,
        contactsImported: true,
        primaryArchetypeId: 'Reformer',
        exactAge: 29,
        selectedArchetypeIds: ['Reformer', 'Watchman'],
        compassAssessmentData: {
          'Reformer': OnboardingCompassData(
            instances: 10,
            fears: 'many',
            maturity: 45,
          ),
          'Watchman': OnboardingCompassData(
            instances: 3,
            fears: 'some',
            maturity: 28,
          ),
        },
        spiritualAgeScore: 37,
        spiritualAgeStage: 'Child',
        commitmentCategory: 'discipline',
        primaryMissionFocus: 'faithSharing',
        email: 'a@b.com',
        fullName: 'Chibueze',
        phone: '+2348012345678',
        personalDistractions: ['social_media', 'procrastination'],
        bibleReadingCadence: BibleReadingCadence.severalTimesWeek,
        lastChurchAttendance: ChurchAttendance.thisWeek,
        prayerRhythm: PrayerRhythm.dailyShort,
        sovereigntyScore: 4,
        charityScore: 5,
        trustScore: 3,
      );

      final decoded = OnboardingState.fromJson(
        jsonDecode(jsonEncode(state.toJson())) as Map<String, dynamic>,
      );

      expect(decoded.step, state.step);
      expect(decoded.primaryArchetypeId, state.primaryArchetypeId);
      expect(decoded.exactAge, isNull);
      expect(decoded.derivedAgeBand, isNull);
      expect(decoded.selectedArchetypeIds, state.selectedArchetypeIds);
      expect(decoded.compassAssessmentData['Reformer']?.fears, 'many');
      expect(decoded.spiritualAgeScore, 37);
      expect(decoded.spiritualAgeStage, 'Child');
      expect(decoded.hasFullCompassResult, isFalse);
      expect(state.compassSubmissionPayload['age_band'], '25_34');
      expect(state.compassSubmissionPayload['selected_path'], 'development');
      expect(state.compassSubmissionPayload['selected_tasks'], [
        'dev_1',
        'dev_2',
        'dev_3',
      ]);
      expect(
        state.compassSubmissionPayload,
        containsPair('metadata', isA<Map<String, dynamic>>()),
      );
      final metadata =
          state.compassSubmissionPayload['metadata'] as Map<String, dynamic>;
      expect(metadata['action_plan'], isA<Map<String, dynamic>>());
      expect(
        metadata['primary_archetype_profile'],
        isA<Map<String, dynamic>>(),
      );
      expect(decoded.commitmentCategory, state.commitmentCategory);
      expect(decoded.primaryMissionFocus, state.primaryMissionFocus);
      expect(decoded.email, state.email);
      expect(decoded.fullName, state.fullName);
      expect(decoded.phone, state.phone);
      expect(decoded.personalDistractions, state.personalDistractions);
      expect(decoded.bibleReadingCadence, state.bibleReadingCadence);
      expect(decoded.lastChurchAttendance, state.lastChurchAttendance);
      expect(decoded.prayerRhythm, state.prayerRhythm);
      expect(decoded.sovereigntyScore, state.sovereigntyScore);
      expect(decoded.charityScore, state.charityScore);
      expect(decoded.trustScore, state.trustScore);
    });

    test('garbled input falls back to defaults without throwing', () {
      final decoded = OnboardingState.fromJson(const {});
      expect(decoded.step, OnboardingStep.theProblem);
      expect(decoded.lifestyle, 'Student');
      expect(decoded.primaryVirtue, VirtueType.humility);
      expect(decoded.sovereigntyScore, 3);
    });
  });
}
