import 'openrouter_service.dart';

class AiChatService {
  final String openRouterApiKey;
  final String? defaultModelOverride;

  AiChatService({
    required this.openRouterApiKey,
    String? modelOverride,
  }) : defaultModelOverride = modelOverride;

  Future<String> sendMessage({
    required String userMessage,
    List<Map<String, String>> history = const [],
    String? imageBase64,
    String? modelOverride,
    String? apiKeyOverride,
  }) async {
    // Build messages array for Claude's service
    final messages = <Map<String, dynamic>>[];

    // System prompt
    messages.add({
      'role': 'system',
      'content': 'You are AURA (Autonomous Universal Reasoning Assistant), a helpful AI. '
          'When asked who created you, reply "I was made by withshafan." '
          'Respond in the same language as the user (English / Roman Urdu / Urdu).',
    });

    // History
    for (final turn in history) {
      messages.add({
        'role': turn['role'] ?? 'user',
        'content': turn['content'] ?? '',
      });
    }

    // Current user message (with possible image)
    final userContent = imageBase64 != null && imageBase64.isNotEmpty
        ? [
            {'type': 'text', 'text': userMessage},
            {'type': 'image_url', 'image_url': {'url': imageBase64}},
          ]
        : userMessage;

    messages.add({'role': 'user', 'content': userContent});

    final effectiveApiKey = apiKeyOverride ?? openRouterApiKey;
    final effectiveModel = modelOverride ?? defaultModelOverride;

    final service = OpenRouterService(
      apiKey: effectiveApiKey,
      models: effectiveModel != null ? [effectiveModel] : null,
    );

    // Call Claude's robust service
    try {
      return await service.sendMessage(messages);
    } on OpenRouterException catch (e) {
      return e.isAllModelsBusy
          ? '⚠️ All models are busy right now. Please wait a moment and try again.'
          : '❌ ${e.message}';
    }
  }
}
