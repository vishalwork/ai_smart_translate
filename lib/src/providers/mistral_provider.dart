import 'dart:convert';
import 'ai_provider.dart';

/// Mistral AI — Free tier available
class MistralProvider extends AiProvider {
  MistralProvider({required super.apiKey});

  @override
  String get name => 'Mistral';

  static const _url = 'https://api.mistral.ai/v1/chat/completions';

  @override
  Future<Map<String, String>> translateChunk({
    required List<String> texts,
    required String langName,
    String langCode = '',
  }) async {
    final res = await httpPost(
      Uri.parse(_url),
      {
        'model': 'mistral-small-latest',
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
