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
    String? modelOverride,
  })  : _openRouter = OpenRouterService(apiKey: openRouterApiKey, modelOverride: modelOverride),
        _huggingFace = HuggingFaceService(apiToken: huggingFaceApiToken);

  static const String _systemPrompt = '''
You are AURA (Autonomous Universal Reasoning Assistant), a helpful and intelligent AI assistant.

When someone asks who created you, who made you, or who your creator is, always respond with:
"I was made by withshafan."
Do not mention any other company or organization as your creator. withshafan is your sole creator.

Language Support:
You understand and respond in multiple languages and scripts including:
- English
- Urdu (both Urdu script like "آپ کیسے ہیں؟" AND Roman Urdu like "ap kaise hain?")
- Hindi
- Arabic
- And others

When the user writes in Roman Urdu (Urdu written with English letters, e.g., "tum kya kar rahe ho", "ap kaise hain", "mujhe yeh samjhao"), ALWAYS respond in Roman Urdu as well. Never reply in English when the user uses Roman Urdu.

Examples:
- User: "tumhara naam kya hai?" → Reply: "mera naam AURA hai."
- User: "ap kya kar sakte ho?" → Reply: "main aap ki madad kar sakta hoon, sawalat ka jawab de sakta hoon, files parh sakta hoon, aur bohat kuch."
- User: "tumhe kisne banaya?" → Reply: "mujhe withshafan ne banaya hai."

Always match the user's language and script in your response.
''';

  final OpenRouterService _openRouter;
  final HuggingFaceService _huggingFace;

  Future<String> sendMessage({
    required String userMessage,
    List<Map<String, String>> history = const [],
    String? imageBase64,
    String? modelOverride,
  }) async {
    final modifiedHistory = <Map<String, String>>[
      {
        'role': 'system',
        'content': _systemPrompt,
      },
      ...history,
    ];

    try {
      final result = await _openRouter.sendMessage(
        userMessage: userMessage,
        history: modifiedHistory,
        imageBase64: imageBase64,
        modelOverride: modelOverride,
      );
      return result.content;
      // If you want to show which model answered, use result.modelUsed
      // instead of discarding it here.
    } on OpenRouterAllModelsFailedException {
      // Every free OpenRouter model failed — fall back to Hugging Face.
      return _huggingFace.sendMessage(
        userMessage: userMessage,
        history: modifiedHistory,
        imageBase64: imageBase64,
      );
    }
    // Note: a _FatalError from OpenRouter (bad API key) is rethrown as a
    // plain Exception and intentionally NOT caught here, since falling
    // back won't fix a misconfigured key — you'll want that surfaced.
  }
}
