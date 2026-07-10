import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:uuid/uuid.dart';
import '../models/audit_entry.dart';

class AuditService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  String get uid => FirebaseAuth.instance.currentUser!.uid;

  Future<void> log({
    required String agent,
    required String action,
    required String tier,
    required Map<String, dynamic> details,
  }) async {
    final entry = AuditEntry(
      id: const Uuid().v4(),
      agent: agent,
      action: action,
      tier: tier,
      details: details,
      userId: uid,
      timestamp: DateTime.now(),
    );
    await _db.collection('users').doc(uid).collection('audit').doc(entry.id).set(entry.toMap());
  }

  Stream<List<AuditEntry>> get entries => _db
          .collection('users')
          .doc(uid)
          .collection('audit')
          .orderBy('timestamp', descending: true)
          .limit(100)
          .snapshots()
          .map((snap) =>
              snap.docs.map((d) => AuditEntry.fromMap(d.data())).toList());
}
