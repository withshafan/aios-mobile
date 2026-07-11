import '../config/api_keys.dart';
import 'openrouter_service.dart';

class AiChatService {
  late final OpenRouterService _openRouter;

  AiChatService({
    required String openRouterApiKey,
    String? modelOverride,
  }) {
    _openRouter = OpenRouterService(
      apiKey: openRouterApiKey,
      model: modelOverride ?? 'tencent/hy3',
    );
  }

  Future<String> sendMessage({
    required String userMessage,
    List<Map<String, String>> history = const [],
    String? imageBase64,
    String? modelOverride,
  }) async {
    final response = await _openRouter.sendMessage(
      userMessage: userMessage,
      history: history,
      imageBase64: imageBase64,
      modelOverride: modelOverride,
    );
    return response.text;   // unwrap the ChatResponse
  }
}
