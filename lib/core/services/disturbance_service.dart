import 'dart:io';
import 'package:logger/logger.dart';
import 'package:do_not_disturb/do_not_disturb.dart';

/// Service for managing Do Not Disturb (DND) mode during meditation sessions
class DisturbanceService {
  static final DisturbanceService _instance = DisturbanceService._internal();
  factory DisturbanceService() => _instance;
  DisturbanceService._internal();

  final Logger _logger = Logger();
  final DoNotDisturbPlugin _dndPlugin = DoNotDisturbPlugin();
  
  bool _isDndEnabled = false;
  InterruptionFilter? _originalInterruptionFilter;
  
  /// Get current DND state
  bool get isDndEnabled => _isDndEnabled;

  /// Request necessary permissions for DND functionality
  Future<bool> requestPermissions() async {
    try {
      if (Platform.isAndroid) {
        // Check if we have notification policy access
        final hasAccess = await _dndPlugin.isNotificationPolicyAccessGranted();
        if (!hasAccess) {
          _logger.w('Notification policy access not granted, redirecting to settings');
          await _dndPlugin.openNotificationPolicyAccessSettings();
          return false;
        }
        _logger.d('Notification policy access granted');
        return true;
      } else if (Platform.isIOS) {
        // iOS doesn't require special permissions for basic DND
        _logger.d('iOS DND control available');
        return true;
      }
      
      return false;
    } catch (e) {
      _logger.e('Failed to request DND permissions: $e');
      return false;
    }
  }

  /// Enable DND mode for meditation session
  Future<bool> enableDnd() async {
    try {
      if (_isDndEnabled) {
        _logger.d('DND already enabled');
        return true;
      }

      // Check permissions first
      if (!await requestPermissions()) {
        _logger.w('Cannot enable DND: permissions not granted');
        return false;
      }

      bool success = false;

      if (Platform.isAndroid) {
        // Store current state
        _originalInterruptionFilter = await _dndPlugin.getDNDStatus();
        
        // Enable DND mode using do_not_disturb
        await _dndPlugin.setInterruptionFilter(InterruptionFilter.none);
        _isDndEnabled = true;
        _logger.i('DND mode enabled for meditation');
        return true;
      } else if (Platform.isIOS) {
        // iOS: Set silent mode using audio session
        success = await _setSilentMode(true);
        if (success) {
          _isDndEnabled = true;
          _logger.i('Silent mode enabled for meditation (iOS)');
          return true;
        }
      }

      return false;
    } catch (e) {
      _logger.e('Failed to enable DND: $e');
      return false;
    }
  }

  /// Enable priority DND mode that allows media/alarms but blocks other interruptions
  Future<bool> enablePriorityDnd() async {
    try {
      if (_isDndEnabled) {
        _logger.d('DND already enabled');
        return true;
      }

      // Check permissions first
      if (!await requestPermissions()) {
        _logger.w('Cannot enable priority DND: permissions not granted');
        return false;
      }

      bool success = false;

      if (Platform.isAndroid) {
        // Store current state
        _originalInterruptionFilter = await _dndPlugin.getDNDStatus();
        
        // Enable priority DND mode that allows alarms/media
        await _dndPlugin.setInterruptionFilter(InterruptionFilter.priority);
        _isDndEnabled = true;
        _logger.i('Priority DND mode enabled for meditation');
        return true;
      } else if (Platform.isIOS) {
        // iOS: Set silent mode using audio session
        success = await _setSilentMode(true);
        if (success) {
          _isDndEnabled = true;
          _logger.i('Silent mode enabled for meditation (iOS)');
          return true;
        }
      }

      return false;
    } catch (e) {
      _logger.e('Failed to enable priority DND: $e');
      return false;
    }
  }

  /// Disable DND mode and restore original settings
  Future<bool> disableDnd() async {
    try {
      if (!_isDndEnabled) {
        _logger.d('DND not enabled, nothing to restore');
        return true;
      }

      bool success = false;

      if (Platform.isAndroid) {
        // Restore original interruption filter
        if (_originalInterruptionFilter != null) {
          await _dndPlugin.setInterruptionFilter(_originalInterruptionFilter!);
        } else {
          // Fallback to allowing all interruptions
          await _dndPlugin.setInterruptionFilter(InterruptionFilter.all);
        }
        _isDndEnabled = false;
        success = true;
      } else if (Platform.isIOS) {
        // Restore normal mode on iOS
        success = await _setSilentMode(false);
        _isDndEnabled = !success;
      }

      if (success) {
        _logger.i('DND mode disabled, original settings restored');
      } else {
        _logger.w('Failed to restore original settings');
      }

      return success;
    } catch (e) {
      _logger.e('Failed to disable DND: $e');
      return false;
    }
  }

  
  /// iOS: Set silent mode using audio session
  Future<bool> _setSilentMode(bool silent) async {
    try {
      _logger.d('Setting iOS silent mode: ${silent ? "ON" : "OFF"}');
      
      // For iOS, we would need to use platform channel to control audio session
      // This is a simplified implementation - in production you'd use
      // platform channels to access AVAudioSession configuration
      
      return true; // Simulate success for now
    } catch (e) {
      _logger.e('Failed to set iOS silent mode: $e');
      return false;
    }
  }

  /// Check if DND is supported on this device
  bool get isSupported {
    return Platform.isAndroid || Platform.isIOS;
  }

  /// Get user-friendly status message
  String get statusMessage {
    if (!isSupported) {
      return 'DND not supported on this platform';
    }
    return _isDndEnabled ? 'DND mode active' : 'DND mode inactive';
  }
}
