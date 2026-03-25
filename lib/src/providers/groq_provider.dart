import 'dart:convert';
import 'ai_provider.dart';

/// Groq (Llama 3.1) — Free: 30 RPM · 500K tokens/day
class GroqProvider extends AiProvider {
  GroqProvider({required super.apiKey});

  @override
  String get name => 'Groq';

  static const _url = 'https://api.groq.com/openai/v1/chat/completions';

  @override
  Future<Map<String, String>> translateChunk({
    required List<String> texts,
    required String langName,
    String langCode = '',
  }) async {
    final res = await httpPost(
      Uri.parse(_url),
      {
        'model': 'llama-3.1-8b-instant',
        'messages': [
          {'role': 'user', 'content': buildPrompt(texts, langName)}
        ],
        'temperature': 0.1,
        'response_format': {'type': 'json_object'},
      },
      headers: {'Authorization': 'Bearer $apiKey'},
    );

    if (res.statusCode == 429) {
      markRateLimited();
      throw RateLimitException(name);
    }
    if (res.statusCode != 200) {
      throw Exception('$name: ${res.statusCode} ${res.body}');
    }

    final decoded = jsonDecode(res.body) as Map<String, dynamic>;
    final content = decoded['choices'][0]['message']['content'] as String;
    return parseResponse(content, texts);
  }
}
