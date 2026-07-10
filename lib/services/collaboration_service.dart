import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CollaborationService {
  String get uid => FirebaseAuth.instance.currentUser!.uid;

  Future<void> createProject(String name) async {
    final doc = await FirebaseFirestore.instance.collection('projects').add({
      'name': name,
      'owner': uid,
      'members': [uid],
      'createdAt': FieldValue.serverTimestamp(),
    });
    await doc.collection('tasks').add({'title': 'Sample task', 'done': false});
  }

  Future<void> inviteMember(String projectId, String email) async {
    // In production, you'd use Firebase Auth to get user by email; for now just store email.
    await FirebaseFirestore.instance.collection('projects').doc(projectId).update({
      'members': FieldValue.arrayUnion([email]),
    });
  }

  Stream<QuerySnapshot> get myProjects => FirebaseFirestore.instance
      .collection('projects')
      .where('members', arrayContains: uid)
      .snapshots();
}
