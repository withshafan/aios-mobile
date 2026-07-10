import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CircuitBreakerService {
  CircuitBreakerService() {
    debugPrint('CircuitBreakerService constructor START');
    debugPrint('CircuitBreakerService constructor END');
  }
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  String get uid => FirebaseAuth.instance.currentUser!.uid;

  // Checks if an agent is tripped (too many failures recently)
  Future<bool> isAgentTripped(String agentName) async {
    final now = DateTime.now();
    final cutoff = now.subtract(const Duration(minutes: 10));
    final snap = await _db
        .collection('users')
        .doc(uid)
        .collection('agent_failures')
        .where('agent', isEqualTo: agentName)
        .where('timestamp', isGreaterThanOrEqualTo: cutoff.toIso8601String())
        .get();
    return snap.docs.length >= 5; // trip after 5 failures in 10 min
  }

  // Record a failure for an agent
  Future<void> recordFailure(String agentName) async {
    await _db.collection('users').doc(uid).collection('agent_failures').add({
      'agent': agentName,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  // Reset after successful execution
  Future<void> clearFailures(String agentName) async {
    final batch = _db.batch();
    final snaps = await _db
        .collection('users')
        .doc(uid)
        .collection('agent_failures')
        .where('agent', isEqualTo: agentName)
        .get();
    for (var doc in snaps.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();
  }
}
