import 'package:flutter_test/flutter_test.dart';
import 'package:elbiblio/features/spiritual_aid/domain/models/faith_prompt.dart';

void main() {
  group('FaithPrompt', () {
    late FaithPrompt prompt;
    late DateTime fixedDate;

    setUp(() {
      fixedDate = DateTime(2025, 1, 1);
      prompt = FaithPrompt(
        id: 'theo_01',
        question: 'What does it mean that God is both just and merciful?',
        context: 'The Bible describes God as perfectly just.',
        category: 'theology',
        relatedScripture: 'The Lord, the Lord, the compassionate...',
        scriptureReference: 'Exodus 34:6-7',
        discussionStarters: [
          'Think of a time you experienced both consequences and mercy.',
          'How does the cross demonstrate justice and mercy together?',
          'Does understanding God\'s justice make His mercy more meaningful?',
        ],
        date: fixedDate,
      );
    });

    group('construction', () {
      test('creates with all required fields', () {
        expect(prompt.id, 'theo_01');
        expect(prompt.question.isNotEmpty, true);
        expect(prompt.context.isNotEmpty, true);
        expect(prompt.category, 'theology');
        expect(prompt.relatedScripture.isNotEmpty, true);
        expect(prompt.scriptureReference, 'Exodus 34:6-7');
        expect(prompt.discussionStarters.length, 3);
        expect(prompt.date, fixedDate);
      });
    });

    group('copyWith', () {
      test('returns identical copy when no args', () {
        final copy = prompt.copyWith();
        expect(copy.id, prompt.id);
        expect(copy.question, prompt.question);
        expect(copy.discussionStarters.length, prompt.discussionStarters.length);
      });

      test('updates specified fields', () {
        final newDate = DateTime(2025, 6, 1);
        final copy = prompt.copyWith(date: newDate, category: 'daily_life');
        expect(copy.date, newDate);
        expect(copy.category, 'daily_life');
        expect(copy.id, prompt.id);
      });
    });

    group('JSON serialization', () {
      test('toJson produces correct map', () {
        final json = prompt.toJson();
        expect(json['id'], 'theo_01');
        expect(json['category'], 'theology');
        expect(json['discussionStarters'], isA<List>());
        expect((json['discussionStarters'] as List).length, 3);
        expect(json['date'], fixedDate.toIso8601String());
      });

      test('round-trip toJson -> fromJson preserves data', () {
        final json = prompt.toJson();
        final restored = FaithPrompt.fromJson(json);
        expect(restored.id, prompt.id);
        expect(restored.question, prompt.question);
        expect(restored.context, prompt.context);
        expect(restored.category, prompt.category);
        expect(restored.relatedScripture, prompt.relatedScripture);
        expect(restored.scriptureReference, prompt.scriptureReference);
        expect(restored.discussionStarters, prompt.discussionStarters);
        expect(restored.date, prompt.date);
      });
    });

    group('categories', () {
      test('has exactly 6 categories', () {
        expect(FaithPrompt.categories.length, 6);
      });

      test('contains expected categories', () {
        expect(FaithPrompt.categories, contains('theology'));
        expect(FaithPrompt.categories, contains('daily_life'));
        expect(FaithPrompt.categories, contains('relationships'));
        expect(FaithPrompt.categories, contains('suffering'));
        expect(FaithPrompt.categories, contains('purpose'));
        expect(FaithPrompt.categories, contains('growth'));
      });
    });
  });
}
