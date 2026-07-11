import 'package:flutter/material.dart';
import '../theme/nova_theme.dart';

class SourcesCard extends StatelessWidget {
  final List<Map<String, String>> sources;

  const SourcesCard({super.key, required this.sources});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.only(top: 8, bottom: 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? NovaColors.darkSurface : NovaColors.lightSurface2,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? NovaColors.darkBorder : NovaColors.lightBorder,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Sources',
              style: TextStyle(
                color: isDark ? NovaColors.darkTextSecondary : NovaColors.lightTextSecondary,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              )),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: sources.map((s) {
              return GestureDetector(
                onTap: () {},
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: NovaColors.accent.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.link, size: 14, color: NovaColors.accent),
                      const SizedBox(width: 4),
                      Text(s['title'] ?? '',
                          style: TextStyle(color: NovaColors.accent, fontSize: 12)),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
