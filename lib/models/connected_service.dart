class ConnectedService {
  final String id;          // e.g., 'google_drive', 'github'
  final String name;
  final String icon;        // icon code point (Icons class)
  bool isConnected;
  String? accessToken;

  ConnectedService({
    required this.id,
    required this.name,
    required this.icon,
    this.isConnected = false,
    this.accessToken,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'icon': icon,
        'isConnected': isConnected,
        'accessToken': accessToken,
      };

  factory ConnectedService.fromMap(Map<String, dynamic> map) =>
      ConnectedService(
        id: map['id'],
        name: map['name'],
        icon: map['icon'],
        isConnected: map['isConnected'] ?? false,
        accessToken: map['accessToken'],
      );
}
