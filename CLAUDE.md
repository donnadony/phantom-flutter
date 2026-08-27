# CLAUDE.md

This file provides guidance to Claude Code when working with code in this repository OR when integrating this package into another project.

## Project Overview

Phantom Flutter is a cross-platform debug toolkit for Flutter apps. It provides a floating debug button overlay that opens a full debug panel with logs, network inspector, mock services, configuration, device info, SharedPreferences viewer, localization management, a sandbox file browser, and a deep link tester.

It is the Flutter counterpart of [phantom-ios](https://github.com/donnadony/phantom-ios) and is kept at feature parity with it. Mock collections exported from either toolkit can be imported by the other.

## How to Add to a Flutter Project

### Step 1: Add dependency

```yaml
# In pubspec.yaml
dependencies:
  phantom_flutter:
    git:
      url: https://github.com/donnadony/phantom-flutter.git
      ref: v0.0.4
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

### Step 3: Choose which modules to show

By default only Logs and Network are listed. Opt into the rest:

```dart
Phantom.enableAllFeatures();

// Or pick an explicit subset, in menu order:
Phantom.setFeatures([
  PhantomFeature.logs,
  PhantomFeature.network,
  PhantomFeature.mockServices,
  PhantomFeature.configuration,
]);

// Append your own row to the menu:
Phantom.addCustomEntry(
  title: 'Force crash',
  icon: Icons.bug_report,
  action: () => throw Exception('test crash'),
);
```

### Step 4: Add network logging to your HTTP layer

```dart
// Before making request:
Phantom.logRequest(method: 'GET', url: url, headers: headers, body: body);

// After receiving response:
Phantom.logResponse(url: url, statusCode: 200, headers: headers, body: responseBody, durationMs: duration);

// On failure — completes the pending entry instead of leaving it PENDING forever:
Phantom.logRequestError(url: url, errorMessage: 'Connection timeout');

// Or log both sides at once:
Phantom.completeRequest(
  method: 'POST', url: url,
  requestHeaders: {'Content-Type': 'application/json'},
  requestBody: {'key': 'value'},
  statusCode: 200,
  responseBody: {'result': 'ok'},
  durationMs: 250,
);
```

Headers and bodies accept `Map`, `List`, or `String` — they are formatted automatically.

### Step 5: Add app logs

```dart
Phantom.logInfo('User logged in', tag: 'Auth');
Phantom.logWarning('Retrying request', tag: 'Network');
Phantom.logError('Request failed', tag: 'Network');

// Or with an explicit level:
Phantom.log(PhantomLogLevel.info, 'User logged in', tag: 'Auth');
```

### Step 6 (optional): Register configs

```dart
Phantom.registerConfig('API URL', key: 'api_url', defaultValue: 'https://api.example.com');
Phantom.registerConfig('Debug Mode', key: 'debug', defaultValue: 'false', type: PhantomConfigType.toggle);
Phantom.registerConfig('Environment', key: 'env', defaultValue: 'prod', type: PhantomConfigType.picker, options: ['dev', 'staging', 'prod']);

final url = await Phantom.config('api_url');
```

### Step 7 (optional): Register localizations

```dart
Phantom.registerLocalization(key: 'welcome', english: 'Welcome', spanish: 'Bienvenido', group: 'Home');
```

### Step 8 (optional): Mock interceptor

```dart
final mock = Phantom.mockResponse(method: 'GET', url: requestUrl);
if (mock != null) {
  // Serve mock.statusCode / mock.body instead of the real request.
  // The call is already recorded in the Network inspector, flagged MOCK.
  return;
}
```

Ship mocks with the app and merge them on startup:

```dart
await Phantom.loadMocksFromAsset('assets/mocks/staging.json');
```

## Complete API Reference

```dart
// Features & menu
Phantom.setFeatures([PhantomFeature.logs, ...]);
Phantom.enableAllFeatures();
Phantom.addCustomEntry(title:, icon:, action:);
Phantom.clearCustomEntries();

// Logging
Phantom.log(PhantomLogLevel.info/warning/error, message, tag: tag);
Phantom.logInfo(message, tag:);
Phantom.logWarning(message, tag:);
Phantom.logError(message, tag:);

// Network
Phantom.logRequest(method:, url:, headers:, body:);
Phantom.logResponse(url:, statusCode:, headers:, body:, durationMs:);
Phantom.logRequestError(url:, errorMessage:, statusCode:, headers:, durationMs:);
Phantom.updateResponseMetadata(url:, headers:, statusCode:);
Phantom.completeRequest(method:, url:, requestHeaders:, requestBody:, statusCode:, responseHeaders:, responseBody:, durationMs:);
Phantom.logExternalEntry(Map data, sourcePrefix:);

// Mocks
Phantom.mockResponse(method:, url:);        // (statusCode, body, headers)? — also logs the hit
Phantom.loadMocks();                        // reload persisted rules
Phantom.loadMocksFromAsset(assetPath);      // merge a bundled collection → count?
Phantom.loadMocksFromJson(jsonString);      // merge raw JSON → count?
Phantom.exportMocks(name:, description:);   // → JSON collection string
Phantom.mockRules;                          // List<PhantomMockRule>

// Config
Phantom.registerConfig(label, key:, defaultValue:, type:, options:, group:);
Phantom.config(key);                        // Future<String?>
Phantom.setConfig(key, value);              // null clears the override
Phantom.resetConfig(key);

// Localization
Phantom.registerLocalization(key:, english:, spanish:, group:);
Phantom.setLanguage(PhantomLanguage.english/spanish);
Phantom.currentLanguage;
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
- **PhantomNetworkLogger** — HTTP request/response capture with pending-request correlation, mock flagging, and error completion
- **PhantomMockInterceptor** — Path-based URL matching for mock responses (persisted via SharedPreferences), multi-response rules, collection import/export
- **PhantomConfig** — Key-value override system (persisted with `phantom_config_` prefix)
- **PhantomLocalizer** — Bilingual string management (English/Spanish)

### Key Patterns

- **State management**: Plain `ChangeNotifier` — no external state dependency
- **Theme**: `PhantomTheme` with Kodivex dark defaults via `PhantomThemeProvider` (InheritedWidget)
- **Overlay**: `PhantomOverlay` wraps the host app with a draggable floating button + internal `MaterialApp`
- **Menu**: driven by `PhantomFeature` + `Phantom.customEntries`, not hardcoded

### Mock matching rules

Patterns are matched against the URL **path**, not the full URL, so `/v1/users` is not accidentally satisfied by `?redirect=/v1/users`. A rule matches when its method (or `ANY`) and its active response's method both accept the request method. A hit is recorded in the Network inspector automatically — do not log it a second time from your HTTP layer.

### Dependencies

- `shared_preferences`, `package_info_plus`, `device_info_plus`
- `path_provider` (file browser, device storage stats)
- `url_launcher` (deep link tester)
- `share_plus` (exporting logs / network / mocks)
- `file_picker` (importing mock collections)

### Known platform gaps vs phantom-ios

- Device Info reports the app's own storage usage per directory rather than device-wide free/total disk: Dart exposes no cross-platform API for the latter.
- Memory reports `ProcessInfo.currentRss` / `maxRss` instead of iOS's `phys_footprint`.
