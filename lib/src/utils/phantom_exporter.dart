import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../core/models/phantom_log_item.dart';
import '../core/models/phantom_network_item.dart';

/// Writes debug payloads to a temp file and hands them to the platform share
/// sheet — the Flutter equivalent of phantom-ios `PhantomShareSheet`.
class PhantomExporter {
  PhantomExporter._();

  /// Serialises app logs using the same envelope as phantom-ios so exports from
  /// either toolkit can be read by the same tooling.
  static String encodeLogs(List<PhantomLogItem> logs) {
    final entries = logs.map((item) {
      return {
        'level': item.level.label,
        'message': item.message,
        'timestamp': item.createdAt.toIso8601String(),
        if (item.tag != null) 'tag': item.tag,
      };
    }).toList();

    return _encodePayload(type: 'phantom_logs', entries: entries);
  }

  static String encodeNetwork(List<PhantomNetworkItem> logs) {
    final entries = logs.map((item) {
      return {
        'method': item.methodType,
        'url': item.url ?? '',
        'request_headers': item.requestHeaders,
        'request_body': item.requestBody,
        'response_headers': item.responseHeaders,
        'response_body': item.responseBody,
        'response_size_bytes': item.responseSizeBytes,
        'created_at': item.createdAt.toIso8601String(),
        if (item.statusCode != null) 'status_code': item.statusCode,
        if (item.durationMs != null) 'duration_ms': item.durationMs,
        if (item.completedAt != null)
          'completed_at': item.completedAt!.toIso8601String(),
        if (item.isMock) 'is_mock': true,
      };
    }).toList();

    return _encodePayload(type: 'phantom_network', entries: entries);
  }

  static String _encodePayload({
    required String type,
    required List<Map<String, dynamic>> entries,
  }) {
    return const JsonEncoder.withIndent('  ').convert({
      'exported_at': DateTime.now().toIso8601String(),
      'type': type,
      'count': entries.length,
      'entries': entries,
    });
  }

  /// Writes [contents] to a temp file named [fileName] and opens the share
  /// sheet. Returns false if the platform has no share support.
  static Future<bool> share({
    required String contents,
    required String fileName,
    String? subject,
  }) async {
    try {
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/$fileName');
      await file.writeAsString(contents);
      await Share.shareXFiles([XFile(file.path)], subject: subject ?? fileName);
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Opens the system file picker and returns the contents of the chosen JSON
  /// file, or null if the user cancelled or the file could not be read.
  static Future<String?> pickJsonFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: const ['json'],
        withData: true,
      );
      final picked = result?.files.single;
      if (picked == null) return null;
      if (picked.bytes != null) return utf8.decode(picked.bytes!);
      if (picked.path != null) return await File(picked.path!).readAsString();
      return null;
    } catch (_) {
      return null;
    }
  }
}
