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
}
