/// Type of a built-in or custom AI provider.
enum ProviderType { gemini, groq, openRouter, googleTranslate, custom }

/// Configuration for a single AI provider.
///
/// Pass an ordered list to [AiSmartTranslate.init] via the `providers`
/// parameter to fully control the fallback chain and model selection.
///
/// ```dart
/// await AiSmartTranslate.init(
///   providers: [
///     ProviderConfig.groq(apiKey: '...'),
///     ProviderConfig.openRouter(apiKey: '...', model: 'mistralai/mistral-7b-instruct:free'),
///     ProviderConfig.gemini(apiKey: '...'),
///     ProviderConfig.googleTranslate(apiKey: '...'),
///     ProviderConfig.custom(
///       name: 'MyAI',
///       apiKey: '...',
///       endpoint: 'https://api.myai.com/v1/chat/completions',
///       model: 'my-model-v1',
///     ),
///   ],
/// );
/// ```
class ProviderConfig {
  const ProviderConfig._({
    required this.type,
    required this.apiKey,
    this.model,
    this.endpoint,
    this.customName,
    this.appName,
  });

  final ProviderType type;
  final String apiKey;

  /// Model override. If null, the provider's default model is used.
  final String? model;

  /// Endpoint URL — required for [ProviderConfig.custom].
  final String? endpoint;

  /// Display name — required for [ProviderConfig.custom].
  final String? customName;

  /// App name sent in OpenRouter requests (X-Title header).
  final String? appName;

  // ─── Built-in factories ──────────────────────────────────────────────────

  /// Gemini AI (Google) — Free: 15 RPM · 1M tokens/day
  /// Default model: gemini-2.0-flash-lite
  factory ProviderConfig.gemini({required String apiKey}) =>
      ProviderConfig._(type: ProviderType.gemini, apiKey: apiKey);

  /// Groq (Llama) — Free: 30 RPM · 500K tokens/day
  /// Default model: llama-3.1-8b-instant
  factory ProviderConfig.groq({required String apiKey, String? model}) =>
      ProviderConfig._(type: ProviderType.groq, apiKey: apiKey, model: model);

  /// OpenRouter — Free models available
  /// Default model: openrouter/auto:free
  factory ProviderConfig.openRouter({
    required String apiKey,
    String? model,
    String? appName,
  }) =>
      ProviderConfig._(
        type: ProviderType.openRouter,
        apiKey: apiKey,
        model: model,
        appName: appName,
      );

  /// Google Cloud Translation API — deterministic, non-AI fallback
  factory ProviderConfig.googleTranslate({required String apiKey}) =>
      ProviderConfig._(
          type: ProviderType.googleTranslate, apiKey: apiKey);

  // ─── Custom factory ───────────────────────────────────────────────────────

  /// Any OpenAI-compatible endpoint (e.g. Ollama, Together AI, custom LLM).
  ///
  /// The request format used:
  /// ```json
  /// {
  ///   "model": "<model>",
  ///   "messages": [{"role": "user", "content": "<prompt>"}],
  ///   "temperature": 0.1
  /// }
  /// ```
  /// Authorization: Bearer <apiKey>
  factory ProviderConfig.custom({
    required String name,
    required String apiKey,
    required String endpoint,
    required String model,
  }) =>
      ProviderConfig._(
        type: ProviderType.custom,
        apiKey: apiKey,
        model: model,
        endpoint: endpoint,
        customName: name,
      );
}
