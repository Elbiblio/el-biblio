import 'package:flutter_test/flutter_test.dart';
import 'package:elbiblio/features/spiritual_aid/domain/models/quick_prayer.dart';

void main() {
  group('QuickPrayer', () {
    late QuickPrayer prayer;

    setUp(() {
      prayer = const QuickPrayer(
        id: 'anx_01',
        title: 'When Worry Overwhelms',
        body: 'Father, my mind is racing...',
        category: 'anxiety',
        relatedVerse: 'Do not be anxious about anything.',
        relatedVerseReference: 'Philippians 4:6',
        estimatedSeconds: 30,
        isFavorite: false,
      );
    });

    group('construction', () {
      test('creates with all required fields', () {
        expect(prayer.id, 'anx_01');
        expect(prayer.title, 'When Worry Overwhelms');
        expect(prayer.body, 'Father, my mind is racing...');
        expect(prayer.category, 'anxiety');
        expect(prayer.relatedVerse, 'Do not be anxious about anything.');
        expect(prayer.relatedVerseReference, 'Philippians 4:6');
        expect(prayer.estimatedSeconds, 30);
        expect(prayer.isFavorite, false);
      });

      test('isFavorite defaults to false', () {
        const p = QuickPrayer(
          id: 'test',
          title: 'Test',
          body: 'Body',
          category: 'anxiety',
          relatedVerse: 'Verse',
          relatedVerseReference: 'Ref',
          estimatedSeconds: 10,
        );
        expect(p.isFavorite, false);
      });
    });

    group('copyWith', () {
      test('returns identical copy when no args', () {
        final copy = prayer.copyWith();
        expect(copy.id, prayer.id);
        expect(copy.title, prayer.title);
        expect(copy.isFavorite, prayer.isFavorite);
      });

      test('can toggle isFavorite', () {
        final copy = prayer.copyWith(isFavorite: true);
        expect(copy.isFavorite, true);
        expect(copy.id, prayer.id);
      });
    });

    group('JSON serialization', () {
      test('toJson produces correct map', () {
        final json = prayer.toJson();
        expect(json['id'], 'anx_01');
        expect(json['title'], 'When Worry Overwhelms');
        expect(json['category'], 'anxiety');
        expect(json['estimatedSeconds'], 30);
        expect(json['isFavorite'], false);
      });

      test('round-trip toJson -> fromJson preserves data', () {
        final json = prayer.toJson();
        final restored = QuickPrayer.fromJson(json);
        expect(restored.id, prayer.id);
        expect(restored.title, prayer.title);
        expect(restored.body, prayer.body);
        expect(restored.category, prayer.category);
        expect(restored.relatedVerse, prayer.relatedVerse);
        expect(restored.relatedVerseReference, prayer.relatedVerseReference);
        expect(restored.estimatedSeconds, prayer.estimatedSeconds);
        expect(restored.isFavorite, prayer.isFavorite);
      });

      test('fromJson defaults isFavorite to false when missing', () {
        final json = prayer.toJson();
        json.remove('isFavorite');
        final restored = QuickPrayer.fromJson(json);
        expect(restored.isFavorite, false);
      });
    });

    group('categories', () {
      test('has exactly 8 categories', () {
        expect(QuickPrayer.categories.length, 8);
      });

      test('contains expected categories', () {
        expect(QuickPrayer.categories, contains('anxiety'));
        expect(QuickPrayer.categories, contains('gratitude'));
        expect(QuickPrayer.categories, contains('healing'));
        expect(QuickPrayer.categories, contains('strength'));
        expect(QuickPrayer.categories, contains('forgiveness'));
        expect(QuickPrayer.categories, contains('guidance'));
        expect(QuickPrayer.categories, contains('protection'));
        expect(QuickPrayer.categories, contains('peace'));
      });
    });
  });
}
