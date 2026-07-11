import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

class ImageGenerationService {
  final String apiToken;

  ImageGenerationService({required this.apiToken});

  /// Generates an image and returns the local file path.
  Future<String> generateImage(String prompt) async {
    final response = await http.post(
      Uri.parse('https://api-inference.huggingface.co/models/stabilityai/stable-diffusion-2-1'),
      headers: {
        'Authorization': 'Bearer $apiToken',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'inputs': prompt,
      }),
    );

    if (response.statusCode == 200) {
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/aura_generated_${DateTime.now().millisecondsSinceEpoch}.png');
      await file.writeAsBytes(response.bodyBytes);
      return file.path;
    } else {
      final error = jsonDecode(response.body);
      throw Exception(error['error'] ?? 'Image generation failed');
    }
  }
}
