import '../models/app_risk_result.dart';

import 'dart:convert';
import 'dart:typed_data';

AppRiskResult evaluateAppRisk(Map<String, dynamic> app) {
  double score = 0;
  final List<String> reasons = [];
  final List<String> perms = List<String>.from(app["permissions"] ?? []);

  final bool isSystem = app["is_system"] == true;

  // 1. Permission flags
  final bool hasInternet = perms.contains("android.permission.INTERNET");
  final bool hasCamera = perms.contains("android.permission.CAMERA");
  final bool hasMic = perms.contains("android.permission.RECORD_AUDIO");
  final bool hasSms = perms.any((p) => p.contains("SMS"));
  final bool hasContacts = perms.contains("android.permission.READ_CONTACTS");
  final bool hasLocation = perms.any((p) => p.contains("LOCATION"));
  final bool hasOverlay =
      perms.contains("android.permission.SYSTEM_ALERT_WINDOW");

  // 2. High-risk combinations (USER apps only)
  if (!isSystem && hasInternet) {
    if (hasSms) {
      score += 40;
      reasons.add(
          "Critical: Can read SMS and transmit data (Potential 2FA interception)");
    }
    if (hasCamera || hasMic) {
      score += 30;
      reasons.add("High: Media capture with internet access");
    }
    if (hasContacts) {
      score += 15;
      reasons.add("Medium: Contact list exfiltration risk");
    }
    if (hasLocation) {
      score += 15;
      reasons.add("Medium: Real-time tracking capabilities");
    }
  }

  // 3. Overlay is dangerous even for system apps
  if (hasOverlay) {
    score += 25;
    reasons.add("High: Overlay permission can be used for phishing/tapjacking");
  }

  // 4. Dormancy (ONLY if lastUsed is known)
  final int lastUsed = app["last_used"] ?? 0;
  final int sevenDaysMs = 1000 * 60 * 60 * 24 * 7;

  final bool isDormant =
      lastUsed > 0 &&
      DateTime.now().millisecondsSinceEpoch - lastUsed > sevenDaysMs;

  if (isDormant && perms.isNotEmpty && !isSystem) {
    score *= 1.1;
    reasons.add("Security Note: App is dormant but retains sensitive access");
  }

  // 5. System app score cap
  if (isSystem && score > 30) {
    score = 30;
    reasons.add("System app: elevated permissions are expected");
  }

  // 6. Normalize
  int finalScore = score.round().clamp(0, 100);

  // 7. Classification
  AppRiskLevel level;
  if (finalScore >= 75) {
    level = AppRiskLevel.high;
  } else if (finalScore >= 35) {
    level = AppRiskLevel.medium;
  } else {
    level = AppRiskLevel.low;
  }

  return AppRiskResult(
    appName: app["app_name"] ?? "Unknown",
    packageName: app["package_name"] ?? "",
    riskScore: finalScore,
    level: level,
    reasons: reasons,
    permissions: perms,
    icon: app["icon"] != null ? base64Decode(app["icon"]) : null,
  );
}
