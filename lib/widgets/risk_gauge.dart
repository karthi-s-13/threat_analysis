import 'package:flutter/material.dart';

class RiskGauge extends StatelessWidget {
  final int score;

  const RiskGauge({super.key, required this.score});

  Color get color {
    if (score <= 30) return Colors.green;
    if (score <= 70) return Colors.orange;
    return Colors.red;
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 160,
      width: 160,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CircularProgressIndicator(
            value: score / 100,
            strokeWidth: 12,
            backgroundColor: Colors.grey.shade300,
            color: color,
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "$score%",
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Text("Risk Score"),
            ],
          ),
        ],
      ),
    );
  }
}
