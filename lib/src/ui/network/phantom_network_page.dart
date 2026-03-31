import 'package:flutter/material.dart';

import '../../core/models/phantom_network_item.dart';
import '../../core/phantom_network_logger.dart';
import '../../theme/phantom_theme.dart';
import 'phantom_network_detail_page.dart';

class PhantomNetworkPage extends StatefulWidget {
  const PhantomNetworkPage({super.key});

  @override
  State<PhantomNetworkPage> createState() => _PhantomNetworkPageState();
}

enum _FilterType { all, errors, slow }

class _PhantomNetworkPageState extends State<PhantomNetworkPage> {
  final _networkLogger = PhantomNetworkLogger.instance;
  String _searchText = '';
  _FilterType _selectedFilter = _FilterType.all;

  @override
  void initState() {
    super.initState();
    _networkLogger.addListener(_onUpdate);
  }

  @override
  void dispose() {
    _networkLogger.removeListener(_onUpdate);
    super.dispose();
  }

  void _onUpdate() => setState(() {});

  List<PhantomNetworkItem> get _filteredLogs {
    var list = _networkLogger.logs.reversed.toList();
    switch (_selectedFilter) {
      case _FilterType.errors:
        list = list.where((i) => (i.statusCode ?? 0) >= 400).toList();
        break;
      case _FilterType.slow:
        list = list.where((i) => (i.durationMs ?? 0) > 1000).toList();
        break;
      case _FilterType.all:
        break;
    }
    if (_searchText.isNotEmpty) {
      final query = _searchText.toLowerCase();
      list = list.where((item) {
        final url = item.url?.toLowerCase() ?? '';
        final request = item.requestBody.toLowerCase();
        final response = item.responseBody.toLowerCase();
        final headers =
            '${item.requestHeaders}\n${item.responseHeaders}'.toLowerCase();
        return url.contains(query) ||
            request.contains(query) ||
            response.contains(query) ||
            headers.contains(query);
      }).toList();
    }
    return list;
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
          'Network (${_networkLogger.logs.length})',
          style: TextStyle(
              color: theme.onBackground, fontWeight: FontWeight.bold),
        ),
        actions: [
          TextButton(
            onPressed: _networkLogger.clearAll,
            child: Text('Clear',
                style: TextStyle(
                    color: theme.error, fontWeight: FontWeight.w600)),
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
                  hintText: 'Filter by endpoint, body or headers',
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
    final filters = {
      _FilterType.all: 'All',
      _FilterType.errors: 'Errors',
      _FilterType.slow: 'Slow >1s',
    };
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: filters.entries.map((entry) {
          final selected = _selectedFilter == entry.key;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () => setState(() => _selectedFilter = entry.key),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: selected ? theme.primary : theme.surface,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  entry.value,
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

  Widget _buildList(List<PhantomNetworkItem> logs, PhantomTheme theme) {
    if (logs.isEmpty) {
      return Center(
        child: Text('No requests',
            style: TextStyle(color: theme.onBackgroundVariant)),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      itemCount: logs.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (_, index) => _logRow(logs[index], theme),
    );
  }

  Widget _logRow(PhantomNetworkItem item, PhantomTheme theme) {
    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => PhantomThemeProvider(
              theme: theme,
              child: PhantomNetworkDetailPage(item: item),
            ),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: theme.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: theme.outlineVariant),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _statusDotColor(item, theme),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        item.methodType,
                        style: TextStyle(
                          color: theme.methodColor(item.methodType),
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 6),
                      _statusBadge(item, theme),
                      if (item.isMock) ...[
                        const SizedBox(width: 6),
                        _mockBadge(theme),
                      ],
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    _pathText(item),
                    style: TextStyle(
                        color: theme.onBackgroundVariant, fontSize: 12),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      Text(
                        _formatTime(item.createdAt),
                        style: TextStyle(
                            color: theme.onBackgroundVariant, fontSize: 12),
                      ),
                      if (item.durationMs != null) ...[
                        const SizedBox(width: 8),
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
                      ],
                      if (item.responseSizeBytes > 0) ...[
                        const SizedBox(width: 8),
                        Text(
                          _formatBytes(item.responseSizeBytes),
                          style: TextStyle(
                              color: theme.onBackgroundVariant, fontSize: 12),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Icon(Icons.chevron_right,
                  color: theme.onBackgroundVariant, size: 16),
            ),
          ],
        ),
      ),
    );
  }

  Widget _statusBadge(PhantomNetworkItem item, PhantomTheme theme) {
    if (item.statusCode != null) {
      final code = item.statusCode!;
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        decoration: BoxDecoration(
          color: theme.statusBackgroundColor(code),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          '$code',
          style: TextStyle(
            color: theme.statusColor(code),
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
      );
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: theme.surfaceVariant,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        item.isPending ? 'PENDING' : 'DONE',
        style: TextStyle(
          color: theme.onBackground,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _mockBadge(PhantomTheme theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: theme.warning,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        'MOCK',
        style: TextStyle(
          color: theme.onPrimary,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Color _statusDotColor(PhantomNetworkItem item, PhantomTheme theme) {
    if (item.statusCode == null) {
      return item.isPending ? theme.error : theme.onBackgroundVariant;
    }
    final code = item.statusCode!;
    return (code >= 200 && code < 300) ? theme.success : theme.error;
  }

  String _pathText(PhantomNetworkItem item) {
    if (item.url == null) return 'No URL';
    final uri = Uri.tryParse(item.url!);
    if (uri == null) return item.url!;
    return uri.path.isEmpty ? (uri.host) : uri.path;
  }

  String _formatTime(DateTime dt) {
    return '${dt.hour.toString().padLeft(2, '0')}:'
        '${dt.minute.toString().padLeft(2, '0')}:'
        '${dt.second.toString().padLeft(2, '0')}';
  }

  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(0)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}
