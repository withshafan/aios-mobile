class ApprovalMatrixEntry {
  String actionCategory;
  String tier; // 'auto_approve', 'notify_only', 'require_confirm', 'require_biometric'

  ApprovalMatrixEntry({
    required this.actionCategory,
    required this.tier,
  });

  Map<String, dynamic> toMap() => {
        'actionCategory': actionCategory,
        'tier': tier,
      };

  factory ApprovalMatrixEntry.fromMap(Map<String, dynamic> map) =>
      ApprovalMatrixEntry(
        actionCategory: map['actionCategory'],
        tier: map['tier'] ?? 'require_confirm',
      );
}
