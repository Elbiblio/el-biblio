import 'dart:io';

import 'package:elbiblio/core/services/xp_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

void main() {
  late Directory hiveDir;

  setUp(() async {
    hiveDir = await Directory.systemTemp.createTemp('xp_service_test_');
    Hive.init(hiveDir.path);
  });

  tearDown(() async {
    await Hive.close();
    if (hiveDir.existsSync()) {
      await hiveDir.delete(recursive: true);
    }
  });

  test('initialize is safe to call more than once', () async {
    final service = XPService.instance;

    await Future.wait([service.initialize(), service.initialize()]);
    await service.initialize();

    await service.addXP(
      type: XPActivityType.dailyCheckIn,
      description: 'Checked in',
    );

    expect(service.getTotalXP(), XPRewards.dailyCheckIn);
  });
}
