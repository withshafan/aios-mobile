class KnowledgeItem {
  final String id;
  final String title;
  final String content;
  final String source;     // 'gmail', 'drive', 'chatgpt', etc.
  final DateTime timestamp;

  KnowledgeItem({
    required this.id,
    required this.title,
    required this.content,
    required this.source,
    required this.timestamp,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'title': title,
        'content': content,
        'source': source,
        'timestamp': timestamp.toIso8601String(),
      };

  factory KnowledgeItem.fromMap(Map<String, dynamic> map) =>
      KnowledgeItem(
        id: map['id'],
        title: map['title'],
        content: map['content'],
        source: map['source'],
        timestamp: DateTime.parse(map['timestamp']),
      );
}
