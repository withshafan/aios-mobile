import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/tokens.dart';
import '../services/circuit_breaker_service.dart';

class SystemHealthScreen extends StatefulWidget {
  const SystemHealthScreen({super.key});

  @override
  State<SystemHealthScreen> createState() => _SystemHealthScreenState();
}

class _SystemHealthScreenState extends State<SystemHealthScreen> {
  final List<String> _agents = ['email', 'calendar', 'browser', 'files', 'android', 'plugin'];
  Map<String, bool> _status = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _checkStatus();
  }

  Future<void> _checkStatus() async {
    final cb = context.read<CircuitBreakerService>();
    Map<String, bool> status = {};
    for (var agent in _agents) {
      status[agent] = !await cb.isAgentTripped(agent);
    }
    setState(() {
      _status = status;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('System Health')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _checkStatus,
              child: ListView(
                padding: const EdgeInsets.all(space4),
                children: _agents.map((agent) {
                  final healthy = _status[agent] ?? true;
                  return Card(
                    color: AppColors.surfaceRaised,
                    margin: const EdgeInsets.only(bottom: space2),
                    child: ListTile(
                      leading: Icon(
                        healthy ? Icons.check_circle : Icons.error,
                        color: healthy ? AppColors.accentSuccess : AppColors.accentCritical,
                      ),
                      title: Text(agent.toUpperCase()),
                      subtitle: Text(healthy ? 'Operational' : 'Circuit breaker tripped'),
                      trailing: healthy
                          ? null
                          : ElevatedButton(
                              onPressed: () async {
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
