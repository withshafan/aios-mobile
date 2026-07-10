import 'dart:convert';
import 'package:http/http.dart' as http;
import 'analytics_service.dart';

class OpenRouterService {
  // Paste your OpenRouter key here
  static const String apiKey = 'YOUR_API_KEY';

  final AnalyticsService _analyticsService;

  OpenRouterService(this._analyticsService);

  Future<ChatResponse> sendMessage(String prompt, List<String>? fullHistory) async {
    final history = _trimHistory(fullHistory);

    final messages = <Map<String, String>>[];
    if (history != null) {
      for (final msg in history) {
        if (msg.startsWith('User: ')) {
          messages.add({'role': 'user', 'content': msg.substring(6)});
        } else if (msg.startsWith('AI: ')) {
          messages.add({'role': 'assistant', 'content': msg.substring(4)});
        }
      }
    }
    messages.add({'role': 'user', 'content': prompt});

    final inputTokens = _analyticsService.estimateTokens(prompt);
    final contextTokens = history?.fold(0, (sum, msg) => sum + _analyticsService.estimateTokens(msg)) ?? 0;

    try {
      final response = await http.post(
        Uri.parse('https://openrouter.ai/api/v1/chat/completions'),
        headers: {
          'Authorization': 'Bearer $apiKey',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'model': 'meta-llama/llama-3.2-3b-instruct:free',   // free model
          'messages': messages,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final text = data['choices'][0]['message']['content'] as String? ?? 'No response.';
        final outputTokens = _analyticsService.estimateTokens(text);
        await _analyticsService.logMessage(inputTokens + contextTokens, outputTokens);
        return ChatResponse(text: text);
      } else {
        final errorBody = jsonDecode(response.body);
        final errorMsg = errorBody['error']?['message'] ?? 'Unknown error';
        return ChatResponse(text: '⚠️ OpenRouter error: $errorMsg');
      }
    } catch (e) {
      return ChatResponse(text: '⚠️ Network error: ${e.toString().substring(0, 100)}');
    }
  }

  List<String>? _trimHistory(List<String>? fullHistory) {
    if (fullHistory == null || fullHistory.isEmpty) return null;
    const maxPairs = 1;
    final count = maxPairs * 2;
    return fullHistory.length <= count
        ? fullHistory
        : fullHistory.sublist(fullHistory.length - count);
  }
}

class ChatResponse {
  final String text;
  ChatResponse({required this.text});
}
