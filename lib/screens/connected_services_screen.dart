import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/tokens.dart';
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
            padding: const EdgeInsets.all(space4),
            itemCount: services.length,
            itemBuilder: (_, i) {
              final service = services[i];
              return Card(
                color: AppColors.surfaceRaised,
                margin: const EdgeInsets.only(bottom: space3),
                child: ListTile(
                  leading: _getIcon(service.icon),
                  title: Text(service.name),
                  subtitle: Text(service.isConnected ? 'Connected' : 'Tap to connect'),
                  trailing: Switch(
                    value: service.isConnected,
                    onChanged: (val) async {
                      if (val) {
                        // simulate OAuth
                        await context.read<ConnectedServicesService>().addService(
                              ConnectedService(id: service.id, name: service.name, icon: service.icon, isConnected: true),
                            );
                      } else {
                        await context.read<ConnectedServicesService>().removeService(service.id);
                      }
                    },
                  ),
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
      case 'cloud': return const Icon(Icons.cloud, color: AppColors.accentViolet);
      case 'code': return const Icon(Icons.code, color: AppColors.accentViolet);
      case 'email': return const Icon(Icons.email, color: AppColors.accentViolet);
      case 'description': return const Icon(Icons.description, color: AppColors.accentViolet);
      case 'chat': return const Icon(Icons.chat, color: AppColors.accentViolet);
      default: return const Icon(Icons.link, color: AppColors.accentViolet);
    }
  }
}
