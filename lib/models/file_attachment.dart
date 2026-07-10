class FileAttachment {
  final String fileName;
  final String mimeType;
  final List<int> bytes;
  final String? extractedText; // filled after processing

  FileAttachment({
    required this.fileName,
    required this.mimeType,
    required this.bytes,
    this.extractedText,
  });
}
