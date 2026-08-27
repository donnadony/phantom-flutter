import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/models/phantom_mock_rule.dart';
import '../../core/models/phantom_network_item.dart';
import '../../core/phantom_mock_interceptor.dart';
import '../../theme/phantom_theme.dart';
import '../../utils/curl_builder.dart';
import '../../utils/json_formatter.dart';
import '../mock/phantom_mock_edit_page.dart';
import 'phantom_json_tree_view.dart';

enum _DetailTab { request, response, headers }

class PhantomNetworkDetailPage extends StatefulWidget {
  final PhantomNetworkItem item;

  const PhantomNetworkDetailPage({super.key, required this.item});

  @override
  State<PhantomNetworkDetailPage> createState() =>
      _PhantomNetworkDetailPageState();
}

class _PhantomNetworkDetailPageState extends State<PhantomNetworkDetailPage> {
  final _interceptor = PhantomMockInterceptor.instance;

  _DetailTab _selectedTab = _DetailTab.response;
  bool _showJsonTree = true;
  String? _copiedMessage;

  @override
  void initState() {
    super.initState();
    _interceptor.addListener(_onUpdate);
  }

  @override
  void dispose() {
    _interceptor.removeListener(_onUpdate);
    super.dispose();
  }

  void _onUpdate() {
    if (mounted) setState(() {});
  }

  PhantomNetworkItem get _item => widget.item;

  PhantomMockRule? get _existingRule => _item.url == null
      ? null
      : _interceptor.ruleForEndpoint(
          method: _item.methodType,
          url: _item.url!,
        );

  @override
  Widget build(BuildContext context) {
    final theme = PhantomThemeProvider.of(context);
    final status = _item.statusCode;

    return Scaffold(
      backgroundColor: theme.background,
      appBar: AppBar(
        backgroundColor: theme.background,
        foregroundColor: theme.onBackground,
        title: Text(
          '${_item.methodType}${status != null ? ' $status' : ''}',
          style:
              TextStyle(color: theme.onBackground, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            tooltip: 'Copy URL',
            icon: Icon(Icons.link, color: theme.onBackground, size: 20),
            onPressed: () => _copy(_item.url ?? '', 'URL copied'),
          ),
        ],
      ),
      body: Column(
        children: [
          _buildUrlHeader(theme),
          _buildTabBar(theme),
          Expanded(child: _buildContent(theme)),
          _buildActions(theme),
        ],
      ),
    );
  }

  Widget _buildUrlHeader(PhantomTheme theme) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.surface,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SelectableText(
            _item.url ?? 'No URL',
            style: TextStyle(color: theme.onBackground, fontSize: 13),
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              if (_item.statusCode != null)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: theme.statusBackgroundColor(_item.statusCode!),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${_item.statusCode}',
                    style: TextStyle(
                      color: theme.statusColor(_item.statusCode!),
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              if (_item.durationMs != null)
                Text(
                  '${_item.durationMs}ms',
                  style: TextStyle(
                    color: _item.durationMs! > 1000
                        ? theme.error
                        : theme.onBackgroundVariant,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              if (_item.responseSizeBytes > 0)
                Text(
                  _formatBytes(_item.responseSizeBytes),
                  style: TextStyle(
                      color: theme.onBackgroundVariant, fontSize: 12),
                ),
              if (_item.isMock)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: theme.warning,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    'MOCK',
                    style: TextStyle(
                      color: theme.onPrimary,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar(PhantomTheme theme) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: theme.inputBackground,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: _DetailTab.values.map((tab) {
          final selected = _selectedTab == tab;
          return Expanded(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => setState(() => _selectedTab = tab),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: selected ? theme.onBackground : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  tab.name[0].toUpperCase() + tab.name.substring(1),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color:
                        selected ? theme.background : theme.onBackgroundVariant,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildContent(PhantomTheme theme) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.surface,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildViewToggle(theme),
          const SizedBox(height: 8),
          Expanded(
            child: SingleChildScrollView(
              child: _showJsonTree
                  ? _buildTreeContent(theme)
                  : SelectableText(
                      _plainText,
                      style: TextStyle(
                        color: theme.onBackground,
                        fontSize: 12,
                        fontFamily: 'monospace',
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildViewToggle(PhantomTheme theme) {
    Widget option(String label, bool selected, VoidCallback onTap) {
      return GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: selected ? theme.surfaceVariant : Colors.transparent,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: selected ? theme.onBackground : theme.onBackgroundVariant,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      );
    }

    return Row(
      children: [
        Container(
          decoration: BoxDecoration(
            color: theme.inputBackground,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Row(
            children: [
              option('Viewer', _showJsonTree,
                  () => setState(() => _showJsonTree = true)),
              option('Text', !_showJsonTree,
                  () => setState(() => _showJsonTree = false)),
            ],
          ),
        ),
        const Spacer(),
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => _copy(_plainText, 'Copied'),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                _copiedMessage != null ? Icons.check : Icons.copy_rounded,
                color: theme.info,
                size: 14,
              ),
              const SizedBox(width: 4),
              Text(
                _copiedMessage ?? 'Copy',
                style: TextStyle(
                  color: theme.info,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTreeContent(PhantomTheme theme) {
    switch (_selectedTab) {
      case _DetailTab.request:
        return PhantomJsonTreeView(jsonString: _requestText);
      case _DetailTab.response:
        return PhantomJsonTreeView(jsonString: _responseText);
      case _DetailTab.headers:
        return _buildHeadersTree(theme);
    }
  }

  Widget _buildHeadersTree(PhantomTheme theme) {
    final hasRequest = _hasHeaders(_item.requestHeaders);
    final hasResponse = _hasHeaders(_item.responseHeaders);

    if (!hasRequest && !hasResponse) {
      return Text(
        'No headers',
        style: TextStyle(
          color: theme.onBackgroundVariant,
          fontSize: 12,
          fontFamily: 'monospace',
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (hasRequest) ...[
          Text(
            'Request Headers',
            style: TextStyle(
                color: theme.primary,
                fontSize: 12,
                fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          PhantomJsonTreeView(
              jsonString: headersAsJson(_item.requestHeaders)),
          const SizedBox(height: 12),
        ],
        if (hasResponse) ...[
          Text(
            'Response Headers',
            style: TextStyle(
                color: theme.primary,
                fontSize: 12,
                fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          PhantomJsonTreeView(
              jsonString: headersAsJson(_item.responseHeaders)),
        ],
      ],
    );
  }

  Widget _buildActions(PhantomTheme theme) {
    final existing = _existingRule;
    final hasRule = existing != null || _item.isMock;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Row(
        children: [
          Expanded(
            child: _actionButton(
              label: hasRule ? 'Edit Mock' : 'Mock this',
              color: hasRule ? theme.warning : theme.info,
              theme: theme,
              onTap: () => hasRule && existing != null
                  ? _editMock(existing, theme)
                  : _createMock(theme),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _actionButton(
              label: 'Copy cURL',
              color: theme.success,
              theme: theme,
              onTap: () => _copy(buildCurlCommand(_item), 'cURL copied'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _actionButton({
    required String label,
    required Color color,
    required PhantomTheme theme,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: theme.onPrimary,
            fontSize: 13,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  // MARK: - Content helpers

  String get _requestText =>
      _item.requestBody.isEmpty ? 'No request body' : _item.requestBody;

  String get _responseText =>
      _item.responseBody.isEmpty ? 'No response body' : _item.responseBody;

  String get _plainText {
    switch (_selectedTab) {
      case _DetailTab.request:
        return prettyPrintJson(_requestText) ?? _requestText;
      case _DetailTab.response:
        return prettyPrintJson(_responseText) ?? _responseText;
      case _DetailTab.headers:
        return 'Request Headers:\n${_item.requestHeaders}\n\n'
            'Response Headers:\n${_item.responseHeaders}';
    }
  }

  bool _hasHeaders(String headers) {
    final trimmed = headers.trim();
    return trimmed.isNotEmpty && trimmed != 'No headers';
  }

  // MARK: - Actions

  void _createMock(PhantomTheme theme) {
    final path = _item.path;
    final id = DateTime.now().microsecondsSinceEpoch.toString();
    final responseId = '${id}_r';
    final segments = path.split('/').where((s) => s.isNotEmpty);

    final rule = PhantomMockRule(
      id: id,
      urlPattern: path,
      httpMethod: _item.methodType,
      responses: [
        PhantomMockResponse(
          id: responseId,
          name: 'Response 1',
          httpMethod: _item.methodType,
          statusCode: _item.statusCode ?? 200,
          responseBody: _prettyBody(_item.responseBody),
        ),
      ],
      activeResponseId: responseId,
      ruleDescription:
          'Mock ${segments.isEmpty ? 'endpoint' : segments.last}',
    );

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PhantomThemeProvider(
          theme: theme,
          child: PhantomMockEditPage(
            existingRule: rule,
            onSave: PhantomMockInterceptor.instance.addRule,
          ),
        ),
      ),
    );
  }

  void _editMock(PhantomMockRule rule, PhantomTheme theme) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PhantomThemeProvider(
          theme: theme,
          child: PhantomMockEditPage(
            existingRule: rule,
            onSave: PhantomMockInterceptor.instance.updateRule,
            onDelete: () => PhantomMockInterceptor.instance.deleteRule(rule.id),
          ),
        ),
      ),
    );
  }

  String _prettyBody(String body) {
    if (body.isEmpty) return '{\n  \n}';
    return prettyPrintJson(body) ?? body;
  }

  void _copy(String text, String message) {
    Clipboard.setData(ClipboardData(text: text));
    setState(() => _copiedMessage = message);
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _copiedMessage = null);
    });
  }

  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(0)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}
