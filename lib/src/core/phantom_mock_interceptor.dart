import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'models/phantom_mock_rule.dart';

class PhantomMockInterceptor extends ChangeNotifier {
  PhantomMockInterceptor._();
  static final PhantomMockInterceptor instance = PhantomMockInterceptor._();

  static const _storageKey = 'phantom_mock_rules';

  final List<PhantomMockRule> _rules = [];

  List<PhantomMockRule> get rules => List.unmodifiable(_rules);

  Future<void> loadRules() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_storageKey);
    if (jsonString == null) return;
    try {
      _rules
        ..clear()
        ..addAll(PhantomMockRule.decodeRules(jsonString));
      notifyListeners();
    } catch (_) {}
  }

  Future<void> _saveRules() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_storageKey, PhantomMockRule.encodeRules(_rules));
  }

  Future<void> addRule(PhantomMockRule rule) async {
    _rules.add(rule);
    notifyListeners();
    await _saveRules();
  }

  Future<void> updateRule(PhantomMockRule rule) async {
    final index = _rules.indexWhere((r) => r.id == rule.id);
    if (index == -1) return;
    _rules[index] = rule;
    notifyListeners();
    await _saveRules();
  }

  Future<void> deleteRule(String id) async {
    _rules.removeWhere((r) => r.id == id);
    notifyListeners();
    await _saveRules();
  }

  Future<void> toggleRule(String id) async {
    final index = _rules.indexWhere((r) => r.id == id);
    if (index == -1) return;
    _rules[index].isEnabled = !_rules[index].isEnabled;
    notifyListeners();
    await _saveRules();
  }

  ({int statusCode, String body, String headers})? mockResponse({
    required String method,
    required String url,
  }) {
    for (final rule in _rules) {
      if (!rule.isEnabled) continue;
      if (rule.httpMethod != 'ANY' &&
          rule.httpMethod.toUpperCase() != method.toUpperCase()) {
        continue;
      }
      if (!url.contains(rule.urlPattern)) continue;
      final response = rule.activeResponse;
      if (response == null) continue;
      return (
        statusCode: response.statusCode,
        body: response.responseBody,
        headers: '[MOCK]',
      );
    }
    return null;
  }

  Future<void> importRules(String jsonString) async {
    try {
      final imported = PhantomMockRule.decodeRules(jsonString);
      _rules.addAll(imported);
      notifyListeners();
      await _saveRules();
    } catch (_) {}
  }

  String exportRules() {
    return const JsonEncoder.withIndent('  ')
        .convert(_rules.map((r) => r.toJson()).toList());
  }

  Future<void> clearAll() async {
    _rules.clear();
    notifyListeners();
    await _saveRules();
  }
}
