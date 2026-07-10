import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ContinuityService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  String get uid => FirebaseAuth.instance.currentUser!.uid;

  Future<void> saveState({
    int? selectedNavIndex,
    String? activeChatScreen, // 'chat', 'tasks', etc.
    String? lastMessage,
  }) async {
    await _db.collection('users').doc(uid).collection('state').doc('session').set({
      'selectedNavIndex': selectedNavIndex,
      'activeChatScreen': activeChatScreen,
      'lastMessage': lastMessage,
      'lastUpdated': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<Map<String, dynamic>?> restoreState() async {
    try {
      final doc = await _db.collection('users').doc(uid).collection('state').doc('session').get();
      return doc.data();
    } catch (e) {
      return null;
    }
  }
}
