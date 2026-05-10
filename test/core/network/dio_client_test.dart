import 'dart:convert';
import 'dart:io';

import 'package:elbiblio/core/errors/app_exception.dart';
import 'package:elbiblio/core/network/dio_client.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logger/logger.dart';

void main() {
  late HttpServer server;

  tearDown(() async {
    await server.close(force: true);
  });

  test(
    'throws typed API failure for 4xx responses with backend message',
    () async {
      server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      server.listen((request) {
        request.response
          ..statusCode = HttpStatus.unprocessableEntity
          ..headers.contentType = ContentType.json
          ..write(
            jsonEncode({
              'message': 'Email is required',
              'errors': {
                'email': ['Email is required'],
              },
            }),
          )
          ..close();
      });

      final client = DioClient(
        Logger(level: Level.off),
        baseUrl: 'http://127.0.0.1:${server.port}',
      );

      await expectLater(
        client.get<Map<String, dynamic>>('/signup'),
        throwsA(
          isA<ApiRequestException>()
              .having((error) => error.statusCode, 'statusCode', 422)
              .having((error) => error.message, 'message', 'Email is required'),
        ),
      );
    },
  );
}
