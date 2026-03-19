import 'dart:async';

import 'package:dio/dio.dart';
import 'package:elbiblio/core/application/push_token_notifier.dart';
import 'package:elbiblio/core/network/dio_client.dart';
import 'package:elbiblio/core/services/notifications/push_notification_service.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logger/logger.dart';

class _FakePushGateway implements PushNotificationGateway {
  _FakePushGateway({this.initialToken, Map<String, dynamic>? deviceInfo})
      : _deviceInfo = deviceInfo ?? const {'platform': 'android', 'app_version': '1.0.0'};

  final String? initialToken;
  final Map<String, dynamic> _deviceInfo;
  final StreamController<String> _tokenController = StreamController<String>.broadcast();
  final StreamController<RemoteMessage> _messageController = StreamController<RemoteMessage>.broadcast();

  @override
  String? get currentToken => initialToken;

  @override
  Stream<RemoteMessage> get messageStream => _messageController.stream;

  @override
  Stream<String> get tokenStream => _tokenController.stream;

  @override
  Future<Map<String, dynamic>> getDeviceInfo() async => _deviceInfo;

  @override
  Future<void> initialize() async {}

  @override
  Future<void> subscribeToTopic(String topic) async {}

  @override
  Future<void> unsubscribeFromTopic(String topic) async {}

  Future<void> dispose() async {
    await _tokenController.close();
    await _messageController.close();
  }
}

class _FakeDioClient extends DioClient {
  _FakeDioClient({this.statusCode = 200}) : super(Logger());

  final int statusCode;
  String? lastPath;
  dynamic lastData;

  @override
  Future<Response<T>> post<T>(
    String path, {
    data,
    Map<String, dynamic>? queryParameters,
    Map<String, String>? headers,
  }) async {
    lastPath = path;
    lastData = data;
    return Response<T>(
      requestOptions: RequestOptions(path: path),
      statusCode: statusCode,
      data: <String, dynamic>{} as T,
    );
  }
}

void main() {
  group('PushTokenNotifier', () {
    test('initialize picks current token from gateway', () async {
      final gateway = _FakePushGateway(initialToken: 'abc123');
      final client = _FakeDioClient();
      final notifier = PushTokenNotifier(gateway, client);

      await notifier.initialize();

      expect(notifier.state.currentToken, 'abc123');
      await gateway.dispose();
      notifier.dispose();
    });

    test('syncTokenToBackend posts to expected endpoint and succeeds', () async {
      final gateway = _FakePushGateway();
      final client = _FakeDioClient(statusCode: 200);
      final notifier = PushTokenNotifier(gateway, client);

      final synced = await notifier.syncTokenToBackend(
        userId: '42',
        token: 'token_123',
      );

      expect(synced, isTrue);
      expect(client.lastPath, '/push-notifications/register-device');
      expect((client.lastData as Map<String, dynamic>)['device_token'], 'token_123');
      expect(notifier.state.lastError, isNull);
      await gateway.dispose();
      notifier.dispose();
    });
  });
}
