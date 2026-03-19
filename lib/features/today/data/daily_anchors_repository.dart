import 'package:hive/hive.dart';

import '../../../core/repository/base_repository.dart';
import '../../../core/storage/hive_boxes.dart';
import '../../../shared/utils/date_time_formatter.dart';
import '../domain/models/daily_anchors.dart';

class DailyAnchorsRepository extends BaseRepository {
  DailyAnchorsRepository(super.logger);

  Box<DailyAnchors> get _box => Hive.box<DailyAnchors>(HiveBoxes.dailyAnchors);

  Future<DailyAnchors> getForDate(
    DateTime date, {
    required VirtueType virtueType,
  }) {
    return guard(() async {
      final key = DateTimeFormatter.hiveDayKey(date);
      final existing = _box.get(key);
      if (existing != null) {
        return existing;
      }

      final created = DailyAnchorsFactory.forDate(
        date: date,
        virtueType: virtueType,
      );
      await _box.put(key, created);
      return created;
    }, operation: 'get_daily_anchors');
  }

  Future<DailyAnchors> save(DailyAnchors anchors) {
    return guard(() async {
      final key = DateTimeFormatter.hiveDayKey(anchors.date);
      await _box.put(key, anchors);
      return anchors;
    }, operation: 'save_daily_anchors');
  }

  Future<DailyAnchors> updateCompletion(
    DateTime date, {
    required VirtueType fallbackVirtue,
    required AnchorType type,
    required bool isCompleted,
  }) {
    return guard(() async {
      final current = await getForDate(date, virtueType: fallbackVirtue);

      final updated = switch (type) {
        AnchorType.coreVirtue => current.copyWith(
            coreVirtue: current.coreVirtue.copyWith(isCompleted: isCompleted),
          ),
        AnchorType.habit => current.copyWith(
            habit: current.habit.copyWith(isCompleted: isCompleted),
          ),
        AnchorType.energyAction => current.copyWith(
            energyAction: current.energyAction.copyWith(isCompleted: isCompleted),
          ),
      };

      final allCompleted =
          updated.coreVirtue.isCompleted &&
          updated.habit.isCompleted &&
          updated.energyAction.isCompleted;

      final withCompletion = updated.copyWith(isCompleted: allCompleted);
      await _box.put(DateTimeFormatter.hiveDayKey(date), withCompletion);
      return withCompletion;
    }, operation: 'update_anchor_completion');
  }

  Future<List<DailyAnchors>> history() {
    return guard(() async {
      final values = _box.values.toList()
        ..sort((left, right) => right.date.compareTo(left.date));
      return values;
    }, operation: 'daily_anchor_history');
  }

  Future<int> getConsecutiveMissedDays() {
    return guard(() async {
      final now = DateTime.now();
      final values = _box.values.toList()
        ..sort((left, right) => right.date.compareTo(left.date));
      
      int missedCount = 0;
      
      // Check the last 3 days (excluding today)
      for (int i = 0; i < 3 && i < values.length; i++) {
        final anchors = values[i];
        final daysDiff = now.difference(anchors.date).inDays;
        
        // Only count if it's a previous day (not today) and was missed
        if (daysDiff > 0 && daysDiff <= 3 && !anchors.isCompleted) {
          missedCount++;
        } else if (daysDiff > 0 && anchors.isCompleted) {
          // Break if we find a completed day in the range
          break;
        }
      }
      
      return missedCount;
    }, operation: 'check_consecutive_missed_days');
  }
}
