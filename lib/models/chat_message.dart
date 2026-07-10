class ChatMessage {
  final String id;
  final String content;
  final bool isUser;
  final DateTime timestamp;
  final String? imageUrl;
  final List<String>? sources;

  ChatMessage({
    required this.id,
    required this.content,
    required this.isUser,
    required this.timestamp,
    this.imageUrl,
    this.sources,
  });

  Map<String, dynamic> toFirestore() {
    return {
      'content': content,
      'isUser': isUser,
      'timestamp': timestamp.toIso8601String(),
      if (imageUrl != null) 'imageUrl': imageUrl,
      if (sources != null) 'sources': sources,
    };
  }

  factory ChatMessage.fromFirestore(Map<String, dynamic> data, String id) {
    return ChatMessage(
      id: id,
      content: data['content'] ?? '',
      isUser: data['isUser'] ?? true,
      timestamp: DateTime.parse(data['timestamp']),
      imageUrl: data['imageUrl'] as String?,
      sources: (data['sources'] as List?)?.map((e) => e as String).toList(),
    );
  }
}
