import 'package:flutter/foundation.dart';

import 'models/phantom_log_item.dart';

class PhantomLogger extends ChangeNotifier {
  PhantomLogger._();
  static final PhantomLogger instance = PhantomLogger._();

  final List<PhantomLogItem> _logs = [];

  List<PhantomLogItem> get logs => List.unmodifiable(_logs);

  void log(PhantomLogLevel level, String message, {String? tag}) {
    final item = PhantomLogItem(
      id: _nextId(),
      level: level,
      message: message,
      tag: tag,
      createdAt: DateTime.now(),
    );
    _logs.insert(0, item);
    notifyListeners();
  }

  void info(String message, {String? tag}) =>
      log(PhantomLogLevel.info, message, tag: tag);

  void warn(String message, {String? tag}) =>
      log(PhantomLogLevel.warning, message, tag: tag);

  void error(String message, {String? tag}) =>
      log(PhantomLogLevel.error, message, tag: tag);

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
