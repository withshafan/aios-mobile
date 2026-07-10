import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/connected_services_service.dart';
import '../models/connected_service.dart';

class ConnectedServicesScreen extends StatelessWidget {
  const ConnectedServicesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Connected Services')),
      body: StreamBuilder<List<ConnectedService>>(
        stream: context.read<ConnectedServicesService>().services,
        builder: (ctx, snap) {
          final services = snap.data ?? [];
          return ListView.builder(
            itemCount: services.length,
            itemBuilder: (_, i) {
              final service = services[i];
              return ListTile(
                leading: _getIcon(service.icon),
                title: Text(service.name),
                subtitle: Text(service.isConnected ? 'Connected' : 'Not connected'),
                trailing: Switch(
                  value: service.isConnected,
                  onChanged: (val) async {
                    if (val) {
                      // Simulate OAuth connection (Google Drive example)
                      _showOAuthDialog(context, service);
                    } else {
                      await context.read<ConnectedServicesService>().removeService(service.id);
                    }
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _getIcon(String iconName) {
    switch (iconName) {
      case 'cloud': return const Icon(Icons.cloud);
      case 'code': return const Icon(Icons.code);
      case 'email': return const Icon(Icons.email);
      case 'description': return const Icon(Icons.description);
      case 'chat': return const Icon(Icons.chat);
      default: return const Icon(Icons.link);
    }
  }

  void _showOAuthDialog(BuildContext context, ConnectedService service) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Connect ${service.name}'),
        content: const Text('This will open your browser to authorize AURA. Allow?'),
        actions: [
          TextButton(child: const Text('Cancel'), onPressed: () => Navigator.pop(ctx, false)),
          TextButton(child: const Text('Connect'), onPressed: () => Navigator.pop(ctx, true)),
        ],
      ),
    );
    if (result == true) {
      // Open a dummy OAuth URL (in a real app, use GoogleSignIn with additional scopes)
      final url = Uri.parse('https://accounts.google.com/o/oauth2/auth?...');
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      }
      // For now, we'll just set connected status
      await context.read<ConnectedServicesService>().addService(
            ConnectedService(id: service.id, name: service.name, icon: service.icon, isConnected: true),
          );
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${service.name} connected')));
    }
  }
}
