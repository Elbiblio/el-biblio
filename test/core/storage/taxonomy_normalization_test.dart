import 'package:flutter_test/flutter_test.dart';

import 'package:elbiblio/core/storage/app_settings.dart';
import 'package:elbiblio/features/assessment/domain/models/calling_profile.dart';
import 'package:elbiblio/features/assessment/domain/models/weekly_plan.dart';
import 'package:elbiblio/features/commitments/domain/models/commitment_category.dart';
import 'package:elbiblio/features/mission/domain/models/mission_focus.dart';

void main() {
  group('Taxonomy Normalization Regression Tests', () {
    test('CommitmentCategory normalizeStorageValue handles legacy strings', () {
      expect(CommitmentCategory.normalizeStorageValue('Creative'), 'growth');
      expect(CommitmentCategory.normalizeStorageValue('Intellectual'), 'growth');
      expect(CommitmentCategory.normalizeStorageValue('Balanced'), 'growth');
      expect(CommitmentCategory.normalizeStorageValue('Protective'), 'discipline');
      expect(CommitmentCategory.normalizeStorageValue('Practical'), 'discipline');
      expect(CommitmentCategory.normalizeStorageValue('Relational'), 'discipline');
      expect(CommitmentCategory.normalizeStorageValue('Compassionate'), 'charity');
      expect(CommitmentCategory.normalizeStorageValue('creative'), 'growth');
      expect(CommitmentCategory.normalizeStorageValue(''), 'growth');
      expect(CommitmentCategory.normalizeStorageValue(null), 'growth');
      expect(CommitmentCategory.normalizeStorageValue('growth'), 'growth');
      expect(CommitmentCategory.normalizeStorageValue('discipline'), 'discipline');
      expect(CommitmentCategory.normalizeStorageValue('charity'), 'charity');
    });

    test('MissionFocusTypeX normalizeStorageValue handles legacy strings', () {
      expect(MissionFocusTypeX.normalizeStorageValue('acts of service'), 'service');
      expect(MissionFocusTypeX.normalizeStorageValue('general service'), 'service');
      expect(MissionFocusTypeX.normalizeStorageValue('service & stewardship'), 'service');
      expect(MissionFocusTypeX.normalizeStorageValue('care & compassion'), 'service');
      expect(MissionFocusTypeX.normalizeStorageValue('faithsharing '), 'faithSharing');
      expect(MissionFocusTypeX.normalizeStorageValue('faith sharing'), 'faithSharing');
      expect(MissionFocusTypeX.normalizeStorageValue('teaching & discipleship'), 'faithSharing');
      expect(MissionFocusTypeX.normalizeStorageValue('justice & protection'), 'faithSharing');
      expect(MissionFocusTypeX.normalizeStorageValue('creative expression'), 'encouragement');
      expect(MissionFocusTypeX.normalizeStorageValue('leadership & guidance'), 'encouragement');
      expect(MissionFocusTypeX.normalizeStorageValue(''), 'service');
      expect(MissionFocusTypeX.normalizeStorageValue(null), 'service');
      expect(MissionFocusTypeX.normalizeStorageValue('service'), 'service');
      expect(MissionFocusTypeX.normalizeStorageValue('faithSharing'), 'faithSharing');
      expect(MissionFocusTypeX.normalizeStorageValue('encouragement'), 'encouragement');
    });

    test('AppSettings fromMap normalizes legacy commitment category', () {
      final map = {
        'onboardingCompleted': true,
        'commitmentCategory': 'Compassionate',
        'primaryMissionFocus': 'service',
      };
      final settings = AppSettings.fromMap(map);
      expect(settings.commitmentCategory, CommitmentCategory.charity.name);
    });

    test('AppSettings fromMap normalizes legacy mission focus', () {
      final map = {
        'onboardingCompleted': true,
        'commitmentCategory': 'charity',
        'primaryMissionFocus': 'acts of service',
      };
      final settings = AppSettings.fromMap(map);
      expect(settings.primaryMissionFocus, MissionFocusType.service.name);
    });

    test('AppSettings toMap normalizes values on serialization', () {
      final settings = AppSettings.defaults().copyWith(
        commitmentCategory: 'Compassionate',
        primaryMissionFocus: 'acts of service',
      );
      final map = settings.toMap();
      expect(map['commitmentCategory'], CommitmentCategory.charity.name);
      expect(map['primaryMissionFocus'], MissionFocusType.service.name);
    });

    test('CallingProfile fromMap normalizes nested taxonomy values', () {
      final map = {
        'archetypeId': 'Artisan',
        'archetypeIdentity': 'Creator',
        'commitmentCategory': 'Creative',
        'missionFocus': 'creative expression',
        'weeklyPriorities': [],
        'burdensAndServiceTendencies': [],
        'growthRisks': [],
        'relationalFocus': [],
        'recommendedPractices': [],
        'personalDistractions': [],
        'createdAt': '2024-01-01T00:00:00.000Z',
      };
      final profile = CallingProfile.fromMap(map);
      expect(profile.commitmentCategory, CommitmentCategory.growth.name);
      expect(profile.missionFocus, MissionFocusType.encouragement.name);
    });

    test('WeeklyPlan fromMap normalizes mission focus and commitment categories', () {
      final map = {
        'id': 'week-1',
        'callingProfileId': 'profile-1',
        'weekStart': '2024-01-01T00:00:00.000Z',
        'dailyAnchors': [],
        'weeklyCommitments': [
          {
            'id': 'commit-1',
            'type': 'habit',
            'title': 'Test',
            'description': 'Test desc',
            'targetCount': 5,
            'currentCount': 0,
            'category': 'Practical',
          },
        ],
        'missionFocusForWeek': 'teaching & discipleship',
        'accountabilityFocus': 'partner',
        'reflectionPrompt': 'Test',
        'createdAt': '2024-01-01T00:00:00.000Z',
      };
      final plan = WeeklyPlan.fromMap(map);
      expect(plan.missionFocusForWeek, MissionFocusType.faithSharing.name);
      expect(plan.weeklyCommitments.first.category, CommitmentCategory.discipline.name);
    });

    test('WeeklyPlan toMap normalizes values on serialization', () {
      final plan = WeeklyPlan(
        id: 'week-1',
        callingProfileId: 'profile-1',
        weekStart: DateTime(2024, 1, 1),
        dailyAnchors: [],
        weeklyCommitments: [
          const WeeklyCommitment(
            id: 'commit-1',
            type: 'habit',
            title: 'Test',
            description: 'Test desc',
            targetCount: 5,
            currentCount: 0,
            category: 'Practical',
          ),
        ],
        missionFocusForWeek: 'teaching & discipleship',
        accountabilityFocus: 'partner',
        reflectionPrompt: 'Test',
        createdAt: DateTime(2024, 1, 1),
      );
      final map = plan.toMap();
      expect(map['missionFocusForWeek'], MissionFocusType.faithSharing.name);
      expect(map['weeklyCommitments'][0]['category'], CommitmentCategory.discipline.name);
    });
  });
}
