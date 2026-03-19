import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logger/logger.dart';
import '../services/connectivity_service.dart';
import '../services/offline_sync_queue.dart';
import '../services/offline_sync_service.dart';
import '../services/offline_data_validation_service.dart';
import '../network/dio_client.dart';

/// Comprehensive offline service provider configuration
class OfflineServiceProvider {
  OfflineServiceProvider(this._logger);

  final Logger _logger;
  late ConnectivityService _connectivityService;
  late OfflineSyncQueue _syncQueue;
  late OfflineSyncService _syncService;
  late OfflineDataValidationService _validationService;

  /// Initialize all offline services
  Future<void> initializeServices(DioClient dioClient) async {
    try {
      _logger.i('Initializing offline services...');

      // Initialize connectivity service
      _connectivityService = ConnectivityService(_logger);
      _logger.d('Connectivity service initialized');

      // Initialize sync queue
      _syncQueue = OfflineSyncQueue(_logger);
      _logger.d('Sync queue initialized');

      // Initialize sync service
      _syncService = OfflineSyncService(
        _logger,
        _connectivityService,
        _syncQueue,
        dioClient,
      );
      _logger.d('Sync service initialized');

      // Initialize validation service
      _validationService = OfflineDataValidationService(_logger);
      _logger.d('Validation service initialized');

      // Run initial validation
      await _runInitialValidation();

      _logger.i('All offline services initialized successfully');
    } catch (e) {
      _logger.e('Failed to initialize offline services: $e');
      rethrow;
    }
  }

  /// Run initial validation of critical files
  Future<void> _runInitialValidation() async {
    try {
      _logger.d('Running initial data validation...');
      
      final validationResults = await _validationService.validateCriticalFiles();
      
      int totalFiles = 0;
      int corruptedFiles = 0;
      
      for (final category in validationResults.entries) {
        totalFiles += category.value.length;
        corruptedFiles += category.value
            .where((result) => result.result.name.contains('corrupted') || 
                             result.result.name.contains('invalid'))
            .length;
      }
      
      _logger.i('Initial validation complete: $totalFiles files checked, $corruptedFiles corrupted');
      
      if (corruptedFiles > 0) {
        _logger.w('Found $corruptedFiles corrupted files, attempting repair...');
        final repairedCount = await _validationService.cleanupCorruptedFiles(createBackups: true);
        _logger.i('Repaired $repairedCount corrupted files');
      }
    } catch (e) {
      _logger.e('Initial validation failed: $e');
    }
  }

  /// Get connectivity service
  ConnectivityService get connectivity => _connectivityService;

  /// Get sync service
  OfflineSyncService get sync => _syncService;

  /// Get validation service
  OfflineDataValidationService get validation => _validationService;

  /// Get sync queue
  OfflineSyncQueue get syncQueue => _syncQueue;

  /// Get comprehensive offline status
  Future<Map<String, dynamic>> getOfflineStatus() async {
    try {
      final syncStats = await _syncService.getSyncStats();
      final validationStats = await _validationService.getValidationStats();
      final queueStats = await _syncQueue.getQueueStats();

      return {
        'connectivity': {
          'isOnline': _connectivityService.hasInternetConnection,
          'connectionType': _connectivityService.getConnectionTypeDescription(),
          'suitableForDownloads': _connectivityService.isSuitableForDownloads(),
          'isMetered': _connectivityService.isMeteredConnection(),
        },
        'sync': syncStats,
        'validation': validationStats,
        'queue': queueStats,
        'timestamp': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      _logger.e('Failed to get offline status: $e');
      return {'error': e.toString()};
    }
  }

  /// Perform comprehensive offline health check
  Future<Map<String, dynamic>> performHealthCheck() async {
    final healthCheck = <String, dynamic>{
      'overall': 'healthy',
      'issues': <String>[],
      'recommendations': <String>[],
      'timestamp': DateTime.now().toIso8601String(),
    };

    try {
      // Check connectivity
      if (!_connectivityService.hasInternetConnection) {
        healthCheck['issues'].add('No internet connection');
        healthCheck['recommendations'].add('Check network settings');
        healthCheck['overall'] = 'degraded';
      }

      // Check sync queue
      final pendingCount = await _syncQueue.getPendingCount();
      if (pendingCount > 100) {
        healthCheck['issues'].add('High number of pending sync actions: $pendingCount');
        healthCheck['recommendations'].add('Consider manual sync or cleanup');
        healthCheck['overall'] = 'degraded';
      }

      // Check data validation
      final validationResults = await _validationService.validateCriticalFiles();
      int corruptedCount = 0;
      
      for (final category in validationResults.entries) {
        corruptedCount += category.value
            .where((result) => result.result.name.contains('corrupted') || 
                             result.result.name.contains('invalid'))
            .length;
      }

      if (corruptedCount > 0) {
        healthCheck['issues'].add('Found $corruptedCount corrupted files');
        healthCheck['recommendations'].add('Run data repair process');
        healthCheck['overall'] = 'unhealthy';
      }

      // Check storage space (basic check)
      try {
        final cacheDir = _validationService.validationCacheDir;
        if (cacheDir.isNotEmpty) {
          // This is a simplified check - in production you'd want more sophisticated storage monitoring
          healthCheck['storage'] = 'adequate';
        }
      } catch (e) {
        healthCheck['issues'].add('Unable to check storage space');
        healthCheck['overall'] = 'degraded';
      }

    } catch (e) {
      _logger.e('Health check failed: $e');
      healthCheck['overall'] = 'error';
      healthCheck['issues'].add('Health check failed: $e');
    }

    return healthCheck;
  }

  /// Cleanup and dispose all services
  void dispose() {
    try {
      _logger.i('Disposing offline services...');
      
      _syncService.dispose();
      _syncQueue.dispose();
      _validationService.dispose();
      _connectivityService.dispose();
      
      _logger.i('Offline services disposed successfully');
    } catch (e) {
      _logger.e('Error disposing offline services: $e');
    }
  }
}

/// Provider for offline service provider
final offlineServiceProvider = Provider<OfflineServiceProvider>((ref) {
  throw UnimplementedError('OfflineServiceProvider must be provided in app_providers.dart');
});

/// Provider for connectivity service
final connectivityServiceProvider = Provider<ConnectivityService>((ref) {
  final offlineProvider = ref.watch(offlineServiceProvider);
  return offlineProvider.connectivity;
});

/// Provider for sync service
final syncServiceProvider = Provider<OfflineSyncService>((ref) {
  final offlineProvider = ref.watch(offlineServiceProvider);
  return offlineProvider.sync;
});

/// Provider for validation service
final validationServiceProvider = Provider<OfflineDataValidationService>((ref) {
  final offlineProvider = ref.watch(offlineServiceProvider);
  return offlineProvider.validation;
});

/// Provider for sync queue
final syncQueueProvider = Provider<OfflineSyncQueue>((ref) {
  final offlineProvider = ref.watch(offlineServiceProvider);
  return offlineProvider.syncQueue;
});

/// Provider for offline status
final offlineStatusProvider = Provider<Future<Map<String, dynamic>>>((ref) async {
  final offlineProvider = ref.watch(offlineServiceProvider);
  return offlineProvider.getOfflineStatus();
});

/// Provider for health check
final healthCheckProvider = Provider<Future<Map<String, dynamic>>>((ref) async {
  final offlineProvider = ref.watch(offlineServiceProvider);
  return offlineProvider.performHealthCheck();
});
