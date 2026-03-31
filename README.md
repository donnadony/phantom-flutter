# Phantom Flutter

A cross-platform debug toolkit for Flutter apps. Inspect logs, network requests, mock responses, config overrides, device info, SharedPreferences, and localization — all from a floating debug button.

[![Flutter](https://img.shields.io/badge/Flutter-3.29%2B-blue)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.9%2B-blue)](https://dart.dev)
[![License](https://img.shields.io/badge/License-MIT-green)](LICENSE)

## Features

- **Logs** — App-level logging with levels (info, warning, error) and tag filtering
- **Network Inspector** — Capture and inspect HTTP requests/responses with JSON tree viewer
- **cURL Export** — Copy any network request as a ready-to-paste cURL command
- **Mock Services** — Intercept network requests and return mock responses at runtime
- **Configuration** — Key-value override system with text, toggle, and picker types
- **Device Info** — View app version, device model, OS version, screen size
- **SharedPreferences Viewer** — Browse, edit, add, and delete stored preferences
- **Localization** — Bilingual string management (English/Spanish) with language switching

## Installation

Add to your `pubspec.yaml`:

```yaml
dependencies:
  phantom_flutter:
    git:
      url: https://github.com/donnadony/phantom-flutter.git
```

## Quick Start

### 1. Wrap your app

```dart
import 'package:phantom_flutter/phantom_flutter.dart';

void main() {
  runApp(
    PhantomOverlay(
      child: MaterialApp(
        home: MyHomePage(),
      ),
    ),
  );
}
```

A floating purple debug button appears on screen. Tap it to open the Phantom debug panel.

### 2. Log messages

```dart
Phantom.log(PhantomLogLevel.info, 'User logged in', tag: 'Auth');
Phantom.log(PhantomLogLevel.warning, 'Cache expired', tag: 'Cache');
Phantom.log(PhantomLogLevel.error, 'Failed to fetch data', tag: 'Network');
```

### 3. Log network requests

#### Manual logging

```dart
// Log request
Phantom.logRequest(
  method: 'GET',
  url: 'https://api.example.com/users',
  headers: 'Authorization: Bearer token123',
);

// Log response (correlates with pending request by URL)
Phantom.logResponse(
  url: 'https://api.example.com/users',
  statusCode: 200,
  headers: 'Content-Type: application/json',
  body: '{"users": [...]}',
);
```

#### One-shot logging (request + response together)

```dart
Phantom.completeRequest(
  method: 'POST',
  url: 'https://api.example.com/login',
  requestHeaders: 'Content-Type: application/json',
  requestBody: '{"email": "user@example.com"}',
  statusCode: 200,
  responseHeaders: 'Content-Type: application/json',
  responseBody: '{"token": "abc123"}',
  durationMs: 250,
);
```

#### With dart:io HttpClient

```dart
final client = HttpClient();
final request = await client.getUrl(Uri.parse(url));

Phantom.logRequest(method: 'GET', url: url);

final response = await request.close();
final body = await response.transform(utf8.decoder).join();

Phantom.logResponse(
  url: url,
  statusCode: response.statusCode,
  body: body,
);
```

#### External entries (WebViews, platform channels)

```dart
Phantom.logExternalEntry({
  'url': 'https://api.example.com/data',
  'method': 'GET',
  'statusCode': 200,
  'responseBody': '{"result": "ok"}',
  'durationMs': 150,
}, sourcePrefix: '[WebView]');
```

### 4. Mock Services

Intercept network requests and return mock responses at runtime. Rules persist across app launches via SharedPreferences.

```dart
// Check for mock before making a real request
final mock = Phantom.mockResponse(method: 'GET', url: requestUrl);
if (mock != null) {
  // Use mock.statusCode, mock.body, mock.headers
  return;
}

// Proceed with real request...
```

You can also create mocks from the UI:
- Open **Network** → tap a request → tap **"Mock this"**
- Open **Mock Services** → tap **"+"** to create manually

### 5. Configuration

Register configurable values that can be overridden at runtime from the debug panel.

```dart
// Text input
Phantom.registerConfig(
  'API Base URL',
  key: 'api_base_url',
  defaultValue: 'https://api.example.com',
);

// Toggle (boolean)
Phantom.registerConfig(
  'Enable Cache',
  key: 'enable_cache',
  defaultValue: 'true',
  type: PhantomConfigType.toggle,
  group: 'Performance',
);

// Picker (enum)
Phantom.registerConfig(
  'Log Level',
  key: 'log_level',
  defaultValue: 'info',
  type: PhantomConfigType.picker,
  options: ['debug', 'info', 'warning', 'error'],
);

// Read effective value (override or default)
final baseUrl = await Phantom.config('api_base_url');
```

Config entries can be organized into **groups** — when multiple groups exist, a filter appears automatically in the UI.

### 6. Localization

Manage bilingual strings (English/Spanish) with a language switcher in the debug panel.

```dart
// Register entries
Phantom.registerLocalization(
  key: 'welcome',
  english: 'Welcome',
  spanish: 'Bienvenido',
  group: 'Home',
);

Phantom.registerLocalization(
  key: 'login',
  english: 'Log In',
  spanish: 'Iniciar Sesión',
  group: 'Auth',
);

// Get localized string (uses current language)
final text = Phantom.localized('welcome'); // "Welcome" or "Bienvenido"

// Switch language
await Phantom.setLanguage(PhantomLanguage.spanish);
```

### 7. Device Info

No setup required — accessible from the Phantom debug panel. Shows:

| Section | Fields |
|---------|--------|
| **App** | App Name, Package Name, Version, Build Number |
| **Device** | Device Name, Model, OS Version, Physical Device |
| **Screen** | Screen Size, Pixel Ratio, Physical Pixels |

Tap any row to copy its value to the clipboard.

### 8. SharedPreferences Viewer

No setup required — accessible from the Phantom debug panel.

- **Search** by key or value
- **Filter**: All, App (excludes system keys), Phantom (`phantom_` prefixed)
- **Type badges**: String, Int, Double, Bool, List
- **Inline toggle** for Bool entries
- **Tap to edit** String values
- **Long-press** for context menu: Copy Key, Copy Value, Delete
- **Add** new entries via the "+" button
- **Clear** filtered entries

### 9. Open Phantom programmatically

```dart
// Open via floating button (default)
PhantomOverlay(child: MyApp())

// Open programmatically (requires Navigator context)
Phantom.show(context);

// Disable floating button
PhantomOverlay(
  showFloatingButton: false,
  child: MyApp(),
)
```

## Theme

Phantom ships with a dark theme (Kodivex) by default. Customize colors:

```dart
PhantomOverlay(
  theme: PhantomTheme(
    background: Color(0xFF1A1A2E),
    surface: Color(0xFF16213E),
    primary: Color(0xFFE94560),
  ),
  child: MyApp(),
)

// Or set globally
Phantom.setTheme(PhantomTheme(
  background: Color(0xFF1A1A2E),
  // ... override only what you need
));
```

## Architecture

```
phantom_flutter/
  lib/
    phantom_flutter.dart              # Single public import
    src/
      phantom_main.dart               # Phantom static API
      phantom_overlay.dart            # Floating button wrapper
      core/
        models/                       # Data models
        phantom_logger.dart           # ChangeNotifier singleton
        phantom_network_logger.dart   # Request/response correlation
        phantom_mock_interceptor.dart # URL pattern matching + persistence
        phantom_config.dart           # Key-value overrides + persistence
        phantom_localizer.dart        # Bilingual string management
      adapters/
        dio_interceptor.dart          # Optional Dio adapter
      theme/
        phantom_theme.dart            # Kodivex dark theme
      ui/
        phantom_view.dart             # Root navigation
        logs/                         # Log list + filters
        network/                      # Network list + detail + JSON tree
        mock/                         # Mock rules list + editor
        config/                       # Config overrides
        device_info/                  # App + device info
        shared_prefs/                 # SharedPreferences viewer
        localization/                 # Language switcher + entries
      utils/
        curl_builder.dart             # cURL command generator
        json_formatter.dart           # JSON pretty printer
  example/                            # Demo app
  test/                               # Unit tests
```

## Dependencies

| Package | Purpose |
|---------|---------|
| `shared_preferences` | Persist mock rules, config overrides, language |
| `package_info_plus` | App version, build number, package name |
| `device_info_plus` | Device model, OS version |

All are first-party Flutter community packages. No third-party dependencies.

## License

MIT
