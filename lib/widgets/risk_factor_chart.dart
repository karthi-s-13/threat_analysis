import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../models/risk_factor.dart';

class RiskFactorChart extends StatelessWidget {
  final List<RiskFactor> factors;

  const RiskFactorChart({
    super.key,
    required this.factors,
  });

  Color _severityColor(String severity) {
    switch (severity) {
      case "high":
        return Colors.redAccent;
      case "medium":
        return Colors.orangeAccent;
      case "low":
      default:
        return Colors.greenAccent;
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 220,
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: 100, // percentage scale
          gridData: FlGridData(show: true),
          borderData: FlBorderData(show: false),
          barTouchData: BarTouchData(enabled: true),

          barGroups: factors.asMap().entries.map((entry) {
            final index = entry.key;
            final factor = entry.value;

            return BarChartGroupData(
              x: index,
              barRods: [
                BarChartRodData(
                  toY: factor.contribution.toDouble(), // ✅ RATE
                  width: 18,
                  color: _severityColor(factor.severity),
                  borderRadius: BorderRadius.circular(4),
                ),
              ],
            );
          }).toList(),

          titlesData: FlTitlesData(
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),

            // 📊 Y AXIS → RATE
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                interval: 20,
                getTitlesWidget: (value, _) {
                  return Text(
                    "${value.toInt()}%",
                    style: const TextStyle(
                      fontSize: 10,
                      color: Colors.white70,
                    ),
                  );
                },
              ),
            ),

            // 📌 X AXIS → FACTORS
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, _) {
                  final index = value.toInt();
                  if (index < 0 || index >= factors.length) {
                    return const SizedBox.shrink();
                  }
                  return Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      factors[index].title.split(" ").first,
                      style: const TextStyle(
                        fontSize: 10,
                        color: Colors.white,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}
