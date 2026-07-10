import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/webhook_service.dart';

class WebhookManagementScreen extends StatelessWidget {
  const WebhookManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final service = context.read<WebhookService>();
    final eventCtrl = TextEditingController();
    final urlCtrl = TextEditingController();

    return Scaffold(
      appBar: AppBar(title: const Text('Webhook Triggers')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(child: TextField(controller: eventCtrl, decoration: const InputDecoration(labelText: 'Event Name'))),
                const SizedBox(width: 8),
                Expanded(child: TextField(controller: urlCtrl, decoration: const InputDecoration(labelText: 'URL'))),
                IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: () {
                    service.addWebhook(eventCtrl.text, urlCtrl.text);
                    eventCtrl.clear();
                    urlCtrl.clear();
                  },
                ),
              ],
            ),
          ),
          const Divider(),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: service.webhooks,
              builder: (ctx, snap) {
                if (!snap.hasData) return const CircularProgressIndicator();
                final docs = snap.data!.docs;
                return ListView.builder(
                  itemCount: docs.length,
                  itemBuilder: (ctx, i) {
                    final data = docs[i].data() as Map<String, dynamic>;
                    return ListTile(
                      title: Text(data['event']),
                      subtitle: Text(data['url']),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete),
                        onPressed: () => service.deleteWebhook(docs[i].id),
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
