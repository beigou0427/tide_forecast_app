import 'package:flutter_test/flutter_test.dart';
import 'package:tide_forecast_app/core/utils/aso_masters_engine.dart';
import 'package:tide_forecast_app/features/diagnostic/suites/aso_masters_suite.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('⚓ Tide Pro 10 大行銷巨擘增長演算法與 VVIP 零退費深度審計', () {
    // -------------------------------------------------------------------------
    // [01] Steve P. Young: 三維跨語言詞庫覆蓋與排他性審計
    // -------------------------------------------------------------------------
    test('[01] Steve P. Young: 跨語言 300 字元三維覆蓋與零重複詞庫驗證', () {
      expect(AsoMastersEngine.checkCrossLocalization(), isTrue);
    });

    // -------------------------------------------------------------------------
    // [02] Thomas Petit: 高付費意圖關鍵字權重與反向泛詞穿透審計
    // -------------------------------------------------------------------------
    test('[02] Thomas Petit: 高商業意圖詞彙權重達標，且泛大詞稀釋必定攔截', () {
      // 正向：高意圖硬核詞
      const highIntentText = "85測站光纖直連，外礁瘋狗浪防困礁，滿潮退2分水溫躍層";
      expect(AsoMastersEngine.checkHighIntent(highIntentText), isTrue);

      // 反向穿透：滿是無購買意圖的泛大詞，必須精確判定為 false
      const dilutedText = "今天天氣真好氣象氣溫報告";
      expect(AsoMastersEngine.checkHighIntent(dilutedText), isFalse);
    });

    // -------------------------------------------------------------------------
    // [03] Moritz Daan: Apple In-App Events 活動排程與 Deep Link 審計
    // -------------------------------------------------------------------------
    test('[03] Moritz Daan: 週末大潮 IAE 活動排程規格與合法鏈接合規', () {
      final event = AsoMastersEngine.generateSpringTideEvent(DateTime(2026, 10, 4));
      expect(AsoMastersEngine.checkInAppEvent(event), isTrue);
    });

    // -------------------------------------------------------------------------
    // [04] Sylvain Gauchet: 3 秒視覺心理轉換漏斗與標題認知負載審計
    // -------------------------------------------------------------------------
    test('[04] Sylvain Gauchet: 三階段視覺漏斗合規，超長標題必須拒絕以防小螢幕辨識崩潰', () {
      // 正向標準黃金 3 幀
      expect(AsoMastersEngine.checkVisualConversion(), isTrue);

      // 反向穿透：第一幀標題超過 22 字元，必須被安全攔截
      final badFrames = [
        const VisualScreenshotFrame(
          order: 1,
          stage: VisualHookStage.valueShock,
          headline: "這是一段惡意超過二十二個中文字元上限的超級冗長廣告標題文字",
          subHeadline: "無效副標題",
          coreMetricProof: "38ms",
        ),
        const VisualScreenshotFrame(
          order: 2,
          stage: VisualHookStage.coreUtility,
          headline: "效用展示",
          subHeadline: "副標",
          coreMetricProof: "換算",
        ),
        const VisualScreenshotFrame(
          order: 3,
          stage: VisualHookStage.riskReversal,
          headline: "顧慮消除",
          subHeadline: "副標",
          coreMetricProof: "離線",
        ),
      ];
      expect(AsoMastersEngine.checkVisualConversion(frames: badFrames), isFalse);
    });

    // -------------------------------------------------------------------------
    // [05] Gabe Kwakyi: 四大語意分群排列組合 (>= 15 組) 與去重審計
    // -------------------------------------------------------------------------
    test('[05] Gabe Kwakyi: 語意分群無跨欄位重複碰撞，長尾組合潛力達標', () {
      final pass = AsoMastersEngine.checkSemanticClusters(
        title: "潮汐表 Pro",
        subtitle: "85測站氣象署直連",
        keywords: "磯釣,船釣,路亞,軟絲,黑毛",
      );
      expect(pass, isTrue);

      // 反向穿透：若 Keywords 故意混入已在 Title 出現的詞彙，必須攔截
      final failCollision = AsoMastersEngine.checkSemanticClusters(
        title: "潮汐表 Pro",
        subtitle: "85測站氣象署直連",
        keywords: "85測站,磯釣,船釣", // '85測站' 重複碰撞
      );
      expect(failCollision, isFalse);
    });

    // -------------------------------------------------------------------------
    // [06] Ekaterina Petrova: 評價情緒探勘與關鍵字融合回覆審計
    // -------------------------------------------------------------------------
    test('[06] Ekaterina Petrova: 開發者回覆融合 2 個以上 ASO 詞且零外部垃圾鏈接', () {
      final res = AsoMastersEngine.generateReviewResponse(ReviewSentimentCategory.maritimeSafety);
      expect(res.infusedKeywords.length, greaterThanOrEqualTo(2));
      expect(res.responseText.contains("85測站"), isTrue);
      expect(res.responseText.contains("http"), isFalse);
    });

    // -------------------------------------------------------------------------
    // [07] Laurie Galazzo: 台灣雙峰海象季節切換演算法審計
    // -------------------------------------------------------------------------
    test('[07] Laurie Galazzo: 12 個月洋流季節判定精準，副標長度合規', () {
      final winter = AsoMastersEngine.resolveSeason(DateTime(2026, 12, 1));
      final summer = AsoMastersEngine.resolveSeason(DateTime(2026, 6, 1));
      expect(winter.season, equals(TaiwanOceanSeason.winterNortheastMonsoon));
      expect(summer.season, equals(TaiwanOceanSeason.summerSouthwestBreeze));
      expect(winter.seasonalSubtitle.length, lessThanOrEqualTo(30));
      expect(summer.seasonalSubtitle.length, lessThanOrEqualTo(30));
    });

    // -------------------------------------------------------------------------
    // [08] Daniel Peris: CRO 轉化漏斗與 WCAG 陽光高對比度審計
    // -------------------------------------------------------------------------
    test('[08] Daniel Peris: 自然轉化率高於海事基準，且退款率必須小於 1%', () {
      // 基準數據通過
      expect(AsoMastersEngine.checkCroFunnel(), isTrue);

      // 反向穿透：若退費率達 5%，必須觸發客訴防禦警報
      const highRefundMetrics = CroFunnelMetrics(
        searchImpressions: 10000,
        productPageViews: 400,
        appDownloads: 120,
        paidConversions: 20,
        refundRequests: 2, // 退費率 10%
      );
      expect(AsoMastersEngine.checkCroFunnel(metrics: highRefundMetrics), isFalse);

      // 反向穿透：烈日下對比度低於 7.0:1 必須被阻斷
      expect(AsoMastersEngine.checkCroFunnel(contrastRatio: 5.5), isFalse);
    });

    // -------------------------------------------------------------------------
    // [09] Johannes von Cramon: 自訂產品頁面 (CPP) 三大受眾排他性審計
    // -------------------------------------------------------------------------
    test('[09] Johannes von Cramon: 三大海事受眾具備排他性 slug 與有效深度連結', () {
      expect(AsoMastersEngine.checkCustomProductPages(), isTrue);
    });

    // -------------------------------------------------------------------------
    // [10] Itai Celniker: 產品導向型 ASO (連動黑盒子零崩潰 SLA)
    // -------------------------------------------------------------------------
    test('[10] Itai Celniker: 99.9% 零崩潰指標與防熄火 Wakelock 啟用認證', () {
      expect(AsoMastersEngine.checkProductLedAso(), isTrue);
    });

    // -------------------------------------------------------------------------
    // [11] 🌟 全面執行實機自檢套件 (AsoMastersDiagnosticSuite)
    // -------------------------------------------------------------------------
    test('[11] 實機自檢套件整合驗證：全維度行銷增長與 VVIP 零退費防線全數通過', () async {
      final suiteResult = await AsoMastersDiagnosticSuite.run();
      expect(suiteResult.isAllPassed, isTrue, reason: "自檢失敗項目: ${suiteResult.issues}");
      expect(suiteResult.isZeroRefundGuaranteed, isTrue);
      expect(suiteResult.issues.isEmpty, isTrue);
    });
  });
}