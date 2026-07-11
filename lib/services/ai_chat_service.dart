import 'package:flutter/foundation.dart';
import 'openrouter_service.dart';

class AiChatService {
  final String openRouterApiKey;
  final String? modelOverride;

  AiChatService({
    required this.openRouterApiKey,
    this.modelOverride,
  }) {
    debugPrint('🔑 AiChatService key: ${openRouterApiKey.length > 10 ? openRouterApiKey.substring(0, 10) : openRouterApiKey}...');
  }

  Future<String> sendMessage({
    required String userMessage,
    List<Map<String, String>> history = const [],
    String? imageBase64,
    String? modelOverride,
  }) async {
    final service = OpenRouterService(
      apiKey: openRouterApiKey,
      model: modelOverride ?? this.modelOverride ?? 'tencent/hy3',
    );
    final response = await service.sendMessage(
      userMessage: userMessage,
      history: history,
      imageBase64: imageBase64,
      modelOverride: modelOverride ?? this.modelOverride,
    );
    return response.text;
  }
}
