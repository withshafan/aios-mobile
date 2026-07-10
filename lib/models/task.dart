class AiosTask {
  final String id;
  final String title;
  final String? description;
  final DateTime dueDate;
  final bool isCompleted;
  final DateTime createdAt;

  AiosTask({
    required this.id,
    required this.title,
    this.description,
    required this.dueDate,
    this.isCompleted = false,
    required this.createdAt,
  });

  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'description': description,
      'dueDate': dueDate.toIso8601String(),
      'isCompleted': isCompleted,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory AiosTask.fromFirestore(Map<String, dynamic> data, String id) {
    return AiosTask(
      id: id,
      title: data['title'] ?? '',
      description: data['description'],
      dueDate: DateTime.parse(data['dueDate']),
      isCompleted: data['isCompleted'] ?? false,
      createdAt: DateTime.parse(data['createdAt']),
    );
  }
}
