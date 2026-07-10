import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/tokens.dart';
import '../services/attention_service.dart';
import 'package:intl/intl.dart';

class AttentionCenterScreen extends StatelessWidget {
  const AttentionCenterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Attention Center')),
      body: StreamBuilder<List<AttentionItem>>(
        stream: context.read<AttentionService>().items,
        builder: (ctx, snap) {
          final items = snap.data ?? [];
          if (items.isEmpty) {
            return const Center(child: Text('All clear. Nothing needs your attention.'));
          }
          return ListView.builder(
            padding: const EdgeInsets.all(space4),
            itemCount: items.length,
            itemBuilder: (_, i) {
              final item = items[i];
              final urgencyColor = item.urgency >= 8 ? AppColors.accentCritical : (item.urgency >= 5 ? AppColors.accentWarning : AppColors.accentSuccess);
              return Dismissible(
                key: Key(item.id),
                background: Container(color: AppColors.accentSuccess, child: const Icon(Icons.done)),
                onDismissed: (_) => context.read<AttentionService>().markRead(item.id),
                child: Card(
                  color: AppColors.surfaceRaised,
                  margin: const EdgeInsets.only(bottom: space2),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: urgencyColor,
                      child: Icon(item.isRead ? Icons.done : Icons.warning, color: Colors.white, size: 20),
                    ),
                    title: Text(item.title),
                    subtitle: Text(
                      'Urgency ${item.urgency} · ${DateFormat.jm().format(item.timestamp)}',
                      style: const TextStyle(fontSize: 12),
                    ),
                    onTap: () => context.read<AttentionService>().markRead(item.id),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
