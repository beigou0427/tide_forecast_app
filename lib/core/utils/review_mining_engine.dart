enum ReviewSentimentCategory {
  enthusiasticAngler, // 興奮釣友 (大咬、破個人紀錄、爆箱)
  maritimeSafety,     // 海事安全感謝 (避開長湧、防困礁、及時撤退)
  professionalCaptain // 專業船長肯定 (駕駛台好用、光纖直連準確)
}

class GeneratedDeveloperResponse {
  final ReviewSentimentCategory category;
  final String responseText;
  final List<String> infusedKeywords;

  const GeneratedDeveloperResponse({
    required this.category,
    required this.responseText,
    required this.infusedKeywords,
  });
}

class ReviewMiningAuditReport {
  final bool isKeywordInfusionSufficient;
  final bool isLengthCompliant;
  final bool isZeroLinkSpam;
  final List<String> issues;

  const ReviewMiningAuditReport({
    required this.isKeywordInfusionSufficient,
    required this.isLengthCompliant,
    required this.isZeroLinkSpam,
    required this.issues,
  });

  bool get isPassed => isKeywordInfusionSufficient && isLengthCompliant && isZeroLinkSpam && issues.isEmpty;
}

/// 🌟 Ekaterina Petrova (AppFollow 前負責人 / 評論探勘權威)
/// 評價情緒探勘與動態關鍵字融合回覆引擎
class ReviewMiningEngine {
  /// 針對三種最高價值 5 星評價情境，自動生成融合 ASO 關鍵字之官方回覆
  static GeneratedDeveloperResponse generateKeywordInfusedResponse({
    required String reviewerName,
    required ReviewSentimentCategory category,
  }) {
    switch (category) {
      case ReviewSentimentCategory.enthusiasticAngler:
        return GeneratedDeveloperResponse(
          category: category,
          responseText: "感謝 $reviewerName 釣友的五星肯定！恭喜拉上大物！老船長會持續優化全台 85 測站光纖直連與滿退 2 分走水黃金期計算，祝您每次出海都爆箱滿載！",
          infusedKeywords: ["85測站", "光纖直連", "走水黃金期"],
        );
      case ReviewSentimentCategory.maritimeSafety:
        return GeneratedDeveloperResponse(
          category: category,
          responseText: "感謝 $reviewerName 船長的回饋！能及時發布外礁長湧瘋狗浪預警並守護人身安全是我們的第一職責。老船長團隊會持續捍衛 30 分鐘滿潮防困礁雷達，祝航安順行！",
          infusedKeywords: ["瘋狗浪", "防困礁", "外礁"],
        );
      case ReviewSentimentCategory.professionalCaptain:
        return GeneratedDeveloperResponse(
          category: category,
          responseText: "感謝 $reviewerName 船長對駕駛台純潮汐儀表的支持！我們已備妥全島 85 測站一鍵離線神盾預載，外海斷網依然秒級導航，老船長團隊隨時為您待命！",
          infusedKeywords: ["純潮汐", "85測站", "離線神盾"],
        );
    }
  }

  /// 🌟 專屬自動化自檢診斷方法：檢驗回覆是否具備 ASO 權重且符合 Apple 審查規範
  static ReviewMiningAuditReport runDiagnosticCheck() {
    final List<String> issues = [];
    final categories = ReviewSentimentCategory.values;

    bool allInfused = true;
    bool allLengthOk = true;
    bool allZeroLink = true;

    for (final cat in categories) {
      final res = generateKeywordInfusedResponse(reviewerName: "測試釣友", category: cat);

      // 1. 檢驗關鍵字融合數 (至少 2 個)
      if (res.infusedKeywords.length < 2) {
        allInfused = false;
        issues.add("[類別: ${cat.name}] 關鍵字融合數不足 (${res.infusedKeywords.length} < 2)");
      }

      // 2. 檢驗長度 (Apple 建議回覆字數介於 30 至 150 字元間)
      if (res.responseText.length < 30 || res.responseText.length > 150) {
        allLengthOk = false;
        issues.add("[類別: ${cat.name}] 回覆長度不合規 (${res.responseText.length} 字，需介於 30~150 字)");
      }

      // 3. 嚴禁任何外部推銷連結 (Apple 官方審查條款)
      if (res.responseText.contains("http://") || res.responseText.contains("https://")) {
        allZeroLink = false;
        issues.add("[類別: ${cat.name}] 包含外部超連結，違反 Apple 開發者回覆公約");
      }
    }

    return ReviewMiningAuditReport(
      isKeywordInfusionSufficient: allInfused,
      isLengthCompliant: allLengthOk,
      isZeroLinkSpam: allZeroLink,
      issues: issues,
    );
  }
}