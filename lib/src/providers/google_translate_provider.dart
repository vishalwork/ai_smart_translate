import 'dart:convert';
import 'dart:developer';
import 'package:http/http.dart' as http;
import '../config/translate_config.dart';
import 'ai_provider.dart';

/// Google Cloud Translation API v2 — deterministic fallback.
///
/// Get a key → https://console.cloud.google.com
/// Enable "Cloud Translation API" in your project before use.
class GoogleTranslateProvider extends AiProvider {
  GoogleTranslateProvider({required super.apiKey});

  @override
  String get name => 'Google Translate';

  static const _url =
      'https://translation.googleapis.com/language/translate/v2';

  @override
  Future<Map<String, String>> translateChunk({
    required List<String> texts,
    required String langName,
    String langCode = '',
  }) async {
    final source = TranslateConfig.sourceLang;
    final target = langCode.isNotEmpty ? langCode : source;

    // POST https://translation.googleapis.com/language/translate/v2?key=KEY
    // Body: { "q": [...], "source": "en", "target": "hi", "format": "text" }
    final res = await http.post(
      Uri.parse('$_url?key=$apiKey'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'q': texts,
        'source': source,
        'target': target,
        'format': 'text',
      }),
    );

    if (res.statusCode == 429) {
      markRateLimited();
      throw RateLimitException(name);
    }
    if (res.statusCode != 200) {
      log('[$name] Error ${res.statusCode}: ${res.body}',
          name: 'AiSmartTranslate');
      throw Exception('$name: ${res.statusCode} ${res.body}');
    }

    // Response: { "data": { "translations": [{"translatedText": "..."}] } }
    final decoded = jsonDecode(res.body) as Map<String, dynamic>;
    final translations = (decoded['data']['translations'] as List)
        .map((e) => (e as Map<String, dynamic>)['translatedText'] as String)
        .toList();

    final result = <String, String>{};
    for (var i = 0; i < texts.length; i++) {
      result[texts[i]] = i < translations.length ? translations[i] : texts[i];
    }
    return result;
  }
}
