import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/plugin_service.dart';
import '../models/plugin_info.dart';

class PluginsScreen extends StatelessWidget {
  const PluginsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final pluginService = context.watch<PluginService>();
    final plugins = pluginService.plugins;

    if (plugins.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: plugins.length,
      itemBuilder: (_, i) {
        final plugin = plugins[i];
        return Card(
          child: ListTile(
            title: Text(plugin.name),
            subtitle: Text(plugin.description),
            trailing: Switch(
              value: plugin.isEnabled,
              onChanged: (_) => pluginService.togglePlugin(plugin.id, plugin.isEnabled),
            ),
          ),
        );
      },
    );
  }
}
