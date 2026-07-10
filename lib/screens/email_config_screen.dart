import 'package:flutter/material.dart';
import '../services/email_service.dart';

class EmailConfigScreen extends StatefulWidget {
  const EmailConfigScreen({super.key});

  @override
  State<EmailConfigScreen> createState() => _EmailConfigScreenState();
}

class _EmailConfigScreenState extends State<EmailConfigScreen> {
  final _formKey = GlobalKey<FormState>();
  final _hostController = TextEditingController();
  final _portController = TextEditingController();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _emailService = EmailService();
  bool _isLoading = false;
  bool _isConfigured = false;

  @override
  void initState() {
    super.initState();
    _loadConfig();
  }

  Future<void> _loadConfig() async {
    final config = await _emailService.getConfig();
    if (config != null) {
      _hostController.text = config['host'] as String? ?? '';
      _portController.text = config['port']?.toString() ?? '';
      _usernameController.text = config['username'] as String? ?? '';
      _passwordController.text = config['password'] as String? ?? '';
      setState(() => _isConfigured = true);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    await _emailService.saveConfig(
      host: _hostController.text.trim(),
      port: int.tryParse(_portController.text.trim()) ?? 587,
      username: _usernameController.text.trim(),
      password: _passwordController.text.trim(),
    );
    setState(() {
      _isLoading = false;
      _isConfigured = true;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Email configuration saved.')),
    );
  }

  @override
  void dispose() {
    _hostController.dispose();
    _portController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Email Configuration')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              const Text(
                'Configure your SMTP server to send emails.',
                style: TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _hostController,
                decoration: const InputDecoration(
                  labelText: 'SMTP Host',
                  hintText: 'smtp.gmail.com',
                  border: OutlineInputBorder(),
                ),
                validator: (v) => v == null || v.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _portController,
                decoration: const InputDecoration(
                  labelText: 'Port',
                  hintText: '587',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                validator: (v) => v == null || v.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _usernameController,
                decoration: const InputDecoration(
                  labelText: 'Username (your email)',
                  hintText: 'you@gmail.com',
                  border: OutlineInputBorder(),
                ),
                validator: (v) => v == null || v.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _passwordController,
                decoration: const InputDecoration(
                  labelText: 'Password or App Password',
                  hintText: 'your-app-password',
                  border: OutlineInputBorder(),
                ),
                obscureText: true,
                validator: (v) => v == null || v.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _isLoading ? null : _save,
                child: _isLoading
                    ? const CircularProgressIndicator()
                    : const Text('Save Configuration'),
              ),
              if (_isConfigured)
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(
                    '✓ Email is configured',
                    style: TextStyle(color: Colors.green, fontSize: 16),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
