class AgentRole {
  final String id;
  final String name;
  final String description;
  final String parentId; // empty for root

  AgentRole({
    required this.id,
    required this.name,
    required this.description,
    this.parentId = '',
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'description': description,
        'parentId': parentId,
      };

  factory AgentRole.fromMap(Map<String, dynamic> map) => AgentRole(
        id: map['id'],
        name: map['name'],
        description: map['description'],
        parentId: map['parentId'] ?? '',
      );
}
