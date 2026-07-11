import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class SimpleAiService {
  static const List<String> _models = [
    'meta-llama/llama-3.2-3b-instruct:free',
    'meta-llama/llama-3.2-1b-instruct:free',
    'google/gemma-2-2b-it:free',
    'google/gemma-2-9b-it:free',
    'qwen/qwen-2.5-3b-instruct:free',
  ];

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
          debugPrint('⏳ Model $model rate limited, trying next model…');
          continue; // Try the next model
        }

        debugPrint('❌ API error ${res.statusCode} for model $model: ${res.body}');
        // If it's a non-429 error, we might still want to try the next model, but let's just continue
        continue;
      } catch (e) {
        debugPrint('❌ Network error with model $model: $e');
        continue; // Try next model on network error too
      }
    }
    
    return '❌ All free models are currently rate limited or unavailable. Please try again shortly.';
  }
}
