enum KeywordIntentClass {
  highIntentCommercial, // 高付費意圖詞 (如: 瘋狗浪, 85測站光纖直連, 滿潮退2分, 釣點水溫)
  informationalNiche,   // 利基水文詞 (如: 湧浪週期, 潮汐係數, 蒲福風級, 咬度)
  vanityBroad,          // 虛榮大詞 (如: 天氣, 氣象, 氣溫)
}

class KeywordScoreItem {
  final String keyword;
  final KeywordIntentClass intentClass;
  final int commercialWeight; // 1 ~ 10

  const KeywordScoreItem({
    required this.keyword,
    required this.intentClass,
    required this.commercialWeight,
  });
}

class HighIntentAuditReport {
  final double highIntentRatio;       // 高意圖詞佔比 (需 >= 70%)
  final double vanityDilutionRatio;   // 虛榮詞稀釋度 (需 <= 10%)
  final int totalAuditedTerms;
  final bool isVvipConversionOptimized;
  final List<String> issues;

  const HighIntentAuditReport({
    required this.highIntentRatio,
    required this.vanityDilutionRatio,
    required this.totalAuditedTerms,
    required this.isVvipConversionOptimized,
    required this.issues,
  });

  bool get isPassed => isVvipConversionOptimized && issues.isEmpty;
}

/// 🌟 Thomas Petit (知名行動成長顧問) 高意圖詞庫分析與自檢引擎
/// 杜絕泛天氣大詞稀釋，專注推動高客單價 VVIP 轉化
class HighIntentKeywordEngine {
  // 核心高意圖海事字典庫
  static const Map<String, KeywordScoreItem> intentDictionary = {
    // 1. 高意圖商業詞 (權重 8 ~ 10)
    "85測站": KeywordScoreItem(keyword: "85測站", intentClass: KeywordIntentClass.highIntentCommercial, commercialWeight: 10),
    "光纖直連": KeywordScoreItem(keyword: "光纖直連", intentClass: KeywordIntentClass.highIntentCommercial, commercialWeight: 10),
    "瘋狗浪": KeywordScoreItem(keyword: "瘋狗浪", intentClass: KeywordIntentClass.highIntentCommercial, commercialWeight: 10),
    "防困礁": KeywordScoreItem(keyword: "防困礁", intentClass: KeywordIntentClass.highIntentCommercial, commercialWeight: 9),
    "走水黃金期": KeywordScoreItem(keyword: "走水黃金期", intentClass: KeywordIntentClass.highIntentCommercial, commercialWeight: 9),
    "滿潮退2分": KeywordScoreItem(keyword: "滿潮退2分", intentClass: KeywordIntentClass.highIntentCommercial, commercialWeight: 9),
    "離線神盾": KeywordScoreItem(keyword: "離線神盾", intentClass: KeywordIntentClass.highIntentCommercial, commercialWeight: 9),
    "水溫躍層": KeywordScoreItem(keyword: "水溫躍層", intentClass: KeywordIntentClass.highIntentCommercial, commercialWeight: 8),
    "釣點": KeywordScoreItem(keyword: "釣點", intentClass: KeywordIntentClass.highIntentCommercial, commercialWeight: 8),

    // 2. 利基水文專業詞 (權重 5 ~ 7)
    "潮差": KeywordScoreItem(keyword: "潮差", intentClass: KeywordIntentClass.informationalNiche, commercialWeight: 7),
    "湧浪週期": KeywordScoreItem(keyword: "湧浪週期", intentClass: KeywordIntentClass.informationalNiche, commercialWeight: 7),
    "潮汐係數": KeywordScoreItem(keyword: "潮汐係數", intentClass: KeywordIntentClass.informationalNiche, commercialWeight: 6),
    "蒲福風級": KeywordScoreItem(keyword: "蒲福風級", intentClass: KeywordIntentClass.informationalNiche, commercialWeight: 6),
    "咬度": KeywordScoreItem(keyword: "咬度", intentClass: KeywordIntentClass.informationalNiche, commercialWeight: 5),

    // 3. 虛榮泛大詞 (權重 1 ~ 2)
    "天氣": KeywordScoreItem(keyword: "天氣", intentClass: KeywordIntentClass.vanityBroad, commercialWeight: 2),
    "氣象": KeywordScoreItem(keyword: "氣象", intentClass: KeywordIntentClass.vanityBroad, commercialWeight: 2),
    "溫度": KeywordScoreItem(keyword: "溫度", intentClass: KeywordIntentClass.vanityBroad, commercialWeight: 1),
  };

  /// 🌟 專屬自動化自檢診斷方法：檢驗 App 前置文案與副標題之轉化力
  static HighIntentAuditReport auditMetadataIntent({
    required String title,
    required String subtitle,
    required String firstThreeLinesOfDescription,
  }) {
    final List<String> issues = [];
    final String combined = "$title $subtitle $firstThreeLinesOfDescription";

    int highIntentCount = 0;
    int vanityCount = 0;
    int totalEvaluated = 0;

    intentDictionary.forEach((term, item) {
      if (combined.contains(term)) {
        totalEvaluated++;
        if (item.intentClass == KeywordIntentClass.highIntentCommercial) {
          highIntentCount++;
        } else if (item.intentClass == KeywordIntentClass.vanityBroad) {
          vanityCount++;
        }
      }
    });

    final double highIntentRatio = totalEvaluated > 0 ? (highIntentCount / totalEvaluated) : 0.0;
    final double vanityRatio = totalEvaluated > 0 ? (vanityCount / totalEvaluated) : 0.0;

    if (highIntentRatio < 0.65) {
      issues.add("高意圖詞彙密度不足 (${(highIntentRatio * 100).toStringAsFixed(1)}% < 65%)，恐吸引過多無購買意圖之泛流量");
    }

    if (vanityRatio > 0.15) {
      issues.add("虛榮泛詞稀釋度超標 (${(vanityRatio * 100).toStringAsFixed(1)}% > 15%)，建議減少「天氣/溫度」等大詞");
    }

    final bool isOptimized = highIntentRatio >= 0.65 && vanityRatio <= 0.15;

    return HighIntentAuditReport(
      highIntentRatio: highIntentRatio,
      vanityDilutionRatio: vanityRatio,
      totalAuditedTerms: totalEvaluated,
      isVvipConversionOptimized: isOptimized,
      issues: issues,
    );
  }
}