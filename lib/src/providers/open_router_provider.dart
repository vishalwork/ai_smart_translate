import 'dart:convert';
import 'ai_provider.dart';

/// OpenRouter — Free models available (no credit card needed)
class OpenRouterProvider extends AiProvider {
  OpenRouterProvider({required super.apiKey, this.appName = 'Flutter App'});

  final String appName;

  @override
  String get name => 'OpenRouter';

  static const _url = 'https://openrouter.ai/api/v1/chat/completions';
  static const _model = 'meta-llama/llama-3.2-3b-instruct:free';

  @override
  Future<Map<String, String>> translateChunk({
    required List<String> texts,
    required String langName,
    String langCode = '',
  }) async {
    final res = await httpPost(
      Uri.parse(_url),
      {
        'model': _model,
        'messages': [
          {'role': 'user', 'content': buildPrompt(texts, langName)}
        ],
        'temperature': 0.1,
        'response_format': {'type': 'json_object'},
      },
      headers: {
        'Authorization': 'Bearer $apiKey',
        'X-Title': appName,
      },
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
