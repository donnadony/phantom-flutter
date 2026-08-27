import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/models/phantom_mock_rule.dart';
import '../../theme/phantom_theme.dart';
import 'phantom_response_edit_page.dart';
import 'phantom_status_code_picker.dart';

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
  late List<PhantomMockResponse> _responses;
  String? _activeResponseId;

  bool get _isEditing => widget.existingRule != null;

  /// With 0 or 1 responses the single response is edited inline; beyond that the
  /// rule switches to the response-list UI.
  bool get _hasMultipleResponses => _responses.length > 1;

  bool get _isValid =>
      _descriptionController.text.trim().isNotEmpty &&
      _urlPatternController.text.trim().isNotEmpty;

  @override
  void initState() {
    super.initState();
    final rule = widget.existingRule;
    _descriptionController =
        TextEditingController(text: rule?.ruleDescription ?? '');
    _urlPatternController = TextEditingController(text: rule?.urlPattern ?? '');
    _responses = List<PhantomMockResponse>.from(rule?.responses ?? const []);
    _activeResponseId = rule?.activeResponseId ?? _responses.firstOrNull?.id;

    final active = rule?.activeResponse;
    _httpMethod = active?.httpMethod ?? rule?.httpMethod ?? 'ANY';
    _statusCode = active?.statusCode ?? 200;
    _responseBodyController =
        TextEditingController(text: active?.responseBody ?? '{\n  \n}');
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
          style: TextStyle(
              color: theme.onBackground,
              fontWeight: FontWeight.bold,
              fontSize: 16),
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
            _sectionLabel('URL Pattern (partial match on path)', theme),
            _textField(_urlPatternController, 'e.g. /v1/users', theme),
            const SizedBox(height: 16),
            _sectionLabel('HTTP Method', theme),
            const SizedBox(height: 8),
            _methodPicker(theme),
            const SizedBox(height: 20),
            if (_hasMultipleResponses)
              _responseList(theme)
            else
              _inlineResponseEditor(theme),
            const SizedBox(height: 12),
            _addResponseButton(theme),
            if (_isEditing) ...[
              const SizedBox(height: 24),
              _deleteButton(theme),
            ],
          ],
        ),
      ),
    );
  }

  // MARK: - Inline (single response) editor

  Widget _inlineResponseEditor(PhantomTheme theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionLabel('Status Code', theme),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: () => _pickStatusCode(theme),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: theme.surface,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                Text(
                  '$_statusCode - ${phantomStatusCodeLabel(_statusCode)}',
                  style: TextStyle(
                      color: theme.statusColor(_statusCode), fontSize: 14),
                ),
                const Spacer(),
                Icon(Icons.expand_more,
                    color: theme.onBackgroundVariant, size: 20),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        _sectionLabel('Response Body (JSON)', theme),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            GestureDetector(
              onTap: _pasteBody,
              child: Text('Paste',
                  style: TextStyle(
                      color: theme.info,
                      fontSize: 12,
                      fontWeight: FontWeight.bold)),
            ),
            const SizedBox(width: 16),
            GestureDetector(
              onTap: _formatBody,
              child: Text('Format',
                  style: TextStyle(
                      color: theme.info,
                      fontSize: 12,
                      fontWeight: FontWeight.bold)),
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

  // MARK: - Multi-response list

  Widget _responseList(PhantomTheme theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _sectionLabel('Responses (${_responses.length})', theme),
            const SizedBox(width: 8),
            Text(
              'tap to edit · radio selects the active one',
              style:
                  TextStyle(color: theme.onBackgroundVariant, fontSize: 11),
            ),
          ],
        ),
        const SizedBox(height: 8),
        for (var i = 0; i < _responses.length; i++) ...[
          _responseRow(_responses[i], i, theme),
          const SizedBox(height: 8),
        ],
      ],
    );
  }

  Widget _responseRow(PhantomMockResponse response, int index, PhantomTheme theme) {
    final isActive = _isActiveResponse(response);

    return Dismissible(
      key: Key('response_${response.id}'),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: theme.error,
          borderRadius: BorderRadius.circular(10),
        ),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      onDismissed: (_) => _deleteResponse(response),
      child: GestureDetector(
        onTap: () => _editResponse(response, theme),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: theme.surface,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isActive ? theme.primary : theme.outlineVariant,
              width: isActive ? 1.5 : 1,
            ),
          ),
          child: Row(
            children: [
              GestureDetector(
                onTap: () =>
                    setState(() => _activeResponseId = response.id),
                child: Icon(
                  isActive
                      ? Icons.radio_button_checked
                      : Icons.radio_button_unchecked,
                  color: isActive ? theme.primary : theme.onBackgroundVariant,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      response.name.isEmpty
                          ? 'Response ${index + 1}'
                          : response.name,
                      style: TextStyle(
                        color: theme.onBackground,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 1),
                          decoration: BoxDecoration(
                            color: theme
                                .methodColor(response.httpMethod)
                                .withValues(alpha: 0.18),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            response.httpMethod,
                            style: TextStyle(
                              color: theme.methodColor(response.httpMethod),
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '${response.statusCode} · ${phantomStatusCodeLabel(response.statusCode)}',
                          style: TextStyle(
                            color: theme.statusColor(response.statusCode),
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right,
                  color: theme.onBackgroundVariant, size: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _addResponseButton(PhantomTheme theme) {
    return GestureDetector(
      onTap: () => _addResponse(theme),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: theme.outlineVariant),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add, color: theme.info, size: 16),
            const SizedBox(width: 6),
            Text(
              'Add Response',
              style: TextStyle(
                  color: theme.info,
                  fontSize: 13,
                  fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  // MARK: - Shared widgets

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

  Widget _textField(
      TextEditingController controller, String hint, PhantomTheme theme) {
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
      children: phantomHttpMethods.map((method) {
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
          style: TextStyle(
              color: theme.error, fontSize: 14, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  // MARK: - Actions

  bool _isActiveResponse(PhantomMockResponse response) {
    if (_activeResponseId != null) return _activeResponseId == response.id;
    return _responses.firstOrNull?.id == response.id;
  }

  void _pickStatusCode(PhantomTheme theme) {
    showPhantomStatusCodePicker(
      context: context,
      theme: theme,
      currentCode: _statusCode,
      onSelect: (code) => setState(() => _statusCode = code),
    );
  }

  Future<void> _addResponse(PhantomTheme theme) async {
    // Fold whatever is in the inline editor into the list before growing it,
    // otherwise the first response would be lost when the UI switches modes.
    _syncInlineToResponses();

    final created = await Navigator.of(context).push<PhantomMockResponse>(
      MaterialPageRoute(
        builder: (_) => PhantomThemeProvider(
          theme: theme,
          child: PhantomResponseEditPage(
            defaultName: 'Response ${_responses.length + 1}',
            defaultMethod: _httpMethod,
          ),
        ),
      ),
    );
    if (created == null) return;

    setState(() {
      _responses.add(created);
      _activeResponseId ??= created.id;
    });
  }

  Future<void> _editResponse(
      PhantomMockResponse response, PhantomTheme theme) async {
    final updated = await Navigator.of(context).push<PhantomMockResponse>(
      MaterialPageRoute(
        builder: (_) => PhantomThemeProvider(
          theme: theme,
          child: PhantomResponseEditPage(existingResponse: response),
        ),
      ),
    );
    if (updated == null) return;

    setState(() {
      final index = _responses.indexWhere((r) => r.id == updated.id);
      if (index != -1) _responses[index] = updated;
    });
  }

  void _deleteResponse(PhantomMockResponse response) {
    setState(() {
      _responses.removeWhere((r) => r.id == response.id);
      if (_activeResponseId == response.id) {
        _activeResponseId = _responses.firstOrNull?.id;
      }
      // Dropping back to a single response returns to the inline editor, so it
      // has to show what is left rather than the deleted response.
      final remaining = _responses.firstOrNull;
      if (remaining != null && _responses.length == 1) {
        _httpMethod = remaining.httpMethod;
        _statusCode = remaining.statusCode;
        _responseBodyController.text = remaining.responseBody;
      }
    });
  }

  /// Mirrors the inline editor fields into [_responses] so both editing modes
  /// agree on the rule's content.
  void _syncInlineToResponses() {
    if (_responses.isEmpty) {
      final created = PhantomMockResponse(
        id: _newId(),
        name: 'Response 1',
        httpMethod: _httpMethod,
        statusCode: _statusCode,
        responseBody: _responseBodyController.text,
      );
      _responses.add(created);
      _activeResponseId = created.id;
    } else if (_responses.length == 1) {
      _responses[0] = _responses[0].copyWith(
        httpMethod: _httpMethod,
        statusCode: _statusCode,
        responseBody: _responseBodyController.text,
      );
      _activeResponseId = _responses[0].id;
    }
  }

  void _save() {
    _syncInlineToResponses();

    final activeId = _activeResponseId ?? _responses.firstOrNull?.id;
    final active = _responses.cast<PhantomMockResponse?>().firstWhere(
          (r) => r!.id == activeId,
          orElse: () => _responses.firstOrNull,
        );

    final rule = PhantomMockRule(
      id: widget.existingRule?.id ?? _newId(),
      isEnabled: widget.existingRule?.isEnabled ?? true,
      urlPattern: _urlPatternController.text.trim(),
      httpMethod: active?.httpMethod ?? _httpMethod,
      responses: _responses,
      activeResponseId: activeId,
      ruleDescription: _descriptionController.text.trim(),
      createdAt: widget.existingRule?.createdAt,
    );

    widget.onSave(rule);
    Navigator.of(context).pop();
  }

  Future<void> _pasteBody() async {
    final data = await Clipboard.getData('text/plain');
    if (data?.text == null) return;
    _responseBodyController.text = data!.text!;
    _formatBody();
  }

  void _formatBody() {
    try {
      final parsed = jsonDecode(_responseBodyController.text);
      _responseBodyController.text =
          const JsonEncoder.withIndent('  ').convert(parsed);
    } catch (_) {}
  }

  String _newId() =>
      '${DateTime.now().microsecondsSinceEpoch}_${_responses.length}';
}

extension _FirstOrNull<T> on List<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
