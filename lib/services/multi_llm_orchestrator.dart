import 'plugin_service.dart';
import 'analytics_service.dart';
import 'deepseek_service.dart';

class MultiLLMOrchestrator {
  final PluginService _pluginService;
  final AnalyticsService _analyticsService;

  MultiLLMOrchestrator(this._pluginService, this._analyticsService);

  Future<String> processPrompt(String prompt, {bool complexReasoning = false}) async {
    final deepseek = DeepSeekService(_analyticsService);
    final response = await deepseek.sendMessage(prompt, null);
    return response.text;
  }
}
