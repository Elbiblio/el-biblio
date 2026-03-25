import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:elbiblio/features/games/domain/models/jesus_journey_event.dart';

void main() {
  group('JourneyQuestion', () {
    late JourneyQuestion question;

    setUp(() {
      question = const JourneyQuestion(
        question: 'Which prophet foretold that a virgin would conceive?',
        options: ['Jeremiah', 'Isaiah', 'Ezekiel', 'Daniel'],
        correctIndex: 1,
        explanation: 'Isaiah 7:14 says the virgin will conceive.',
        difficulty: 1,
      );
    });

    group('construction', () {
      test('creates with all fields', () {
        expect(question.question, 'Which prophet foretold that a virgin would conceive?');
        expect(question.options.length, 4);
        expect(question.correctIndex, 1);
        expect(question.explanation.isNotEmpty, true);
        expect(question.difficulty, 1);
      });

      test('difficulty defaults to 1', () {
        const q = JourneyQuestion(
          question: 'Test?',
          options: ['A', 'B'],
          correctIndex: 0,
          explanation: 'Explanation',
        );
        expect(q.difficulty, 1);
      });
    });

    group('JSON serialization', () {
      test('round-trip toJson -> fromJson preserves data', () {
        final json = question.toJson();
        final restored = JourneyQuestion.fromJson(json);
        expect(restored.question, question.question);
        expect(restored.options, question.options);
        expect(restored.correctIndex, question.correctIndex);
        expect(restored.explanation, question.explanation);
        expect(restored.difficulty, question.difficulty);
      });
    });
  });

  group('JesusJourneyEvent', () {
    late JesusJourneyEvent event;

    setUp(() {
      event = const JesusJourneyEvent(
        order: 0,
        id: 'prophecies_of_messiah',
        title: 'Prophecies of the Messiah',
        subtitle: 'Old Testament promises fulfilled',
        narrative: 'Centuries before the birth of Jesus...',
        bibleReference: 'Isaiah 7:14; Micah 5:2',
        keyVerse: 'For to us a child is born...',
        keyVerseReference: 'Isaiah 9:6',
        spiritualTakeaway: 'God keeps every promise.',
        themeColor: Color(0xFF5C4B8A),
        iconName: 'scroll_text',
        xpReward: 15,
        questions: [
          JourneyQuestion(
            question: 'Q1?',
            options: ['A', 'B', 'C', 'D'],
            correctIndex: 1,
            explanation: 'Explanation 1',
          ),
          JourneyQuestion(
            question: 'Q2?',
            options: ['A', 'B', 'C', 'D'],
            correctIndex: 2,
            explanation: 'Explanation 2',
          ),
          JourneyQuestion(
            question: 'Q3?',
            options: ['A', 'B', 'C', 'D'],
            correctIndex: 0,
            explanation: 'Explanation 3',
          ),
        ],
      );
    });

    group('construction', () {
      test('creates with all required fields', () {
        expect(event.order, 0);
        expect(event.id, 'prophecies_of_messiah');
        expect(event.title, 'Prophecies of the Messiah');
        expect(event.subtitle.isNotEmpty, true);
        expect(event.narrative.isNotEmpty, true);
        expect(event.bibleReference.isNotEmpty, true);
        expect(event.keyVerse.isNotEmpty, true);
        expect(event.keyVerseReference.isNotEmpty, true);
        expect(event.spiritualTakeaway.isNotEmpty, true);
        expect(event.questions.length, 3);
        expect(event.xpReward, 15);
      });

      test('xpReward defaults to 15', () {
        const e = JesusJourneyEvent(
          order: 0,
          id: 'test',
          title: 'Test',
          subtitle: 'Sub',
          narrative: 'Nar',
          bibleReference: 'Ref',
          keyVerse: 'Verse',
          keyVerseReference: 'VRef',
          spiritualTakeaway: 'Take',
          questions: [],
          themeColor: Color(0xFF000000),
          iconName: 'icon',
        );
        expect(e.xpReward, 15);
      });
    });

    group('JSON serialization', () {
      test('toJson produces correct map', () {
        final json = event.toJson();
        expect(json['order'], 0);
        expect(json['id'], 'prophecies_of_messiah');
        expect(json['title'], 'Prophecies of the Messiah');
        expect(json['questions'], isA<List>());
        expect((json['questions'] as List).length, 3);
        expect(json['xpReward'], 15);
      });

      test('round-trip toJson -> fromJson preserves data', () {
        final json = event.toJson();
        final restored = JesusJourneyEvent.fromJson(json);
        expect(restored.order, event.order);
        expect(restored.id, event.id);
        expect(restored.title, event.title);
        expect(restored.subtitle, event.subtitle);
        expect(restored.narrative, event.narrative);
        expect(restored.bibleReference, event.bibleReference);
        expect(restored.keyVerse, event.keyVerse);
        expect(restored.keyVerseReference, event.keyVerseReference);
        expect(restored.spiritualTakeaway, event.spiritualTakeaway);
        expect(restored.questions.length, 3);
        expect(restored.iconName, event.iconName);
        expect(restored.xpReward, event.xpReward);
      });

      test('question data preserved through event JSON round-trip', () {
        final json = event.toJson();
        final restored = JesusJourneyEvent.fromJson(json);
        expect(restored.questions[0].question, 'Q1?');
        expect(restored.questions[0].correctIndex, 1);
        expect(restored.questions[1].correctIndex, 2);
        expect(restored.questions[2].correctIndex, 0);
      });
    });
  });
}
