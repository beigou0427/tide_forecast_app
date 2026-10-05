enum VisualHookStage {
  valueShock,     // 第 1 幀：價值震撼 (權威專線、0 延遲)
  coreUtility,    // 第 2 幀：核心效用 (純潮汐儀表、走水窗口)
  riskReversal,   // 第 3 幀：顧慮消除 (85站離線預載、斷網可用)
}

class VisualScreenshotFrame {
  final int order;
  final VisualHookStage stage;
  final String headline;
  final String subHeadline;
  final String coreMetricProof;

  const VisualScreenshotFrame({
    required this.order,
    required this.stage,
    required this.headline,
    required this.subHeadline,
    required this.coreMetricProof,
  });
}

class VisualConversionAuditReport {
  final bool isSequenceValid;
  final bool isCognitiveLoadSafe;
  final bool hasConcreteMetricProof;
  final List<String> issues;

  const VisualConversionAuditReport({
    required this.isSequenceValid,
    required this.isCognitiveLoadSafe,
    required this.hasConcreteMetricProof,
    required this.issues,
  });

  bool get isPassed => isSequenceValid && isCognitiveLoadSafe && hasConcreteMetricProof && issues.isEmpty;
}

/// 🌟 Sylvain Gauchet (Apptamin 創辦人 / 影片預覽大師)
/// 前 3 張截圖 3 秒視覺心理轉換與轉化率 (CVR) 自檢引擎
class VisualConversionEngine {
  /// 官方推薦前 3 幀黃金轉換序列
  static const List<VisualScreenshotFrame> goldenTrioFrames = [
    VisualScreenshotFrame(
      order: 1,
      stage: VisualHookStage.valueShock,
      headline: "85 測站光纖直連 · 0 延遲實況雷達",
      subHeadline: "中央氣象署官方遙測陣列直連，掌握即時波高風速",
      coreMetricProof: "0 延遲 · 38ms 響應",
    ),
    VisualScreenshotFrame(
      order: 2,
      stage: VisualHookStage.coreUtility,
      headline: "純潮汐航海儀表 · 滿退起流走水窗口",
      subHeadline: "滿乾潮差精確換算，滿退 2 分水大咬時機一眼看懂",
      coreMetricProof: "起流黃金期換算",
    ),
    VisualScreenshotFrame(
      order: 3,
      stage: VisualHookStage.riskReversal,
      headline: "全島 85 站離線預載神盾 · 斷網無憂",
      subHeadline: "出海前 10 秒一鍵封裝，無基地台訊號外礁照常導航",
      coreMetricProof: "100% 離線可用",
    ),
  ];

  /// 🌟 專屬自動化自檢診斷方法：檢驗截圖文案排版是否符合 3 秒認知轉換定律
  static VisualConversionAuditReport runDiagnosticCheck({List<VisualScreenshotFrame>? frames}) {
    final targetFrames = frames ?? goldenTrioFrames;
    final List<String> issues = [];

    // 1. 檢驗張數 (前 3 幀必須齊全)
    if (targetFrames.length < 3) {
      issues.add("前置截圖不足 3 張，無法構成完整視覺轉化漏斗");
    }

    // 2. 檢驗三階心理學順序 (價值震撼 -> 核心效用 -> 顧慮消除)
    bool sequenceOk = true;
    if (targetFrames.length >= 3) {
      if (targetFrames[0].stage != VisualHookStage.valueShock) sequenceOk = false;
      if (targetFrames[1].stage != VisualHookStage.coreUtility) sequenceOk = false;
      if (targetFrames[2].stage != VisualHookStage.riskReversal) sequenceOk = false;
    } else {
      sequenceOk = false;
    }
    if (!sequenceOk) {
      issues.add("前 3 幀視覺序列偏離【價值震撼 -> 核心效用 -> 顧慮消除】黃金漏斗");
    }

    // 3. 認知負載檢驗 (主標題 <= 22 字元，確保小螢幕上字體大而清晰)
    bool cognitiveOk = true;
    for (final f in targetFrames) {
      if (f.headline.length > 22) {
        cognitiveOk = false;
        issues.add("[第 ${f.order} 幀] 主標題過長 (${f.headline.length} 字)，烈日或縮圖下難以辨識");
      }
    }

    // 4. 具體硬核數據實證檢驗 (拒絕抽象空洞形容詞)
    bool metricProofOk = true;
    for (final f in targetFrames) {
      if (f.coreMetricProof.isEmpty) {
        metricProofOk = false;
        issues.add("[第 ${f.order} 幀] 缺少具體硬核數據實證");
      }
    }

    return VisualConversionAuditReport(
      isSequenceValid: sequenceOk,
      isCognitiveLoadSafe: cognitiveOk,
      hasConcreteMetricProof: metricProofOk,
      issues: issues,
    );
  }
}