import 'package:flutter_test/flutter_test.dart';
import 'package:elbiblio/features/spiritual_aid/data/faith_prompt_catalog.dart';
import 'package:elbiblio/features/spiritual_aid/domain/models/faith_prompt.dart';

void main() {
  group('FaithPromptCatalog', () {
    test('has 30 total prompts (5 per category x 6 categories)', () {
      expect(FaithPromptCatalog.all.length, 30);
    });

    test('all prompts have unique ids', () {
      final ids = FaithPromptCatalog.all.map((p) => p.id).toSet();
      expect(ids.length, FaithPromptCatalog.all.length);
    });

    test('all prompts have non-empty question', () {
      for (final p in FaithPromptCatalog.all) {
        expect(p.question.isNotEmpty, true,
            reason: 'Prompt ${p.id} should have a non-empty question');
      }
    });

    test('all prompts have non-empty context', () {
      for (final p in FaithPromptCatalog.all) {
        expect(p.context.isNotEmpty, true,
            reason: 'Prompt ${p.id} should have a non-empty context');
      }
    });

    test('all prompts have non-empty category', () {
      for (final p in FaithPromptCatalog.all) {
        expect(p.category.isNotEmpty, true,
            reason: 'Prompt ${p.id} should have a non-empty category');
      }
    });

    test('all prompts have related scripture', () {
      for (final p in FaithPromptCatalog.all) {
        expect(p.relatedScripture.isNotEmpty, true,
            reason: 'Prompt ${p.id} should have related scripture');
        expect(p.scriptureReference.isNotEmpty, true,
            reason: 'Prompt ${p.id} should have a scripture reference');
      }
    });

    test('all prompts have discussion starters', () {
      for (final p in FaithPromptCatalog.all) {
        expect(p.discussionStarters.isNotEmpty, true,
            reason: 'Prompt ${p.id} should have discussion starters');
        for (final starter in p.discussionStarters) {
          expect(starter.isNotEmpty, true,
              reason: 'Prompt ${p.id} has an empty discussion starter');
        }
      }
    });

    test('prompts cover all 6 categories', () {
      final categories = FaithPromptCatalog.all.map((p) => p.category).toSet();
      for (final cat in FaithPrompt.categories) {
        expect(categories.contains(cat), true,
            reason: 'Category "$cat" should have prompts');
      }
    });

    test('each category has exactly 5 prompts', () {
      for (final cat in FaithPrompt.categories) {
        final count = FaithPromptCatalog.byCategory(cat).length;
        expect(count, 5, reason: 'Category "$cat" should have 5 prompts, got $count');
      }
    });

    test('all prompt categories are valid', () {
      for (final p in FaithPromptCatalog.all) {
        expect(FaithPrompt.categories.contains(p.category), true,
            reason: 'Prompt ${p.id} has invalid category "${p.category}"');
      }
    });

    group('getDailyPrompt', () {
      test('returns a valid prompt', () {
        final prompt = FaithPromptCatalog.getDailyPrompt();
        expect(prompt, isNotNull);
        expect(prompt.question.isNotEmpty, true);
      });
    });

    group('byCategory', () {
      test('returns correct prompts for theology', () {
        final prompts = FaithPromptCatalog.byCategory('theology');
        expect(prompts.length, 5);
        for (final p in prompts) {
          expect(p.category, 'theology');
        }
      });

      test('returns empty list for unknown category', () {
        final prompts = FaithPromptCatalog.byCategory('nonexistent');
        expect(prompts, isEmpty);
      });
    });

    group('byId', () {
      test('returns prompt for valid id', () {
        final prompt = FaithPromptCatalog.byId('theo_01');
        expect(prompt, isNotNull);
        expect(prompt!.id, 'theo_01');
      });

      test('returns null for invalid id', () {
        final prompt = FaithPromptCatalog.byId('nonexistent');
        expect(prompt, isNull);
      });
    });
  });
}
