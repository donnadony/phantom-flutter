import 'dart:convert';

import 'package:flutter/foundation.dart';

import 'models/phantom_network_item.dart';

class PhantomNetworkLogger extends ChangeNotifier {
  PhantomNetworkLogger._();
  static final PhantomNetworkLogger instance = PhantomNetworkLogger._();

  final List<PhantomNetworkItem> _items = [];
  final Map<String, List<String>> _pendingByKey = {};
  final Map<String, List<String>> _pendingByUrl = {};

  List<PhantomNetworkItem> get logs => List.unmodifiable(_items);

  int _counter = 0;

  String _nextId() {
    _counter++;
    return 'net_$_counter';
  }

  void logRequest({
    required String method,
    required String url,
    String headers = 'No headers',
    String body = 'No body',
  }) {
    final id = _nextId();
    final item = PhantomNetworkItem(
      id: id,
      url: url,
      methodType: method,
      requestHeaders: headers,
      requestBody: body,
      createdAt: DateTime.now(),
    );
    _items.add(item);
    _addPending(id: id, method: method, url: url, body: body);
    notifyListeners();
  }

  void logResponse({
    required String url,
    required int statusCode,
    String headers = 'No headers',
    String body = '',
    int? durationMs,
    bool isMock = false,
  }) {
    final index = _indexOfPendingByUrl(url);
    final now = DateTime.now();
    final responseSize = utf8.encode(body).length;

    if (index != null) {
      final existing = _items[index];
      final duration =
          durationMs ?? now.difference(existing.createdAt).inMilliseconds;
      _items[index] = existing.copyWith(
        statusCode: statusCode,
        responseHeaders: headers,
        responseBody: body,
        responseSizeBytes: responseSize,
        completedAt: now,
        durationMs: duration,
        isMock: isMock ? true : null,
      );
      _removePending(existing.id);
    } else {
      _items.add(PhantomNetworkItem(
        id: _nextId(),
        url: url,
        methodType: 'GET',
        responseHeaders: headers,
        responseBody: body,
        responseSizeBytes: responseSize,
        statusCode: statusCode,
        completedAt: now,
        durationMs: durationMs,
        createdAt: now,
        isMock: isMock,
      ));
    }
    notifyListeners();
  }

  /// Records a failed request (timeout, socket error, cancellation) against its
  /// pending entry so it stops showing as PENDING forever.
  void logError({
    required String url,
    required String errorMessage,
    int? statusCode,
    String headers = 'No headers',
    int? durationMs,
  }) {
    logResponse(
      url: url,
      statusCode: statusCode ?? -1,
      headers: headers,
      body: errorMessage,
      durationMs: durationMs,
    );
  }

  void completeRequest({
    required String method,
    required String url,
    String requestHeaders = 'No headers',
    String requestBody = 'No body',
    required int statusCode,
    String responseHeaders = 'No headers',
    String responseBody = '',
    int? durationMs,
    bool isMock = false,
  }) {
    final index = _indexOfPending(method: method, url: url, body: requestBody);
    final now = DateTime.now();
    final responseSize = utf8.encode(responseBody).length;

    if (index != null) {
      final existing = _items[index];
      final duration =
          durationMs ?? now.difference(existing.createdAt).inMilliseconds;
      _items[index] = existing.copyWith(
        statusCode: statusCode,
        responseHeaders: responseHeaders,
        responseBody: responseBody,
        responseSizeBytes: responseSize,
        completedAt: now,
        durationMs: duration,
        isMock: isMock ? true : null,
      );
      _removePending(existing.id);
    } else {
      final createdAt = durationMs != null
          ? now.subtract(Duration(milliseconds: durationMs))
          : now;
      _items.add(PhantomNetworkItem(
        id: _nextId(),
        url: url,
        methodType: method,
        requestHeaders: requestHeaders,
        requestBody: requestBody,
        responseHeaders: responseHeaders,
        responseBody: responseBody,
        responseSizeBytes: responseSize,
        statusCode: statusCode,
        completedAt: now,
        durationMs: durationMs,
        createdAt: createdAt,
        isMock: isMock,
      ));
    }
    notifyListeners();
  }

  /// Called by [PhantomMockInterceptor] when a request is served from a mock so
  /// the intercepted call still shows up in the Network list, flagged as MOCK.
  void logMockResponse({
    required String method,
    required String url,
    required int statusCode,
    String headers = 'Content-Type: application/json',
    String body = '',
  }) {
    completeRequest(
      method: method,
      url: url,
      statusCode: statusCode,
      responseHeaders: headers,
      responseBody: body,
      durationMs: 0,
      isMock: true,
    );
  }

  /// Attaches status/headers to an in-flight entry without completing it, for
  /// HTTP clients that surface response metadata before the body.
  void updateResponseMetadata({
    required String url,
    String headers = 'No headers',
    int? statusCode,
  }) {
    final index = _indexOfPendingByUrl(url) ?? _indexOfLatestWithoutStatus(url);
    if (index == null) return;
    _items[index] = _items[index].copyWith(
      responseHeaders: headers,
      statusCode: statusCode,
    );
    notifyListeners();
  }

  void logExternalEntry(Map<String, dynamic> data,
      {String sourcePrefix = '[External]'}) {
    final url = data['url'] as String? ?? '';
    final method = data['method'] as String? ?? 'GET';
    final statusCode = data['statusCode'] as int?;
    final requestHeaders = data['requestHeaders'] as String? ?? 'No headers';
    final responseBody = data['responseBody'] as String? ?? '';
    final responseSizeBytes = data['responseSizeBytes'] as int? ?? 0;
    final durationMs = data['durationMs'] as int?;
    final now = DateTime.now();
    final createdAt = durationMs != null
        ? now.subtract(Duration(milliseconds: durationMs))
        : now;

    _items.add(PhantomNetworkItem(
      id: _nextId(),
      url: url,
      methodType: '$sourcePrefix $method',
      requestHeaders: requestHeaders,
      requestBody: 'No body',
      responseHeaders: 'No headers',
      responseBody: responseBody,
      responseSizeBytes: responseSizeBytes,
      statusCode: statusCode,
      completedAt: now,
      durationMs: durationMs,
      createdAt: createdAt,
    ));
    notifyListeners();
  }

  void clearAll() {
    _items.clear();
    _pendingByKey.clear();
    _pendingByUrl.clear();
    notifyListeners();
  }

  void _addPending({
    required String id,
    required String method,
    required String url,
    required String body,
  }) {
    final key = _makeKey(method, url, body);
    _pendingByKey.putIfAbsent(key, () => []).add(id);
    _pendingByUrl.putIfAbsent(url, () => []).add(id);
  }

  void _removePending(String id) {
    _pendingByKey.updateAll((_, ids) {
      ids.remove(id);
      return ids;
    });
    _pendingByKey.removeWhere((_, ids) => ids.isEmpty);
    _pendingByUrl.updateAll((_, ids) {
      ids.remove(id);
      return ids;
    });
    _pendingByUrl.removeWhere((_, ids) => ids.isEmpty);
  }

  int? _indexOfPending({
    required String method,
    required String url,
    required String body,
  }) {
    final key = _makeKey(method, url, body);
    final ids = _pendingByKey[key];
    if (ids != null) {
      for (final id in ids) {
        final index =
            _items.indexWhere((item) => item.id == id && item.isPending);
        if (index != -1) return index;
      }
    }
    return _indexOfPendingByUrl(url);
  }

  int? _indexOfPendingByUrl(String url) {
    final ids = _pendingByUrl[url];
    if (ids == null) return null;
    for (final id in ids) {
      final index =
          _items.indexWhere((item) => item.id == id && item.isPending);
      if (index != -1) return index;
    }
    return null;
  }

  int? _indexOfLatestWithoutStatus(String url) {
    for (var i = _items.length - 1; i >= 0; i--) {
      if (_items[i].url == url && _items[i].statusCode == null) return i;
    }
    return null;
  }

  String _makeKey(String method, String url, String body) {
    return '$method|$url|$body';
  }
}
