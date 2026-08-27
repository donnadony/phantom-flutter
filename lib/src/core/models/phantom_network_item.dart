import 'package:flutter/foundation.dart';

@immutable
class PhantomNetworkItem {
  final String id;
  final String? url;
  final String methodType;
  final String requestHeaders;
  final String requestBody;
  final String responseHeaders;
  final String responseBody;
  final int responseSizeBytes;
  final int? statusCode;
  final DateTime? completedAt;
  final int? durationMs;
  final DateTime createdAt;
  final bool isMock;

  const PhantomNetworkItem({
    required this.id,
    this.url,
    required this.methodType,
    this.requestHeaders = 'No headers',
    this.requestBody = 'No body',
    this.responseHeaders = 'No headers',
    this.responseBody = '',
    this.responseSizeBytes = 0,
    this.statusCode,
    this.completedAt,
    this.durationMs,
    required this.createdAt,
    this.isMock = false,
  });

  PhantomNetworkItem copyWith({
    String? responseHeaders,
    String? responseBody,
    int? responseSizeBytes,
    int? statusCode,
    DateTime? completedAt,
    int? durationMs,
    bool? isMock,
  }) {
    return PhantomNetworkItem(
      id: id,
      url: url,
      methodType: methodType,
      requestHeaders: requestHeaders,
      requestBody: requestBody,
      responseHeaders: responseHeaders ?? this.responseHeaders,
      responseBody: responseBody ?? this.responseBody,
      responseSizeBytes: responseSizeBytes ?? this.responseSizeBytes,
      statusCode: statusCode ?? this.statusCode,
      completedAt: completedAt ?? this.completedAt,
      durationMs: durationMs ?? this.durationMs,
      createdAt: createdAt,
      isMock: isMock ?? this.isMock,
    );
  }

  bool get isPending => completedAt == null;

  /// Path portion of [url], falling back to the host or the raw string.
  String get path {
    if (url == null) return '';
    final uri = Uri.tryParse(url!);
    if (uri == null) return url!;
    return uri.path.isEmpty ? uri.host : uri.path;
  }
}
