import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'models/phantom_mock_collection.dart';
import 'models/phantom_mock_rule.dart';
import 'phantom_network_logger.dart';

/// Result of a successful mock match.
typedef PhantomMockHit = ({int statusCode, String body, String headers});

class PhantomMockInterceptor extends ChangeNotifier {
  PhantomMockInterceptor._();
  static final PhantomMockInterceptor instance = PhantomMockInterceptor._();

  static const _storageKey = 'phantom_mock_rules';
  static const _mockHeaders = 'Content-Type: application/json';

  final List<PhantomMockRule> _rules = [];

  List<PhantomMockRule> get rules => List.unmodifiable(_rules);

  bool get hasRules => _rules.isNotEmpty;

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

  /// Switches which of a rule's responses is served.
  Future<void> setActiveResponse({
    required String ruleId,
    required String responseId,
  }) async {
    final index = _rules.indexWhere((r) => r.id == ruleId);
    if (index == -1) return;
    _rules[index].activeResponseId = responseId;
    notifyListeners();
    await _saveRules();
  }

  /// Returns the rule that would serve [method] [url], or null.
  ///
  /// Patterns are matched against the URL *path* (not the full URL) so a
  /// pattern like `/v1/users` is not accidentally satisfied by a query string
  /// or a host that happens to contain the same text.
  PhantomMockRule? matchingRule({
    required String method,
    required String url,
  }) {
    final path = _pathOf(url);
    final upperMethod = method.toUpperCase();
    for (final rule in _rules) {
      if (!rule.isEnabled) continue;
      if (!_methodMatches(rule.httpMethod, upperMethod)) continue;
      if (!path.contains(rule.urlPattern)) continue;
      final response = rule.activeResponse;
      if (response == null) continue;
      if (!_methodMatches(response.httpMethod, upperMethod)) continue;
      return rule;
    }
    return null;
  }

  /// Looks up a mock for [method] [url]. On a hit the call is also recorded in
  /// the Network inspector flagged as MOCK, mirroring phantom-ios.
  PhantomMockHit? mockResponse({
    required String method,
    required String url,
  }) {
    final rule = matchingRule(method: method, url: url);
    final response = rule?.activeResponse;
    if (response == null) return null;

    PhantomNetworkLogger.instance.logMockResponse(
      method: method,
      url: url,
      statusCode: response.statusCode,
      headers: _mockHeaders,
      body: response.responseBody,
    );

    return (
      statusCode: response.statusCode,
      body: response.responseBody,
      headers: _mockHeaders,
    );
  }

  /// Finds an existing rule that already covers this endpoint, so the Network
  /// detail screen can offer "Edit Mock" instead of creating a duplicate.
  PhantomMockRule? ruleForEndpoint({
    required String method,
    required String url,
  }) {
    final path = _pathOf(url);
    final upperMethod = method.toUpperCase();
    for (final rule in _rules) {
      if (!_methodMatches(rule.httpMethod, upperMethod)) continue;
      if (rule.urlPattern.isNotEmpty && path.contains(rule.urlPattern)) {
        return rule;
      }
    }
    return null;
  }

  /// Merges a collection into the current rules, replacing any rule with the
  /// same url pattern + method instead of duplicating it.
  ///
  /// Returns the number of rules imported, or null if the payload was invalid.
  Future<int?> importCollection(String jsonString) async {
    final collection = PhantomMockCollection.decode(jsonString);
    if (collection == null || collection.rules.isEmpty) return null;
    for (final incoming in collection.rules) {
      final index = _rules.indexWhere((r) =>
          r.urlPattern == incoming.urlPattern &&
          r.httpMethod == incoming.httpMethod);
      if (index != -1) {
        _rules[index] = incoming;
      } else {
        _rules.add(incoming);
      }
    }
    notifyListeners();
    await _saveRules();
    return collection.rules.length;
  }

  String exportCollection({
    String name = 'Phantom Mocks',
    String description = '',
  }) {
    return PhantomMockCollection(
      name: name,
      description: description,
      rules: _rules,
    ).encode();
  }

  Future<void> clearAll() async {
    _rules.clear();
    notifyListeners();
    await _saveRules();
  }

  bool _methodMatches(String ruleMethod, String requestMethod) {
    return ruleMethod == 'ANY' || ruleMethod.toUpperCase() == requestMethod;
  }

  String _pathOf(String url) {
    final uri = Uri.tryParse(url);
    if (uri == null || uri.path.isEmpty) return url;
    return uri.path;
  }
}
