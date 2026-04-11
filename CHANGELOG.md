## 1.1.0

* Web support — `WebCacheBackend` added using SharedPreferences (IndexedDB on web)
* Linux / Windows / macOS desktop support — `SqfliteCacheBackend` now uses `sqflite_common_ffi` on desktop platforms
* `TranslationCacheBackend` abstract class exported — implement custom storage backend
* `cacheBackend` parameter added to `AiSmartTranslate.init()` for custom backend injection
* **No migration required** — existing Android/iOS users unaffected, same SQLite DB and schema
* `ProviderConfig` class added — define provider order and models via `providers` list in `init()`
* Custom provider support — plug in any OpenAI-compatible endpoint via `ProviderConfig.custom`
* Model override — `ProviderConfig.groq` and `ProviderConfig.openRouter` now accept a `model` parameter
* Default fallback order changed: Groq → OpenRouter → Gemini → Google Translate (Gemini moved to 3rd)
* Mistral provider removed
* Improved error logging — Gemini 429 response body now logged for easier debugging

## 1.0.3

* `dont` parameter added to `trOf`, `trContentOf` — preserves specified substrings (names, dates, etc.) from being translated
* `trWith(dont: [...])` method added as context-free alternative to `.tr` getter with skip support
* `trContentWith(dont: [...])` method added as context-free alternative to `.trContent` getter with skip support

## 1.0.2

* Minor improvement and code fixes

## 1.0.1

* Google Cloud Translate API added as fallback option
* Minor improvement and code fixes
* `trContent` / `trContentOf(context)` for runtime translation

## 1.0.0

* Initial release
* `.tr` String extension with debounced batch queue
* AI provider chain: Gemini, Groq, OpenRouter
* Auto fallback on rate-limit (429)
* SQLite offline cache
* TranslationScope widget for automatic UI rebuilds
* `AiSmartTranslate` facade for easy access
