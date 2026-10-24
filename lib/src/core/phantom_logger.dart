import 'dart:convert';

import 'package:flutter/foundation.dart';

import 'models/phantom_log_item.dart';

class PhantomLogger extends ChangeNotifier {
  PhantomLogger._();
  static final PhantomLogger instance = PhantomLogger._();

  final List<PhantomLogItem> _logs = [];

  List<PhantomLogItem> get logs => List.unmodifiable(_logs);

  /// [details] may be a map, a list or an object with `toJson()`, stored as
  /// indented JSON; a string, stored as given; or any other value, stored as
  /// its `toString()`. A payload that cannot be encoded — a cycle, a throwing
  /// `toString()` — is replaced by a note saying so, never thrown.
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
    if (details == null || details is String) return details as String?;
    try {
      final json = details is Map || details is List
          ? details
          : _toJson(details);
      if (json is Map || json is List) return _json.convert(json);
      return details.toString();
    } catch (error) {
      return '<details could not be encoded: $error>';
    }
  }

  /// What `jsonEncode` would use for [value]: its `toJson()` when it has one,
  /// otherwise its text.
  static Object? _encodable(Object? value) => _toJson(value) ?? '$value';

  static Object? _toJson(Object? value) {
    try {
      return (value as dynamic).toJson();
    } on NoSuchMethodError {
      return null;
    }
  }

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
