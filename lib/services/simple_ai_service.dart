import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class SimpleAiService {
  static const String _model = 'meta-llama/llama-3.2-3b-instruct:free';

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

    try {
      final res = await http
          .post(
            Uri.parse('https://openrouter.ai/api/v1/chat/completions'),
            headers: {
              'Authorization': 'Bearer $key',
              'Content-Type': 'application/json',
            },
            body: jsonEncode({'model': _model, 'messages': messages}),
          )
          .timeout(const Duration(seconds: 30));

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        return data['choices'][0]['message']['content'] as String? ?? 'No response.';
      }

      if (res.statusCode == 429) {
        debugPrint('⏳ Rate limited, waiting 5 seconds…');
        await Future.delayed(const Duration(seconds: 5));
        // Retry once after delay
        final retry = await http
            .post(
              Uri.parse('https://openrouter.ai/api/v1/chat/completions'),
              headers: {
                'Authorization': 'Bearer $key',
                'Content-Type': 'application/json',
              },
              body: jsonEncode({'model': _model, 'messages': messages}),
            )
            .timeout(const Duration(seconds: 30));
        if (retry.statusCode == 200) {
          final data = jsonDecode(retry.body);
          return data['choices'][0]['message']['content'] as String? ?? 'No response.';
        }
        return '❌ Rate limited. Please wait a moment and try again.';
      }

      debugPrint('❌ API error ${res.statusCode}: ${res.body}');
      return '❌ API error (${res.statusCode}). Try again shortly.';
    } catch (e) {
      debugPrint('❌ Network error: $e');
      return '❌ Network error. Check your connection.';
    }
  }
}
