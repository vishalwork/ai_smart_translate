/// AI-powered Flutter translation with automatic provider fallback.
///
/// Quick start:
/// ```dart
/// // 1. init (once in main)
/// await AiSmartTranslate.init(geminiKey: 'YOUR_KEY');
///
/// // 2. wrap app
/// runApp(TranslationScope(child: MyApp()));
///
/// // 3. use .tr anywhere
/// Text('Hello'.tr)
///
/// // 4. change language
/// await AiSmartTranslate.changeLanguage('hi');
/// ```
library ai_smart_translate;

export 'src/cache/translation_cache_backend.dart';
export 'src/config/provider_config.dart';
export 'src/config/translate_config.dart';
export 'src/extensions/string_extension.dart';
export 'src/widgets/translation_scope.dart';

import 'src/cache/translation_cache.dart';
import 'src/cache/translation_cache_backend.dart';
import 'src/config/provider_config.dart';
import 'src/config/translate_config.dart';
import 'src/service/translate_service.dart';

/// Main entry point for ai_smart_translate.
class AiSmartTranslate {
  AiSmartTranslate._();

  // ─── Init ─────────────────────────────────────────────────────────────────

  /// Initialize the translation service. Call once in `main()`.
  ///
  /// Provide at least one API key. Providers with empty keys are skipped.
  /// On rate-limit, the next provider is tried automatically.
  ///
  /// Default priority: Groq → OpenRouter → Gemini → Google Translate
  ///
  /// **Simple usage** (named keys, default order):
  /// ```dart
  /// await AiSmartTranslate.init(
  ///   geminiKey: Env.geminiKey,
  ///   groqKey: Env.groqKey,
  ///   googleTranslateKey: Env.gtKey,
  /// );
  /// ```
  ///
  /// **Custom order + custom model** (use `providers` list):
  /// ```dart
  /// await AiSmartTranslate.init(
  ///   providers: [
  ///     ProviderConfig.groq(apiKey: Env.groqKey, model: 'llama-3.3-70b-versatile'),
  ///     ProviderConfig.openRouter(apiKey: Env.orKey, model: 'mistralai/mistral-7b-instruct:free'),
  ///     ProviderConfig.gemini(apiKey: Env.geminiKey),
  ///     ProviderConfig.googleTranslate(apiKey: Env.gtKey),
  ///     ProviderConfig.custom(
  ///       name: 'MyLLM',
  ///       apiKey: '...',
  ///       endpoint: 'https://api.myai.com/v1/chat/completions',
  ///       model: 'my-model-v1',
  ///     ),
  ///   ],
  /// );
  /// ```
  ///
  /// **Custom cache backend** (optional — auto-selected by default):
  /// ```dart
  /// await AiSmartTranslate.init(
  ///   geminiKey: '...',
  ///   cacheBackend: MyCustomCacheBackend(),
  /// );
  /// ```
  static Future<void> init({
    List<ProviderConfig>? providers,
    String geminiKey = '',
    String groqKey = '',
    String openRouterKey = '',
    String googleTranslateKey = '',
    String sourceLang = 'en',
    String appName = 'Flutter App',
    TranslationCacheBackend? cacheBackend,
  }) async {
    TranslateConfig.sourceLang = sourceLang;
    if (cacheBackend != null) {
      TranslationCache.instance.setBackend(cacheBackend);
    }

    if (providers != null) {
      TranslateConfig.providers = providers;
    } else {
      // Default order: Groq → OpenRouter → Gemini → Google Translate
      TranslateConfig.providers = [
        if (groqKey.isNotEmpty) ProviderConfig.groq(apiKey: groqKey),
        if (openRouterKey.isNotEmpty)
          ProviderConfig.openRouter(apiKey: openRouterKey, appName: appName),
        if (geminiKey.isNotEmpty) ProviderConfig.gemini(apiKey: geminiKey),
        if (googleTranslateKey.isNotEmpty)
          ProviderConfig.googleTranslate(apiKey: googleTranslateKey),
      ];
    }

    await TranslateService.instance.init(appName: appName);
  }

  // ─── Language ─────────────────────────────────────────────────────────────

  /// Currently active language code (e.g. "hi", "ar").
  static String get currentLanguage =>
      TranslateService.instance.currentLanguage;

  /// Stream that emits the new language code on every change.
  static Stream<String> get languageStream =>
      TranslateService.instance.languageStream;

  /// Change the active language.
  /// Pass [clearCache] = true to delete the old language's SQLite cache.
  static Future<void> changeLanguage(String langCode,
          {bool clearCache = false}) =>
      TranslateService.instance.changeLanguage(langCode,
          clearCache: clearCache);

  // ─── Translate ────────────────────────────────────────────────────────────

  /// Async single translation.
  static Future<String> translate(String text) =>
      TranslateService.instance.translate(text);

  /// Async batch translation. More efficient than multiple [translate] calls.
  static Future<Map<String, String>> translateBatch(List<String> texts) =>
      TranslateService.instance.translateBatch(texts);

  /// Translate user-generated/API content on demand (post body, bio, etc.).
  static Future<String> translateContent(String content) =>
      TranslateService.instance.translateContent(content);

  // ─── Cache ────────────────────────────────────────────────────────────────

  /// Number of cached translations for [lang].
  static Future<int> cachedCount(String lang) =>
      TranslateService.instance.cachedCount(lang);

  /// All language codes that have a local cache.
  static Future<List<String>> cachedLanguages() =>
      TranslateService.instance.cachedLanguages();

  /// Delete cache for [lang].
  static Future<void> clearCache(String lang) =>
      TranslateService.instance.clearCache(lang);

  // ─── Debug ────────────────────────────────────────────────────────────────

  /// Currently active AI provider name (e.g. "Gemini Flash").
  static String? get activeProvider =>
      TranslateService.instance.activeProvider;

  /// Status of all configured providers.
  static List<Map<String, dynamic>> get providerStatus =>
      TranslateService.instance.providerStatus;
}
