import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/plugin_service.dart';
import '../models/plugin_info.dart';

class PluginMarketplaceScreen extends StatelessWidget {
  const PluginMarketplaceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final pluginService = context.read<PluginService>();
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('plugin_marketplace').snapshots(),
      builder: (ctx, snap) {
        if (!snap.hasData) return const Center(child: CircularProgressIndicator());
        final plugins = snap.data!.docs.map((d) => PluginInfo.fromFirestore(d.data() as Map<String, dynamic>, d.id)).toList();
        return ListView.builder(
          itemCount: plugins.length,
          itemBuilder: (_, i) {
            final p = plugins[i];
            return ListTile(
              title: Text(p.name),
              subtitle: Text(p.description),
              trailing: ElevatedButton(
                child: const Text('Install'),
                onPressed: () async {
                  // Install by adding to user's plugins collection
                  await FirebaseFirestore.instance
                      .collection('users')
                      .doc(pluginService.userId)
                      .collection('plugins')
                      .doc(p.id)
                      .set(p.toFirestore());
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Plugin ${p.name} installed')),
                  );
                },
              ),
            );
          },
        );
      },
    );
  }
}
