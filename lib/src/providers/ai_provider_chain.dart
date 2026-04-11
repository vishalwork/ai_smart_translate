import 'dart:developer';
import '../config/provider_config.dart';
import '../config/translate_config.dart';
import 'ai_provider.dart';
import 'custom_provider.dart';
import 'gemini_provider.dart';
import 'google_translate_provider.dart';
import 'groq_provider.dart';
import 'open_router_provider.dart';

/// Manages a prioritized list of AI providers with automatic fallback.
///
/// Default order: Groq → OpenRouter → Gemini → Google Translate
/// On 429: provider enters cooldown, next is tried automatically.
class AiProviderChain {
  AiProviderChain._();
  static final AiProviderChain instance = AiProviderChain._();

  List<AiProvider> _providers = [];

  void initialize({String appName = 'Flutter App'}) {
    _providers = TranslateConfig.providers
        .where((c) => c.apiKey.isNotEmpty)
        .map((c) => _build(c, appName))
        .toList();

    log('[AiSmartTranslate] Providers: ${_providers.map((p) => p.name).join(' → ')}',
        name: 'AiSmartTranslate');
  }

  AiProvider _build(ProviderConfig c, String appName) {
    switch (c.type) {
      case ProviderType.gemini:
        return GeminiProvider(apiKey: c.apiKey);
      case ProviderType.groq:
        return GroqProvider(apiKey: c.apiKey, model: c.model);
      case ProviderType.openRouter:
        return OpenRouterProvider(
          apiKey: c.apiKey,
          model: c.model,
          appName: c.appName ?? appName,
        );
      case ProviderType.googleTranslate:
        return GoogleTranslateProvider(apiKey: c.apiKey);
      case ProviderType.custom:
        return CustomAiProvider(
          apiKey: c.apiKey,
          providerName: c.customName!,
          endpoint: c.endpoint!,
          model: c.model!,
        );
    }
  }

  Future<Map<String, String>> translate({
    required List<String> texts,
    required String targetLang,
  }) async {
    final langName = TranslateConfig.languageName(targetLang);

    for (final provider in _providers) {
      if (!provider.isAvailable) continue;

      try {
        final result = await provider.translateChunk(
          texts: texts,
          langName: langName,
          langCode: targetLang,
        );
        log('[AiSmartTranslate] ✅ ${provider.name} translated ${texts.length} strings',
            name: 'AiSmartTranslate');
        return result;
      } on RateLimitException {
        log('[AiSmartTranslate] ${provider.name} rate-limited → trying next',
            name: 'AiSmartTranslate');
        continue;
      } catch (e) {
        log('[AiSmartTranslate] ${provider.name} error: $e → trying next',
            name: 'AiSmartTranslate');
        continue;
      }
    }

    // All providers failed — return originals (graceful degradation)
    log('[AiSmartTranslate] All providers failed. Returning originals.',
        name: 'AiSmartTranslate');
    return {for (final t in texts) t: t};
  }

  String? get activeProvider {
    for (final p in _providers) {
      if (p.isAvailable) return p.name;
    }
    return null;
  }

  List<Map<String, dynamic>> get status => _providers
      .map((p) => {'name': p.name, 'available': p.isAvailable})
      .toList();

  void resetAll() {
    for (final p in _providers) {
      p.reset();
    }
  }
}
