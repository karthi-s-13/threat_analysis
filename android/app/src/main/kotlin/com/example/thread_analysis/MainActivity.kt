package com.example.thread_analysis

import android.app.usage.UsageStats
import android.app.usage.UsageStatsManager
import android.content.Context
import android.content.Intent
import android.content.pm.ApplicationInfo
import android.content.pm.PackageManager

import android.graphics.Bitmap
import android.graphics.Canvas
import android.graphics.drawable.BitmapDrawable
import android.net.Uri
import android.provider.Settings
import android.util.Base64

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.ByteArrayOutputStream

class MainActivity : FlutterActivity() {

    private val CHANNEL = "app_permission_scanner"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler {
                call,
                result ->
            when (call.method) {

                // =============================
                // SCAN APPS
                // =============================
                "scanApps" -> {
                    if (!hasUsageAccess()) {
                        openUsageSettings()
                        result.error(
                                "USAGE_ACCESS_REQUIRED",
                                "Usage access permission not granted",
                                null
                        )
                    } else {
                        result.success(scanAppsUsingUsageStats())
                    }
                }

                // =============================
                // OPEN APP SETTINGS
                // =============================
                "openAppSettings" -> {
                    val pkg = call.argument<String>("package")
                    if (pkg != null) {
                        val intent = Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS)
                        intent.data = Uri.parse("package:$pkg")
                        intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                        startActivity(intent)
                        result.success(null)
                    } else {
                        result.error("INVALID_PACKAGE", "Package name missing", null)
                    }
                }
                else -> result.notImplemented()
            }
        }
    }

    // =============================
    // CHECK USAGE ACCESS
    // =============================
    private fun hasUsageAccess(): Boolean {
        val usm = getSystemService(Context.USAGE_STATS_SERVICE) as UsageStatsManager

        val now = System.currentTimeMillis()
        val stats: List<UsageStats> =
                usm.queryUsageStats(UsageStatsManager.INTERVAL_DAILY, now - 1000 * 60, now)

        return stats.isNotEmpty()
    }

    // =============================
    // OPEN USAGE SETTINGS
    // =============================
    private fun openUsageSettings() {
        val intent = Intent(Settings.ACTION_USAGE_ACCESS_SETTINGS)
        intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        startActivity(intent)
    }

    // =============================
    // SCAN APPS + PERMISSIONS
    // =============================
    private fun scanAppsUsingUsageStats(): List<Map<String, Any>> {
        val usm = getSystemService(Context.USAGE_STATS_SERVICE) as UsageStatsManager
        val pm = packageManager

        val now = System.currentTimeMillis()
        val stats =
                usm.queryUsageStats(
                        UsageStatsManager.INTERVAL_DAILY,
                        now - 1000 * 60 * 60 * 24,
                        now
                )

        val appList = mutableListOf<Map<String, Any>>()

        for (stat in stats) {
            try {
                val pkgInfo = pm.getPackageInfo(stat.packageName, PackageManager.GET_PERMISSIONS)

                val appInfo = pkgInfo.applicationInfo ?: continue

                // 🚫 SKIP SYSTEM APPS
                val isSystemApp =
                        (appInfo.flags and ApplicationInfo.FLAG_SYSTEM) != 0 ||
                                (appInfo.flags and ApplicationInfo.FLAG_UPDATED_SYSTEM_APP) != 0

                if (isSystemApp) continue

                val appName = pm.getApplicationLabel(appInfo).toString()

                val iconDrawable = appInfo.loadIcon(pm)
                val iconBase64 = drawableToBase64(iconDrawable)

                val permissions = pkgInfo.requestedPermissions?.toList() ?: emptyList()

                appList.add(
                        mapOf(
                                "app_name" to appName,
                                "package_name" to stat.packageName,
                                "permissions" to permissions,
                                "last_used" to stat.lastTimeUsed,
                                "icon" to iconBase64
                        )
                )
            } catch (e: Exception) {
                // Ignore safely
            }
        }

        return appList
    }

    private fun drawableToBase64(drawable: android.graphics.drawable.Drawable): String {
        val bitmap =
                if (drawable is BitmapDrawable) {
                    drawable.bitmap
                } else {
                    val bitmap =
                            Bitmap.createBitmap(
                                    drawable.intrinsicWidth,
                                    drawable.intrinsicHeight,
                                    Bitmap.Config.ARGB_8888
                            )
                    val canvas = Canvas(bitmap)
                    drawable.setBounds(0, 0, canvas.width, canvas.height)
                    drawable.draw(canvas)
                    bitmap
                }

        val stream = ByteArrayOutputStream()
        bitmap.compress(Bitmap.CompressFormat.PNG, 100, stream)
        val bytes = stream.toByteArray()

        return Base64.encodeToString(bytes, Base64.NO_WRAP)
    }
}
