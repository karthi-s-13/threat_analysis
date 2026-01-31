import 'risk_factor.dart';
import 'threat_category.dart';

class MailAnalysisResult {
  final String threatLevel; // safe | spam | phishing
  final int riskScore;
  final String summary;
  final List<RiskFactor> factors;
  final List<ThreatCategory> categories;
  final List<HighlightedWord> highlights;

  MailAnalysisResult({
    required this.threatLevel,
    required this.riskScore,
    required this.summary,
    required this.factors,
    required this.categories,
    required this.highlights,
  });
}

class HighlightedWord {
  final String text;
  final bool suspicious;

  HighlightedWord({
    required this.text,
    required this.suspicious,
  });
}
