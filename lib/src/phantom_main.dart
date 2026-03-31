import 'package:flutter/material.dart';

import 'dart:convert';

import 'core/models/phantom_config_entry.dart';
import 'core/models/phantom_localization_entry.dart';
import 'core/models/phantom_log_item.dart';
import 'core/phantom_config.dart';
import 'core/phantom_localizer.dart';
import 'core/phantom_logger.dart';
import 'core/phantom_mock_interceptor.dart';
import 'core/phantom_network_logger.dart';
import 'theme/phantom_theme.dart';
import 'ui/phantom_view.dart';

class Phantom {
  Phantom._();

  static PhantomTheme theme = PhantomTheme.kodivex;

  static void setTheme(PhantomTheme newTheme) {
    theme = newTheme;
  }

  // MARK: - App Logging

  static void log(
    PhantomLogLevel level,
    String message, {
    String? tag,
  }) {
    PhantomLogger.instance.log(level, message, tag: tag);
  }

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

  static void logRequest({
    required String method,
    required String url,
    String headers = 'No headers',
    dynamic body = 'No body',
  }) {
    PhantomNetworkLogger.instance.logRequest(
      method: method,
      url: url,
      headers: headers,
      body: _formatBody(body),
    );
  }

  static void logResponse({
    required String url,
    required int statusCode,
    String headers = 'No headers',
    dynamic body = '',
    int? durationMs,
  }) {
    PhantomNetworkLogger.instance.logResponse(
      url: url,
      statusCode: statusCode,
      headers: headers,
      body: _formatBody(body),
      durationMs: durationMs,
    );
  }

  static void completeRequest({
    required String method,
    required String url,
    String requestHeaders = 'No headers',
    dynamic requestBody = 'No body',
    required int statusCode,
    String responseHeaders = 'No headers',
    dynamic responseBody = '',
    int? durationMs,
  }) {
    PhantomNetworkLogger.instance.completeRequest(
      method: method,
      url: url,
      requestHeaders: requestHeaders,
      requestBody: _formatBody(requestBody),
      statusCode: statusCode,
      responseHeaders: responseHeaders,
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

  static ({int statusCode, String body, String headers})? mockResponse({
    required String method,
    required String url,
  }) {
    return PhantomMockInterceptor.instance
        .mockResponse(method: method, url: url);
  }

  static Future<void> loadMocks() async {
    await PhantomMockInterceptor.instance.loadRules();
  }

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
