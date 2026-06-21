import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../di/app_providers.dart';

/// Observes app lifecycle to pause/resume ambient audio when the app
/// is backgrounded or foregrounded.
class SoundLifecycleObserver extends WidgetsBindingObserver {
  SoundLifecycleObserver(this._ref);

  final WidgetRef _ref;
  bool _isInitialized = false;

  void initialize() {
    if (_isInitialized) return;
    _isInitialized = true;
    WidgetsBinding.instance.addObserver(this);
  }

  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final service = _ref.read(soundServiceProvider);
    switch (state) {
      case AppLifecycleState.paused:
      case AppLifecycleState.detached:
      case AppLifecycleState.hidden:
        service.setAppPaused(true);
      case AppLifecycleState.resumed:
        service.setAppPaused(false);
      case AppLifecycleState.inactive:
        break;
    }
  }
}
