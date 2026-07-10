class WorldModelNode {
  String id;
  String name;
  String type; // 'project', 'folder', 'device', etc.
  String? parentId;
  List<WorldModelNode> children;

  WorldModelNode({
    required this.id,
    required this.name,
    required this.type,
    this.parentId,
    this.children = const [],
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'type': type,
        'parentId': parentId,
        'children': children.map((c) => c.toMap()).toList(),
      };

  factory WorldModelNode.fromMap(Map<String, dynamic> map) => WorldModelNode(
        id: map['id'],
        name: map['name'],
        type: map['type'],
        parentId: map['parentId'],
        children: (map['children'] as List?)
                ?.map((c) => WorldModelNode.fromMap(c))
                .toList() ??
            [],
      );
}
