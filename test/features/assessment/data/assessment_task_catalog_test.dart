import 'package:elbiblio/features/assessment/data/assessment_task_catalog.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AssessmentTaskCatalog', () {
    const catalog = AssessmentTaskCatalog();

    test('returns development tasks for development path', () {
      final tasks = catalog.tasksForPath('development');
      expect(tasks, isNotEmpty);
      expect(tasks.first.id.startsWith('dev_'), isTrue);
    });

    test('falls back to recalibration tasks when path is null', () {
      final tasks = catalog.tasksForPath(null);
      expect(tasks, isNotEmpty);
      expect(tasks.first.id.startsWith('rec_'), isTrue);
    });

    test('falls back to recalibration tasks for unknown path', () {
      final tasks = catalog.tasksForPath('unknown');
      expect(tasks, isNotEmpty);
      expect(tasks.first.id.startsWith('rec_'), isTrue);
    });
  });
}
