class LLMProvider {
  final String id;
  String name;
  String apiKey;
  String baseUrl;
  bool isEnabled;
  int priority; // lower = higher priority

  LLMProvider({
    required this.id,
    required this.name,
    this.apiKey = '',
    required this.baseUrl,
    this.isEnabled = false,
    this.priority = 10,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'apiKey': apiKey,
        'baseUrl': baseUrl,
        'isEnabled': isEnabled,
        'priority': priority,
      };

  factory LLMProvider.fromMap(Map<String, dynamic> map) => LLMProvider(
        id: map['id'],
        name: map['name'],
        apiKey: map['apiKey'] ?? '',
        baseUrl: map['baseUrl'],
        isEnabled: map['isEnabled'] ?? false,
        priority: map['priority'] ?? 10,
      );
}
