import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ContinuityService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  String get uid => FirebaseAuth.instance.currentUser!.uid;

  Future<void> saveState({
    int? selectedNavIndex,
    String? activeChatScreen, // 'chat', 'tasks', etc.
    String? lastMessage,
    String? deviceName,
    int? screenIndex,
    String? lastActive,
  }) async {
    await _db.collection('users').doc(uid).collection('state').doc('session').set({
      if (selectedNavIndex != null) 'selectedNavIndex': selectedNavIndex,
      if (activeChatScreen != null) 'activeChatScreen': activeChatScreen,
      if (lastMessage != null) 'lastMessage': lastMessage,
      if (deviceName != null) 'deviceName': deviceName,
      if (screenIndex != null) 'screenIndex': screenIndex,
      'lastActive': FieldValue.serverTimestamp(),
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

  Future<Map<String, dynamic>?> getLastState() async {
    return restoreState();
  }
}
