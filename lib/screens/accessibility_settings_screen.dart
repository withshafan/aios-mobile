import 'package:flutter/material.dart';
import '../theme/tokens.dart';
import '../services/accessibility_settings.dart';

class AccessibilitySettingsScreen extends StatefulWidget {
  const AccessibilitySettingsScreen({super.key});

  @override
  State<AccessibilitySettingsScreen> createState() => _AccessibilitySettingsScreenState();
}

class _AccessibilitySettingsScreenState extends State<AccessibilitySettingsScreen> {
  bool _highContrast = false;
  double _textScale = 1.0;
  bool _reducedMotion = false;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final hc = await AccessibilitySettings.getHighContrast();
    final ts = await AccessibilitySettings.getTextScale();
    final rm = await AccessibilitySettings.getReducedMotion();
    setState(() {
      _highContrast = hc;
      _textScale = ts;
      _reducedMotion = rm;
      _loading = false;
    });
  }

  Future<void> _updateHighContrast(bool val) async {
    setState(() => _highContrast = val);
    await AccessibilitySettings.setHighContrast(val);
    // Apply to theme — requires full app rebuild; we'll just show a prompt
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Restart app for high contrast to take effect')),
      );
    }
  }

  Future<void> _updateTextScale(double val) async {
    setState(() => _textScale = val);
    await AccessibilitySettings.setTextScale(val);
  }

  Future<void> _updateReducedMotion(bool val) async {
    setState(() => _reducedMotion = val);
    await AccessibilitySettings.setReducedMotion(val);
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());

    return Scaffold(
      appBar: AppBar(title: const Text('Accessibility')),
      body: ListView(
        padding: const EdgeInsets.all(space4),
        children: [
          SwitchListTile(
            title: const Text('High Contrast Mode'),
            subtitle: const Text('Increase contrast for better readability'),
            value: _highContrast,
            onChanged: _updateHighContrast,
          ),
          const Divider(),
          ListTile(
            title: const Text('Text Scale'),
            subtitle: Text('${_textScale.toStringAsFixed(1)}x'),
            trailing: SizedBox(
              width: 200,
              child: Slider(
                value: _textScale,
                min: 0.8,
                max: 2.0,
                divisions: 12,
                label: '${_textScale.toStringAsFixed(1)}x',
                onChanged: (val) => setState(() => _textScale = val),
                onChangeEnd: _updateTextScale,
              ),
            ),
          ),
          const Divider(),
          SwitchListTile(
            title: const Text('Reduced Motion'),
            subtitle: const Text('Disable animations and transitions'),
            value: _reducedMotion,
            onChanged: _updateReducedMotion,
          ),
        ],
      ),
    );
  }
}
