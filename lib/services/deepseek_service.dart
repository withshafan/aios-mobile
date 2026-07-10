import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'analytics_service.dart';

class DeepSeekService {
  static const String apiKey = 'YOUR_API_KEY';
  final AnalyticsService _analyticsService;

  static const int maxHistoryPairs = 3;

  DeepSeekService(this._analyticsService);

  Future<ChatResponse> sendMessage(String prompt, List<String>? fullHistory) async {
    final history = _trimHistory(fullHistory);

    final messages = <Map<String, dynamic>>[];
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
        Uri.parse('https://api.deepseek.com/chat/completions'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $apiKey',
        },
        body: jsonEncode({
          'model': 'deepseek-chat',
          'messages': messages,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final text = data['choices'][0]['message']['content'] ?? 'No response.';
        final outputTokens = _analyticsService.estimateTokens(text);
        await _analyticsService.logMessage(inputTokens + contextTokens, outputTokens);
        return ChatResponse(text: text);
      } else {
        throw Exception('API Error: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      final errorString = e.toString();
      return ChatResponse(
        text: '⚠️ Sorry, an error occurred: ${errorString.length > 100 ? errorString.substring(0, 100) : errorString}'
      );
    }
  }

  List<String>? _trimHistory(List<String>? fullHistory) {
    if (fullHistory == null || fullHistory.isEmpty) return null;
    final count = maxHistoryPairs * 2;
    return fullHistory.length <= count
        ? fullHistory
        : fullHistory.sublist(fullHistory.length - count);
  }
}

class ChatResponse {
  final String text;

  ChatResponse({required this.text});
}
