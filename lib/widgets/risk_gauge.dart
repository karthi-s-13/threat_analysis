import 'package:flutter/material.dart';

class RiskGauge extends StatelessWidget {
  final int score;

  const RiskGauge({
    super.key,
    required this.score,
  });

  Color get color {
    if (score <= 30) return Colors.greenAccent;
    if (score <= 70) return Colors.orangeAccent;
    return Colors.redAccent;
  }

  String get riskLabel {
    if (score <= 30) return "LOW";
    if (score <= 70) return "MEDIUM";
    return "HIGH";
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 180,
      width: 180,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Outer ring
          SizedBox(
            height: 180,
            width: 180,
            child: CircularProgressIndicator(
              value: score / 100,
              strokeWidth: 14,
              backgroundColor: Colors.grey.shade800,
              color: color,
            ),
          ),

          // Center content
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "$score%",
                style: TextStyle(
                  fontSize: 40, // 🔥 Bigger score
                  fontWeight: FontWeight.w900,
                  color: color,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                "RISK SCORE",
                style: TextStyle(
                  fontSize: 12,
                  letterSpacing: 1.2,
                  color: Colors.white70,
                ),
              ),
              const SizedBox(height: 6),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  riskLabel,
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
