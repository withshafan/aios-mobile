class AuditEntry {
  final String id;
  final String agent;          // e.g., 'email', 'calendar', 'browser'
  final String action;         // 'send_email', 'create_event', etc.
  final String tier;           // 'read-only', 'reversible', 'irreversible'
  final Map<String, dynamic> details; // what happened
  final String userId;
  final DateTime timestamp;

  AuditEntry({
    required this.id,
    required this.agent,
    required this.action,
    required this.tier,
    required this.details,
    required this.userId,
    required this.timestamp,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'agent': agent,
        'action': action,
        'tier': tier,
        'details': details,
        'userId': userId,
        'timestamp': timestamp.toIso8601String(),
      };

  factory AuditEntry.fromMap(Map<String, dynamic> map) => AuditEntry(
        id: map['id'],
        agent: map['agent'],
        action: map['action'],
        tier: map['tier'],
        details: Map<String, dynamic>.from(map['details']),
        userId: map['userId'],
        timestamp: DateTime.parse(map['timestamp']),
      );
}
