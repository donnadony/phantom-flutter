import 'package:flutter/material.dart';

import '../../theme/phantom_theme.dart';

/// HTTP status codes offered when building a mock, grouped by class.
const phantomStatusCodeGroups = <String, Map<int, String>>{
  '1xx - Informational': {
    100: 'Continue',
    101: 'Switching Protocols',
    102: 'Processing',
    103: 'Early Hints',
  },
  '2xx - Successful': {
    200: 'OK',
    201: 'Created',
    202: 'Accepted',
    204: 'No Content',
    206: 'Partial Content',
    207: 'Multi-Status',
  },
  '3xx - Redirection': {
    301: 'Moved Permanently',
    302: 'Found',
    304: 'Not Modified',
    307: 'Temporary Redirect',
    308: 'Permanent Redirect',
  },
  '4xx - Client Error': {
    400: 'Bad Request',
    401: 'Unauthorized',
    403: 'Forbidden',
    404: 'Not Found',
    405: 'Method Not Allowed',
    408: 'Request Timeout',
    409: 'Conflict',
    422: 'Unprocessable Entity',
    429: 'Too Many Requests',
  },
  '5xx - Server Error': {
    500: 'Internal Server Error',
    501: 'Not Implemented',
    502: 'Bad Gateway',
    503: 'Service Unavailable',
    504: 'Gateway Timeout',
  },
};

const _commonStatusCodes = <int, String>{
  200: 'OK',
  201: 'Created',
  204: 'No Content',
  400: 'Bad Request',
  401: 'Unauthorized',
  403: 'Forbidden',
  404: 'Not Found',
  500: 'Internal Server Error',
};

String phantomStatusCodeLabel(int code) {
  for (final group in phantomStatusCodeGroups.values) {
    final label = group[code];
    if (label != null) return label;
  }
  return '';
}

void showPhantomStatusCodePicker({
  required BuildContext context,
  required PhantomTheme theme,
  required int currentCode,
  required void Function(int) onSelect,
}) {
  showModalBottomSheet<void>(
    context: context,
    backgroundColor: theme.background,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (_) => _StatusCodePicker(
      currentCode: currentCode,
      theme: theme,
      onSelect: onSelect,
    ),
  );
}

class _StatusCodePicker extends StatefulWidget {
  final int currentCode;
  final PhantomTheme theme;
  final void Function(int) onSelect;

  const _StatusCodePicker({
    required this.currentCode,
    required this.theme,
    required this.onSelect,
  });

  @override
  State<_StatusCodePicker> createState() => _StatusCodePickerState();
}

class _StatusCodePickerState extends State<_StatusCodePicker> {
  String _search = '';

  bool _matches(int code, String label) {
    if (_search.isEmpty) return true;
    final q = _search.toLowerCase();
    return code.toString().contains(q) || label.toLowerCase().contains(q);
  }

  @override
  Widget build(BuildContext context) {
    final theme = widget.theme;

    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.7,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text(
              'Status Code',
              style: TextStyle(
                color: theme.onBackground,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: theme.surface,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.search,
                    color: theme.onBackgroundVariant,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      style: TextStyle(color: theme.onBackground, fontSize: 14),
                      decoration: InputDecoration(
                        hintText: 'Search by code or name',
                        hintStyle: TextStyle(color: theme.onBackgroundVariant),
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(vertical: 8),
                      ),
                      onChanged: (v) => setState(() => _search = v),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: ListView(
              children: [
                if (_search.isEmpty) ...[
                  _sectionHeader('Common', theme),
                  ..._commonStatusCodes.entries.map(
                    (e) => _codeRow(e.key, e.value, theme),
                  ),
                  const SizedBox(height: 8),
                ],
                ...phantomStatusCodeGroups.entries.expand((group) {
                  final filtered = group.value.entries
                      .where((e) => _matches(e.key, e.value))
                      .toList();
                  if (filtered.isEmpty) return <Widget>[];
                  return [
                    if (_search.isEmpty) _sectionHeader(group.key, theme),
                    ...filtered.map((e) => _codeRow(e.key, e.value, theme)),
                  ];
                }),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionHeader(String title, PhantomTheme theme) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Text(
        title,
        style: TextStyle(
          color: theme.onBackgroundVariant,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _codeRow(int code, String label, PhantomTheme theme) {
    final selected = widget.currentCode == code;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        widget.onSelect(code);
        Navigator.of(context).pop();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        color: selected ? theme.surfaceVariant : Colors.transparent,
        child: Row(
          children: [
            Text(
              '$code - $label',
              style: TextStyle(
                color: theme.statusColor(code),
                fontSize: 14,
                fontWeight: selected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
            if (selected) ...[
              const Spacer(),
              Icon(Icons.check, color: theme.success, size: 18),
            ],
          ],
        ),
      ),
    );
  }
}
