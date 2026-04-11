/// Abstract cache backend for ai_smart_translate.
///
/// Implement this to provide a custom storage backend and pass it to
/// [AiSmartTranslate.init] via the `cacheBackend` parameter.
abstract class TranslationCacheBackend {
  Future<void> init();

  /// Returns Map<sourceText, translated> for cached entries only.
  Future<Map<String, String>> getBatch(List<String> texts, String targetLang);

  /// Persist a batch of translations.
  Future<void> saveAll(Map<String, String> translations, String targetLang);

  /// Delete all cached translations for [lang].
  Future<void> clearLanguage(String lang);

  /// Delete all cached translations across all languages.
  Future<void> clearAll();

  /// Count of cached translations for [lang].
  Future<int> count(String lang);

  /// All language codes that have at least one cached translation.
  Future<List<String>> cachedLanguages();
}
