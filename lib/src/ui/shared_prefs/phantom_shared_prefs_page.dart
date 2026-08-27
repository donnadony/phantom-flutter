import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../theme/phantom_theme.dart';

class PhantomSharedPrefsPage extends StatefulWidget {
  const PhantomSharedPrefsPage({super.key});

  @override
  State<PhantomSharedPrefsPage> createState() => _PhantomSharedPrefsPageState();
}

enum _FilterType { all, app, phantom }

class _PhantomSharedPrefsPageState extends State<PhantomSharedPrefsPage> {
  Map<String, dynamic> _allEntries = {};
  String _searchText = '';
  _FilterType _selectedFilter = _FilterType.all;

  @override
  void initState() {
    super.initState();
    _loadEntries();
  }

  Future<void> _loadEntries() async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys();
    final entries = <String, dynamic>{};
    for (final key in keys) {
      entries[key] = prefs.get(key);
    }
    setState(() => _allEntries = entries);
  }

  static const _systemPrefixes = ['flutter.', 'com.apple.', 'NS', 'AK'];

  List<MapEntry<String, dynamic>> get _filteredEntries {
    var entries = _allEntries.entries.toList();
    switch (_selectedFilter) {
      case _FilterType.app:
        entries = entries
            .where(
              (e) =>
                  !_systemPrefixes.any((p) => e.key.startsWith(p)) &&
                  !e.key.startsWith('phantom_'),
            )
            .toList();
        break;
      case _FilterType.phantom:
        entries = entries.where((e) => e.key.startsWith('phantom_')).toList();
        break;
      case _FilterType.all:
        break;
    }
    if (_searchText.isNotEmpty) {
      final q = _searchText.toLowerCase();
      entries = entries
          .where(
            (e) =>
                e.key.toLowerCase().contains(q) ||
                e.value.toString().toLowerCase().contains(q),
          )
          .toList();
    }
    entries.sort((a, b) => a.key.compareTo(b.key));
    return entries;
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
          'SharedPreferences (${_allEntries.length})',
          style: TextStyle(
            color: theme.onBackground,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.add, color: theme.onBackground),
            onPressed: () => _showAddDialog(theme),
          ),
          TextButton(
            onPressed: _clearAll,
            child: Text(
              'Clear',
              style: TextStyle(
                color: theme.error,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          _buildSearch(theme),
          _buildFilters(theme),
          Expanded(
            child: entries.isEmpty
                ? Center(
                    child: Text(
                      'No entries',
                      style: TextStyle(color: theme.onBackgroundVariant),
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 6,
                    ),
                    itemCount: entries.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 6),
                    itemBuilder: (_, i) => _entryRow(entries[i], theme),
                  ),
          ),
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
                  hintText: 'Search by key or value',
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
      _FilterType.app: 'App',
      _FilterType.phantom: 'Phantom',
    };
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: filters.entries.map((f) {
          final selected = _selectedFilter == f.key;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () => setState(() => _selectedFilter = f.key),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: selected ? theme.primary : theme.surface,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  f.value,
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

  Widget _entryRow(MapEntry<String, dynamic> entry, PhantomTheme theme) {
    final isBool = entry.value is bool;
    final typeLabel = _typeLabel(entry.value);

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: isBool
          ? null
          : () => _showEditDialog(entry.key, entry.value, theme),
      onLongPress: () => _showEntryActions(entry.key, entry.value, theme),
      child: Container(
        padding: const EdgeInsets.all(10),
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
                    entry.key,
                    style: TextStyle(
                      color: theme.onBackground,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 5,
                          vertical: 1,
                        ),
                        decoration: BoxDecoration(
                          color: theme.surfaceVariant,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          typeLabel,
                          style: TextStyle(
                            color: theme.onBackgroundVariant,
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      if (!isBool)
                        Expanded(
                          child: Text(
                            entry.value.toString(),
                            style: TextStyle(
                              color: theme.onBackgroundVariant,
                              fontSize: 11,
                              fontFamily: 'monospace',
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            if (isBool)
              Switch.adaptive(
                value: entry.value as bool,
                activeTrackColor: theme.success,
                onChanged: (v) async {
                  final prefs = await SharedPreferences.getInstance();
                  await prefs.setBool(entry.key, v);
                  _loadEntries();
                },
              ),
          ],
        ),
      ),
    );
  }

  String _typeLabel(dynamic value) {
    if (value is bool) return 'Bool';
    if (value is int) return 'Int';
    if (value is double) return 'Double';
    if (value is List) return 'List';
    return 'String';
  }

  void _showEditDialog(String key, dynamic currentValue, PhantomTheme theme) {
    _showValueEditor(theme, existingKey: key, existingValue: currentValue);
  }

  void _showAddDialog(PhantomTheme theme) => _showValueEditor(theme);

  /// Add/edit sheet with an explicit type, so an int stays an int in
  /// SharedPreferences instead of being coerced to a string.
  void _showValueEditor(
    PhantomTheme theme, {
    String? existingKey,
    dynamic existingValue,
  }) {
    final isEditing = existingKey != null;
    final keyController = TextEditingController(text: existingKey ?? '');
    final valueController = TextEditingController(
      text: existingValue is List
          ? (existingValue).join(', ')
          : existingValue?.toString() ?? '',
    );
    var type = isEditing ? _typeLabel(existingValue) : 'String';
    if (type == 'List') type = 'String';

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: theme.background,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Padding(
          padding: EdgeInsets.fromLTRB(
            16,
            16,
            16,
            MediaQuery.of(ctx).viewInsets.bottom + 16,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isEditing ? 'Edit Value' : 'Add Entry',
                style: TextStyle(
                  color: theme.onBackground,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              _sheetLabel('Key', theme),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: theme.surface,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: TextField(
                  controller: keyController,
                  enabled: !isEditing,
                  autofocus: !isEditing,
                  style: TextStyle(
                    color: isEditing
                        ? theme.onBackgroundVariant
                        : theme.onBackground,
                    fontSize: 14,
                    fontFamily: 'monospace',
                  ),
                  decoration: InputDecoration(
                    hintText: 'Key',
                    hintStyle: TextStyle(color: theme.onBackgroundVariant),
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              _sheetLabel('Value', theme),
              if (type == 'Bool')
                Row(
                  children: ['true', 'false'].map((option) {
                    final selected =
                        valueController.text.toLowerCase() == option;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: GestureDetector(
                        onTap: () =>
                            setSheetState(() => valueController.text = option),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: selected ? theme.primary : theme.surface,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            option,
                            style: TextStyle(
                              color: selected
                                  ? theme.onPrimary
                                  : theme.onBackground,
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                )
              else
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: theme.surface,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: TextField(
                    controller: valueController,
                    autofocus: isEditing,
                    keyboardType: type == 'Int' || type == 'Double'
                        ? const TextInputType.numberWithOptions(decimal: true)
                        : TextInputType.text,
                    style: TextStyle(
                      color: theme.onBackground,
                      fontSize: 14,
                      fontFamily: 'monospace',
                    ),
                    decoration: InputDecoration(
                      hintText: 'Value',
                      hintStyle: TextStyle(color: theme.onBackgroundVariant),
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                  ),
                ),
              const SizedBox(height: 12),
              _sheetLabel('Type', theme),
              Wrap(
                spacing: 8,
                children: _writableTypes.map((option) {
                  final selected = type == option;
                  return GestureDetector(
                    onTap: () => setSheetState(() {
                      type = option;
                      if (option == 'Bool' &&
                          valueController.text.toLowerCase() != 'true' &&
                          valueController.text.toLowerCase() != 'false') {
                        valueController.text = 'true';
                      }
                    }),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: selected ? theme.primary : theme.surface,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        option,
                        style: TextStyle(
                          color: selected
                              ? theme.onPrimary
                              : theme.onBackground,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: Text(
                      'Cancel',
                      style: TextStyle(color: theme.onBackgroundVariant),
                    ),
                  ),
                  const SizedBox(width: 8),
                  TextButton(
                    onPressed: () async {
                      final key = keyController.text.trim();
                      if (key.isEmpty) return;
                      await _writeValue(key, valueController.text, type);
                      if (ctx.mounted) Navigator.pop(ctx);
                      await _loadEntries();
                    },
                    child: Text(
                      isEditing ? 'Save' : 'Add',
                      style: TextStyle(
                        color: theme.info,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  static const _writableTypes = ['String', 'Int', 'Double', 'Bool'];

  Widget _sheetLabel(String text, PhantomTheme theme) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        text,
        style: TextStyle(
          color: theme.onBackgroundVariant,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  /// Writes [raw] under [key] using the SharedPreferences setter for [type].
  ///
  /// The key is removed first so switching an entry's type doesn't leave the
  /// old typed value behind.
  Future<void> _writeValue(String key, String raw, String type) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(key);
    switch (type) {
      case 'Int':
        await prefs.setInt(key, int.tryParse(raw.trim()) ?? 0);
      case 'Double':
        await prefs.setDouble(key, double.tryParse(raw.trim()) ?? 0);
      case 'Bool':
        final normalized = raw.trim().toLowerCase();
        await prefs.setBool(key, normalized == 'true' || normalized == '1');
      default:
        await prefs.setString(key, raw);
    }
  }

  void _showEntryActions(String key, dynamic value, PhantomTheme theme) {
    showModalBottomSheet(
      context: context,
      backgroundColor: theme.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(Icons.copy, color: theme.info),
              title: Text(
                'Copy Key',
                style: TextStyle(color: theme.onBackground),
              ),
              onTap: () {
                Clipboard.setData(ClipboardData(text: key));
                Navigator.pop(ctx);
              },
            ),
            ListTile(
              leading: Icon(Icons.copy_all, color: theme.info),
              title: Text(
                'Copy Value',
                style: TextStyle(color: theme.onBackground),
              ),
              onTap: () {
                Clipboard.setData(ClipboardData(text: value.toString()));
                Navigator.pop(ctx);
              },
            ),
            ListTile(
              leading: Icon(Icons.delete, color: theme.error),
              title: Text('Delete', style: TextStyle(color: theme.error)),
              onTap: () async {
                final prefs = await SharedPreferences.getInstance();
                await prefs.remove(key);
                if (ctx.mounted) Navigator.pop(ctx);
                _loadEntries();
              },
            ),
          ],
        ),
      ),
    );
  }

  void _clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    final keys = _filteredEntries.map((e) => e.key).toList();
    for (final key in keys) {
      await prefs.remove(key);
    }
    _loadEntries();
  }
}
