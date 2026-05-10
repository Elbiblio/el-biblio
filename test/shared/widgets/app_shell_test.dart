import 'package:elbiblio/core/constants/app_routes.dart';
import 'package:elbiblio/shared/widgets/app_shell.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('bottom nav route selection does not match sibling prefixes', () {
    expect(isShellRouteSelected(AppRoutes.grow, AppRoutes.grow), isTrue);
    expect(isShellRouteSelected('/grow/story', AppRoutes.grow), isTrue);
    expect(
      isShellRouteSelected(AppRoutes.growTogether, AppRoutes.grow),
      isFalse,
    );
    expect(
      isShellRouteSelected(AppRoutes.commitmentJourney, AppRoutes.commit),
      isFalse,
    );
  });
}
