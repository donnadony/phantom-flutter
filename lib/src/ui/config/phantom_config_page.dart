import 'package:flutter/material.dart';

import '../../core/models/phantom_config_entry.dart';
import '../../core/phantom_config.dart';
import '../../theme/phantom_theme.dart';

class PhantomConfigPage extends StatefulWidget {
  const PhantomConfigPage({super.key});

  @override
  State<PhantomConfigPage> createState() => _PhantomConfigPageState();
}

class _PhantomConfigPageState extends State<PhantomConfigPage> {
  final _config = PhantomConfig.instance;
  String? _selectedGroup;

  @override
  void initState() {
    super.initState();
    _config.addListener(_onUpdate);
  }

  @override
  void dispose() {
    _config.removeListener(_onUpdate);
    super.dispose();
  }

  void _onUpdate() => setState(() {});

  List<PhantomConfigEntry> get _filteredEntries {
    if (_selectedGroup == null) return _config.entries;
    return _config.entriesForGroup(_selectedGroup!);
  }

  @override
  Widget build(BuildContext context) {
    final theme = PhantomThemeProvider.of(context);
    final entries = _filteredEntries;

    return Scaffold(
      backgroundColor: theme.background,
      appBar: AppBar(
        backgroundColor: theme.background,
        foregroundColor: theme.onBackground,
        title: Text(
          'Configuration',
          style: TextStyle(color: theme.onBackground, fontWeight: FontWeight.bold),
        ),
        actions: [
          TextButton(
            onPressed: () => _config.resetAll(),
            child: Text('Reset All', style: TextStyle(color: theme.error, fontWeight: FontWeight.w600, fontSize: 14)),
          ),
        ],
      ),
      body: entries.isEmpty
          ? _buildEmpty(theme)
          : Column(
              children: [
                if (_config.groups.length > 1) _buildGroupFilter(theme),
                Expanded(child: _buildList(entries, theme)),
              ],
            ),
    );
  }

  Widget _buildEmpty(PhantomTheme theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.settings_outlined, color: theme.onBackgroundVariant, size: 48),
          const SizedBox(height: 16),
          Text(
            'No configuration entries',
            style: TextStyle(color: theme.onBackground, fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Use Phantom.registerConfig() to add\nconfigurable values.',
            textAlign: TextAlign.center,
            style: TextStyle(color: theme.onBackgroundVariant, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildGroupFilter(PhantomTheme theme) {
    final groups = _config.groups;
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          _groupChip('All', _selectedGroup == null, theme, () => setState(() => _selectedGroup = null)),
          ...groups.map((g) => _groupChip(g, _selectedGroup == g, theme, () => setState(() => _selectedGroup = g))),
        ],
      ),
    );
  }

  Widget _groupChip(String label, bool selected, PhantomTheme theme, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: selected ? theme.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            border: selected ? null : Border.all(color: theme.outlineVariant),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: selected ? theme.onPrimary : theme.onBackground,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildList(List<PhantomConfigEntry> entries, PhantomTheme theme) {
    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: entries.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (_, index) => _configCard(entries[index], theme),
    );
  }

  Widget _configCard(PhantomConfigEntry entry, PhantomTheme theme) {
    return FutureBuilder<String?>(
      future: _config.value(entry.key),
      builder: (context, snapshot) {
        final overrideValue = snapshot.data;
        final isModified = overrideValue != null && overrideValue.isNotEmpty;

        return Container(
          padding: const EdgeInsets.all(12),
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
                  Expanded(
                    child: Text(
                      entry.label,
                      style: TextStyle(color: theme.onBackground, fontSize: 14, fontWeight: FontWeight.bold),
                    ),
                  ),
                  if (isModified)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: theme.warning.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        'Modified',
                        style: TextStyle(color: theme.warning, fontSize: 10, fontWeight: FontWeight.bold),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                'Default: ${entry.defaultValue}',
                style: TextStyle(color: theme.onBackgroundVariant, fontSize: 12, fontFamily: 'monospace'),
              ),
              const SizedBox(height: 8),
              _buildEditor(entry, overrideValue, theme),
              if (isModified) ...[
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: () => _config.resetValue(entry.key),
                  child: Text(
                    'Reset to Default',
                    style: TextStyle(color: theme.error, fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildEditor(PhantomConfigEntry entry, String? currentValue, PhantomTheme theme) {
    switch (entry.type) {
      case PhantomConfigType.toggle:
        final isOn = (currentValue ?? entry.defaultValue) == 'true';
        return Row(
          children: [
            Text('Enabled', style: TextStyle(color: theme.onBackgroundVariant, fontSize: 13)),
            const Spacer(),
            Switch.adaptive(
              value: isOn,
              activeTrackColor: theme.success,
              onChanged: (v) => _config.setValue(entry.key, v ? 'true' : 'false'),
            ),
          ],
        );
      case PhantomConfigType.picker:
        final selected = currentValue ?? entry.defaultValue;
        return GestureDetector(
          onTap: () {
            showModalBottomSheet(
              context: context,
              backgroundColor: theme.background,
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
              ),
              builder: (ctx) => SafeArea(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(entry.label, style: TextStyle(color: theme.onBackground, fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                    ...entry.options.map((option) {
                      final isSelected = selected == option;
                      return GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () {
                          _config.setValue(entry.key, option);
                          Navigator.pop(ctx);
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          color: isSelected ? theme.surfaceVariant : Colors.transparent,
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(option, style: TextStyle(
                                  color: theme.onBackground,
                                  fontSize: 14,
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                )),
                              ),
                              if (isSelected) Icon(Icons.check, color: theme.success, size: 18),
                            ],
                          ),
                        ),
                      );
                    }),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            );
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: theme.inputBackground,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    selected,
                    style: TextStyle(color: theme.onBackground, fontSize: 14, fontFamily: 'monospace'),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Icon(Icons.expand_more, color: theme.onBackgroundVariant, size: 20),
              ],
            ),
          ),
        );
      case PhantomConfigType.text:
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: theme.inputBackground,
            borderRadius: BorderRadius.circular(8),
          ),
          child: TextField(
            controller: TextEditingController(text: currentValue ?? ''),
            style: TextStyle(color: theme.onBackground, fontSize: 13, fontFamily: 'monospace'),
            decoration: InputDecoration(
              hintText: entry.defaultValue,
              hintStyle: TextStyle(color: theme.onBackgroundVariant),
              border: InputBorder.none,
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(vertical: 8),
            ),
            onChanged: (v) => _config.setValue(entry.key, v),
          ),
        );
    }
  }
}
