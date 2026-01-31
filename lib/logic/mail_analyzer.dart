import '../models/mail_result.dart';
import '../models/risk_factor.dart';
import '../models/threat_category.dart';

MailAnalysisResult analyzeMail({
  required String content,
  required String sender,
}) {
  int riskScore = 0;
  final List<RiskFactor> factors = [];
  final List<HighlightedWord> highlights = [];

  final lowerContent = content.toLowerCase();

  // ==========================
  // Sender Analysis
  // ==========================
  final senderDomain = sender.contains("@") ? sender.split("@").last : "";
  final suspiciousSender =
      RegExp(r'\.ru$|\.cn$|\.tk$|temp|fake|random').hasMatch(senderDomain);

  if (suspiciousSender) {
    riskScore += 25;
    factors.add(
      RiskFactor(
        id: "sender",
        title: "Suspicious Sender Domain",
        description: "Sender domain is commonly associated with phishing",
        severity: "high",
        detected: true,
        contribution: 25,
      ),
    );
  }

  // ==========================
  // Urgency Language
  // ==========================
  final urgentWords =
      RegExp(r'urgent|immediately|act now|expires|deadline');
  if (urgentWords.hasMatch(lowerContent)) {
    riskScore += 15;
    factors.add(
      RiskFactor(
        id: "urgency",
        title: "Urgency Tactics",
        description: "Message pressures user to act quickly",
        severity: "medium",
        detected: true,
        contribution: 15,
      ),
    );
  }

  // ==========================
  // Sensitive Data Request
  // ==========================
  final sensitiveRequest = RegExp(
    r'password|otp|pin|credit card|bank|verification code',
  );
  if (sensitiveRequest.hasMatch(lowerContent)) {
    riskScore += 30;
    factors.add(
      RiskFactor(
        id: "sensitive",
        title: "Sensitive Information Request",
        description: "Requests confidential personal or financial information",
        severity: "high",
        detected: true,
        contribution: 30,
      ),
    );
  }

  // ==========================
  // Prize / Scam Patterns
  // ==========================
  final prizeScam =
      RegExp(r'congratulations|winner|lottery|reward|bonus|free money');
  if (prizeScam.hasMatch(lowerContent)) {
    riskScore += 20;
    factors.add(
      RiskFactor(
        id: "scam",
        title: "Prize / Scam Indicators",
        description: "Message promises rewards or winnings",
        severity: "high",
        detected: true,
        contribution: 20,
      ),
    );
  }

  // ==========================
  // Fear Tactics
  // ==========================
  final fearWords =
      RegExp(r'suspended|locked|unauthorized|hacked|breach');
  if (fearWords.hasMatch(lowerContent)) {
    riskScore += 15;
    factors.add(
      RiskFactor(
        id: "fear",
        title: "Fear-Based Manipulation",
        description: "Uses fear to manipulate the user",
        severity: "medium",
        detected: true,
        contribution: 15,
      ),
    );
  }

  // ==========================
  // Highlight Suspicious Words
  // ==========================
  final suspiciousWords = [
    'urgent',
    'verify',
    'password',
    'otp',
    'winner',
    'congratulations',
    'bank',
    'click',
    'suspended'
  ];

  for (final word in content.split(RegExp(r'\s+'))) {
    final clean = word.toLowerCase().replaceAll(RegExp(r'[^a-z]'), '');
    highlights.add(
      HighlightedWord(
        text: word,
        suspicious: suspiciousWords.contains(clean),
      ),
    );
  }

  // ==========================
  // Cap Score
  // ==========================
  if (riskScore > 100) riskScore = 100;

  // ==========================
  // Threat Level
  // ==========================
  String threatLevel;
  String summary;

  if (riskScore <= 25) {
    threatLevel = "safe";
    summary = "No strong phishing indicators detected.";
  } else if (riskScore <= 60) {
    threatLevel = "spam";
    summary = "Message shows spam-like characteristics.";
  } else {
    threatLevel = "phishing";
    summary = "High confidence phishing attempt detected.";
  }

  return MailAnalysisResult(
    threatLevel: threatLevel,
    riskScore: riskScore,
    summary: summary,
    factors: factors,
    highlights: highlights,
    categories: [
      ThreatCategory(
        name: "Content Safety",
        level: threatLevel == "phishing" ? "high" : "medium",
        score: riskScore,
      ),
    ],
  );
}
