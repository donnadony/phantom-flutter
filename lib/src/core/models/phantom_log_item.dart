import 'package:flutter/foundation.dart';

enum PhantomLogLevel {
  info,
  warning,
  error;

  /// Short uppercase label used in the UI and in exports.
  String get label {
    switch (this) {
      case PhantomLogLevel.info:
        return 'INFO';
      case PhantomLogLevel.warning:
        return 'WARN';
      case PhantomLogLevel.error:
        return 'ERROR';
    }
  }

  String get emoji {
    switch (this) {
      case PhantomLogLevel.info:
        return '🔵';
      case PhantomLogLevel.warning:
        return '🟡';
      case PhantomLogLevel.error:
        return '🔴';
    }
  }

  static PhantomLogLevel? fromLabel(String label) {
    for (final level in PhantomLogLevel.values) {
      if (level.label == label.toUpperCase()) return level;
    }
    return null;
  }
}

@immutable
class PhantomLogItem {
  final String id;
  final PhantomLogLevel level;
  final String message;
  final String? tag;
  final DateTime createdAt;

  const PhantomLogItem({
    required this.id,
    required this.level,
    required this.message,
    this.tag,
    required this.createdAt,
  });
}
