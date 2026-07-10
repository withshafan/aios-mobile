class StrategicMission {
  String id;
  String title;
  String description;
  double progress;
  List<String> objectives;
  List<String> milestones;
  DateTime createdAt;
  DateTime? deadline;

  StrategicMission({
    required this.id,
    required this.title,
    this.description = '',
    this.progress = 0,
    this.objectives = const [],
    this.milestones = const [],
    required this.createdAt,
    this.deadline,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'title': title,
        'description': description,
        'progress': progress,
        'objectives': objectives,
        'milestones': milestones,
        'createdAt': createdAt.toIso8601String(),
        'deadline': deadline?.toIso8601String(),
      };

  factory StrategicMission.fromMap(Map<String, dynamic> map) => StrategicMission(
        id: map['id'],
        title: map['title'],
        description: map['description'] ?? '',
        progress: (map['progress'] ?? 0).toDouble(),
        objectives: List<String>.from(map['objectives'] ?? []),
        milestones: List<String>.from(map['milestones'] ?? []),
        createdAt: DateTime.parse(map['createdAt']),
        deadline: map['deadline'] != null ? DateTime.parse(map['deadline']) : null,
      );
}
