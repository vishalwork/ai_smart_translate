import 'dart:convert';
import 'package:http/http.dart' as http;

/// Base class for all AI translation providers.
abstract class AiProvider {
  AiProvider({required this.apiKey});

  final String apiKey;

  String get name;

  // ─── Rate limit ───────────────────────────────────────────────────────────

  DateTime? _unavailableUntil;
  Duration get cooldown => const Duration(minutes: 2);

  bool get isAvailable {
    if (apiKey.isEmpty) return false;
    if (_unavailableUntil == null) return true;
    return DateTime.now().isAfter(_unavailableUntil!);
  }

  void markRateLimited() =>
      _unavailableUntil = DateTime.now().add(cooldown);

  void markRateLimitedFor(Duration duration) =>
      _unavailableUntil = DateTime.now().add(duration);

  void reset() => _unavailableUntil = null;

  // ─── Translation ──────────────────────────────────────────────────────────

  /// Translate [texts] to [langName]. Returns Map<source, translated>.
  /// Must throw [RateLimitException] on HTTP 429.
  /// [langCode] is the BCP-47 code (e.g. "hi") — used by non-AI providers.
  Future<Map<String, String>> translateChunk({
    required List<String> texts,
    required String langName,
    String langCode = '',
  });

  // ─── Shared helpers ───────────────────────────────────────────────────────

  String buildPrompt(List<String> texts, String langName) => '''
Translate the following texts to $langName.
Rules:
- Return ONLY a valid JSON object.
- Each key is the EXACT original text; value is the translation.
- Keep placeholders exactly: {name}, {count}, %s, %d, \$var
- Do NOT translate proper nouns or brand names.
- No explanation, no markdown outside JSON.

Texts: ${jsonEncode(texts)}
Format: {"original": "translated"}
''';

  Map<String, String> parseResponse(String raw, List<String> originals) {
    try {
      final cleaned = raw.trim()
          .replaceAll(RegExp(r'^```json\s*', multiLine: true), '')
          .replaceAll(RegExp(r'^```\s*', multiLine: true), '')
          .replaceAll(RegExp(r'\s*```$', multiLine: true), '')
          .trim();
      final map = jsonDecode(cleaned) as Map<String, dynamic>;
      return map.map((k, v) => MapEntry(k, v.toString()));
    } catch (_) {
      return {for (final t in originals) t: t};
    }
  }

  Future<http.Response> httpPost(Uri uri, Map<String, dynamic> body,
      {Map<String, String>? headers}) {
    return http.post(
      uri,
      headers: {'Content-Type': 'application/json', ...?headers},
      body: jsonEncode(body),
    );
  }
}

class RateLimitException implements Exception {
  const RateLimitException(this.provider);
  final String provider;
  @override
  String toString() => 'RateLimitException[$provider]';
}
