import 'plugin_service.dart';
import 'analytics_service.dart';
import 'openrouter_service.dart';

class MultiLLMOrchestrator {
  final PluginService _pluginService;
  final AnalyticsService _analyticsService;

  MultiLLMOrchestrator(this._pluginService, this._analyticsService);

  Future<String> processPrompt(String prompt, {bool complexReasoning = false}) async {
    final aiService = OpenRouterService(_analyticsService);
    final response = await aiService.sendMessage(prompt, null);
    return response.text;
  }
}
