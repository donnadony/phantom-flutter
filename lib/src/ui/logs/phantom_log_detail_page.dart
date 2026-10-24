import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/models/phantom_log_item.dart';
import '../../theme/phantom_theme.dart';
import '../network/phantom_json_tree_view.dart';

/// A log's message and its [PhantomLogItem.details] in full: a payload that
/// is valid JSON as a tree, with keys sorted, anything else as plain text.
class PhantomLogDetailPage extends StatefulWidget {
  final PhantomLogItem item;

  const PhantomLogDetailPage({super.key, required this.item});

  @override
  State<PhantomLogDetailPage> createState() => _PhantomLogDetailPageState();
}

class _PhantomLogDetailPageState extends State<PhantomLogDetailPage> {
  bool _copied = false;
  Timer? _copiedReset;

  @override
  void dispose() {
    _copiedReset?.cancel();
    super.dispose();
  }

  PhantomLogItem get _item => widget.item;

  @override
  Widget build(BuildContext context) {
    final theme = PhantomThemeProvider.of(context);

    return Scaffold(
      backgroundColor: theme.background,
      appBar: AppBar(
        backgroundColor: theme.background,
        foregroundColor: theme.onBackground,
        title: Text(
          _item.tag ?? _item.level.label,
          style: TextStyle(
            color: theme.onBackground,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.sizeOf(context).height * 0.25,
              ),
              child: SingleChildScrollView(child: _buildHeader(theme)),
            ),
            const SizedBox(height: 12),
            Expanded(child: _buildDetails(theme)),
            const SizedBox(height: 12),
            _buildCopyButton(theme),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(PhantomTheme theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(_item.level.emoji, style: const TextStyle(fontSize: 11)),
            const SizedBox(width: 6),
            Text(
              _item.level.label,
              style: TextStyle(
                color: theme.onBackgroundVariant,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Spacer(),
            Text(
              _formatTimestamp(_item.createdAt),
              style: TextStyle(color: theme.onBackgroundVariant, fontSize: 11),
            ),
          ],
        ),
        const SizedBox(height: 6),
        SelectableText(
          _item.message,
          style: TextStyle(
            color: theme.onBackground,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildDetails(PhantomTheme theme) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: theme.outlineVariant),
      ),
      child: PhantomJsonTreeView(
        jsonString: _item.details ?? '',
        truncateLeaves: false,
      ),
    );
  }

  Widget _buildCopyButton(PhantomTheme theme) {
    return GestureDetector(
      onTap: _copy,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: theme.surfaceVariant,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _copied ? Icons.check : Icons.copy_rounded,
              color: theme.primary,
              size: 16,
            ),
            const SizedBox(width: 6),
            Text(
              _copied ? 'Copied' : 'Copy details',
              style: TextStyle(
                color: theme.primary,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _copy() {
    Clipboard.setData(ClipboardData(text: _item.details ?? ''));
    setState(() => _copied = true);
    _copiedReset?.cancel();
    _copiedReset = Timer(const Duration(seconds: 2), () {
      if (mounted) setState(() => _copied = false);
    });
  }

  String _formatTimestamp(DateTime dt) {
    String two(int n) => n.toString().padLeft(2, '0');
    final millis = dt.millisecond.toString().padLeft(3, '0');
    return '${two(dt.hour)}:${two(dt.minute)}:${two(dt.second)}.$millis';
  }
}
