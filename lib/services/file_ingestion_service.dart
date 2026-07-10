import 'dart:convert';
import 'dart:typed_data';
import '../models/file_attachment.dart';

class FileIngestionService {
  /// Extract text content from a file based on its MIME type.
  /// Returns the extracted text, or null if unsupported.
  Future<String?> extractText(FileAttachment attachment) async {
    switch (attachment.mimeType) {
      case 'text/plain':
      case 'application/json':
      case 'text/markdown':
        return utf8.decode(attachment.bytes);
      case 'application/pdf':
        return _extractPdf(attachment.bytes);
      case 'application/vnd.openxmlformats-officedocument.wordprocessingml.document':
        return _extractDocx(attachment.bytes);
      case 'image/jpeg':
      case 'image/png':
      case 'image/webp':
        // Will be handled by Gemini vision later; return placeholder
        return '[Image attached: ${attachment.fileName}]';
      default:
        return null; // unsupported
    }
  }

  Future<String> _extractPdf(List<int> bytes) async {
    // pdf_text had dependency conflicts, so stubbing this out.
    return '[Text extracted from PDF (placeholder)]';
  }

  String _extractDocx(List<int> bytes) {
    // docx package does not exist, stubbing this out.
    return '[Text extracted from DOCX (placeholder)]';
  }
}
