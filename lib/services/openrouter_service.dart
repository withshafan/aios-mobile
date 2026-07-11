import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;

/// Result wrapper so the UI can show which model actually answered
/// (handy for debugging or a small "answered by: ..." label).
class ChatResult {
  final String content;
  final String modelUsed;
  ChatResult({required this.content, required this.modelUsed});
}

/// Thrown only if EVERY model in the fallback chain failed.
class OpenRouterAllModelsFailedException implements Exception {
  final List<String> triedModels;
  final String lastError;
  OpenRouterAllModelsFailedException(this.triedModels, this.lastError);

  @override
  String toString() =>
      'All OpenRouter models failed. Tried: ${triedModels.join(", ")}. '
      'Last error: $lastError';
}

/// Internal: signals "this model failed, try the next one in the chain".
class _RetryableError {
  final String message;
  _RetryableError(this.message);
}

/// Internal: signals "stop entirely, this isn't a model problem"
/// (e.g. bad API key — retrying with another model won't help).
class _FatalError {
  final String message;
  _FatalError(this.message);
}

class OpenRouterService {
  OpenRouterService({required this.apiKey});

  final String apiKey;
  static const _base = 'https://openrouter.ai/api/v1';

  // Cache the live free-model list for a few minutes so we're not
  // hitting /models on every single chat message.
  List<String>? _cachedFreeModels;
  DateTime? _cacheTime;

  Map<String, String> get _headers => {
        'Authorization': 'Bearer $apiKey',
        'Content-Type': 'application/json',
        // Optional attribution headers OpenRouter uses for its public
        // rankings page — not required for requests to work, but good practice.
        'HTTP-Referer': 'https://your-app.example',
        'X-Title': 'Your Flutter App',
      };

  /// Pulls the CURRENT list of models that are actually free right now
  /// (prompt price == 0 AND completion price == 0), instead of trusting
  /// a hardcoded ":free" suffix that may have been retired.
  Future<List<String>> fetchFreeModelIds({bool forceRefresh = false}) async {
    if (!forceRefresh &&
        _cachedFreeModels != null &&
        _cacheTime != null &&
        DateTime.now().difference(_cacheTime!) < const Duration(minutes: 10)) {
      return _cachedFreeModels!;
    }

    final res = await http
        .get(Uri.parse('$_base/models'), headers: _headers)
        .timeout(const Duration(seconds: 15));

    if (res.statusCode != 200) {
      throw Exception('Failed to list models: HTTP ${res.statusCode}');
    }

    final data = jsonDecode(res.body) as Map<String, dynamic>;
    final models = (data['data'] as List).cast<Map<String, dynamic>>();

    final free = models.where((m) {
      final pricing = m['pricing'] as Map<String, dynamic>?;
      if (pricing == null) return false;
      final prompt = double.tryParse(pricing['prompt']?.toString() ?? '1') ?? 1;
      final completion =
          double.tryParse(pricing['completion']?.toString() ?? '1') ?? 1;
      return prompt == 0 && completion == 0;
    }).map((m) => m['id'] as String).toList();

    _cachedFreeModels = free;
    _cacheTime = DateTime.now();
    return free;
  }

  /// Sends a chat message. Tries [preferredModels] first (in order), then
  /// any other currently-free model straight from the live catalog, then
  /// falls back to OpenRouter's own auto-router "openrouter/free" as a
  /// last resort. Returns which model actually answered.
  Future<ChatResult> sendMessage({
    required String userMessage,
    List<Map<String, String>> history = const [],
    String? imageBase64,
    List<String> preferredModels = const [
      'google/gemma-2-2b-it:free',
      'qwen/qwen-2.5-7b-instruct:free',
      'meta-llama/llama-3.2-3b-instruct:free',
      'google/gemma-2-9b-it:free',
    ],
  }) async {
    final chain = <String>[];
    if (imageBase64 != null) {
      chain.addAll([
        'google/gemini-2.0-flash-lite-preview-02-05:free',
        'meta-llama/llama-3.2-11b-vision-instruct:free',
        'qwen/qwen2.5-vl-72b-instruct:free'
      ]);
    }
    chain.addAll(preferredModels);

    try {
      final live = await fetchFreeModelIds();
      for (final m in live) {
        if (!chain.contains(m)) chain.add(m);
      }
    } catch (_) {
      // If listing fails, we still have the static chain + auto-router below.
    }

    // Ultimate fallback: OpenRouter's own router that picks a live free
    // model for you, so this call basically can't go permanently dark.
    chain.add('openrouter/free');

    final errors = <String>[];

    for (final model in chain) {
      try {
        final content = await _attempt(model, userMessage, history, imageBase64);
        return ChatResult(content: content, modelUsed: model);
      } on _RetryableError catch (e) {
        errors.add('$model -> ${e.message}');
        continue;
      } on _FatalError catch (e) {
        throw Exception(e.message);
      }
    }

    throw OpenRouterAllModelsFailedException(chain, errors.join(' | '));
  }

  Future<String> _attempt(
    String model,
    String userMessage,
    List<Map<String, String>> history,
    String? imageBase64,
  ) async {
    final dynamic userContent = imageBase64 != null
        ? [
            {"type": "text", "text": userMessage.isNotEmpty ? userMessage : "Describe this image."},
            {"type": "image_url", "image_url": {"url": imageBase64}},
          ]
        : userMessage;

    final body = jsonEncode({
      'model': model,
      'messages': [
        ...history,
        {'role': 'user', 'content': userContent},
      ],
    });

    http.Response res;
    try {
      res = await http
          .post(Uri.parse('$_base/chat/completions'),
              headers: _headers, body: body)
          .timeout(const Duration(seconds: 30));
    } on TimeoutException {
      throw _RetryableError('timed out');
    } catch (e) {
      throw _RetryableError('network error: $e');
    }

    // Bad key / unauthorized — no point trying other models.
    if (res.statusCode == 401 || res.statusCode == 403) {
      throw _FatalError(
          'Invalid or unauthorized OpenRouter API key (HTTP ${res.statusCode}).');
    }

    // Rate limited (OpenRouter-level or passed through from the provider).
    if (res.statusCode == 429) {
      throw _RetryableError('rate limited (HTTP 429)');
    }

    // Upstream provider outage.
    if (res.statusCode >= 500) {
      throw _RetryableError('provider outage (HTTP ${res.statusCode})');
    }

    if (res.statusCode != 200) {
      // Covers "Provider returned error", model retired/not found,
      // request shape the specific model doesn't support, etc.
      throw _RetryableError('HTTP ${res.statusCode}: ${res.body}');
    }

    final data = jsonDecode(res.body) as Map<String, dynamic>;

    if (data['error'] != null) {
      throw _RetryableError(data['error'].toString());
    }

    final choices = data['choices'] as List?;
    if (choices == null || choices.isEmpty) {
      throw _RetryableError('empty response from provider');
    }

    return choices.first['message']['content'] as String;
  }
}
