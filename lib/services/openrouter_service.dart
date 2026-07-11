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

  static const int _maxCycles = 6;                // more retries
  static const Duration _baseBackoff = Duration(seconds: 1);
  static const Duration _maxBackoff = Duration(seconds: 30);

  OpenRouterService({
    required this.apiKey,
    List<String>? models,
  }) : models = models ??
            const [
              'meta-llama/llama-3.2-3b-instruct:free',
              'meta-llama/llama-3.2-1b-instruct:free',
              'meta-llama/llama-3.2-11b-vision-instruct:free',
            ];

  static const _base = 'https://openrouter.ai/api/v1';

  Map<String, String> get _headers => {
        'Authorization': 'Bearer $apiKey',
        'Content-Type': 'application/json',
        'HTTP-Referer': 'https://aura-aios.app',
        'X-Title': 'AURA AIOS',
      };

  Future<String> sendMessage(List<Map<String, dynamic>> messages) async {
    for (int cycle = 0; cycle < _maxCycles; cycle++) {
      for (final model in models) {
        final body = jsonEncode({'model': model, 'messages': messages});
        debugPrint('📤 Sending to $model (cycle ${cycle + 1})');

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
            // Rate limited or server error, we will continue to the next model
            debugPrint('❌ $model overloaded (status ${response.statusCode})');
          } else {
            // Fatal error like 401 or 400
            final errorBody = response.body;
            debugPrint('❌ $model fatal error: $errorBody');
            throw OpenRouterException('API Error (${response.statusCode}): ${_extractErrorMessage(errorBody)}');
          }
        } catch (e) {
          if (e is OpenRouterException) rethrow;
          debugPrint('❌ Network error with $model: $e');
        }
      }
      
      // If we got here, all models failed in this cycle. Apply backoff before next cycle.
      if (cycle < _maxCycles - 1) {
        final delaySeconds = (_baseBackoff.inSeconds * (1 << cycle)).clamp(1, _maxBackoff.inSeconds);
        debugPrint('⏳ All models failed cycle ${cycle + 1}. Retrying in ${delaySeconds}s…');
        await Future.delayed(Duration(seconds: delaySeconds));
      }
    }

    // If we exhausted all cycles
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
