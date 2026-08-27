## 0.0.5

### Added

* **The floating button can be hidden from the panel.** A row at the foot of the menu takes it off the screen — useful when it covers the very thing being inspected, or for a clean screenshot. With it hidden, shaking the device reopens Phantom, and the same row puts the button back.

  The hidden state is deliberately not persisted: it lasts the session, so restarting the app is a guaranteed way back on every platform, including desktop and web where there is no accelerometer to shake. The row says so, since the gesture leaves no trace on screen to discover.

### Dependencies

* Adds `sensors_plus` for shake detection.

## 0.0.4

### Fixed

* **An open keyboard made the sheet unusable.** The panel is bottom-anchored, but its nested `MaterialApp` builds its `MediaQuery` from the `FlutterView`, so the keyboard inset was applied inside a box that never moved: on a 400x800 screen with a 336pt keyboard the panel's contents collapsed to zero height. Every text field the panel owns — Configuration entries, the SharedPreferences editor, mock response bodies — was reachable only by tapping a field that then erased the page it lived on. The sheet now sits on top of the keyboard and caps its height to what is left.
* **The status bar padded the panel from the inside.** The same inherited `MediaQuery` made the panel's `AppBar` render 47pt taller than it should, on every page it pushes — a third of the visible chrome on a half-height sheet.
* **At full height the sheet went edge to edge**, putting its grabber and rounded corners under the notch and its contents beneath the system clock. Its tallest detent now stops 10pt below the status bar, leaving the presenting screen visible above it the way an iOS sheet does.
* **Drag-to-close stopped working below the default `minSize`.** The drag clamped to a hardcoded floor of `0.1` while the close threshold followed `minSize`, so any `minSize` under `0.1` removed the dismiss gesture entirely. The floor now derives from `minSize`.
* `PhantomSheet` now asserts `initialSize >= minSize`. Passing `PhantomOverlay(initialSheetSize: 0.2)` previously opened the sheet already below its close threshold, where a two-pixel drag dismissed it.
* `PhantomOverlay` now asserts `initialSheetSize` is a fraction between 0 and 1. At 0 the panel had no height but its scrim still swallowed every tap.
* `PhantomSheet` resets its drag state before calling `onClose`, so callers that hide the sheet rather than unmounting it get it back in a usable state.

### Documentation

* `PhantomOverlay.presentation` documents that it governs the floating button only: `Phantom.show(context)` always pushes the panel full screen on the host navigator.

## 0.0.3

### Added

* **Sheet presentation** — `PhantomOverlay(presentation: PhantomPresentation.sheet)` makes the panel rise from the bottom at half the screen, draggable by its handle to full height and dismissed by dragging it down or tapping outside. It leaves the app visible behind it, so what the screen shows can be compared against what the request returned. `fullScreen` remains the default, so existing callers are unaffected.
* `initialSheetSize` to control the height the sheet opens at, which doubles as its lower snap point.
* `buttonIcon` to override the floating button's glyph.
* `PhantomPresentation`, `PhantomSheet`, `PhantomView`, `PhantomViewBody` and `PhantomDioInterceptorBase` are now exported.

## 0.0.2

Feature parity pass with [phantom-ios](https://github.com/donnadony/phantom-ios).

### Added

* **File Browser** — browse the app sandbox (documents, support, cache, temp, and platform-specific roots), with sizes, modified dates, extension icons, JSON/text preview, and delete.
* **Deep Link Tester** — open URL schemes and universal links, with a persisted history of the last 50 attempts and their success state.
* **Configurable menu** — `PhantomFeature` plus `Phantom.setFeatures()` / `Phantom.enableAllFeatures()` control which modules appear; `Phantom.addCustomEntry()` appends your own rows.
* **Export / Import** — share app logs and network captures as JSON, export mock rules as a `PhantomMockCollection`, and import collections from a file. The collection format is interchangeable with phantom-ios.
* **Multi-response mock rules** — a rule can hold several named responses with a selectable active one, each with its own method, status code, and body.
* **Storage and Memory sections** in Device Info.
* **Typed SharedPreferences editing** — add and edit entries as String, Int, Double, or Bool.
* New APIs: `Phantom.logInfo/logWarning/logError`, `logRequestError`, `updateResponseMetadata`, `setConfig`, `resetConfig`, `currentLanguage`, `loadMocksFromAsset`, `loadMocksFromJson`, `exportMocks`, `mockRules`.
* Group headers in Configuration when viewing all groups.

### Changed

* **Mock matching now runs against the URL path**, not the full URL, and also validates the active response's method. A pattern like `/v1/admin` no longer matches `?redirect=/v1/admin`.
* **Mock hits are logged automatically** — `Phantom.mockResponse()` records the intercepted call in the Network inspector flagged as MOCK. HTTP layers should no longer log it themselves.
* **Mock import merges** by URL pattern + method instead of appending duplicates.
* `PhantomLogLevel` exposes canonical `label` (INFO/WARN/ERROR) and `emoji`.
* `isMock` is a real field on `PhantomNetworkItem` instead of being inferred from a header sentinel.
* cURL export escapes quotes correctly and accepts headers stored as JSON.
* `PhantomDioInterceptorBase` logs the request before checking for a mock, so a mocked call keeps its request headers and body.

### Fixed

* Configuration text fields lost the caret while typing, because the controller was rebuilt on every frame.
* Configuration showed stored overrides as empty on first render, because the fields were seeded before the values were read.
* The Network detail Viewer/Text toggle was hardcoded to Viewer and could not be switched.
* The Network detail screen offered "Mock this" even when a rule already covered the endpoint, creating duplicates; it now offers "Edit Mock".
* Failed requests logged through the Dio adapter stayed PENDING forever.

## 0.0.1

* Initial release.
