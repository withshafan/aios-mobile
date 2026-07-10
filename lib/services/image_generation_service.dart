import 'package:http/http.dart' as http;

class ImageGenerationService {
  // Uses a free placeholder API that returns a random image URL based on prompt.
  // Replace with DALL-E/Stable Diffusion if you have an API key.
  Future<String?> generateImage(String prompt) async {
    try {
      final response = await http.get(
        Uri.parse('https://api.unsplash.com/photos/random?query=${Uri.encodeComponent(prompt)}'),
      );
      // Unsplash requires a Client-ID for production, but for demo we use a simple placeholder.
      // We'll return a static placeholder for now.
    } catch (e) {
      // Ignore
    }
    return 'https://picsum.photos/400/300?random&text=${Uri.encodeComponent(prompt)}';
  }
}
