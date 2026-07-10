import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/multi_llm_service.dart';
import '../models/llm_provider.dart';

class LLMProvidersScreen extends StatelessWidget {
  const LLMProvidersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Universal AI Ecosystem')),
      body: StreamBuilder<List<LLMProvider>>(
        stream: context.read<MultiLLMService>().providers,
        builder: (ctx, snap) {
          final providers = snap.data ?? [];
          return ListView.builder(
            itemCount: providers.length,
            itemBuilder: (_, i) {
              final p = providers[i];
              return Card(
                child: ListTile(
                  title: Text(p.name),
                  subtitle: Text(p.isEnabled ? 'Enabled (priority ${p.priority})' : 'Disabled'),
                  trailing: Switch(
                    value: p.isEnabled,
                    onChanged: (val) {
                      p.isEnabled = val;
                      context.read<MultiLLMService>().saveProvider(p);
                    },
                  ),
                  onTap: () => _editProvider(context, p),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.add),
        onPressed: () => _editProvider(context, null),
      ),
    );
  }

  void _editProvider(BuildContext context, LLMProvider? provider) {
    final nameCtrl = TextEditingController(text: provider?.name);
    final keyCtrl = TextEditingController(text: provider?.apiKey);
    final urlCtrl = TextEditingController(text: provider?.baseUrl);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(provider == null ? 'Add Provider' : 'Edit Provider'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Name')),
            TextField(controller: keyCtrl, decoration: const InputDecoration(labelText: 'API Key')),
            TextField(controller: urlCtrl, decoration: const InputDecoration(labelText: 'Base URL')),
          ],
        ),
        actions: [
          TextButton(child: const Text('Cancel'), onPressed: () => Navigator.pop(ctx)),
          TextButton(
            child: const Text('Save'),
            onPressed: () {
              final newProvider = LLMProvider(
                id: provider?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
                name: nameCtrl.text,
                apiKey: keyCtrl.text,
                baseUrl: urlCtrl.text,
                isEnabled: provider?.isEnabled ?? false,
                priority: provider?.priority ?? 10,
              );
              context.read<MultiLLMService>().saveProvider(newProvider);
              Navigator.pop(ctx);
            },
          ),
        ],
      ),
    );
  }
}
