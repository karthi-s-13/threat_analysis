import '../models/risk_factor.dart';
import '../models/threat_category.dart';
import '../models/url_result.dart';

class URLAnalyzer {
  // Risk weight constants
  static const int WEIGHT_NO_HTTPS = 25;
  static const int WEIGHT_IP_ADDRESS = 35;
  static const int WEIGHT_SUSPICIOUS_KEYWORDS = 20;
  static const int WEIGHT_SUSPICIOUS_TLD = 15;
  static const int WEIGHT_EXCESSIVE_SUBDOMAINS = 15;
  static const int WEIGHT_SPECIAL_CHARS = 10;
  static const int WEIGHT_SHORTENED_URL = 25;
  static const int WEIGHT_MISLEADING_DOMAIN = 30;
  static const int WEIGHT_LONG_URL = 10;
  static const int WEIGHT_PORT_NUMBER = 15;
  static const int WEIGHT_HOMOGRAPH_ATTACK = 35;

  // Suspicious TLDs commonly used in phishing
  static const Set<String> SUSPICIOUS_TLDS = {
    '.tk', '.ml', '.ga', '.cf', '.gq', '.zip', '.top', 
    '.work', '.click', '.link', '.xyz', '.info'
  };

  // Known URL shorteners
  static const Set<String> URL_SHORTENERS = {
    'bit.ly', 'tinyurl.com', 'goo.gl', 'ow.ly', 't.co',
    'is.gd', 'buff.ly', 'adf.ly', 'bitly.com', 'short.link'
  };

  // High-value targets for phishing
  static const Set<String> HIGH_VALUE_BRANDS = {
    'paypal', 'amazon', 'microsoft', 'apple', 'google',
    'facebook', 'netflix', 'instagram', 'twitter', 'linkedin',
    'bank', 'chase', 'wellsfargo', 'citibank', 'bankofamerica'
  };

  URLAnalysisResult analyzeURL(String url) {
    int riskScore = 0;
    final List<RiskFactor> factors = [];
    final List<ThreatCategory> threatCategories = [];

    try {
      final Uri uri = Uri.parse(url.toLowerCase());
      final String domain = uri.host;
      final String path = uri.path;
      final String fullUrl = url.toLowerCase();

      // 1. HTTPS/SSL Check
      _checkHTTPS(uri, factors, (score) => riskScore += score);

      // 2. IP Address Check (improved)
      _checkIPAddress(domain, factors, (score) => riskScore += score);

      // 3. Suspicious Keywords Check (enhanced)
      _checkSuspiciousKeywords(fullUrl, factors, (score) => riskScore += score);

      // 4. TLD Check
      _checkSuspiciousTLD(domain, factors, (score) => riskScore += score);

      // 5. Subdomain Analysis
      _checkExcessiveSubdomains(domain, factors, (score) => riskScore += score);

      // 6. Special Characters & Encoding
      _checkSpecialCharacters(fullUrl, factors, (score) => riskScore += score);

      // 7. URL Shortener Detection
      _checkURLShortener(domain, factors, (score) => riskScore += score);

      // 8. Misleading Domain Check
      _checkMisleadingDomain(domain, factors, (score) => riskScore += score);

      // 9. URL Length Check
      _checkURLLength(url, factors, (score) => riskScore += score);

      // 10. Port Number Check
      _checkPortNumber(uri, factors, (score) => riskScore += score);

      // 11. Homograph/Punycode Attack
      _checkHomographAttack(domain, factors, (score) => riskScore += score);

      // 12. Path Depth Analysis
      _checkPathDepth(path, factors, (score) => riskScore += score);

      // Cap score at 100
      riskScore = riskScore.clamp(0, 100);

      // Generate threat categories
      threatCategories.addAll(_generateThreatCategories(factors, riskScore));

      // Determine threat level with more granular classification
      final threatLevel = _determineThreatLevel(riskScore);
      final severityLevel = _determineSeverityLevel(riskScore);

      return URLAnalysisResult(
        threatLevel: threatLevel,
        riskScore: riskScore,
        summary: _generateSummary(threatLevel, riskScore, factors.length),
        factors: factors,
        threatCategories: threatCategories,
        severityLevel: severityLevel,
      );
    } catch (e) {
      // Handle malformed URLs
      return URLAnalysisResult(
        threatLevel: "dangerous",
        riskScore: 100,
        summary: "Malformed or invalid URL detected",
        factors: [
          RiskFactor(
            id: "malformed",
            title: "Invalid URL Format",
            description: "URL cannot be properly parsed: $e",
            severity: "critical",
            detected: true,
            contribution: 100,
          )
        ],
        threatCategories: [
          ThreatCategory(
            name: "URL Validity",
            level: "dangerous",
            score: 100,
          )
        ],
        severityLevel: "critical",
      );
    }
  }

  void _checkHTTPS(Uri uri, List<RiskFactor> factors, Function(int) addScore) {
    if (uri.scheme != 'https') {
      addScore(WEIGHT_NO_HTTPS);
      factors.add(
        RiskFactor(
          id: "ssl",
          title: "No HTTPS Encryption",
          description: "URL does not use secure HTTPS protocol, making data vulnerable to interception",
          severity: "high",
          detected: true,
          contribution: WEIGHT_NO_HTTPS,
        ),
      );
    }
  }

  void _checkIPAddress(String domain, List<RiskFactor> factors, Function(int) addScore) {
    // IPv4 pattern
    final ipv4Pattern = RegExp(r'^(\d{1,3}\.){3}\d{1,3}$');
    // IPv6 pattern (simplified)
    final ipv6Pattern = RegExp(r'^([0-9a-f]{0,4}:){2,7}[0-9a-f]{0,4}$', caseSensitive: false);
    
    if (ipv4Pattern.hasMatch(domain) || ipv6Pattern.hasMatch(domain)) {
      addScore(WEIGHT_IP_ADDRESS);
      factors.add(
        RiskFactor(
          id: "ip",
          title: "Direct IP Address",
          description: "Legitimate sites rarely use IP addresses instead of domain names",
          severity: "high",
          detected: true,
          contribution: WEIGHT_IP_ADDRESS,
        ),
      );
    }
  }

  void _checkSuspiciousKeywords(String url, List<RiskFactor> factors, Function(int) addScore) {
    final phishingKeywords = [
      'login', 'verify', 'secure', 'account', 'confirm', 'update',
      'suspend', 'limited', 'banking', 'authenticate', 'validation',
      'restore', 'unlock', 'urgent', 'expire', 'alert', 'notification'
    ];

    final detectedKeywords = phishingKeywords.where((kw) => url.contains(kw)).toList();

    if (detectedKeywords.isNotEmpty) {
      // More keywords = higher risk
      final baseScore = WEIGHT_SUSPICIOUS_KEYWORDS;
      final additionalScore = (detectedKeywords.length - 1) * 5;
      final totalScore = (baseScore + additionalScore).clamp(0, 30);
      
      addScore(totalScore);
      factors.add(
        RiskFactor(
          id: "keywords",
          title: "Phishing Keywords Detected",
          description: "Found ${detectedKeywords.length} suspicious keyword(s): ${detectedKeywords.join(', ')}",
          severity: detectedKeywords.length > 2 ? "high" : "medium",
          detected: true,
          contribution: totalScore,
        ),
      );
    }
  }

  void _checkSuspiciousTLD(String domain, List<RiskFactor> factors, Function(int) addScore) {
    for (final tld in SUSPICIOUS_TLDS) {
      if (domain.endsWith(tld)) {
        addScore(WEIGHT_SUSPICIOUS_TLD);
        factors.add(
          RiskFactor(
            id: "tld",
            title: "Suspicious Top-Level Domain",
            description: "TLD '$tld' is commonly associated with phishing and spam",
            severity: "medium",
            detected: true,
            contribution: WEIGHT_SUSPICIOUS_TLD,
          ),
        );
        break;
      }
    }
  }

  void _checkExcessiveSubdomains(String domain, List<RiskFactor> factors, Function(int) addScore) {
    final subdomainCount = domain.split('.').length - 2; // Subtract domain and TLD
    
    if (subdomainCount > 2) {
      addScore(WEIGHT_EXCESSIVE_SUBDOMAINS);
      factors.add(
        RiskFactor(
          id: "subdomains",
          title: "Excessive Subdomains",
          description: "Found $subdomainCount subdomain levels, which may indicate domain spoofing",
          severity: "medium",
          detected: true,
          contribution: WEIGHT_EXCESSIVE_SUBDOMAINS,
        ),
      );
    }
  }

  void _checkSpecialCharacters(String url, List<RiskFactor> factors, Function(int) addScore) {
    // Check for suspicious special characters
    final suspiciousChars = RegExp(r'[@%]');
    final atSymbolCount = '@'.allMatches(url).length;
    
    if (atSymbolCount > 0) {
      addScore(WEIGHT_SPECIAL_CHARS);
      factors.add(
        RiskFactor(
          id: "special_chars",
          title: "Suspicious Characters",
          description: "URL contains '@' symbol which can be used to hide the real domain",
          severity: "medium",
          detected: true,
          contribution: WEIGHT_SPECIAL_CHARS,
        ),
      );
    }
    
    // Check for excessive URL encoding
    final encodedChars = '%'.allMatches(url).length;
    if (encodedChars > 3) {
      addScore(5);
      factors.add(
        RiskFactor(
          id: "encoding",
          title: "Excessive URL Encoding",
          description: "URL contains $encodedChars encoded characters, possibly hiding malicious content",
          severity: "low",
          detected: true,
          contribution: 5,
        ),
      );
    }
  }

  void _checkURLShortener(String domain, List<RiskFactor> factors, Function(int) addScore) {
    if (URL_SHORTENERS.contains(domain)) {
      addScore(WEIGHT_SHORTENED_URL);
      factors.add(
        RiskFactor(
          id: "shortener",
          title: "URL Shortener Detected",
          description: "Shortened URLs hide the true destination and are often used in phishing",
          severity: "high",
          detected: true,
          contribution: WEIGHT_SHORTENED_URL,
        ),
      );
    }
  }

  void _checkMisleadingDomain(String domain, List<RiskFactor> factors, Function(int) addScore) {
    for (final brand in HIGH_VALUE_BRANDS) {
      if (domain.contains(brand) && !domain.startsWith(brand)) {
        // Brand name appears but not as primary domain
        addScore(WEIGHT_MISLEADING_DOMAIN);
        factors.add(
          RiskFactor(
            id: "misleading",
            title: "Potential Brand Impersonation",
            description: "Domain contains '$brand' but appears to be impersonating the legitimate site",
            severity: "high",
            detected: true,
            contribution: WEIGHT_MISLEADING_DOMAIN,
          ),
        );
        break;
      }
    }
    
    // Check for common typosquatting patterns
    final typosquatPatterns = [
      RegExp(r'[0O][0O]'), // Double zeros/O's
      RegExp(r'[l1][l1]'), // l and 1 confusion
      RegExp(r'rn'), // 'rn' looking like 'm'
    ];
    
    for (final pattern in typosquatPatterns) {
      if (pattern.hasMatch(domain)) {
        addScore(10);
        factors.add(
          RiskFactor(
            id: "typosquat",
            title: "Possible Typosquatting",
            description: "Domain uses character combinations that may mimic legitimate sites",
            severity: "medium",
            detected: true,
            contribution: 10,
          ),
        );
        break;
      }
    }
  }

  void _checkURLLength(String url, List<RiskFactor> factors, Function(int) addScore) {
    if (url.length > 100) {
      addScore(WEIGHT_LONG_URL);
      factors.add(
        RiskFactor(
          id: "length",
          title: "Unusually Long URL",
          description: "URL length (${url.length} characters) may hide suspicious content",
          severity: "low",
          detected: true,
          contribution: WEIGHT_LONG_URL,
        ),
      );
    }
  }

  void _checkPortNumber(Uri uri, List<RiskFactor> factors, Function(int) addScore) {
    if (uri.hasPort && uri.port != 80 && uri.port != 443) {
      addScore(WEIGHT_PORT_NUMBER);
      factors.add(
        RiskFactor(
          id: "port",
          title: "Non-Standard Port",
          description: "URL uses port ${uri.port}, which is unusual for regular websites",
          severity: "medium",
          detected: true,
          contribution: WEIGHT_PORT_NUMBER,
        ),
      );
    }
  }

  void _checkHomographAttack(String domain, List<RiskFactor> factors, Function(int) addScore) {
    // Check for punycode (xn--)
    if (domain.contains('xn--')) {
      addScore(WEIGHT_HOMOGRAPH_ATTACK);
      factors.add(
        RiskFactor(
          id: "homograph",
          title: "Punycode/Homograph Attack",
          description: "Domain uses internationalized characters that may visually impersonate legitimate sites",
          severity: "high",
          detected: true,
          contribution: WEIGHT_HOMOGRAPH_ATTACK,
        ),
      );
    }
  }

  void _checkPathDepth(String path, List<RiskFactor> factors, Function(int) addScore) {
    final pathSegments = path.split('/').where((s) => s.isNotEmpty).length;
    
    if (pathSegments > 5) {
      addScore(5);
      factors.add(
        RiskFactor(
          id: "path_depth",
          title: "Deep URL Path",
          description: "URL has $pathSegments path segments, which may indicate redirection chains",
          severity: "low",
          detected: true,
          contribution: 5,
        ),
      );
    }
  }

  List<ThreatCategory> _generateThreatCategories(List<RiskFactor> factors, int overallScore) {
    final categories = <String, List<RiskFactor>>{};
    
    // Group factors by category
    for (final factor in factors) {
      final category = _getCategoryForFactor(factor.id);
      categories.putIfAbsent(category, () => []).add(factor);
    }
    
    // Create threat categories with aggregated scores
    return categories.entries.map((entry) {
      final categoryScore = entry.value
          .fold<int>(0, (sum, factor) => sum + factor.contribution)
          .clamp(0, 100);
      
      return ThreatCategory(
        name: entry.key,
        level: _determineThreatLevel(categoryScore),
        score: categoryScore,
      );
    }).toList();
  }

  String _getCategoryForFactor(String factorId) {
    switch (factorId) {
      case 'ssl':
      case 'port':
        return 'Connection Security';
      case 'ip':
      case 'tld':
      case 'subdomains':
        return 'Domain Trust';
      case 'keywords':
      case 'misleading':
      case 'typosquat':
      case 'homograph':
        return 'Phishing Indicators';
      case 'shortener':
      case 'length':
      case 'path_depth':
        return 'URL Structure';
      case 'special_chars':
      case 'encoding':
        return 'Obfuscation Techniques';
      default:
        return 'General Risk';
    }
  }

  String _determineThreatLevel(int score) {
    if (score <= 20) return 'safe';
    if (score <= 40) return 'low';
    if (score <= 60) return 'suspicious';
    if (score <= 80) return 'dangerous';
    return 'critical';
  }

  String _determineSeverityLevel(int score) {
    if (score <= 20) return 'safe';
    if (score <= 40) return 'low';
    if (score <= 60) return 'medium';
    if (score <= 80) return 'high';
    return 'critical';
  }

  String _generateSummary(String threatLevel, int score, int factorCount) {
    final levelDescriptions = {
      'safe': 'appears to be legitimate',
      'low': 'shows minor risk indicators',
      'suspicious': 'exhibits concerning characteristics',
      'dangerous': 'displays multiple red flags',
      'critical': 'is highly likely to be malicious',
    };

    return 'Risk assessment complete: This URL $levelDescriptions[threatLevel] '
           'with a risk score of $score/100 based on $factorCount detected factor(s).';
  }
}

// Convenience function for backward compatibility
URLAnalysisResult analyzeURL(String url) {
  return URLAnalyzer().analyzeURL(url);
}