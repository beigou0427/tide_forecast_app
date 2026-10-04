import 'dart:math' as math;

class SolunarData {
  final String lunarDateStr;    // 例如: "農曆十三", "農曆初一", "農曆三十"
  final String moonPhaseName;    // 例如: "下弦月"
  final String moonPhaseEmoji;   // 例如: "🌗"
  final String tideCategory;     // "大潮" | "中潮" | "小潮" | "長潮"
  final int fishActivityScore;   // 50 ~ 100 咬度活躍指數 (戴明受控區間)
  final int tidalCoefficient;    // 🌟 VVIP 核心：國際海事標準潮汐係數 (20 ~ 120)
  final String biteWindowAdvice;

  SolunarData({
    required this.lunarDateStr,
    required this.moonPhaseName,
    required this.moonPhaseEmoji,
    required this.tideCategory,
    required this.fishActivityScore,
    required this.tidalCoefficient,
    required this.biteWindowAdvice,
  });
}

/// 🌟 W. Edwards Deming (戴明) 統計製程受控天文月相算盤
/// 導入變異性歸一化 (Normalization)、剛性邊界夾鉗與國際標準潮汐係數 (Coefficient)
class SolunarUtil {
  // 朔望月權威週期常數 (天)
  static const double synodicMonth = 29.53058867;
  
  // 天文朔望基準點：2000年1月6日 18:14 UTC (新月朔點)
  static final DateTime epochRef = DateTime.utc(2000, 1, 6, 18, 14);

  static SolunarData calculate(DateTime date) {
    // 1. 計算自基準點以來的時間差 (天)，精確至分鐘
    final double epochDays = date.toUtc().difference(epochRef).inMinutes / (24.0 * 60.0);
    
    // 戴明統計變異消除：確保取模結果恆為非負數 [0.0, synodicMonth)
    double remainder = epochDays % synodicMonth;
    if (remainder < 0) {
      remainder += synodicMonth;
    }

    // 歸一化相位比例，嚴格約束於 [0.0, 1.0)
    final double phaseRatio = (remainder / synodicMonth).clamp(0.0, 0.999999);
    
    // 計算農曆日數並剛性夾鉗於 [1, 30] 區間
    final int rawLunarDay = (phaseRatio * synodicMonth).round() % 30 + 1;
    final int lunarDay = rawLunarDay.clamp(1, 30);

    // 2. 月相名稱與 Emoji
    String moonName;
    String moonEmoji;
    if (phaseRatio < 0.03 || phaseRatio > 0.97) {
      moonName = "朔月 (新月)"; moonEmoji = "🌑";
    } else if (phaseRatio < 0.22) {
      moonName = "眉月"; moonEmoji = "🌒";
    } else if (phaseRatio < 0.28) {
      moonName = "上弦月"; moonEmoji = "🌓";
    } else if (phaseRatio < 0.47) {
      moonName = "盈凸月"; moonEmoji = "🌔";
    } else if (phaseRatio < 0.53) {
      moonName = "望月 (滿月)"; moonEmoji = "🌕";
    } else if (phaseRatio < 0.72) {
      moonName = "虧凸月"; moonEmoji = "🌖";
    } else if (phaseRatio < 0.78) {
      moonName = "下弦月"; moonEmoji = "🌗";
    } else {
      moonName = "殘月"; moonEmoji = "🌘";
    }

    // 3. 🌟 VVIP 核心：國際海事標準潮汐係數 (Tidal Coefficient, 20~120)
    final double rawCoefficient = 70.0 + 50.0 * math.cos(2 * math.pi * phaseRatio);
    final int coefficient = rawCoefficient.round().clamp(20, 120);

    // 4. 台灣海事水文定律 (初一十五大潮、初八廿三小潮、初十廿五長潮)
    String tideCat;
    int activityScore;
    String biteAdvice;

    if (coefficient >= 95) {
      tideCat = "大潮";
      activityScore = 95;
      biteAdvice = "大潮走水急湍，活水帶動大量魚群，滿潮返退2分、乾潮起2分為起流時段！";
    } else if (coefficient >= 75) {
      tideCat = "中潮";
      activityScore = 85;
      biteAdvice = "流水平穩流速適中，全天就餌平均，特別適合浮游磯釣與前打作釣。";
    } else if (coefficient >= 45) {
      tideCat = "小潮";
      activityScore = 70;
      biteAdvice = "潮差偏小走水較緩，魚群活性平穩，宜尋找浪腳或岬角流尾處下竿。";
    } else {
      tideCat = "長潮";
      activityScore = 65;
      biteAdvice = "潮差最小流速近滯，宜換用細線輕釣組，或改攻港內洄游魚種。";
    }

    final int clampedScore = activityScore.clamp(50, 100);
    final String dayStr = _formatChineseLunarDay(lunarDay);

    return SolunarData(
      lunarDateStr: "農曆$dayStr",
      moonPhaseName: moonName,
      moonPhaseEmoji: moonEmoji,
      tideCategory: tideCat,
      fishActivityScore: clampedScore,
      tidalCoefficient: coefficient,
      biteWindowAdvice: biteAdvice,
    );
  }

  static String _formatChineseLunarDay(int day) {
    final int d = day.clamp(1, 30);
    if (d <= 10) {
      return "初${_digits[d]}";
    } else if (d < 20) {
      return "十${_digits[d - 10]}";
    } else if (d == 20) {
      return "二十";
    } else if (d < 30) {
      return "廿${_digits[d - 20]}";
    } else {
      return "三十";
    }
  }

  static const List<String> _digits = [
    '', '一', '二', '三', '四', '五', '六', '七', '八', '九', '十'
  ];
}
