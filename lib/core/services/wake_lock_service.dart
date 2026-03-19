import 'dart:io';
import 'package:logger/logger.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

/// Service for managing wake lock during meditation sessions
class WakeLockService {
  static final WakeLockService _instance = WakeLockService._internal();
  factory WakeLockService() => _instance;
  WakeLockService._internal();

  final Logger _logger = Logger();
  
  bool _isWakeLockEnabled = false;
  
  /// Get current wake lock state
  bool get isWakeLockEnabled => _isWakeLockEnabled;

  /// Request necessary permissions for wake lock
  Future<bool> requestPermissions() async {
    try {
      // WAKE_LOCK permission is already in AndroidManifest.xml
      // No additional runtime permissions needed for wake lock
      if (Platform.isAndroid) {
        _logger.d('Wake lock permission available in manifest');
        return true;
      } else if (Platform.isIOS) {
        // iOS doesn't require special permissions for preventing idle timer
        _logger.d('iOS idle timer control available');
        return true;
      }
      
      return false;
    } catch (e) {
      _logger.e('Failed to request wake lock permissions: $e');
      return false;
    }
  }

  /// Enable wake lock for meditation session
  Future<bool> enableWakeLock() async {
    try {
      if (_isWakeLockEnabled) {
        _logger.d('Wake lock already enabled');
        return true;
      }

      // Check permissions first
      if (!await requestPermissions()) {
        _logger.w('Cannot enable wake lock: permissions not granted');
        return false;
      }

      bool success = false;

      if (Platform.isAndroid) {
        // Use wakelock_plus for Android
        try {
          await WakelockPlus.enable();
          success = true;
          _logger.i('Android wake lock enabled');
        } catch (e) {
          _logger.e('Failed to enable Android wake lock: $e');
          success = false;
        }
      } else if (Platform.isIOS) {
        // For iOS, wakelock_plus also handles idle timer prevention
        try {
          await WakelockPlus.enable();
          success = true;
          _logger.i('iOS idle timer prevention enabled');
        } catch (e) {
          _logger.e('Failed to enable iOS idle timer prevention: $e');
          success = false;
        }
      }

      if (success) {
        _isWakeLockEnabled = true;
        _logger.i('Wake lock enabled for meditation');
        return true;
      }

      return false;
    } catch (e) {
      _logger.e('Failed to enable wake lock: $e');
      return false;
    }
  }

  /// Disable wake lock and restore normal behavior
  Future<bool> disableWakeLock() async {
    try {
      if (!_isWakeLockEnabled) {
        _logger.d('Wake lock not enabled, nothing to restore');
        return true;
      }

      bool success = false;

      if (Platform.isAndroid) {
        try {
          await WakelockPlus.disable();
          success = true;
          _logger.i('Android wake lock disabled');
        } catch (e) {
          _logger.e('Failed to disable Android wake lock: $e');
          success = false;
        }
      } else if (Platform.isIOS) {
        try {
          await WakelockPlus.disable();
          success = true;
          _logger.i('iOS idle timer prevention disabled');
        } catch (e) {
          _logger.e('Failed to disable iOS idle timer prevention: $e');
          success = false;
        }
      }

      if (success) {
        _isWakeLockEnabled = false;
        _logger.i('Wake lock disabled, normal sleep behavior restored');
      } else {
        _logger.w('Failed to disable wake lock');
      }

      return success;
    } catch (e) {
      _logger.e('Failed to disable wake lock: $e');
      return false;
    }
  }

  /// Check if wake lock is supported on this device
  bool get isSupported {
    return Platform.isAndroid || Platform.isIOS;
  }

  /// Get user-friendly status message
  String get statusMessage {
    if (!isSupported) {
      return 'Wake lock not supported on this platform';
    }
    return _isWakeLockEnabled ? 'Wake lock active' : 'Wake lock inactive';
  }

  /// Toggle wake lock state
  Future<bool> toggle() async {
    if (_isWakeLockEnabled) {
      return await disableWakeLock();
    } else {
      return await enableWakeLock();
    }
  }
}
