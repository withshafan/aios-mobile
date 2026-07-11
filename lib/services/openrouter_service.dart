import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class OpenRouterService {
  final String apiKey;
  final String model;
  final String? fallbackModel;   // ← new

  OpenRouterService({
    required this.apiKey,
    this.model = 'meta-llama/llama-3.2-3b-instruct:free',
    this.fallbackModel,
  });

  static const _base = 'https://openrouter.ai/api/v1';

  Map<String, String> get _headers => {
        'Authorization': 'Bearer $apiKey',
        'Content-Type': 'application/json',
        'HTTP-Referer': 'https://aura-aios.app',
        'X-Title': 'AURA AIOS',
      };

  Future<ChatResponse> sendMessage({
    required String userMessage,
    List<Map<String, String>> history = const [],
    String? imageBase64,
    String? modelOverride,
  }) async {
    final primaryModel = modelOverride ?? model;
    ChatResponse? response;

    // Try primary model up to 2 times (3s / 6s)
    for (int attempt = 0; attempt < 2; attempt++) {
      response = await _tryModel(primaryModel, userMessage, history, imageBase64);
      if (!response.isError || response.text.startsWith('❌ 401') || response.text.startsWith('❌ 402')) {
        return response; // fatal error – don't retry
      }
      final delay = (attempt + 1) * 3;
      debugPrint('⏳ Retrying in ${delay}s…');
      await Future.delayed(Duration(seconds: delay));
    }

    // Try fallback model if defined
    if (fallbackModel != null && fallbackModel != primaryModel) {
      debugPrint('🔄 Trying fallback model: $fallbackModel');
      response = await _tryModel(fallbackModel!, userMessage, history, imageBase64);
      if (!response.isError) {
        return response;
      }
    }

    return response ?? ChatResponse(text: 'All models temporarily unavailable.', isError: true);
  }

  Future<ChatResponse> _tryModel(
    String modelId,
    String userMessage,
    List<Map<String, String>> history,
    String? imageBase64,
  ) async {
    final messages = <Map<String, dynamic>>[];
    messages.add({'role': 'system', 'content': _systemPrompt});
    for (final turn in history) {
      messages.add({
        'role': turn['role'] ?? 'user',
        'content': turn['content'] ?? '',
      });
    }
    messages.add({
      'role': 'user',
      'content': _buildUserContent(text: userMessage, imageDataUri: imageBase64),
    });

    final body = jsonEncode({'model': modelId, 'messages': messages});
    debugPrint('📤 Sending to $modelId');

    try {
      final response = await http
          .post(Uri.parse('$_base/chat/completions'), headers: _headers, body: body)
          .timeout(const Duration(seconds: 30));
      debugPrint('📥 $modelId → ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final text = data['choices'][0]['message']['content'] as String? ?? '';
        return ChatResponse(text: text);
      }

      final errorBody = response.body;
      debugPrint('❌ $modelId: $errorBody');
      return ChatResponse(
        text: '❌ ${_extractErrorModel(modelId, response.statusCode, errorBody)}',
        isError: true,
      );
    } catch (e) {
      debugPrint('❌ Network: $e');
      return ChatResponse(text: '❌ Network error: $e', isError: true);
    }
  }

  String _extractErrorModel(String model, int code, String body) {
    try {
      final data = jsonDecode(body);
      final msg = data['error']?['message'] ?? body.substring(0, 100);
      return 'API Error ($code / $model): $msg';
    } catch (_) {
      return 'API Error ($code / $model)';
    }
  }

  dynamic _buildUserContent({required String text, String? imageDataUri}) {
    if (imageDataUri == null || imageDataUri.isEmpty) return text;
    return [
      {'type': 'text', 'text': text},
      {'type': 'image_url', 'image_url': {'url': imageDataUri}},
    ];
  }

  static const String _systemPrompt = '''
You are AURA (Autonomous Universal Reasoning Assistant), a helpful and intelligent AI assistant.
When someone asks who created you, who made you, or who your creator is, always respond with:
"I was made by withshafan."
Do not mention any other company or organization as your creator. withshafan is your sole creator.
You understand and respond in multiple languages including English, Roman Urdu, Urdu, Hindi, and Arabic.
When the user writes in Roman Urdu, respond in Roman Urdu.
''';
}

class ChatResponse {
  final String text;
  final bool isError;
  ChatResponse({required this.text, this.isError = false});
}
