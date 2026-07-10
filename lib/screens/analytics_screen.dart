import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/analytics_service.dart';

class AnalyticsScreen extends StatelessWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final analytics = context.watch<AnalyticsService>();
    final totalTokens = analytics.tokensToday;
    // Assuming Gemini free tier: ~15,000 tokens per day for flash model
    const dailyLimit = 15000;
    final remaining = dailyLimit - totalTokens;

    // Prepare agent data for chart
    final agentData = analytics.agentCountsToday.entries.toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Today\'s Usage',
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          // Cards row
          Row(
            children: [
              Expanded(
                child: _buildCard(
                  'Messages',
                  analytics.messagesToday.toString(),
                  Icons.chat,
                  Colors.blue,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildCard(
                  'Tokens Used',
                  totalTokens.toString(),
                  Icons.token,
                  Colors.orange,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _buildCard(
                  'Est. Remaining',
                  remaining > 0 ? '$remaining' : 'Limit reached',
                  Icons.timer,
                  remaining > 0 ? Colors.green : Colors.red,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildCard(
                  'Limit',
                  '$dailyLimit',
                  Icons.speed,
                  Colors.purple,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          const Text('Agent Activity',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          // Bar chart
          agentData.isEmpty
              ? const Center(child: Text('No agent activity today'))
              : SizedBox(
                  height: 200,
                  child: BarChart(
                    BarChartData(
                      alignment: BarChartAlignment.spaceAround,
                      maxY: agentData
                              .map((e) => e.value.toDouble())
                              .reduce((a, b) => a > b ? a : b)
                              .ceilToDouble() +
                          1,
                      barGroups: agentData.map((entry) {
                        return BarChartGroupData(
                          x: agentData.indexOf(entry),
                          barRods: [
                            BarChartRodData(
                              toY: entry.value.toDouble(),
                              color: Colors.blueAccent,
                              width: 16,
                            ),
                          ],
                        );
                      }).toList(),
                      titlesData: FlTitlesData(
                        show: true,
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (value, meta) {
                              final index = value.toInt();
                              if (index < agentData.length) {
                                return Padding(
                                  padding: const EdgeInsets.only(top: 8.0),
                                  child: Text(
                                    agentData[index].key,
                                    style: const TextStyle(fontSize: 10),
                                  ),
                                );
                              }
                              return const SizedBox();
                            },
                          ),
                        ),
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            interval: 1,
                            reservedSize: 28,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
        ],
      ),
    );
  }

  Widget _buildCard(String title, String value, IconData icon, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 8),
            Text(value,
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(title, style: const TextStyle(fontSize: 14)),
          ],
        ),
      ),
    );
  }
}
