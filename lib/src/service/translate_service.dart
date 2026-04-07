import 'dart:async';
import 'dart:developer';

import 'package:shared_preferences/shared_preferences.dart';

import '../cache/translation_cache.dart';
import '../config/translate_config.dart';
import '../providers/ai_provider_chain.dart';

/// Core translation service.
/// Use via [AiSmartTranslate] (the public facade).
class TranslateService {
  TranslateService._();
  static final TranslateService instance = TranslateService._();

  // ─── State ────────────────────────────────────────────────────────────────

  String _currentLang = 'en';
  bool _initialized = false;

  /// In-memory cache for current session (cleared on language change).
  final Map<String, String> _mem = {};

  // ─── Streams ──────────────────────────────────────────────────────────────

  final _langController = StreamController<String>.broadcast();
  final _updateController = StreamController<void>.broadcast();

  /// Emits new language code on language change.
  Stream<String> get languageStream => _langController.stream;

  /// Emits whenever new translations are cached (triggers .tr rebuild).
  Stream<void> get onUpdate => _updateController.stream;

  // ─── .tr queue (debounced batch → SQLite cached) ─────────────────────────

  final Set<String> _pending = {};
  Timer? _debounce;

  // ─── .trContent queue (debounced batch → memory only, no SQLite) ──────────

  final Set<String> _contentPending = {};      // plain text items
  final Set<String> _htmlContentPending = {};  // HTML items (translated node-by-node)
  Timer? _contentDebounce;

  // ─── Public ───────────────────────────────────────────────────────────────

  String get currentLanguage => _currentLang;
  bool get isSourceLang => _currentLang == TranslateConfig.sourceLang;

  Future<void> init({String appName = 'Flutter App'}) async {
    if (_initialized) return;
    await TranslationCache.instance.init();
    final prefs = await SharedPreferences.getInstance();
    _currentLang =
        prefs.getString(TranslateConfig.langPrefKey) ?? TranslateConfig.sourceLang;
    AiProviderChain.instance.initialize(appName: appName);
    _initialized = true;
    log('[AiSmartTranslate] Ready. Language: $_currentLang',
        name: 'AiSmartTranslate');
  }

  // ─── .tr (sync) ───────────────────────────────────────────────────────────

  /// Called by the `.tr` extension. Returns cached value instantly.
  /// If not cached → queues for batch translation → UI rebuilds via stream.
  String getSync(String text) {
    if (!_initialized || isSourceLang || text.trim().isEmpty) return text;
    final cached = _mem[text];
    if (cached != null) return cached;
    _queueForTranslation(text);
    return text;
  }

  void _queueForTranslation(String text) {
    _pending.add(text);
    _debounce?.cancel();
    _debounce = Timer(TranslateConfig.trDebounce, _processPending);
  }

  Future<void> _processPending() async {
    if (_pending.isEmpty) return;
    final batch = _pending.toList();
    _pending.clear();
    final result = await _translateBatch(batch);
    if (result.isNotEmpty) {
      _mem.addAll(result);
      _updateController.add(null);
    }
  }

  /// Like [getSync] but preserves [dont] substrings unchanged.
  /// Replaces each with a unique placeholder, translates, then restores.
  String getSyncWithDont(String text, List<String> dont) {
    if (!_initialized || isSourceLang || text.trim().isEmpty) return text;

    // Filter out blank entries to avoid replacing empty strings.
    final parts = dont.where((s) => s.isNotEmpty).toList();
    if (parts.isEmpty) return getSync(text);

    // Build placeholder map: e.g. {{__TR0__}} → "John"
    final placeholders = <String, String>{};
    String modified = text;
    for (var i = 0; i < parts.length; i++) {
      final placeholder = '{{__TR${i}__}}';
      placeholders[placeholder] = parts[i];
      modified = modified.replaceAll(parts[i], placeholder);
    }

    final translated = getSync(modified);

    // Restore original substrings
    String result = translated;
    for (final entry in placeholders.entries) {
      result = result.replaceAll(entry.key, entry.value);
    }
    return result;
  }

  // ─── .trContent (sync) ────────────────────────────────────────────────────

  /// Called by `.trContent` / `.trContentOf`. Memory-only — never saved to SQLite.
  /// - Plain text → translated directly.
  /// - HTML → original returned immediately (formatting intact), text nodes
  ///   translated in background, translated HTML returned on rebuild.
  String getContentSync(String text) {
    if (!_initialized || isSourceLang || text.trim().isEmpty) return text;

    final cached = _mem[text];
    if (cached != null) return cached;

    log('[AiSmartTranslate] trContent queued: "${text.substring(0, text.length.clamp(0, 40))}..."',
        name: 'AiSmartTranslate');

    if (_htmlTagRegex.hasMatch(text)) {
      _htmlContentPending.add(text);
    } else {
      _contentPending.add(text);
    }
    _contentDebounce?.cancel();
    _contentDebounce =
        Timer(TranslateConfig.trDebounce, _processContentPending);

    return text;
  }

  static final _htmlTagRegex = RegExp(r'<[^>]+>');

  // Extracts visible text nodes from HTML (text between tags).
  static List<String> _extractTextNodes(String html) {
    final regex = RegExp(r'>([^<]+)<');
    return regex
        .allMatches(html)
        .map((m) => m.group(1)!.trim())
        .where((t) => t.isNotEmpty)
        .toList();
  }

  // Re-injects translated text nodes back into original HTML structure.
  static String _injectTranslations(
      String html, Map<String, String> translations) {
    return html.replaceAllMapped(RegExp(r'>([^<]+)<'), (match) {
      final node = match.group(1)!.trim();
      final translated = translations[node];
      if (translated != null && translated != node) {
        return match.group(0)!.replaceFirst(node, translated);
      }
      return match.group(0)!;
    });
  }

  Future<void> _processContentPending() async {
    final plainBatch = _contentPending.toList();
    final htmlBatch = _htmlContentPending.toList();
    _contentPending.clear();
    _htmlContentPending.clear();

    // ── Plain text ────────────────────────────────────────────────────────
    if (plainBatch.isNotEmpty) {
      final chunks = _chunk(plainBatch, TranslateConfig.chunkSize);
      for (var i = 0; i < chunks.length; i++) {
        final result = await AiProviderChain.instance.translate(
          texts: chunks[i],
          targetLang: _currentLang,
        );
        _mem.addAll(result);
        if (i < chunks.length - 1) {
          await Future.delayed(TranslateConfig.chunkDelay);
        }
      }
    }

    // ── HTML: extract text nodes → translate → re-inject ──────────────────
    if (htmlBatch.isNotEmpty) {
      // Collect all unique text nodes across all HTML items
      final nodeToHtmls = <String, List<String>>{}; // node → which htmls use it
      for (final html in htmlBatch) {
        for (final node in _extractTextNodes(html)) {
          nodeToHtmls.putIfAbsent(node, () => []).add(html);
        }
      }

      final uniqueNodes = nodeToHtmls.keys.toList();
      final nodeTranslations = <String, String>{};

      final chunks = _chunk(uniqueNodes, TranslateConfig.chunkSize);
      for (var i = 0; i < chunks.length; i++) {
        final result = await AiProviderChain.instance.translate(
          texts: chunks[i],
          targetLang: _currentLang,
        );
        nodeTranslations.addAll(result);
        if (i < chunks.length - 1) {
          await Future.delayed(TranslateConfig.chunkDelay);
        }
      }

      // Re-inject translations into each HTML string
      for (final html in htmlBatch) {
        _mem[html] = _injectTranslations(html, nodeTranslations);
      }
    }

    if (plainBatch.isNotEmpty || htmlBatch.isNotEmpty) {
      _updateController.add(null); // triggers rebuild
    }
  }

  /// Like [getContentSync] but preserves [dont] substrings unchanged.
  String getContentSyncWithDont(String text, List<String> dont) {
    if (!_initialized || isSourceLang || text.trim().isEmpty) return text;

    final parts = dont.where((s) => s.isNotEmpty).toList();
    if (parts.isEmpty) return getContentSync(text);

    final placeholders = <String, String>{};
    String modified = text;
    for (var i = 0; i < parts.length; i++) {
      final placeholder = '{{__TR${i}__}}';
      placeholders[placeholder] = parts[i];
      modified = modified.replaceAll(parts[i], placeholder);
    }

    final translated = getContentSync(modified);

    String result = translated;
    for (final entry in placeholders.entries) {
      result = result.replaceAll(entry.key, entry.value);
    }
    return result;
  }

  // ─── Async translate ──────────────────────────────────────────────────────

  /// Awaitable single translation.
  Future<String> translate(String text) async {
    if (!_initialized || isSourceLang || text.trim().isEmpty) return text;

    final cached = _mem[text];
    if (cached != null) return cached;

    final result = await _translateBatch([text]);
    return result[text] ?? text;
  }

  /// Awaitable batch translation.
  Future<Map<String, String>> translateBatch(List<String> texts) async {
    if (texts.isEmpty || isSourceLang) {
      return {for (final t in texts) t: t};
    }
    return _translateBatch(texts);
  }

  /// Translate dynamic content (API data, post body, comments, etc.).
  /// Does NOT cache — avoids DB bloat from ever-changing user content.
  Future<String> translateContent(String content) async {
    if (!_initialized || isSourceLang || content.trim().isEmpty) return content;

    // Check memory cache only (session-scoped, not persisted to SQLite)
    final memCached = _mem[content];
    if (memCached != null) return memCached;

    final result = await AiProviderChain.instance.translate(
      texts: [content],
      targetLang: _currentLang,
    );
    final translated = result[content] ?? content;

    // Store in memory only (cleared on language change / app restart)
    _mem[content] = translated;
    return translated;
  }

  // ─── Language ─────────────────────────────────────────────────────────────

  Future<void> changeLanguage(String langCode,
      {bool clearCache = false}) async {
    _assertInit();
    if (_currentLang == langCode) return;

    if (clearCache) await TranslationCache.instance.clearLanguage(_currentLang);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(TranslateConfig.langPrefKey, langCode);

    _currentLang = langCode;
    _mem.clear();
    _pending.clear();
    _contentPending.clear();
    _htmlContentPending.clear();
    _langController.add(langCode);
  }

  // ─── Cache utils ──────────────────────────────────────────────────────────

  Future<void> clearCache(String lang) async {
    await TranslationCache.instance.clearLanguage(lang);
    if (lang == _currentLang) _mem.clear();
  }

  Future<int> cachedCount(String lang) =>
      TranslationCache.instance.count(lang);

  Future<List<String>> cachedLanguages() =>
      TranslationCache.instance.cachedLanguages();

  /// Returns status of all AI providers.
  List<Map<String, dynamic>> get providerStatus =>
      AiProviderChain.instance.status;

  String? get activeProvider => AiProviderChain.instance.activeProvider;

  // ─── Internal ─────────────────────────────────────────────────────────────

  Future<Map<String, String>> _translateBatch(List<String> texts) async {
    // 1. Check SQLite cache
    final cached = await TranslationCache.instance.getBatch(texts, _currentLang);

    // 2. Find missing
    final missing = texts.where((t) => !cached.containsKey(t)).toList();

    if (missing.isNotEmpty) {
      // 3. Chunk and call AI chain
      final translated = <String, String>{};
      final chunks = _chunk(missing, TranslateConfig.chunkSize);

      for (var i = 0; i < chunks.length; i++) {
        final result = await AiProviderChain.instance.translate(
          texts: chunks[i],
          targetLang: _currentLang,
        );
        translated.addAll(result);

        if (i < chunks.length - 1) {
          await Future.delayed(TranslateConfig.chunkDelay);
        }
      }

      // 4. Save to SQLite + memory
      await TranslationCache.instance.saveAll(translated, _currentLang);
      _mem.addAll(translated);
      cached.addAll(translated);
    }

    return {for (final t in texts) t: cached[t] ?? t};
  }

  List<List<T>> _chunk<T>(List<T> list, int size) {
    final chunks = <List<T>>[];
    for (var i = 0; i < list.length; i += size) {
      chunks.add(list.sublist(
          i, (i + size) > list.length ? list.length : (i + size)));
    }
    return chunks;
  }

  void _assertInit() {
    assert(_initialized,
        'AiSmartTranslate not initialized. Call AiSmartTranslate.init() first.');
  }

  void dispose() {
    _langController.close();
    _updateController.close();
    _debounce?.cancel();
  }
}
