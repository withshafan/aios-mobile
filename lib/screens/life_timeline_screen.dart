import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../theme/tokens.dart';
import '../services/life_timeline_service.dart';

class LifeTimelineScreen extends StatelessWidget {
  const LifeTimelineScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Life Timeline')),
      body: StreamBuilder<List<LifeTimelineEvent>>(
        stream: context.read<LifeTimelineService>().events,
        builder: (ctx, snap) {
          final events = snap.data ?? [];
          if (events.isEmpty) {
            return const Center(child: Text('No events yet. Your story is waiting.'));
          }
          return ListView.builder(
            padding: const EdgeInsets.all(space4),
            itemCount: events.length,
            itemBuilder: (_, i) {
              final event = events[i];
              return IntrinsicHeight(
                child: Row(
                  children: [
                    // Timeline indicator
                    Column(
                      children: [
                        Container(
                          width: 12,
                          height: 12,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.accentViolet,
                          ),
                        ),
                        Expanded(
                          child: Container(
                            width: 2,
                            color: AppColors.borderHairline,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: space3),
                    Expanded(
                      child: Card(
                        color: AppColors.surfaceRaised,
                        margin: const EdgeInsets.only(bottom: space2),
                        child: Padding(
                          padding: const EdgeInsets.all(space4),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(event.title, style: const TextStyle(fontWeight: FontWeight.w600)),
                              Text(DateFormat.yMMMd().format(event.date),
                                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                              if (event.description.isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.only(top: space1),
                                  child: Text(event.description),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.add),
        onPressed: () => _addEvent(context),
      ),
    );
  }

  void _addEvent(BuildContext context) {
    final titleCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Life Event'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: titleCtrl, decoration: const InputDecoration(labelText: 'Title')),
            TextField(controller: descCtrl, decoration: const InputDecoration(labelText: 'Description')),
          ],
        ),
        actions: [
          TextButton(
            child: const Text('Cancel'),
            onPressed: () => Navigator.pop(ctx),
          ),
          TextButton(
            child: const Text('Save'),
            onPressed: () {
              final event = LifeTimelineEvent(
                id: DateTime.now().millisecondsSinceEpoch.toString(),
                title: titleCtrl.text,
                category: 'general',
                date: DateTime.now(),
                description: descCtrl.text,
              );
              context.read<LifeTimelineService>().addEvent(event);
              Navigator.pop(ctx);
            },
          ),
        ],
      ),
    );
  }
}
