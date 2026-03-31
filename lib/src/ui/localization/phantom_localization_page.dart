import 'package:flutter/material.dart';

import '../../core/models/phantom_localization_entry.dart';
import '../../core/phantom_localizer.dart';
import '../../theme/phantom_theme.dart';

class PhantomLocalizationPage extends StatefulWidget {
  const PhantomLocalizationPage({super.key});

  @override
  State<PhantomLocalizationPage> createState() => _PhantomLocalizationPageState();
}

class _PhantomLocalizationPageState extends State<PhantomLocalizationPage> {
  final _localizer = PhantomLocalizer.instance;
  String _searchText = '';
  String? _selectedGroup;

  @override
  void initState() {
    super.initState();
    _localizer.addListener(_onUpdate);
  }

  @override
  void dispose() {
    _localizer.removeListener(_onUpdate);
    super.dispose();
  }

  void _onUpdate() => setState(() {});

  List<PhantomLocalizationEntry> get _filteredEntries {
    var list = _selectedGroup != null
        ? _localizer.entriesForGroup(_selectedGroup!)
        : _localizer.entries;
    if (_searchText.isNotEmpty) {
      final q = _searchText.toLowerCase();
      list = list.where((e) =>
          e.key.toLowerCase().contains(q) ||
          e.english.toLowerCase().contains(q) ||
          e.spanish.toLowerCase().contains(q)).toList();
    }
    return list;
  }

  @override
  Widget build(BuildContext context) {
    final theme = PhantomThemeProvider.of(context);
    final entries = _filteredEntries;
    final lang = _localizer.currentLanguage;

    return Scaffold(
      backgroundColor: theme.background,
      appBar: AppBar(
        backgroundColor: theme.background,
        foregroundColor: theme.onBackground,
        title: Text('Localization', style: TextStyle(color: theme.onBackground, fontWeight: FontWeight.bold)),
        actions: [
          PopupMenuButton<PhantomLanguage>(
            icon: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.language, color: theme.onBackground, size: 18),
                const SizedBox(width: 4),
                Text(lang.displayName, style: TextStyle(color: theme.onBackground, fontSize: 14, fontWeight: FontWeight.bold)),
              ],
            ),
            color: theme.surface,
            onSelected: (l) => _localizer.setLanguage(l),
            itemBuilder: (_) => PhantomLanguage.values.map((l) {
              return PopupMenuItem(
                value: l,
                child: Row(
                  children: [
                    Text(l.displayName, style: TextStyle(color: theme.onBackground)),
                    if (l == lang) ...[
                      const Spacer(),
                      Icon(Icons.check, color: theme.success, size: 16),
                    ],
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
      body: entries.isEmpty
          ? _buildEmpty(theme)
          : Column(
              children: [
                if (_localizer.groups.length > 1) _buildGroupFilter(theme),
                _buildSearch(theme),
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
          Icon(Icons.translate, color: theme.onBackgroundVariant, size: 48),
          const SizedBox(height: 16),
          Text('No localization entries', style: TextStyle(color: theme.onBackground, fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(
            'Use Phantom.registerLocalization() to add entries.',
            textAlign: TextAlign.center,
            style: TextStyle(color: theme.onBackgroundVariant, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildGroupFilter(PhantomTheme theme) {
    final groups = _localizer.groups;
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
          child: Text(label, style: TextStyle(
            color: selected ? theme.onPrimary : theme.onBackground,
            fontSize: 12, fontWeight: FontWeight.bold,
          )),
        ),
      ),
    );
  }

  Widget _buildSearch(PhantomTheme theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        decoration: BoxDecoration(color: theme.surface, borderRadius: BorderRadius.circular(10)),
        child: Row(
          children: [
            Icon(Icons.search, color: theme.onBackgroundVariant, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                style: TextStyle(color: theme.onBackground, fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'Search by key or value',
                  hintStyle: TextStyle(color: theme.onBackgroundVariant),
                  border: InputBorder.none, isDense: true,
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

  Widget _buildList(List<PhantomLocalizationEntry> entries, PhantomTheme theme) {
    final lang = _localizer.currentLanguage;
    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: entries.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (_, i) => _entryCard(entries[i], lang, theme),
    );
  }

  Widget _entryCard(PhantomLocalizationEntry entry, PhantomLanguage lang, PhantomTheme theme) {
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
                child: Text(entry.key, style: TextStyle(color: theme.info, fontSize: 13, fontWeight: FontWeight.w600, fontFamily: 'monospace')),
              ),
              if (_localizer.groups.length > 1)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(color: theme.surfaceVariant, borderRadius: BorderRadius.circular(4)),
                  child: Text(entry.group, style: TextStyle(color: theme.onBackgroundVariant, fontSize: 10)),
                ),
            ],
          ),
          const SizedBox(height: 6),
          Text('EN: ${entry.english}', style: TextStyle(color: theme.onBackgroundVariant, fontSize: 12)),
          const SizedBox(height: 2),
          Text('ES: ${entry.spanish}', style: TextStyle(color: theme.onBackgroundVariant, fontSize: 12)),
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(Icons.arrow_forward, color: theme.success, size: 12),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  entry.value(lang),
                  style: TextStyle(color: theme.success, fontSize: 12, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
