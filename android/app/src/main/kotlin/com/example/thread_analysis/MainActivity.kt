package com.example.thread_analysis

import android.app.usage.UsageStatsManager
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.net.Uri
import android.provider.Settings
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.util.*

class MainActivity : FlutterActivity() {

    private val CHANNEL = "app_permission_scanner"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler {
                call,
                result ->
            when (call.method) {

                // =========================
                // CHECK USAGE PERMISSION
                // =========================
                "checkUsagePermission" -> {
                    val usageStatsManager =
                            getSystemService(Context.USAGE_STATS_SERVICE) as UsageStatsManager

                    val now = System.currentTimeMillis()
                    val stats =
                            usageStatsManager.queryUsageStats(
                                    UsageStatsManager.INTERVAL_DAILY,
                                    now - 1000 * 60 * 60,
                                    now
                            )

                    result.success(stats.isNotEmpty())
                }

                // =========================
                // OPEN USAGE SETTINGS
                // =========================
                "openUsageSettings" -> {
                    startActivity(Intent(Settings.ACTION_USAGE_ACCESS_SETTINGS))
                    result.success(null)
                }

                // =========================
                // OPEN APP SETTINGS
                // =========================
                "openAppSettings" -> {
                    val pkg = call.argument<String>("package")
                    val intent = Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS)
                    intent.data = Uri.parse("package:$pkg")
                    startActivity(intent)
                    result.success(null)
                }

                // =========================
                // REAL APP SCAN
                // =========================
                "scanApps" -> {
                    try {
                        result.success(scanInstalledApps())
                    } catch (e: Exception) {
                        result.error("SCAN_FAILED", e.message, null)
                    }
                }
                else -> result.notImplemented()
            }
        }
    }

    // =========================
    // CORE SCAN LOGIC
    // =========================
    private fun scanInstalledApps(): List<Map<String, Any>> {

        val pm = packageManager
        val usageStatsManager = getSystemService(Context.USAGE_STATS_SERVICE) as UsageStatsManager

        val now = System.currentTimeMillis()

        val usageStats =
                usageStatsManager.queryUsageStats(
                        UsageStatsManager.INTERVAL_DAILY,
                        now - 1000L * 60 * 60 * 24 * 7,
                        now
                )

        val usageMap = usageStats.associateBy { it.packageName }

        val apps = pm.getInstalledApplications(PackageManager.GET_META_DATA)
        val results = mutableListOf<Map<String, Any>>()

        println("TOTAL INSTALLED APPS = ${apps.size}")

        for (app in apps) {

            val packageName = app.packageName
            val appName = pm.getApplicationLabel(app).toString()

            val packageInfo = pm.getPackageInfo(packageName, PackageManager.GET_PERMISSIONS)

            val permissions = packageInfo.requestedPermissions?.toList() ?: emptyList()

            val lastUsed = usageMap[packageName]?.lastTimeUsed ?: 0L

            println("APP → $appName | perms=${permissions.size} | lastUsed=$lastUsed")

            results.add(
                    mapOf(
                            "app_name" to appName,
                            "package_name" to packageName,
                            "permissions" to permissions,
                            "last_used" to lastUsed,
                            "is_system" to false // temporary
                    )
            )
        }

        println("FINAL APP COUNT SENT TO FLUTTER = ${results.size}")

        return results
    }
}
