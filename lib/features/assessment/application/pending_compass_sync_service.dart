import 'package:logger/logger.dart';

typedef CompassSubmitter = Future<void> Function(Map<String, dynamic> payload);
typedef PendingCompassClearer = Future<void> Function();

class PendingCompassSyncService {
  PendingCompassSyncService(this._logger);

  final Logger _logger;

  Future<bool> trySync({
    required bool isAuthenticated,
    required Map<String, dynamic>? payload,
    required CompassSubmitter submit,
    required PendingCompassClearer clear,
  }) async {
    if (!isAuthenticated || payload == null || payload.isEmpty) {
      return false;
    }

    try {
      await submit(Map<String, dynamic>.from(payload));
      await clear();
      return true;
    } catch (error, stackTrace) {
      _logger.w(
        'Pending compass sync failed; payload will remain queued.',
        error: error,
        stackTrace: stackTrace,
      );
      return false;
    }
  }
}
