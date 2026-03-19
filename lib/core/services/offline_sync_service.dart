import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/connectivity_service.dart';
import '../services/offline_sync_queue.dart';
import '../network/dio_client.dart';

/// Sync status for the application
enum SyncStatus {
  idle,
  syncing,
  offline,
  error,
}

/// Main offline sync service that coordinates connectivity and sync queue
class OfflineSyncService {
  OfflineSyncService(
    this._logger,
    this._connectivityService,
    this._syncQueue,
    this._dioClient,
  ) {
    _initializeSyncService();
  }

  final Logger _logger;
  final ConnectivityService _connectivityService;
  final OfflineSyncQueue _syncQueue;
  final DioClient _dioClient;

  // Sync state
  ValueListenable<SyncStatus> get syncStatus => _syncStatus;
  final _syncStatus = ValueNotifier<SyncStatus>(SyncStatus.idle);
  
  // Stream for sync status changes
  Stream<SyncStatus> get syncStatusStream => _syncStatusStreamController.stream;
  final _syncStatusStreamController = StreamController<SyncStatus>.broadcast();
  
  ValueListenable<bool> get isOnline => _connectivityService.isConnected;
  ValueListenable<int> get pendingActionsCount => _pendingActionsCount;
  final _pendingActionsCount = ValueNotifier<int>(0);

  // Stream for sync events
  Stream<List<SyncResultDetail>> get syncEventsStream => _syncEventsStreamController.stream;
  final _syncEventsStreamController = StreamController<List<SyncResultDetail>>.broadcast();

  Timer? _syncTimer;
  Timer? _statusUpdateTimer;
  bool _isInitialized = false;
  bool _isSyncing = false;

  /// Initialize the sync service
  Future<void> _initializeSyncService() async {
    try {
      if (_isInitialized) return;

      // Listen to connectivity changes
      _connectivityService.connectivityStream.listen(_handleConnectivityChange);

      // Start periodic status updates
      _startStatusUpdates();

      // Initial status update
      await _updatePendingCount();

      _isInitialized = true;
      _logger.i('Offline sync service initialized');

      // Trigger initial sync if online
      if (_connectivityService.hasInternetConnection) {
        _triggerSync();
      }
    } catch (e) {
      _logger.e('Failed to initialize offline sync service: $e');
      _syncStatus.value = SyncStatus.error;
    }
  }

  /// Handle connectivity changes
  void _handleConnectivityChange(bool isConnected) {
    _logger.i('Connectivity changed: ${isConnected ? "ONLINE" : "OFFLINE"}');
    
    if (isConnected) {
      _syncStatus.value = SyncStatus.idle;
      _syncStatusStreamController.add(SyncStatus.idle);
      // Trigger sync when coming back online
      _triggerSync();
    } else {
      _syncStatus.value = SyncStatus.offline;
      _syncStatusStreamController.add(SyncStatus.offline);
    }
  }

  /// Trigger sync process
  Future<void> _triggerSync() async {
    if (_isSyncing || !_connectivityService.hasInternetConnection) {
      return;
    }

    _isSyncing = true;
    _syncStatus.value = SyncStatus.syncing;
    _syncStatusStreamController.add(SyncStatus.syncing);

    try {
      _logger.d('Starting sync process...');
      
      final results = await _syncQueue.processQueue(syncFunction: _executeSyncAction);
      
      // Emit sync results
      _syncEventsStreamController.add(results);
      
      // Update status based on results
      final hasFailures = results.any((result) => 
          result.result == SyncResult.failed || result.result == SyncResult.conflict);
      
      if (hasFailures) {
        _syncStatus.value = SyncStatus.error;
        _syncStatusStreamController.add(SyncStatus.error);
      } else {
        _syncStatus.value = SyncStatus.idle;
        _syncStatusStreamController.add(SyncStatus.idle);
      }
      
      _logger.i('Sync completed: ${results.length} actions processed');
      
    } catch (e) {
      _logger.e('Sync process failed: $e');
      _syncStatus.value = SyncStatus.error;
      _syncStatusStreamController.add(SyncStatus.error);
    } finally {
      _isSyncing = false;
      await _updatePendingCount();
    }
  }

  /// Execute a single sync action
  Future<Map<String, dynamic>> _executeSyncAction(String endpoint, Map<String, dynamic> data) async {
    try {
      // Determine HTTP method based on action type or endpoint
      final method = _determineHttpMethod(data['actionType'] ?? '', endpoint);
      
      switch (method) {
        case 'POST':
          final response = await _dioClient.post(endpoint, data: data);
          return response.data ?? {};
        case 'PUT':
          final response = await _dioClient.put(endpoint, data: data);
          return response.data ?? {};
        case 'DELETE':
          final response = await _dioClient.delete(endpoint, data: data);
          return response.data ?? {};
        case 'GET':
        default:
          final response = await _dioClient.get(endpoint, queryParameters: data);
          return response.data ?? {};
      }
    } catch (e) {
      _logger.e('Sync action failed for $endpoint: $e');
      rethrow;
    }
  }

  /// Determine HTTP method based on action type and endpoint
  String _determineHttpMethod(String actionType, String endpoint) {
    // Common patterns for determining HTTP method
    if (actionType.toLowerCase().contains('create') || 
        actionType.toLowerCase().contains('add') ||
        endpoint.toLowerCase().contains('/create')) {
      return 'POST';
    } else if (actionType.toLowerCase().contains('update') || 
               actionType.toLowerCase().contains('edit') ||
               endpoint.toLowerCase().contains('/update')) {
      return 'PUT';
    } else if (actionType.toLowerCase().contains('delete') || 
               actionType.toLowerCase().contains('remove') ||
               endpoint.toLowerCase().contains('/delete')) {
      return 'DELETE';
    }
    
    // Default to POST for most actions
    return 'POST';
  }

  /// Enqueue an action for offline sync
  Future<void> enqueueAction({
    required String actionType,
    required String endpoint,
    required Map<String, dynamic> data,
    String? userId,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      await _syncQueue.enqueueAction(
        actionType: actionType,
        endpoint: endpoint,
        data: data,
        userId: userId,
        metadata: metadata,
      );

      await _updatePendingCount();

      // If online, trigger sync immediately
      if (_connectivityService.hasInternetConnection && !_isSyncing) {
        _triggerSync();
      }

      _logger.d('Action enqueued for sync: $actionType');
    } catch (e) {
      _logger.e('Failed to enqueue action: $e');
      rethrow;
    }
  }

  /// Force sync all pending actions
  Future<List<SyncResultDetail>> forceSync() async {
    if (!_connectivityService.hasInternetConnection) {
      throw Exception('Cannot sync while offline');
    }

    await _triggerSync();
    
    // Return the most recent sync results
    return [];
  }

  /// Get sync statistics
  Future<Map<String, dynamic>> getSyncStats() async {
    try {
      final queueStats = await _syncQueue.getQueueStats();
      final pendingActions = await _syncQueue.getPendingActions();
      
      return {
        'isOnline': _connectivityService.hasInternetConnection,
        'connectionType': _connectivityService.getConnectionTypeDescription(),
        'syncStatus': _syncStatus.value.toString(),
        'isSyncing': _isSyncing,
        'pendingActionsCount': pendingActions.length,
        'queueStats': queueStats,
        'lastSyncTime': DateTime.now().toIso8601String(), // This could be stored persistently
      };
    } catch (e) {
      _logger.e('Failed to get sync stats: $e');
      return {};
    }
  }

  /// Clear all pending actions
  Future<void> clearPendingActions() async {
    try {
      await _syncQueue.clearQueue();
      await _updatePendingCount();
      _logger.i('All pending actions cleared');
    } catch (e) {
      _logger.e('Failed to clear pending actions: $e');
      rethrow;
    }
  }

  /// Clear actions for specific user
  Future<void> clearUserActions(String userId) async {
    try {
      await _syncQueue.clearUserActions(userId);
      await _updatePendingCount();
      _logger.i('Actions cleared for user: $userId');
    } catch (e) {
      _logger.e('Failed to clear user actions: $e');
      rethrow;
    }
  }

  /// Update pending actions count
  Future<void> _updatePendingCount() async {
    try {
      final count = await _syncQueue.getPendingCount();
      _pendingActionsCount.value = count;
    } catch (e) {
      _logger.e('Failed to update pending count: $e');
    }
  }

  /// Start periodic status updates
  void _startStatusUpdates() {
    _statusUpdateTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      _updatePendingCount();
      
      // Auto-sync if online and not currently syncing
      if (_connectivityService.hasInternetConnection && !_isSyncing) {
        _triggerSync();
      }
    });
  }

  /// Check if service can perform network operations
  bool get canSync => _connectivityService.hasInternetConnection && !_isSyncing;

  /// Get human-readable sync status description
  String getSyncStatusDescription() {
    switch (_syncStatus.value) {
      case SyncStatus.idle:
        return _connectivityService.hasInternetConnection ? 'Up to date' : 'Offline';
      case SyncStatus.syncing:
        return 'Syncing...';
      case SyncStatus.offline:
        return 'Offline';
      case SyncStatus.error:
        return 'Sync error';
    }
  }

  /// Wait for sync to complete (with timeout)
  Future<bool> waitForSync({Duration timeout = const Duration(minutes: 5)}) async {
    if (!_isSyncing) return true;

    final completer = Completer<bool>();
    Timer? timeoutTimer;
    late StreamSubscription<SyncStatus> subscription;

    subscription = syncStatusStream.listen((status) {
      if (status != SyncStatus.syncing) {
        timeoutTimer?.cancel();
        subscription.cancel();
        if (!completer.isCompleted) {
          completer.complete(true);
        }
      }
    });

    timeoutTimer = Timer(timeout, () {
      subscription.cancel();
      if (!completer.isCompleted) {
        completer.complete(false);
      }
    });

    return completer.future;
  }

  void dispose() {
    _syncTimer?.cancel();
    _statusUpdateTimer?.cancel();
    _syncEventsStreamController.close();
    _syncStatusStreamController.close();
    _syncStatus.dispose();
    _pendingActionsCount.dispose();
    _syncQueue.dispose();
    _connectivityService.dispose();
  }

  @override
  String toString() => 
      'OfflineSyncService(status: $_syncStatus, online: ${_connectivityService.hasInternetConnection}, pending: $_pendingActionsCount)';
}

/// Provider for the offline sync service
final offlineSyncServiceProvider = Provider<OfflineSyncService>((ref) {
  throw UnimplementedError('OfflineSyncService must be provided in app_providers.dart');
});

/// Provider for sync status
final syncStatusProvider = Provider<SyncStatus>((ref) {
  final syncService = ref.watch(offlineSyncServiceProvider);
  return syncService.syncStatus.value;
});

/// Provider for pending actions count
final pendingActionsCountProvider = Provider<int>((ref) {
  final syncService = ref.watch(offlineSyncServiceProvider);
  return syncService.pendingActionsCount.value;
});

/// Provider for online status
final isOnlineProvider = Provider<bool>((ref) {
  final syncService = ref.watch(offlineSyncServiceProvider);
  return syncService.isOnline.value;
});
