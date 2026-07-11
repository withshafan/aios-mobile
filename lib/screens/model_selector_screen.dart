import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/tokens.dart';

class ModelSelectorScreen extends StatefulWidget {
  const ModelSelectorScreen({super.key});

  @override
  State<ModelSelectorScreen> createState() => _ModelSelectorScreenState();
}

class _ModelSelectorScreenState extends State<ModelSelectorScreen> {
  String _selectedModel = 'tencent/hy3';
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadSelection();
  }

  Future<void> _loadSelection() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _selectedModel = prefs.getString('selected_model') ?? 'tencent/hy3';
      _loading = false;
    });
  }

  Future<void> _saveSelection(String model) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('selected_model', model);
    setState(() => _selectedModel = model);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Model updated. Restart the app to apply.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    return Scaffold(
      appBar: AppBar(title: const Text('AI Model')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildModelCard(
            id: 'tencent/hy3',
            name: 'Tencent Hy3',
            description: 'Deep reasoning, agent workflows, long conversations',
            icon: Icons.psychology,
            color: AppColors.accentViolet,
            isSelected: _selectedModel == 'tencent/hy3',
          ),
          const SizedBox(height: 12),
          _buildModelCard(
            id: 'google/gemma-4-26b-a4b',
            name: 'Google Gemma 4 26B',
            description: 'Fast, multimodal, vision support',
            icon: Icons.flash_on,
            color: AppColors.accentCyan,
            isSelected: _selectedModel == 'google/gemma-4-26b-a4b',
          ),
        ],
      ),
    );
  }

  Widget _buildModelCard({
    required String id,
    required String name,
    required String description,
    required IconData icon,
    required Color color,
    required bool isSelected,
  }) {
    return GestureDetector(
      onTap: () => _saveSelection(id),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.15) : AppColors.surfaceRaised,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? color : AppColors.borderHairline,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: color.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Icon(Icons.check_circle, color: color, size: 24),
          ],
        ),
      ),
    );
  }
}
