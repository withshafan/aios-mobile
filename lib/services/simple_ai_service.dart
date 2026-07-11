import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class SimpleAiService {
  static const List<String> _models = [
    'mistralai/mistral-7b-instruct:free',
  ];

  static const Duration _baseBackoff = Duration(seconds: 8);
  static const int _maxRetries = 1;

  Future<bool> testConnection() async {
    try {
      final key = dotenv.env['OPENROUTER_API_KEY'] ?? '';
      final res = await http.get(
        Uri.parse('https://openrouter.ai/api/v1/models'),
        headers: {
          'Authorization': 'Bearer $key',
        },
      ).timeout(const Duration(seconds: 10));
      debugPrint('🌐 Connection test: ${res.statusCode}');
      return res.statusCode == 200;
    } catch (e) {
      debugPrint('🌐 Connection test FAILED: $e');
      return false;
    }
  }

  Future<String> sendMessage({
    required String userMessage,
    List<Map<String, String>> history = const [],
    String? imageBase64,
  }) async {
    final key = dotenv.env['OPENROUTER_API_KEY'] ?? '';
    if (key.isEmpty) return '❌ No API key found.';

    final messages = <Map<String, dynamic>>[
      {
        'role': 'system',
        'content': 'You are AURA. Creator: withshafan. Match user language.',
      },
      ...history,
      {
        'role': 'user',
        'content': imageBase64 != null && imageBase64.isNotEmpty
            ? [
                {'type': 'text', 'text': userMessage},
                {
                  'type': 'image_url',
                  'image_url': {'url': imageBase64},
                },
              ]
            : userMessage,
      },
    ];

    for (final model in _models) {
      debugPrint('🔑 Using key: ${key.length > 12 ? key.substring(0, 12) : key}...');
      debugPrint('📤 Sending request to: $model');

      for (int attempt = 0; attempt <= _maxRetries; attempt++) {
        try {
          final res = await http
              .post(
                Uri.parse('https://openrouter.ai/api/v1/chat/completions'),
                headers: {
                  'Authorization': 'Bearer $key',
                  'Content-Type': 'application/json',
                },
                body: jsonEncode({'model': model, 'messages': messages}),
              )
              .timeout(const Duration(seconds: 30));

          if (res.statusCode == 200) {
            final data = jsonDecode(res.body);
            return data['choices'][0]['message']['content'] as String? ?? 'No response.';
          }

          if (res.statusCode == 429) {
            if (attempt < _maxRetries) {
              final delaySeconds = _baseBackoff.inSeconds * (attempt + 1);
              debugPrint('⏳ Model $model rate limited (attempt ${attempt + 1}), waiting $delaySeconds seconds…');
              await Future.delayed(Duration(seconds: delaySeconds));
              continue;
            }
            debugPrint('⏳ Model $model rate limited, max retries reached.');
            break; // Stop retrying this model
          }

          debugPrint('❌ API error ${res.statusCode} for model $model: ${res.body}');
          break; // Non-429 error, stop retrying
        } catch (e) {
          debugPrint('❌ Network error with model $model: $e');
          break; // Network error, stop retrying
        }
      }
    }
    
    return '❌ All free models are currently rate limited or unavailable. Please try again shortly.';
  }
}
