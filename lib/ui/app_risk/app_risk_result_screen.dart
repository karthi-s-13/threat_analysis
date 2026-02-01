import 'package:flutter/material.dart';

import '../../models/app_risk_result.dart';
import 'app_risk_detail_screen.dart';
import 'app_risk_loading_screen.dart';

import '../../app_state/app_risk_cache.dart';

class AppRiskResultScreen extends StatelessWidget {
  final List<AppRiskResult> results;

  const AppRiskResultScreen({super.key, required this.results});

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

  String _riskLabel(AppRiskLevel level) {
    switch (level) {
      case AppRiskLevel.high:
        return "HIGH RISK";
      case AppRiskLevel.medium:
        return "MEDIUM RISK";
      case AppRiskLevel.low:
      default:
        return "LOW RISK";
    }
  }

  @override
  Widget build(BuildContext context) {
    final int highCount = results
        .where((e) => e.level == AppRiskLevel.high)
        .length;
    final int mediumCount = results
        .where((e) => e.level == AppRiskLevel.medium)
        .length;
    final int lowCount = results
        .where((e) => e.level == AppRiskLevel.low)
        .length;

    return Scaffold(
      backgroundColor: const Color(0xFF0B0F1A),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // =============================
          // CUSTOM APP BAR
          // =============================
          SliverAppBar(
            expandedHeight: 200,
            floating: false,
            pinned: true,
            backgroundColor: const Color(0xFF0B0F1A),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.cyanAccent),
              onPressed: () => Navigator.pop(context),
            ),

            // ✅ ADD THIS BLOCK
            actions: [
              IconButton(
                icon: const Icon(Icons.refresh, color: Colors.cyanAccent),
                tooltip: "Rescan apps",
                onPressed: () {
                  // clear cache
                  AppRiskCache.cachedResults = null;
                  AppRiskCache.lastScanTime = null;

                  // go back to loading screen
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const AppRiskLoadingScreen(),
                    ),
                  );
                },
              ),
            ],

            flexibleSpace: FlexibleSpaceBar(
              centerTitle: true,
              title: const Text(
                "App Risk Analysis",
                style: TextStyle(
                  color: Colors.cyanAccent,
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
                      Colors.cyanAccent.withOpacity(0.15),
                      const Color(0xFF0B0F1A),
                    ],
                  ),
                ),
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 40),
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            Colors.cyanAccent.withOpacity(0.2),
                            Colors.transparent,
                          ],
                        ),
                      ),
                      child: const Icon(
                        Icons.assessment,
                        size: 56,
                        color: Colors.cyanAccent,
                      ),
                    ),
                  ),
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
                  // SUMMARY SECTION
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
                            colors: [Colors.cyanAccent, Colors.blueAccent],
                          ),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        "Overall Risk Summary",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Risk Stats Cards
                  Row(
                    children: [
                      Expanded(
                        child: _summaryCard(
                          count: highCount,
                          label: "High",
                          color: Colors.redAccent,
                          icon: Icons.warning,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _summaryCard(
                          count: mediumCount,
                          label: "Medium",
                          color: Colors.orangeAccent,
                          icon: Icons.info,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _summaryCard(
                          count: lowCount,
                          label: "Low",
                          color: Colors.greenAccent,
                          icon: Icons.check_circle,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 28),

                  // =============================
                  // APP LIST HEADER
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
                            colors: [Colors.cyanAccent, Colors.blueAccent],
                          ),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          "Installed Apps (High → Low Risk)",
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
                          color: Colors.cyanAccent.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.cyanAccent.withOpacity(0.3),
                          ),
                        ),
                        child: Text(
                          "${results.length} apps",
                          style: const TextStyle(
                            color: Colors.cyanAccent,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),

          // =============================
          // APP LIST
          // =============================
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate((context, index) {
                final app = results[index];
                final riskColor = _riskColor(app.level);

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
                      color: riskColor.withOpacity(0.3),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: riskColor.withOpacity(0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => AppRiskDetailScreen(app: app),
                          ),
                        );
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            // App Icon
                            Container(
                              width: 56,
                              height: 56,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: riskColor.withOpacity(0.3),
                                  width: 2,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: riskColor.withOpacity(0.2),
                                    blurRadius: 8,
                                    spreadRadius: 1,
                                  ),
                                ],
                              ),
                              child: app.icon != null
                                  ? CircleAvatar(
                                      backgroundImage: MemoryImage(app.icon!),
                                      backgroundColor: Colors.transparent,
                                      radius: 26,
                                    )
                                  : CircleAvatar(
                                      backgroundColor: riskColor.withOpacity(
                                        0.2,
                                      ),
                                      radius: 26,
                                      child: Icon(
                                        Icons.apps,
                                        color: riskColor,
                                        size: 28,
                                      ),
                                    ),
                            ),
                            const SizedBox(width: 16),

                            // App Info
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    app.appName,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 6),
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: riskColor.withOpacity(0.15),
                                          borderRadius: BorderRadius.circular(
                                            6,
                                          ),
                                          border: Border.all(
                                            color: riskColor.withOpacity(0.3),
                                          ),
                                        ),
                                        child: Text(
                                          _riskLabel(app.level),
                                          style: TextStyle(
                                            color: riskColor,
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                            letterSpacing: 0.5,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.white.withOpacity(0.05),
                                          borderRadius: BorderRadius.circular(
                                            6,
                                          ),
                                        ),
                                        child: Row(
                                          children: [
                                            Icon(
                                              Icons.pie_chart,
                                              size: 12,
                                              color: riskColor,
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              "${app.riskScore}%",
                                              style: TextStyle(
                                                color: riskColor,
                                                fontSize: 11,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),

                            // Chevron
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: riskColor.withOpacity(0.1),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.chevron_right,
                                color: riskColor,
                                size: 20,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              }, childCount: results.length),
            ),
          ),

          // Bottom padding
          const SliverToBoxAdapter(child: SizedBox(height: 20)),
        ],
      ),
    );
  }

  Widget _summaryCard({
    required int count,
    required String label,
    required Color color,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [color.withOpacity(0.15), color.withOpacity(0.05)],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3), width: 1.5),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 12),
          Text(
            "$count",
            style: TextStyle(
              color: color,
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: color.withOpacity(0.8),
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
