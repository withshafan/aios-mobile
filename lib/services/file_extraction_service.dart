import 'dart:io';
import 'package:archive/archive.dart';
import 'package:xml/xml.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';

class FileExtractionService {
  /// Extract text from a file based on its extension.
  /// Returns the extracted text, or null if format unsupported.
  Future<String?> extract(File file) async {
    final ext = file.path.split('.').last.toLowerCase();
    switch (ext) {
      case 'txt':
      case 'md':
      case 'json':
      case 'csv':
      case 'yaml':
      case 'xml':
        return await file.readAsString();
      case 'pdf':
        return _extractPdf(file);
      case 'docx':
        return _extractDocx(file);
      case 'jpg':
      case 'jpeg':
      case 'png':
      case 'webp':
        // Images are handled as base64, not text
        return null;
      default:
        return null; // Unsupported format – AI will only get file name + size
    }
  }

  Future<String?> _extractPdf(File file) async {
    try {
      final bytes = await file.readAsBytes();
      final PdfDocument document = PdfDocument(inputBytes: bytes);
      String text = PdfTextExtractor(document).extractText();
      document.dispose();
      return text;
    } catch (_) {
      return null;
    }
  }

  Future<String?> _extractDocx(File file) async {
    try {
      final bytes = await file.readAsBytes();
      final archive = ZipDecoder().decodeBytes(bytes);
      final docFile = archive.findFile('word/document.xml');
      if (docFile == null) return null;
      
      final content = String.fromCharCodes(docFile.content as List<int>);
      final document = XmlDocument.parse(content);
      
      final paragraphs = document.findAllElements('w:p');
      final buffer = StringBuffer();
      
      for (var paragraph in paragraphs) {
        final texts = paragraph.findAllElements('w:t');
        for (var text in texts) {
          buffer.write(text.innerText);
        }
        buffer.writeln();
      }
      return buffer.toString();
    } catch (_) {
      return null;
    }
  }
}
