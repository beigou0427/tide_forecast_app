enum TargetAudienceCohort {
  rockAnglers,     // 外礁磯釣客
  boatSkippers,    // 駕駛台船長 / 船釣領航員
  diversAndSurfers // 自由潛水 / 衝浪玩家
}

class CustomProductPageConfig {
  final TargetAudienceCohort cohort;
  final String cohortName;
  final String urlSlug;
  final String heroHeadline;
  final String subHeadline;
  final List<String> highlightedMetrics;
  final String deepLinkRoute;

  const CustomProductPageConfig({
    required this.cohort,
    required this.cohortName,
    required this.urlSlug,
    required this.heroHeadline,
    required this.subHeadline,
    required this.highlightedMetrics,
    required this.deepLinkRoute,
  });
}

class CppAuditReport {
  final bool isCohortCoverageComplete;
  final bool isDeepLinkSyntaxValid;
  final bool isMetricsDistinct;
  final int totalConfiguredPages;
  final List<String> issues;

  const CppAuditReport({
    required this.isCohortCoverageComplete,
    required this.isDeepLinkSyntaxValid,
    required this.isMetricsDistinct,
    required this.totalConfiguredPages,
    required this.issues,
  });

  bool get isPassed => isCohortCoverageComplete && isDeepLinkSyntaxValid && isMetricsDistinct && issues.isEmpty;
}

/// 🌟 Johannes von Cramon (Growfirst 共同創辦人)
/// Apple 自訂產品頁面 (Custom Product Pages, CPP) 分群路由與自檢引擎
class CustomProductPageEngine {
  /// 三大海事受眾官方配置矩陣
  static const List<CustomProductPageConfig> audiencePages = [
    // 1. 外礁磯釣客
    CustomProductPageConfig(
      cohort: TargetAudienceCohort.rockAnglers,
      cohortName: "外礁磯釣客專屬頁面",
      urlSlug: "rock-angling",
      heroHeadline: "黑毛白毛活性與浪腳白沫指標 · 滿潮防困礁主動警報",
      subHeadline: "外海週期 10 秒深層長湧 (瘋狗浪) 動能預警，滿退 2 分水大咬黃金期換算",
      highlightedMetrics: ["湧浪週期", "長湧動能", "防困礁", "滿退起流"],
      deepLinkRoute: "tidepro://onboarding?cohort=rock_anglers",
    ),

    // 2. 駕駛台船長 / 船釣領航員
    CustomProductPageConfig(
      cohort: TargetAudienceCohort.boatSkippers,
      cohortName: "駕駛台船長專屬頁面",
      urlSlug: "boat-captain",
      heroHeadline: "85 測站光纖直連 38ms 響應 · 全島離線神盾預載",
      subHeadline: "繞過公共快取直連氣象署陣列，駕駛台純潮汐儀表一屏綜覽、螢幕常亮永不熄火",
      highlightedMetrics: ["85測站", "光纖直連", "離線神盾", "純潮汐儀表"],
      deepLinkRoute: "tidepro://onboarding?cohort=boat_skippers",
    ),

    // 3. 自由潛水 / 衝浪玩家
    CustomProductPageConfig(
      cohort: TargetAudienceCohort.diversAndSurfers,
      cohortName: "自潛與衝浪專屬頁面",
      urlSlug: "surf-and-dive",
      heroHeadline: "實測海溫躍層與波高週期 · 澄澈平浪微流窗口",
      subHeadline: "即時掌握近岸澄澈度、浪況消長與潮差走勢，水上極限運動最可靠的安全夥伴",
      highlightedMetrics: ["海溫躍層", "波高週期", "平水微流", "潮差係數"],
      deepLinkRoute: "tidepro://onboarding?cohort=surf_dive",
    ),
  ];

  /// 🌟 專屬自動化自檢診斷方法：檢驗受眾頁面覆蓋度與 Deep Link 合規性
  static CppAuditReport runDiagnosticCheck() {
    final List<String> issues = [];

    // 1. 檢驗 3 大受眾完整性 (且不超過 Apple 35 組限制)
    final bool countOk = audiencePages.length >= 3 && audiencePages.length <= 35;
    if (!countOk) {
      issues.add("自訂產品頁面配置數量不符 (目前: ${audiencePages.length}，需介於 3 至 35 組之間)");
    }

    // 2. 檢驗 Deep Link 路由格式
    bool deepLinkOk = true;
    for (final page in audiencePages) {
      final uri = Uri.tryParse(page.deepLinkRoute);
      if (uri == null || uri.scheme != "tidepro" || !uri.queryParameters.containsKey("cohort")) {
        deepLinkOk = false;
        issues.add("[受眾: ${page.cohortName}] 深度連結格式異常: ${page.deepLinkRoute}");
      }
    }

    // 3. 檢驗各受眾核心指標差異度 (排他性)
    final Set<String> allMetrics = {};
    int totalPointers = 0;
    for (final page in audiencePages) {
      totalPointers += page.highlightedMetrics.length;
      allMetrics.addAll(page.highlightedMetrics);
    }
    // 總指標數與不重複集合數差距小於 3 視為具備高度受眾區隔
    final bool distinctOk = (totalPointers - allMetrics.length) <= 2;
    if (!distinctOk) {
      issues.add("各受眾主打指標過度雷同，未發揮客製化分群轉化優勢");
    }

    return CppAuditReport(
      isCohortCoverageComplete: countOk,
      isDeepLinkSyntaxValid: deepLinkOk,
      isMetricsDistinct: distinctOk,
      totalConfiguredPages: audiencePages.length,
      issues: issues,
    );
  }
}