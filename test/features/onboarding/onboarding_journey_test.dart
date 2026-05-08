import 'package:flutter_test/flutter_test.dart';

import 'package:elbiblio/core/storage/app_settings.dart';
import 'package:elbiblio/features/commitments/domain/models/commitment_category.dart';
import 'package:elbiblio/features/onboarding/application/onboarding_notifier.dart';
import 'package:elbiblio/features/onboarding/application/onboarding_state.dart';
import 'package:elbiblio/features/today/domain/models/daily_anchors.dart';

void main() {
  group('Onboarding Journey Integration Test', () {
    late OnboardingNotifier notifier;

    setUp(() {
      final settings = AppSettings.defaults();
      notifier = OnboardingNotifier(settings);
    });

    tearDown(() {
      notifier.dispose();
    });

    test('Onboarding starts at problem step', () {
      expect(notifier.state.step, OnboardingStep.theProblem);
    });

    test('Onboarding can advance through steps', () {
      expect(notifier.state.step, OnboardingStep.theProblem);

      notifier.next();
      expect(notifier.state.step, OnboardingStep.theSolution);

      notifier.next();
      expect(notifier.state.step, OnboardingStep.yourIdentity);

      notifier.next();
      expect(notifier.state.step, OnboardingStep.yourAccount);
    });

    test('Onboarding can go back through steps', () {
      notifier.next();
      notifier.next();
      
      expect(notifier.state.step, OnboardingStep.yourIdentity);
      
      notifier.back();
      expect(notifier.state.step, OnboardingStep.theSolution);
      
      notifier.back();
      expect(notifier.state.step, OnboardingStep.theProblem);
    });

    test('Mini assessment answers are tracked', () {
      notifier.answerMiniAssessment(0, 1);
      notifier.answerMiniAssessment(1, 2);
      notifier.answerMiniAssessment(2, 3);
      
      expect(notifier.state.miniAssessmentAnswers, [1, 2, 3]);
    });
test('Commitment category normalizes legacy values', () {
      notifier.setCommitmentCategory('Compassionate');
      expect(notifier.state.commitmentCategory, CommitmentCategory.charity.name);
      
      notifier.setCommitmentCategory('creative');
      expect(notifier.state.commitmentCategory, CommitmentCategory.growth.name);
      
      notifier.setCommitmentCategory('Practical');
      expect(notifier.state.commitmentCategory, CommitmentCategory.discipline.name);
    });

    test('Lifestyle can be set', () {
      notifier.setLifestyle('morning');
      expect(notifier.state.lifestyle, 'morning');
    });

    test('Primary virtue can be set', () {
      notifier.setPrimaryVirtue(VirtueType.faith);
      expect(notifier.state.primaryVirtue, VirtueType.faith);
    });
  });
}
