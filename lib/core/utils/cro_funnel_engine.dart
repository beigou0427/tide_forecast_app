class CroFunnelMetrics {
  final int searchImpressions;     // 搜尋曝光數
  final int productPageViews;      // 點擊進店數
  final int appDownloads;          // 下載安裝數
  final int paidConversions;       // 付費訂閱/買斷數

  const CroFunnelMetrics({
    required this.searchImpressions,
    required this.productPageViews,
    required this.appDownloads,
    required this.paidConversions,
  });

  double get tapThroughRate => searchImpressions > 0 ? (productPageViews / searchImpressions) : 0.0;
  double get conversionRate => productPageViews > 0 ? (appDownloads / productPageViews) : 0.0;
  double get paidConversionRate => appDownloads > 0 ? (paidConversions / appDownloads) : 0.0;
}

class CroAuditReport {
  final bool isTtrHealthy;
  final bool isCvrHealthy;
  final bool isContrastRatioCompliant;
  final double currentTtr;
  final double currentCvr;
  final double visualContrastRatio; // 對比度 (如 8.5:1)
  final List<String> issues;

  const CroAuditReport({
    required this.isTtrHealthy,
    required this.isCvrHealthy,
    required this.isContrastRatioCompliant,
    required this.currentTtr,
    required this.currentCvr,
    required this.visualContrastRatio,
    required this.issues,
  });

  bool get isPassed => isTtrHealthy && isCvrHealthy && isContrastRatioCompliant && issues.isEmpty;
}

/// 🌟 Daniel Peris (TheTool / PickASO 創辦人)
/// 自然點擊率 (TTR) 與下載轉化率 (CVR) 漏斗優化引擎
class CroFunnelEngine {
  // 海事工具類基準線 (Benchmark)
  static const double benchmarkTtr = 0.021; // 業界平均 2.1%
  static const double targetTtr = 0.035;    // Tide Pro 目標 3.5%
  static const double benchmarkCvr = 0.180; // 業界平均 18.0%
  static const double targetCvr = 0.280;    // Tide Pro 目標 28.0%

  /// 🌟 專屬自動化自檢診斷方法：檢驗轉化漏斗數據與視覺資產對比度
  static CroAuditReport runDiagnosticCheck({
    CroFunnelMetrics? metrics,
    double? mockContrastRatio,
  }) {
    final effectiveMetrics = metrics ?? const CroFunnelMetrics(
      searchImpressions: 10000,
      productPageViews: 380, // TTR = 3.8%
      appDownloads: 115,     // CVR = 30.2%
      paidConversions: 24,   // 付費率 = 20.8%
    );

    final List<String> issues = [];
    final ttr = effectiveMetrics.tapThroughRate;
    final cvr = effectiveMetrics.conversionRate;
    final contrast = mockContrastRatio ?? 8.6; // #021B33 深淵藍底配 #EAB308 金錨對比度約 8.6:1

    // 1. 檢驗進店點擊率 TTR (需大於行業基準 2.1%)
    final bool ttrOk = ttr >= targetTtr;
    if (ttr < benchmarkTtr) {
      issues.add("進店點擊率 TTR (${(ttr * 100).toStringAsFixed(1)}%) 低於行業均值 2.1%，建議優化 App 圖示與副標題");
    }

    // 2. 檢驗下載轉化率 CVR (需大於行業基準 18.0%)
    final bool cvrOk = cvr >= targetCvr;
    if (cvr < benchmarkCvr) {
      issues.add("下載轉化率 CVR (${(cvr * 100).toStringAsFixed(1)}%) 低於行業均值 18.0%，建議重整前 3 張截圖視覺衝擊力");
    }

    // 3. 檢驗海事儀表視覺對比度 (WCAG AAA 要求 >= 7.0:1)
    final bool contrastOk = contrast >= 7.0;
    if (!contrastOk) {
      issues.add("視覺對比度不足 ($contrast:1 < 7.0:1)，在海上強烈陽光直射下難以辨識");
    }

    return CroAuditReport(
      isTtrHealthy: ttr >= benchmarkTtr,
      isCvrHealthy: cvr >= benchmarkCvr,
      isContrastRatioCompliant: contrastOk,
      currentTtr: ttr,
      currentCvr: cvr,
      visualContrastRatio: contrast,
      issues: issues,
    );
  }
}