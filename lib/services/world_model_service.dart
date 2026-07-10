import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/world_model.dart';

class WorldModelService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  String get uid => FirebaseAuth.instance.currentUser!.uid;

  Stream<List<WorldModelNode>> get worldStream => _db
          .collection('users')
          .doc(uid)
          .collection('world')
          .doc('root')
          .snapshots()
          .map((doc) {
        if (doc.exists) {
          final data = doc.data()!;
          final children = (data['nodes'] as List?)
                  ?.map((n) => WorldModelNode.fromMap(n))
                  .toList() ??
              [];
          return children;
        }
        return [];
      });

  Future<void> saveWorld(List<WorldModelNode> nodes) async {
    await _db
        .collection('users')
        .doc(uid)
        .collection('world')
        .doc('root')
        .set({
      'nodes': nodes.map((n) => n.toMap()).toList(),
    });
  }
}
