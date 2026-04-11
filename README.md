# ai_smart_translate

AI-powered Flutter localization with automatic provider fallback, offline caching, and zero JSON maintenance.

## Features

- **`.tr` extension** — `'Hello'.tr` on any String
- **AI-powered** — no JSON files, no manual translations
- **Auto fallback** — Groq → OpenRouter → Gemini → Google Translate
- **Custom order** — define your own provider priority via `providers` list
- **Custom models** — override default model per provider
- **Custom providers** — plug in any OpenAI-compatible endpoint
- **Offline cache** — SQLite (mobile/desktop), SharedPreferences (web), translate once, use forever
- **Web + Desktop support** — works on Android, iOS, Web, Linux, Windows, macOS
- **Dynamic content** — translate API data on demand
- **Low cost** — Groq and OpenRouter offer free tiers; Gemini requires a Google AI Studio key (free quota available); Google Translate is a paid API

## Quick Start

### 1. Add dependency

```yaml
dependencies:
  ai_smart_translate: ^1.1.0
```

### 2. Initialize in `main.dart`

**Simple (named keys, default order):**

```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await AiSmartTranslate.init(
    groqKey: 'YOUR_GROQ_KEY',             // 1st — free: 30 RPM
    openRouterKey: 'YOUR_OR_KEY',         // 2nd — free models
    geminiKey: 'YOUR_GEMINI_KEY',         // 3rd — free: 1M tokens/day
    googleTranslateKey: 'YOUR_GT_KEY',    // 4th — paid, deterministic
  );

  runApp(const TranslationScope(child: MyApp()));
}
```

**Custom order + custom model:**

```dart
await AiSmartTranslate.init(
  providers: [
    ProviderConfig.groq(apiKey: '...', model: 'llama-3.3-70b-versatile'),
    ProviderConfig.openRouter(apiKey: '...', model: 'mistralai/mistral-7b-instruct:free'),
    ProviderConfig.gemini(apiKey: '...'),
    ProviderConfig.googleTranslate(apiKey: '...'),
  ],
);
```

**Custom OpenAI-compatible endpoint:**

```dart
await AiSmartTranslate.init(
  providers: [
    ProviderConfig.custom(
      name: 'MyLLM',
      apiKey: 'YOUR_KEY',
      endpoint: 'https://api.myai.com/v1/chat/completions',
      model: 'my-model-v1',
    ),
    ProviderConfig.gemini(apiKey: '...'), // fallback
  ],
);
```

### 3. Use `.tr` on any string

```dart
Text('Hello'.tr)
Text('Welcome, {name}'.tr)   // placeholders preserved
Text('Settings'.tr)
```

### 4. Change language

```dart
await AiSmartTranslate.changeLanguage('hi'); // Hindi
await AiSmartTranslate.changeLanguage('ar'); // Arabic
```

## Translate API / Dynamic Content

```dart
// On a "Translate" button tap:
final translated = await AiSmartTranslate.translateContent(post.body);
setState(() => _displayText = translated);
```

## Provider Fallback

Default priority (can be overridden via `providers` list):

| Provider | Tier | Limits | Default Priority |
|---|---|---|---|
| Groq (Llama) | Free | 30 RPM · 500K tokens/day | 1st |
| OpenRouter | Free models available | Varies by model | 2nd |
| Gemini 2.0 Flash Lite | Free quota (AI Studio key) | 30 RPM · 1,500 req/day · 1M TPM | 3rd |
| Google Translate | Paid | $20 per 1M characters | 4th |

> **Gemini note:** Free quota is available via [Google AI Studio](https://aistudio.google.com) key only.
> Google Cloud API keys require billing to be enabled.

On HTTP 429 (rate limit), the current provider enters a cooldown and the next provider is tried automatically.

## ProviderConfig Reference

| Factory | Required | Optional |
|---|---|---|
| `ProviderConfig.gemini` | `apiKey` | — |
| `ProviderConfig.groq` | `apiKey` | `model` |
| `ProviderConfig.openRouter` | `apiKey` | `model`, `appName` |
| `ProviderConfig.googleTranslate` | `apiKey` | — |
| `ProviderConfig.custom` | `name`, `apiKey`, `endpoint`, `model` | — |

Custom providers use OpenAI-compatible format with `Authorization: Bearer <apiKey>`.

## Supported Languages

`en` `hi` `ur` `ar` `fr` `es` `de` `zh` `ja` `ko` `pt` `ru` `bn` `ta` `te` `mr` `gu` `kn` `ml` `pa`

## API Reference

```dart
// Init — simple
AiSmartTranslate.init(geminiKey: '...', groqKey: '...');

// Init — custom order
AiSmartTranslate.init(providers: [ProviderConfig.groq(apiKey: '...'), ...]);

// Language
AiSmartTranslate.currentLanguage         // "hi"
AiSmartTranslate.languageStream          // Stream<String>
AiSmartTranslate.changeLanguage('hi');

// Translate
AiSmartTranslate.translate('Hello');                    // Future<String>
AiSmartTranslate.translateBatch(['Hi', 'Bye']);         // Future<Map>
AiSmartTranslate.translateContent(apiText);             // Future<String>

// Cache
AiSmartTranslate.cachedCount('hi');      // Future<int>
AiSmartTranslate.cachedLanguages();      // Future<List<String>>
AiSmartTranslate.clearCache('hi');

// Debug
AiSmartTranslate.activeProvider          // "Groq"
AiSmartTranslate.providerStatus          // List of provider statuses
```
