class SolunarData {
  final String lunarDateStr;    // 例如: "農曆十三", "農曆初一", "農曆三十"
  final String moonPhaseName;    // 例如: "下弦月"
  final String moonPhaseEmoji;   // 例如: "🌗"
  final String tideCategory;     // "大潮" | "中潮" | "小潮" | "長潮"
  final int fishActivityScore;   // 50 ~ 100 咬度活躍指數
  final String biteWindowAdvice;

  SolunarData({
    required this.lunarDateStr,
    required this.moonPhaseName,
    required this.moonPhaseEmoji,
    required this.tideCategory,
    required this.fishActivityScore,
    required this.biteWindowAdvice,
  });
}

class SolunarUtil {
  static SolunarData calculate(DateTime date) {
    final double epochDays = date.difference(DateTime.utc(2000, 1, 6, 18, 14)).inMinutes / (24 * 60);
    const double synodicMonth = 29.53058867;
    
    final double phaseRatio = (epochDays % synodicMonth) / synodicMonth;
    final int lunarDay = (phaseRatio * synodicMonth).round() % 30 + 1;

    // 1. 月相名稱與 Emoji
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

    // 2. 🌟 台灣正統海事水文定律 (初一十五大潮、初八廿三小潮、初十廿五長潮)
    String tideCat;
    int activityScore;
    String biteAdvice;

    if ((lunarDay >= 1 && lunarDay <= 3) || (lunarDay >= 15 && lunarDay <= 17)) {
      tideCat = "大潮";
      activityScore = 95;
      biteAdvice = "大潮走水急湍，活水帶動大量魚群，滿潮返退2分、乾潮起2分為爆咬時段！";
    } else if ((lunarDay >= 4 && lunarDay <= 6) || (lunarDay >= 18 && lunarDay <= 20)) {
      tideCat = "中潮";
      activityScore = 85;
      biteAdvice = "流水平穩流速適中，全天咬口平均，特別適合浮游磯釣與前打作釣。";
    } else if ((lunarDay >= 7 && lunarDay <= 8) || (lunarDay >= 22 && lunarDay <= 23)) {
      tideCat = "小潮";
      activityScore = 70;
      biteAdvice = "潮差偏小走水較緩，魚群活性平穩，宜尋找浪腳或岬角流尾處下竿。";
    } else if ((lunarDay >= 9 && lunarDay <= 10) || (lunarDay >= 24 && lunarDay <= 25)) {
      tideCat = "長潮";
      activityScore = 65;
      biteAdvice = "潮差最小流速近滯，宜換用細線輕釣組，或改攻港內洄游魚種。";
    } else {
      // 11~14 與 26~30 若潮/轉潮
      tideCat = "中潮";
      activityScore = 80;
      biteAdvice = "潮水回升走水漸暢，魚群開始索餌，各標點皆可嘗試。";
    }

    // 3. 🌟 嚴格繁體中文農曆排版演算法 (徹底消滅「初十三」與「廿十」)
    final String dayStr = _formatChineseLunarDay(lunarDay);

    return SolunarData(
      lunarDateStr: "農曆$dayStr",
      moonPhaseName: moonName,
      moonPhaseEmoji: moonEmoji,
      tideCategory: tideCat,
      fishActivityScore: activityScore,
      biteWindowAdvice: biteAdvice,
    );
  }

  static String _formatChineseLunarDay(int day) {
    if (day <= 10) {
      return "初${_digits[day]}";
    } else if (day < 20) {
      return "十${_digits[day - 10]}";
    } else if (day == 20) {
      return "二十";
    } else if (day < 30) {
      return "廿${_digits[day - 20]}";
    } else {
      return "三十";
    }
  }

  static const List<String> _digits = [
    '', '一', '二', '三', '四', '五', '六', '七', '八', '九', '十'
  ];
}
