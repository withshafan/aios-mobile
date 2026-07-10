import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/connected_service.dart';

class ConnectedServicesService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  String get uid => FirebaseAuth.instance.currentUser!.uid;

  Stream<List<ConnectedService>> get services => _db
          .collection('users')
          .doc(uid)
          .collection('connected_services')
          .snapshots()
          .map((snap) => snap.docs
              .map((d) => ConnectedService.fromMap(d.data()))
              .toList());

  Future<void> addService(ConnectedService service) async {
    await _db
        .collection('users')
        .doc(uid)
        .collection('connected_services')
        .doc(service.id)
        .set(service.toMap(), SetOptions(merge: true));
  }

  Future<void> removeService(String id) async {
    await _db
        .collection('users')
        .doc(uid)
        .collection('connected_services')
        .doc(id)
        .delete();
  }

  // Seed default available services (called once)
  static Future<void> seedAvailableServices(FirebaseFirestore db, String uid) async {
    final snap = await db.collection('users').doc(uid).collection('connected_services').get();
    if (snap.docs.isNotEmpty) return;
    final defaults = [
      ConnectedService(id: 'google_drive', name: 'Google Drive', icon: 'cloud'),
      ConnectedService(id: 'github', name: 'GitHub', icon: 'code'),
      ConnectedService(id: 'gmail', name: 'Gmail', icon: 'email'),
      ConnectedService(id: 'notion', name: 'Notion', icon: 'description'),
      ConnectedService(id: 'slack', name: 'Slack', icon: 'chat'),
    ];
    for (var service in defaults) {
      await db.collection('users').doc(uid).collection('connected_services').doc(service.id).set(service.toMap());
    }
  }
}
