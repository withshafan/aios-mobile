import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/audit_service.dart';
import 'package:intl/intl.dart';
import '../../models/audit_entry.dart';

class AuditLogScreen extends StatelessWidget {
  const AuditLogScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Audit Log')),
      body: StreamBuilder<List<AuditEntry>>(
        stream: context.read<AuditService>().entries,
        builder: (ctx, snap) {
          final entries = snap.data ?? [];
          return ListView.builder(
            itemCount: entries.length,
            itemBuilder: (_, i) {
              final entry = entries[i];
              return Card(
                child: ListTile(
                  leading: Icon(_getIcon(entry.tier)),
                  title: Text('${entry.agent}: ${entry.action}'),
                  subtitle: Text(
                      '${DateFormat.yMd().add_jm().format(entry.timestamp)} - ${entry.tier}'),
                  onTap: () => _showDetails(context, entry),
                ),
              );
            },
          );
        },
      ),
    );
  }

  IconData _getIcon(String tier) {
    switch (tier) {
      case 'irreversible': return Icons.warning;
      case 'reversible': return Icons.undo;
      default: return Icons.remove_red_eye;
    }
  }

  void _showDetails(BuildContext context, AuditEntry entry) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(entry.action),
        content: SingleChildScrollView(
          child: Text(entry.details.toString()),
        ),
      ),
    );
  }
}
