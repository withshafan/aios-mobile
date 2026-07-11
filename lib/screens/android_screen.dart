import 'dart:async';
import 'package:flutter/material.dart';
import 'package:process_run/shell.dart';
import '../theme/tokens.dart';

enum AdbState { unknown, disconnected, unauthorized, connected, pairing }

class AndroidScreen extends StatefulWidget {
  const AndroidScreen({super.key});

  @override
  State<AndroidScreen> createState() => _AndroidScreenState();
}

class _AndroidScreenState extends State<AndroidScreen> {
  final Shell _shell = Shell();
  AdbState _state = AdbState.unknown;
  String? _deviceName;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _checkDevice();
    _timer = Timer.periodic(const Duration(seconds: 5), (_) => _checkDevice());
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _checkDevice() async {
    try {
      final result = await _shell.run('adb devices -l');
      final lines = result.outLines;
      bool found = false;
      for (final line in lines.skip(1)) {
        if (line.trim().isEmpty) continue;
        final parts = line.trim().split(RegExp(r'\s+'));
        if (parts.length >= 2) {
          final status = parts[1];
          if (status == 'device') {
            found = true;
            final model = RegExp(r'model:(.*?)\s').firstMatch(line)?.group(1) ?? 'Android';
            setState(() {
              _state = AdbState.connected;
              _deviceName = model;
            });
            break;
          } else if (status == 'unauthorized') {
            setState(() { _state = AdbState.unauthorized; _deviceName = null; });
            found = true;
            break;
          }
        }
      }
      if (!found) {
        // Check wireless pairing
        final pairResult = await _shell.run('adb pair');
        if (pairResult.outText.contains('Enter pairing code')) {
          setState(() => _state = AdbState.pairing);
        } else {
          setState(() => _state = AdbState.disconnected);
        }
      }
    } catch (e) {
      setState(() => _state = AdbState.disconnected);
    }
  }

  String get _statusText {
    switch (_state) {
      case AdbState.unknown: return 'Checking...';
      case AdbState.disconnected: return 'No device connected';
      case AdbState.unauthorized: return 'Device unauthorized – allow USB debugging';
      case AdbState.connected: return 'Connected to $_deviceName';
      case AdbState.pairing: return 'Wireless pairing available – check your device';
    }
  }

  IconData get _statusIcon {
    switch (_state) {
      case AdbState.connected: return Icons.phone_android;
      case AdbState.pairing: return Icons.wifi_tethering;
      default: return Icons.phone_android_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Android Device')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(_statusIcon, size: 64, color: _state == AdbState.connected ? AppColors.accentSuccess : AppColors.textSecondary),
              const SizedBox(height: 16),
              Text(_statusText, textAlign: TextAlign.center, style: TextStyle(color: AppColors.textPrimary, fontSize: 18)),
              const SizedBox(height: 8),
              if (_state == AdbState.disconnected)
                const Text('Connect your phone via USB and enable USB debugging.\nOr use wireless ADB pairing.',
                    textAlign: TextAlign.center, style: TextStyle(color: AppColors.textSecondary)),
              if (_state == AdbState.unauthorized)
                const Text('Check your device screen and tap "Allow" when prompted.',
                    textAlign: TextAlign.center, style: TextStyle(color: AppColors.accentWarning)),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                icon: const Icon(Icons.refresh),
                label: const Text('Refresh'),
                onPressed: _checkDevice,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
