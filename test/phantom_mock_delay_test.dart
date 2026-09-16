import 'package:flutter_test/flutter_test.dart';
import 'package:phantom_flutter/src/adapters/dio_interceptor.dart';
import 'package:phantom_flutter/src/core/models/phantom_mock_rule.dart';
import 'package:phantom_flutter/src/core/phantom_mock_interceptor.dart';
import 'package:phantom_flutter/src/core/phantom_network_logger.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _Adapter extends PhantomDioInterceptorBase {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final mocks = PhantomMockInterceptor.instance;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    PhantomNetworkLogger.instance.clearAll();
    await mocks.clearAll();
  });

  Future<void> addRule({required int delayMs}) => mocks.addRule(
    PhantomMockRule(
      id: 'rule',
      urlPattern: '/v1/users',
      responses: [
        PhantomMockResponse(
          id: 'response',
          name: 'Slow',
          delayMs: delayMs,
          responseBody: '{}',
        ),
      ],
    ),
  );

  Future<void> intercept(_Adapter adapter, {required void Function() onMock}) =>
      adapter.onRequestIntercept(
        null,
        method: 'GET',
        url: 'https://example.com/v1/users',
        headers: const {},
        data: null,
        hashCode: 1,
        continueRequest: () {},
        rejectWithMock: (_, _, _) => onMock(),
      );

  test('a response answers at once unless a delay is asked for', () {
    expect(PhantomMockResponse(id: 'a', name: 'n').delayMs, 0);
  });

  test('a response carries its delay through json', () {
    final response = PhantomMockResponse(id: 'a', name: 'n', delayMs: 1500);

    expect(PhantomMockResponse.fromJson(response.toJson()).delayMs, 1500);
  });

  test('copyWith replaces the delay and keeps it otherwise', () {
    final response = PhantomMockResponse(id: 'a', name: 'n', delayMs: 500);

    expect(response.copyWith(delayMs: 3000).delayMs, 3000);
    expect(response.copyWith(name: 'other').delayMs, 500);
  });

  test('a hit carries the delay its response asks for', () async {
    await addRule(delayMs: 1500);

    final hit = mocks.mockResponse(
      method: 'GET',
      url: 'https://example.com/v1/users',
    );

    expect(hit?.delayMs, 1500);
  });

  test('the dio adapter waits the delay out before answering', () async {
    await addRule(delayMs: 300);
    var answered = false;

    final intercepting = intercept(_Adapter(), onMock: () => answered = true);
    await Future<void>.delayed(const Duration(milliseconds: 50));
    expect(answered, isFalse);

    await intercepting;
    expect(answered, isTrue);
  });

  test('a mock with no delay still answers within the same turn', () async {
    await addRule(delayMs: 0);
    var answered = false;

    final intercepting = intercept(_Adapter(), onMock: () => answered = true);

    expect(answered, isTrue);
    await intercepting;
  });
}
