import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/collaboration_service.dart';

class SharedProjectsScreen extends StatelessWidget {
  const SharedProjectsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final service = context.read<CollaborationService>();
    final nameCtrl = TextEditingController();

    return Scaffold(
      appBar: AppBar(title: const Text('Shared Workspaces')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(child: TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'New Project Name'))),
                IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: () {
                    service.createProject(nameCtrl.text);
                    nameCtrl.clear();
                  },
                ),
              ],
            ),
          ),
          const Divider(),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: service.myProjects,
              builder: (ctx, snap) {
                if (!snap.hasData) return const CircularProgressIndicator();
                final docs = snap.data!.docs;
                return ListView.builder(
                  itemCount: docs.length,
                  itemBuilder: (ctx, i) {
                    final data = docs[i].data() as Map<String, dynamic>;
                    return ListTile(
                      title: Text(data['name']),
                      subtitle: Text('Members: ${(data['members'] as List).length}'),
                      trailing: IconButton(
                        icon: const Icon(Icons.person_add),
                        onPressed: () {
                          // Show dialog to invite member
                        },
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
