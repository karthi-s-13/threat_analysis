import 'package:flutter/services.dart';

class AppScannerChannel {
  static const MethodChannel _channel =
      MethodChannel('app_permission_scanner');

  /// Check whether Usage Access permission is granted
  static Future<bool> checkUsagePermission() async {
    try {
      final bool hasPermission =
          await _channel.invokeMethod('checkUsagePermission');
      return hasPermission;
    } catch (e) {
      return false;
    }
  }

  /// Open Usage Access settings screen
  static Future<void> openUsageSettings() async {
    try {
      await _channel.invokeMethod('openUsageSettings');
    } catch (_) {}
  }

  /// Scan apps using UsageStats
  static Future<List<Map<String, dynamic>>> scanApps() async {
    final List result = await _channel.invokeMethod('scanApps');
    return result
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
  }

  /// Open App settings page
  static Future<void> openAppSettings(String packageName) async {
    try {
      await _channel.invokeMethod(
        'openAppSettings',
        {"package": packageName},
      );
    } catch (_) {}
  }
}
