import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import '../theme/tokens.dart';
import '../theme/aura_theme.dart';
import '../services/task_service.dart';
import '../services/analytics_service.dart';
import '../services/plugin_service.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final analytics = context.watch<AnalyticsService>();
    final theme = Theme.of(context).extension<AuraTheme>()!;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(space4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Greeting
          Text(
            'Good ${_getGreeting()},',
            style: TextStyle(color: theme.textSecondary, fontSize: 18),
          ),
          const SizedBox(height: space1),
          Text(
            'Here\'s your overview',
            style: TextStyle(color: theme.textPrimary, fontSize: 28, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: space6),

          // Mission hero card with gradient
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(space5),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(radiusLg),
              gradient: const LinearGradient(
                colors: [AppColors.accentViolet, AppColors.accentCyan],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.accentViolet.withOpacity(0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.flag, color: Colors.white),
                const SizedBox(height: space3),
                const Text('Current Mission', style: TextStyle(color: Colors.white70, fontSize: 12)),
                const Text('Build AI Operating System', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w600)),
                const SizedBox(height: space4),
                // Progress
                ClipRRect(
                  borderRadius: BorderRadius.circular(radiusFull),
                  child: const LinearProgressIndicator(
                    value: 0.65,
                    backgroundColor: Colors.white24,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    minHeight: 6,
                  ),
                ),
                const SizedBox(height: space2),
                const Text('65% complete – next: Frontend UI', style: TextStyle(color: Colors.white70, fontSize: 12)),
              ],
            ),
          ),
          const SizedBox(height: space6),

          // Active Agents row
          Text('Active Agents', style: TextStyle(color: theme.textPrimary, fontSize: 16, fontWeight: FontWeight.w600)),
          const SizedBox(height: space3),
          SizedBox(
            height: 80,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                _agentAvatar('Planner', AppColors.gradientIdle, true),
                const SizedBox(width: space3),
                _agentAvatar('Coding', AppColors.gradientActive, true),
                const SizedBox(width: space3),
                _agentAvatar('Research', AppColors.gradientSuccess, false),
              ],
            ),
          ),
          const SizedBox(height: space6),

          // Pending Approvals
          Text('Pending Approvals', style: TextStyle(color: theme.textPrimary, fontSize: 16, fontWeight: FontWeight.w600)),
          const SizedBox(height: space3),
          Container(
            padding: const EdgeInsets.all(space4),
            decoration: BoxDecoration(
              color: theme.surfaceRaised,
              borderRadius: BorderRadius.circular(radiusMd),
            ),
            child: const Row(
              children: [
                Icon(Icons.email_outlined, color: AppColors.accentWarning),
                SizedBox(width: space3),
                Expanded(child: Text('Send email to john@example.com')),
                Text('Review', style: TextStyle(color: AppColors.accentViolet)),
              ],
            ),
          ),
          const SizedBox(height: space6),

          // System Health
          Text('System Health', style: TextStyle(color: theme.textPrimary, fontSize: 16, fontWeight: FontWeight.w600)),
          const SizedBox(height: space3),
          Row(
            children: [
              _healthDot('Email', true),
              const SizedBox(width: space3),
              _healthDot('Calendar', true),
              const SizedBox(width: space3),
              _healthDot('Browser', true),
              const SizedBox(width: space3),
              _healthDot('Files', false),
            ],
          ),
          const SizedBox(height: space6),

          // Analytics Sparkline
          Text('Token Usage (7 days)', style: TextStyle(color: theme.textPrimary, fontSize: 16, fontWeight: FontWeight.w600)),
          const SizedBox(height: space3),
          SizedBox(
            height: 100,
            child: _buildSparkline(analytics),
          ),
        ],
      ),
    );
  }

  Widget _agentAvatar(String name, List<Color> gradient, bool active) {
    return Column(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(colors: gradient),
            boxShadow: active
                ? [BoxShadow(color: gradient.last.withOpacity(0.5), blurRadius: 12)]
                : [],
          ),
          child: Icon(Icons.person, color: Colors.white.withOpacity(0.9), size: 24),
        ),
        const SizedBox(height: space1),
        Text(name, style: const TextStyle(color: AppColors.textSecondary, fontSize: 10)),
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: active ? AppColors.accentSuccess : AppColors.textDisabled,
          ),
        ),
      ],
    );
  }

  Widget _healthDot(String label, bool healthy) {
    return Expanded(
      child: Column(
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: healthy ? AppColors.accentSuccess : AppColors.accentCritical,
              boxShadow: [
                BoxShadow(
                  color: (healthy ? AppColors.accentSuccess : AppColors.accentCritical).withOpacity(0.5),
                  blurRadius: 8,
                ),
              ],
            ),
          ),
          const SizedBox(height: space1),
          Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 10)),
        ],
      ),
    );
  }

  Widget _buildSparkline(AnalyticsService analytics) {
    // Dummy data for now
    final spots = [0, 1, 3, 2, 5, 4, 6].asMap().entries.map((e) => FlSpot(e.key.toDouble(), e.value.toDouble())).toList();
    return LineChart(
      LineChartData(
        gridData: const FlGridData(show: false),
        titlesData: const FlTitlesData(show: false),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: AppColors.accentCyan,
            barWidth: 2,
            belowBarData: BarAreaData(
              show: true,
              color: AppColors.accentCyan.withOpacity(0.1),
            ),
            dotData: const FlDotData(show: false),
          ),
        ],
      ),
    );
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Morning';
    if (hour < 18) return 'Afternoon';
    return 'Evening';
  }
}
