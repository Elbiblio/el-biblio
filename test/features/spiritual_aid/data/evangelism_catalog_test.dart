import 'package:flutter_test/flutter_test.dart';
import 'package:elbiblio/features/spiritual_aid/data/evangelism_catalog.dart';
import 'package:elbiblio/features/spiritual_aid/domain/models/evangelism_content.dart';

void main() {
  group('EvangelismCatalog', () {
    test('has items in the catalog', () {
      expect(EvangelismCatalog.all.isNotEmpty, true);
    });

    test('all items have unique ids', () {
      final ids = EvangelismCatalog.all.map((c) => c.id).toSet();
      expect(ids.length, EvangelismCatalog.all.length);
    });

    test('all items have non-empty title', () {
      for (final c in EvangelismCatalog.all) {
        expect(c.title.isNotEmpty, true,
            reason: 'Item ${c.id} should have a non-empty title');
      }
    });

    test('all items have non-empty body', () {
      for (final c in EvangelismCatalog.all) {
        expect(c.body.isNotEmpty, true,
            reason: 'Item ${c.id} should have a non-empty body');
      }
    });

    test('all items have non-empty category', () {
      for (final c in EvangelismCatalog.all) {
        expect(c.category.isNotEmpty, true,
            reason: 'Item ${c.id} should have a non-empty category');
      }
    });

    test('all items have non-empty type', () {
      for (final c in EvangelismCatalog.all) {
        expect(c.type.isNotEmpty, true,
            reason: 'Item ${c.id} should have a non-empty type');
      }
    });

    test('all item categories are valid', () {
      for (final c in EvangelismCatalog.all) {
        expect(EvangelismContent.categories.contains(c.category), true,
            reason: 'Item ${c.id} has invalid category "${c.category}"');
      }
    });

    test('all item types are valid', () {
      for (final c in EvangelismCatalog.all) {
        expect(EvangelismContent.types.contains(c.type), true,
            reason: 'Item ${c.id} has invalid type "${c.type}"');
      }
    });

    test('has verse_card items', () {
      final verseCards = EvangelismCatalog.byType('verse_card');
      expect(verseCards.isNotEmpty, true);
      expect(verseCards.length, 8);
    });

    test('has testimony_template items', () {
      final templates = EvangelismCatalog.byType('testimony_template');
      expect(templates.isNotEmpty, true);
      expect(templates.length, 6);
    });

    test('has conversation_starter items', () {
      final starters = EvangelismCatalog.byType('conversation_starter');
      expect(starters.isNotEmpty, true);
      expect(starters.length, 8);
    });

    test('has guide items', () {
      final guides = EvangelismCatalog.byType('guide');
      expect(guides.isNotEmpty, true);
      expect(guides.length, 4);
    });

    test('has prayer_card items', () {
      final prayerCards = EvangelismCatalog.byType('prayer_card');
      expect(prayerCards.isNotEmpty, true);
      expect(prayerCards.length, 6);
    });

    test('verse_cards and prayer_cards have related verses', () {
      final withVerses = EvangelismCatalog.all
          .where((c) => c.type == 'verse_card' || c.type == 'prayer_card');
      for (final c in withVerses) {
        expect(c.relatedVerse, isNotNull,
            reason: 'Item ${c.id} of type ${c.type} should have a related verse');
        expect(c.relatedVerse!.isNotEmpty, true,
            reason: 'Item ${c.id} should have a non-empty related verse');
        expect(c.relatedVerseReference, isNotNull,
            reason: 'Item ${c.id} should have a verse reference');
        expect(c.relatedVerseReference!.isNotEmpty, true,
            reason: 'Item ${c.id} should have a non-empty verse reference');
      }
    });

    group('byType', () {
      test('returns only items of specified type', () {
        for (final type in EvangelismContent.types) {
          final items = EvangelismCatalog.byType(type);
          for (final item in items) {
            expect(item.type, type);
          }
        }
      });

      test('returns empty for unknown type', () {
        expect(EvangelismCatalog.byType('unknown'), isEmpty);
      });
    });

    group('byCategory', () {
      test('returns only items of specified category', () {
        for (final cat in EvangelismContent.categories) {
          final items = EvangelismCatalog.byCategory(cat);
          for (final item in items) {
            expect(item.category, cat);
          }
        }
      });
    });

    group('byId', () {
      test('returns item for valid id', () {
        final item = EvangelismCatalog.byId('vc_01');
        expect(item, isNotNull);
        expect(item!.id, 'vc_01');
      });

      test('returns null for invalid id', () {
        expect(EvangelismCatalog.byId('nonexistent'), isNull);
      });
    });
  });
}
