import 'dart:convert';

import '../core/models/phantom_network_item.dart';

/// Builds a runnable `curl` command for a captured request.
///
/// Handles both header formats Phantom stores: `Key: value` lines and a JSON
/// object (which some HTTP clients hand over verbatim).
String buildCurlCommand(PhantomNetworkItem item) {
  final parts = <String>[
    "curl -X ${item.methodType} '${_shellEscape(item.url ?? '')}'",
  ];

  for (final header in parseHeaders(item.requestHeaders)) {
    parts.add("-H '${_shellEscape(header)}'");
  }

  if (item.requestBody != 'No body' && item.requestBody.isNotEmpty) {
    parts.add("-d '${_shellEscape(item.requestBody)}'");
  }

  return parts.join(' \\\n  ');
}

/// Normalises a stored header blob into `Key: value` strings, sorted by key.
List<String> parseHeaders(String headers) {
  final trimmed = headers.trim();
  if (trimmed.isEmpty || trimmed == 'No headers') return const [];

  if (trimmed.startsWith('{')) {
    try {
      final decoded = jsonDecode(trimmed);
      if (decoded is Map<String, dynamic>) {
        final keys = decoded.keys.toList()..sort();
        return [for (final key in keys) '$key: ${decoded[key]}'];
      }
    } catch (_) {
      // Fall through to line parsing.
    }
  }

  return trimmed
      .split('\n')
      .map((line) => line.trim())
      .where((line) => line.isNotEmpty && line.contains(':'))
      .toList();
}

/// Converts a stored header blob into a JSON object string, so it can be shown
/// in the JSON tree viewer. Returns the input untouched if it can't be parsed.
String headersAsJson(String headers) {
  final trimmed = headers.trim();
  if (trimmed.startsWith('{') || trimmed.startsWith('[')) return trimmed;

  final map = <String, String>{};
  for (final header in parseHeaders(headers)) {
    final index = header.indexOf(':');
    if (index <= 0) continue;
    final key = header.substring(0, index).trim();
    final value = header.substring(index + 1).trim();
    if (key.isNotEmpty) map[key] = value;
  }
  if (map.isEmpty) return headers;

  final sorted = Map.fromEntries(
    map.entries.toList()..sort((a, b) => a.key.compareTo(b.key)),
  );
  return const JsonEncoder.withIndent('  ').convert(sorted);
}

String _shellEscape(String value) => value.replaceAll("'", "'\\''");
