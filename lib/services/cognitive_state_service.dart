import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/cognitive_state.dart';

class CognitiveStateService {
  CognitiveStateService() {
    debugPrint('CognitiveStateService constructor START');
    debugPrint('CognitiveStateService constructor END');
  }
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  String get uid => FirebaseAuth.instance.currentUser!.uid;

  Stream<CognitiveState> get stateStream => _db
          .collection('users')
          .doc(uid)
          .collection('cognitive')
          .doc('state')
          .snapshots()
          .map((doc) {
        if (doc.exists) {
          return CognitiveState.fromMap(doc.data()!);
        }
        return CognitiveState();
      });

  Future<void> updateState(CognitiveState state) async {
    await _db
        .collection('users')
        .doc(uid)
        .collection('cognitive')
        .doc('state')
        .set(state.toMap(), SetOptions(merge: true));
  }
}
