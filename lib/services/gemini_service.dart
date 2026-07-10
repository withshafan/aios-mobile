import 'package:google_generative_ai/google_generative_ai.dart';
import 'plugin_service.dart';
import 'analytics_service.dart';

class GeminiService {
  static const String apiKey = 'YOUR_API_KEY'; // Replace
  final PluginService _pluginService;
  final AnalyticsService _analyticsService;

  GeminiService(this._pluginService, this._analyticsService);

  Future<ChatResponse> sendMessage(String prompt, List<String>? history) async {
    final model = GenerativeModel(model: 'gemini-2.0-flash', apiKey: apiKey);
    final contents = <Content>[];
    if (history != null) {
      for (int i = 0; i < history.length; i++) {
        if (i % 2 == 0) {
          contents.add(Content.text(history[i].replaceFirst('User: ', '')));
        } else {
          contents.add(Content.model([TextPart(history[i].replaceFirst('AI: ', ''))]));
        }
      }
    }
    contents.add(Content.text(prompt));
    final response = await model.generateContent(contents);
    final text = response.text ?? 'No response.';
    await _analyticsService.logMessage(_analyticsService.estimateTokens(prompt), _analyticsService.estimateTokens(text));
    return ChatResponse(text: text);
  }
}

class ChatResponse {
  final String text;
  ChatResponse({required this.text});
}
