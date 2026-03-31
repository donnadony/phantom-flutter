import 'dart:convert';

import '../core/phantom_mock_interceptor.dart';
import '../core/phantom_network_logger.dart';

typedef DioInterceptorHandler = dynamic;

abstract class PhantomDioInterceptorBase {
  final _networkLogger = PhantomNetworkLogger.instance;
  final _mockInterceptor = PhantomMockInterceptor.instance;
  final Map<int, DateTime> _requestTimestamps = {};

  void onRequestIntercept(
    dynamic requestOptions, {
    required String method,
    required String url,
    required Map<String, dynamic> headers,
    required dynamic data,
    required int hashCode,
    required void Function() continueRequest,
    required void Function(int statusCode, dynamic data, Map<String, dynamic> headers) rejectWithMock,
  }) {
    final headersStr = _formatHeaders(headers);
    final bodyStr = _formatBody(data);

    final mock = _mockInterceptor.mockResponse(method: method, url: url);
    if (mock != null) {
      _networkLogger.completeRequest(
        method: method,
        url: url,
        requestHeaders: headersStr,
        requestBody: bodyStr,
        statusCode: mock.statusCode,
        responseHeaders: mock.headers,
        responseBody: mock.body,
        durationMs: 0,
      );
      rejectWithMock(mock.statusCode, mock.body, {'X-Phantom-Mock': 'true'});
      return;
    }

    _networkLogger.logRequest(
      method: method,
      url: url,
      headers: headersStr,
      body: bodyStr,
    );
    _requestTimestamps[hashCode] = DateTime.now();
    continueRequest();
  }

  void onResponseIntercept({
    required String method,
    required String url,
    required int statusCode,
    required Map<String, dynamic> responseHeaders,
    required dynamic responseData,
    required int requestHashCode,
  }) {
    final startTime = _requestTimestamps.remove(requestHashCode);
    final durationMs = startTime != null
        ? DateTime.now().difference(startTime).inMilliseconds
        : null;
    final headersStr = _formatHeaders(responseHeaders);
    final bodyStr = _formatBody(responseData);

    _networkLogger.logResponse(
      url: url,
      statusCode: statusCode,
      headers: headersStr,
      body: bodyStr,
      durationMs: durationMs,
    );
  }

  void onErrorIntercept({
    required String method,
    required String url,
    required int? statusCode,
    required String errorMessage,
    required dynamic responseData,
    required int requestHashCode,
  }) {
    final startTime = _requestTimestamps.remove(requestHashCode);
    final durationMs = startTime != null
        ? DateTime.now().difference(startTime).inMilliseconds
        : null;
    final bodyStr = responseData != null ? _formatBody(responseData) : errorMessage;

    _networkLogger.logResponse(
      url: url,
      statusCode: statusCode ?? 0,
      headers: 'Error',
      body: bodyStr,
      durationMs: durationMs,
    );
  }

  String _formatHeaders(Map<String, dynamic> headers) {
    if (headers.isEmpty) return 'No headers';
    return headers.entries.map((e) => '${e.key}: ${e.value}').join('\n');
  }

  String _formatBody(dynamic data) {
    if (data == null) return 'No body';
    if (data is String) return data.isEmpty ? 'No body' : data;
    if (data is Map || data is List) {
      try {
        return const JsonEncoder.withIndent('  ').convert(data);
      } catch (_) {
        return data.toString();
      }
    }
    return data.toString();
  }
}
