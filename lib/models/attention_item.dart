class AttentionItem {
  String id;
  String title;
  String type;
  int urgency;
  int importance;
  DateTime timestamp;
  bool isRead;

  AttentionItem({
    required this.id,
    required this.title,
    this.type = 'notification',
    this.urgency = 5,
    this.importance = 5,
    required this.timestamp,
    this.isRead = false,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'title': title,
        'type': type,
        'urgency': urgency,
        'importance': importance,
        'timestamp': timestamp.toIso8601String(),
        'isRead': isRead,
      };

  factory AttentionItem.fromMap(Map<String, dynamic> map) =>
      AttentionItem(
        id: map['id'],
        title: map['title'],
        type: map['type'] ?? 'notification',
        urgency: map['urgency'] ?? 5,
        importance: map['importance'] ?? 5,
        timestamp: DateTime.parse(map['timestamp']),
        isRead: map['isRead'] ?? false,
      );
}
