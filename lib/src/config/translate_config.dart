import 'provider_config.dart';

/// Configuration for ai_smart_translate.
/// Set API keys before calling [AiSmartTranslate.init].
class TranslateConfig {
  TranslateConfig._();

  // ─── Provider chain ───────────────────────────────────────────────────────

  /// Ordered list of providers. First available = first tried.
  /// Set via [AiSmartTranslate.init] — do not set directly.
  static List<ProviderConfig> providers = [];

  // ─── Settings ─────────────────────────────────────────────────────────────

  /// Language the app strings are written in.
  static String sourceLang = 'en';

  /// Texts per AI API call. Keep ≤ 50.
  static int chunkSize = 50;

  /// Delay between chunks (respects 15 RPM free limit).
  static Duration chunkDelay = const Duration(milliseconds: 700);

  /// Debounce before processing .tr() queue (batches rapid calls).
  static Duration trDebounce = const Duration(milliseconds: 150);

  /// SQLite database name.
  static String dbName = 'ai_smart_translate.db';

  /// SharedPreferences key for persisting selected language.
  static String langPrefKey = 'ai_smart_translate_lang';

  // ─── Language names ───────────────────────────────────────────────────────

  static const Map<String, String> languageNames = {
    'en': 'English', 'hi': 'Hindi', 'ur': 'Urdu', 'ar': 'Arabic',
    'fr': 'French', 'es': 'Spanish', 'de': 'German',
    'zh': 'Chinese (Simplified)', 'ja': 'Japanese', 'ko': 'Korean',
    'pt': 'Portuguese', 'ru': 'Russian', 'bn': 'Bengali',
    'ta': 'Tamil', 'te': 'Telugu', 'mr': 'Marathi',
    'gu': 'Gujarati', 'kn': 'Kannada', 'ml': 'Malayalam', 'pa': 'Punjabi',
  };

  static String languageName(String code) =>
      languageNames[code] ?? code.toUpperCase();
}
