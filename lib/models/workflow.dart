class Workflow {
  final String id;
  final String name;
  final String triggerType; // 'time'
  final String triggerData; // e.g., '09:00' for time-based
  final String actionType; // 'create_task' or 'notification'
  final String actionData; // task title or notification text
  final bool isActive;

  Workflow({
    required this.id,
    required this.name,
    required this.triggerType,
    required this.triggerData,
    required this.actionType,
    required this.actionData,
    this.isActive = true,
  });

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'triggerType': triggerType,
      'triggerData': triggerData,
      'actionType': actionType,
      'actionData': actionData,
      'isActive': isActive,
    };
  }

  factory Workflow.fromFirestore(Map<String, dynamic> data, String id) {
    return Workflow(
      id: id,
      name: data['name'] ?? '',
      triggerType: data['triggerType'] ?? 'time',
      triggerData: data['triggerData'] ?? '09:00',
      actionType: data['actionType'] ?? 'create_task',
      actionData: data['actionData'] ?? '',
      isActive: data['isActive'] ?? true,
    );
  }
}
