import 'package:flutter_test/flutter_test.dart';
import 'package:phantom_flutter/phantom_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('PhantomLogger', () {
    setUp(() => PhantomLogger.instance.clearAll());

    test('logs items with correct level and tag', () {
      PhantomLogger.instance.log(
        PhantomLogLevel.info,
        'test message',
        tag: 'Auth',
      );

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

    test('convenience helpers map to the right level', () {
      PhantomLogger.instance.info('i');
      PhantomLogger.instance.warn('w');
      PhantomLogger.instance.error('e');

      final levels = PhantomLogger.instance.logs.map((l) => l.level).toList();
      expect(levels, [
        PhantomLogLevel.error,
        PhantomLogLevel.warning,
        PhantomLogLevel.info,
      ]);
    });

    test('levels expose canonical labels', () {
      expect(PhantomLogLevel.info.label, 'INFO');
      expect(PhantomLogLevel.warning.label, 'WARN');
      expect(PhantomLogLevel.error.label, 'ERROR');
      expect(PhantomLogLevel.fromLabel('WARN'), PhantomLogLevel.warning);
    });

    test('clearAll removes all logs', () {
      PhantomLogger.instance.log(PhantomLogLevel.info, 'test');
      PhantomLogger.instance.clearAll();

      expect(PhantomLogger.instance.logs, isEmpty);
    });
  });

  group('PhantomNetworkLogger', () {
    setUp(() => PhantomNetworkLogger.instance.clearAll());

    test('correlates a response with its pending request', () {
      PhantomNetworkLogger.instance.logRequest(
        method: 'GET',
        url: 'https://api.test/v1/users',
      );
      PhantomNetworkLogger.instance.logResponse(
        url: 'https://api.test/v1/users',
        statusCode: 200,
        body: '{"ok":true}',
      );

      final logs = PhantomNetworkLogger.instance.logs;
      expect(logs.length, 1);
      expect(logs.first.statusCode, 200);
      expect(logs.first.isPending, isFalse);
      expect(logs.first.methodType, 'GET');
    });

    test('a response with no pending request creates its own entry', () {
      PhantomNetworkLogger.instance.logResponse(
        url: 'https://api.test/orphan',
        statusCode: 404,
      );

      expect(PhantomNetworkLogger.instance.logs.length, 1);
      expect(PhantomNetworkLogger.instance.logs.first.statusCode, 404);
    });

    test('concurrent requests to the same URL each get their own entry', () {
      PhantomNetworkLogger.instance.logRequest(
        method: 'GET',
        url: 'https://api.test/feed',
      );
      PhantomNetworkLogger.instance.logRequest(
        method: 'GET',
        url: 'https://api.test/feed',
      );

      PhantomNetworkLogger.instance.logResponse(
        url: 'https://api.test/feed',
        statusCode: 200,
      );

      final logs = PhantomNetworkLogger.instance.logs;
      expect(logs.length, 2);
      expect(logs.where((l) => l.isPending).length, 1);
      expect(logs.where((l) => !l.isPending).length, 1);
    });

    test('logError completes a pending request', () {
      PhantomNetworkLogger.instance.logRequest(
        method: 'POST',
        url: 'https://api.test/login',
      );
      PhantomNetworkLogger.instance.logError(
        url: 'https://api.test/login',
        errorMessage: 'Connection timeout',
      );

      final item = PhantomNetworkLogger.instance.logs.single;
      expect(item.isPending, isFalse);
      expect(item.responseBody, 'Connection timeout');
    });

    test('updateResponseMetadata does not complete the request', () {
      PhantomNetworkLogger.instance.logRequest(
        method: 'GET',
        url: 'https://api.test/slow',
      );
      PhantomNetworkLogger.instance.updateResponseMetadata(
        url: 'https://api.test/slow',
        statusCode: 200,
        headers: 'Content-Type: application/json',
      );

      final item = PhantomNetworkLogger.instance.logs.single;
      expect(item.statusCode, 200);
      expect(item.isPending, isTrue);
    });

    test('logMockResponse flags the entry as a mock', () {
      PhantomNetworkLogger.instance.logMockResponse(
        method: 'GET',
        url: 'https://api.test/v1/users',
        statusCode: 200,
        body: '[]',
      );

      expect(PhantomNetworkLogger.instance.logs.single.isMock, isTrue);
    });

    test('completeRequest records size and duration', () {
      PhantomNetworkLogger.instance.completeRequest(
        method: 'POST',
        url: 'https://api.test/v1/orders',
        statusCode: 201,
        responseBody: '{"id":1}',
        durationMs: 250,
      );

      final item = PhantomNetworkLogger.instance.logs.single;
      expect(item.durationMs, 250);
      expect(item.responseSizeBytes, 8);
    });
  });

  group('PhantomMockInterceptor', () {
    final interceptor = PhantomMockInterceptor.instance;

    PhantomMockRule buildRule({
      String id = 'rule_1',
      String pattern = '/v1/users',
      String method = 'ANY',
      int statusCode = 200,
      String body = '[]',
      bool enabled = true,
    }) {
      return PhantomMockRule(
        id: id,
        isEnabled: enabled,
        urlPattern: pattern,
        httpMethod: method,
        ruleDescription: 'Test rule',
        responses: [
          PhantomMockResponse(
            id: '${id}_r1',
            name: 'Response 1',
            httpMethod: method,
            statusCode: statusCode,
            responseBody: body,
          ),
        ],
        activeResponseId: '${id}_r1',
      );
    }

    setUp(() async {
      await interceptor.clearAll();
      PhantomNetworkLogger.instance.clearAll();
    });

    test('matches a rule on the URL path', () async {
      await interceptor.addRule(buildRule());

      final hit = interceptor.mockResponse(
        method: 'GET',
        url: 'https://api.test/v1/users?page=2',
      );

      expect(hit, isNotNull);
      expect(hit!.statusCode, 200);
      expect(hit.body, '[]');
    });

    test('does not match when the pattern only appears in the query', () async {
      await interceptor.addRule(buildRule(pattern: '/v1/admin'));

      final hit = interceptor.mockResponse(
        method: 'GET',
        url: 'https://api.test/v1/users?redirect=/v1/admin',
      );

      expect(hit, isNull);
    });

    test('respects the HTTP method', () async {
      await interceptor.addRule(buildRule(method: 'POST'));

      expect(
        interceptor.mockResponse(
          method: 'GET',
          url: 'https://api.test/v1/users',
        ),
        isNull,
      );
      expect(
        interceptor.mockResponse(
          method: 'POST',
          url: 'https://api.test/v1/users',
        ),
        isNotNull,
      );
    });

    test('disabled rules are skipped', () async {
      await interceptor.addRule(buildRule(enabled: false));

      expect(
        interceptor.mockResponse(
          method: 'GET',
          url: 'https://api.test/v1/users',
        ),
        isNull,
      );
    });

    test('a hit is recorded in the network log as a mock', () async {
      await interceptor.addRule(buildRule());

      interceptor.mockResponse(method: 'GET', url: 'https://api.test/v1/users');

      final logs = PhantomNetworkLogger.instance.logs;
      expect(logs.length, 1);
      expect(logs.single.isMock, isTrue);
      expect(logs.single.statusCode, 200);
    });

    test('setActiveResponse switches which response is served', () async {
      final rule = buildRule();
      rule.responses.add(
        PhantomMockResponse(
          id: 'rule_1_r2',
          name: 'Server error',
          httpMethod: 'ANY',
          statusCode: 500,
          responseBody: '{"error":"boom"}',
        ),
      );
      await interceptor.addRule(rule);

      await interceptor.setActiveResponse(
        ruleId: 'rule_1',
        responseId: 'rule_1_r2',
      );

      final hit = interceptor.mockResponse(
        method: 'GET',
        url: 'https://api.test/v1/users',
      );
      expect(hit!.statusCode, 500);
    });

    test('export produces a collection that round-trips', () async {
      await interceptor.addRule(buildRule());
      final exported = interceptor.exportCollection(name: 'My mocks');

      await interceptor.clearAll();
      final imported = await interceptor.importCollection(exported);

      expect(imported, 1);
      expect(interceptor.rules.single.urlPattern, '/v1/users');
      expect(PhantomMockCollection.decode(exported)!.name, 'My mocks');
    });

    test('import merges rules with the same pattern and method', () async {
      await interceptor.addRule(buildRule(statusCode: 200));

      final incoming = PhantomMockCollection(
        name: 'Incoming',
        rules: [buildRule(id: 'rule_2', statusCode: 503)],
      ).encode();
      await interceptor.importCollection(incoming);

      expect(interceptor.rules.length, 1);
      expect(interceptor.rules.single.activeResponse!.statusCode, 503);
    });

    test('import accepts a bare array of rules', () async {
      final bare = PhantomMockRule.encodeRules([buildRule()]);

      expect(await interceptor.importCollection(bare), 1);
    });

    test('import rejects invalid payloads', () async {
      expect(await interceptor.importCollection('not json'), isNull);
      expect(await interceptor.importCollection('{"rules":[]}'), isNull);
    });

    test('ruleForEndpoint finds an existing rule for the endpoint', () async {
      await interceptor.addRule(buildRule());

      final found = interceptor.ruleForEndpoint(
        method: 'GET',
        url: 'https://api.test/v1/users/42',
      );
      expect(found?.id, 'rule_1');
    });

    test('rules survive a save/load round-trip', () async {
      await interceptor.addRule(buildRule());
      await interceptor.loadRules();

      expect(interceptor.rules.length, 1);
      expect(interceptor.rules.single.ruleDescription, 'Test rule');
    });
  });

  group('PhantomConfig', () {
    test('registers entries and reads default values', () async {
      PhantomConfig.instance.register(
        label: 'API URL',
        key: 'config_test_api_url',
        defaultValue: 'https://api.example.com',
      );

      expect(
        await PhantomConfig.instance.effectiveValue('config_test_api_url'),
        'https://api.example.com',
      );
    });

    test('an override wins over the default and can be reset', () async {
      PhantomConfig.instance.register(
        label: 'Env',
        key: 'config_test_env',
        defaultValue: 'prod',
      );

      await PhantomConfig.instance.setValue('config_test_env', 'staging');
      expect(
        await PhantomConfig.instance.effectiveValue('config_test_env'),
        'staging',
      );

      await PhantomConfig.instance.resetValue('config_test_env');
      expect(
        await PhantomConfig.instance.effectiveValue('config_test_env'),
        'prod',
      );
    });

    test('registering the same key twice is a no-op', () {
      final before = PhantomConfig.instance.entries.length;
      PhantomConfig.instance.register(
        label: 'Dup',
        key: 'config_test_dup',
        defaultValue: 'a',
      );
      PhantomConfig.instance.register(
        label: 'Dup again',
        key: 'config_test_dup',
        defaultValue: 'b',
      );

      expect(PhantomConfig.instance.entries.length, before + 1);
    });
  });

  group('PhantomLocalizer', () {
    setUp(() => PhantomLocalizer.instance.removeAll());

    test('returns the value for the active language', () async {
      PhantomLocalizer.instance.register(
        key: 'welcome',
        english: 'Welcome',
        spanish: 'Bienvenido',
      );

      expect(PhantomLocalizer.instance.localized('welcome'), 'Welcome');

      await PhantomLocalizer.instance.setLanguage(PhantomLanguage.spanish);
      expect(PhantomLocalizer.instance.localized('welcome'), 'Bienvenido');

      await PhantomLocalizer.instance.setLanguage(PhantomLanguage.english);
    });

    test('an unknown key falls back to the key itself', () {
      expect(PhantomLocalizer.instance.localized('missing'), 'missing');
    });

    test('the same key can live in different groups', () {
      PhantomLocalizer.instance.register(
        key: 'title',
        english: 'Home',
        spanish: 'Inicio',
        group: 'Home',
      );
      PhantomLocalizer.instance.register(
        key: 'title',
        english: 'Profile',
        spanish: 'Perfil',
        group: 'Profile',
      );

      expect(
        PhantomLocalizer.instance.localized('title', group: 'Profile'),
        'Profile',
      );
      expect(PhantomLocalizer.instance.groups, ['Home', 'Profile']);
    });
  });
}
