class CognitiveState {
  String currentFocus;
  List<String> backgroundTasks;
  List<String> pendingApprovals;
  List<String> waitingConditions;
  String recentlyCompleted;
  String nextPlanned;
  String userPriority;
  double confidence;
  String operatingMode;

  CognitiveState({
    this.currentFocus = '',
    this.backgroundTasks = const [],
    this.pendingApprovals = const [],
    this.waitingConditions = const [],
    this.recentlyCompleted = '',
    this.nextPlanned = '',
    this.userPriority = '',
    this.confidence = 0.96,
    this.operatingMode = 'Assisted',
  });

  Map<String, dynamic> toMap() => {
        'currentFocus': currentFocus,
        'backgroundTasks': backgroundTasks,
        'pendingApprovals': pendingApprovals,
        'waitingConditions': waitingConditions,
        'recentlyCompleted': recentlyCompleted,
        'nextPlanned': nextPlanned,
        'userPriority': userPriority,
        'confidence': confidence,
        'operatingMode': operatingMode,
      };

  factory CognitiveState.fromMap(Map<String, dynamic> map) => CognitiveState(
        currentFocus: map['currentFocus'] ?? '',
        backgroundTasks: List<String>.from(map['backgroundTasks'] ?? []),
        pendingApprovals: List<String>.from(map['pendingApprovals'] ?? []),
        waitingConditions: List<String>.from(map['waitingConditions'] ?? []),
        recentlyCompleted: map['recentlyCompleted'] ?? '',
        nextPlanned: map['nextPlanned'] ?? '',
        userPriority: map['userPriority'] ?? '',
        confidence: (map['confidence'] ?? 0.96).toDouble(),
        operatingMode: map['operatingMode'] ?? 'Assisted',
      );
}
