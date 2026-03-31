import 'package:flutter/foundation.dart';

enum PhantomLogLevel { info, warning, error }

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
