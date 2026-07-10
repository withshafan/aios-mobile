import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/circuit_breaker_service.dart';

class SystemHealthScreen extends StatefulWidget {
  const SystemHealthScreen({super.key});

  @override
  State<SystemHealthScreen> createState() => _SystemHealthScreenState();
}

class _SystemHealthScreenState extends State<SystemHealthScreen> {
  final _agents = ['email', 'calendar', 'browser', 'files'];
  final Map<String, bool> _status = {};

  @override
  void initState() {
    super.initState();
    _checkStatus();
  }

  Future<void> _checkStatus() async {
    final cb = context.read<CircuitBreakerService>();
    for (var agent in _agents) {
      final tripped = await cb.isAgentTripped(agent);
      setState(() => _status[agent] = !tripped);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('System Health & Circuit Breakers')),
      body: RefreshIndicator(
        onRefresh: _checkStatus,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: _agents.map((agent) {
            final healthy = _status[agent] ?? true;
            return Card(
              child: ListTile(
                leading: Icon(
                  healthy ? Icons.check_circle : Icons.error,
                  color: healthy ? Colors.green : Colors.red,
                ),
                title: Text(agent.toUpperCase()),
                subtitle: Text(healthy ? 'Operational' : 'Tripped (too many failures)'),
                trailing: ElevatedButton(
                  onPressed: healthy
                      ? null
                      : () async {
                          await context.read<CircuitBreakerService>().clearFailures(agent);
                          _checkStatus();
                        },
                  child: const Text('Reset'),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}
