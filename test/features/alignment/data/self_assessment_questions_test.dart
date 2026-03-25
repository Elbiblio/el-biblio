import 'package:flutter_test/flutter_test.dart';
import 'package:elbiblio/features/alignment/data/self_assessment_questions.dart';
import 'package:elbiblio/features/alignment/domain/models/habit_assessment.dart';

void main() {
  group('SelfAssessmentQuestions', () {
    test('has questions in the catalog', () {
      expect(SelfAssessmentQuestions.allQuestions.isNotEmpty, true);
    });

    test('all questions have unique ids', () {
      final ids = SelfAssessmentQuestions.allQuestions.map((q) => q.id).toSet();
      expect(ids.length, SelfAssessmentQuestions.allQuestions.length);
    });

    test('all questions have non-empty question text', () {
      for (final q in SelfAssessmentQuestions.allQuestions) {
        expect(q.question.isNotEmpty, true,
            reason: 'Question ${q.id} should have non-empty text');
      }
    });

    test('all questions have non-empty relatedHabitIds', () {
      for (final q in SelfAssessmentQuestions.allQuestions) {
        expect(q.relatedHabitIds.isNotEmpty, true,
            reason: 'Question ${q.id} should have related habit ids');
      }
    });

    test('questions cover all HabitCategory values', () {
      final categories =
          SelfAssessmentQuestions.allQuestions.map((q) => q.category).toSet();
      for (final cat in HabitCategory.values) {
        expect(categories.contains(cat), true,
            reason: 'Category ${cat.name} should have questions');
      }
    });

    test('byCategory returns correct questions', () {
      for (final cat in HabitCategory.values) {
        final questions = SelfAssessmentQuestions.byCategory(cat);
        expect(questions.isNotEmpty, true,
            reason: 'Category ${cat.name} should have questions');
        for (final q in questions) {
          expect(q.category, cat);
        }
      }
    });

    test('spiritual category has questions', () {
      final spiritual = SelfAssessmentQuestions.byCategory(HabitCategory.spiritual);
      expect(spiritual.isNotEmpty, true);
    });

    test('mental category has questions', () {
      final mental = SelfAssessmentQuestions.byCategory(HabitCategory.mental);
      expect(mental.isNotEmpty, true);
    });

    test('physical category has questions', () {
      final physical = SelfAssessmentQuestions.byCategory(HabitCategory.physical);
      expect(physical.isNotEmpty, true);
    });

    test('relational category has questions', () {
      final relational = SelfAssessmentQuestions.byCategory(HabitCategory.relational);
      expect(relational.isNotEmpty, true);
    });

    test('digital category has questions', () {
      final digital = SelfAssessmentQuestions.byCategory(HabitCategory.digital);
      expect(digital.isNotEmpty, true);
    });

    test('all relatedHabitIds reference valid habit ids', () {
      // Collect all habit IDs from the habit catalog
      // We check they follow naming conventions (bad_xx_N)
      for (final q in SelfAssessmentQuestions.allQuestions) {
        for (final habitId in q.relatedHabitIds) {
          expect(habitId.isNotEmpty, true,
              reason: 'Question ${q.id} has an empty related habit id');
          // All related habits should be bad habits (start with 'bad_')
          expect(habitId.startsWith('bad_'), true,
              reason:
                  'Question ${q.id} references "$habitId" which does not start with "bad_"');
        }
      }
    });
  });
}
