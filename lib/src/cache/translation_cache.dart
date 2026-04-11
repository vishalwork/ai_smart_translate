import 'cache_backend_stub.dart'
    if (dart.library.html) 'web_cache_backend.dart'
    if (dart.library.io) 'sqflite_cache_backend.dart';
import 'translation_cache_backend.dart';

/// Platform-aware translation cache.
///
/// - Android / iOS → SQLite via sqflite
/// - Linux / Windows / macOS → SQLite via sqflite_common_ffi
/// - Web → SharedPreferences
///
/// Inject a custom backend via [TranslationCache.setBackend] before [init].
class TranslationCache {
  TranslationCache._();
  static final TranslationCache instance = TranslationCache._();

  late TranslationCacheBackend _backend = defaultCacheBackend;

  /// Override the default backend before calling [init].
  /// Use this to inject a custom storage implementation.
  void setBackend(TranslationCacheBackend backend) => _backend = backend;

  Future<void> init() => _backend.init();

  Future<Map<String, String>> getBatch(List<String> texts, String targetLang) =>
      _backend.getBatch(texts, targetLang);

  Future<void> saveAll(Map<String, String> translations, String targetLang) =>
      _backend.saveAll(translations, targetLang);

  Future<void> clearLanguage(String lang) => _backend.clearLanguage(lang);

  Future<void> clearAll() => _backend.clearAll();

  Future<int> count(String lang) => _backend.count(lang);

  Future<List<String>> cachedLanguages() => _backend.cachedLanguages();
}
