class LifeTimelineEvent {
  String id;
  String title;
  String category;
  DateTime date;
  String description;

  LifeTimelineEvent({
    required this.id,
    required this.title,
    required this.category,
    required this.date,
    this.description = '',
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'title': title,
        'category': category,
        'date': date.toIso8601String(),
        'description': description,
      };

  factory LifeTimelineEvent.fromMap(Map<String, dynamic> map) =>
      LifeTimelineEvent(
        id: map['id'],
        title: map['title'],
        category: map['category'],
        date: DateTime.parse(map['date']),
        description: map['description'] ?? '',
      );
}
