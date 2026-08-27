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
