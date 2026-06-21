import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Reads the Android overlay action that launched the app.
///
/// The native [OverlayResponseActivity] forwards the action and payload to
/// MainActivity, which stores them until Flutter consumes them via this
/// channel. This is a no-op on non-Android platforms.
class OverlayResponseService {
  OverlayResponseService._();

  static final OverlayResponseService instance = OverlayResponseService._();

  static const _channel = MethodChannel('com.elbiblio.app/overlay');

  bool get _isAndroid => defaultTargetPlatform == TargetPlatform.android;

  Future<Map<String, dynamic>?> getOverlayAction() async {
    if (!_isAndroid) return null;
    try {
      final result = await _channel.invokeMethod<Map<dynamic, dynamic>>(
        'getOverlayAction',
      );
      if (result == null) return null;
      return {
        'action': result['action'] as String?,
        'payload': result['payload'] as String?,
      };
    } catch (e) {
      return null;
    }
  }

  Future<void> consumeOverlayAction() async {
    if (!_isAndroid) return;
    try {
      await _channel.invokeMethod('consumeOverlayAction');
    } catch (_) {}
  }
}
