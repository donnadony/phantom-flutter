import 'package:flutter/material.dart';

import '../../core/models/phantom_mock_rule.dart';
import '../../core/phantom_mock_interceptor.dart';
import '../../theme/phantom_theme.dart';
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

  void _onUpdate() => setState(() {});

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
          style: TextStyle(color: theme.onBackground, fontWeight: FontWeight.bold),
        ),
        actions: [
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
            style: TextStyle(color: theme.onBackground, fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              'Tap + to add a mock rule, or use "Mock this" from a network request detail.',
              textAlign: TextAlign.center,
              style: TextStyle(color: theme.onBackgroundVariant, fontSize: 14),
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
                        _methodBadge(rule.httpMethod, theme),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            rule.urlPattern,
                            style: TextStyle(color: theme.onBackgroundVariant, fontSize: 12),
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
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                            decoration: BoxDecoration(
                              color: theme.statusBackgroundColor(activeResponse.statusCode),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              '${activeResponse.statusCode}',
                              style: TextStyle(
                                color: theme.statusColor(activeResponse.statusCode),
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            activeResponse.name,
                            style: TextStyle(color: theme.onBackgroundVariant, fontSize: 11),
                          ),
                          if (rule.responses.length > 1) ...[
                            const SizedBox(width: 6),
                            Text(
                              '(${rule.responses.length} responses)',
                              style: TextStyle(color: theme.onBackgroundVariant, fontSize: 11),
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

  void _openEditor(BuildContext context, PhantomTheme theme, PhantomMockRule? rule) {
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
            onDelete: rule != null ? () => _interceptor.deleteRule(rule.id) : null,
          ),
        ),
      ),
    );
  }
}
