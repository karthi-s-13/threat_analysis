import '../models/mail_result.dart';
import '../models/risk_factor.dart';
import '../models/threat_category.dart';

// Compile Regex patterns once for performance
class _Patterns {
  static final urgent = RegExp(r'\b(urgent|immediately|act now|expires|deadline|24 hours|suspended)\b', caseSensitive: false);
  static final sensitive = RegExp(r'\b(password|otp|pin|credit card|social security|cvv|routing number|verification code)\b', caseSensitive: false);
  static final prize = RegExp(r'\b(congratulations|winner|lottery|reward|bonus|free money|inheritance|million dollars)\b', caseSensitive: false);
  static final fear = RegExp(r'\b(unauthorized|hacked|breach|legal action|warrant|arrest|locked|restricted)\b', caseSensitive: false);
  static final genericGreeting = RegExp(r'^\s*(dear|hello)\s+(customer|user|member|client|friend)', caseSensitive: false, multiLine: true);
  
  // Detects IP addresses in links or raw IP text
  static final ipAddress = RegExp(r'https?:\/\/[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+'); 
  // Detects plain http (not https)
  static final insecureHttp = RegExp(r'http:\/\/(?!localhost)'); 
}

const _freeEmailProviders = {
  'gmail.com', 'yahoo.com', 'hotmail.com', 'outlook.com', 'aol.com', 'icloud.com', 'protonmail.com'
};

const _corporateKeywords = [
  'support', 'security', 'billing', 'account', 'verify', 'team', 'service'
];

MailAnalysisResult analyzeMail({
  required String content,
  required String sender,
}) {
  int riskScore = 0;
  final List<RiskFactor> factors = [];
  final List<HighlightedWord> highlights = [];
  
  // Normalize content for analysis
  final lowerContent = content.toLowerCase();
  final senderLower = sender.toLowerCase();
  
  // Extract domain (handles "Name <email@domain.com>" format if present)
  String senderDomain = "";
  if (senderLower.contains("@")) {
    final parts = senderLower.split("@");
    senderDomain = parts.last.replaceAll('>', '').trim();
  }

  // ==========================
  // 1. Sender Analysis (Enhanced)
  // ==========================
  
  // Check for suspicious TLDs and patterns
  final suspiciousTlds = RegExp(r'\.(ru|cn|tk|top|xyz|club|info)$');
  final suspiciousKeywords = RegExp(r'(temp|fake|random|noreply.*[0-9]{3,})'); // e.g. noreply882
  
  if (suspiciousTlds.hasMatch(senderDomain) || suspiciousKeywords.hasMatch(senderDomain)) {
    riskScore += 30;
    factors.add(RiskFactor(
      id: "sender_domain",
      title: "Suspicious Sender Domain",
      description: "The sender's domain ($senderDomain) has a high reputation for spam/phishing.",
      severity: "high",
      detected: true,
      contribution: 30,
    ));
  }

  // Check for Free Provider Mismatch (e.g., claiming to be Support but using Gmail)
  if (_freeEmailProviders.contains(senderDomain)) {
    // Check if the local-part (before @) or content implies a corporate entity
    bool impliesCorporate = _corporateKeywords.any((word) => senderLower.contains(word));
    
    if (impliesCorporate) {
      riskScore += 40; // High Risk: Corporate emails don't come from Gmail
      factors.add(RiskFactor(
        id: "provider_mismatch",
        title: "Sender Identity Mismatch",
        description: "Email claims to be official/corporate but was sent from a public free email provider.",
        severity: "critical",
        detected: true,
        contribution: 40,
      ));
    }
  }

  // ==========================
  // 2. Link & Technical Analysis
  // ==========================
  if (_Patterns.ipAddress.hasMatch(content)) {
    riskScore += 50;
    factors.add(RiskFactor(
      id: "ip_link",
      title: "Obfuscated Link (IP)",
      description: "Contains a link pointing to a raw IP address instead of a domain name.",
      severity: "critical",
      detected: true,
      contribution: 50,
    ));
  }

  if (_Patterns.insecureHttp.hasMatch(content)) {
    riskScore += 10;
    factors.add(RiskFactor(
      id: "insecure_link",
      title: "Insecure Links",
      description: "Contains links using HTTP instead of the secure HTTPS protocol.",
      severity: "low",
      detected: true,
      contribution: 10,
    ));
  }

  // ==========================
  // 3. Behavioral Analysis
  // ==========================

  // Generic Greeting check (common in mass phishing)
  if (_Patterns.genericGreeting.hasMatch(lowerContent)) {
    riskScore += 10;
    factors.add(RiskFactor(
      id: "generic_greeting",
      title: "Impersonal Greeting",
      description: "Uses a generic greeting ('Dear Customer') rather than your name.",
      severity: "low",
      detected: true,
      contribution: 10,
    ));
  }

  // Urgency
  if (_Patterns.urgent.hasMatch(lowerContent)) {
    riskScore += 15;
    factors.add(RiskFactor(
      id: "urgency",
      title: "Urgency Tactics",
      description: "Pressures you to act immediately to bypass critical thinking.",
      severity: "medium",
      detected: true,
      contribution: 15,
    ));
  }

  // Sensitive Data
  if (_Patterns.sensitive.hasMatch(lowerContent)) {
    riskScore += 35;
    factors.add(RiskFactor(
      id: "sensitive",
      title: "Sensitive Info Request",
      description: "Requests highly confidential credentials or financial data.",
      severity: "high",
      detected: true,
      contribution: 35,
    ));
  }

  // Fear Tactics
  if (_Patterns.fear.hasMatch(lowerContent)) {
    riskScore += 20;
    factors.add(RiskFactor(
      id: "fear",
      title: "Threatening Language",
      description: "Uses fear of account loss or legal action to coerce compliance.",
      severity: "medium",
      detected: true,
      contribution: 20,
    ));
  }

  // Prize / Scam
  if (_Patterns.prize.hasMatch(lowerContent)) {
    riskScore += 25;
    factors.add(RiskFactor(
      id: "scam",
      title: "Unrealistic Promise",
      description: "Promises money or rewards typical of lottery/inheritance scams.",
      severity: "high",
      detected: true,
      contribution: 25,
    ));
  }

  // ==========================
  // 4. Highlight Suspicious Words
  // ==========================
  
  // Combine all keywords for highlighting lookup
  final allSuspiciousTerms = [
    'urgent', 'verify', 'password', 'otp', 'winner', 'congratulations', 
    'bank', 'click', 'suspended', 'act now', 'immediately', 'breach', 
    'locked', 'lottery', 'wire', 'transfer'
  ];

  // Tokenize preserving whitespace to reconstruct text or simply list words
  // Note: This logic assumes simple space splitting. 
  for (final word in content.split(RegExp(r'\s+'))) {
    // Clean punctuation from edges (e.g., "Verify," -> "verify")
    final cleanWord = word.toLowerCase().replaceAll(RegExp(r'^[^a-z0-9]+|[^a-z0-9]+$'), '');
    
    // Check strict equality against list
    bool isSuspicious = allSuspiciousTerms.contains(cleanWord);
    
    // Check contains for composite words (e.g. "password123") only if strict failed
    if (!isSuspicious) {
       isSuspicious = allSuspiciousTerms.any((term) => cleanWord.contains(term) && term.length > 3);
    }

    highlights.add(
      HighlightedWord(
        text: word, // Return original word with punctuation for display
        suspicious: isSuspicious,
      ),
    );
  }

  // ==========================
  // 5. Final Calculation
  // ==========================
  if (riskScore > 100) riskScore = 100;

  String threatLevel;
  String summary;

  if (riskScore <= 20) {
    threatLevel = "safe";
    summary = "This message appears safe.";
  } else if (riskScore <= 65) {
    threatLevel = "suspicious"; // changed from "spam" to "suspicious" for better UX
    summary = "Caution advised. Several risk indicators were detected.";
  } else {
    threatLevel = "phishing";
    summary = "High Risk! Strong evidence of phishing or malicious intent.";
  }

  return MailAnalysisResult(
    threatLevel: threatLevel,
    riskScore: riskScore,
    summary: summary,
    factors: factors,
    highlights: highlights,
    categories: [
      ThreatCategory(
        name: "Content Analysis",
        level: riskScore > 65 ? "high" : (riskScore > 20 ? "medium" : "low"),
        score: riskScore,
      ),
    ],
  );
}