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

  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();
  
  bool _initialized = false;
  String? _currentToken;
  StreamSubscription<String>? _tokenSubscription;
  StreamSubscription<RemoteMessage>? _messageSubscription;

  // Callbacks for handling push notifications
  final StreamController<RemoteMessage> _messageStreamController = 
      StreamController<RemoteMessage>.broadcast();
  @override
  Stream<RemoteMessage> get messageStream => _messageStreamController.stream;

  final StreamController<String> _tokenStreamController = 
      StreamController<String>.broadcast();
  @override
  Stream<String> get tokenStream => _tokenStreamController.stream;

  /// Initialize Firebase and push notification services
  @override
  Future<void> initialize() async {
    if (_initialized) return;

    try {
      // Check if Firebase is available before proceeding
      try {
        await Firebase.initializeApp();
        debugPrint('Firebase initialized in PushNotificationService');
      } catch (e) {
        debugPrint('Firebase not available in PushNotificationService: $e');
        // Don't rethrow - continue without push notifications
        return;
      }
      
      // Request notification permissions
      await _requestPermissions();

      // Get initial message if app was opened from notification
      final initialMessage = await _firebaseMessaging.getInitialMessage();
      if (initialMessage != null) {
        _handleMessage(initialMessage);
      }

      // Handle messages when app is in foreground
      _messageSubscription = FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

      // Handle messages when app is in background but opened
      FirebaseMessaging.onMessageOpenedApp.listen(_handleMessage);

      // Handle background messages
      FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

      // Get and monitor token changes
      await _initializeToken();

      _initialized = true;
      debugPrint('PushNotificationService initialized successfully');
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

    debugPrint('Notification permission status: ${settings.authorizationStatus}');
    return settings.authorizationStatus == AuthorizationStatus.authorized;
  }

  /// Initialize FCM token and monitor for changes
  Future<void> _initializeToken() async {
    try {
      // Get current token
      final token = await _firebaseMessaging.getToken();
      if (token != null) {
        _currentToken = token;
        _tokenStreamController.add(token);
        debugPrint('FCM Token obtained successfully: ${token.substring(0, 8)}...');
      } else {
        debugPrint('FCM Token is null - this might be expected in some environments');
      }

      // Monitor token refresh
      _tokenSubscription = _firebaseMessaging.onTokenRefresh.listen((newToken) {
        _currentToken = newToken;
        _tokenStreamController.add(newToken);
        debugPrint('FCM Token refreshed: ${newToken.substring(0, 8)}...');
      });

    } catch (e) {
      final errorMessage = e.toString();
      debugPrint('Failed to get FCM token: $errorMessage');
      
      // Provide more specific error information
      if (errorMessage.contains('FIS_AUTH_ERROR')) {
        debugPrint('FIS_AUTH_ERROR: This usually indicates Firebase installation issues.');
        debugPrint('Possible solutions:');
        debugPrint('1. Check if google-services.json (Android) or GoogleService-Info.plist (iOS) is properly configured');
        debugPrint('2. Verify Firebase project settings and app registration');
        debugPrint('3. Try clearing app data and reinstalling');
        debugPrint('4. Check network connectivity');
      } else if (errorMessage.contains('firebase_messaging/unknown')) {
        debugPrint('Firebase Messaging unknown error - service may not be available in this environment');
      }
      
      // Continue without FCM token - app should still function
      debugPrint('Continuing without FCM token - local notifications will still work');
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
    debugPrint('App opened from notification: ${message.messageId}');
    _messageStreamController.add(message);
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
      id: message.hashCode,
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
      debugPrint('Subscribed to topic: $topic');
    } catch (e) {
      debugPrint('Failed to subscribe to topic $topic: $e');
    }
  }

  /// Unsubscribe from a topic
  @override
  Future<void> unsubscribeFromTopic(String topic) async {
    try {
      await _firebaseMessaging.unsubscribeFromTopic(topic);
      debugPrint('Unsubscribed from topic: $topic');
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
    _messageStreamController.close();
    _tokenStreamController.close();
  }
}

/// Background message handler (must be top-level function)
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  try {
    await Firebase.initializeApp();
    debugPrint('Handling a background message: ${message.messageId}');
  } catch (e) {
    debugPrint('Firebase initialization failed in background handler: $e');
  }
}
