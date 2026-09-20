class SolunarData {
  final String lunarDateStr;    // 例如: "農曆八月廿一"
  final String moonPhaseName;    // 例如: "下弦月"
  final String moonPhaseEmoji;   // 例如: "🌗"
  final String tideCategory;     // "大潮" | "中潮" | "小潮" | "長潮"
  final int fishActivityScore;   // 60 ~ 98 咬度活躍指數
  final String biteWindowAdvice; // "晨昏交替與滿潮退2分咬度最佳"

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
  /// 依據西曆日期推算月相、大中小潮與咬度加權
  static SolunarData calculate(DateTime date) {
    // 基準新月點 (2000年1月6日 18:14 UTC)
    final double epochDays = date.difference(DateTime.utc(2000, 1, 6, 18, 14)).inMinutes / (24 * 60);
    const double synodicMonth = 29.53058867; // 朔望月週期 (日)
    
    final double phaseRatio = (epochDays % synodicMonth) / synodicMonth;
    final int lunarDay = (phaseRatio * synodicMonth).round() % 30 + 1;

    // 1. 月相名稱與 Emoji
    String moonName;
    String moonEmoji;
    if (phaseRatio < 0.03 || phaseRatio > 0.97) {
      moonName = "朔月 (新月)";
      moonEmoji = "🌑";
    } else if (phaseRatio < 0.22) {
      moonName = "眉月";
      moonEmoji = "🌒";
    } else if (phaseRatio < 0.28) {
      moonName = "上弦月";
      moonEmoji = "🌓";
    } else if (phaseRatio < 0.47) {
      moonName = "盈凸月";
      moonEmoji = "🌔";
    } else if (phaseRatio < 0.53) {
      moonName = "望月 (滿月)";
      moonEmoji = "🌕";
    } else if (phaseRatio < 0.72) {
      moonName = "虧凸月";
      moonEmoji = "🌖";
    } else if (phaseRatio < 0.78) {
      moonName = "下弦月";
      moonEmoji = "🌗";
    } else {
      moonName = "殘月";
      moonEmoji = "🌘";
    }

    // 2. 潮差等級推算 (傳統台灣海釣口訣)
    // 初一、十五大潮；初八、二三小潮；初十、廿五長潮
    String tideCat;
    int activityScore;
    String biteAdvice;

    if ((lunarDay >= 1 && lunarDay <= 4) || (lunarDay >= 15 && lunarDay <= 18)) {
      tideCat = "大潮";
      activityScore = 95;
      biteAdvice = "大潮走水急湍，活水帶動大量魚群，滿潮返退2分、乾潮起2分為爆咬時段！";
    } else if ((lunarDay >= 5 && lunarDay <= 8) || (lunarDay >= 19 && lunarDay <= 22)) {
      tideCat = "中潮";
      activityScore = 85;
      biteAdvice = "流水平穩流速適中，全天咬口平均，特別適合浮游磯釣與前打作釣。";
    } else if ((lunarDay >= 9 && lunarDay <= 11) || (lunarDay >= 23 && lunarDay <= 25)) {
      tideCat = "小潮";
      activityScore = 70;
      biteAdvice = "潮差偏小走水較緩，魚群活性平穩，宜尋找浪腳或岬角流尾處下竿。";
    } else {
      tideCat = "長潮";
      activityScore = 65;
      biteAdvice = "水流近乎停滯，宜換用細線輕釣組，或改攻港內洄游魚種。";
    }

    final String lunarDate = "農曆初${lunarDay <= 10 ? _chineseDigits[lunarDay] : (lunarDay < 20 ? '十${_chineseDigits[lunarDay - 10]}' : (lunarDay == 20 ? '二十' : '廿${_chineseDigits[lunarDay - 20]}'))}";

    return SolunarData(
      lunarDateStr: lunarDate,
      moonPhaseName: moonName,
      moonPhaseEmoji: moonEmoji,
      tideCategory: tideCat,
      fishActivityScore: activityScore,
      biteWindowAdvice: biteAdvice,
    );
  }

  static const List<String> _chineseDigits = [
    '', '一', '二', '三', '四', '五', '六', '七', '八', '九', '十'
  ];
}
