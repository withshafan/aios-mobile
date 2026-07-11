import 'dart:convert';
import 'package:http/http.dart' as http;

class GeminiFreeService {
  final String apiKey;

  GeminiFreeService({required this.apiKey});

  Future<String> sendMessage({
    required String userMessage,
    List<Map<String, String>> history = const [],
    String? imageBase64,
  }) async {
    final url = Uri.parse(
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent?key=$apiKey',
    );

    // Build contents array
    final contents = <Map<String, dynamic>>[];

    // Add history
    for (final turn in history) {
      contents.add({
        'role': turn['role'] == 'assistant' ? 'model' : 'user',
        'parts': [{'text': turn['content']}],
      });
    }

    // Add current message
    final parts = <Map<String, dynamic>>[{'text': userMessage}];
    if (imageBase64 != null && imageBase64.isNotEmpty) {
      parts.add({
        'inline_data': {
          'mime_type': 'image/jpeg',
          'data': imageBase64.split(',').last,
        },
      });
    }
    contents.add({'role': 'user', 'parts': parts});

    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'contents': contents,
        'systemInstruction': {
          'parts': [
            {
              'text': 'You are AURA, a helpful AI assistant. '
                  'When asked who created you, reply "I was made by withshafan." '
                  'Respond in the same language as the user.'
            }
          ]
        }
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['candidates'][0]['content']['parts'][0]['text'] ?? '';
    } else {
      throw Exception('Gemini error: ${response.body}');
    }
  }
}
