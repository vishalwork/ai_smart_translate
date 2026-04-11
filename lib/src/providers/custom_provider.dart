import 'dart:convert';
import 'ai_provider.dart';

/// Generic OpenAI-compatible AI provider.
/// Configured via [ProviderConfig.custom].
class CustomAiProvider extends AiProvider {
  CustomAiProvider({
    required super.apiKey,
    required this.providerName,
    required this.endpoint,
    required this.model,
  });

  final String providerName;
  final String endpoint;
  final String model;

  @override
  String get name => providerName;

  @override
  Future<Map<String, String>> translateChunk({
    required List<String> texts,
    required String langName,
    String langCode = '',
  }) async {
    final res = await httpPost(
      Uri.parse(endpoint),
      {
        'model': model,
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
