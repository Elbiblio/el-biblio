import 'dart:async';
import 'dart:io';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:package_info_plus/package_info_plus.dart';

abstract class PushNotificationGateway {
  Future<void> initialize();
  Stream<RemoteMessage> get messageStream;
  Stream<String> get tokenStream;
  String? get currentToken;
  Future<void> subscribeToTopic(String topic);
  Future<void> unsubscribeFromTopic(String topic);
  Future<Map<String, dynamic>> getDeviceInfo();
}

/// Service for managing Firebase Cloud Messaging (FCM) and APNS push notifications
class PushNotificationService implements PushNotificationGateway {
  static final PushNotificationService _instance = PushNotificationService._();
  factory PushNotificationService() => _instance;
  PushNotificationService._();
  static bool _backgroundHandlerRegistered = false;

  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;
  String? _currentToken;
  int _nextId = 1 << 30;
  StreamSubscription<String>? _tokenSubscription;
  StreamSubscription<RemoteMessage>? _messageSubscription;

  // Callbacks for handling push notifications
  final StreamController<RemoteMessage> _messageStreamController =
      StreamController<RemoteMessage>.broadcast();
  @override
  Stream<RemoteMessage> get messageStream => _messageStreamController.stream;

  final StreamController<String> _tokenStreamController =
      StreamController<String>.broadcast();
  StreamSubscription<RemoteMessage>? _onMessageOpenedAppSubscription;
  @override
  Stream<String> get tokenStream => _tokenStreamController.stream;

  static void registerBackgroundHandler() {
    if (_backgroundHandlerRegistered) return;
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
    _backgroundHandlerRegistered = true;
  }

  /// Initialize Firebase and push notification services
  @override
  Future<void> initialize() async {
    if (_initialized) return;

    try {
      // Check if Firebase is available before proceeding
      try {
        await Firebase.initializeApp();
      } catch (e) {
        debugPrint('Firebase not available for push notifications: $e');
        // Don't rethrow - continue without push notifications
        return;
      }

      // Initialize local notifications plugin for foreground display
      const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
      const iosInit = DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
      );
      const initSettings = InitializationSettings(
        android: androidInit,
        iOS: iosInit,
      );
      await _localNotifications.initialize(
        settings: initSettings,
        onDidReceiveNotificationResponse: _onLocalNotificationTapped,
      );

      // Get initial message if app was opened from notification
      final initialMessage = await _firebaseMessaging.getInitialMessage();
      if (initialMessage != null) {
        _handleMessage(initialMessage);
      }

      // Handle messages when app is in foreground
      _messageSubscription = FirebaseMessaging.onMessage.listen(
        _handleForegroundMessage,
      );

      // Handle messages when app is in background but opened
      _onMessageOpenedAppSubscription =
          FirebaseMessaging.onMessageOpenedApp.listen(_handleMessage);

      if (await _canInitializeTokenWithoutPrompt()) {
        await _initializeToken();
      } else {
        debugPrint(
          'PushNotificationService: notification permission not granted; '
          'skipping FCM token initialization.',
        );
      }

      _initialized = true;
    } catch (e) {
      debugPrint('Failed to initialize PushNotificationService: $e');
      // Don't rethrow - allow app to continue without push notifications
    }
  }

  /// Request notification permissions
  Future<bool> _requestPermissions() async {
    final settings = await _firebaseMessaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );

    return settings.authorizationStatus == AuthorizationStatus.authorized;
  }

  Future<bool> requestPermissions() async {
    final granted = await _requestPermissions();
    if (granted) {
      await _initializeToken();
    }
    return granted;
  }

  Future<bool> _canInitializeTokenWithoutPrompt() async {
    if (!Platform.isIOS && !Platform.isMacOS) {
      return true;
    }

    final settings = await _firebaseMessaging.getNotificationSettings();
    return settings.authorizationStatus == AuthorizationStatus.authorized ||
        settings.authorizationStatus == AuthorizationStatus.provisional;
  }

  /// Initialize FCM token and monitor for changes
  Future<void> _initializeToken() async {
    try {
      // Get current token
      final token = await _firebaseMessaging.getToken();
      if (token != null) {
        _currentToken = token;
        _tokenStreamController.add(token);
      }

      // Monitor token refresh
      _tokenSubscription = _firebaseMessaging.onTokenRefresh.listen((newToken) {
        _currentToken = newToken;
        _tokenStreamController.add(newToken);
      });
    } catch (e) {
      debugPrint('Failed to get FCM token: $e');
    }
  }

  /// Get current FCM token
  @override
  String? get currentToken => _currentToken;

  /// Handle foreground messages
  void _handleForegroundMessage(RemoteMessage message) {
    debugPrint('Received foreground message: ${message.messageId}');

    // Show local notification for foreground messages
    _showLocalNotification(message);

    // Add to message stream for app to handle
    _messageStreamController.add(message);
  }

  /// Handle messages when app is opened from notification
  void _handleMessage(RemoteMessage message) {
    _messageStreamController.add(message);
  }

  /// Handle tap on a local notification shown by this service
  void _onLocalNotificationTapped(NotificationResponse response) {
    if (response.payload != null && response.payload!.isNotEmpty) {
      debugPrint(
        'PushNotificationService: local notification tapped: ${response.payload}',
      );
    }
  }

  /// Show local notification for foreground messages
  Future<void> _showLocalNotification(RemoteMessage message) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
          'push_notifications_channel',
          'Push Notifications',
          channelDescription: 'Remote push notifications',
          importance: Importance.max,
          priority: Priority.high,
          showWhen: true,
        );

    const DarwinNotificationDetails iOSPlatformChannelSpecifics =
        DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        );

    const NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
      iOS: iOSPlatformChannelSpecifics,
    );

    await _localNotifications.show(
      id: _nextId++,
      title: message.notification?.title ?? 'New Message',
      body: message.notification?.body ?? 'You have a new message',
      notificationDetails: platformChannelSpecifics,
      payload: message.data.toString(),
    );
  }

  /// Subscribe to a topic
  @override
  Future<void> subscribeToTopic(String topic) async {
    try {
      await _firebaseMessaging.subscribeToTopic(topic);
    } catch (e) {
      debugPrint('Failed to subscribe to topic $topic: $e');
    }
  }

  /// Unsubscribe from a topic
  @override
  Future<void> unsubscribeFromTopic(String topic) async {
    try {
      await _firebaseMessaging.unsubscribeFromTopic(topic);
    } catch (e) {
      debugPrint('Failed to unsubscribe from topic $topic: $e');
    }
  }

  /// Get device information for push token registration
  @override
  Future<Map<String, dynamic>> getDeviceInfo() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      return {
        'platform': Platform.operatingSystem,
        'platform_version': Platform.operatingSystemVersion,
        'app_version': packageInfo.version,
        'build_number': packageInfo.buildNumber,
        'device_model': Platform.isIOS ? 'iOS' : Platform.operatingSystem,
      };
    } catch (e) {
      debugPrint('Failed to get device info: $e');
      return {
        'platform': Platform.operatingSystem,
        'platform_version': 'unknown',
        'app_version': 'unknown',
        'build_number': 'unknown',
        'device_model': 'unknown',
      };
    }
  }

  /// Dispose resources
  void dispose() {
    _tokenSubscription?.cancel();
    _messageSubscription?.cancel();
    _onMessageOpenedAppSubscription?.cancel();
    _messageStreamController.close();
    _tokenStreamController.close();
  }
}

/// Background message handler (must be top-level function)
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  try {
    await Firebase.initializeApp();
  } catch (e) {
    debugPrint('Firebase initialization failed in background handler: $e');
  }
}
