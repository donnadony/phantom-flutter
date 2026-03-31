import 'package:flutter_test/flutter_test.dart';
import 'package:phantom_flutter/phantom_flutter.dart';

void main() {
  group('PhantomLogger', () {
    setUp(() => PhantomLogger.instance.clearAll());

    test('logs items with correct level and tag', () {
      PhantomLogger.instance.log(PhantomLogLevel.info, 'test message', tag: 'Auth');

      expect(PhantomLogger.instance.logs.length, 1);
      expect(PhantomLogger.instance.logs.first.level, PhantomLogLevel.info);
      expect(PhantomLogger.instance.logs.first.message, 'test message');
      expect(PhantomLogger.instance.logs.first.tag, 'Auth');
    });

    test('newest logs appear first', () {
      PhantomLogger.instance.log(PhantomLogLevel.info, 'first');
      PhantomLogger.instance.log(PhantomLogLevel.error, 'second');

      expect(PhantomLogger.instance.logs.first.message, 'second');
    });

    test('clearAll removes all logs', () {
      PhantomLogger.instance.log(PhantomLogLevel.info, 'test');
      PhantomLogger.instance.clearAll();

      expect(PhantomLogger.instance.logs, isEmpty);
    });
  });

  group('PhantomNetworkLogger', () {
    setUp(() => PhantomNetworkLogger.instance.clearAll());

    test('logs request and correlates response', () {
      PhantomNetworkLogger.instance.logRequest(
        method: 'GET',
        url: 'https://api.example.com/users',
      );

      expect(PhantomNetworkLogger.instance.logs.length, 1);
      expect(PhantomNetworkLogger.instance.logs.first.isPending, true);

      PhantomNetworkLogger.instance.logResponse(
        url: 'https://api.example.com/users',
        statusCode: 200,
        body: '{"users": []}',
      );

      expect(PhantomNetworkLogger.instance.logs.length, 1);
      expect(PhantomNetworkLogger.instance.logs.first.statusCode, 200);
      expect(PhantomNetworkLogger.instance.logs.first.isPending, false);
    });

    test('completeRequest creates a full entry', () {
      PhantomNetworkLogger.instance.completeRequest(
        method: 'POST',
        url: 'https://api.example.com/login',
        statusCode: 200,
        responseBody: '{"token": "abc"}',
        durationMs: 150,
      );

      final item = PhantomNetworkLogger.instance.logs.first;
      expect(item.methodType, 'POST');
      expect(item.statusCode, 200);
      expect(item.durationMs, 150);
    });
  });

  group('Phantom static API', () {
    setUp(() {
      PhantomLogger.instance.clearAll();
      PhantomNetworkLogger.instance.clearAll();
    });

    test('log delegates to PhantomLogger', () {
      Phantom.log(PhantomLogLevel.warning, 'test warning', tag: 'Test');

      expect(PhantomLogger.instance.logs.length, 1);
      expect(PhantomLogger.instance.logs.first.level, PhantomLogLevel.warning);
    });

    test('logRequest delegates to PhantomNetworkLogger', () {
      Phantom.logRequest(method: 'GET', url: 'https://example.com');

      expect(PhantomNetworkLogger.instance.logs.length, 1);
    });
  });
}
