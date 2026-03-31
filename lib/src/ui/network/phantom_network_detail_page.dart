import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/models/phantom_network_item.dart';
import '../../theme/phantom_theme.dart';
import '../../utils/curl_builder.dart';
import '../../utils/json_formatter.dart';

class PhantomNetworkDetailPage extends StatefulWidget {
  final PhantomNetworkItem item;

  const PhantomNetworkDetailPage({super.key, required this.item});

  @override
  State<PhantomNetworkDetailPage> createState() =>
      _PhantomNetworkDetailPageState();
}

enum _DetailTab { request, response, headers }

class _PhantomNetworkDetailPageState extends State<PhantomNetworkDetailPage> {
  _DetailTab _selectedTab = _DetailTab.response;
  bool _showFormatted = true;
  String? _copiedMessage;

  @override
  Widget build(BuildContext context) {
    final theme = PhantomThemeProvider.of(context);
    final item = widget.item;

    return Scaffold(
      backgroundColor: theme.background,
      appBar: AppBar(
        backgroundColor: theme.background,
        foregroundColor: theme.onBackground,
        title: Text(
          item.methodType,
          style: TextStyle(
              color: theme.onBackground, fontWeight: FontWeight.bold),
        ),
      ),
      body: Column(
        children: [
          _buildUrlHeader(item, theme),
          _buildTabBar(theme),
          Expanded(child: _buildContent(item, theme)),
          _buildActions(item, theme),
        ],
      ),
    );
  }

  Widget _buildUrlHeader(PhantomNetworkItem item, PhantomTheme theme) {
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
          Text(
            item.url ?? 'No URL',
            style: TextStyle(color: theme.onBackground, fontSize: 13),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              if (item.statusCode != null) ...[
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: theme.statusBackgroundColor(item.statusCode!),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${item.statusCode}',
                    style: TextStyle(
                      color: theme.statusColor(item.statusCode!),
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
              ],
              if (item.durationMs != null)
                Text(
                  '${item.durationMs}ms',
                  style: TextStyle(
                    color: item.durationMs! > 1000
                        ? theme.error
                        : theme.onBackgroundVariant,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              const SizedBox(width: 8),
              if (item.responseSizeBytes > 0)
                Text(
                  _formatBytes(item.responseSizeBytes),
                  style: TextStyle(
                      color: theme.onBackgroundVariant, fontSize: 12),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar(PhantomTheme theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: _DetailTab.values.map((tab) {
          final selected = _selectedTab == tab;
          return Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _selectedTab = tab),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: selected ? theme.surfaceVariant : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  tab.name[0].toUpperCase() + tab.name.substring(1),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color:
                        selected ? theme.onBackground : theme.onBackgroundVariant,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildContent(PhantomNetworkItem item, PhantomTheme theme) {
    String text;
    switch (_selectedTab) {
      case _DetailTab.request:
        text = item.requestBody.isEmpty ? 'No request body' : item.requestBody;
        break;
      case _DetailTab.response:
        text =
            item.responseBody.isEmpty ? 'No response body' : item.responseBody;
        break;
      case _DetailTab.headers:
        text =
            'Request Headers:\n${item.requestHeaders}\n\nResponse Headers:\n${item.responseHeaders}';
        break;
    }

    final displayText =
        (_showFormatted && _selectedTab != _DetailTab.headers)
            ? (prettyPrintJson(text) ?? text)
            : text;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.surface,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Stack(
        children: [
          SingleChildScrollView(
            child: Text(
              displayText,
              style: TextStyle(
                color: theme.onBackground,
                fontSize: 12,
                fontFamily: 'monospace',
              ),
            ),
          ),
          Positioned(
            top: 0,
            right: 0,
            child: Row(
              children: [
                if (_selectedTab != _DetailTab.headers) ...[
                  _toggleButton(
                    label: _showFormatted ? 'Raw' : 'Format',
                    theme: theme,
                    onTap: () =>
                        setState(() => _showFormatted = !_showFormatted),
                  ),
                  const SizedBox(width: 8),
                ],
                _toggleButton(
                  label: _copiedMessage ?? 'Copy',
                  theme: theme,
                  onTap: () => _copyText(text),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _toggleButton({
    required String label,
    required PhantomTheme theme,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: theme.surfaceVariant,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: theme.info,
            fontSize: 11,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildActions(PhantomNetworkItem item, PhantomTheme theme) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () {
                final curl = buildCurlCommand(item);
                Clipboard.setData(ClipboardData(text: curl));
                _showCopied('cURL copied');
              },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: theme.success,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Copy cURL',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: theme.onPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _copyText(String text) {
    Clipboard.setData(ClipboardData(text: text));
    _showCopied('Copied');
  }

  void _showCopied(String message) {
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
