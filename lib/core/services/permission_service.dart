import 'dart:io';
import 'package:logger/logger.dart';
import 'package:permission_handler/permission_handler.dart';

/// Service for managing runtime permissions for meditation features
class PermissionService {
  static final PermissionService _instance = PermissionService._internal();
  factory PermissionService() => _instance;
  PermissionService._internal();

  final Logger _logger = Logger();

  /// Check and request all necessary permissions for meditation
  Future<Map<String, bool>> requestMeditationPermissions() async {
    final Map<String, bool> results = {};

    try {
      // Audio recording permission (for speech-to-text in journal)
      results['record_audio'] = await _requestPermission(Permission.microphone);

      // Contacts permission (for social features)
      results['contacts'] = await _requestPermission(Permission.contacts);

      // Platform-specific permissions
      if (Platform.isAndroid) {
        // Android-specific permissions
        // Note: MODIFY_AUDIO_SETTINGS and WAKE_LOCK are manifest permissions
        // They don't require runtime requests
        results['modify_audio_settings'] = true;
        results['wake_lock'] = true;
      }

      _logger.i('Permission request results: $results');
      return results;
    } catch (e) {
      _logger.e('Error requesting meditation permissions: $e');
      return results;
    }
  }

  /// Check current status of all meditation permissions
  Future<Map<String, PermissionStatus>> checkMeditationPermissions() async {
    final Map<String, PermissionStatus> status = {};

    try {
      // Audio recording permission
      status['record_audio'] = await Permission.microphone.status;

      // Contacts permission
      status['contacts'] = await Permission.contacts.status;

      // Platform-specific
      if (Platform.isAndroid) {
        // Android doesn't require runtime permission for basic notifications
        // status['notifications'] = await Permission.notification.status;
      }

      _logger.d('Permission status check: $status');
      return status;
    } catch (e) {
      _logger.e('Error checking meditation permissions: $e');
      return status;
    }
  }

  /// Request a single permission
  Future<bool> _requestPermission(Permission permission) async {
    try {
      final status = await permission.request();
      return status.isGranted;
    } catch (e) {
      _logger.e('Error requesting permission ${permission.toString()}: $e');
      return false;
    }
  }

  /// Check if all critical permissions are granted
  Future<bool> areCriticalPermissionsGranted() async {
    final status = await checkMeditationPermissions();
    
    // Critical permissions for core functionality
    final criticalPermissions = ['record_audio', 'contacts'];
    
    for (final permission in criticalPermissions) {
      final permissionStatus = status[permission];
      if (permissionStatus == null || !permissionStatus.isGranted) {
        return false;
      }
    }
    
    return true;
  }

  /// Get user-friendly permission status messages
  Map<String, String> getPermissionStatusMessages(Map<String, PermissionStatus> status) {
    final messages = <String, String>{};

    for (final entry in status.entries) {
      final permission = entry.key;
      final permissionStatus = entry.value;

      switch (permissionStatus) {
        case PermissionStatus.granted:
          messages[permission] = 'Granted';
          break;
        case PermissionStatus.denied:
          messages[permission] = 'Denied - Please enable in settings';
          break;
        case PermissionStatus.restricted:
          messages[permission] = 'Restricted - Contact device administrator';
          break;
        case PermissionStatus.limited:
          messages[permission] = 'Limited - Partial access granted';
          break;
        case PermissionStatus.permanentlyDenied:
          messages[permission] = 'Permanently denied - Please enable in settings';
          break;
        case PermissionStatus.provisional:
          messages[permission] = 'Provisional - Limited access granted';
          break;
      }
    }

    return messages;
  }

  /// Open app settings for manual permission management
  Future<bool> openAppSettings() async {
    try {
      return await openAppSettings();
    } catch (e) {
      _logger.e('Error opening app settings: $e');
      return false;
    }
  }

  /// Check if specific permission is granted
  Future<bool> isPermissionGranted(Permission permission) async {
    try {
      final status = await permission.status;
      return status.isGranted;
    } catch (e) {
      _logger.e('Error checking permission status: $e');
      return false;
    }
  }
}
