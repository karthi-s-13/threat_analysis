import 'risk_factor.dart';
import 'threat_category.dart';

class URLAnalysisResult {
  final String threatLevel;
  final int riskScore;
  final List<RiskFactor> factors;
  final String summary;
  final List<ThreatCategory> threatCategories;
  final String severityLevel;

  URLAnalysisResult({
    required this.threatLevel,
    required this.riskScore,
    required this.factors,
    required this.summary,
    required this.threatCategories,
    required this.severityLevel,
  });
}
