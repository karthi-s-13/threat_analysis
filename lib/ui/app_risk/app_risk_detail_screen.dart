import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../models/app_risk_result.dart';

class AppRiskDetailScreen extends StatelessWidget {
  final AppRiskResult app;

  const AppRiskDetailScreen({super.key, required this.app});

  List<_Capability> _extractAllCapabilities() {
    final caps = <String, _Capability>{};

    void add(String key, _Capability cap) {
      caps.putIfAbsent(key, () => cap);
    }

    for (final perm in app.permissions) {
      final p = perm.toUpperCase();

      if (p.contains("CAMERA")) {
        add(
          "camera",
          _Capability(
            label: "Camera",
            icon: Icons.camera_alt,
            color: Colors.redAccent,
          ),
        );
      } else if (p.contains("RECORD_AUDIO")) {
        add(
          "microphone",
          _Capability(
            label: "Microphone",
            icon: Icons.mic,
            color: Colors.redAccent,
          ),
        );
      } else if (p.contains("SMS")) {
        add(
          "sms",
          _Capability(label: "SMS", icon: Icons.sms, color: Colors.redAccent),
        );
      } else if (p.contains("LOCATION")) {
        add(
          "location",
          _Capability(
            label: "Location",
            icon: Icons.location_on,
            color: Colors.orangeAccent,
          ),
        );
      } else if (p.contains("READ_CONTACTS")) {
        add(
          "contacts",
          _Capability(
            label: "Contacts",
            icon: Icons.contacts,
            color: Colors.orangeAccent,
          ),
        );
      } else if (p.contains("STORAGE") ||
          p.contains("READ_EXTERNAL") ||
          p.contains("WRITE_EXTERNAL")) {
        add(
          "storage",
          _Capability(
            label: "Storage",
            icon: Icons.folder,
            color: Colors.orangeAccent,
          ),
        );
      } else if (p.contains("INTERNET")) {
        add(
          "internet",
          _Capability(
            label: "Internet",
            icon: Icons.language,
            color: Colors.greenAccent,
          ),
        );
      } else if (p.contains("CALL") || p.contains("PHONE")) {
        add(
          "phone",
          _Capability(
            label: "Phone",
            icon: Icons.call,
            color: Colors.redAccent,
          ),
        );
      } else if (p.contains("NOTIFICATION")) {
        add(
          "notification",
          _Capability(
            label: "Notifications",
            icon: Icons.notifications,
            color: Colors.orangeAccent,
          ),
        );
      } else if (p.contains("BLUETOOTH")) {
        add(
          "bluetooth",
          _Capability(
            label: "Bluetooth",
            icon: Icons.bluetooth,
            color: Colors.greenAccent,
          ),
        );
      } else if (p.contains("SYSTEM_ALERT_WINDOW") || p.contains("OVERLAY")) {
        add(
          "overlay",
          _Capability(
            label: "Overlay",
            icon: Icons.layers,
            color: Colors.redAccent,
          ),
        );
      }
      // ❌ NO ELSE → unknown permissions are ignored
    }

    return caps.values.toList();
  }

  static const MethodChannel _channel = MethodChannel('app_permission_scanner');

  // =============================
  // RISK COLORS
  // =============================
  Color _riskColor(AppRiskLevel level) {
    switch (level) {
      case AppRiskLevel.high:
        return Colors.redAccent;
      case AppRiskLevel.medium:
        return Colors.orangeAccent;
      case AppRiskLevel.low:
      default:
        return Colors.greenAccent;
    }
  }

  // =============================
  // PERMISSION SEVERITY
  // =============================
  Color _permissionColor(String permission) {
    final p = permission.toUpperCase();

    // 🔴 HIGH RISK
    if (p.contains("READ_SMS") ||
        p.contains("SEND_SMS") ||
        p.contains("RECEIVE_SMS") ||
        p.contains("SYSTEM_ALERT_WINDOW") ||
        p.contains("RECORD_AUDIO") ||
        p.contains("CAMERA")) {
      return Colors.redAccent;
    }

    // 🟠 MEDIUM RISK
    if (p.contains("READ_CONTACTS") ||
        p.contains("ACCESS_FINE_LOCATION") ||
        p.contains("ACCESS_COARSE_LOCATION") ||
        p.contains("READ_CALL_LOG") ||
        p.contains("LOCATION")) {
      return Colors.orangeAccent;
    }

    // ❌ LOW RISK → DO NOT SHOW (fallback)
    return Colors.transparent;
  }

  IconData _permissionIcon(String permission) {
    final p = permission.toUpperCase();

    if (p.contains("SMS")) return Icons.sms_failed;
    if (p.contains("CAMERA")) return Icons.camera_alt;
    if (p.contains("RECORD_AUDIO")) return Icons.mic;
    if (p.contains("CONTACT")) return Icons.contacts;
    if (p.contains("LOCATION")) return Icons.location_on;
    if (p.contains("INTERNET")) return Icons.language;

    return Icons.security;
  }

  String _permissionExplanation(String permission) {
    final p = permission.toUpperCase();

    if (p.contains("CAMERA")) {
      return "Can capture photos or videos without your awareness.";
    }
    if (p.contains("RECORD_AUDIO")) {
      return "Can record audio from the microphone.";
    }
    if (p.contains("READ_SMS") || p.contains("RECEIVE_SMS")) {
      return "Can read your SMS messages (often used in OTP theft).";
    }
    if (p.contains("SEND_SMS")) {
      return "Can send SMS messages silently, possibly causing financial loss.";
    }
    if (p.contains("READ_CONTACTS")) {
      return "Can access your contacts and personal relationships.";
    }
    if (p.contains("SYSTEM_ALERT_WINDOW")) {
      return "Can draw over other apps (used in phishing overlays).";
    }
    if (p.contains("INTERNET")) {
      return "Allows the app to communicate over the internet.";
    }

    return "This permission may affect privacy or device security.";
  }

  Future<void> _openAppSettings() async {
    try {
      await _channel.invokeMethod('openAppSettings', {
        "package": app.packageName,
      });
    } catch (e) {
      debugPrint("Failed to open app settings: $e");
    }
  }

  // =============================
  // UI
  // =============================
  @override
  Widget build(BuildContext context) {
    final riskColor = _riskColor(app.level);

    return Scaffold(
      backgroundColor: const Color(0xFF0B0F1A),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // =============================
          // CUSTOM APP BAR WITH APP INFO
          // =============================
          SliverAppBar(
            expandedHeight: 280,
            floating: false,
            pinned: true,
            backgroundColor: const Color(0xFF0B0F1A),
            leading: IconButton(
              icon: Icon(Icons.arrow_back, color: riskColor),
              onPressed: () => Navigator.pop(context),
            ),
            flexibleSpace: FlexibleSpaceBar(
              centerTitle: true,
              title: const Text(
                "App Risk Details",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      riskColor.withOpacity(0.2),
                      const Color(0xFF0B0F1A),
                    ],
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(height: 60),
                    // App Icon with glow
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            riskColor.withOpacity(0.3),
                            Colors.transparent,
                          ],
                        ),
                      ),
                      child: Container(
                        width: 96,
                        height: 96,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: riskColor.withOpacity(0.5),
                            width: 3,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: riskColor.withOpacity(0.3),
                              blurRadius: 20,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: app.icon != null
                            ? CircleAvatar(
                                backgroundImage: MemoryImage(app.icon!),
                                backgroundColor: Colors.transparent,
                                radius: 46,
                              )
                            : CircleAvatar(
                                backgroundColor: riskColor.withOpacity(0.2),
                                radius: 46,
                                child: Icon(
                                  Icons.apps,
                                  size: 48,
                                  color: riskColor,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // App Name
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 32),
                      child: Text(
                        app.appName,
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Risk Badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            riskColor.withOpacity(0.3),
                            riskColor.withOpacity(0.15),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: riskColor.withOpacity(0.5),
                          width: 1.5,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.shield, color: riskColor, size: 16),
                          const SizedBox(width: 8),
                          Text(
                            "${app.level.name.toUpperCase()} RISK • ${app.riskScore}%",
                            style: TextStyle(
                              color: riskColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // =============================
          // CONTENT
          // =============================
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // =============================
                  // APP CAPABILITIES (ALL PERMISSIONS)
                  // =============================
                  Row(
                    children: [
                      Container(
                        width: 4,
                        height: 24,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [Colors.redAccent, Colors.orangeAccent],
                          ),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        "Capabilities Used",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: _extractAllCapabilities().map((cap) {
                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              cap.color.withOpacity(0.25),
                              cap.color.withOpacity(0.1),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(22),
                          border: Border.all(color: cap.color.withOpacity(0.5)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(cap.icon, color: cap.color, size: 18),
                            const SizedBox(width: 8),
                            Text(
                              cap.label,
                              style: TextStyle(
                                color: cap.color,
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.3,
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),

                  const SizedBox(height: 32),

                  // =============================
                  // WHY THIS APP IS RISKY
                  // =============================
                  Row(
                    children: [
                      Container(
                        width: 4,
                        height: 24,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [riskColor, riskColor.withOpacity(0.5)],
                          ),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        "Why this app is risky",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  if (app.reasons.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Colors.greenAccent.withOpacity(0.1),
                            Colors.greenAccent.withOpacity(0.05),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.greenAccent.withOpacity(0.2),
                        ),
                      ),
                      child: Row(
                        children: const [
                          Icon(
                            Icons.check_circle,
                            color: Colors.greenAccent,
                            size: 20,
                          ),
                          SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              "No significant risk patterns detected.",
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    ...app.reasons.map(
                      (reason) => Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Colors.redAccent.withOpacity(0.1),
                              Colors.redAccent.withOpacity(0.05),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.redAccent.withOpacity(0.3),
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.redAccent.withOpacity(0.2),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.warning,
                                color: Colors.redAccent,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Text(
                                reason,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  height: 1.4,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                  const SizedBox(height: 32),

                  
                  // =============================
                  // PERMISSIONS & RISK LEVEL
                  // =============================
                  Row(
                    children: [
                      Container(
                        width: 4,
                        height: 24,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [riskColor, riskColor.withOpacity(0.5)],
                          ),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          "Permissions & Risk Level",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: riskColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: riskColor.withOpacity(0.3)),
                        ),
                        child: Text(
                          "${app.permissions.length} permissions",
                          style: TextStyle(
                            color: riskColor,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  ...app.permissions
                      .where((perm) {
                        final color = _permissionColor(perm);
                        return color == Colors.redAccent ||
                            color == Colors.orangeAccent;
                      })
                      .map((perm) {
                        final color = _permissionColor(perm);
                        final icon = _permissionIcon(perm);
                        final explanation = _permissionExplanation(perm);
                        final permName = perm.replaceAll(
                          "android.permission.",
                          "",
                        );

                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                const Color(0xFF1A1F35),
                                const Color(0xFF12182B),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: color.withOpacity(0.3),
                              width: 1.5,
                            ),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Icon
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        color.withOpacity(0.3),
                                        color.withOpacity(0.15),
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: color.withOpacity(0.4),
                                    ),
                                  ),
                                  child: Icon(icon, color: color, size: 24),
                                ),
                                const SizedBox(width: 16),
                                // Content
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        permName,
                                        style: TextStyle(
                                          color: color,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        explanation,
                                        style: const TextStyle(
                                          color: Colors.white60,
                                          fontSize: 13,
                                          height: 1.4,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }),

                  const SizedBox(height: 32),

                  // =============================
                  // OPEN SETTINGS BUTTON
                  // =============================
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      gradient: LinearGradient(
                        colors: [Colors.cyanAccent, Colors.blueAccent],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.cyanAccent.withOpacity(0.3),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.settings, size: 22),
                      label: const Text(
                        "Open App Permission Settings",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.3,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        foregroundColor: Colors.black,
                        shadowColor: Colors.transparent,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      onPressed: _openAppSettings,
                    ),
                  ),

                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Capability {
  final String label;
  final IconData icon;
  final Color color;

  _Capability({required this.label, required this.icon, required this.color});
}
