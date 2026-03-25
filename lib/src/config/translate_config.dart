/// Configuration for ai_smart_translate.
/// Set API keys before calling [AiSmartTranslate.init].
class TranslateConfig {
  TranslateConfig._();

  // ─── API Keys ─────────────────────────────────────────────────────────────
  // Set at least one. Providers with empty keys are skipped.

  /// Gemini 2.0 Flash — Free: 15 RPM · 1M tokens/day
  /// Get key → https://aistudio.google.com
  static String geminiKey = '';

  /// Groq (Llama 3.1) — Free: 30 RPM · 500K tokens/day
  /// Get key → https://console.groq.com
  static String groqKey = '';

  /// OpenRouter — Free models, no credit card
  /// Get key → https://openrouter.ai
  static String openRouterKey = '';

  /// Mistral AI — Free tier
  /// Get key → https://console.mistral.ai
  static String mistralKey = '';

  /// Google Translate — deterministic fallback (non-AI)
  /// Uses translate-pa.googleapis.com/v1/translateHtml
  /// Get key → https://console.cloud.google.com (enable "Cloud Translation API")
  static String googleTranslateKey = '';

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
