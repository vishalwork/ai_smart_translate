## 1.0.0

* Initial release
* `.tr` String extension with debounced batch queue
* AI provider chain: Gemini, Groq, OpenRouter, Mistral
* Auto fallback on rate-limit (429)
* SQLite offline cache
* TranslationScope widget for automatic UI rebuilds
* `AiSmartTranslate` facade for easy access


## 1.0.1

* Google Cloud Translate API added as fallback option
* Minor improvement and code fixes
* `trContent` / `trContentOf(context)` for runtime translation



## 1.0.2

* Minor improvement and code fixes

## 1.0.3

* `dont` parameter added to `trOf`, `trContentOf` — preserves specified substrings (names, dates, etc.) from being translated
* `trWith(dont: [...])` method added as context-free alternative to `.tr` getter with skip support
* `trContentWith(dont: [...])` method added as context-free alternative to `.trContent` getter with skip support          