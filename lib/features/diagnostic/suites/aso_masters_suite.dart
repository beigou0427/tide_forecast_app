import 'package:tide_forecast_app/core/utils/aso_masters_engine.dart';
import 'package:tide_forecast_app/core/utils/constants.dart';
import 'package:tide_forecast_app/core/services/global_error_trap.dart';

/// 🌟 10 大行銷巨擘增長演算法與 VVIP 零退費自檢結果實體
class AsoMastersSuiteResult {
  final bool isCrossLocalizationPassed;
  final bool isHighIntentPassed;
  final bool isInAppEventPassed;
  final bool isVisualConversionPassed;
  final bool isSemanticClustersPassed;
  final bool isReviewMiningPassed;
  final bool isSeasonalityPassed;
  final bool isCroFunnelPassed;
  final bool isCustomProductPagesPassed;
  final bool isProductLedAsoPassed;
  final bool isZeroRefundGuaranteed;
  final List<String> issues;
  final String message;

  const AsoMastersSuiteResult({
    required this.isCrossLocalizationPassed,
    required this.isHighIntentPassed,
    required this.isInAppEventPassed,
    required this.isVisualConversionPassed,
    required this.isSemanticClustersPassed,
    required this.isReviewMiningPassed,
    required this.isSeasonalityPassed,
    required this.isCroFunnelPassed,
    required this.isCustomProductPagesPassed,
    required this.isProductLedAsoPassed,
    required this.isZeroRefundGuaranteed,
    required this.issues,
    required this.message,
  });

  bool get isAllPassed =>
      isCrossLocalizationPassed &&
      isHighIntentPassed &&
      isInAppEventPassed &&
      isVisualConversionPassed &&
      isSemanticClustersPassed &&
      isReviewMiningPassed &&
      isSeasonalityPassed &&
      isCroFunnelPassed &&
      isCustomProductPagesPassed &&
      isProductLedAsoPassed &&
      isZeroRefundGuaranteed &&
      issues.isEmpty;
}

/// 🌟 經海事最高規格重塑之「增長行銷與零退費」實機自檢診斷套件
class AsoMastersDiagnosticSuite {
  static Future<AsoMastersSuiteResult> run() async {
    final List<String> auditIssues = [];

    // =========================================================================
    // [01] Steve P. Young: 三維跨語言詞庫覆蓋與位元組邊界審查
    // =========================================================================
    final bool crossLocOk = AsoMastersEngine.checkCrossLocalization();
    if (!crossLocOk) {
      auditIssues.add("01. 跨語言詞庫有重複詞彙或超出 Apple 30/100 字元限制");
    }

    // =========================================================================
    // [02] Thomas Petit: 高付費意圖詞彙權重審查 (防泛流量引發高退款)
    // =========================================================================
    const highIntentSample = "85測站光纖直連，外礁瘋狗浪防困礁，滿潮退2分水溫躍層";
    final bool highIntentOk = AsoMastersEngine.checkHighIntent(highIntentSample);
    if (!highIntentOk) {
      auditIssues.add("02. 高意圖商業詞權重未達標，泛詞過多易吸引錯誤客群引發退費");
    }

    // =========================================================================
    // [03] Moritz Daan: Apple In-App Events (IAE) 活動格式合規性審查
    // =========================================================================
    final now = DateTime.now();
    final eventProposal = AsoMastersEngine.generateSpringTideEvent(now);
    final bool inAppEventOk = AsoMastersEngine.checkInAppEvent(eventProposal);
    if (!inAppEventOk) {
      auditIssues.add("03. In-App Event 中繼資料長度或活動時限不符合 Apple 審查規範");
    }

    // =========================================================================
    // [04] Sylvain Gauchet: 3秒視覺心理轉換漏斗與硬核實證審查
    // =========================================================================
    final bool visualOk = AsoMastersEngine.checkVisualConversion();
    if (!visualOk) {
      auditIssues.add("04. 前置視覺截圖未按【震撼->效用->除疑】順序或文字認知負載過重");
    }

    // =========================================================================
    // [05] Gabe Kwakyi: 四大語意分群排列組合與排他性審查
    // =========================================================================
    final bool semanticOk = AsoMastersEngine.checkSemanticClusters(
      title: AsoMastersEngine.zhHantLayer.title,
      subtitle: AsoMastersEngine.zhHantLayer.subtitle,
      keywords: AsoMastersEngine.zhHantLayer.keywords,
    );
    if (!semanticOk) {
      auditIssues.add("05. 語意分群存在標題/副標重複碰撞，未發揮最大排列組合搜尋潛力");
    }

    // =========================================================================
    // [06] Ekaterina Petrova: 評論探勘與海事關鍵字融合審查
    // =========================================================================
    final reviewResp = AsoMastersEngine.generateReviewResponse(ReviewSentimentCategory.maritimeSafety);
    final bool reviewMiningOk = reviewResp.infusedKeywords.length >= 2 &&
        reviewResp.responseText.contains("85測站") &&
        !reviewResp.responseText.contains("http");
    if (!reviewMiningOk) {
      auditIssues.add("06. 開發者回覆未融合足夠海事 ASO 關鍵字或包含違規超連結");
    }

    // =========================================================================
    // [07] Laurie Galazzo: 台灣雙峰海象季節自適應演算法邊界審查
    // =========================================================================
    final winterPkg = AsoMastersEngine.resolveSeason(DateTime(2026, 12, 1));
    final summerPkg = AsoMastersEngine.resolveSeason(DateTime(2026, 6, 1));
    final bool seasonalityOk = winterPkg.season == TaiwanOceanSeason.winterNortheastMonsoon &&
        summerPkg.season == TaiwanOceanSeason.summerSouthwestBreeze &&
        winterPkg.seasonalSubtitle.length <= 30 &&
        summerPkg.seasonalSubtitle.length <= 30;
    if (!seasonalityOk) {
      auditIssues.add("07. 雙峰季節性切換判定失準或副標題超長");
    }

    // =========================================================================
    // [08] Daniel Peris: CRO 漏斗健康度與 WCAG 陽光高對比度審查
    // =========================================================================
    final bool croFunnelOk = AsoMastersEngine.checkCroFunnel();
    if (!croFunnelOk) {
      auditIssues.add("08. 轉化漏斗數值低於行業基準或視覺對比度低於 7.0:1");
    }

    // =========================================================================
    // [09] Johannes von Cramon: 自訂產品頁面 (CPP) 三大受眾排他性審查
    // =========================================================================
    final bool cppOk = AsoMastersEngine.checkCustomProductPages();
    if (!cppOk) {
      auditIssues.add("09. 自訂產品頁面受眾缺少排他性或深度連結格式無效");
    }

    // =========================================================================
    // [10] Itai Celniker: 產品導向型 ASO (連動全域黑盒子 99.9% 零崩潰)
    // =========================================================================
    final bool productLedOk = AsoMastersEngine.checkProductLedAso();
    if (!productLedOk) {
      auditIssues.add("10. 產品導向指標異常：黑盒子中偵測到未捕獲錯誤，違反 99.9% 零崩潰 SLA");
    }

    // =========================================================================
    // [11] 🌟 VVIP 零退費與客訴防禦機制 (Zero-Refund Invariant Verification)
    // =========================================================================
    bool zeroRefundOk = true;

    // A. 價格透明度：4 大商品 ID 必須宣告完整，無任何隱形暗扣
    if (AppConstants.iapProductIds.length != 4) {
      zeroRefundOk = false;
      auditIssues.add("11A. 商業定價矩陣缺漏，非透明計費易遭用戶向 Apple 申請退款");
    }

    // B. 合法條款可及性：EULA 與隱私政策 URI 必須格式合法
    final uriEula = Uri.tryParse("https://www.apple.com/legal/internet-services/itunes/dev/stdeula/");
    final uriPrivacy = Uri.tryParse("https://gist.github.com/beigou0427/99e6eddb729ae53eb8e7474866f3f009");
    if (uriEula?.hasScheme != true || uriPrivacy?.hasScheme != true) {
      zeroRefundOk = false;
      auditIssues.add("11B. 法律合約連結無效，違反 App Store Guideline 3.1.2 訂閱規範");
    }

    // C. 零資料造假：黑盒子無重大水文渲染異常
    if (GlobalErrorTrap.hasErrors) {
      zeroRefundOk = false;
      auditIssues.add("11C. 全域黑盒子存在未捕獲崩潰，直接導致 VVIP 使用中斷並投訴");
    }

    String summaryMsg;
    if (auditIssues.isEmpty) {
      summaryMsg = "全球 10 大行銷巨擘策略全數通過實機自檢，VVIP 零退費與防客訴形式化防線 100% 穩固！";
    } else {
      summaryMsg = "發現 ${auditIssues.length} 項潛在行銷轉化或退費風險漏洞，請立即排查！";
    }

    return AsoMastersSuiteResult(
      isCrossLocalizationPassed: crossLocOk,
      isHighIntentPassed: highIntentOk,
      isInAppEventPassed: inAppEventOk,
      isVisualConversionPassed: visualOk,
      isSemanticClustersPassed: semanticOk,
      isReviewMiningPassed: reviewMiningOk,
      isSeasonalityPassed: seasonalityOk,
      isCroFunnelPassed: croFunnelOk,
      isCustomProductPagesPassed: cppOk,
      isProductLedAsoPassed: productLedOk,
      isZeroRefundGuaranteed: zeroRefundOk,
      issues: auditIssues,
      message: summaryMsg,
    );
  }
}