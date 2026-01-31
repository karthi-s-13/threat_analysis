import 'dart:typed_data';



enum AppRiskLevel { low, medium, high }

class AppRiskResult {
  final String appName;
  final String packageName;
  final int riskScore;
  final AppRiskLevel level;
  final List<String> reasons;
  final List<String> permissions;
  final Uint8List? icon; // Added field for app icon

  AppRiskResult({
    required this.appName,
    required this.packageName,
    required this.riskScore,
    required this.level,
    required this.reasons,
    required this.permissions,
    this.icon,
  });
}
