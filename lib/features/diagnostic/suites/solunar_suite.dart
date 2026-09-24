import 'package:tide_forecast_app/core/utils/solunar_util.dart';

class SolunarSuiteResult {
  final bool is365DaysOrbitPassed;
  final bool isTidalRulesAccurate;
  final bool isExtremeEpochSafe;
  final bool isLunarRegexValid;
  final int totalDaysAudited;
  final String sampleDate;
  final String sampleLunar;
  final String samplePhase;
  final String sampleTide;
  final int sampleScore;
  final String message;

  const SolunarSuiteResult({
    required this.is365DaysOrbitPassed,
    required this.isTidalRulesAccurate,
    required this.isExtremeEpochSafe,
    required this.isLunarRegexValid,
    required this.totalDaysAudited,
    required this.sampleDate,
    required this.sampleLunar,
    required this.samplePhase,
    required this.sampleTide,
    required this.sampleScore,
    required this.message,
  });

  bool get isAllPassed =>
      is365DaysOrbitPassed &&
      isTidalRulesAccurate &&
      isExtremeEpochSafe &&
      isLunarRegexValid;
}

class SolunarDiagnosticSuite {
  static Future<SolunarSuiteResult> run() async {
    // 1. 365 天跨年連續運算壓測
    bool orbitOk = true;
    bool regexOk = true;
    final lunarRegex = RegExp(r'^農曆(初[一二三四五六七八九十]|十[一二三四五六七八九]|二十|廿[一二三四五六七八九]|三十)$');
    final startDate = DateTime(2026, 1, 1);
    
    for (int day = 0; day < 365; day++) {
      final date = startDate.add(Duration(days: day));
      final s = SolunarUtil.calculate(date);

      // 檢核數值區間
      if (s.fishActivityScore < 50 || s.fishActivityScore > 100) {
        orbitOk = false;
        break;
      }
      if (s.moonPhaseName.isEmpty || s.moonPhaseEmoji.isEmpty || s.tideCategory.isEmpty) {
        orbitOk = false;
        break;
      }

      // 檢核農曆字串正則
      if (!lunarRegex.hasMatch(s.lunarDateStr)) {
        regexOk = false;
        break;
      }
    }

    // 2. 抽驗大中小潮對齊水文定律 (初一十五大潮、初八廿三小潮、初十廿五長潮)
    bool tidalRulesOk = true;
    // 遍歷尋找特定的農曆日進行水文定律驗證
    for (int day = 0; day < 60; day++) {
      final date = startDate.add(Duration(days: day));
      final s = SolunarUtil.calculate(date);
      if (s.lunarDateStr == "農曆初一" || s.lunarDateStr == "農曆十五") {
        if (s.tideCategory != "大潮" || s.fishActivityScore < 90) tidalRulesOk = false;
      }
      if (s.lunarDateStr == "農曆初八" || s.lunarDateStr == "農曆廿三") {
        if (s.tideCategory != "小潮") tidalRulesOk = false;
      }
      if (s.lunarDateStr == "農曆初十" || s.lunarDateStr == "農曆廿五") {
        if (s.tideCategory != "長潮") tidalRulesOk = false;
      }
    }

    // 3. 極端混沌時間戳注入 (1970年 Unix紀元、2000年基準點、2099年未來)
    bool chaosEpochOk = true;
    try {
      final s1970 = SolunarUtil.calculate(DateTime(1970, 1, 1));
      final s2000 = SolunarUtil.calculate(DateTime(2000, 1, 6));
      final s2099 = SolunarUtil.calculate(DateTime(2099, 12, 31));
      if (s1970.fishActivityScore == 0 || s2000.fishActivityScore == 0 || s2099.fishActivityScore == 0) {
        chaosEpochOk = false;
      }
    } catch (_) {
      chaosEpochOk = false;
    }

    // 今日實測樣本
    final today = DateTime.now();
    final todaySample = SolunarUtil.calculate(today);

    String msg;
    if (!orbitOk) {
      msg = "365 天運算出現咬度溢出或空字串";
    } else if (!regexOk) {
      msg = "農曆字串未通過繁體正則語法驗證";
    } else if (!tidalRulesOk) {
      msg = "大中小潮水文定律對齊失真 (初一十五非大潮)";
    } else if (!chaosEpochOk) {
      msg = "極端歷史或未來年份引發計算崩潰";
    } else {
      msg = "365 天連續運算零溢出，水文定律精準對齊，跨世紀極限防禦完備";
    }

    return SolunarSuiteResult(
      is365DaysOrbitPassed: orbitOk,
      isTidalRulesAccurate: tidalRulesOk,
      isExtremeEpochSafe: chaosEpochOk,
      isLunarRegexValid: regexOk,
      totalDaysAudited: 365,
      sampleDate: "${today.year}/${today.month}/${today.day}",
      sampleLunar: todaySample.lunarDateStr,
      samplePhase: "${todaySample.moonPhaseEmoji} ${todaySample.moonPhaseName}",
      sampleTide: todaySample.tideCategory,
      sampleScore: todaySample.fishActivityScore,
      message: msg,
    );
  }
}

