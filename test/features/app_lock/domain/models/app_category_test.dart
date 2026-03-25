import 'package:flutter_test/flutter_test.dart';
import 'package:elbiblio/features/app_lock/domain/models/app_category.dart';

void main() {
  group('AppCategory', () {
    test('has exactly 5 values', () {
      expect(AppCategory.values.length, 5);
    });

    test('all categories have non-empty ids', () {
      for (final cat in AppCategory.values) {
        expect(cat.id.isNotEmpty, true, reason: '${cat.name} should have a non-empty id');
      }
    });

    test('all categories have non-empty labels', () {
      for (final cat in AppCategory.values) {
        expect(cat.label.isNotEmpty, true, reason: '${cat.name} should have a non-empty label');
      }
    });

    test('all categories have positive suggestedLimitMinutes', () {
      for (final cat in AppCategory.values) {
        expect(cat.suggestedLimitMinutes > 0, true,
            reason: '${cat.name} should have positive suggestedLimitMinutes');
      }
    });

    test('each category has unique id', () {
      final ids = AppCategory.values.map((c) => c.id).toSet();
      expect(ids.length, AppCategory.values.length);
    });

    test('specific category properties', () {
      expect(AppCategory.social.id, 'social');
      expect(AppCategory.social.label, 'Social Media');
      expect(AppCategory.social.suggestedLimitMinutes, 60);

      expect(AppCategory.entertainment.id, 'entertainment');
      expect(AppCategory.entertainment.suggestedLimitMinutes, 90);

      expect(AppCategory.news.id, 'news');
      expect(AppCategory.news.suggestedLimitMinutes, 30);

      expect(AppCategory.gaming.id, 'gaming');
      expect(AppCategory.gaming.suggestedLimitMinutes, 60);

      expect(AppCategory.other.id, 'other');
    });

    group('fromId', () {
      test('returns correct category for valid id', () {
        expect(AppCategory.fromId('social'), AppCategory.social);
        expect(AppCategory.fromId('entertainment'), AppCategory.entertainment);
        expect(AppCategory.fromId('news'), AppCategory.news);
        expect(AppCategory.fromId('gaming'), AppCategory.gaming);
        expect(AppCategory.fromId('other'), AppCategory.other);
      });

      test('returns other for unknown id', () {
        expect(AppCategory.fromId('unknown'), AppCategory.other);
        expect(AppCategory.fromId(''), AppCategory.other);
      });
    });
  });

  group('PopularApp', () {
    test('popularApps list is not empty', () {
      expect(popularApps.isNotEmpty, true);
    });

    test('all popular apps have non-empty names', () {
      for (final app in popularApps) {
        expect(app.name.isNotEmpty, true);
      }
    });

    test('all popular apps have non-empty package names', () {
      for (final app in popularApps) {
        expect(app.packageName.isNotEmpty, true);
      }
    });

    test('popular apps have unique package names', () {
      final packages = popularApps.map((a) => a.packageName).toSet();
      expect(packages.length, popularApps.length);
    });

    test('popular apps cover multiple categories', () {
      final categories = popularApps.map((a) => a.category).toSet();
      expect(categories.length, greaterThanOrEqualTo(3));
    });
  });
}
