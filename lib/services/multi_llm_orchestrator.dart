import 'package:google_generative_ai/google_generative_ai.dart';
import 'plugin_service.dart';
import 'analytics_service.dart';
import 'gemini_service.dart';

class MultiLLMOrchestrator {
  final PluginService _pluginService;
  final AnalyticsService _analyticsService;

  MultiLLMOrchestrator(this._pluginService, this._analyticsService);

  Future<String> processPrompt(String prompt, {bool complexReasoning = false}) async {
    // Model selection logic (simplified)
    String modelName = 'gemini-2.0-flash';
    if (complexReasoning) {
      modelName = 'gemini-2.0-flash'; // same for now
    }
    final model = GenerativeModel(model: modelName, apiKey: GeminiService.apiKey);
    final response = await model.generateContent([Content.text(prompt)]);
    final text = response.text ?? 'Unable to process.';
    await _analyticsService.logMessage(_analyticsService.estimateTokens(prompt), _analyticsService.estimateTokens(text));
    return text;
  }
}
