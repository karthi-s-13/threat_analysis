import '../models/app_risk_result.dart';

import 'dart:convert';
import 'dart:typed_data';

AppRiskResult evaluateAppRisk(Map<String, dynamic> app) {
  int score = 0;
  final List<String> reasons = [];

  final List<String> perms =
      List<String>.from(app["permissions"] ?? []);

  bool hasCamera = perms.contains("android.permission.CAMERA");
  bool hasMic = perms.contains("android.permission.RECORD_AUDIO");
  bool hasSms = perms.any((p) => p.contains("SMS"));
  bool hasContacts =
      perms.contains("android.permission.READ_CONTACTS");
  bool hasInternet =
      perms.contains("android.permission.INTERNET");
  bool hasOverlay =
      perms.contains("android.permission.SYSTEM_ALERT_WINDOW");

  final int lastUsed = app["last_used"] ?? 0;
  final bool rarelyUsed =
      DateTime.now().millisecondsSinceEpoch - lastUsed >
          1000 * 60 * 60 * 24 * 7; // 7 days

  // ============================
  // DECISION TREE RULES
  // ============================

  if (hasCamera && hasMic && hasInternet) {
    score += 30;
    reasons.add("Uses camera, microphone, and internet");
  }

  if (hasSms && hasInternet) {
    score += 25;
    reasons.add("Can access SMS and internet");
  }

  if (hasContacts && hasInternet) {
    score += 15;
    reasons.add("Can access contacts and internet");
  }

  if (hasOverlay) {
    score += 20;
    reasons.add("Can draw over other apps (overlay)");
  }

  if (rarelyUsed && (hasCamera || hasMic || hasSms)) {
    score += 10;
    reasons.add("Sensitive permissions with rare usage");
  }

  // ============================
  // CLAMP SCORE
  // ============================
  if (score > 100) score = 100;

  // ============================
  // CLASSIFICATION
  // ============================
  AppRiskLevel level;
  if (score >= 70) {
    level = AppRiskLevel.high;
  } else if (score >= 40) {
    level = AppRiskLevel.medium;
  } else {
    level = AppRiskLevel.low;
  }

  final String? iconBase64 = app["icon"];

  return AppRiskResult(
    appName: app["app_name"] ?? "Unknown",
    packageName: app["package_name"] ?? "",
    riskScore: score,
    level: level,
    reasons: reasons,
    permissions: perms,
    icon: iconBase64 != null
    ? base64Decode(iconBase64)
    : null,
  );
}
