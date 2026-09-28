import 'dart:math' as math;
import '../../features/tide/data/tide_model.dart';
import 'solunar_util.dart';

class SpeciesBiteIndex {
  final String speciesName;
  final int biteProbability; // 0 ~ 99%
  final String statusBadge;   // "🔥 爆咬開口" | "⚡ 活性極高" | "平穩索餌" | "閉口停滯"
  final String triggerReason; // "水溫上升 +1.2℃ · 潮目白沫成形"
  final String tacticalTip;    // "建議使用 1.5 號阿波掛青磺蝦，攻湧浪內緣"

  const SpeciesBiteIndex({
    required this.speciesName,
    required this.biteProbability,
    required this.statusBadge,
    required this.triggerReason,
    required this.tacticalTip,
  });
}

class BitePredictionResult {
  final int overallBiteScore;       // 10 ~ 99
  final String biteLevel;           // "🔥 爆咬黃金窗口" | "⚡ 活躍索餌期" | "一般作業水準"
  final String primaryWindow;       // "預估滿潮返退 2 分水 (前後 1.5 小時)"
  final String oceanTriggerSummary; // "水溫穩定微升 + 氣壓微降，外洋魚群向近岸潮目靠攏"
  final List<SpeciesBiteIndex> speciesIndices;

  const BitePredictionResult({
    required this.overallBiteScore,
    required this.biteLevel,
    required this.primaryWindow,
    required this.oceanTriggerSummary,
    required this.speciesIndices,
  });
}

/// Ken Norton 10x 價值突破：台灣海域五大標竿魚種水溫驟變索餌預警引擎
class BitePredictionEngine {
  static BitePredictionResult predict({
    required TideStationData stationData,
    required DateTime targetDate,
  }) {
    final solunar = SolunarUtil.calculate(targetDate);
    final obsList = stationData.observations;
    final latest = obsList.isNotEmpty ? obsList.last : null;

    final double waveH = latest?.waveHeight ?? 0.8;
    final double windS = latest?.windSpeed ?? 4.0;
    final double seaTemp = latest?.seaTemperature ?? 24.0;
    final double pressure = latest?.airPressure ?? 1013.2;

    // 計算 6 小時水溫與氣壓變化率 (ΔT & ΔP)
    double deltaTemp = 0.0;
    double deltaPressure = 0.0;

    if (obsList.length >= 6) {
      final past = obsList[math.max(0, obsList.length - 6)];
      if (latest?.seaTemperature != null && past.seaTemperature != null) {
        deltaTemp = latest!.seaTemperature! - past.seaTemperature!;
      }
      if (latest?.airPressure != null && past.airPressure != null) {
        deltaPressure = latest!.airPressure! - past.airPressure!;
      }
    }

    final List<SpeciesBiteIndex> species = [];

    // 1. 黑毛 / 白毛 (磯釣之王)：偏好 19°C~23.5°C，對水溫回升與浪腳白沫極度敏感
    int kuroScore = 60;
    String kuroTrigger = "常態水溫";
    if (seaTemp >= 19.0 && seaTemp <= 24.0) kuroScore += 15;
    if (deltaTemp > 0.4) {
      kuroScore += 18;
      kuroTrigger = "水溫回升 +${deltaTemp.toStringAsFixed(1)}℃ 誘發索餌";
    } else if (deltaTemp < -0.8) {
      kuroScore -= 20;
      kuroTrigger = "水溫驟降 ${deltaTemp.toStringAsFixed(1)}℃ 恐閉口";
    }
    if (waveH >= 0.8 && waveH <= 1.8) {
      kuroScore += 12;
      kuroTrigger += " · 浪腳白沫豐沛";
    }
    kuroScore = kuroScore.clamp(15, 96);
    species.add(SpeciesBiteIndex(
      speciesName: "黑毛 · 白毛",
      biteProbability: kuroScore,
      statusBadge: kuroScore >= 85 ? "🔥 爆咬開口" : (kuroScore >= 70 ? "⚡ 活性極高" : "平穩索餌"),
      triggerReason: kuroTrigger,
      tacticalTip: "建議掛阿波 0~0.5 號配合生鮮南極蝦，攻消波塊外緣流尾。",
    ));

    // 2. 軟絲 / 頭足類 (岸拋木蝦)：討厭渾濁大浪，酷愛清澈微流與小潮/長潮平水期
    int squidScore = 55;
    String squidTrigger = "水色正常";
    if (waveH < 0.9 && windS < 5.0) {
      squidScore += 25;
      squidTrigger = "風平浪靜 · 水質澄澈透明";
    } else if (waveH >= 1.5) {
      squidScore -= 30;
      squidTrigger = "風浪過大水濁 · 抱餌意願低";
    }
    if (solunar.tideCategory == "中潮" || solunar.tideCategory == "小潮") {
      squidScore += 10;
    }
    squidScore = squidScore.clamp(10, 95);
    species.add(SpeciesBiteIndex(
      speciesName: "軟絲 · 透抽",
      biteProbability: squidScore,
      statusBadge: squidScore >= 80 ? "🔥 抱餌狂咬" : (squidScore >= 65 ? "⚡ 活性佳" : "索餌謹慎"),
      triggerReason: squidTrigger,
      tacticalTip: "建議選用 3.0~3.5 號沉水木蝦，夜間搭配夜光本體攻岬角緩流。",
    ));

    // 3. 紅甘 / 煙仔虎 / 青物 (岸拋鐵板)：酷愛大潮活水急流與氣壓鋒面前降壓
    int pelagicScore = 50;
    String pelagicTrigger = "常態走水";
    if (solunar.tideCategory == "大潮") {
      pelagicScore += 25;
      pelagicTrigger = "大潮急流走活水 · 誘集餌魚";
    }
    if (deltaPressure < -0.8 && deltaPressure > -3.5) {
      pelagicScore += 15;
      pelagicTrigger += " · 氣壓微降促使靠岸獵食";
    }
    pelagicScore = pelagicScore.clamp(15, 95);
    species.add(SpeciesBiteIndex(
      speciesName: "紅甘 · 煙仔虎",
      biteProbability: pelagicScore,
      statusBadge: pelagicScore >= 82 ? "🔥 追餌狂炸" : (pelagicScore >= 68 ? "⚡ 靠岸活躍" : "零星咬口"),
      triggerReason: pelagicTrigger,
      tacticalTip: "選用 40g~60g 快沉微鐵，於滿潮退 2 分急流處全層快抽跳底。",
    ));

    // 4. 黑鯛 / 石斑 (前打沉底)：底棲抗濁，偏好漲潮推浪帶入岸邊泥沙貝類
    int breamScore = 65;
    String breamTrigger = "底棲覓食水文適宜";
    if (waveH >= 0.7 && waveH <= 1.5) {
      breamScore += 15;
      breamTrigger = "拍浪捲起底棲甲殼餌料";
    }
    breamScore = breamScore.clamp(20, 92);
    species.add(SpeciesBiteIndex(
      speciesName: "黑鯛 · 石斑",
      biteProbability: breamScore,
      statusBadge: breamScore >= 80 ? "🔥 底層大咬" : "穩定索餌",
      triggerReason: breamTrigger,
      tacticalTip: "採用前打青磺蝦或活白蝦，貼近防波堤樁腳緩慢落入搜尋。",
    ));

    // 綜合咬度與黃金窗口推算
    final int avgSpeciesScore = (species.fold<int>(0, (sum, s) => sum + s.biteProbability) / species.length).round();
    final int overallScore = ((solunar.fishActivityScore * 0.45) + (avgSpeciesScore * 0.55)).round().clamp(10, 99);

    String level = "一般作業水準";
    if (overallScore >= 85) level = "🔥 全台罕見爆咬黃金窗口";
    else if (overallScore >= 72) level = "⚡ 魚群高活性積極索餌期";

    String summary = "水溫穩定，走水節奏契合天體潮位，多數標點作業皆具潛力。";
    if (deltaTemp > 0.5) summary = "水溫顯著微升 +${deltaTemp.toStringAsFixed(1)}℃，水溫躍層形成促使黑毛與近岸魚種積極就餌！";
    else if (deltaTemp < -0.6) summary = "海水底層冷水上翻，魚群索餌開口度轉向敏感，建議精細釣組放緩放輕。";

    return BitePredictionResult(
      overallBiteScore: overallScore,
      biteLevel: level,
      primaryWindow: "滿潮返退 2 分水至返退 5 分 (前後 2 小時黃金流動)",
      oceanTriggerSummary: summary,
      speciesIndices: species,
    );
  }
}
