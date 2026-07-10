import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class MemoryIntegrityService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  String get uid => FirebaseAuth.instance.currentUser!.uid;

  // Find potentially stale or conflicting chat messages
  Future<List<Map<String, dynamic>>> findConflicts() async {
    // Simple heuristic: older messages marked as "corrected" or contradictory phrases
    final snaps = await _db
        .collection('users')
        .doc(uid)
        .collection('chats')
        .where('isUser', isEqualTo: false)
        .orderBy('timestamp', descending: false)
        .get();
    final messages = snaps.docs.map((d) => d.data()).toList();
    List<Map<String, dynamic>> conflicts = [];
    for (int i = 0; i < messages.length - 1; i++) {
      final curr = messages[i];
      final next = messages[i + 1];
      // If both are from AI and contain contradictory keywords (e.g., "remember" vs "forget")
      if (curr['content'].toString().contains('remember') &&
          next['content'].toString().contains('forget')) {
        conflicts.add({
          'first': curr,
          'second': next,
        });
      }
    }
    return conflicts;
  }

  // Archive old, unused memories
  Future<void> archiveOldMemories(int days) async {
    final cutoff = DateTime.now().subtract(Duration(days: days));
    final snaps = await _db
        .collection('users')
        .doc(uid)
        .collection('chats')
        .where('timestamp', isLessThanOrEqualTo: cutoff.toIso8601String())
        .get();
    final batch = _db.batch();
    for (var doc in snaps.docs) {
      batch.update(doc.reference, {'archived': true});
    }
    await batch.commit();
  }

  Future<void> forgetAbout(String keyword) async {
    final snaps = await _db
        .collection('users')
        .doc(uid)
        .collection('chats')
        .get();
    final batch = _db.batch();
    for (var doc in snaps.docs) {
      final content = doc.data()['content'].toString().toLowerCase();
      if (content.contains(keyword.toLowerCase())) {
        batch.delete(doc.reference);
      }
    }
    await batch.commit();
  }
}
