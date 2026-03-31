import 'package:flutter/material.dart';

class PhantomTheme {
  final Color background;
  final Color surface;
  final Color surfaceVariant;
  final Color onBackground;
  final Color onBackgroundVariant;
  final Color onPrimary;
  final Color primary;
  final Color primaryContainer;
  final Color info;
  final Color warning;
  final Color error;
  final Color success;
  final Color outline;
  final Color outlineVariant;
  final Color tint;
  final Color inputBackground;
  final Color httpGet;
  final Color httpPost;
  final Color httpPut;
  final Color httpDelete;
  final Color jsonString;
  final Color jsonNumber;
  final Color jsonBoolean;
  final Color jsonNull;

  const PhantomTheme({
    required this.background,
    required this.surface,
    required this.surfaceVariant,
    required this.onBackground,
    required this.onBackgroundVariant,
    required this.onPrimary,
    required this.primary,
    required this.primaryContainer,
    required this.info,
    required this.warning,
    required this.error,
    required this.success,
    required this.outline,
    required this.outlineVariant,
    required this.tint,
    required this.inputBackground,
    required this.httpGet,
    required this.httpPost,
    required this.httpPut,
    required this.httpDelete,
    required this.jsonString,
    required this.jsonNumber,
    required this.jsonBoolean,
    required this.jsonNull,
  });

  static const kodivex = PhantomTheme(
    background: Color(0xFF0B1326),
    surface: Color(0xFF1C2540),
    surfaceVariant: Color(0xFF283050),
    onBackground: Color(0xFFE4ECFF),
    onBackgroundVariant: Color(0xFFA8B4D0),
    onPrimary: Color(0xFF3C0091),
    primary: Color(0xFFD0BCFF),
    primaryContainer: Color(0xFFA078FF),
    info: Color(0xFF5DE6FF),
    warning: Color(0xFFFFB869),
    error: Color(0xFFFFB4AB),
    success: Color(0xFF5DE6FF),
    outline: Color(0xFF958EA0),
    outlineVariant: Color(0xFF5A5570),
    tint: Color(0xFFA078FF),
    inputBackground: Color(0xFF0F1829),
    httpGet: Color(0xFF5DE6FF),
    httpPost: Color(0xFFD0BCFF),
    httpPut: Color(0xFFFFB869),
    httpDelete: Color(0xFFFFB4AB),
    jsonString: Color(0xFF5DE6FF),
    jsonNumber: Color(0xFFD0BCFF),
    jsonBoolean: Color(0xFFFFB869),
    jsonNull: Color(0xFF958EA0),
  );

  Color methodColor(String method) {
    switch (method.toUpperCase()) {
      case 'GET':
        return httpGet;
      case 'POST':
        return httpPost;
      case 'PUT':
        return httpPut;
      case 'DELETE':
        return httpDelete;
      default:
        return onBackground;
    }
  }

  Color statusColor(int code) {
    if (code >= 200 && code < 300) return success;
    if (code >= 300 && code < 500) return warning;
    return error;
  }

  Color statusBackgroundColor(int code) {
    if (code >= 200 && code < 300) return success.withValues(alpha: 0.18);
    if (code >= 300 && code < 500) return warning.withValues(alpha: 0.18);
    return error.withValues(alpha: 0.16);
  }
}

class PhantomThemeProvider extends InheritedWidget {
  final PhantomTheme theme;

  const PhantomThemeProvider({
    super.key,
    required this.theme,
    required super.child,
  });

  static PhantomTheme of(BuildContext context) {
    final provider =
        context.dependOnInheritedWidgetOfExactType<PhantomThemeProvider>();
    return provider?.theme ?? PhantomTheme.kodivex;
  }

  @override
  bool updateShouldNotify(PhantomThemeProvider oldWidget) {
    return theme != oldWidget.theme;
  }
}
