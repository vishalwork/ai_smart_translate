import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'translation_cache_backend.dart';

/// Default export used by conditional import in [TranslationCache].
final TranslationCacheBackend defaultCacheBackend = WebCacheBackend();

/// SharedPreferences-backed cache for web.
///
/// Key format: `_ast_v1_<lang>_<hash>` → translated text
/// Language index: `_ast_v1_langs` → JSON list of lang codes
class WebCacheBackend implements TranslationCacheBackend {
  SharedPreferences? _prefs;

  static const _prefix = '_ast_v1_';
  static const _langsKey = '_ast_v1_langs';

  @override
  Future<void> init() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  SharedPreferences get _p {
    assert(_prefs != null, 'WebCacheBackend not initialized');
    return _prefs!;
  }

  String _key(String lang, String hash) => '$_prefix${lang}_$hash';

  @override
  Future<Map<String, String>> getBatch(
      List<String> texts, String targetLang) async {
    final result = <String, String>{};
    for (final text in texts) {
      final val = _p.getString(_key(targetLang, _hash(text)));
      if (val != null) result[text] = val;
    }
    return result;
  }

  @override
  Future<void> saveAll(
      Map<String, String> translations, String targetLang) async {
    if (translations.isEmpty) return;
    for (final entry in translations.entries) {
      await _p.setString(_key(targetLang, _hash(entry.key)), entry.value);
    }
    await _trackLang(targetLang);
  }

  @override
  Future<void> clearLanguage(String lang) async {
    final keysToRemove =
        _p.getKeys().where((k) => k.startsWith('$_prefix${lang}_')).toList();
    for (final k in keysToRemove) {
      await _p.remove(k);
    }
    final langs = _readLangs()..remove(lang);
    await _p.setString(_langsKey, jsonEncode(langs));
  }

  @override
  Future<void> clearAll() async {
    final keysToRemove =
        _p.getKeys().where((k) => k.startsWith(_prefix)).toList();
    for (final k in keysToRemove) {
      await _p.remove(k);
    }
    await _p.remove(_langsKey);
  }

  @override
  Future<int> count(String lang) async {
    return _p.getKeys().where((k) => k.startsWith('$_prefix${lang}_')).length;
  }

  @override
  Future<List<String>> cachedLanguages() async => _readLangs();

  // ─── Helpers ──────────────────────────────────────────────────────────────

  List<String> _readLangs() {
    final raw = _p.getString(_langsKey);
    if (raw == null) return [];
    return (jsonDecode(raw) as List).cast<String>();
  }

  Future<void> _trackLang(String lang) async {
    final langs = _readLangs();
    if (!langs.contains(lang)) {
      langs.add(lang);
      await _p.setString(_langsKey, jsonEncode(langs));
    }
  }

  static String _hash(String text) {
    var h = 5381;
    for (var i = 0; i < text.length; i++) {
      h = ((h << 5) + h + text.codeUnitAt(i)) & 0x7FFFFFFF;
    }
    return h.toRadixString(16).padLeft(7, '0');
  }
}
