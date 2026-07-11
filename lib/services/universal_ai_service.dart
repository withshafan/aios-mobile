import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class UniversalAiService {
  // ── Multiple Gemini keys ──
  List<String> get _geminiKeys => [
        dotenv.env['GEMINI_API_KEY'] ?? '',
        dotenv.env['GEMINI_KEY_2'] ?? '',
        dotenv.env['GEMINI_KEY_3'] ?? '',
      ].where((k) => k.isNotEmpty).toList();

  int _geminiIndex = 0;

  Future<String?> _tryGemini(String prompt, List<Map<String, String>> history, String? imageBase64) async {
    final keys = _geminiKeys;
    if (keys.isEmpty) return null;

    // Try each key (round‑robin starting from last successful)
    for (int i = 0; i < keys.length; i++) {
      final key = keys[(_geminiIndex + i) % keys.length];
      try {
        final url = Uri.parse(
          'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent?key=$key',
        );

        final contents = <Map<String, dynamic>>[];
        for (final h in history) {
          contents.add({
            'role': h['role'] == 'assistant' ? 'model' : 'user',
            'parts': [{'text': h['content']}],
          });
        }
        final parts = <Map<String, dynamic>>[{'text': prompt}];
        if (imageBase64 != null && imageBase64.isNotEmpty) {
          parts.add({'inline_data': {'mime_type': 'image/jpeg', 'data': imageBase64.split(',').last}});
        }
        contents.add({'role': 'user', 'parts': parts});

        final res = await http.post(url, headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'contents': contents,
            'systemInstruction': {'parts': [{'text': 'You are AURA. Creator: withshafan. Match user language.'}]}
          }),
        ).timeout(const Duration(seconds: 15));

        if (res.statusCode == 200) {
          _geminiIndex = (_geminiIndex + i) % keys.length;  // remember winning key
          final data = jsonDecode(res.body);
          return data['candidates'][0]['content']['parts'][0]['text'] as String?;
        } else if (res.statusCode == 429) {
          debugPrint('🔵 Gemini key ${key.substring(0,6)}: 429, rotating...');
          continue;   // try next key
        }
      } catch (_) {}
    }
    return null;
  }

  // ── OpenRouter (only valid keys) ──
  Future<String?> _tryOpenRouter(String prompt, List<Map<String, String>> history, String? imageBase64) async {
    // Only key #0 is valid (the others return 401)
    final key = dotenv.env['OPENROUTER_API_KEY'] ?? '';
    if (key.isEmpty) return null;

    // List of free models to try
    final freeModels = [
      'meta-llama/llama-3.2-3b-instruct:free',
      'meta-llama/llama-3.2-1b-instruct:free',
      'google/gemma-2-2b-it:free',
    ];

    for (final model in freeModels) {
      try {
        final messages = <Map<String, dynamic>>[];
        messages.add({'role': 'system', 'content': 'You are AURA. Creator: withshafan.'});
        for (final h in history) {
          messages.add({'role': h['role'], 'content': h['content']});
        }
        messages.add({
          'role': 'user',
          'content': imageBase64 != null && imageBase64.isNotEmpty
              ? [{'type': 'text', 'text': prompt}, {'type': 'image_url', 'image_url': {'url': imageBase64}}]
              : prompt,
        });

        final res = await http.post(
          Uri.parse('https://openrouter.ai/api/v1/chat/completions'),
          headers: {'Authorization': 'Bearer $key', 'Content-Type': 'application/json'},
          body: jsonEncode({'model': model, 'messages': messages}),
        ).timeout(const Duration(seconds: 15));

        if (res.statusCode == 200) {
          final data = jsonDecode(res.body);
          return data['choices'][0]['message']['content'] as String?;
        }
      } catch (_) {}
    }
    return null;
  }

  // ── Hugging Face (correct model) ──
  Future<String?> _tryHuggingFace(String prompt, List<Map<String, String>> history) async {
    final token = dotenv.env['HUGGINGFACE_API_KEY'] ?? '';
    if (token.isEmpty) return null;

    try {
      final messages = <Map<String, String>>[];
      for (final h in history) {
        messages.add({'role': h['role'] ?? 'user', 'content': h['content'] ?? ''});
      }
      messages.add({'role': 'user', 'content': prompt});

      final res = await http.post(
        Uri.parse('https://router.huggingface.co/v1/chat/completions'),
        headers: {'Authorization': 'Bearer $token', 'Content-Type': 'application/json'},
        body: jsonEncode({
          'model': 'mistralai/Mistral-7B-Instruct-v0.2',   // free, proven to work
          'messages': messages,
          'max_tokens': 500,
        }),
      ).timeout(const Duration(seconds: 20));

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        return data['choices'][0]['message']['content'] as String?;
      }
    } catch (_) {}
    return null;
  }

  // ── Public orchestrator ──
  Future<String> sendMessage({
    required String userMessage,
    List<Map<String, String>> history = const [],
    String? imageBase64,
  }) async {
    String? reply;

    reply = await _tryGemini(userMessage, history, imageBase64);
    if (reply != null) return reply;

    // Wait 2 seconds before trying OpenRouter (allow rate limits to reset)
    await Future.delayed(const Duration(seconds: 2));
    reply = await _tryOpenRouter(userMessage, history, imageBase64);
    if (reply != null) return reply;

    reply = await _tryHuggingFace(userMessage, history);
    if (reply != null) return reply;

    return '⚠️ All free AI services are temporarily unavailable. Please try again in a few seconds.';
  }
}
