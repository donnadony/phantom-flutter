import 'dart:convert';

import 'package:flutter/material.dart';

import '../../theme/phantom_theme.dart';

class PhantomJsonTreeView extends StatelessWidget {
  final String jsonString;

  const PhantomJsonTreeView({super.key, required this.jsonString});

  @override
  Widget build(BuildContext context) {
    final theme = PhantomThemeProvider.of(context);
    try {
      final parsed = jsonDecode(jsonString);
      return SingleChildScrollView(
        child: _buildRootContent(parsed, theme),
      );
    } catch (_) {
      return SingleChildScrollView(
        child: Text(
          jsonString,
          style: TextStyle(
            color: theme.onBackground,
            fontSize: 12,
            fontFamily: 'monospace',
          ),
        ),
      );
    }
  }

  Widget _buildRootContent(dynamic parsed, PhantomTheme theme) {
    if (parsed is Map) {
      final entries = parsed.entries.toList()
        ..sort((a, b) => a.key.toString().compareTo(b.key.toString()));
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: entries.map((e) {
          return _JsonNodeView(keyName: e.key.toString(), value: e.value, theme: theme);
        }).toList(),
      );
    }
    if (parsed is List) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: parsed.asMap().entries.map((e) {
          return _JsonNodeView(keyName: '[${e.key}]', value: e.value, theme: theme);
        }).toList(),
      );
    }
    return Text(
      parsed.toString(),
      style: TextStyle(color: theme.onBackground, fontSize: 12, fontFamily: 'monospace'),
    );
  }
}

class _JsonNodeView extends StatefulWidget {
  final String keyName;
  final dynamic value;
  final PhantomTheme theme;

  const _JsonNodeView({
    required this.keyName,
    required this.value,
    required this.theme,
  });

  @override
  State<_JsonNodeView> createState() => _JsonNodeViewState();
}

class _JsonNodeViewState extends State<_JsonNodeView> {
  bool _expanded = true;

  @override
  Widget build(BuildContext context) {
    final value = widget.value;
    if (value is Map) return _buildMap(value.cast<String, dynamic>());
    if (value is List) return _buildArray(value);
    return _buildLeaf();
  }

  Widget _buildMap(Map<String, dynamic> map) {
    final theme = widget.theme;
    final entries = map.entries.toList()..sort((a, b) => a.key.compareTo(b.key));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: () => setState(() => _expanded = !_expanded),
          behavior: HitTestBehavior.opaque,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 1),
            child: Row(
              children: [
                Text(
                  _expanded ? '⊟ ' : '⊞ ',
                  style: TextStyle(color: theme.onBackgroundVariant, fontSize: 14, fontFamily: 'monospace'),
                ),
                Text(
                  '{} ',
                  style: TextStyle(color: theme.onBackgroundVariant, fontSize: 11, fontWeight: FontWeight.bold, fontFamily: 'monospace'),
                ),
                Text(
                  widget.keyName,
                  style: TextStyle(color: theme.onBackground, fontSize: 12, fontWeight: FontWeight.w600, fontFamily: 'monospace'),
                ),
                if (!_expanded)
                  Text(
                    ' (${entries.length})',
                    style: TextStyle(color: theme.onBackgroundVariant, fontSize: 11, fontFamily: 'monospace'),
                  ),
              ],
            ),
          ),
        ),
        if (_expanded)
          Padding(
            padding: const EdgeInsets.only(left: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: entries.map((e) {
                return _JsonNodeView(keyName: e.key, value: e.value, theme: theme);
              }).toList(),
            ),
          ),
      ],
    );
  }

  Widget _buildArray(List<dynamic> arr) {
    final theme = widget.theme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: () => setState(() => _expanded = !_expanded),
          behavior: HitTestBehavior.opaque,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 1),
            child: Row(
              children: [
                Text(
                  _expanded ? '⊟ ' : '⊞ ',
                  style: TextStyle(color: theme.onBackgroundVariant, fontSize: 14, fontFamily: 'monospace'),
                ),
                Text(
                  '[] ',
                  style: TextStyle(color: theme.onBackgroundVariant, fontSize: 11, fontWeight: FontWeight.bold, fontFamily: 'monospace'),
                ),
                Text(
                  widget.keyName,
                  style: TextStyle(color: theme.onBackground, fontSize: 12, fontWeight: FontWeight.w600, fontFamily: 'monospace'),
                ),
                Text(
                  ' [${arr.length}]',
                  style: TextStyle(color: theme.onBackgroundVariant, fontSize: 11, fontFamily: 'monospace'),
                ),
              ],
            ),
          ),
        ),
        if (_expanded)
          Padding(
            padding: const EdgeInsets.only(left: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: arr.asMap().entries.map((e) {
                return _JsonNodeView(keyName: '[${e.key}]', value: e.value, theme: theme);
              }).toList(),
            ),
          ),
      ],
    );
  }

  Widget _buildLeaf() {
    final theme = widget.theme;
    final displayValue = _formatValue(widget.value);
    final color = _valueColor(widget.value, theme);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.keyName,
            style: TextStyle(color: theme.onBackground, fontSize: 12, fontWeight: FontWeight.w500, fontFamily: 'monospace'),
          ),
          Text(
            ' : ',
            style: TextStyle(color: theme.onBackgroundVariant, fontSize: 12, fontFamily: 'monospace'),
          ),
          Flexible(
            child: Text(
              displayValue,
              style: TextStyle(color: color, fontSize: 12, fontFamily: 'monospace'),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  String _formatValue(dynamic value) {
    if (value == null) return 'null';
    if (value is String) return '"$value"';
    return value.toString();
  }

  Color _valueColor(dynamic value, PhantomTheme theme) {
    if (value == null) return theme.jsonNull;
    if (value is String) return theme.jsonString;
    if (value is bool) return theme.jsonBoolean;
    if (value is num) return theme.jsonNumber;
    return theme.onBackgroundVariant;
  }
}
