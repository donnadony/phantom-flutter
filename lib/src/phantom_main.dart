import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;

import 'core/models/phantom_config_entry.dart';
import 'core/models/phantom_feature.dart';
import 'core/models/phantom_localization_entry.dart';
import 'core/models/phantom_log_item.dart';
import 'core/models/phantom_mock_rule.dart';
import 'core/phantom_config.dart';
import 'core/phantom_localizer.dart';
import 'core/phantom_logger.dart';
import 'core/phantom_mock_interceptor.dart';
import 'core/phantom_network_logger.dart';
import 'theme/phantom_theme.dart';
import 'ui/phantom_view.dart';

class Phantom {
  Phantom._();

  // MARK: - Theme

  static PhantomTheme theme = PhantomTheme.kodivex;

  static void setTheme(PhantomTheme newTheme) {
    theme = newTheme;
  }

  // MARK: - Features

  /// Modules shown in the Phantom menu, in order. Defaults to logs + network,
  /// matching phantom-ios.
  static List<PhantomFeature> features = [
    PhantomFeature.logs,
    PhantomFeature.network,
  ];

  static void setFeatures(List<PhantomFeature> newFeatures) {
    features = newFeatures;
  }

  /// Enables every built-in module.
  static void enableAllFeatures() {
    features = PhantomFeature.values.toList();
  }

  // MARK: - Custom Entries

  static final List<PhantomCustomEntry> customEntries = [];

  static void addCustomEntry({
    required String title,
    required IconData icon,
    required VoidCallback action,
  }) {
    customEntries.add(
      PhantomCustomEntry(title: title, icon: icon, action: action),
    );
  }

  static void clearCustomEntries() => customEntries.clear();

  // MARK: - App Logging

  static void log(
    PhantomLogLevel level,
    String message, {
    String? tag,
  }) {
    PhantomLogger.instance.log(level, message, tag: tag);
  }

  static void logInfo(String message, {String? tag}) =>
      PhantomLogger.instance.info(message, tag: tag);

  static void logWarning(String message, {String? tag}) =>
      PhantomLogger.instance.warn(message, tag: tag);

  static void logError(String message, {String? tag}) =>
      PhantomLogger.instance.error(message, tag: tag);

  // MARK: - Network Logging

  static String _formatBody(dynamic body) {
    if (body == null) return 'No body';
    if (body is String) return body.isEmpty ? 'No body' : body;
    if (body is Map || body is List) {
      try {
        return const JsonEncoder.withIndent('  ').convert(body);
      } catch (_) {
        return body.toString();
      }
    }
    return body.toString();
  }

  static String _formatHeaders(dynamic headers) {
    if (headers == null) return 'No headers';
    if (headers is String) return headers.isEmpty ? 'No headers' : headers;
    if (headers is Map) {
      return headers.entries.map((e) {
        final value = e.value is List ? (e.value as List).join(', ') : e.value;
        return '${e.key}: $value';
      }).join('\n');
    }
    return headers.toString();
  }

  static void logRequest({
    required String method,
    required String url,
    dynamic headers = 'No headers',
    dynamic body = 'No body',
  }) {
    PhantomNetworkLogger.instance.logRequest(
      method: method,
      url: url,
      headers: _formatHeaders(headers),
      body: _formatBody(body),
    );
  }

  static void logResponse({
    required String url,
    required int statusCode,
    dynamic headers = 'No headers',
    dynamic body = '',
    int? durationMs,
  }) {
    PhantomNetworkLogger.instance.logResponse(
      url: url,
      statusCode: statusCode,
      headers: _formatHeaders(headers),
      body: _formatBody(body),
      durationMs: durationMs,
    );
  }

  /// Completes a pending request that failed (timeout, socket error, cancel).
  static void logRequestError({
    required String url,
    required String errorMessage,
    int? statusCode,
    dynamic headers = 'No headers',
    int? durationMs,
  }) {
    PhantomNetworkLogger.instance.logError(
      url: url,
      errorMessage: errorMessage,
      statusCode: statusCode,
      headers: _formatHeaders(headers),
      durationMs: durationMs,
    );
  }

  /// Attaches status/headers to an in-flight request without completing it.
  static void updateResponseMetadata({
    required String url,
    dynamic headers = 'No headers',
    int? statusCode,
  }) {
    PhantomNetworkLogger.instance.updateResponseMetadata(
      url: url,
      headers: _formatHeaders(headers),
      statusCode: statusCode,
    );
  }

  static void completeRequest({
    required String method,
    required String url,
    dynamic requestHeaders = 'No headers',
    dynamic requestBody = 'No body',
    required int statusCode,
    dynamic responseHeaders = 'No headers',
    dynamic responseBody = '',
    int? durationMs,
  }) {
    PhantomNetworkLogger.instance.completeRequest(
      method: method,
      url: url,
      requestHeaders: _formatHeaders(requestHeaders),
      requestBody: _formatBody(requestBody),
      statusCode: statusCode,
      responseHeaders: _formatHeaders(responseHeaders),
      responseBody: _formatBody(responseBody),
      durationMs: durationMs,
    );
  }

  static void logExternalEntry(
    Map<String, dynamic> data, {
    String sourcePrefix = '[External]',
  }) {
    PhantomNetworkLogger.instance
        .logExternalEntry(data, sourcePrefix: sourcePrefix);
  }

  // MARK: - Mock Interceptor

  /// Returns a mock for this request, if one is registered and enabled.
  ///
  /// A hit is also recorded in the Network inspector, flagged as MOCK.
  static PhantomMockHit? mockResponse({
    required String method,
    required String url,
  }) {
    return PhantomMockInterceptor.instance
        .mockResponse(method: method, url: url);
  }

  /// Reloads persisted mock rules from disk.
  static Future<void> loadMocks() async {
    await PhantomMockInterceptor.instance.loadRules();
  }

  /// Merges a bundled asset (a mock collection or a bare rule array) into the
  /// current rules. Returns the number of rules imported, or null on failure.
  static Future<int?> loadMocksFromAsset(String assetPath) async {
    try {
      final contents = await rootBundle.loadString(assetPath);
      return await PhantomMockInterceptor.instance.importCollection(contents);
    } catch (_) {
      return null;
    }
  }

  /// Merges a raw JSON string into the current rules.
  static Future<int?> loadMocksFromJson(String jsonString) {
    return PhantomMockInterceptor.instance.importCollection(jsonString);
  }

  static String exportMocks({
    String name = 'Phantom Mocks',
    String description = '',
  }) {
    return PhantomMockInterceptor.instance
        .exportCollection(name: name, description: description);
  }

  static List<PhantomMockRule> get mockRules =>
      PhantomMockInterceptor.instance.rules;

  // MARK: - Configuration

  static void registerConfig(
    String label, {
    required String key,
    required String defaultValue,
    PhantomConfigType type = PhantomConfigType.text,
    List<String> options = const [],
    String group = 'General',
  }) {
    PhantomConfig.instance.register(
      label: label,
      key: key,
      defaultValue: defaultValue,
      type: type,
      options: options,
      group: group,
    );
  }

  static Future<String?> config(String key) async {
    return PhantomConfig.instance.effectiveValue(key);
  }

  /// Overrides a config value programmatically. Pass null to clear it.
  static Future<void> setConfig(String key, String? value) {
    return PhantomConfig.instance.setValue(key, value);
  }

  static Future<void> resetConfig(String key) {
    return PhantomConfig.instance.resetValue(key);
  }

  // MARK: - Localization

  static void registerLocalization({
    required String key,
    required String english,
    required String spanish,
    String group = 'General',
  }) {
    PhantomLocalizer.instance.register(
      key: key,
      english: english,
      spanish: spanish,
      group: group,
    );
  }

  static Future<void> setLanguage(PhantomLanguage language) async {
    await PhantomLocalizer.instance.setLanguage(language);
  }

  static PhantomLanguage get currentLanguage =>
      PhantomLocalizer.instance.currentLanguage;

  static String localized(String key, {String? group}) {
    return PhantomLocalizer.instance.localized(key, group: group);
  }

  // MARK: - UI

  static void show(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PhantomThemeProvider(
          theme: theme,
          child: const PhantomView(),
        ),
      ),
    );
  }
}
