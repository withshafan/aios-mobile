class PluginInfo {
  final String id;
  final String name;
  final String description;
  final String functionName; // name used in Gemini function calling
  final Map<String, dynamic> parameters; // schema for function
  final bool isEnabled;

  PluginInfo({
    required this.id,
    required this.name,
    required this.description,
    required this.functionName,
    required this.parameters,
    this.isEnabled = false,
  });

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'description': description,
      'functionName': functionName,
      'parameters': parameters,
      'isEnabled': isEnabled,
    };
  }

  factory PluginInfo.fromFirestore(Map<String, dynamic> data, String id) {
    return PluginInfo(
      id: id,
      name: data['name'] ?? '',
      description: data['description'] ?? '',
      functionName: data['functionName'] ?? '',
      parameters: Map<String, dynamic>.from(data['parameters'] ?? {}),
      isEnabled: data['isEnabled'] ?? false,
    );
  }
}
