class WindCompassSuiteResult {
  final bool isNegativeAnglesSafe;
  final bool is16DirectionsAccurate;
  final bool isBeaufortScaleAccurate;
  final bool isTacticalAdviceValid;
  final String sample0Deg;
  final String sample67Deg;
  final String sample180Deg;
  final String sample270Deg;
  final String message;

  const WindCompassSuiteResult({
    required this.isNegativeAnglesSafe,
    required this.is16DirectionsAccurate,
    required this.isBeaufortScaleAccurate,
    required this.isTacticalAdviceValid,
    required this.sample0Deg,
    required this.sample67Deg,
    required this.sample180Deg,
    required this.sample270Deg,
    required this.message,
  });

  bool get isAllPassed =>
      isNegativeAnglesSafe &&
      is16DirectionsAccurate &&
      isBeaufortScaleAccurate &&
      isTacticalAdviceValid;
}

class WindCompassDiagnosticSuite {
  static const List<String> _directions = [
    "北風", "北北東", "東北風", "東北東",
    "東風", "東南東", "東南風", "南南東",
    "南風", "南南西", "西南風", "西南西",
    "西風", "西北西", "西北風", "北北西"
  ];

  static String getDirectionName(double deg) {
    final double normalized = (deg % 360 + 360) % 360;
    final int idx = ((normalized + 11.25) / 22.5).floor() % 16;
    return _directions[idx];
  }

  static String getBeaufortScale(double speed) {
    if (speed < 0.3) return "0 級無風";
    if (speed < 1.6) return "1 級軟風";
    if (speed < 3.4) return "2 級輕風";
    if (speed < 5.5) return "3 級微風";
    if (speed < 8.0) return "4 級和風";
    if (speed < 10.8) return "5 級清勁風";
    if (speed < 13.9) return "6 級強風";
    if (speed < 17.2) return "7 級疾風";
    return "8 級以上大風";
  }

  static String getTacticAdvice(double speed) {
    if (speed >= 10.8) {
      return "⚠️ 陣風強烈，釣竿受風面積大易走線，防波堤外側請嚴防強側風吹落！";
    } else if (speed >= 6.0) {
      return "🚩 具備推浪水流，建議尋找背風側岬角或深場作釣，換用較重配鉛維持泳層。";
    } else {
      return "🌊 風力柔和，微風帶起水面波紋有利降減魚群戒心，輕量路亞與阿波操控感最佳。";
    }
  }

  static Future<WindCompassSuiteResult> run() async {
    // 1. 負角度、超界角度防溢出極限測試
    bool negativeSafe = true;
    try {
      const chaosAngles = [-720.0, -360.0, -180.0, -15.0, -0.1, 0.0, 359.9, 360.0, 720.0, 1080.0];
      for (final deg in chaosAngles) {
        final name = getDirectionName(deg);
        if (name.isEmpty) negativeSafe = false;
      }
    } catch (_) {
      negativeSafe = false;
    }

    // 2. 16 方位角名稱中文精準映射校驗
    bool dirAccurate = true;
    final d0 = getDirectionName(0.0);       // 北風
    final d67 = getDirectionName(67.5);     // 東北東
    final d90 = getDirectionName(90.0);     // 東風
    final d180 = getDirectionName(180.0);   // 南風
    final d270 = getDirectionName(270.0);   // 西風

    if (d0 != "北風" || d67 != "東北東" || d90 != "東風" || d180 != "南風" || d270 != "西風") {
      dirAccurate = false;
    }

    // 3. 蒲福風力等級階梯校驗 (0~8級)
    bool beaufortOk = true;
    final bf0 = getBeaufortScale(0.1);   // 0級無風
    final bf1 = getBeaufortScale(1.0);   // 1級軟風
    final bf3 = getBeaufortScale(4.0);   // 3級微風
    final bf5 = getBeaufortScale(9.0);   // 5級清勁風
    final bf7 = getBeaufortScale(15.0);  // 7級疾風
    final bf8 = getBeaufortScale(25.0);  // 8級以上大風

    if (bf0 != "0 級無風" || bf1 != "1 級軟風" || bf3 != "3 級微風" ||
        bf5 != "5 級清勁風" || bf7 != "7 級疾風" || bf8 != "8 級以上大風") {
      beaufortOk = false;
    }

    // 4. 戰術指引字串有效性
    bool tacticOk = true;
    final tLow = getTacticAdvice(2.0);
    final tMid = getTacticAdvice(8.0);
    final tHigh = getTacticAdvice(14.0);
    if (tLow.isEmpty || tMid.isEmpty || tHigh.isEmpty || !tHigh.contains("吹落")) {
      tacticOk = false;
    }

    String msg;
    if (!negativeSafe) {
      msg = "負角度運算拋出負索引 RangeError 崩潰";
    } else if (!dirAccurate) {
      msg = "16 方位角映射偏離標準方位 (0°非北風或67.5°非東北東)";
    } else if (!beaufortOk) {
      msg = "蒲福風級階梯換算失準";
    } else if (!tacticOk) {
      msg = "風力戰術指引文字缺失";
    } else {
      msg = "負角度防溢出完備，16 方位角與蒲福風級階梯 100% 精準對齊";
    }

    return WindCompassSuiteResult(
      isNegativeAnglesSafe: negativeSafe,
      is16DirectionsAccurate: dirAccurate,
      isBeaufortScaleAccurate: beaufortOk,
      isTacticalAdviceValid: tacticOk,
      sample0Deg: d0,
      sample67Deg: d67,
      sample180Deg: d180,
      sample270Deg: d270,
      message: msg,
    );
  }
}

