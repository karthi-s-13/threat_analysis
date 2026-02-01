import '../models/app_risk_result.dart';

class AppRiskCache {
  static List<AppRiskResult>? cachedResults;
  static DateTime? lastScanTime;

  static bool get hasCache => cachedResults != null;
}
