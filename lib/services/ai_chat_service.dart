import 'gemini_free_service.dart';
import 'openrouter_service.dart';

class AiChatService {
  final String geminiApiKey;
  final String openRouterApiKey;
  final String? defaultModelOverride;

  late final GeminiFreeService _gemini;

  AiChatService({
    required this.geminiApiKey,
    required this.openRouterApiKey,
    String? modelOverride,
  })  : defaultModelOverride = modelOverride,
        _gemini = GeminiFreeService(apiKey: geminiApiKey);

  Future<String> sendMessage({
    required String userMessage,
    List<Map<String, String>> history = const [],
    String? imageBase64,
    String? modelOverride,
    String? apiKeyOverride,
  }) async {
    // 1. Try Gemini first (unlimited free tier)
    try {
      if (geminiApiKey.isNotEmpty) {
        return await _gemini.sendMessage(
          userMessage: userMessage,
          history: history,
          imageBase64: imageBase64,
        );
      }
    } catch (e) {
      // If Gemini fails, we will fall back to OpenRouter
      // Print the error in debug mode
      print('Gemini failed: $e. Falling back to OpenRouter...');
    }

    // 2. Fallback to OpenRouter
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
          ? '⚠️ All AI services are temporarily unavailable. Please try again.'
          : '❌ ${e.message}';
    } catch (_) {
      return '⚠️ All AI services are temporarily unavailable. Please try again.';
    }
  }
}
