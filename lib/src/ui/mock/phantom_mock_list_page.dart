import 'package:flutter/material.dart';

import '../../core/models/phantom_mock_rule.dart';
import '../../core/phantom_mock_interceptor.dart';
import '../../theme/phantom_theme.dart';
import '../../utils/phantom_exporter.dart';
import 'phantom_mock_edit_page.dart';

class PhantomMockListPage extends StatefulWidget {
  const PhantomMockListPage({super.key});

  @override
  State<PhantomMockListPage> createState() => _PhantomMockListPageState();
}

class _PhantomMockListPageState extends State<PhantomMockListPage> {
  final _interceptor = PhantomMockInterceptor.instance;

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

  @override
  Widget build(BuildContext context) {
    final theme = PhantomThemeProvider.of(context);
    final rules = _interceptor.rules;

    return Scaffold(
      backgroundColor: theme.background,
      appBar: AppBar(
        backgroundColor: theme.background,
        foregroundColor: theme.onBackground,
        title: Text(
          'Mock Services',
          style:
              TextStyle(color: theme.onBackground, fontWeight: FontWeight.bold),
        ),
        actions: [
          PopupMenuButton<_MockMenuAction>(
            icon: Icon(Icons.more_horiz, color: theme.onBackground, size: 20),
            color: theme.surface,
            onSelected: (action) => _handleMenu(action, theme),
            itemBuilder: (_) => [
              PopupMenuItem(
                value: _MockMenuAction.import,
                child: Row(
                  children: [
                    Icon(Icons.file_download_outlined,
                        color: theme.onBackground, size: 18),
                    const SizedBox(width: 10),
                    Text('Import from file',
                        style: TextStyle(color: theme.onBackground)),
                  ],
                ),
              ),
              if (rules.isNotEmpty)
                PopupMenuItem(
                  value: _MockMenuAction.export,
                  child: Row(
                    children: [
                      Icon(Icons.file_upload_outlined,
                          color: theme.onBackground, size: 18),
                      const SizedBox(width: 10),
                      Text('Export all mocks',
                          style: TextStyle(color: theme.onBackground)),
                    ],
                  ),
                ),
              if (rules.isNotEmpty)
                PopupMenuItem(
                  value: _MockMenuAction.clear,
                  child: Row(
                    children: [
                      Icon(Icons.delete_outline, color: theme.error, size: 18),
                      const SizedBox(width: 10),
                      Text('Delete all rules',
                          style: TextStyle(color: theme.error)),
                    ],
                  ),
                ),
            ],
          ),
          IconButton(
            icon: Icon(Icons.add, color: theme.onBackground),
            onPressed: () => _openEditor(context, theme, null),
          ),
        ],
      ),
      body: rules.isEmpty ? _buildEmpty(theme) : _buildList(rules, theme),
    );
  }

  Widget _buildEmpty(PhantomTheme theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.sensors_off, color: theme.onBackgroundVariant, size: 48),
          const SizedBox(height: 16),
          Text(
            'No mock rules',
            style: TextStyle(
                color: theme.onBackground,
                fontSize: 18,
                fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              'Tap + to create a rule, import from a JSON file, or use "Mock this" from the Network view.',
              textAlign: TextAlign.center,
              style:
                  TextStyle(color: theme.onBackgroundVariant, fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildList(List<PhantomMockRule> rules, PhantomTheme theme) {
    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: rules.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (_, index) => _ruleRow(rules[index], theme),
    );
  }

  Widget _ruleRow(PhantomMockRule rule, PhantomTheme theme) {
    final activeResponse = rule.activeResponse;

    return Dismissible(
      key: Key(rule.id),
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
      onDismissed: (_) => _interceptor.deleteRule(rule.id),
      child: GestureDetector(
        onTap: () => _openEditor(context, theme, rule),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: theme.surface,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: theme.outlineVariant),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      rule.ruleDescription,
                      style: TextStyle(
                        color: theme.onBackground,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        _methodBadge(
                            activeResponse?.httpMethod ?? rule.httpMethod,
                            theme),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            rule.urlPattern,
                            style: TextStyle(
                                color: theme.onBackgroundVariant, fontSize: 12),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    if (activeResponse != null) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.play_arrow,
                              color: theme.primary, size: 12),
                          const SizedBox(width: 2),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 1),
                            decoration: BoxDecoration(
                              color: theme.statusBackgroundColor(
                                  activeResponse.statusCode),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              '${activeResponse.statusCode}',
                              style: TextStyle(
                                color:
                                    theme.statusColor(activeResponse.statusCode),
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              activeResponse.name,
                              style: TextStyle(
                                  color: theme.onBackgroundVariant,
                                  fontSize: 11),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (rule.responses.length > 1) ...[
                            const SizedBox(width: 6),
                            Text(
                              '(${rule.responses.length} responses)',
                              style: TextStyle(
                                  color: theme.onBackgroundVariant,
                                  fontSize: 11),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              Switch.adaptive(
                value: rule.isEnabled,
                activeTrackColor: theme.success,
                onChanged: (_) => _interceptor.toggleRule(rule.id),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _methodBadge(String method, PhantomTheme theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: theme.methodColor(method).withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        method,
        style: TextStyle(
          color: theme.methodColor(method),
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Future<void> _handleMenu(_MockMenuAction action, PhantomTheme theme) async {
    switch (action) {
      case _MockMenuAction.import:
        await _importMocks();
      case _MockMenuAction.export:
        await _exportMocks();
      case _MockMenuAction.clear:
        _confirmClearAll(theme);
    }
  }

  Future<void> _importMocks() async {
    final contents = await PhantomExporter.pickJsonFile();
    if (contents == null) return;

    final imported = await _interceptor.importCollection(contents);
    if (!mounted) return;

    _toast(imported == null
        ? 'Invalid mock file'
        : '$imported rule${imported == 1 ? '' : 's'} loaded');
  }

  Future<void> _exportMocks() async {
    final shared = await PhantomExporter.share(
      contents: _interceptor.exportCollection(),
      fileName: 'phantom_mocks.json',
      subject: 'Phantom mock rules',
    );
    if (!mounted || shared) return;
    _toast('Could not export mocks');
  }

  void _confirmClearAll(PhantomTheme theme) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: theme.surface,
        title: Text('Delete all rules?',
            style: TextStyle(color: theme.onBackground, fontSize: 16)),
        content: Text(
          'This removes every mock rule stored on this device.',
          style: TextStyle(color: theme.onBackgroundVariant, fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel',
                style: TextStyle(color: theme.onBackgroundVariant)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              _interceptor.clearAll();
            },
            child: Text('Delete',
                style: TextStyle(
                    color: theme.error, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _toast(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _openEditor(
      BuildContext context, PhantomTheme theme, PhantomMockRule? rule) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PhantomThemeProvider(
          theme: theme,
          child: PhantomMockEditPage(
            existingRule: rule,
            onSave: (savedRule) {
              if (rule != null) {
                _interceptor.updateRule(savedRule);
              } else {
                _interceptor.addRule(savedRule);
              }
            },
            onDelete:
                rule != null ? () => _interceptor.deleteRule(rule.id) : null,
          ),
        ),
      ),
    );
  }
}

enum _MockMenuAction { import, export, clear }
