import 'dart:convert';

String? prettyPrintJson(String input) {
  try {
    final parsed = jsonDecode(input);
    return const JsonEncoder.withIndent('  ').convert(parsed);
  } catch (_) {
    return null;
  }
}
