import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class OpenRouterException implements Exception {
  final String message;
  final bool isAllModelsBusy;

  OpenRouterException(this.message, {this.isAllModelsBusy = false});
}

class OpenRouterService {
  final String apiKey;
  final List<String> models;

  OpenRouterService({
    required this.apiKey,
    List<String>? models,
  }) : models = models ??
            const [
              'meta-llama/llama-3.2-3b-instruct:free', // main chat
              'meta-llama/llama-3.2-11b-vision-instruct:free', // images
              'meta-llama/llama-3.2-1b-instruct:free', // fast fallback
            ];

  static const _base = 'https://openrouter.ai/api/v1';

  Map<String, String> get _headers => {
        'Authorization': 'Bearer $apiKey',
        'Content-Type': 'application/json',
        'HTTP-Referer': 'https://aura-aios.app',
        'X-Title': 'AURA AIOS',
      };

  Future<String> sendMessage(List<Map<String, dynamic>> messages) async {
    for (final model in models) {
      // Try each model up to 2 times
      for (int attempt = 0; attempt < 2; attempt++) {
        final body = jsonEncode({'model': model, 'messages': messages});
        debugPrint('📤 Sending to $model (attempt ${attempt + 1})');

        try {
          final response = await http
              .post(Uri.parse('$_base/chat/completions'), headers: _headers, body: body)
              .timeout(const Duration(seconds: 30));
          debugPrint('📥 $model → ${response.statusCode}');

          if (response.statusCode == 200) {
            final data = jsonDecode(response.body);
            return data['choices'][0]['message']['content'] as String? ?? '';
          }

          if (response.statusCode == 429 || response.statusCode >= 500) {
            // Rate limited or server error, wait and retry
            final delay = (attempt + 1) * 3;
            debugPrint('⏳ Retrying in ${delay}s…');
            await Future.delayed(Duration(seconds: delay));
            continue; // try next attempt
          } else {
            // Fatal error like 401 or 400
            final errorBody = response.body;
            debugPrint('❌ $model: $errorBody');
            throw OpenRouterException('API Error (${response.statusCode}): ${_extractErrorMessage(errorBody)}');
          }
        } catch (e) {
          if (e is OpenRouterException) rethrow;
          debugPrint('❌ Network error with $model: $e');
          // If network error, might be timeout, we can try to retry
          if (attempt == 1) {
            // If it's the last attempt for this model, we'll let the outer loop try the next model
            break;
          }
        }
      }
      debugPrint('🔄 Model $model exhausted, trying next fallback model...');
    }

    // If we exhausted all models and retries
    throw OpenRouterException('All models failed to respond.', isAllModelsBusy: true);
  }

  String _extractErrorMessage(String body) {
    try {
      final data = jsonDecode(body);
      return data['error']?['message'] ?? body.substring(0, 100);
    } catch (_) {
      return body.substring(0, 100);
    }
  }
}
