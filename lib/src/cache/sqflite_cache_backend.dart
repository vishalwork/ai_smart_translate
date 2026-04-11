import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../config/translate_config.dart';
import 'translation_cache_backend.dart';

/// Default export used by conditional import in [TranslationCache].
final TranslationCacheBackend defaultCacheBackend = SqfliteCacheBackend();

/// SQLite-backed cache for mobile (Android/iOS) and desktop (Linux/Windows/macOS).
/// Uses sqflite_common_ffi on desktop, native sqflite on mobile.
///
/// Existing users are unaffected — same DB name and schema.
class SqfliteCacheBackend implements TranslationCacheBackend {
  Database? _db;

  @override
  Future<void> init() async {
    if (_db != null) return;

    // Desktop platforms need FFI initialization.
    if (Platform.isLinux || Platform.isWindows || Platform.isMacOS) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }

    final dbPath = p.join(await getDatabasesPath(), TranslateConfig.dbName);
    _db = await openDatabase(dbPath, version: 1, onCreate: (db, _) async {
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
      await db.execute('CREATE INDEX idx_lang ON translations(target_lang)');
    });
  }

  Database get _d {
    assert(_db != null, 'SqfliteCacheBackend not initialized');
    return _db!;
  }

  @override
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

  @override
  Future<void> saveAll(
      Map<String, String> translations, String targetLang) async {
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

  @override
  Future<void> clearLanguage(String lang) async =>
      _d.delete('translations', where: 'target_lang = ?', whereArgs: [lang]);

  @override
  Future<void> clearAll() async => _d.delete('translations');

  @override
  Future<int> count(String lang) async {
    final r = await _d.rawQuery(
        'SELECT COUNT(*) as c FROM translations WHERE target_lang = ?', [lang]);
    return (r.first['c'] as int?) ?? 0;
  }

  @override
  Future<List<String>> cachedLanguages() async {
    final r =
        await _d.rawQuery('SELECT DISTINCT target_lang FROM translations');
    return r.map((e) => e['target_lang'] as String).toList();
  }

  static String _hash(String text) {
    var h = 5381;
    for (var i = 0; i < text.length; i++) {
      h = ((h << 5) + h + text.codeUnitAt(i)) & 0x7FFFFFFF;
    }
    return h.toRadixString(16).padLeft(7, '0');
  }
}
