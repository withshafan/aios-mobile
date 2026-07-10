import 'package:flutter/material.dart';
import '../services/android_service.dart';

class AndroidScreen extends StatefulWidget {
  const AndroidScreen({super.key});

  @override
  State<AndroidScreen> createState() => _AndroidScreenState();
}

class _AndroidScreenState extends State<AndroidScreen> {
  final AndroidService _androidService = AndroidService();
  final TextEditingController _commandController = TextEditingController();
  final List<String> _logs = [];
  bool _isDeviceConnected = false;

  @override
  void initState() {
    super.initState();
    _checkDevice();
  }

  Future<void> _checkDevice() async {
    final connected = await _androidService.isDeviceConnected();
    setState(() => _isDeviceConnected = connected);
  }

  Future<void> _runWithConfirmation(String action, Future<String> Function() exec) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Execute action?'),
        content: Text('The AI wants to:\n$action'),
        actions: [
          TextButton(
            child: const Text('Cancel'),
            onPressed: () => Navigator.pop(ctx, false),
          ),
          TextButton(
            child: const Text('Run'),
            onPressed: () => Navigator.pop(ctx, true),
          ),
        ],
      ),
    );
    if (confirm == true) {
      try {
        final output = await exec();
        setState(() => _logs.insert(0, '✓ $action\n$output'));
      } catch (e) {
        setState(() => _logs.insert(0, '✗ $action\nError: $e'));
      }
    } else {
      setState(() => _logs.insert(0, '✗ User cancelled: $action'));
    }
  }

  void _executeCustom() async {
    final cmd = _commandController.text.trim();
    if (cmd.isEmpty) return;
    _commandController.clear();
    _runWithConfirmation('Custom ADB: $cmd', () => _androidService.executeCustomCommand(cmd));
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (!_isDeviceConnected)
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Card(
              color: Colors.red,
              child: ListTile(
                leading: Icon(Icons.warning),
                title: Text('No device connected via ADB'),
                subtitle: Text('Connect your phone with USB debugging enabled.'),
              ),
            ),
          ),
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _commandController,
                  decoration: const InputDecoration(
                    hintText: 'Type an ADB shell command...',
                    border: OutlineInputBorder(),
                  ),
                  onSubmitted: (_) => _executeCustom(),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.send),
                onPressed: _executeCustom,
              ),
            ],
          ),
        ),
        Wrap(
          spacing: 8,
          children: [
            ActionChip(
              label: const Text('Open WhatsApp'),
              onPressed: () => _runWithConfirmation(
                'Open WhatsApp',
                () => _androidService.openApp('com.whatsapp'),
              ),
            ),
            ActionChip(
              label: const Text('Take Screenshot'),
              onPressed: () => _runWithConfirmation(
                'Take screenshot',
                () => _androidService.takeScreenshot(),
              ),
            ),
            ActionChip(
              label: const Text('Battery Info'),
              onPressed: () => _runWithConfirmation(
                'Get battery info',
                () => _androidService.getBatteryInfo(),
              ),
            ),
            ActionChip(
              label: const Text('Device Info'),
              onPressed: () => _runWithConfirmation(
                'Get device info',
                () => _androidService.getDeviceInfo(),
              ),
            ),
          ],
        ),
        const Divider(),
        const Text('Log', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        Expanded(
          child: ListView.builder(
            itemCount: _logs.length,
            itemBuilder: (_, i) => ListTile(
              dense: true,
              title: Text(_logs[i], style: const TextStyle(fontSize: 12, fontFamily: 'monospace')),
            ),
          ),
        ),
      ],
    );
  }
}
