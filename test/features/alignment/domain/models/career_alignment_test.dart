import 'package:flutter_test/flutter_test.dart';
import 'package:elbiblio/features/alignment/domain/models/career_alignment.dart';

void main() {
  group('SpiritualGift', () {
    test('constructs with required fields', () {
      const gift = SpiritualGift(
        name: 'Creative Expression',
        description: 'The ability to bring beauty and truth to life.',
        strength: 0.9,
        biblicalExample: 'Bezalel was filled with the Spirit.',
      );
      expect(gift.name, 'Creative Expression');
      expect(gift.strength, 0.9);
    });

    test('JSON round-trip preserves data', () {
      const gift = SpiritualGift(
        name: 'Discernment',
        description: 'Perceiving spiritual realities.',
        strength: 0.85,
        biblicalExample: 'Nehemiah discerned the plots.',
      );
      final json = gift.toJson();
      final restored = SpiritualGift.fromJson(json);
      expect(restored.name, gift.name);
      expect(restored.description, gift.description);
      expect(restored.strength, gift.strength);
      expect(restored.biblicalExample, gift.biblicalExample);
    });
  });

  group('CareerPath', () {
    test('constructs with required fields', () {
      const path = CareerPath(
        title: 'Creative Arts',
        description: 'Music, visual arts, filmmaking.',
        alignedGifts: ['Creative Expression', 'Prophetic Imagination'],
        whyItFits: 'Your ability to see beauty uniquely equips you.',
      );
      expect(path.title, 'Creative Arts');
      expect(path.alignedGifts.length, 2);
    });

    test('JSON round-trip preserves data', () {
      const path = CareerPath(
        title: 'Law and Justice',
        description: 'Legal practice, advocacy.',
        alignedGifts: ['Discernment', 'Protection'],
        whyItFits: 'Your sense of justice translates to defending the vulnerable.',
      );
      final json = path.toJson();
      final restored = CareerPath.fromJson(json);
      expect(restored.title, path.title);
      expect(restored.description, path.description);
      expect(restored.alignedGifts, path.alignedGifts);
      expect(restored.whyItFits, path.whyItFits);
    });
  });

  group('CareerAlignment', () {
    late CareerAlignment alignment;

    setUp(() {
      alignment = const CareerAlignment(
        archetypeId: 'Artisan',
        spiritualGifts: [
          SpiritualGift(
            name: 'Creative Expression',
            description: 'Bring beauty to life.',
            strength: 0.9,
            biblicalExample: 'Bezalel crafted the tabernacle.',
          ),
          SpiritualGift(
            name: 'Innovation',
            description: 'Finding new ways.',
            strength: 0.7,
            biblicalExample: 'Jesus used parables.',
          ),
        ],
        suggestedPaths: [
          CareerPath(
            title: 'Creative Arts',
            description: 'Music, visual arts.',
            alignedGifts: ['Creative Expression'],
            whyItFits: 'Your creativity shines here.',
          ),
        ],
        callingStatement: 'You are called to reveal beauty.',
        nextSteps: ['Identify your medium.', 'Use creativity in church.'],
        resources: ['Walking on Water', 'Art and the Bible'],
      );
    });

    group('construction', () {
      test('creates with all required fields', () {
        expect(alignment.archetypeId, 'Artisan');
        expect(alignment.spiritualGifts.length, 2);
        expect(alignment.suggestedPaths.length, 1);
        expect(alignment.callingStatement.isNotEmpty, true);
        expect(alignment.nextSteps.length, 2);
        expect(alignment.resources.length, 2);
      });
    });

    group('JSON serialization', () {
      test('toJson produces correct map', () {
        final json = alignment.toJson();
        expect(json['archetypeId'], 'Artisan');
        expect(json['spiritualGifts'], isA<List>());
        expect((json['spiritualGifts'] as List).length, 2);
        expect(json['suggestedPaths'], isA<List>());
        expect(json['callingStatement'], isA<String>());
        expect(json['nextSteps'], isA<List>());
        expect(json['resources'], isA<List>());
      });

      test('round-trip toJson -> fromJson preserves data', () {
        final json = alignment.toJson();
        final restored = CareerAlignment.fromJson(json);
        expect(restored.archetypeId, alignment.archetypeId);
        expect(restored.spiritualGifts.length, alignment.spiritualGifts.length);
        expect(restored.spiritualGifts[0].name, 'Creative Expression');
        expect(restored.spiritualGifts[0].strength, 0.9);
        expect(restored.suggestedPaths.length, alignment.suggestedPaths.length);
        expect(restored.suggestedPaths[0].title, 'Creative Arts');
        expect(restored.callingStatement, alignment.callingStatement);
        expect(restored.nextSteps, alignment.nextSteps);
        expect(restored.resources, alignment.resources);
      });
    });
  });
}
