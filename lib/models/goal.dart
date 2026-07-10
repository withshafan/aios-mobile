class Goal {
  String id;
  String title;
  String description;
  double progress; // 0.0 to 1.0
  List<String> milestones;
  List<SubTask> subtasks;
  DateTime createdAt;
  DateTime? deadline;

  Goal({
    required this.id,
    required this.title,
    this.description = '',
    this.progress = 0.0,
    this.milestones = const [],
    this.subtasks = const [],
    required this.createdAt,
    this.deadline,
  });

  Map<String, dynamic> toFirestore() => {
        'title': title,
        'description': description,
        'progress': progress,
        'milestones': milestones,
        'subtasks': subtasks.map((s) => s.toMap()).toList(),
        'createdAt': createdAt.toIso8601String(),
        'deadline': deadline?.toIso8601String(),
      };

  factory Goal.fromFirestore(Map<String, dynamic> data, String id) => Goal(
        id: id,
        title: data['title'] ?? '',
        description: data['description'] ?? '',
        progress: (data['progress'] ?? 0.0).toDouble(),
        milestones: List<String>.from(data['milestones'] ?? []),
        subtasks: (data['subtasks'] as List?)
                ?.map((s) => SubTask.fromMap(s))
                .toList() ??
            [],
        createdAt: DateTime.parse(data['createdAt']),
        deadline:
            data['deadline'] != null ? DateTime.parse(data['deadline']) : null,
      );
}

class SubTask {
  String name;
  bool isCompleted;

  SubTask({required this.name, this.isCompleted = false});

  Map<String, dynamic> toMap() => {'name': name, 'isCompleted': isCompleted};
  factory SubTask.fromMap(Map<String, dynamic> map) =>
      SubTask(name: map['name'], isCompleted: map['isCompleted'] ?? false);
}
