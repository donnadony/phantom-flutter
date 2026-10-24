import 'dart:convert';

import 'package:flutter/foundation.dart';

import 'models/phantom_log_item.dart';

class PhantomLogger extends ChangeNotifier {
  PhantomLogger._();
  static final PhantomLogger instance = PhantomLogger._();

  final List<PhantomLogItem> _logs = [];

  List<PhantomLogItem> get logs => List.unmodifiable(_logs);

  /// [details] may be a map or a list, which is stored as indented JSON, or
  /// any other value, which is stored as its `toString()`.
  void log(
    PhantomLogLevel level,
    String message, {
    String? tag,
    Object? details,
  }) {
    final item = PhantomLogItem(
      id: _nextId(),
      level: level,
      message: message,
      tag: tag,
      createdAt: DateTime.now(),
      details: _encodeDetails(details),
    );
    _logs.insert(0, item);
    notifyListeners();
  }

  void info(String message, {String? tag, Object? details}) =>
      log(PhantomLogLevel.info, message, tag: tag, details: details);

  void warn(String message, {String? tag, Object? details}) =>
      log(PhantomLogLevel.warning, message, tag: tag, details: details);

  void error(String message, {String? tag, Object? details}) =>
      log(PhantomLogLevel.error, message, tag: tag, details: details);

  static const _json = JsonEncoder.withIndent('  ', _encodable);

  static String? _encodeDetails(Object? details) {
    if (details == null) return null;
    if (details is String) return details;
    if (details is Map || details is List) return _json.convert(details);
    return details.toString();
  }

  static Object? _encodable(Object? value) => value.toString();

  void clearAll() {
    _logs.clear();
    notifyListeners();
  }

  int _counter = 0;

  String _nextId() {
    _counter++;
    return 'log_$_counter';
  }
}
