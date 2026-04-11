import 'translation_cache_backend.dart';

/// Stub — should never be reached at runtime.
final TranslationCacheBackend defaultCacheBackend = _StubBackend();

class _StubBackend implements TranslationCacheBackend {
  @override
  Future<void> init() => throw UnsupportedError('No cache backend for this platform');
  @override
  Future<Map<String, String>> getBatch(List<String> texts, String targetLang) =>
      throw UnsupportedError('No cache backend for this platform');
  @override
  Future<void> saveAll(Map<String, String> translations, String targetLang) =>
      throw UnsupportedError('No cache backend for this platform');
  @override
  Future<void> clearLanguage(String lang) =>
      throw UnsupportedError('No cache backend for this platform');
  @override
  Future<void> clearAll() =>
      throw UnsupportedError('No cache backend for this platform');
  @override
  Future<int> count(String lang) =>
      throw UnsupportedError('No cache backend for this platform');
  @override
  Future<List<String>> cachedLanguages() =>
      throw UnsupportedError('No cache backend for this platform');
}
