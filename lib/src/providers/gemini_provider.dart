import 'dart:convert';
import 'dart:developer';
import 'package:http/http.dart' as http;
import 'ai_provider.dart';

/// Gemini 1.5 Flash — Free: 15 RPM · 1M tokens/day
class GeminiProvider extends AiProvider {
  GeminiProvider({required super.apiKey});

  @override
  String get name => 'Gemini 2.0 Flash Lite';

  static const _url =
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash-lite:generateContent';

  @override
  Future<Map<String, String>> translateChunk({
    required List<String> texts,
    required String langName,
    String langCode = '',
  }) async {
    final res = await http.post(
      Uri.parse('$_url?key=$apiKey'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'contents': [
          {
            'parts': [{'text': buildPrompt(texts, langName)}]
          }
        ],
        'generationConfig': {
          'temperature': 0.1,
          'responseMimeType': 'application/json',
        },
      }),
    );

    if (res.statusCode == 429) {
      // Parse retryDelay from response if available, else use default cooldown
      try {
        final body = jsonDecode(res.body) as Map<String, dynamic>;
        final details = body['error']?['details'] as List?;
        if (details != null) {
          for (final d in details) {
            final delay = d['retryDelay'] as String?;
            if (delay != null) {
              final seconds = int.tryParse(delay.replaceAll('s', '')) ?? 120;
              markRateLimitedFor(Duration(seconds: seconds + 5));
              log('[$name] Rate limited. Retry in ${seconds}s',
                  name: 'AiSmartTranslate');
              throw RateLimitException(name);
            }
          }
        }
      } catch (e) {
        if (e is RateLimitException) rethrow;
      }
      markRateLimited();
      throw RateLimitException(name);
    }
    if (res.statusCode != 200) {
      throw Exception('$name: ${res.statusCode} ${res.body}');
    }
    if (res.statusCode != 200) {
      throw Exception('$name: ${res.statusCode} ${res.body}');
    }

    final decoded = jsonDecode(res.body) as Map<String, dynamic>;
    final text =
        decoded['candidates'][0]['content']['parts'][0]['text'] as String;
    return parseResponse(text, texts);
  }
}
