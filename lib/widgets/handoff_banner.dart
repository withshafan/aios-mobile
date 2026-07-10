import 'package:flutter/material.dart';
import '../theme/tokens.dart';

class HandoffBanner extends StatelessWidget {
  final String deviceName;
  final String timeAgo;
  final VoidCallback onResume;
  final VoidCallback onDismiss;

  const HandoffBanner({
    super.key,
    required this.deviceName,
    required this.timeAgo,
    required this.onResume,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: space4),
      decoration: BoxDecoration(
        color: AppColors.surfaceRaised,
        border: Border(
          left: BorderSide(width: 2, color: AppColors.gradientIdle.first),
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.devices, color: AppColors.gradientIdle.first, size: 18),
          const SizedBox(width: space2),
          Expanded(
            child: Text(
              'Continued from $deviceName · $timeAgo',
              style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
            ),
          ),
          TextButton(
            onPressed: onResume,
            child: const Text('Resume', style: TextStyle(fontSize: 12)),
          ),
          IconButton(
            icon: const Icon(Icons.close, size: 16, color: AppColors.textDisabled),
            onPressed: onDismiss,
          ),
        ],
      ),
    );
  }
}
