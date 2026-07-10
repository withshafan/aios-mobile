import 'package:google_generative_ai/google_generative_ai.dart';

class GeminiService {
  static const String apiKey = 'AQ.Ab8RN6KKbYNwtMLsyVu1mbIkLRvwoqpLMfPL0L5aDsa7XgDTig'; // Replace this
  late final GenerativeModel _model;

  GeminiService() {
    _model = GenerativeModel(model: 'gemini-2.0-flash', apiKey: apiKey);
  }

  Future<String> generateResponse(String prompt, List<String>? history) async {
    final chat = _model.startChat(history: history?.map((text) => Content.text(text)).toList());
    final content = Content.text(prompt);
    final response = await chat.sendMessage(content);
    return response.text ?? 'I could not process that.';
  }
}
