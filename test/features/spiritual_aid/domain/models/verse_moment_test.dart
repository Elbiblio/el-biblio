import 'package:flutter_test/flutter_test.dart';
import 'package:elbiblio/features/spiritual_aid/domain/models/verse_moment.dart';

void main() {
  group('VerseMoment', () {
    late VerseMoment moment;
    late DateTime fixedDate;

    setUp(() {
      fixedDate = DateTime(2025, 6, 15, 10, 30);
      moment = VerseMoment(
        verseText: 'For God so loved the world...',
        reference: 'John 3:16',
        bookContext: 'Gospel of John',
        explanation: 'This verse summarizes the gospel message.',
        generatedAt: fixedDate,
        isBookmarked: false,
      );
    });

    group('construction', () {
      test('creates with all fields', () {
        expect(moment.verseText, 'For God so loved the world...');
        expect(moment.reference, 'John 3:16');
        expect(moment.bookContext, 'Gospel of John');
        expect(moment.explanation, 'This verse summarizes the gospel message.');
        expect(moment.generatedAt, fixedDate);
        expect(moment.isBookmarked, false);
      });

      test('optional fields can be null', () {
        final minimal = VerseMoment(
          verseText: 'Be still and know.',
          reference: 'Psalm 46:10',
          generatedAt: fixedDate,
        );
        expect(minimal.bookContext, isNull);
        expect(minimal.explanation, isNull);
        expect(minimal.isBookmarked, false);
      });
    });

    group('copyWith', () {
      test('returns identical copy when no args', () {
        final copy = moment.copyWith();
        expect(copy.verseText, moment.verseText);
        expect(copy.reference, moment.reference);
        expect(copy.bookContext, moment.bookContext);
        expect(copy.explanation, moment.explanation);
        expect(copy.generatedAt, moment.generatedAt);
        expect(copy.isBookmarked, moment.isBookmarked);
      });

      test('can toggle isBookmarked', () {
        final copy = moment.copyWith(isBookmarked: true);
        expect(copy.isBookmarked, true);
        expect(copy.verseText, moment.verseText);
      });
    });

    group('JSON serialization', () {
      test('toJson produces correct map with all fields', () {
        final json = moment.toJson();
        expect(json['verseText'], 'For God so loved the world...');
        expect(json['reference'], 'John 3:16');
        expect(json['bookContext'], 'Gospel of John');
        expect(json['explanation'], isNotNull);
        expect(json['generatedAt'], fixedDate.toIso8601String());
        expect(json['isBookmarked'], false);
      });

      test('toJson handles null optional fields', () {
        final minimal = VerseMoment(
          verseText: 'Text',
          reference: 'Ref',
          generatedAt: fixedDate,
        );
        final json = minimal.toJson();
        expect(json['bookContext'], isNull);
        expect(json['explanation'], isNull);
      });

      test('round-trip toJson -> fromJson preserves all data', () {
        final json = moment.toJson();
        final restored = VerseMoment.fromJson(json);
        expect(restored.verseText, moment.verseText);
        expect(restored.reference, moment.reference);
        expect(restored.bookContext, moment.bookContext);
        expect(restored.explanation, moment.explanation);
        expect(restored.generatedAt, moment.generatedAt);
        expect(restored.isBookmarked, moment.isBookmarked);
      });

      test('fromJson handles missing optional fields', () {
        final json = {
          'verseText': 'Text',
          'reference': 'Ref',
          'generatedAt': fixedDate.toIso8601String(),
        };
        final restored = VerseMoment.fromJson(json);
        expect(restored.bookContext, isNull);
        expect(restored.explanation, isNull);
        expect(restored.isBookmarked, false);
      });
    });
  });
}
