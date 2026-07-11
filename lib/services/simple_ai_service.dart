import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class SimpleAiService {
  static const Duration _requestTimeout = Duration(seconds: 30);

  /// Try Gemini first (unlimited free, 15 RPM), fall back to OpenRouter.
  Future<String> sendMessage({
    required String userMessage,
    List<Map<String, String>> history = const [],
    String? imageBase64,
  }) async {
    final reply = await _tryGemini(userMessage, history, imageBase64);
    if (reply != null) return reply;

    return _tryOpenRouter(userMessage, history, imageBase64);
  }

  // ── Gemini (unlimited free) ──────────────────────────────────
  Future<String?> _tryGemini(
    String prompt,
    List<Map<String, String>> history,
    String? imageBase64,
  ) async {
    final key = dotenv.env['GEMINI_API_KEY'] ?? '';
    if (key.isEmpty) return null;

    try {
      final contents = <Map<String, dynamic>>[];
      for (final h in history) {
        contents.add({
          'role': h['role'] == 'assistant' ? 'model' : 'user',
          'parts': [{'text': h['content']}],
        });
      }
      final parts = <Map<String, dynamic>>[{'text': prompt}];
      if (imageBase64 != null && imageBase64.isNotEmpty) {
        parts.add({
          'inline_data': {
            'mime_type': 'image/jpeg',
            'data': imageBase64.split(',').last,
          },
        });
      }
      contents.add({'role': 'user', 'parts': parts});

      final res = await http
          .post(
            Uri.parse(
              'https://generativelanguage.googleapis.com/v1beta/models/'
              'gemini-2.0-flash:generateContent?key=$key',
            ),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'contents': contents,
              'systemInstruction': {
                'parts': [
                  {
                    'text': 'You are AURA. Creator: withshafan. Match user language.',
                  }
                ],
              },
            }),
          )
          .timeout(_requestTimeout);

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        return data['candidates']?[0]?['content']?['parts']?[0]?['text'] as String?;
      }

      // 429 = rate limited on Gemini, fall through to OpenRouter.
      debugPrint('🔵 Gemini fallback (${res.statusCode})');
    } catch (_) {}
    return null;
  }

  // ── OpenRouter (backup, 50 req/day) ──────────────────────────
  Future<String> _tryOpenRouter(
    String prompt,
    List<Map<String, String>> history,
    String? imageBase64,
  ) async {
    final key = dotenv.env['OPENROUTER_API_KEY'] ?? '';
    if (key.isEmpty) return '❌ No API key configured.';

    // Only model we know works for free right now.
    const model = 'meta-llama/llama-3.2-3b-instruct:free';

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
                {'type': 'text', 'text': prompt},
                {
                  'type': 'image_url',
                  'image_url': {'url': imageBase64},
                },
              ]
            : prompt,
      },
    ];

    for (int attempt = 0; attempt <= 2; attempt++) {
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
            .timeout(_requestTimeout);

        if (res.statusCode == 200) {
          final data = jsonDecode(res.body);
          return data['choices']?[0]?['message']?['content'] as String? ??
              '❌ Empty response.';
        }

        if (res.statusCode == 429 && attempt < 2) {
          debugPrint('⏳ OpenRouter 429 (attempt $attempt), waiting…');
          await Future.delayed(Duration(seconds: 8 + attempt * 4));
          continue;
        }

        debugPrint('❌ OpenRouter error ${res.statusCode}');
        return '❌ All AI services are currently unavailable. Please try again later.';
      } catch (_) {
        if (attempt < 2) {
          await Future.delayed(const Duration(seconds: 4));
          continue;
        }
      }
    }
    return '❌ All AI services are currently unavailable. Please try again later.';
  }
}
