import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class UniversalAiService {
  // ── Gemini (unlimited free) ──
  Future<String?> _tryGemini(String prompt, List<Map<String, String>> history, String? imageBase64) async {
    final key = dotenv.env['GEMINI_API_KEY'] ?? '';
    debugPrint('🔵 Gemini key present: ${key.isNotEmpty} (${key.length} chars)');
    if (key.isEmpty) return null;

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

      debugPrint('🔵 Gemini: sending request...');
      final res = await http.post(url, headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'contents': contents,
          'systemInstruction': {'parts': [{'text': 'You are AURA. Creator: withshafan. Match user language.'}]}
        }),
      ).timeout(const Duration(seconds: 15));
      debugPrint('🔵 Gemini: status ${res.statusCode}');

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        return data['candidates'][0]['content']['parts'][0]['text'] as String?;
      } else {
        debugPrint('🔵 Gemini error body: ${res.body.substring(0, res.body.length > 200 ? 200 : res.body.length)}');
      }
    } catch (e) {
      debugPrint('🔵 Gemini exception: $e');
    }
    return null;
  }

  // ── OpenRouter (multiple keys) ──
  Future<String?> _tryOpenRouter(String prompt, List<Map<String, String>> history, String? imageBase64) async {
    final keys = [
      dotenv.env['OPENROUTER_API_KEY'],
      dotenv.env['GEMMA_KEY'],
      dotenv.env['HY3_KEY'],
    ].where((k) => k != null && k.isNotEmpty).toList();

    debugPrint('🟠 OpenRouter: ${keys.length} keys available');

    for (int i = 0; i < keys.length; i++) {
      final key = keys[i];
      try {
        debugPrint('🟠 OpenRouter: trying key #$i...');
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
          body: jsonEncode({'model': 'meta-llama/llama-3.2-3b-instruct:free', 'messages': messages}),
        ).timeout(const Duration(seconds: 15));

        debugPrint('🟠 OpenRouter key #$i: status ${res.statusCode}');
        if (res.statusCode == 200) {
          final data = jsonDecode(res.body);
          return data['choices'][0]['message']['content'] as String?;
        } else {
          debugPrint('🟠 OpenRouter error: ${res.body.substring(0, res.body.length > 200 ? 200 : res.body.length)}');
        }
      } catch (e) {
        debugPrint('🟠 OpenRouter key #$i exception: $e');
      }
    }
    return null;
  }

  // ── Hugging Face (free credits) ──
  Future<String?> _tryHuggingFace(String prompt, List<Map<String, String>> history) async {
    final token = dotenv.env['HUGGINGFACE_API_KEY'] ?? '';
    debugPrint('🟣 HuggingFace token present: ${token.isNotEmpty}');
    if (token.isEmpty) return null;

    try {
      final messages = <Map<String, String>>[];
      for (final h in history) {
        messages.add({'role': h['role'] ?? 'user', 'content': h['content'] ?? ''});
      }
      messages.add({'role': 'user', 'content': prompt});

      debugPrint('🟣 HuggingFace: sending request...');
      final res = await http.post(
        Uri.parse('https://router.huggingface.co/v1/chat/completions'),
        headers: {'Authorization': 'Bearer $token', 'Content-Type': 'application/json'},
        body: jsonEncode({'model': 'meta-llama/Llama-3.2-3B-Instruct', 'messages': messages, 'max_tokens': 500}),
      ).timeout(const Duration(seconds: 20));
      debugPrint('🟣 HuggingFace: status ${res.statusCode}');

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        return data['choices'][0]['message']['content'] as String?;
      } else {
        debugPrint('🟣 HuggingFace error: ${res.body.substring(0, res.body.length > 200 ? 200 : res.body.length)}');
      }
    } catch (e) {
      debugPrint('🟣 HuggingFace exception: $e');
    }
    return null;
  }

  // ── Public orchestrator ──
  Future<String> sendMessage({
    required String userMessage,
    List<Map<String, String>> history = const [],
    String? imageBase64,
  }) async {
    debugPrint('🚀 UniversalAiService: starting chain...');
    String? reply;

    reply = await _tryGemini(userMessage, history, imageBase64);
    if (reply != null) { debugPrint('✅ Gemini succeeded'); return reply; }
    debugPrint('⛔ Gemini failed, trying OpenRouter...');

    reply = await _tryOpenRouter(userMessage, history, imageBase64);
    if (reply != null) { debugPrint('✅ OpenRouter succeeded'); return reply; }
    debugPrint('⛔ OpenRouter failed, trying HuggingFace...');

    reply = await _tryHuggingFace(userMessage, history);
    if (reply != null) { debugPrint('✅ HuggingFace succeeded'); return reply; }

    debugPrint('❌ ALL providers failed');
    return '⚠️ All free AI services are temporarily unavailable. Please try again in a few seconds.';
  }
}
