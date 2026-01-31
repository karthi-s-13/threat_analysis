import 'package:flutter/services.dart';

class AppScannerChannel {
  static const MethodChannel _channel =
      MethodChannel('app_permission_scanner');

  static Future<List<Map<String, dynamic>>> scanApps() async {
    try {
      final List<dynamic> result =
          await _channel.invokeMethod('scanApps');

      return result
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
    } on PlatformException catch (e) {
      if (e.code == "USAGE_ACCESS_REQUIRED") {
        throw Exception("Usage access permission required");
      }
      throw Exception("Scan failed: ${e.message}");
    }
  }
}
