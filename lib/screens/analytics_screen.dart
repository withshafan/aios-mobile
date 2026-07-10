import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';
import '../theme/tokens.dart';
import '../services/analytics_service.dart';

class AnalyticsScreen extends StatelessWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final analytics = context.watch<AnalyticsService>();
    final totalTokens = analytics.tokensToday;

    return Scaffold(
      appBar: AppBar(title: const Text('Analytics')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('Tokens used today: $totalTokens', style: const TextStyle(fontSize: 18)),
          const SizedBox(height: 20),
          SizedBox(
            height: 200,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(show: false),
                titlesData: FlTitlesData(show: false),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: [FlSpot(0, 0), FlSpot(1, 2), FlSpot(2, 1), FlSpot(3, 3)],
                    isCurved: true,
                    color: AppColors.accentCyan,
                    barWidth: 2,
                    belowBarData: BarAreaData(show: true, color: AppColors.accentCyan.withOpacity(0.1)),
                    dotData: FlDotData(show: false),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
