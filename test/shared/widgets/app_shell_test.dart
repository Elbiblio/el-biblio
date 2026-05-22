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

  test('shell chrome only shows on top-level destinations', () {
    expect(shouldShowShellChrome(AppRoutes.today), isTrue);
    expect(shouldShowShellChrome(AppRoutes.commit), isTrue);
    expect(shouldShowShellChrome(AppRoutes.reflect), isTrue);
    expect(shouldShowShellChrome(AppRoutes.tribe), isTrue);
    expect(shouldShowShellChrome(AppRoutes.grow), isTrue);
    expect(shouldShowShellChrome(AppRoutes.profile), isTrue);
    expect(shouldShowShellChrome(AppRoutes.notifications), isFalse);
    expect(shouldShowShellChrome(AppRoutes.bible), isFalse);
    expect(shouldShowShellChrome(AppRoutes.journal), isFalse);
    expect(shouldShowShellChrome(AppRoutes.act), isFalse);
    expect(shouldShowShellChrome(AppRoutes.meditation), isFalse);
    expect(shouldShowShellChrome(AppRoutes.games), isFalse);
    expect(shouldShowShellChrome('${AppRoutes.journal}/new'), isFalse);
    expect(shouldShowShellChrome('${AppRoutes.profile}/reminders'), isFalse);
  });

  test('shell chrome controller stays hidden until all popups close', () {
    final controller = ShellChromeController();
    addTearDown(controller.hideChrome.dispose);

    expect(controller.hideChrome.value, isFalse);

    controller.didPushPopup();
    expect(controller.hideChrome.value, isTrue);

    controller.didPushPopup();
    controller.didPopPopup();
    expect(controller.hideChrome.value, isTrue);

    controller.didPopPopup();
    expect(controller.hideChrome.value, isFalse);

    controller.didPopPopup();
    expect(controller.hideChrome.value, isFalse);
  });

  test('shell chrome controller handles popup route replacements', () {
    final controller = ShellChromeController();
    addTearDown(controller.hideChrome.dispose);

    controller.didReplacePopup(oldRouteWasPopup: false, newRouteIsPopup: true);
    expect(controller.hideChrome.value, isTrue);

    controller.didReplacePopup(oldRouteWasPopup: true, newRouteIsPopup: true);
    expect(controller.hideChrome.value, isTrue);

    controller.didReplacePopup(oldRouteWasPopup: true, newRouteIsPopup: false);
    expect(controller.hideChrome.value, isFalse);
  });
}
