import 'plugin_service.dart';
import 'analytics_service.dart';
import 'simple_ai_service.dart';

class MultiLLMOrchestrator {
  final PluginService _pluginService;
  final AnalyticsService _analyticsService;
  final SimpleAiService _aiService;

  MultiLLMOrchestrator(this._pluginService, this._analyticsService, this._aiService);

  Future<String> processPrompt(String prompt, {bool complexReasoning = false}) async {
    final responseText = await _aiService.sendMessage(userMessage: prompt);
    return responseText;
  }
}

