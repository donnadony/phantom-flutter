import 'package:flutter/material.dart';

import '../../core/models/phantom_log_item.dart';
import '../../core/phantom_logger.dart';
import '../../theme/phantom_theme.dart';

class PhantomLogsPage extends StatefulWidget {
  const PhantomLogsPage({super.key});

  @override
  State<PhantomLogsPage> createState() => _PhantomLogsPageState();
}

class _PhantomLogsPageState extends State<PhantomLogsPage> {
  final _logger = PhantomLogger.instance;
  String _searchText = '';
  String _selectedFilter = 'All';

  @override
  void initState() {
    super.initState();
    _logger.addListener(_onUpdate);
  }

  @override
  void dispose() {
    _logger.removeListener(_onUpdate);
    super.dispose();
  }

  void _onUpdate() => setState(() {});

  List<PhantomLogItem> get _filteredLogs {
    var list = _logger.logs;
    if (_selectedFilter != 'All') {
      final level = _filterLevel(_selectedFilter);
      if (level != null) {
        list = list.where((l) => l.level == level).toList();
      }
    }
    if (_searchText.isNotEmpty) {
      final query = _searchText.toLowerCase();
      list = list.where((l) {
        return l.message.toLowerCase().contains(query) ||
            (l.tag?.toLowerCase().contains(query) ?? false);
      }).toList();
    }
    return list;
  }

  PhantomLogLevel? _filterLevel(String filter) {
    switch (filter) {
      case 'Info':
        return PhantomLogLevel.info;
      case 'Warning':
        return PhantomLogLevel.warning;
      case 'Error':
        return PhantomLogLevel.error;
      default:
        return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = PhantomThemeProvider.of(context);
    final logs = _filteredLogs;

    return Scaffold(
      backgroundColor: theme.background,
      appBar: AppBar(
        backgroundColor: theme.background,
        foregroundColor: theme.onBackground,
        title: Text(
          'Logs (${_logger.logs.length})',
          style: TextStyle(color: theme.onBackground, fontWeight: FontWeight.bold),
        ),
        actions: [
          TextButton(
            onPressed: _logger.clearAll,
            child: Text('Clear', style: TextStyle(color: theme.error, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
      body: Column(
        children: [
          _buildSearch(theme),
          _buildFilters(theme),
          Expanded(child: _buildList(logs, theme)),
        ],
      ),
    );
  }

  Widget _buildSearch(PhantomTheme theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        decoration: BoxDecoration(
          color: theme.surface,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            Icon(Icons.search, color: theme.onBackgroundVariant, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                style: TextStyle(color: theme.onBackground, fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'Search logs...',
                  hintStyle: TextStyle(color: theme.onBackgroundVariant),
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(vertical: 8),
                ),
                onChanged: (v) => setState(() => _searchText = v),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilters(PhantomTheme theme) {
    const filters = ['All', 'Info', 'Warning', 'Error'];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: filters.map((f) {
          final selected = _selectedFilter == f;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () => setState(() => _selectedFilter = f),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: selected ? theme.primary : theme.surface,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  f,
                  style: TextStyle(
                    color: selected ? theme.onPrimary : theme.onBackground,
                    fontSize: 12,
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

  Widget _buildList(List<PhantomLogItem> logs, PhantomTheme theme) {
    if (logs.isEmpty) {
      return Center(
        child: Text('No logs', style: TextStyle(color: theme.onBackgroundVariant)),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      itemCount: logs.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (_, index) => _logRow(logs[index], theme),
    );
  }

  Widget _logRow(PhantomLogItem item, PhantomTheme theme) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: theme.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: theme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _levelColor(item.level, theme),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                item.level.name.toUpperCase(),
                style: TextStyle(
                  color: _levelColor(item.level, theme),
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (item.tag != null) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                  decoration: BoxDecoration(
                    color: theme.surfaceVariant,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    item.tag!,
                    style: TextStyle(color: theme.onBackgroundVariant, fontSize: 10),
                  ),
                ),
              ],
              const Spacer(),
              Text(
                _formatTime(item.createdAt),
                style: TextStyle(color: theme.onBackgroundVariant, fontSize: 11),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            item.message,
            style: TextStyle(color: theme.onBackground, fontSize: 12),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Color _levelColor(PhantomLogLevel level, PhantomTheme theme) {
    switch (level) {
      case PhantomLogLevel.info:
        return theme.info;
      case PhantomLogLevel.warning:
        return theme.warning;
      case PhantomLogLevel.error:
        return theme.error;
    }
  }

  String _formatTime(DateTime dt) {
    return '${dt.hour.toString().padLeft(2, '0')}:'
        '${dt.minute.toString().padLeft(2, '0')}:'
        '${dt.second.toString().padLeft(2, '0')}';
  }
}
