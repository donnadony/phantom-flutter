import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'models/phantom_config_entry.dart';

class PhantomConfig extends ChangeNotifier {
  PhantomConfig._();
  static final PhantomConfig instance = PhantomConfig._();

  static const _storagePrefix = 'phantom_config_';

  final List<PhantomConfigEntry> _entries = [];

  List<PhantomConfigEntry> get entries => List.unmodifiable(_entries);

  void register({
    required String label,
    required String key,
    required String defaultValue,
    PhantomConfigType type = PhantomConfigType.text,
    List<String> options = const [],
    String group = 'General',
  }) {
    if (_entries.any((e) => e.key == key)) return;
    _entries.add(PhantomConfigEntry(
      label: label,
      key: key,
      defaultValue: defaultValue,
      type: type,
      options: options,
      group: group,
    ));
    notifyListeners();
  }

  List<String> get groups {
    final groupSet = _entries.map((e) => e.group).toSet().toList();
    groupSet.sort();
    return groupSet;
  }

  List<PhantomConfigEntry> entriesForGroup(String group) {
    return _entries.where((e) => e.group == group).toList();
  }

  Future<String?> value(String key) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('$_storagePrefix$key');
  }

  Future<String> effectiveValue(String key) async {
    final override = await value(key);
    if (override != null && override.isNotEmpty) return override;
    final entry = _entries.cast<PhantomConfigEntry?>().firstWhere(
          (e) => e!.key == key,
          orElse: () => null,
        );
    return entry?.defaultValue ?? '';
  }

  Future<void> setValue(String key, String? val) async {
    final prefs = await SharedPreferences.getInstance();
    if (val != null && val.isNotEmpty) {
      await prefs.setString('$_storagePrefix$key', val);
    } else {
      await prefs.remove('$_storagePrefix$key');
    }
    notifyListeners();
  }

  Future<void> resetValue(String key) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('$_storagePrefix$key');
    notifyListeners();
  }

  Future<void> resetAll() async {
    final prefs = await SharedPreferences.getInstance();
    for (final entry in _entries) {
      await prefs.remove('$_storagePrefix${entry.key}');
    }
    notifyListeners();
  }
}
