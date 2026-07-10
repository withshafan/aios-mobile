import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class DigitalTwinService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  String get uid => FirebaseAuth.instance.currentUser!.uid;

  Future<Map<String, dynamic>?> getProfile() async {
    final doc = await _db.collection('users').doc(uid).collection('profile').doc('digital_twin').get();
    return doc.data();
  }

  Future<void> updateProfile(Map<String, dynamic> data) async {
    await _db.collection('users').doc(uid).collection('profile').doc('digital_twin').set(data, SetOptions(merge: true));
  }
}
