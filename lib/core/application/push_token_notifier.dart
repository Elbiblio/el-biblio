import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/notifications/push_notification_service.dart';
import '../network/dio_client.dart';

/// Manages push token synchronization with backend
class PushTokenNotifier extends StateNotifier<PushTokenState> {
  PushTokenNotifier(this._notificationService, this._dioClient) : super(const PushTokenState.initial());

  final PushNotificationGateway _notificationService;
  final DioClient _dioClient;
  StreamSubscription<String>? _tokenSubscription;
  StreamSubscription? _messageSubscription;

  /// Initialize push token monitoring
  Future<void> initialize() async {
    try {
      // Initialize the push notification service first
      await _notificationService.initialize();
      
      // Listen for token changes
      _tokenSubscription = _notificationService.tokenStream.listen(
        _onTokenChanged,
        onError: (error) {
          state = PushTokenState.error('Token stream error: $error');
        },
      );

      // Listen for push messages
      _messageSubscription = _notificationService.messageStream.listen(
        _onPushMessageReceived,
        onError: (error) {
          state = state.copyWith(
            lastError: 'Push message error: $error',
          );
        },
      );

      // Get current token
      final currentToken = _notificationService.currentToken;
      if (currentToken != null) {
        state = PushTokenState.tokenAvailable(currentToken);
      }
    } catch (e) {
      state = PushTokenState.error('Push notification initialization failed: $e');
    }
  }

  /// Handle FCM token changes
  void _onTokenChanged(String token) {
    state = PushTokenState.tokenAvailable(token);
    
    // Auto-sync token to backend when user is authenticated
    // This will be handled by the auth notifier
  }

  /// Handle incoming push messages
  void _onPushMessageReceived(dynamic message) {
    state = state.copyWith(
      lastMessage: message,
      messageReceivedAt: DateTime.now(),
    );
  }

  /// Sync push token to backend
  Future<bool> syncTokenToBackend({
    required String userId,
    required String token,
    Map<String, dynamic>? deviceInfo,
  }) async {
    try {
      state = state.copyWith(isSyncing: true);

      // Get device info if not provided
      deviceInfo ??= await _notificationService.getDeviceInfo();

      // Make actual API call to register device token
      final response = await _dioClient.post(
        '/push-notifications/register-device',
        data: {
          'device_token': token,
          'platform': deviceInfo['platform'],
          'app_version': deviceInfo['app_version'],
          'device_info': deviceInfo,
        },
      );

      if (response.statusCode == 200) {
        state = state.copyWith(
          isSyncing: false,
          lastSyncTime: DateTime.now(),
          lastError: null,
        );
        return true;
      } else {
        throw Exception('API call failed with status ${response.statusCode}');
      }
    } catch (e) {
      state = state.copyWith(
        isSyncing: false,
        lastError: 'Failed to sync token: $e',
      );
      return false;
    }
  }

  /// Subscribe to user-specific topics
  Future<void> subscribeToUserTopics(String userId) async {
    try {
      await _notificationService.subscribeToTopic('user_$userId');
      await _notificationService.subscribeToTopic('daily_rhythm');
      await _notificationService.subscribeToTopic('spiritual_insights');
      
      state = state.copyWith(
        subscribedTopics: {
          'user_$userId',
          'daily_rhythm',
          'spiritual_insights',
        },
      );
    } catch (e) {
      state = state.copyWith(
        lastError: 'Failed to subscribe to topics: $e',
      );
    }
  }

  /// Unsubscribe from user-specific topics
  Future<void> unsubscribeFromUserTopics(String userId) async {
    try {
      await _notificationService.unsubscribeFromTopic('user_$userId');
      await _notificationService.unsubscribeFromTopic('daily_rhythm');
      await _notificationService.unsubscribeFromTopic('spiritual_insights');
      
      state = state.copyWith(
        subscribedTopics: {},
      );
    } catch (e) {
      state = state.copyWith(
        lastError: 'Failed to unsubscribe from topics: $e',
      );
    }
  }

  /// Clear push token state (for logout)
  void clearToken() {
    state = const PushTokenState.initial();
  }

  @override
  void dispose() {
    _tokenSubscription?.cancel();
    _messageSubscription?.cancel();
    super.dispose();
  }
}

/// State for push token management
class PushTokenState {
  const PushTokenState({
    this.currentToken,
    this.isSyncing = false,
    this.lastSyncTime,
    this.lastError,
    this.lastMessage,
    this.messageReceivedAt,
    this.subscribedTopics = const {},
  });

  const PushTokenState.initial() 
      : currentToken = null,
        isSyncing = false,
        lastSyncTime = null,
        lastError = null,
        lastMessage = null,
        messageReceivedAt = null,
        subscribedTopics = const {};
  
  const PushTokenState.tokenAvailable(this.currentToken) 
      : isSyncing = false,
        lastSyncTime = null,
        lastError = null,
        lastMessage = null,
        messageReceivedAt = null,
        subscribedTopics = const {};

  final String? currentToken;
  final bool isSyncing;
  final DateTime? lastSyncTime;
  final String? lastError;
  final dynamic lastMessage;
  final DateTime? messageReceivedAt;
  final Set<String> subscribedTopics;

  PushTokenState copyWith({
    String? currentToken,
    bool? isSyncing,
    DateTime? lastSyncTime,
    String? lastError,
    dynamic lastMessage,
    DateTime? messageReceivedAt,
    Set<String>? subscribedTopics,
  }) {
    return PushTokenState(
      currentToken: currentToken ?? this.currentToken,
      isSyncing: isSyncing ?? this.isSyncing,
      lastSyncTime: lastSyncTime ?? this.lastSyncTime,
      lastError: lastError ?? this.lastError,
      lastMessage: lastMessage ?? this.lastMessage,
      messageReceivedAt: messageReceivedAt ?? this.messageReceivedAt,
      subscribedTopics: subscribedTopics ?? this.subscribedTopics,
    );
  }

  static PushTokenState error(String error) => PushTokenState(lastError: error);
}
