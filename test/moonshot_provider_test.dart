import 'dart:convert';
import 'dart:io';

import 'package:ai_balance_tracker/models/balance_info.dart';
import 'package:ai_balance_tracker/models/provider_config.dart';
import 'package:ai_balance_tracker/providers/moonshot_provider.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('MoonshotProvider', () {
    test('returns USD currency for successful balance response', () async {
      final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      addTearDown(server.close);

      server.listen((request) async {
        expect(request.method, 'GET');
        expect(request.uri.path, '/v1/users/me/balance');
        request.response.statusCode = 200;
        request.response.headers.contentType = ContentType.json;
        request.response.write(jsonEncode({
          'code': 0,
          'status': true,
          'data': {'available_balance': 12.5},
        }));
        await request.response.close();
      });

      final config = ProviderConfig(
        id: 'moonshot_test',
        type: ProviderType.moonshot,
        apiKey: 'test-key',
        customEndpoint: 'http://127.0.0.1:${server.port}',
      );
      final provider = MoonshotProvider(config);

      final balance = await provider.getBalance();

      expect(balance.currency, 'USD');
      expect(balance.balance, 12.5);
    });

    test('returns USD currency for invalid API key status', () async {
      final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      addTearDown(server.close);

      server.listen((request) async {
        request.response.statusCode = 401;
        request.response.headers.contentType = ContentType.json;
        request.response.write('{"error":"unauthorized"}');
        await request.response.close();
      });

      final config = ProviderConfig(
        id: 'moonshot_test',
        type: ProviderType.moonshot,
        apiKey: 'bad-key',
        customEndpoint: 'http://127.0.0.1:${server.port}',
      );
      final provider = MoonshotProvider(config);

      final balance = await provider.getBalance();

      expect(balance.currency, 'USD');
      expect(balance.status, BalanceStatus.invalidKey);
    });
  });
}
