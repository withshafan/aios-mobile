import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/approval_matrix.dart';
import 'package:flutter/foundation.dart';

class ApprovalService extends ChangeNotifier {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  String get uid => FirebaseAuth.instance.currentUser!.uid;

  Stream<List<ApprovalMatrixEntry>> get entries => _db
          .collection('users')
          .doc(uid)
          .collection('approval_matrix')
          .snapshots()
          .map((snap) => snap.docs
              .map((d) => ApprovalMatrixEntry.fromMap(d.data()))
              .toList());

  Future<void> updateEntry(ApprovalMatrixEntry entry) async {
    await _db
        .collection('users')
        .doc(uid)
        .collection('approval_matrix')
        .doc(entry.actionCategory)
        .set(entry.toMap());
  }

  Future<void> seedDefaults() async {
    final defaults = [
      'Send Email',
      'Calendar Event',
      'Browser Action',
      'ADB Command',
      'Delete File',
      'Self-Programming',
      'Plugin Install',
      'Workflow Trigger',
      'Research Output',
      'Document Generation',
    ];
    for (var cat in defaults) {
      await updateEntry(ApprovalMatrixEntry(actionCategory: cat, tier: 'require_confirm'));
    }
  }
}
