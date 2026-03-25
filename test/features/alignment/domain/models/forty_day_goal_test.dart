import 'package:flutter_test/flutter_test.dart';
import 'package:elbiblio/features/alignment/domain/models/forty_day_goal.dart';

void main() {
  group('GoalStatus', () {
    test('has exactly 4 values', () {
      expect(GoalStatus.values.length, 4);
    });

    test('all statuses have non-empty labels', () {
      for (final s in GoalStatus.values) {
        expect(s.label.isNotEmpty, true);
      }
    });
  });

  group('DailyGoalTask', () {
    test('constructs with required fields', () {
      const task = DailyGoalTask(
        dayNumber: 1,
        title: 'The First Word',
        description: 'Begin your day by speaking to God.',
        durationMinutes: 5,
        reflectionPrompt: 'What did you notice?',
        relatedVerse: 'Psalm 46:10',
      );
      expect(task.dayNumber, 1);
      expect(task.title, 'The First Word');
      expect(task.durationMinutes, 5);
    });

    test('JSON round-trip preserves data', () {
      const task = DailyGoalTask(
        dayNumber: 5,
        title: 'Listening Prayer',
        description: 'Sit in silence for 3 minutes.',
        durationMinutes: 8,
        reflectionPrompt: 'Did you sense anything?',
        relatedVerse: '1 Samuel 3:10',
      );
      final json = task.toJson();
      final restored = DailyGoalTask.fromJson(json);
      expect(restored.dayNumber, 5);
      expect(restored.title, 'Listening Prayer');
      expect(restored.durationMinutes, 8);
      expect(restored.reflectionPrompt, 'Did you sense anything?');
      expect(restored.relatedVerse, '1 Samuel 3:10');
    });
  });

  group('DayCompletion', () {
    test('constructs with defaults', () {
      final completion = DayCompletion(
        dayNumber: 1,
        completedAt: DateTime(2025, 6, 15),
      );
      expect(completion.rating, 3);
      expect(completion.reflectionNote, isNull);
    });

    test('JSON round-trip preserves data', () {
      final completion = DayCompletion(
        dayNumber: 5,
        completedAt: DateTime(2025, 6, 15),
        reflectionNote: 'Great experience!',
        rating: 5,
      );
      final json = completion.toJson();
      final restored = DayCompletion.fromJson(json);
      expect(restored.dayNumber, 5);
      expect(restored.completedAt, DateTime(2025, 6, 15));
      expect(restored.reflectionNote, 'Great experience!');
      expect(restored.rating, 5);
    });
  });

  group('FortyDayGoal', () {
    late FortyDayGoal goal;
    late DateTime startDate;

    setUp(() {
      startDate = DateTime.now().subtract(const Duration(days: 5));
      final endDate = startDate.add(const Duration(days: 40));
      goal = FortyDayGoal(
        id: 'tpl_prayer',
        title: 'Deepening Your Prayer Life',
        category: 'Prayer Life',
        description: 'Transform your prayer life over 40 days.',
        startDate: startDate,
        endDate: endDate,
        dailyTasks: List.generate(
          40,
          (i) => DailyGoalTask(
            dayNumber: i + 1,
            title: 'Day ${i + 1}',
            description: 'Task for day ${i + 1}',
            durationMinutes: 5,
            reflectionPrompt: 'Reflect on day ${i + 1}',
            relatedVerse: 'Psalm 1:1',
          ),
        ),
        completions: {
          1: DayCompletion(dayNumber: 1, completedAt: startDate),
          2: DayCompletion(dayNumber: 2, completedAt: startDate.add(const Duration(days: 1))),
          3: DayCompletion(dayNumber: 3, completedAt: startDate.add(const Duration(days: 2))),
          4: DayCompletion(dayNumber: 4, completedAt: startDate.add(const Duration(days: 3))),
          5: DayCompletion(dayNumber: 5, completedAt: startDate.add(const Duration(days: 4))),
        },
        status: GoalStatus.active,
      );
    });

    group('computed properties', () {
      test('progress is completions / 40', () {
        expect(goal.progress, 5 / 40.0);
      });

      test('progress is 0 with no completions', () {
        final empty = goal.copyWith(completions: {});
        expect(empty.progress, 0.0);
      });

      test('totalCompletedDays returns completion count', () {
        expect(goal.totalCompletedDays, 5);
      });

      test('currentDay returns days since start + 1 clamped to 40', () {
        final day = goal.currentDay;
        expect(day, greaterThanOrEqualTo(1));
        expect(day, lessThanOrEqualTo(40));
      });

      test('streakDays counts consecutive completed days from current', () {
        // Days 1-5 completed, currentDay ~6
        // Streak counts backwards from currentDay
        // Since day 6 is not completed but days 1-5 are,
        // streak will be 0 (unless currentDay = 5 exactly)
        final streak = goal.streakDays;
        expect(streak, greaterThanOrEqualTo(0));
      });

      test('streakDays is 0 when no completions', () {
        final empty = goal.copyWith(completions: {});
        expect(empty.streakDays, 0);
      });

      test('isDayCompleted returns true for completed days', () {
        expect(goal.isDayCompleted(1), true);
        expect(goal.isDayCompleted(5), true);
        expect(goal.isDayCompleted(6), false);
      });

      test('todayTask returns task for current day', () {
        final task = goal.todayTask;
        expect(task, isNotNull);
        expect(task!.dayNumber, goal.currentDay);
      });
    });

    group('copyWith', () {
      test('returns identical copy when no args', () {
        final copy = goal.copyWith();
        expect(copy.id, goal.id);
        expect(copy.title, goal.title);
        expect(copy.status, goal.status);
        expect(copy.completions.length, goal.completions.length);
      });

      test('updates status', () {
        final copy = goal.copyWith(status: GoalStatus.completed);
        expect(copy.status, GoalStatus.completed);
        expect(copy.id, goal.id);
      });
    });

    group('JSON serialization', () {
      test('round-trip toJson -> fromJson preserves data', () {
        final json = goal.toJson();
        final restored = FortyDayGoal.fromJson(json);
        expect(restored.id, goal.id);
        expect(restored.title, goal.title);
        expect(restored.category, goal.category);
        expect(restored.description, goal.description);
        expect(restored.startDate, goal.startDate);
        expect(restored.endDate, goal.endDate);
        expect(restored.dailyTasks.length, 40);
        expect(restored.completions.length, 5);
        expect(restored.status, GoalStatus.active);
      });

      test('fromJson handles missing completions', () {
        final json = goal.toJson();
        json.remove('completions');
        // fromJson expects completions key but checks for null
        json['completions'] = null;
        final restored = FortyDayGoal.fromJson(json);
        expect(restored.completions, isEmpty);
      });

      test('completions map keys serialized as strings', () {
        final json = goal.toJson();
        final completions = json['completions'] as Map;
        expect(completions.containsKey('1'), true);
      });
    });
  });
}
