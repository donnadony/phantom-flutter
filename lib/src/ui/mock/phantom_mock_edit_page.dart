import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/models/phantom_mock_rule.dart';
import '../../theme/phantom_theme.dart';

class PhantomMockEditPage extends StatefulWidget {
  final PhantomMockRule? existingRule;
  final void Function(PhantomMockRule) onSave;
  final VoidCallback? onDelete;

  const PhantomMockEditPage({
    super.key,
    this.existingRule,
    required this.onSave,
    this.onDelete,
  });

  @override
  State<PhantomMockEditPage> createState() => _PhantomMockEditPageState();
}

class _PhantomMockEditPageState extends State<PhantomMockEditPage> {
  late TextEditingController _descriptionController;
  late TextEditingController _urlPatternController;
  late TextEditingController _responseBodyController;
  String _httpMethod = 'ANY';
  int _statusCode = 200;

  static const _httpMethods = ['ANY', 'GET', 'POST', 'PUT', 'DELETE'];
  static const _statusCodes = <int, String>{
    100: 'Continue', 101: 'Switching Protocols', 102: 'Processing', 103: 'Early Hints',
    200: 'OK', 201: 'Created', 202: 'Accepted', 204: 'No Content', 206: 'Partial Content', 207: 'Multi-Status',
    301: 'Moved Permanently', 302: 'Found', 304: 'Not Modified', 307: 'Temporary Redirect', 308: 'Permanent Redirect',
    400: 'Bad Request', 401: 'Unauthorized', 403: 'Forbidden', 404: 'Not Found', 405: 'Method Not Allowed',
    408: 'Request Timeout', 409: 'Conflict', 422: 'Unprocessable Entity', 429: 'Too Many Requests',
    500: 'Internal Server Error', 501: 'Not Implemented', 502: 'Bad Gateway', 503: 'Service Unavailable', 504: 'Gateway Timeout',
  };

  bool get _isEditing => widget.existingRule != null;

  bool get _isValid =>
      _descriptionController.text.trim().isNotEmpty &&
      _urlPatternController.text.trim().isNotEmpty;

  @override
  void initState() {
    super.initState();
    final rule = widget.existingRule;
    _descriptionController = TextEditingController(text: rule?.ruleDescription ?? '');
    _urlPatternController = TextEditingController(text: rule?.urlPattern ?? '');
    final activeResponse = rule?.activeResponse;
    _httpMethod = activeResponse?.httpMethod ?? rule?.httpMethod ?? 'ANY';
    _statusCode = activeResponse?.statusCode ?? 200;
    _responseBodyController = TextEditingController(
      text: activeResponse?.responseBody ?? '{\n  \n}',
    );
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _urlPatternController.dispose();
    _responseBodyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = PhantomThemeProvider.of(context);

    return Scaffold(
      backgroundColor: theme.background,
      appBar: AppBar(
        backgroundColor: theme.background,
        foregroundColor: theme.onBackground,
        leading: IconButton(
          icon: Icon(Icons.close, color: theme.onBackgroundVariant),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          _isEditing ? 'Edit Mock Rule' : 'New Mock Rule',
          style: TextStyle(color: theme.onBackground, fontWeight: FontWeight.bold, fontSize: 16),
        ),
        actions: [
          TextButton(
            onPressed: _isValid ? _save : null,
            child: Text(
              'Save',
              style: TextStyle(
                color: _isValid ? theme.info : theme.onBackgroundVariant,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sectionLabel('Description', theme),
            _textField(_descriptionController, 'e.g. Empty response', theme),
            const SizedBox(height: 16),
            _sectionLabel('URL Pattern (partial match)', theme),
            _textField(_urlPatternController, 'e.g. /v1/users', theme),
            const SizedBox(height: 16),
            _sectionLabel('HTTP Method', theme),
            const SizedBox(height: 8),
            _methodPicker(theme),
            const SizedBox(height: 16),
            _sectionLabel('Status Code', theme),
            const SizedBox(height: 8),
            _statusCodePicker(theme),
            const SizedBox(height: 16),
            _sectionLabel('Response Body (JSON)', theme),
            const SizedBox(height: 8),
            _responseBodyEditor(theme),
            if (_isEditing) ...[
              const SizedBox(height: 24),
              _deleteButton(theme),
            ],
          ],
        ),
      ),
    );
  }

  Widget _sectionLabel(String label, PhantomTheme theme) {
    return Text(
      label,
      style: TextStyle(
        color: theme.onBackground,
        fontSize: 13,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _textField(TextEditingController controller, String hint, PhantomTheme theme) {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: theme.surface,
        borderRadius: BorderRadius.circular(10),
      ),
      child: TextField(
        controller: controller,
        style: TextStyle(color: theme.onBackground, fontSize: 14),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: theme.onBackgroundVariant),
          border: InputBorder.none,
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(vertical: 10),
        ),
        onChanged: (_) => setState(() {}),
      ),
    );
  }

  Widget _methodPicker(PhantomTheme theme) {
    return Wrap(
      spacing: 8,
      children: _httpMethods.map((method) {
        final selected = _httpMethod == method;
        return GestureDetector(
          onTap: () => setState(() => _httpMethod = method),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: selected ? theme.primary : theme.surface,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              method,
              style: TextStyle(
                color: selected ? theme.onPrimary : theme.onBackground,
                fontSize: 13,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _statusCodePicker(PhantomTheme theme) {
    return GestureDetector(
      onTap: () => _showStatusCodeSheet(theme),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: theme.surface,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            Text(
              '$_statusCode - ${_statusCodes[_statusCode] ?? ''}',
              style: TextStyle(color: theme.statusColor(_statusCode), fontSize: 14),
            ),
            const Spacer(),
            Icon(Icons.expand_more, color: theme.onBackgroundVariant, size: 20),
          ],
        ),
      ),
    );
  }

  void _showStatusCodeSheet(PhantomTheme theme) {
    showModalBottomSheet(
      context: context,
      backgroundColor: theme.background,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => _StatusCodePicker(
        currentCode: _statusCode,
        theme: theme,
        onSelect: (code) {
          setState(() => _statusCode = code);
          Navigator.of(context).pop();
        },
      ),
    );
  }

  Widget _responseBodyEditor(PhantomTheme theme) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            GestureDetector(
              onTap: _pasteBody,
              child: Text('Paste', style: TextStyle(color: theme.info, fontSize: 12, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(width: 16),
            GestureDetector(
              onTap: _formatBody,
              child: Text('Format', style: TextStyle(color: theme.info, fontSize: 12, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Container(
          height: 200,
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: theme.surface,
            borderRadius: BorderRadius.circular(10),
          ),
          child: TextField(
            controller: _responseBodyController,
            maxLines: null,
            expands: true,
            style: TextStyle(
              color: theme.onBackground,
              fontSize: 12,
              fontFamily: 'monospace',
            ),
            decoration: const InputDecoration(
              border: InputBorder.none,
              isDense: true,
              contentPadding: EdgeInsets.zero,
            ),
          ),
        ),
      ],
    );
  }

  Widget _deleteButton(PhantomTheme theme) {
    return GestureDetector(
      onTap: () {
        widget.onDelete?.call();
        Navigator.of(context).pop();
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: theme.error),
        ),
        child: Text(
          'Delete Rule',
          textAlign: TextAlign.center,
          style: TextStyle(color: theme.error, fontSize: 14, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  void _save() {
    final responseId = widget.existingRule?.activeResponse?.id ?? DateTime.now().millisecondsSinceEpoch.toString();
    final response = PhantomMockResponse(
      id: responseId,
      name: 'Response 1',
      httpMethod: _httpMethod,
      statusCode: _statusCode,
      responseBody: _responseBodyController.text,
    );
    final rule = PhantomMockRule(
      id: widget.existingRule?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
      isEnabled: widget.existingRule?.isEnabled ?? true,
      urlPattern: _urlPatternController.text.trim(),
      httpMethod: _httpMethod,
      responses: [response],
      activeResponseId: responseId,
      ruleDescription: _descriptionController.text.trim(),
      createdAt: widget.existingRule?.createdAt,
    );
    widget.onSave(rule);
    Navigator.of(context).pop();
  }

  void _pasteBody() async {
    final data = await Clipboard.getData('text/plain');
    if (data?.text != null) {
      _responseBodyController.text = data!.text!;
      _formatBody();
    }
  }

  void _formatBody() {
    try {
      final parsed = jsonDecode(_responseBodyController.text);
      _responseBodyController.text = const JsonEncoder.withIndent('  ').convert(parsed);
    } catch (_) {}
  }
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

  static const _common = <int, String>{
    200: 'OK', 201: 'Created', 204: 'No Content',
    400: 'Bad Request', 401: 'Unauthorized', 403: 'Forbidden',
    404: 'Not Found', 500: 'Internal Server Error',
  };

  static const _grouped = <String, Map<int, String>>{
    '1xx - Informational': {100: 'Continue', 101: 'Switching Protocols', 102: 'Processing', 103: 'Early Hints'},
    '2xx - Successful': {200: 'OK', 201: 'Created', 202: 'Accepted', 204: 'No Content', 206: 'Partial Content', 207: 'Multi-Status'},
    '3xx - Redirection': {301: 'Moved Permanently', 302: 'Found', 304: 'Not Modified', 307: 'Temporary Redirect', 308: 'Permanent Redirect'},
    '4xx - Client Error': {400: 'Bad Request', 401: 'Unauthorized', 403: 'Forbidden', 404: 'Not Found', 405: 'Method Not Allowed', 408: 'Request Timeout', 409: 'Conflict', 422: 'Unprocessable Entity', 429: 'Too Many Requests'},
    '5xx - Server Error': {500: 'Internal Server Error', 501: 'Not Implemented', 502: 'Bad Gateway', 503: 'Service Unavailable', 504: 'Gateway Timeout'},
  };

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
            child: Text('Status Code', style: TextStyle(color: theme.onBackground, fontSize: 16, fontWeight: FontWeight.bold)),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(color: theme.surface, borderRadius: BorderRadius.circular(10)),
              child: Row(
                children: [
                  Icon(Icons.search, color: theme.onBackgroundVariant, size: 18),
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
                  ..._common.entries.where((e) => _matches(e.key, e.value)).map((e) => _codeRow(e.key, e.value, theme)),
                  const SizedBox(height: 8),
                ],
                ..._grouped.entries.expand((group) {
                  final filtered = group.value.entries.where((e) => _matches(e.key, e.value)).toList();
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
      child: Text(title, style: TextStyle(color: theme.onBackgroundVariant, fontSize: 11, fontWeight: FontWeight.bold)),
    );
  }

  Widget _codeRow(int code, String label, PhantomTheme theme) {
    final selected = widget.currentCode == code;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => widget.onSelect(code),
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
