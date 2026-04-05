import 'package:flutter_test/flutter_test.dart';
import 'package:elbiblio/features/app_lock/domain/models/app_usage_record.dart';

void main() {
  group('UsageSession', () {
    test('constructs with required fields', () {
      final session = UsageSession(
        startTime: DateTime(2025, 6, 15, 10, 0),
        durationMinutes: 15,
      );
      expect(session.startTime, DateTime(2025, 6, 15, 10, 0));
      expect(session.endTime, isNull);
      expect(session.durationMinutes, 15);
    });

    test('constructs with optional endTime', () {
      final session = UsageSession(
        startTime: DateTime(2025, 6, 15, 10, 0),
        endTime: DateTime(2025, 6, 15, 10, 15),
        durationMinutes: 15,
      );
      expect(session.endTime, DateTime(2025, 6, 15, 10, 15));
    });

    test('JSON round-trip without endTime', () {
      final session = UsageSession(
        startTime: DateTime(2025, 6, 15, 10, 0),
        durationMinutes: 20,
      );
      final json = session.toJson();
      final restored = UsageSession.fromJson(json);
      expect(restored.startTime, session.startTime);
      expect(restored.endTime, isNull);
      expect(restored.durationMinutes, session.durationMinutes);
    });

    test('JSON round-trip with endTime', () {
      final session = UsageSession(
        startTime: DateTime(2025, 6, 15, 10, 0),
        endTime: DateTime(2025, 6, 15, 10, 30),
        durationMinutes: 30,
      );
      final json = session.toJson();
      final restored = UsageSession.fromJson(json);
      expect(restored.startTime, session.startTime);
      expect(restored.endTime, session.endTime);
      expect(restored.durationMinutes, session.durationMinutes);
    });
  });

  group('AppUsageRecord', () {
    late AppUsageRecord record;
    late DateTime fixedDate;

    setUp(() {
      fixedDate = DateTime(2025, 6, 15);
      record = AppUsageRecord(
        packageName: 'com.instagram.android',
        appName: 'Instagram',
        usedMinutesToday: 45,
        dailyLimitMinutes: 60,
        date: fixedDate,
        sessions: [
          UsageSession(
            startTime: DateTime(2025, 6, 15, 9, 0),
            endTime: DateTime(2025, 6, 15, 9, 30),
            durationMinutes: 30,
          ),
          UsageSession(
            startTime: DateTime(2025, 6, 15, 14, 0),
            endTime: DateTime(2025, 6, 15, 14, 15),
            durationMinutes: 15,
          ),
        ],
      );
    });

    group('computed properties', () {
      test('usagePercentage returns correct ratio', () {
        expect(record.usagePercentage, 0.75);
      });

      test('usagePercentage clamps at 1.0 when over limit', () {
        final over = record.copyWith(usedMinutesToday: 90);
        expect(over.usagePercentage, 1.0);
      });

      test('usagePercentage is 0.0 when dailyLimitMinutes is 0', () {
        final zero = record.copyWith(dailyLimitMinutes: 0);
        expect(zero.usagePercentage, 0.0);
      });

      test('usagePercentage clamps at 0.0 for negative usage', () {
        final neg = record.copyWith(usedMinutesToday: -5);
        expect(neg.usagePercentage, 0.0);
      });

      test('isLimitReached returns false when under limit', () {
        expect(record.isLimitReached, false);
      });

      test('isLimitReached returns true when at limit', () {
        final atLimit = record.copyWith(usedMinutesToday: 60);
        expect(atLimit.isLimitReached, true);
      });

      test('isLimitReached returns true when over limit', () {
        final over = record.copyWith(usedMinutesToday: 90);
        expect(over.isLimitReached, true);
      });

      test('remainingMinutes returns correct value', () {
        expect(record.remainingMinutes, 15);
      });

      test('remainingMinutes clamps at 0 when over limit', () {
        final over = record.copyWith(usedMinutesToday: 90);
        expect(over.remainingMinutes, 0);
      });

      test('remainingMinutes equals dailyLimitMinutes when no usage', () {
        final noUsage = record.copyWith(usedMinutesToday: 0);
        expect(noUsage.remainingMinutes, 60);
      });
    });

    group('copyWith', () {
      test('returns identical copy when no args', () {
        final copy = record.copyWith();
        expect(copy.packageName, record.packageName);
        expect(copy.appName, record.appName);
        expect(copy.usedMinutesToday, record.usedMinutesToday);
        expect(copy.dailyLimitMinutes, record.dailyLimitMinutes);
        expect(copy.date, record.date);
        expect(copy.sessions.length, record.sessions.length);
      });

      test('updates only specified fields', () {
        final copy = record.copyWith(usedMinutesToday: 50);
        expect(copy.usedMinutesToday, 50);
        expect(copy.appName, record.appName);
      });
    });

    group('JSON serialization', () {
      test('toJson produces correct map', () {
        final json = record.toJson();
        expect(json['packageName'], 'com.instagram.android');
        expect(json['appName'], 'Instagram');
        expect(json['usedMinutesToday'], 45);
        expect(json['dailyLimitMinutes'], 60);
        expect(json['sessions'], isA<List>());
        expect((json['sessions'] as List).length, 2);
      });

      test('round-trip toJson -> fromJson preserves all data', () {
        final json = record.toJson();
        final restored = AppUsageRecord.fromJson(json);
        expect(restored.packageName, record.packageName);
        expect(restored.appName, record.appName);
        expect(restored.usedMinutesToday, record.usedMinutesToday);
        expect(restored.dailyLimitMinutes, record.dailyLimitMinutes);
        expect(restored.date, record.date);
        expect(restored.sessions.length, 2);
        expect(restored.sessions[0].durationMinutes, 30);
        expect(restored.sessions[1].durationMinutes, 15);
      });

      test('fromJson handles missing sessions gracefully', () {
        final json = record.toJson();
        json.remove('sessions');
        final restored = AppUsageRecord.fromJson(json);
        expect(restored.sessions, isEmpty);
      });

      test('default sessions is empty list', () {
        final noSessions = AppUsageRecord(
          packageName: 'test',
          appName: 'Test',
          usedMinutesToday: 0,
          dailyLimitMinutes: 30,
          date: fixedDate,
        );
        expect(noSessions.sessions, isEmpty);
      });
    });

    group('encode / decode', () {
      test('round-trip encode -> decode preserves data', () {
        final encoded = record.encode();
        final restored = AppUsageRecord.decode(encoded);
        expect(restored.packageName, record.packageName);
        expect(restored.usedMinutesToday, record.usedMinutesToday);
        expect(restored.sessions.length, record.sessions.length);
      });
    });
  });
}
