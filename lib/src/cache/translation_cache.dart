import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';
import '../config/translate_config.dart';

/// SQLite-backed translation cache.
class TranslationCache {
  TranslationCache._();
  static final TranslationCache instance = TranslationCache._();

  Database? _db;

  Future<void> init() async {
    if (_db != null) return;
    final path = p.join(await getDatabasesPath(), TranslateConfig.dbName);
    _db = await openDatabase(path, version: 1, onCreate: (db, _) async {
      await db.execute('''
        CREATE TABLE translations (
          source_hash   TEXT NOT NULL,
          target_lang   TEXT NOT NULL,
          source_text   TEXT NOT NULL,
          translated    TEXT NOT NULL,
          created_at    INTEGER NOT NULL,
          PRIMARY KEY (source_hash, target_lang)
        )
      ''');
      await db.execute(
          'CREATE INDEX idx_lang ON translations(target_lang)');
    });
  }

  Database get _d {
    assert(_db != null, 'TranslationCache not initialized');
    return _db!;
  }

  // ─── Read ─────────────────────────────────────────────────────────────────

  Future<String?> get(String sourceText, String targetLang) async {
    final rows = await _d.query(
      'translations',
      columns: ['translated'],
      where: 'source_hash = ? AND target_lang = ?',
      whereArgs: [_hash(sourceText), targetLang],
      limit: 1,
    );
    return rows.isEmpty ? null : rows.first['translated'] as String;
  }

  /// Returns Map<sourceText, translated> for cached entries only.
  Future<Map<String, String>> getBatch(
      List<String> texts, String targetLang) async {
    if (texts.isEmpty) return {};
    final hashToSource = {for (final t in texts) _hash(t): t};
    final ph = List.filled(hashToSource.length, '?').join(',');
    final rows = await _d.rawQuery(
      'SELECT source_hash, translated FROM translations '
      'WHERE target_lang = ? AND source_hash IN ($ph)',
      [targetLang, ...hashToSource.keys],
    );
    final result = <String, String>{};
    for (final r in rows) {
      final src = hashToSource[r['source_hash']];
      if (src != null) result[src] = r['translated'] as String;
    }
    return result;
  }

  // ─── Write ────────────────────────────────────────────────────────────────

  Future<void> saveAll(Map<String, String> translations, String targetLang) async {
    if (translations.isEmpty) return;
    final now = DateTime.now().millisecondsSinceEpoch;
    final batch = _d.batch();
    translations.forEach((src, translated) {
      batch.insert(
        'translations',
        {
          'source_hash': _hash(src),
          'target_lang': targetLang,
          'source_text': src,
          'translated': translated,
          'created_at': now,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    });
    await batch.commit(noResult: true);
  }

  // ─── Delete ───────────────────────────────────────────────────────────────

  Future<void> clearLanguage(String lang) async {
    await _d.delete('translations', where: 'target_lang = ?', whereArgs: [lang]);
  }

  Future<void> clearAll() async => _d.delete('translations');

  // ─── Meta ─────────────────────────────────────────────────────────────────

  Future<int> count(String lang) async {
    final r = await _d.rawQuery(
        'SELECT COUNT(*) as c FROM translations WHERE target_lang = ?', [lang]);
    return (r.first['c'] as int?) ?? 0;
  }

  Future<List<String>> cachedLanguages() async {
    final r = await _d
        .rawQuery('SELECT DISTINCT target_lang FROM translations');
    return r.map((e) => e['target_lang'] as String).toList();
  }

  // ─── Hash ─────────────────────────────────────────────────────────────────

  static String _hash(String text) {
    var h = 5381;
    for (var i = 0; i < text.length; i++) {
      h = ((h << 5) + h + text.codeUnitAt(i)) & 0x7FFFFFFF;
    }
    return h.toRadixString(16).padLeft(7, '0');
  }
}
