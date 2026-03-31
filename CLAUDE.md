# CLAUDE.md

This file provides guidance to Claude Code when working with code in this repository OR when integrating this package into another project.

## Project Overview

Phantom Flutter is a cross-platform debug toolkit for Flutter apps. It provides a floating debug button overlay that opens a full debug panel with logs, network inspector, mock services, configuration, device info, SharedPreferences viewer, and localization management.

## How to Add to a Flutter Project

### Step 1: Add dependency

```yaml
# In pubspec.yaml
dependencies:
  phantom_flutter:
    git:
      url: https://github.com/donnadony/phantom-flutter.git
      ref: v0.0.1
```

Then run `flutter pub get`.

### Step 2: Wrap the root widget

```dart
import 'package:phantom_flutter/phantom_flutter.dart';

void main() {
  runApp(
    PhantomOverlay(
      child: MaterialApp(home: MyHomePage()),
    ),
  );
}
```

### Step 3: Add network logging to HTTP layer

```dart
// Before making request:
Phantom.logRequest(method: 'GET', url: url, headers: headersStr, body: bodyStr);

// After receiving response:
Phantom.logResponse(url: url, statusCode: 200, headers: headersStr, body: responseBody, durationMs: duration);

// Or log both at once:
Phantom.completeRequest(
  method: 'POST', url: url,
  requestHeaders: 'Content-Type: application/json',
  requestBody: '{"key": "value"}',
  statusCode: 200,
  responseBody: '{"result": "ok"}',
  durationMs: 250,
);
```

### Step 4: Add app logs

```dart
Phantom.log(PhantomLogLevel.info, 'User logged in', tag: 'Auth');
Phantom.log(PhantomLogLevel.error, 'Request failed', tag: 'Network');
```

### Step 5 (optional): Register configs

```dart
Phantom.registerConfig('API URL', key: 'api_url', defaultValue: 'https://api.example.com');
Phantom.registerConfig('Debug Mode', key: 'debug', defaultValue: 'false', type: PhantomConfigType.toggle);
Phantom.registerConfig('Environment', key: 'env', defaultValue: 'prod', type: PhantomConfigType.picker, options: ['dev', 'staging', 'prod']);
```

### Step 6 (optional): Register localizations

```dart
Phantom.registerLocalization(key: 'welcome', english: 'Welcome', spanish: 'Bienvenido', group: 'Home');
```

### Step 7 (optional): Mock interceptor

```dart
final mock = Phantom.mockResponse(method: 'GET', url: requestUrl);
if (mock != null) {
  // Use mock.statusCode, mock.body instead of real request
  return;
}
```

## Complete API Reference

```dart
// Logging
Phantom.log(PhantomLogLevel.info/warning/error, message, tag: tag);

// Network
Phantom.logRequest(method:, url:, headers:, body:);
Phantom.logResponse(url:, statusCode:, headers:, body:, durationMs:);
Phantom.completeRequest(method:, url:, requestHeaders:, requestBody:, statusCode:, responseHeaders:, responseBody:, durationMs:);
Phantom.logExternalEntry(Map data, sourcePrefix:);

// Mocks
Phantom.mockResponse(method:, url:);  // returns (statusCode, body, headers)?
Phantom.loadMocks();

// Config
Phantom.registerConfig(label, key:, defaultValue:, type:, options:, group:);
Phantom.config(key);  // Future<String?>

// Localization
Phantom.registerLocalization(key:, english:, spanish:, group:);
Phantom.setLanguage(PhantomLanguage.english/spanish);
Phantom.localized(key, group:);

// Theme
Phantom.setTheme(PhantomTheme(...));

// UI
Phantom.show(context);
PhantomOverlay(child: app, showFloatingButton: true, theme: customTheme);
```

## Build & Test Commands

```bash
flutter pub get
flutter analyze
flutter test
cd example && flutter run
```

## Architecture

This is a Flutter package (Flutter 3.29+, Dart 3.9+) with a single `phantom_flutter` library target.

### Public API Surface

`Phantom` (class) is the sole public entry point — all features are accessed via static methods. It delegates to five singleton core managers:

- **PhantomLogger** — App-level logging with levels and tags
- **PhantomNetworkLogger** — HTTP request/response capture with pending-request correlation
- **PhantomMockInterceptor** — URL pattern matching for mock responses (persisted via SharedPreferences)
- **PhantomConfig** — Key-value override system (persisted with `phantom_config_` prefix)
- **PhantomLocalizer** — Bilingual string management (English/Spanish)

### Key Patterns

- **State management**: Plain `ChangeNotifier` — no external dependency
- **Theme**: `PhantomTheme` with Kodivex dark defaults via `PhantomThemeProvider` (InheritedWidget)
- **Overlay**: `PhantomOverlay` wraps the host app with a draggable floating button + internal `MaterialApp`

### Dependencies

Only 3 external packages (all first-party Flutter community):
- `shared_preferences`, `package_info_plus`, `device_info_plus`
