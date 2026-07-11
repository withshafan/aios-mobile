import 'universal_ai_service.dart';

class AiChatService {
  final UniversalAiService _universal = UniversalAiService();

  AiChatService({
    String? geminiApiKey,
    String? openRouterApiKey,
    String? modelOverride,
  });

  Future<String> sendMessage({
    required String userMessage,
    List<Map<String, String>> history = const [],
    String? imageBase64,
    String? modelOverride,
    String? apiKeyOverride,
  }) async {
    return await _universal.sendMessage(
      userMessage: userMessage,
      history: history,
      imageBase64: imageBase64,
    );
  }
}
