import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/models/phantom_mock_rule.dart';
import '../../theme/phantom_theme.dart';
import 'phantom_status_code_picker.dart';

/// Editor for a single response inside a multi-response mock rule.
///
/// Pops with the built [PhantomMockResponse], or null if cancelled.
class PhantomResponseEditPage extends StatefulWidget {
  final PhantomMockResponse? existingResponse;
  final String defaultName;
  final String defaultMethod;

  const PhantomResponseEditPage({
    super.key,
    this.existingResponse,
    this.defaultName = 'Response',
    this.defaultMethod = 'ANY',
  });

  @override
  State<PhantomResponseEditPage> createState() =>
      _PhantomResponseEditPageState();
}

class _PhantomResponseEditPageState extends State<PhantomResponseEditPage> {
  late TextEditingController _nameController;
  late TextEditingController _bodyController;
  late String _httpMethod;
  late int _statusCode;

  bool get _isEditing => widget.existingResponse != null;

  bool get _isValid => _nameController.text.trim().isNotEmpty;

  @override
  void initState() {
    super.initState();
    final existing = widget.existingResponse;
    _nameController =
        TextEditingController(text: existing?.name ?? widget.defaultName);
    _bodyController =
        TextEditingController(text: existing?.responseBody ?? '{\n  \n}');
    _httpMethod = existing?.httpMethod ?? widget.defaultMethod;
    _statusCode = existing?.statusCode ?? 200;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _bodyController.dispose();
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
          _isEditing ? 'Edit Response' : 'New Response',
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
            _label('Name', theme),
            _textField(_nameController, 'e.g. Empty list', theme),
            const SizedBox(height: 16),
            _label('HTTP Method', theme),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: phantomHttpMethods.map((method) {
                final selected = _httpMethod == method;
                return GestureDetector(
                  onTap: () => setState(() => _httpMethod = method),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 8),
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
            ),
            const SizedBox(height: 16),
            _label('Status Code', theme),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: () => showPhantomStatusCodePicker(
                context: context,
                theme: theme,
                currentCode: _statusCode,
                onSelect: (code) => setState(() => _statusCode = code),
              ),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
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
            Row(
              children: [
                _label('Response Body (JSON)', theme),
                const Spacer(),
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
            const SizedBox(height: 8),
            Container(
              height: 240,
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.surface,
                borderRadius: BorderRadius.circular(10),
              ),
              child: TextField(
                controller: _bodyController,
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
        ),
      ),
    );
  }

  Widget _label(String text, PhantomTheme theme) {
    return Text(
      text,
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

  void _save() {
    final response = PhantomMockResponse(
      id: widget.existingResponse?.id ??
          DateTime.now().microsecondsSinceEpoch.toString(),
      name: _nameController.text.trim(),
      httpMethod: _httpMethod,
      statusCode: _statusCode,
      responseBody: _bodyController.text,
    );
    Navigator.of(context).pop(response);
  }

  Future<void> _pasteBody() async {
    final data = await Clipboard.getData('text/plain');
    if (data?.text == null) return;
    _bodyController.text = data!.text!;
    _formatBody();
  }

  void _formatBody() {
    try {
      final parsed = jsonDecode(_bodyController.text);
      _bodyController.text =
          const JsonEncoder.withIndent('  ').convert(parsed);
    } catch (_) {}
  }
}
