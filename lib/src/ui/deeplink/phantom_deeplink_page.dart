import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../theme/phantom_theme.dart';

/// Opens arbitrary URL schemes / universal links against the running app and
/// keeps a persisted history of what was tried.
class PhantomDeepLinkPage extends StatefulWidget {
  const PhantomDeepLinkPage({super.key});

  @override
  State<PhantomDeepLinkPage> createState() => _PhantomDeepLinkPageState();
}

class _PhantomDeepLinkPageState extends State<PhantomDeepLinkPage> {
  static const _historyKey = 'phantom_deeplink_history';
  static const _maxHistory = 50;

  final _controller = TextEditingController();
  List<_HistoryItem> _history = [];
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _loadHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_historyKey);
    if (raw == null) return;
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      if (!mounted) return;
      setState(() {
        _history = list
            .map((e) => _HistoryItem.fromJson(e as Map<String, dynamic>))
            .toList();
      });
    } catch (_) {}
  }

  Future<void> _saveHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _historyKey,
      jsonEncode(_history.map((e) => e.toJson()).toList()),
    );
  }

  Future<void> _openLink() async {
    final trimmed = _controller.text.trim();
    if (trimmed.isEmpty) {
      setState(() => _errorMessage = 'Enter a URL or scheme');
      return;
    }

    final uri = Uri.tryParse(trimmed);
    if (uri == null || uri.scheme.isEmpty) {
      setState(() => _errorMessage = 'Invalid URL format');
      await _addHistory(trimmed, success: false);
      return;
    }

    setState(() => _errorMessage = null);

    var success = false;
    try {
      success = await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      success = false;
    }

    if (!mounted) return;
    if (!success) {
      setState(() => _errorMessage = 'No app handled this URL');
    }
    await _addHistory(trimmed, success: success);
  }

  Future<void> _addHistory(String url, {required bool success}) async {
    setState(() {
      _history.insert(
        0,
        _HistoryItem(url: url, timestamp: DateTime.now(), success: success),
      );
      if (_history.length > _maxHistory) {
        _history = _history.sublist(0, _maxHistory);
      }
    });
    await _saveHistory();
  }

  Future<void> _clearHistory() async {
    setState(() => _history = []);
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_historyKey);
  }

  @override
  Widget build(BuildContext context) {
    final theme = PhantomThemeProvider.of(context);

    return Scaffold(
      backgroundColor: theme.background,
      appBar: AppBar(
        backgroundColor: theme.background,
        foregroundColor: theme.onBackground,
        title: Text(
          'Deep Link Tester',
          style:
              TextStyle(color: theme.onBackground, fontWeight: FontWeight.bold),
        ),
        actions: [
          if (_history.isNotEmpty)
            TextButton(
              onPressed: _clearHistory,
              child: Text(
                'Clear',
                style: TextStyle(
                    color: theme.error,
                    fontWeight: FontWeight.w600,
                    fontSize: 14),
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          _buildInput(theme),
          if (_errorMessage != null) _buildError(theme),
          Expanded(
            child: _history.isEmpty
                ? _buildEmpty(theme)
                : _buildHistory(theme),
          ),
        ],
      ),
    );
  }

  Widget _buildInput(PhantomTheme theme) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: theme.surface,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                Icon(Icons.link, color: theme.onBackgroundVariant, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _controller,
                    keyboardType: TextInputType.url,
                    autocorrect: false,
                    textCapitalization: TextCapitalization.none,
                    style:
                        TextStyle(color: theme.onBackground, fontSize: 14),
                    decoration: InputDecoration(
                      hintText: 'myapp://path or https://...',
                      hintStyle: TextStyle(color: theme.onBackgroundVariant),
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                    onChanged: (_) => setState(() {}),
                    onSubmitted: (_) => _openLink(),
                  ),
                ),
                if (_controller.text.isNotEmpty)
                  GestureDetector(
                    onTap: () => setState(_controller.clear),
                    child: Icon(Icons.cancel,
                        color: theme.onBackgroundVariant, size: 18),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          GestureDetector(
            onTap: _openLink,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: theme.primary,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.open_in_new, color: theme.onPrimary, size: 16),
                  const SizedBox(width: 6),
                  Text(
                    'Open Link',
                    style: TextStyle(
                      color: theme.onPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildError(PhantomTheme theme) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Row(
        children: [
          Icon(Icons.warning_amber_rounded, color: theme.error, size: 14),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              _errorMessage!,
              style: TextStyle(
                  color: theme.error,
                  fontSize: 12,
                  fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmpty(PhantomTheme theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.link_off, color: theme.onBackgroundVariant, size: 40),
          const SizedBox(height: 12),
          Text('No history yet',
              style:
                  TextStyle(color: theme.onBackgroundVariant, fontSize: 14)),
          const SizedBox(height: 4),
          Text(
            'Enter a URL scheme or universal link above',
            style: TextStyle(color: theme.onBackgroundVariant, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildHistory(PhantomTheme theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
          child: Text(
            'History',
            style: TextStyle(
              color: theme.onBackgroundVariant,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            itemCount: _history.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (_, index) => _historyRow(_history[index], theme),
          ),
        ),
      ],
    );
  }

  Widget _historyRow(_HistoryItem item, PhantomTheme theme) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => setState(() {
        _controller.text = item.url;
        _errorMessage = null;
      }),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: theme.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: theme.outlineVariant),
        ),
        child: Row(
          children: [
            Icon(
              item.success ? Icons.check_circle : Icons.cancel,
              color: item.success ? theme.success : theme.error,
              size: 16,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.url,
                    style:
                        TextStyle(color: theme.onBackground, fontSize: 13),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    item.timeText,
                    style: TextStyle(
                        color: theme.onBackgroundVariant, fontSize: 11),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HistoryItem {
  final String url;
  final DateTime timestamp;
  final bool success;

  const _HistoryItem({
    required this.url,
    required this.timestamp,
    required this.success,
  });

  String get timeText {
    final hh = timestamp.hour.toString().padLeft(2, '0');
    final mm = timestamp.minute.toString().padLeft(2, '0');
    final ss = timestamp.second.toString().padLeft(2, '0');
    return '$hh:$mm:$ss';
  }

  Map<String, dynamic> toJson() => {
        'url': url,
        'timestamp': timestamp.millisecondsSinceEpoch,
        'success': success,
      };

  factory _HistoryItem.fromJson(Map<String, dynamic> json) {
    return _HistoryItem(
      url: json['url'] as String,
      timestamp:
          DateTime.fromMillisecondsSinceEpoch(json['timestamp'] as int),
      success: json['success'] as bool? ?? false,
    );
  }
}
