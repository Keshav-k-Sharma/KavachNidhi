import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/core/network/api_client.dart';
import 'package:frontend/features/subscriptions/data/subscriptions_api.dart';

void main() {
  group('subscriptions_api', () {
    late HttpServer server;
    late ApiClient client;

    setUp(() async {
      server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      client = ApiClient(
        baseUrl: 'http://${server.address.address}:${server.port}',
      );
    });

    tearDown(() async {
      await server.close(force: true);
    });

    test(
      'fetchActiveSubscriptionResult accepts null data when success is true',
      () async {
        server.listen((HttpRequest request) async {
          request.response
            ..statusCode = 200
            ..headers.contentType = ContentType.json
            ..write(
              jsonEncode(<String, dynamic>{
                'success': true,
                'data': null,
                'error': null,
              }),
            );
          await request.response.close();
        });

        final ApiCallResult<Map<String, dynamic>?> result =
            await fetchActiveSubscriptionResult(client);

        expect(result.success, isTrue);
        expect(result.data, isNull);
        expect(result.error, isNull);
      },
    );

    test('subscribeTierResult surfaces backend error text', () async {
      server.listen((HttpRequest request) async {
        request.response
          ..statusCode = 200
          ..headers.contentType = ContentType.json
          ..write(
            jsonEncode(<String, dynamic>{
              'success': false,
              'data': null,
              'error': 'Tier already active',
            }),
          );
        await request.response.close();
      });

      final ApiCallResult<Map<String, dynamic>> result =
          await subscribeTierResult(client, tier: 'plus');

      expect(result.success, isFalse);
      expect(result.error, 'Tier already active');
    });
  });
}
