import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/tokens.dart';
import '../services/approval_service.dart';
import '../models/approval_matrix.dart';

class ApprovalMatrixScreen extends StatelessWidget {
  const ApprovalMatrixScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Approval Matrix')),
      body: StreamBuilder<List<ApprovalMatrixEntry>>(
        stream: context.read<ApprovalService>().entries,
        builder: (ctx, snap) {
          final entries = snap.data ?? [];
          if (entries.isEmpty) {
            return const Center(child: Text('No entries. Seeding defaults...'));
          }
          return ListView(
            padding: const EdgeInsets.all(space4),
            children: entries.map((entry) {
              return Card(
                color: AppColors.surfaceRaised,
                margin: const EdgeInsets.only(bottom: space3),
                child: Padding(
                  padding: const EdgeInsets.all(space4),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(entry.actionCategory,
                          style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                      const SizedBox(height: space2),
                      Row(
                        children: ['auto_approve', 'notify_only', 'require_confirm', 'require_biometric'].map((tier) {
                          final isSelected = entry.tier == tier;
                          return Expanded(
                            child: GestureDetector(
                              onTap: () {
                                entry.tier = tier;
                                context.read<ApprovalService>().updateEntry(entry);
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: space2),
                                margin: const EdgeInsets.symmetric(horizontal: 2),
                                decoration: BoxDecoration(
                                  color: isSelected ? AppColors.accentViolet : AppColors.surfaceOverlay,
                                  borderRadius: BorderRadius.circular(radiusSm),
                                ),
                                child: Text(
                                  tier.replaceAll('_', ' ').toUpperCase(),
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: isSelected ? Colors.white : AppColors.textSecondary,
                                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                  ),
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          );
        },
      ),
    );
  }
}
