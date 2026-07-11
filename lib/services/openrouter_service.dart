import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class OpenRouterService {
  final String apiKey;
  final String model;

  OpenRouterService({
    required this.apiKey,
    this.model = 'meta-llama/llama-3.2-3b-instruct:free',
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
    final useModel = modelOverride ?? model;
    final messages = <Map<String, dynamic>>[];

    messages.add({
      'role': 'system',
      'content': _systemPrompt,
    });

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

    final body = jsonEncode({
      'model': useModel,
      'messages': messages,
    });

    debugPrint('📤 Sending to OpenRouter model: $useModel');
    debugPrint('🔑 Using API key: ${apiKey.substring(0, 10)}...');

    try {
      final response = await http
          .post(Uri.parse('$_base/chat/completions'), headers: _headers, body: body)
          .timeout(const Duration(seconds: 30));

      debugPrint('📥 Response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final text = data['choices'][0]['message']['content'] as String? ?? 'No response.';
        return ChatResponse(text: text);
      } else {
        final errorBody = response.body;
        debugPrint('❌ API Error: $errorBody');
        return ChatResponse(
          text: '❌ API Error (${response.statusCode}): ${_extractErrorMessage(errorBody)}',
          isError: true,
        );
      }
    } catch (e) {
      debugPrint('❌ Network error: $e');
      return ChatResponse(
        text: '❌ Network error: ${e.toString().substring(0, 100)}',
        isError: true,
      );
    }
  }

  String _extractErrorMessage(String body) {
    try {
      final data = jsonDecode(body);
      return data['error']?['message'] ?? body.substring(0, 150);
    } catch (_) {
      return body.substring(0, 150);
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
