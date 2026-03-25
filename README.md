# ai_smart_translate

AI-powered Flutter localization with automatic provider fallback, offline caching, and zero JSON maintenance.

## Features

- **`.tr` extension** — `'Hello'.tr` on any String
- **AI-powered** — no JSON files, no manual translations
- **Auto fallback** — Gemini → Groq → OpenRouter → Mistral
- **Offline cache** — SQLite, translate once, use forever
- **Dynamic content** — translate API data on demand
- **Free** — all providers have generous free tiers

## Quick Start

### 1. Add dependency

```yaml
dependencies:
  ai_smart_translate: ^1.0.0
```

### 2. Initialize in `main.dart`

```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await AiSmartTranslate.init(
    geminiKey: 'YOUR_GEMINI_KEY',   // https://aistudio.google.com
    groqKey: 'YOUR_GROQ_KEY',       // optional fallback
    openRouterKey: 'YOUR_OR_KEY',   // optional fallback
    mistralKey: 'YOUR_MISTRAL_KEY', // optional fallback
  );

  runApp(
    const TranslationScope(child: MyApp()),
  );
}
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

| Provider | Free Tier | Priority |
|---|---|---|
| Gemini 1.5 Flash | 15 RPM · 1M tokens/day | 1st |
| Groq (Llama 3.1) | 30 RPM · 500K tokens/day | 2nd |
| OpenRouter | Free models | 3rd |
| Mistral | Free tier | 4th |

On HTTP 429 (rate limit), the current provider enters a 2-minute cooldown and the next provider is tried automatically.

## Supported Languages

`en` `hi` `ur` `ar` `fr` `es` `de` `zh` `ja` `ko` `pt` `ru` `bn` `ta` `te` `mr` `gu` `kn` `ml` `pa`

## API Reference

```dart
// Init
AiSmartTranslate.init(geminiKey: '...', groqKey: '...');

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
AiSmartTranslate.activeProvider          // "Gemini Flash"
AiSmartTranslate.providerStatus          // List of provider statuses
```
