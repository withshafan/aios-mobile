import 'dart:convert';
import 'dart:io';

class ImageUtils {
  /// Reads [file] and returns a base64 data URI ready to drop into
  /// an OpenRouter/OpenAI-style "image_url" content block.
  static Future<String> fileToBase64DataUri(File file) async {
    final bytes = await file.readAsBytes();
    final base64Str = base64Encode(bytes);
    final mimeType = _mimeTypeFromPath(file.path);
    return 'data:$mimeType;base64,$base64Str';
  }

  static String _mimeTypeFromPath(String path) {
    final ext = path.split('.').last.toLowerCase();
    switch (ext) {
      case 'png':
        return 'image/png';
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'webp':
        return 'image/webp';
      case 'gif':
        return 'image/gif';
      case 'heic':
      case 'heif':
        return 'image/heic';
      default:
        return 'image/jpeg'; // safe fallback
    }
  }
}
