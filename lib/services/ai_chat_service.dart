import 'openrouter_service.dart';
import 'huggingface_service.dart';

/// Single entry point your UI calls. Tries OpenRouter first (which itself
/// tries several free models before giving up), and only reaches for
/// Hugging Face if OpenRouter is entirely unreachable. This is the layer
/// that makes "provider returned error" invisible to your users.
class AiChatService {
  AiChatService({
    required String openRouterApiKey,
    required String huggingFaceApiToken,
  })  : _openRouter = OpenRouterService(apiKey: openRouterApiKey),
        _huggingFace = HuggingFaceService(apiToken: huggingFaceApiToken);

  final OpenRouterService _openRouter;
  final HuggingFaceService _huggingFace;

  Future<String> sendMessage({
    required String userMessage,
    List<Map<String, String>> history = const [],
  }) async {
    try {
      final result = await _openRouter.sendMessage(
        userMessage: userMessage,
        history: history,
      );
      return result.content;
      // If you want to show which model answered, use result.modelUsed
      // instead of discarding it here.
    } on OpenRouterAllModelsFailedException {
      // Every free OpenRouter model failed — fall back to Hugging Face.
      return _huggingFace.sendMessage(
        userMessage: userMessage,
        history: history,
      );
    }
    // Note: a _FatalError from OpenRouter (bad API key) is rethrown as a
    // plain Exception and intentionally NOT caught here, since falling
    // back won't fix a misconfigured key — you'll want that surfaced.
  }
}
