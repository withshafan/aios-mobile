import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/agent_role.dart';

class AgentTeamService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  String get uid => FirebaseAuth.instance.currentUser!.uid;

  Stream<List<AgentRole>> get teamRoles => _db
          .collection('users')
          .doc(uid)
          .collection('team_roles')
          .snapshots()
          .map((snap) => snap.docs
              .map((d) => AgentRole.fromMap(d.data()))
              .toList());

  Future<void> seedTeam() async {
    final existing = await _db.collection('users').doc(uid).collection('team_roles').get();
    if (existing.docs.isNotEmpty) return;
    final roles = [
      AgentRole(id: 'ceo', name: 'CEO Agent', description: 'Oversees all operations'),
      AgentRole(id: 'planner', name: 'Planner Agent', description: 'Decomposes tasks', parentId: 'ceo'),
      AgentRole(id: 'architect', name: 'Architect Agent', description: 'Designs solutions', parentId: 'planner'),
      AgentRole(id: 'backend', name: 'Backend Engineer', description: 'Builds server logic', parentId: 'architect'),
      AgentRole(id: 'frontend', name: 'Frontend Engineer', description: 'Builds UI', parentId: 'architect'),
      AgentRole(id: 'security', name: 'Security Agent', description: 'Audits and protects', parentId: 'architect'),
    ];
    final batch = _db.batch();
    for (var role in roles) {
      final ref = _db.collection('users').doc(uid).collection('team_roles').doc(role.id);
      batch.set(ref, role.toMap());
    }
    await batch.commit();
  }
}
