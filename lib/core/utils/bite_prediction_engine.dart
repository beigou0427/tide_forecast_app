import 'dart:math' as math;
import '../../features/tide/data/tide_model.dart';
import 'solunar_util.dart';

class SpeciesBiteIndex {
  final String speciesName;
  final int biteProbability; // 15 ~ 95%
  final String statusBadge;   // "活性極佳" | "穩定索餌" | "謹慎就餌" | "閉口停滯"
  final String triggerReason; // "海溫微升 +0.8℃ · 浪腳白沫適中"
  final String tacticalTip;    // "建議使用 1.5 號阿波掛生鮮蝦攻湧浪邊緣"

  const SpeciesBiteIndex({
    required this.speciesName,
    required this.biteProbability,
    required this.statusBadge,
    required this.triggerReason,
    required this.tacticalTip,
  });
}

class BitePredictionResult {
  final int overallBiteScore;       // 20 ~ 95
  final String biteLevel;           // "走水活化期" | "穩定索餌期" | "水流平緩期"
  final String primaryWindow;       // "預估滿潮返退 2 分水至 5 分水 (前後 2 小時起流)"
  final String oceanTriggerSummary; // 水文綜合推算摘要
  final List<SpeciesBiteIndex> speciesIndices;

  const BitePredictionResult({
    required this.overallBiteScore,
    required this.biteLevel,
    required this.primaryWindow,
    required this.oceanTriggerSummary,
    required this.speciesIndices,
  });
}

/// 🌟 經海事與水產生物學標準重塑之指標魚種索餌活性推算引擎
/// 嚴格以實測海溫變化率 ΔT 與大氣氣壓走勢 ΔP 為核心物理依據
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
    final double pressure = latest?.airPressure ?? 1013.25;

    // 計算 6 小時海溫與氣壓變化率 (ΔT & ΔP)
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

    // 1. 黑毛 / 白毛 (磯釣指標)：偏好 19°C~23.5°C，對水溫躍層與浪腳白沫極度敏感
    int kuroScore = 60;
    String kuroTrigger = "常態水溫";
    if (seaTemp >= 19.0 && seaTemp <= 24.0) kuroScore += 12;
    if (deltaTemp > 0.4) {
      kuroScore += 15;
      kuroTrigger = "海溫回溫 +${deltaTemp.toStringAsFixed(1)}℃ 誘發索餌";
    } else if (deltaTemp < -0.8) {
      kuroScore -= 22;
      kuroTrigger = "冷水上翻 ${deltaTemp.toStringAsFixed(1)}℃ 魚群開口敏感";
    }
    if (waveH >= 0.8 && waveH <= 1.8) {
      kuroScore += 10;
      kuroTrigger += " · 浪腳白沫氧量充足";
    }
    kuroScore = kuroScore.clamp(15, 95);
    species.add(SpeciesBiteIndex(
      speciesName: "黑毛 · 白毛",
      biteProbability: kuroScore,
      statusBadge: kuroScore >= 80 ? "活性極佳" : (kuroScore >= 68 ? "穩定索餌" : "就餌謹慎"),
      triggerReason: kuroTrigger,
      tacticalTip: "建議掛阿波 0~0.5 號配合生鮮南極蝦，攻消波塊外緣潮目流尾。",
    ));

    // 2. 軟絲 / 頭足類 (岸拋木蝦)：討厭渾濁大浪，偏好澄澈微流與小潮平水期
    int squidScore = 55;
    String squidTrigger = "水色正常";
    if (waveH < 0.9 && windS < 5.0) {
      squidScore += 22;
      squidTrigger = "風浪平順 · 岸際水質透澈";
    } else if (waveH >= 1.5) {
      squidScore -= 28;
      squidTrigger = "風浪偏大水濁 · 抱餌意願低";
    }
    if (solunar.tideCategory == "中潮" || solunar.tideCategory == "小潮") {
      squidScore += 8;
    }
    squidScore = squidScore.clamp(15, 92);
    species.add(SpeciesBiteIndex(
      speciesName: "軟絲 · 透抽",
      biteProbability: squidScore,
      statusBadge: squidScore >= 78 ? "活性良好" : (squidScore >= 65 ? "平穩索餌" : "索餌謹慎"),
      triggerReason: squidTrigger,
      tacticalTip: "選用 3.0~3.5 號慢沉木蝦，夜間搭配夜光本體攻岬角緩流交界處。",
    ));

    // 3. 紅甘 / 煙仔虎 / 青物 (岸拋鐵板)：偏好大潮急流活水與鋒面降壓走水
    int pelagicScore = 50;
    String pelagicTrigger = "常態走水";
    if (solunar.tideCategory == "大潮") {
      pelagicScore += 22;
      pelagicTrigger = "大潮急流活水 · 誘集餌魚群";
    }
    if (deltaPressure < -0.8 && deltaPressure > -3.5) {
      pelagicScore += 14;
      pelagicTrigger += " · 氣壓微降促使靠岸掠食";
    }
    pelagicScore = pelagicScore.clamp(15, 95);
    species.add(SpeciesBiteIndex(
      speciesName: "紅甘 · 煙仔虎",
      biteProbability: pelagicScore,
      statusBadge: pelagicScore >= 80 ? "靠岸活躍" : (pelagicScore >= 66 ? "適度就餌" : "零星就餌"),
      triggerReason: pelagicTrigger,
      tacticalTip: "選用 40g~60g 快沉微鐵，於滿潮退 2 分急流處全層快抽跳底搜尋。",
    ));

    // 4. 黑鯛 / 石斑 (前打沉底)：抗濁底棲，偏好推浪拍岸帶入泥沙貝類
    int breamScore = 62;
    String breamTrigger = "底棲覓食水象適宜";
    if (waveH >= 0.7 && waveH <= 1.5) {
      breamScore += 14;
      breamTrigger = "拍浪捲起底棲甲殼誘餌";
    }
    breamScore = breamScore.clamp(20, 90);
    species.add(SpeciesBiteIndex(
      speciesName: "黑鯛 · 石斑",
      biteProbability: breamScore,
      statusBadge: breamScore >= 78 ? "底層活躍" : "穩定就餌",
      triggerReason: breamTrigger,
      tacticalTip: "採用前打青磺蝦或活白蝦，貼近防波堤樁腳與深坎緩慢落入探尋。",
    ));

    // 綜合走水活躍度與滿退窗口計算
    final int avgSpeciesScore = (species.fold<int>(0, (sum, s) => sum + s.biteProbability) / species.length).round();
    final int overallScore = ((solunar.fishActivityScore * 0.45) + (avgSpeciesScore * 0.55)).round().clamp(20, 95);

    String level = "穩定索餌期";
    if (overallScore >= 80) {
      level = "走水活化期";
    } else if (overallScore <= 60) {
      level = "水流平緩期";
    }

    String summary = "水溫走勢穩定，走水節奏契合天體潮位，多數標點作業皆具良好潛力。";
    if (deltaTemp > 0.5) {
      summary = "海溫顯著微升 +${deltaTemp.toStringAsFixed(1)}℃，水溫躍層形成促使黑毛與近岸魚種積極就餌。";
    } else if (deltaTemp < -0.6) {
      summary = "海水底層冷水翻湧，魚群索餌轉向敏感，建議精細釣組放緩作釣節奏。";
    }

    return BitePredictionResult(
      overallBiteScore: overallScore,
      biteLevel: level,
      primaryWindow: "滿潮返退 2 分水至返退 5 分 (前後 2 小時走水窗口)",
      oceanTriggerSummary: summary,
      speciesIndices: species,
    );
  }
}