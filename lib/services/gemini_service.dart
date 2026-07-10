import 'dart:async';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:flutter/foundation.dart';
import 'analytics_service.dart';
import 'plugin_service.dart';

class GeminiService {
  static const String apiKey = 'YOUR_API_KEY';
  final PluginService _pluginService;
  final AnalyticsService _analyticsService;
  late final GenerativeModel _model;

  // Maximum conversation turns (user+AI pairs) to send as context
  static const int maxHistoryPairs = 3;

  GeminiService(this._pluginService, this._analyticsService) {
    _model = GenerativeModel(model: 'gemini-2.0-flash', apiKey: apiKey);
  }

  Future<ChatResponse> sendMessage(String prompt, List<String>? fullHistory) async {
    // Trim history to last N exchanges (2*maxHistoryPairs messages)
    final history = _trimHistory(fullHistory);

    // Build contents for the model
    final contents = <Content>[];
    if (history != null) {
      for (final msg in history) {
        if (msg.startsWith('User: ')) {
          contents.add(Content.text(msg.substring(6)));
        } else if (msg.startsWith('AI: ')) {
          contents.add(Content.model([TextPart(msg.substring(4))]));
        }
      }
    }
    contents.add(Content.text(prompt));

    // Estimate tokens for logging
    final inputTokens = _analyticsService.estimateTokens(prompt);
    final contextTokens = history?.fold(0, (sum, msg) => sum + _analyticsService.estimateTokens(msg)) ?? 0;

    try {
      // First attempt
      final response = await _model.generateContent(contents);
      final text = response.text ?? 'No response.';
      final outputTokens = _analyticsService.estimateTokens(text);
      await _analyticsService.logMessage(inputTokens + contextTokens, outputTokens);
      return ChatResponse(text: text);
    } catch (e) {
      final errorString = e.toString();
      if (errorString.contains('429') || errorString.contains('RESOURCE_EXHAUSTED') || errorString.contains('quota')) {
        // Retry after a short delay (exponential backoff)
        debugPrint('Quota exceeded, retrying in 5 seconds...');
        await Future.delayed(const Duration(seconds: 5));
        try {
          final response = await _model.generateContent(contents);
          final text = response.text ?? 'No response.';
          final outputTokens = _analyticsService.estimateTokens(text);
          await _analyticsService.logMessage(inputTokens + contextTokens, outputTokens);
          return ChatResponse(text: text);
        } catch (e2) {
          // Quota still exceeded – inform user clearly
          return ChatResponse(
            text: '⚠️ My brain is temporarily overloaded (API quota exceeded). '
                'Please wait a minute and try again, or shorten the conversation.'
          );
        }
      } else {
        // Other error – surface it
        return ChatResponse(
          text: '⚠️ Sorry, an error occurred: ${e.toString().substring(0, 100)}'
        );
      }
    }
  }

  /// Keep only the last [maxHistoryPairs] user+AI pairs (2*maxHistoryPairs messages)
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
