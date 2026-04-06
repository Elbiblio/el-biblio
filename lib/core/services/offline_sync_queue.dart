import 'dart:async';
import 'package:logger/logger.dart';
import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';

part 'offline_sync_queue.g.dart';

/// Represents an action that needs to be synchronized when online
@HiveType(typeId: 50)
class OfflineAction {
  @HiveField(0)
  final String id;
  
  @HiveField(1)
  final String actionType;
  
  @HiveField(2)
  final String endpoint;
  
  @HiveField(3)
  final Map<String, dynamic> data;
  
  @HiveField(4)
  final DateTime createdAt;
  
  @HiveField(5)
  final int retryCount;
  
  @HiveField(6)
  final DateTime? lastRetryAt;
  
  @HiveField(7)
  final String? userId;
  
  @HiveField(8)
  final Map<String, dynamic>? metadata;

  OfflineAction({
    required this.actionType,
    required this.endpoint,
    required this.data,
    this.userId,
    this.metadata,
    this.retryCount = 0,
    this.lastRetryAt,
  }) : id = const Uuid().v4(),
       createdAt = DateTime.now();

  OfflineAction copyWith({
    String? actionType,
    String? endpoint,
    Map<String, dynamic>? data,
    String? userId,
    Map<String, dynamic>? metadata,
    int? retryCount,
    DateTime? lastRetryAt,
  }) {
    return OfflineAction(
      actionType: actionType ?? this.actionType,
      endpoint: endpoint ?? this.endpoint,
      data: data ?? this.data,
      userId: userId ?? this.userId,
      metadata: metadata ?? this.metadata,
      retryCount: retryCount ?? this.retryCount,
      lastRetryAt: lastRetryAt ?? this.lastRetryAt,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'actionType': actionType,
    'endpoint': endpoint,
    'data': data,
    'createdAt': createdAt.toIso8601String(),
    'retryCount': retryCount,
    'lastRetryAt': lastRetryAt?.toIso8601String(),
    'userId': userId,
    'metadata': metadata,
  };

  factory OfflineAction.fromJson(Map<String, dynamic> json) {
    return OfflineAction(
      actionType: json['actionType'],
      endpoint: json['endpoint'],
      data: json['data'],
      userId: json['userId'],
      metadata: json['metadata'],
      retryCount: json['retryCount'] ?? 0,
      lastRetryAt: json['lastRetryAt'] != null 
          ? DateTime.parse(json['lastRetryAt']) 
          : null,
    );
  }

  @override
  String toString() => 
      'OfflineAction(id: $id, type: $actionType, endpoint: $endpoint, retries: $retryCount)';
}

/// Sync result for offline actions
enum SyncResult {
  success,
  failed,
  retry,
  conflict,
}

/// Detailed sync result with additional information
class SyncResultDetail {
  final SyncResult result;
  final String? errorMessage;
  final dynamic responseData;
  final OfflineAction action;
  final DateTime timestamp;

  SyncResultDetail({
    required this.result,
    required this.action,
    this.errorMessage,
    this.responseData,
  }) : timestamp = DateTime.now();

  @override
  String toString() => 
      'SyncResult(result: $result, action: ${action.id}, error: $errorMessage)';
}

/// Offline sync queue manager for handling actions when offline
class OfflineSyncQueue {
  OfflineSyncQueue(this._logger) {
    _initializeQueue();
  }

  final Logger _logger;
  late Box<OfflineAction> _actionBox;
  bool _isInitialized = false;
  
  static const int _maxRetries = 3;
  static const Duration _maxQueueAge = Duration(days: 7);

  /// Initialize the sync queue
  Future<void> _initializeQueue() async {
    try {
      if (!_isInitialized) {
        _actionBox = await Hive.openBox<OfflineAction>('offline_sync_queue');
        _isInitialized = true;
        
        // Clean up old actions on initialization
        await _cleanupOldActions();
        
        _logger.i('Offline sync queue initialized with ${_actionBox.length} pending actions');
      }
    } catch (e) {
      _logger.e('Failed to initialize offline sync queue: $e');
      rethrow;
    }
  }

  /// Add an action to the sync queue
  Future<void> enqueueAction({
    required String actionType,
    required String endpoint,
    required Map<String, dynamic> data,
    String? userId,
    Map<String, dynamic>? metadata,
  }) async {
    await _ensureInitialized();
    
    try {
      final action = OfflineAction(
        actionType: actionType,
        endpoint: endpoint,
        data: data,
        userId: userId,
        metadata: metadata,
      );

      await _actionBox.put(action.id, action);
      _logger.i('Enqueued offline action: ${action.id} ($actionType)');
      
      // Trigger sync processing if online
      _processPendingActions();
    } catch (e) {
      _logger.e('Failed to enqueue offline action: $e');
      rethrow;
    }
  }

  /// Process all pending actions in the queue
  Future<List<SyncResultDetail>> processQueue({
    required Future<Map<String, dynamic>> Function(String endpoint, Map<String, dynamic> data) syncFunction,
  }) async {
    await _ensureInitialized();
    
    final results = <SyncResultDetail>[];
    final actions = _actionBox.values.toList()
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));

    _logger.i('Processing ${actions.length} pending offline actions');

    for (final action in actions) {
      try {
        final result = await _processAction(action, syncFunction);
        results.add(result);

        // Remove successful actions
        if (result.result == SyncResult.success) {
          await _actionBox.delete(action.id);
          _logger.d('Successfully synced and removed action: ${action.id}');
        } else if (result.result == SyncResult.failed || 
                   result.result == SyncResult.conflict) {
          // Remove permanently failed actions
          await _actionBox.delete(action.id);
          _logger.w('Removed failed action: ${action.id} - ${result.errorMessage}');
        } else if (result.result == SyncResult.retry) {
          // Update retry count for retryable actions
          final updatedAction = action.copyWith(
            retryCount: action.retryCount + 1,
            lastRetryAt: DateTime.now(),
          );
          await _actionBox.put(action.id, updatedAction);
        }
      } catch (e) {
        _logger.e('Error processing action ${action.id}: $e');
        results.add(SyncResultDetail(
          result: SyncResult.failed,
          action: action,
          errorMessage: e.toString(),
        ));
      }
    }

    _logger.i('Sync queue processing completed: ${results.where((r) => r.result == SyncResult.success).length} successful, '
               '${results.where((r) => r.result == SyncResult.failed).length} failed, '
               '${results.where((r) => r.result == SyncResult.retry).length} pending');

    return results;
  }

  /// Process a single action
  Future<SyncResultDetail> _processAction(
    OfflineAction action,
    Future<Map<String, dynamic>> Function(String endpoint, Map<String, dynamic> data) syncFunction,
  ) async {
    try {
      // Check retry limit
      if (action.retryCount >= _maxRetries) {
        return SyncResultDetail(
          result: SyncResult.failed,
          action: action,
          errorMessage: 'Maximum retry limit exceeded',
        );
      }

      // Check if action is too old
      final age = DateTime.now().difference(action.createdAt);
      if (age > _maxQueueAge) {
        return SyncResultDetail(
          result: SyncResult.failed,
          action: action,
          errorMessage: 'Action expired (${age.inDays} days old)',
        );
      }

      _logger.d('Processing offline action: ${action.id} (attempt ${action.retryCount + 1})');

      // Execute the sync function
      final response = await syncFunction(action.endpoint, action.data);

      return SyncResultDetail(
        result: SyncResult.success,
        action: action,
        responseData: response,
      );

    } catch (e) {
      final errorMessage = e.toString().toLowerCase();
      
      // Determine if the error is retryable
      final isRetryable = _isRetryableError(errorMessage);
      
      if (isRetryable && action.retryCount < _maxRetries) {
        return SyncResultDetail(
          result: SyncResult.retry,
          action: action,
          errorMessage: 'Retryable error: $e',
        );
      } else {
        return SyncResultDetail(
          result: errorMessage.contains('conflict') ? SyncResult.conflict : SyncResult.failed,
          action: action,
          errorMessage: e.toString(),
        );
      }
    }
  }

  /// Determine if an error is retryable
  bool _isRetryableError(String errorMessage) {
    final retryablePatterns = [
      'connection',
      'timeout',
      'network',
      'host',
      'unreachable',
      'dns',
      'socket',
      '502',
      '503',
      '504',
    ];

    return retryablePatterns.any((pattern) => errorMessage.contains(pattern));
  }

  /// Get pending actions count
  Future<int> getPendingCount() async {
    await _ensureInitialized();
    return _actionBox.length;
  }

  /// Get pending actions by type
  Future<List<OfflineAction>> getPendingActions({String? actionType}) async {
    await _ensureInitialized();
    
    final actions = _actionBox.values.toList();
    if (actionType != null) {
      return actions.where((action) => action.actionType == actionType).toList();
    }
    return actions;
  }

  /// Clear all pending actions
  Future<void> clearQueue() async {
    await _ensureInitialized();
    await _actionBox.clear();
    _logger.i('Offline sync queue cleared');
  }

  /// Clear actions for a specific user
  Future<void> clearUserActions(String userId) async {
    await _ensureInitialized();
    
    final userActions = _actionBox.values
        .where((action) => action.userId == userId)
        .toList();
    
    for (final action in userActions) {
      await _actionBox.delete(action.id);
    }
    
    _logger.i('Cleared ${userActions.length} actions for user: $userId');
  }

  /// Clean up old actions
  Future<void> _cleanupOldActions() async {
    try {
      final now = DateTime.now();
      final oldActions = <OfflineAction>[];
      
      for (final action in _actionBox.values) {
        final age = now.difference(action.createdAt);
        if (age > _maxQueueAge || action.retryCount >= _maxRetries) {
          oldActions.add(action);
        }
      }
      
      for (final action in oldActions) {
        await _actionBox.delete(action.id);
      }
      
      if (oldActions.isNotEmpty) {
        _logger.i('Cleaned up ${oldActions.length} old/expired actions');
      }
    } catch (e) {
      _logger.e('Error during cleanup: $e');
    }
  }

  /// Get queue statistics
  Future<Map<String, dynamic>> getQueueStats() async {
    await _ensureInitialized();
    
    final actions = _actionBox.values.toList();
    final now = DateTime.now();
    
    final stats = <String, dynamic>{
      'totalActions': actions.length,
      'actionsByType': <String, int>{},
      'actionsByRetryCount': <int, int>{},
      'averageAge': 0.0,
      'oldestAction': actions.isNotEmpty ? actions.first.createdAt.toIso8601String() : null,
    };

    if (actions.isNotEmpty) {
      var totalAge = 0;
      
      for (final action in actions) {
        // Count by type
        final actionsByType = stats['actionsByType'] as Map<String, int>;
        final currentTypeCount = actionsByType[action.actionType] ?? 0;
        actionsByType[action.actionType] = currentTypeCount + 1;
        
        // Count by retry count
        final actionsByRetryCount = stats['actionsByRetryCount'] as Map<int, int>;
        final currentRetryCount = actionsByRetryCount[action.retryCount] ?? 0;
        actionsByRetryCount[action.retryCount] = currentRetryCount + 1;
        
        // Calculate age
        totalAge += now.difference(action.createdAt).inSeconds;
      }
      
      stats['averageAge'] = totalAge / actions.length;
    }
    
    return stats;
  }

  /// Ensure the queue is initialized
  Future<void> _ensureInitialized() async {
    if (!_isInitialized) {
      await _initializeQueue();
    }
  }

  /// Process pending actions when connectivity is restored
  void _processPendingActions() {
    // This will be called when connectivity is restored
    // The actual processing will be handled by the SyncService
  }

  void dispose() {
    if (_isInitialized) {
      _actionBox.close();
    }
  }

  @override
  String toString() => 
      'OfflineSyncQueue(pending: ${_actionBox.length}, initialized: $_isInitialized)';
}
