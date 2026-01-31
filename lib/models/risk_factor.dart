class RiskFactor {
  final String id;
  final String title;
  final String description;
  final String severity;
  final bool detected;
  final int contribution;

  RiskFactor({
    required this.id,
    required this.title,
    required this.description,
    required this.severity,
    required this.detected,
    required this.contribution,
  });
}
