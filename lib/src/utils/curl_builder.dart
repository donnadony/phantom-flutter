import '../core/models/phantom_network_item.dart';

String buildCurlCommand(PhantomNetworkItem item) {
  final buffer = StringBuffer('curl');

  if (item.methodType != 'GET') {
    buffer.write(' -X ${item.methodType}');
  }

  if (item.url != null) {
    buffer.write(" '${item.url}'");
  }

  if (item.requestHeaders != 'No headers') {
    for (final line in item.requestHeaders.split('\n')) {
      final trimmed = line.trim();
      if (trimmed.isNotEmpty) {
        buffer.write(" \\\n  -H '$trimmed'");
      }
    }
  }

  if (item.requestBody != 'No body' && item.requestBody.isNotEmpty) {
    final escaped = item.requestBody.replaceAll("'", "'\\''");
    buffer.write(" \\\n  -d '$escaped'");
  }

  return buffer.toString();
}
