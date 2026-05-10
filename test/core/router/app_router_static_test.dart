import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('/reflect opens ReflectScreen instead of redirecting to commit', () {
    final source = File('lib/core/router/app_router.dart').readAsStringSync();

    expect(
      source,
      contains(
        "import '../../features/vision/presentation/screens/reflect_screen.dart';",
      ),
    );
    expect(source, contains('path: AppRoutes.reflect'));
    expect(source, contains('const ReflectScreen()'));
    expect(
      source,
      isNot(contains('path: AppRoutes.reflect,\n            redirect:')),
    );
  });
}
