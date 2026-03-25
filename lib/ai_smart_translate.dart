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

export 'src/config/translate_config.dart';
export 'src/extensions/string_extension.dart';
export 'src/widgets/translation_scope.dart';

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
  /// Priority: Gemini → Groq → OpenRouter → Mistral → Google Translate
  ///
  /// ```dart
  /// await AiSmartTranslate.init(
  ///   geminiKey: Env.geminiKey,            // free: 1M tokens/day
  ///   groqKey: Env.groqKey,               // optional AI fallback
  ///   googleTranslateKey: Env.gtKey,      // deterministic final fallback
  /// );
  /// ```
  static Future<void> init({
    String geminiKey = '',
    String groqKey = '',
    String openRouterKey = '',
    String mistralKey = '',
    String googleTranslateKey = '',
    String sourceLang = 'en',
    String appName = 'Flutter App',
  }) async {
    TranslateConfig.geminiKey = geminiKey;
    TranslateConfig.groqKey = groqKey;
    TranslateConfig.openRouterKey = openRouterKey;
    TranslateConfig.mistralKey = mistralKey;
    TranslateConfig.googleTranslateKey = googleTranslateKey;
    TranslateConfig.sourceLang = sourceLang;

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
