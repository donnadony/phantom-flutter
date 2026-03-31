# CLAUDE.md

This file provides guidance to Claude Code when working with code in this repository.

## Project Overview

Phantom Flutter is a cross-platform debug toolkit for Flutter apps. It provides a floating debug button overlay that opens a full debug panel with logs, network inspector, mock services, configuration, device info, SharedPreferences viewer, and localization management.

## Build & Test Commands

```bash
# Get dependencies
flutter pub get

# Run analyzer
flutter analyze

# Run tests
flutter test

# Run a single test
flutter test --name "PhantomLogger"

# Run example app
cd example && flutter run
```

## Architecture

This is a Flutter package (Flutter 3.29+, Dart 3.9+) with a single `phantom_flutter` library target.

### Public API Surface

`Phantom` (class) is the sole public entry point — all features are accessed via static methods. It delegates to five singleton core managers:

- **PhantomLogger** — App-level logging with levels (info/warning/error) and tags. Stores `PhantomLogItem` entries in-memory, newest first.
- **PhantomNetworkLogger** — Captures HTTP request/response pairs. Uses a pending-request tracking system (keyed by method+url+body) to correlate `logRequest` and `logResponse` calls.
- **PhantomMockInterceptor** — URL pattern matching to intercept requests and return mock responses. Rules persist via SharedPreferences.
- **PhantomConfig** — Generic key-value override system. Host app registers config entries with defaults; overrides persist in SharedPreferences with `phantom_config_` prefix.
- **PhantomLocalizer** — Bilingual string management (English/Spanish) with group filtering. Current language persists in SharedPreferences.

All five core managers are `ChangeNotifier`s with `notifyListeners()`, enabling reactive UI updates via `ListenableBuilder` or `addListener`.

### UI Layer

Flutter widgets under `ui/` provide the debug panel:
- `PhantomView` — Root navigation with menu items for all features
- Feature-specific pages: `PhantomLogsPage`, `PhantomNetworkPage` (with `PhantomNetworkDetailPage` and `PhantomJsonTreeView`), `PhantomMockListPage`/`PhantomMockEditPage`, `PhantomConfigPage`, `PhantomDeviceInfoPage`, `PhantomSharedPrefsPage`, `PhantomLocalizationPage`

### Key Patterns

- **State management**: Plain `ChangeNotifier` — no external state management dependency (no Bloc/Riverpod/Provider). The package must not pollute the host app's dependency tree.
- **Request correlation**: Network logger matches responses to pending requests using a composite key (`method|url|body`) with fallback to URL-only matching.
- **Theme**: `PhantomTheme` data class with Kodivex dark defaults, propagated via `PhantomThemeProvider` (InheritedWidget).
- **Overlay**: `PhantomOverlay` wraps the host app and adds a draggable floating button + its own `MaterialApp` for Phantom's navigation stack.

### Dependencies

Only 3 external packages, all first-party Flutter community:
- `shared_preferences` — persist mock rules, config, language
- `package_info_plus` — app version info
- `device_info_plus` — device model info
