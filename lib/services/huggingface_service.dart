import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;

/// Free-tier alternative to OpenRouter using Hugging Face's Inference
/// Providers router (OpenAI-compatible chat completion endpoint).
///
/// Every Hugging Face account gets monthly free inference credits — no
/// card required to start. Note this is credit-based, not literally
/// unlimited: once your monthly credits run out, calls will fail until
/// they reset or you upgrade. For a free tier that's rate-limited rather
/// than credit-limited (so it doesn't run out mid-month), Google AI
/// Studio's Gemini API is worth having as a second fallback.
///
/// Get a token at: https://huggingface.co/settings/tokens
class HuggingFaceService {
  HuggingFaceService({required this.apiToken});

  final String apiToken;
  static const _base = 'https://router.huggingface.co/v1';

  Future<String> sendMessage({
    required String userMessage,
    List<Map<String, String>> history = const [],
    // Any small instruct model works well here; swap as needed.
    String model = 'meta-llama/Llama-3.2-3B-Instruct',
  }) async {
    http.Response res;
    try {
      res = await http
          .post(
            Uri.parse('$_base/chat/completions'),
            headers: {
              'Authorization': 'Bearer $apiToken',
              'Content-Type': 'application/json',
            },
            body: jsonEncode({
              'model': model,
              'messages': [
                ...history,
                {'role': 'user', 'content': userMessage},
              ],
            }),
          )
          .timeout(const Duration(seconds: 30));
    } on TimeoutException {
      throw Exception('Hugging Face request timed out.');
    }

    if (res.statusCode == 401 || res.statusCode == 403) {
      throw Exception('Invalid or unauthorized Hugging Face token '
          '(HTTP ${res.statusCode}).');
    }

    if (res.statusCode == 429) {
      throw Exception('Hugging Face rate limit or monthly credits exhausted '
          '(HTTP 429).');
    }

    if (res.statusCode != 200) {
      throw Exception('Hugging Face error ${res.statusCode}: ${res.body}');
    }

    final data = jsonDecode(res.body) as Map<String, dynamic>;
    final choices = data['choices'] as List?;
    if (choices == null || choices.isEmpty) {
      throw Exception('Empty response from Hugging Face.');
    }

    return choices.first['message']['content'] as String;
  }
}
