import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'models/phantom_localization_entry.dart';

class PhantomLocalizer extends ChangeNotifier {
  PhantomLocalizer._();
  static final PhantomLocalizer instance = PhantomLocalizer._();

  static const _languageKey = 'phantom_language';

  final List<PhantomLocalizationEntry> _entries = [];
  PhantomLanguage _currentLanguage = PhantomLanguage.english;

  List<PhantomLocalizationEntry> get entries => List.unmodifiable(_entries);
  PhantomLanguage get currentLanguage => _currentLanguage;

  List<String> get groups {
    final groupSet = _entries.map((e) => e.group).toSet().toList();
    groupSet.sort();
    return groupSet;
  }

  List<PhantomLocalizationEntry> entriesForGroup(String group) {
    return _entries.where((e) => e.group == group).toList();
  }

  Future<void> loadLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_languageKey);
    if (saved == 'spanish') {
      _currentLanguage = PhantomLanguage.spanish;
    }
  }

  void register({
    required String key,
    required String english,
    required String spanish,
    String group = 'General',
  }) {
    final id = '${group}_$key';
    if (_entries.any((e) => e.id == id)) return;
    _entries.add(PhantomLocalizationEntry(
      key: key,
      english: english,
      spanish: spanish,
      group: group,
    ));
    notifyListeners();
  }

  Future<void> setLanguage(PhantomLanguage language) async {
    _currentLanguage = language;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_languageKey, language == PhantomLanguage.spanish ? 'spanish' : 'english');
  }

  String localized(String key, {String? group}) {
    final entry = _entries.cast<PhantomLocalizationEntry?>().firstWhere(
          (e) => e!.key == key && (group == null || e.group == group),
          orElse: () => null,
        );
    return entry?.value(_currentLanguage) ?? key;
  }

  void removeAll() {
    _entries.clear();
    notifyListeners();
  }
}
