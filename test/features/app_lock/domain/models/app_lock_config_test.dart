import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:elbiblio/features/app_lock/domain/models/app_lock_config.dart';

void main() {
  group('AppLockConfig', () {
    late AppLockConfig config;
    late DateTime fixedDate;

    setUp(() {
      fixedDate = DateTime(2025, 6, 15, 10, 30);
      config = AppLockConfig(
        id: 'lock_1',
        appName: 'Instagram',
        packageName: 'com.instagram.android',
        dailyLimitMinutes: 60,
        isEnabled: true,
        category: 'social',
        createdAt: fixedDate,
      );
    });

    group('construction', () {
      test('creates with all required fields', () {
        expect(config.id, 'lock_1');
        expect(config.appName, 'Instagram');
        expect(config.packageName, 'com.instagram.android');
        expect(config.dailyLimitMinutes, 60);
        expect(config.isEnabled, true);
        expect(config.category, 'social');
        expect(config.createdAt, fixedDate);
      });

      test('defaults isEnabled to true', () {
        final c = AppLockConfig(
          id: 'lock_2',
          appName: 'TikTok',
          packageName: 'com.tiktok.android',
          dailyLimitMinutes: 30,
          category: 'social',
        );
        expect(c.isEnabled, true);
      });

      test('defaults createdAt to DateTime.now() when not provided', () {
        final before = DateTime.now();
        final c = AppLockConfig(
          id: 'lock_3',
          appName: 'YouTube',
          packageName: 'com.google.android.youtube',
          dailyLimitMinutes: 90,
          category: 'entertainment',
        );
        final after = DateTime.now();
        expect(c.createdAt.isAfter(before.subtract(const Duration(seconds: 1))), true);
        expect(c.createdAt.isBefore(after.add(const Duration(seconds: 1))), true);
      });
    });

    group('copyWith', () {
      test('returns identical copy when no args', () {
        final copy = config.copyWith();
        expect(copy.id, config.id);
        expect(copy.appName, config.appName);
        expect(copy.packageName, config.packageName);
        expect(copy.dailyLimitMinutes, config.dailyLimitMinutes);
        expect(copy.isEnabled, config.isEnabled);
        expect(copy.category, config.category);
        expect(copy.createdAt, config.createdAt);
      });

      test('updates only specified fields', () {
        final copy = config.copyWith(
          dailyLimitMinutes: 30,
          isEnabled: false,
        );
        expect(copy.dailyLimitMinutes, 30);
        expect(copy.isEnabled, false);
        expect(copy.id, config.id);
        expect(copy.appName, config.appName);
      });

      test('can update all fields', () {
        final newDate = DateTime(2025, 12, 25);
        final copy = config.copyWith(
          id: 'new_id',
          appName: 'Facebook',
          packageName: 'com.facebook.katana',
          dailyLimitMinutes: 45,
          isEnabled: false,
          category: 'entertainment',
          createdAt: newDate,
        );
        expect(copy.id, 'new_id');
        expect(copy.appName, 'Facebook');
        expect(copy.packageName, 'com.facebook.katana');
        expect(copy.dailyLimitMinutes, 45);
        expect(copy.isEnabled, false);
        expect(copy.category, 'entertainment');
        expect(copy.createdAt, newDate);
      });
    });

    group('JSON serialization', () {
      test('toJson produces correct map', () {
        final json = config.toJson();
        expect(json['id'], 'lock_1');
        expect(json['appName'], 'Instagram');
        expect(json['packageName'], 'com.instagram.android');
        expect(json['dailyLimitMinutes'], 60);
        expect(json['isEnabled'], true);
        expect(json['category'], 'social');
        expect(json['createdAt'], fixedDate.toIso8601String());
      });

      test('fromJson reconstructs correctly', () {
        final json = config.toJson();
        final restored = AppLockConfig.fromJson(json);
        expect(restored.id, config.id);
        expect(restored.appName, config.appName);
        expect(restored.packageName, config.packageName);
        expect(restored.dailyLimitMinutes, config.dailyLimitMinutes);
        expect(restored.isEnabled, config.isEnabled);
        expect(restored.category, config.category);
        expect(restored.createdAt, config.createdAt);
      });

      test('fromJson defaults isEnabled to true when missing', () {
        final json = config.toJson();
        json.remove('isEnabled');
        final restored = AppLockConfig.fromJson(json);
        expect(restored.isEnabled, true);
      });

      test('round-trip toJson -> fromJson preserves all data', () {
        final json = config.toJson();
        final restored = AppLockConfig.fromJson(json);
        final json2 = restored.toJson();
        expect(json, json2);
      });
    });

    group('encode / decode', () {
      test('encode produces valid JSON string', () {
        final encoded = config.encode();
        final decoded = jsonDecode(encoded);
        expect(decoded, isA<Map<String, dynamic>>());
        expect(decoded['id'], config.id);
      });

      test('decode restores from encoded string', () {
        final encoded = config.encode();
        final restored = AppLockConfig.decode(encoded);
        expect(restored.id, config.id);
        expect(restored.appName, config.appName);
      });

      test('round-trip encode -> decode preserves data', () {
        final encoded = config.encode();
        final restored = AppLockConfig.decode(encoded);
        expect(restored.toJson(), config.toJson());
      });
    });
  });
}
