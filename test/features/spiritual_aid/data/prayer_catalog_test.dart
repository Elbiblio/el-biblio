import 'package:flutter_test/flutter_test.dart';
import 'package:elbiblio/features/spiritual_aid/data/prayer_catalog.dart';
import 'package:elbiblio/features/spiritual_aid/domain/models/quick_prayer.dart';

void main() {
  group('PrayerCatalog', () {
    test('has 40 total prayers (5 per category x 8 categories)', () {
      expect(PrayerCatalog.all.length, 40);
    });

    test('all prayers have unique ids', () {
      final ids = PrayerCatalog.all.map((p) => p.id).toSet();
      expect(ids.length, PrayerCatalog.all.length);
    });

    test('all prayers have non-empty title', () {
      for (final p in PrayerCatalog.all) {
        expect(p.title.isNotEmpty, true,
            reason: 'Prayer ${p.id} should have a non-empty title');
      }
    });

    test('all prayers have non-empty body', () {
      for (final p in PrayerCatalog.all) {
        expect(p.body.isNotEmpty, true,
            reason: 'Prayer ${p.id} should have a non-empty body');
      }
    });

    test('all prayers have non-empty category', () {
      for (final p in PrayerCatalog.all) {
        expect(p.category.isNotEmpty, true,
            reason: 'Prayer ${p.id} should have a non-empty category');
      }
    });

    test('all prayers have related verses', () {
      for (final p in PrayerCatalog.all) {
        expect(p.relatedVerse.isNotEmpty, true,
            reason: 'Prayer ${p.id} should have a related verse');
        expect(p.relatedVerseReference.isNotEmpty, true,
            reason: 'Prayer ${p.id} should have a verse reference');
      }
    });

    test('all prayers have positive estimatedSeconds', () {
      for (final p in PrayerCatalog.all) {
        expect(p.estimatedSeconds > 0, true,
            reason: 'Prayer ${p.id} should have positive estimated seconds');
      }
    });

    test('prayers cover all 8 categories', () {
      final categories = PrayerCatalog.all.map((p) => p.category).toSet();
      for (final cat in QuickPrayer.categories) {
        expect(categories.contains(cat), true,
            reason: 'Category "$cat" should have prayers');
      }
    });

    test('each category has exactly 5 prayers', () {
      for (final cat in QuickPrayer.categories) {
        final count = PrayerCatalog.byCategory(cat).length;
        expect(count, 5, reason: 'Category "$cat" should have 5 prayers, got $count');
      }
    });

    test('all prayer categories are valid', () {
      for (final p in PrayerCatalog.all) {
        expect(QuickPrayer.categories.contains(p.category), true,
            reason: 'Prayer ${p.id} has invalid category "${p.category}"');
      }
    });

    group('byCategory', () {
      test('returns correct prayers for anxiety', () {
        final prayers = PrayerCatalog.byCategory('anxiety');
        expect(prayers.length, 5);
        for (final p in prayers) {
          expect(p.category, 'anxiety');
        }
      });

      test('returns empty list for unknown category', () {
        final prayers = PrayerCatalog.byCategory('nonexistent');
        expect(prayers, isEmpty);
      });
    });

    group('byId', () {
      test('returns prayer for valid id', () {
        final prayer = PrayerCatalog.byId('anx_01');
        expect(prayer, isNotNull);
        expect(prayer!.id, 'anx_01');
      });

      test('returns null for invalid id', () {
        final prayer = PrayerCatalog.byId('nonexistent');
        expect(prayer, isNull);
      });
    });
  });
}
