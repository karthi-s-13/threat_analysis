import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../models/risk_factor.dart';

class RiskFactorChart extends StatelessWidget {
  final List<RiskFactor> factors;

  const RiskFactorChart({super.key, required this.factors});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 220,
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          barGroups: factors.asMap().entries.map((entry) {
            final index = entry.key;
            final factor = entry.value;

            return BarChartGroupData(
              x: index,
              barRods: [
                BarChartRodData(
                  toY: factor.contribution.toDouble(),
                  width: 18,
                  color: factor.severity == "high"
                      ? Colors.red
                      : Colors.orange,
                ),
              ],
            );
          }).toList(),
          titlesData: FlTitlesData(
            leftTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: true),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, _) {
                  return Text(
                    factors[value.toInt()].title.split(" ").first,
                    style: const TextStyle(fontSize: 10),
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
