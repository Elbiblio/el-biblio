import 'package:flutter/material.dart';

import '../services/sound_service.dart';

/// Stops ambient audio when a route is popped or replaced so that sounds
/// from one screen never bleed into the next.
///
/// Wire into [GoRouter.observers] alongside other route observers. Obtain the
/// [SoundService] instance from the [soundServiceProvider] before creating the
/// router and pass it here.
class SoundRouteObserver extends RouteObserver<PageRoute<dynamic>> {
  SoundRouteObserver(this._soundService);

  final SoundService _soundService;

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _soundService.stopAmbient();
    super.didPop(route, previousRoute);
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    _soundService.stopAmbient();
    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);
  }
}
