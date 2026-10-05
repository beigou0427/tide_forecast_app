enum TaiwanOceanSeason {
  winterNortheastMonsoon, // 東北季風期 (9月 ~ 翌年3月：黑毛、白毛、磯釣、長湧防浪)
  summerSouthwestBreeze,  // 夏季西南風期 (4月 ~ 8月：透抽、軟絲、船釣、微流夜釣)
}

class SeasonalAsoPackage {
  final TaiwanOceanSeason season;
  final String seasonName;
  final String seasonalSubtitle;      // 季節性副標題 (限 30 字)
  final String seasonalPromoText;     // 季節性宣傳語 (限 170 字)
  final List<String> priorityKeywords;
  final String targetSpeciesSummary;

  const SeasonalAsoPackage({
    required this.season,
    required this.seasonName,
    required this.seasonalSubtitle,
    required this.seasonalPromoText,
    required this.priorityKeywords,
    required this.targetSpeciesSummary,
  });
}

class SeasonalAsoAuditReport {
  final bool is12MonthsCycleAccurate;
  final bool isSubtitleLengthValid;
  final bool isPromoTextLengthValid;
  final List<String> issues;

  const SeasonalAsoAuditReport({
    required this.is12MonthsCycleAccurate,
    required this.isSubtitleLengthValid,
    required this.isPromoTextLengthValid,
    required this.issues,
  });

  bool get isPassed => is12MonthsCycleAccurate && isSubtitleLengthValid && isPromoTextLengthValid && issues.isEmpty;
}

/// 🌟 Laurie Galazzo (AppTweak 行動成長總監)
/// 台灣海象雙峰季節性 ASO 自動匹配與自檢引擎
class SeasonalAsoEngine {
  /// 根據當前月份自動解析最合適的 ASO 季節套裝
  static SeasonalAsoPackage resolveCurrentSeason(DateTime time) {
    final int month = time.month;
    final bool isNortheastMonsoon = (month >= 9 || month <= 3);

    if (isNortheastMonsoon) {
      return const SeasonalAsoPackage(
        season: TaiwanOceanSeason.winterNortheastMonsoon,
        seasonName: "秋冬東北季風 · 黑毛白毛狂熱季",
        seasonalSubtitle: "85測站氣象署直連，黑毛大咬防瘋狗浪",
        seasonalPromoText: "🌊 東北季風黑毛大咬季來臨！精準掌握外海深層長湧週期，85 測站光纖直連防困礁，全新純潮汐航海儀表模式上線！",
        priorityKeywords: ["黑毛", "白毛", "大坪磯釣", "防瘋狗浪", "湧浪週期", "阿波"],
        targetSpeciesSummary: "黑毛、白毛、鱸魚浪腳開口活性高峰",
      );
    } else {
      return const SeasonalAsoPackage(
        season: TaiwanOceanSeason.summerSouthwestBreeze,
        seasonName: "夏季西南平浪 · 夜釣透抽軟絲季",
        seasonalSubtitle: "85測站氣象署直連，夏夜船釣透抽軟絲微流",
        seasonalPromoText: "⛵ 夏季平順出海黃金期！夜釣透抽軟絲微流走水導航，全新純潮汐航海儀表模式與 85 站離線預載神盾就緒！",
        priorityKeywords: ["透抽", "軟絲", "船釣", "夜釣", "微鐵", "木蝦"],
        targetSpeciesSummary: "透抽、軟絲、紅甘近海走水活性高峰",
      );
    }
  }

  /// 🌟 專屬自動化自檢診斷方法：驗證 12 個月份全軌道演算法邊界與字元限制
  static SeasonalAsoAuditReport runDiagnosticCheck() {
    final List<String> issues = [];
    bool cycleAccurate = true;
    bool subLengthOk = true;
    bool promoLengthOk = true;

    // 遍歷 1 到 12 月份驗證季節切換邊界
    for (int m = 1; m <= 12; m++) {
      final sampleDate = DateTime(2026, m, 15);
      final pkg = resolveCurrentSeason(sampleDate);

      if (m >= 9 || m <= 3) {
        if (pkg.season != TaiwanOceanSeason.winterNortheastMonsoon) {
          cycleAccurate = false;
          issues.add("[$m 月] 季節判定錯誤 (應為東北季風黑毛期)");
        }
      } else {
        if (pkg.season != TaiwanOceanSeason.summerSouthwestBreeze) {
          cycleAccurate = false;
          issues.add("[$m 月] 季節判定錯誤 (應為夏季西南透抽期)");
        }
      }

      if (pkg.seasonalSubtitle.length > 30) {
        subLengthOk = false;
        issues.add("[$m 月] 副標題超過 Apple 30 字限制 (${pkg.seasonalSubtitle.length})");
      }

      if (pkg.seasonalPromoText.length > 170) {
        promoLengthOk = false;
        issues.add("[$m 月] 宣傳文字超過 Apple 170 字限制 (${pkg.seasonalPromoText.length})");
      }
    }

    return SeasonalAsoAuditReport(
      is12MonthsCycleAccurate: cycleAccurate,
      isSubtitleLengthValid: subLengthOk,
      isPromoTextLengthValid: promoLengthOk,
      issues: issues,
    );
  }
}